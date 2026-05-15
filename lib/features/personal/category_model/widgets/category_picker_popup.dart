// lib/features/personal/post_shared/task_model/category_model/message_bubbles/category_picker_popup.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import '../models/category_model.dart';
import '../providers/category_provider.dart';
import 'create_category_dialog.dart';

class CategoryPickerResult {
  final Category category;
  final String? subType;

  CategoryPickerResult({required this.category, this.subType});

  String get categoryId => category.id;
  String get categoryType => category.categoryType;
  String get categoryIcon => category.icon;
  String get categoryColor => category.color;
}

class CategoryPickerPopup {
  /// Show category_model picker as bottom sheet
  static Future<CategoryPickerResult?> show({
    required BuildContext context,
    required String categoryFor,
    CategoryPickerResult? initialSelection,
    bool showSubTypeSelector = true,
    bool allowCreate = true,
  }) async {
    return await showModalBottomSheet<CategoryPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => CategoryPickerSheet(
        categoryFor: categoryFor,
        initialSelection: initialSelection,
        showSubTypeSelector: showSubTypeSelector,
        allowCreate: allowCreate,
      ),
    );
  }

  /// Show category_model picker as dialog (alternative)
  static Future<CategoryPickerResult?> showAsDialog({
    required BuildContext context,
    required String categoryFor,
    CategoryPickerResult? initialSelection,
    bool showSubTypeSelector = true,
    bool allowCreate = true,
  }) async {
    return await showDialog<CategoryPickerResult?>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: 500,
          ),
          child: CategoryPickerContent(
            categoryFor: categoryFor,
            initialSelection: initialSelection,
            showSubTypeSelector: showSubTypeSelector,
            allowCreate: allowCreate,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BOTTOM SHEET
// ============================================================================

class CategoryPickerSheet extends StatelessWidget {
  final String categoryFor;
  final CategoryPickerResult? initialSelection;
  final bool showSubTypeSelector;
  final bool allowCreate;

  const CategoryPickerSheet({
    super.key,
    required this.categoryFor,
    this.initialSelection,
    this.showSubTypeSelector = true,
    this.allowCreate = true,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: CategoryPickerContent(
                  categoryFor: categoryFor,
                  initialSelection: initialSelection,
                  showSubTypeSelector: showSubTypeSelector,
                  allowCreate: allowCreate,
                  scrollController: scrollController,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// MAIN CONTENT
// ============================================================================

class CategoryPickerContent extends StatefulWidget {
  final String categoryFor;
  final CategoryPickerResult? initialSelection;
  final bool showSubTypeSelector;
  final bool allowCreate;
  final ScrollController? scrollController;

  const CategoryPickerContent({
    super.key,
    required this.categoryFor,
    this.initialSelection,
    this.showSubTypeSelector = true,
    this.allowCreate = true,
    this.scrollController,
  });

  @override
  State<CategoryPickerContent> createState() => _CategoryPickerContentState();
}

class _CategoryPickerContentState extends State<CategoryPickerContent> {
  Category? _selectedCategory;
  String? _selectedSubType;
  String _searchQuery = '';
  bool _showOnlyUserCategories = false;

  @override
  void initState() {
    super.initState();
    _initializeSelection();
    _loadCategories();
  }

  void _initializeSelection() {
    if (widget.initialSelection != null) {
      _selectedCategory = widget.initialSelection!.category;
      _selectedSubType = widget.initialSelection!.subType;
    }
  }

  void _loadCategories() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CategoryProvider>();
      provider.loadCategoriesByType(widget.categoryFor);
    });
  }

  List<Category> _getFilteredCategories(CategoryProvider provider) {
    var categories = provider.getCategoriesByType(widget.categoryFor);

    // Filter by user/global
    if (_showOnlyUserCategories) {
      categories = categories.where((cat) => !cat.isGlobal).toList();
    }

    // Filter by search query - CLIENT SIDE
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      categories = categories.where((cat) {
        final matchesName = cat.categoryType.toLowerCase().contains(lowerQuery);
        final matchesDescription =
            cat.description?.toLowerCase().contains(lowerQuery) ?? false;
        return matchesName || matchesDescription;
      }).toList();
    }

    return categories;
  }

  void _selectCategory(Category category) {
    setState(() {
      _selectedCategory = category;
      // Reset sub-type if new category_model doesn't have the previously selected sub-type
      if (_selectedSubType != null &&
          !category.subTypes.contains(_selectedSubType)) {
        _selectedSubType = null;
      }
    });
  }

  void _selectSubType(String? subType) {
    setState(() {
      _selectedSubType = subType;
    });
  }

  void _confirmSelection() {
    if (_selectedCategory == null) {
      AppSnackbar.warning('Please select a category_model');
      return;
    }

    Navigator.pop(
      context,
      CategoryPickerResult(
        category: _selectedCategory!,
        subType: _selectedSubType,
      ),
    );
  }

  Future<void> _createNewCategory() async {
    final result = await showDialog<Category>(
      context: context,
      builder: (context) =>
          CreateCategoryDialog(categoryFor: widget.categoryFor),
    );

    if (result != null && mounted) {
      // Refresh and select the new category_model
      await context.read<CategoryProvider>().refreshCategories(
        widget.categoryFor,
      );
      setState(() {
        _selectedCategory = result;
        _selectedSubType = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, _) {
        if (categoryProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredCategories = _getFilteredCategories(categoryProvider);

        return Column(
          children: [
            // Header
            _buildHeader(context, theme, colorScheme),

            // Search Bar
            _buildSearchBar(context, colorScheme),

            const SizedBox(height: 12),

            // Filter & Create Row
            _buildFilterRow(context, colorScheme),

            const Divider(height: 1),

            // Categories List
            Expanded(
              child: filteredCategories.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredCategories.length,
                      itemBuilder: (context, index) {
                        final category = filteredCategories[index];
                        final isSelected = _selectedCategory?.id == category.id;

                        return _CategoryCard(
                          category: category,
                          isSelected: isSelected,
                          onTap: () => _selectCategory(category),
                        );
                      },
                    ),
            ),

            // Sub-Type Selector
            if (widget.showSubTypeSelector &&
                _selectedCategory != null &&
                _selectedCategory!.subTypes.isNotEmpty)
              _buildSubTypeSelector(context),

            // Confirm Button
            if (_selectedCategory != null) _buildConfirmButton(context),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              CategoryForType.getIcon(widget.categoryFor),
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Category',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  CategoryForType.getDisplayName(widget.categoryFor),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search categories...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _buildFilterChip('All', !_showOnlyUserCategories, () {
            setState(() => _showOnlyUserCategories = false);
          }),
          const SizedBox(width: 8),
          _buildFilterChip('Custom', _showOnlyUserCategories, () {
            setState(() => _showOnlyUserCategories = true);
          }),
          const Spacer(),
          if (widget.allowCreate)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: _createNewCategory,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'NEW',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: colorScheme.onPrimary,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSubTypeSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Sub-Category (Optional)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // None option
              ChoiceChip(
                label: const Text('None'),
                selected: _selectedSubType == null,
                onSelected: (selected) {
                  if (selected) _selectSubType(null);
                },
              ),
              // Sub-types
              ..._selectedCategory!.subTypes.map((subType) {
                return ChoiceChip(
                  label: Text(subType),
                  selected: _selectedSubType == subType,
                  onSelected: (selected) {
                    if (selected) _selectSubType(subType);
                  },
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _confirmSelection,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_selectedCategory!.icon),
                const SizedBox(width: 8),
                Text(
                  _selectedCategory!.categoryType,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedSubType != null) ...[
                  Text(
                    ' • $_selectedSubType',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary.withOpacity(0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 80,
              color: colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              _showOnlyUserCategories
                  ? 'No Custom Categories'
                  : 'No Categories Found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showOnlyUserCategories
                  ? 'Create your first custom category_model'
                  : _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'No categories available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.allowCreate) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _createNewCategory,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Category'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CATEGORY CARD
// ============================================================================

class _CategoryCard extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryColor = _parseColor(category.color);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected
            ? categoryColor.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected
              ? categoryColor
              : colorScheme.outline.withValues(alpha: 0.1),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: categoryColor.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Container with Glass Effect
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        categoryColor.withValues(alpha: 0.2),
                        categoryColor.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: categoryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    category.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              category.categoryType,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: isSelected
                                    ? categoryColor
                                    : colorScheme.onSurface,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (category.isGlobal)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_user_rounded,
                                    size: 10,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'SYSTEM',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 8,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (category.description != null &&
                          category.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          category.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (category.subTypes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: category.subTypes.take(3).map((subType) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.05,
                                  ),
                                ),
                              ),
                              child: Text(
                                subType,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Selection Indicator
                AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: isSelected ? 1.0 : 0.8,
                  child: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_off_rounded,
                    color: isSelected ? categoryColor : colorScheme.onSurface
                        .withValues(alpha: 0.15),
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      final hexCode = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }
}
