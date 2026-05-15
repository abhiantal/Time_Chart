// lib/features/personal/post_shared/task_model/category_model/message_bubbles/create_category_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import '../models/category_model.dart';
import '../providers/category_provider.dart';

class CreateCategoryDialog extends StatefulWidget {
  final String categoryFor;
  final Category? initialCategory;

  const CreateCategoryDialog({
    super.key,
    required this.categoryFor,
    this.initialCategory,
  });

  @override
  State<CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<CreateCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _categoryNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subTypeController = TextEditingController();

  String _selectedColor = '#4CAF50';
  String _selectedIcon = '📁';
  final List<String> _subTypes = [];
  bool _isSubmitting = false;

  // Color options
  final List<String> _colorOptions = [
    '#4CAF50', // Green
    '#2196F3', // Blue
    '#FF9800', // Orange
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#F44336', // Red
    '#00BCD4', // Cyan
    '#FFEB3B', // Yellow (dark text)
    '#795548', // Brown
    '#607D8B', // Blue Grey
    '#FF5722', // Deep Orange
    '#3F51B5', // Indigo
  ];

  // Icon options
  final List<String> _iconOptions = [
    '📁',
    '🎯',
    '⭐',
    '💼',
    '🏃',
    '📚',
    '💪',
    '🎨',
    '💰',
    '🏠',
    '🌟',
    '🔥',
    '✨',
    '🚀',
    '💎',
    '🎓',
    '❤️',
    '🎵',
    '🍎',
    '⚽',
    '🎮',
    '📱',
    '✈️',
    '🏆',
    '📝',
    '🛠️',
    '🎬',
    '📷',
    '🎤',
    '🎪',
    '🎭',
    '🎹',
  ];

  @override
  void initState() {
    super.initState();
    _setContextualDefaults();
  }

  void _setContextualDefaults() {
    if (widget.initialCategory != null) {
      final cat = widget.initialCategory!;
      _categoryNameController.text = cat.categoryType;
      _descriptionController.text = cat.description ?? '';
      _selectedColor = cat.color;
      _selectedIcon = cat.icon;
      _subTypes.addAll(cat.subTypes);
      return;
    }

    switch (widget.categoryFor) {
      case CategoryForType.longGoal:
        _selectedIcon = '🎯';
        _selectedColor = '#4CAF50';
        break;
      case CategoryForType.bucket:
        _selectedIcon = '⭐';
        _selectedColor = '#FF9800';
        break;
      case CategoryForType.dayTask:
        _selectedIcon = '✅';
        _selectedColor = '#2196F3';
        break;
      case CategoryForType.weeklyTask:
        _selectedIcon = '📅';
        _selectedColor = '#9C27B0';
        break;
    }
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    _descriptionController.dispose();
    _subTypeController.dispose();
    super.dispose();
  }

  void _addSubType() {
    final subType = _subTypeController.text.trim();
    if (subType.isNotEmpty && !_subTypes.contains(subType)) {
      setState(() {
        _subTypes.add(subType);
        _subTypeController.clear();
      });
    }
  }

  void _removeSubType(String subType) {
    setState(() {
      _subTypes.remove(subType);
    });
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<CategoryProvider>();
      final isEdit = widget.initialCategory != null;

      Category? result;

      if (isEdit) {
        final success = await provider.updateCategory(
          categoryId: widget.initialCategory!.id,
          categoryType: _categoryNameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          color: _selectedColor,
          icon: _selectedIcon,
          subTypes: _subTypes.isEmpty ? null : _subTypes,
        );

        if (success) {
          // Construct updated category to return
          result = widget.initialCategory!.copyWith(
            categoryType: _categoryNameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            color: _selectedColor,
            icon: _selectedIcon,
            subTypes: _subTypes,
          );
        }
      } else {
        result = await provider.createCategory(
          categoryFor: widget.categoryFor,
          categoryType: _categoryNameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          color: _selectedColor,
          icon: _selectedIcon,
          subTypes: _subTypes.isEmpty ? null : _subTypes,
        );
      }

      if ((isEdit && result != null) ||
          (!isEdit && result != null) && mounted) {
        Navigator.of(context).pop(result);
        AppSnackbar.success(
          'Category "${result.categoryType}" ${isEdit ? 'updated' : 'created'}!',
        );
      } else if (mounted) {
        AppSnackbar.error(provider.error ?? 'Failed to save category');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedColor = _parseColor(_selectedColor);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Gradient
              Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      selectedColor,
                      selectedColor.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        _selectedIcon,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.initialCategory != null
                                ? 'Edit Category'
                                : 'Create Category',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              CategoryForType.getDisplayName(
                                widget.categoryFor,
                              ).toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(theme, 'BASIC INFO'),
                        const SizedBox(height: 16),
                        _buildStyledTextField(
                          controller: _categoryNameController,
                          label: 'Category Name',
                          hint: 'e.g., Fitness, Business, Travel',
                          icon: Icons.label_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Field required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildStyledTextField(
                          controller: _descriptionController,
                          label: 'Short Description',
                          hint: 'Optional context...',
                          icon: Icons.notes_rounded,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 32),

                        _buildSectionHeader(theme, 'APPEARANCE'),
                        const SizedBox(height: 16),
                        // Icon Picker with better layout
                        Text(
                          'Pick an Icon',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 160,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.1),
                            ),
                          ),
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                ),
                            itemCount: _iconOptions.length,
                            itemBuilder: (context, index) {
                              final icon = _iconOptions[index];
                              final isSelected = _selectedIcon == icon;
                              return InkWell(
                                onTap: () =>
                                    setState(() => _selectedIcon = icon),
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? selectedColor.withValues(alpha: 0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? selectedColor
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    icon,
                                    style: TextStyle(
                                      fontSize: isSelected ? 24 : 20,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Color Picker
                        Text(
                          'Select Theme Color',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _colorOptions.map((hex) {
                            final color = _parseColor(hex);
                            final isSelected = _selectedColor == hex;
                            return InkWell(
                              onTap: () => setState(() => _selectedColor = hex),
                              borderRadius: BorderRadius.circular(50),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.onSurface
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.5),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check_rounded,
                                        color: _getContrastColor(color),
                                        size: 20,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),

                        _buildSectionHeader(theme, 'STRUCTURE'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStyledTextField(
                                controller: _subTypeController,
                                label: 'Sub-Category',
                                hint: 'e.g., Running, Gym...',
                                icon: Icons.add_circle_outline_rounded,
                                onSubmitted: (_) => _addSubType(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: _addSubType,
                              style: FilledButton.styleFrom(
                                backgroundColor: selectedColor,
                                minimumSize: const Size(60, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                                shadowColor: selectedColor.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              child: const Icon(Icons.add_rounded),
                            ),
                          ],
                        ),
                        if (_subTypes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _subTypes.map((st) {
                              return Container(
                                padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                                decoration: BoxDecoration(
                                  color: selectedColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      st,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: selectedColor,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      onPressed: () => _removeSubType(st),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                      ),
                                      style: IconButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(24, 24),
                                        foregroundColor: selectedColor,
                                        backgroundColor: selectedColor
                                            .withValues(alpha: 0.1),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),

              // Button Footer
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (widget.initialCategory != null) ...[
                      IconButton(
                        onPressed: _isSubmitting ? null : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Category?'),
                              content: const Text('This will permanently remove this custom category and all its settings. This cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && mounted) {
                            setState(() => _isSubmitting = true);
                            final success = await context.read<CategoryProvider>().deleteCategory(widget.initialCategory!.id);
                            if (success && mounted) {
                              Navigator.of(context).pop('deleted');
                              AppSnackbar.success('Category deleted successfully');
                            } else if (mounted) {
                              setState(() => _isSubmitting = false);
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        tooltip: 'Delete Category',
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          foregroundColor: colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              selectedColor,
                              selectedColor.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: selectedColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _saveCategory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: _getContrastColor(selectedColor),
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  widget.initialCategory != null
                                      ? 'Update Category'
                                      : 'Create Category',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: _parseColor(_selectedColor),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedColor = _parseColor(_selectedColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontWeight: FontWeight.bold),
          onFieldSubmitted: onSubmitted,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: selectedColor, size: 20),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: selectedColor, width: 2),
            ),
            errorStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

Color _parseColor(String hexColor) {
  try {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  } catch (e) {
    return Colors.blue;
  }
}

Color _getContrastColor(Color color) {
  // Calculate relative luminance
  final luminance = color.computeLuminance();
  return luminance > 0.5 ? Colors.black : Colors.white;
}
