// lib/features/long_goals/message_bubbles/goal_filter_popup.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Filter model to hold all filter values
class GoalFilterModel {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category;
  final String? priority;
  final String? status;
  final String searchQuery;

  const GoalFilterModel({
    this.startDate,
    this.endDate,
    this.category,
    this.priority,
    this.status,
    this.searchQuery = '',
  });

  GoalFilterModel copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? priority,
    String? status,
    String? searchQuery,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearCategory = false,
    bool clearPriority = false,
    bool clearStatus = false,
  }) {
    return GoalFilterModel(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      category: clearCategory ? null : (category ?? this.category),
      priority: clearPriority ? null : (priority ?? this.priority),
      status: clearStatus ? null : (status ?? this.status),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasActiveFilters =>
      startDate != null ||
      endDate != null ||
      category != null ||
      priority != null ||
      status != null ||
      searchQuery.isNotEmpty;

  int get activeFilterCount {
    int count = 0;
    if (startDate != null && endDate != null) count++;
    if (category != null) count++;
    if (priority != null) count++;
    if (status != null) count++;
    if (searchQuery.isNotEmpty) count++;
    return count;
  }

  static const GoalFilterModel empty = GoalFilterModel();
}

/// Show the filter popup
Future<GoalFilterModel?> showGoalFilterPopup({
  required BuildContext context,
  required GoalFilterModel currentFilter,
}) async {
  return showModalBottomSheet<GoalFilterModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => GoalFilterPopup(initialFilter: currentFilter),
  );
}

class GoalFilterPopup extends StatefulWidget {
  final GoalFilterModel initialFilter;

  const GoalFilterPopup({super.key, required this.initialFilter});

  @override
  State<GoalFilterPopup> createState() => _GoalFilterPopupState();
}

class _GoalFilterPopupState extends State<GoalFilterPopup>
    with SingleTickerProviderStateMixin {
  late GoalFilterModel _filter;
  late TextEditingController _searchController;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Filter options
  static const List<String> _categories = [
    'Development',
    'Design',
    'Business',
    'Health',
    'Education',
    'Personal',
    'Finance',
    'Career',
  ];

  static const List<String> _priorities = ['low', 'normal', 'high', 'urgent'];

  static const List<String> _statuses = [
    'pending',
    'inProgress',
    'completed',
    'onHold',
    'abandoned',
  ];

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _searchController = TextEditingController(text: _filter.searchQuery);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: _filter.startDate ?? now.subtract(const Duration(days: 30)),
      end: _filter.endDate ?? now.add(const Duration(days: 30)),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365 * 5)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: Theme.of(context).colorScheme),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _filter = _filter.copyWith(
          startDate: picked.start,
          endDate: picked.end,
        );
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _filter = _filter.copyWith(clearStartDate: true, clearEndDate: true);
    });
  }

  void _applyFilters() {
    Navigator.pop(
      context,
      _filter.copyWith(searchQuery: _searchController.text.trim()),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _filter = GoalFilterModel.empty;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Container(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.85),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(theme),
            _buildHeader(theme),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: bottomPadding + 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchSection(theme),
                    _buildDateRangeSection(theme),
                    _buildCategorySection(theme),
                    _buildPrioritySection(theme),
                    _buildStatusSection(theme),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.filter_list_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Goals',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_filter.hasActiveFilters)
                  Text(
                    '${_filter.activeFilterCount} filter${_filter.activeFilterCount > 1 ? 's' : ''} active',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          if (_filter.hasActiveFilters)
            TextButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(theme, 'Search', Icons.search),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by goal title or keyword...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 
                0.5,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSection(ThemeData theme) {
    final hasDateFilter = _filter.startDate != null && _filter.endDate != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(theme, 'Date Range', Icons.date_range),
          const SizedBox(height: 12),
          InkWell(
            onTap: _selectDateRange,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasDateFilter
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 
                        0.5,
                      ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasDateFilter
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: hasDateFilter ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: hasDateFilter
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasDateFilter
                              ? 'Selected Range'
                              : 'Select Date Range',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasDateFilter
                              ? '${DateFormat('MMM dd, yyyy').format(_filter.startDate!)} - ${DateFormat('MMM dd, yyyy').format(_filter.endDate!)}'
                              : 'Tap to select dates',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: hasDateFilter
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        if (hasDateFilter)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${_filter.endDate!.difference(_filter.startDate!).inDays + 1} days',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (hasDateFilter)
                    IconButton(
                      icon: Icon(Icons.close, color: theme.colorScheme.error),
                      onPressed: _clearDateRange,
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(ThemeData theme) {
    return _buildChipSection(
      theme: theme,
      title: 'Category',
      icon: Icons.category_rounded,
      options: _categories,
      selected: _filter.category,
      onSelect: (value) {
        setState(() {
          _filter = _filter.copyWith(
            category: value,
            clearCategory: value == null,
          );
        });
      },
      chipColor: theme.colorScheme.secondaryContainer,
      selectedColor: theme.colorScheme.secondary,
    );
  }

  Widget _buildPrioritySection(ThemeData theme) {
    return _buildChipSection(
      theme: theme,
      title: 'Priority',
      icon: Icons.flag_rounded,
      options: _priorities,
      selected: _filter.priority,
      onSelect: (value) {
        setState(() {
          _filter = _filter.copyWith(
            priority: value,
            clearPriority: value == null,
          );
        });
      },
      chipBuilder: (option, isSelected) {
        final color = _getPriorityColor(option);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.2)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? color
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.check, size: 16, color: color),
                ),
              Text(
                option.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusSection(ThemeData theme) {
    return _buildChipSection(
      theme: theme,
      title: 'Status',
      icon: Icons.timeline_rounded,
      options: _statuses,
      selected: _filter.status,
      onSelect: (value) {
        setState(() {
          _filter = _filter.copyWith(status: value, clearStatus: value == null);
        });
      },
      chipBuilder: (option, isSelected) {
        final (color, icon) = _getStatusStyle(option);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.2)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? color
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                _formatStatusLabel(option),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChipSection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required List<String> options,
    required String? selected,
    required Function(String?) onSelect,
    Color? chipColor,
    Color? selectedColor,
    Widget Function(String, bool)? chipBuilder,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(theme, title, icon),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((option) {
              final isSelected = selected == option;

              if (chipBuilder != null) {
                return GestureDetector(
                  onTap: () => onSelect(isSelected ? null : option),
                  child: chipBuilder(option, isSelected),
                );
              }

              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (value) => onSelect(value ? option : null),
                selectedColor: (selectedColor ?? theme.colorScheme.primary)
                    .withValues(alpha: 0.2),
                checkmarkColor: selectedColor ?? theme.colorScheme.primary,
                backgroundColor:
                    chipColor?.withValues(alpha: 0.3) ??
                    theme.colorScheme.surfaceContainerHighest,
                side: BorderSide(
                  color: isSelected
                      ? (selectedColor ?? theme.colorScheme.primary)
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
                labelStyle: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? (selectedColor ?? theme.colorScheme.primary)
                      : theme.colorScheme.onSurface,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _applyFilters,
                icon: const Icon(Icons.check),
                label: Text(
                  _filter.hasActiveFilters
                      ? 'Apply ${_filter.activeFilterCount} Filter${_filter.activeFilterCount > 1 ? 's' : ''}'
                      : 'Apply Filters',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'normal':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  (Color, IconData) _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return (Colors.green, Icons.check_circle);
      case 'inprogress':
        return (Colors.blue, Icons.timelapse);
      case 'onhold':
        return (Colors.orange, Icons.pause_circle);
      case 'abandoned':
        return (Colors.red, Icons.cancel);
      case 'pending':
      default:
        return (Colors.grey, Icons.pending);
    }
  }

  String _formatStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'inprogress':
        return 'In Progress';
      case 'onhold':
        return 'On Hold';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }
}
