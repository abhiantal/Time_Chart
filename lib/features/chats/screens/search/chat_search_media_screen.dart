import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../widgets/error_handler.dart';
import '../../providers/chat_provider.dart';
import '../../providers/chat_attachment_provider.dart';
import '../../model/chat_attachment_model.dart';
import '../../widgets/common/empty_state_illustration.dart';
import '../../widgets/common/loading_shimmer_list.dart';
import '../../widgets/search/search_empty_state.dart';

class ChatSearchMediaScreen extends StatefulWidget {
  final String chatId;

  const ChatSearchMediaScreen({super.key, required this.chatId});

  @override
  State<ChatSearchMediaScreen> createState() => _ChatSearchMediaScreenState();
}

class _ChatSearchMediaScreenState extends State<ChatSearchMediaScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  String _selectedType = 'all';
  bool _isSearching = false;

  final List<Map<String, String>> _filterTypes = [
    {'value': 'all', 'label': 'All'},
    {'value': 'image', 'label': 'Images'},
    {'value': 'video', 'label': 'Videos'},
    {'value': 'audio', 'label': 'Audio'},
    {'value': 'document', 'label': 'Documents'},
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _isSearching = query.isNotEmpty);
        _performSearch(query);
      }
    });
  }

  void _performSearch(String query) {
    try {
      final provider = context.read<ChatProvider>();
      provider.setActiveChatId(widget.chatId);
      provider.searchNow(query);
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'ChatSearchMediaScreen.performSearch');
    }
  }

  void _clearSearch() {
    HapticFeedback.lightImpact();
    _searchController.clear();
    setState(() => _isSearching = false);
  }

  void _openMediaViewer(ChatMessageAttachmentModel media) {
    final mediaProvider = context.read<ChatAttachmentProvider>();
    final mediaItems = mediaProvider.galleryItems;
    final initialIndex = mediaItems.indexWhere((item) => item.id == media.id);

    context.pushNamed(
      'chatMediaScreen',
      pathParameters: {'chatId': widget.chatId},
      extra: {
        'mediaFiles': mediaItems
            .map((item) => item.toEnhancedMediaFile())
            .toList(),
        'initialIndex': initialIndex != -1 ? initialIndex : 0,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(22),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search media...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.clear_rounded, size: 18),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterTypes.length,
              itemBuilder: (context, index) {
                final filter = _filterTypes[index];
                final isSelected = _selectedType == filter['value'];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter['label']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedType = filter['value']!);
                      if (_searchController.text.isNotEmpty) {
                        _performSearch(_searchController.text);
                      }
                    },
                    selectedColor: colorScheme.primaryContainer,
                    checkmarkColor: colorScheme.primary,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && _isSearching) {
            return const LoadingShimmerList(itemCount: 6);
          }

          if (_isSearching && !provider.hasResults) {
            return SearchEmptyState(
              type: EmptyStateType.noSearchResults,
              searchQuery: _searchController.text,
              onAction: _clearSearch,
              compact: true,
            );
          }

          if (!_isSearching) {
            return _buildEmptyState();
          }

          return _buildMediaGrid(provider);
        },
      ),
    );
  }

  Widget _buildMediaGrid(ChatProvider provider) {
    final media = _filterMediaByType(provider.allMediaResults);

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) {
        final item = media[index];
        return GestureDetector(
          onTap: () => _openMediaViewer(item),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              image: item.thumbnailUrl != null
                  ? DecorationImage(
                      image: NetworkImage(item.thumbnailUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                if (item.isVideo)
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.play_circle_filled_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                if (item.isAudio || item.isVoice)
                  const Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.audiotrack_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                if (item.isDocument)
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.insert_drive_file_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            item.fileName ?? 'Document',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<ChatMessageAttachmentModel> _filterMediaByType(
    List<ChatMessageAttachmentModel> media,
  ) {
    if (_selectedType == 'all') return media;

    return media.where((item) {
      switch (_selectedType) {
        case 'image':
          return item.isImage;
        case 'video':
          return item.isVideo;
        case 'audio':
          return item.isAudio || item.isVoice;
        case 'document':
          return item.isDocument;
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Search Media',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Find photos, videos, audio files, and documents',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
