import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../features/chats/providers/chat_provider.dart';
import '../../features/chats/widgets/common/user_avatar_cached.dart';

class CommunityPicker extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String?> onSelected;

  const CommunityPicker({
    super.key,
    this.initialValue,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialValue,
    required ValueChanged<String?> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: CommunityPicker(
            initialValue: initialValue,
            onSelected: onSelected,
          ),
        ),
      ),
    );
  }

  @override
  State<CommunityPicker> createState() => _CommunityPickerState();
}

class _CommunityPickerState extends State<CommunityPicker> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chatProvider = Provider.of<ChatProvider>(context);

    // In a real app, we might need a dedicated method to fetch only communities
    // but for now we filter from all chats
    final communities = chatProvider.chats
        .where((chat) => chat.isCommunity)
        .where((chat) =>
            chat.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
            false)
        .toList();

    return Column(
      children: [
        // Handle bar
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Community',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Search your communities...',
                prefixIcon: Icon(Icons.search_rounded),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        Expanded(
          child: communities.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: communities.length,
                  itemBuilder: (context, index) {
                    final community = communities[index];
                    final isSelected = community.id == widget.initialValue;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: UserAvatarCached(
                        imageUrl: community.avatar,
                        name: community.name ?? 'Community',
                        size: 40,
                        isGroup: true,
                      ),
                      title: Text(
                        community.name ?? 'Unnamed Community',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${community.totalMembers} members',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded,
                              color: colorScheme.primary)
                          : null,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onSelected(community.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No communities found'
                : 'No results for "$_searchQuery"',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_searchQuery.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Text(
                'You haven\'t joined any communities yet.',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
