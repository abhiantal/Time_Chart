import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import '../providers/save_provider.dart';
import '../models/saves_model.dart';

class CollectionPicker extends StatefulWidget {
  final String postId;
  final String? initialCollection;

  const CollectionPicker({
    super.key,
    required this.postId,
    this.initialCollection,
  });

  @override
  State<CollectionPicker> createState() => _CollectionPickerState();
}

class _CollectionPickerState extends State<CollectionPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  String _selectedCollection = kDefaultCollectionName;
  bool _isCreatingNew = false;
  final TextEditingController _newCollectionController =
      TextEditingController();
  List<SaveCollection> _collections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCollection = widget.initialCollection ?? kDefaultCollectionName;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _loadCollections();
    _animationController.forward();
  }

  @override
  void dispose() {
    _newCollectionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    final provider = context.read<SaveProvider>();
    await provider.initialize();

    if (mounted) {
      setState(() {
        _collections = provider.collections.collections;
        _isLoading = false;
      });
    }
  }

  Future<void> _createAndSave() async {
    final name = _newCollectionController.text.trim();
    if (name.isEmpty) {
      AppSnackbar.error('Please enter a collection name');
      return;
    }

    if (name.length < 2) {
      AppSnackbar.error('Collection name must be at least 2 characters');
      return;
    }

    final provider = context.read<SaveProvider>();
    final success = await provider.createCollection(
      name: name,
      firstPostId: widget.postId,
    );

    if (success && mounted) {
      Navigator.pop(context, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, screenHeight * 0.3 * _slideAnimation.value),
          child: child,
        );
      },
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.7),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Save to collection',
                          style: theme.textScheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose where to save this post',
                          style: theme.textScheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            _isLoading ? _buildLoadingState(theme) : _buildContent(theme),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _isCreatingNew = !_isCreatingNew);
                      },
                      child: Text(_isCreatingNew ? 'Cancel' : 'New Collection'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isCreatingNew
                          ? _createAndSave
                          : () => Navigator.pop(context, _selectedCollection),
                      child: Text(_isCreatingNew ? 'Create' : 'Save'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isCreatingNew) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.create_new_folder,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _newCollectionController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'e.g., Inspirations, Travel, Workout',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (_) => _createAndSave(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Flexible(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _collections.length,
        itemBuilder: (context, index) {
          final collection = _collections[index];
          final isSelected = collection.name == _selectedCollection;

          return ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: collection.isDefault
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                collection.isDefault
                    ? Icons.collections_bookmark
                    : Icons.folder,
                color: collection.isDefault
                    ? theme.colorScheme.primary
                    : theme.colorScheme.secondary,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    collection.name,
                    style: theme.textScheme.titleSmall?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
            subtitle: Text(
              collection.postCountText,
              style: theme.textScheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            selected: isSelected,
            selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedCollection = collection.name;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

extension _ThemeTextScheme on ThemeData {
  TextTheme get textScheme => textTheme;
}
