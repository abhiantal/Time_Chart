// lib/features/day_task/screens_widgets/task_form_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/features/personal/category_model/providers/category_provider.dart';
import 'package:the_time_chart/features/personal/category_model/widgets/category_picker_popup.dart';
import '../../../../../../widgets/app_snackbar.dart';
import '../../../../../../widgets/custom_text_field.dart';
import '../../../../../../widgets/logger.dart';

import '../models/day_task_model.dart';
import '../providers/day_task_provider.dart';
import 'package:the_time_chart/user_settings/providers/settings_provider.dart';

class TaskFormBottomSheet extends StatefulWidget {
  final DayTaskModel? task; // null = create new, non-null = edit existing

  const TaskFormBottomSheet({super.key, this.task});

  @override
  State<TaskFormBottomSheet> createState() => _TaskFormBottomSheetState();

  /// Show for creating new task
  static Future<void> showCreateTask(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => const TaskFormBottomSheet(),
    ).then((_) {});
  }

  /// Show for editing existing task
  static Future<void> showEditTask(BuildContext context, DayTaskModel task) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => TaskFormBottomSheet(task: task),
    ).then((_) {});
  }
}

class _TaskFormBottomSheetState extends State<TaskFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _selectedPriority;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isSubmitting = false;

  // Category
  CategoryPickerResult? _selectedCategoryResult;

  bool get _isEditMode => widget.task != null;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
    _loadCategories();
  }

  void _loadCategories() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategoriesByType('day_task');
    });
  }

  void _initializeFormData() {
    if (_isEditMode) {
      // Edit mode - populate with existing data
      _nameController = TextEditingController(
        text: widget.task!.aboutTask.taskName,
      );
      _descriptionController = TextEditingController(
        text: widget.task!.aboutTask.taskDescription ?? '',
      );
      _selectedPriority = widget.task!.indicators.priority.toLowerCase();
      _selectedDate = DateTime.parse(widget.task!.timeline.taskDate);
      _startTime = TimeOfDay.fromDateTime(widget.task!.timeline.startingTime);
      _endTime = TimeOfDay.fromDateTime(widget.task!.timeline.endingTime);

      // TODO: Initialize category_model from task data if you have category_model fields in DayTaskModel
      // _selectedCategoryResult = ...
    } else {
      // Create mode - empty/default values
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();

      // Load default priority from settings
      final settings = context.read<SettingsProvider>().settings;
      if (settings != null) {
        _selectedPriority = settings.tasks.defaultPriority.name;
      } else {
        _selectedPriority = 'medium';
      }

      _selectedDate = DateTime.now();
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay(
        hour: TimeOfDay.now().hour + 1,
        minute: TimeOfDay.now().minute,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectCategory() async {
    final result = await CategoryPickerPopup.show(
      context: context,
      categoryFor: 'day_task',
      initialSelection: _selectedCategoryResult,
      showSubTypeSelector: true,
      allowCreate: true,
    );

    if (result != null) {
      setState(() {
        _selectedCategoryResult = result;
      });
    }
  }

  Color _parseColor(String hexColor) {
    try {
      final hexCode = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return Theme.of(context).colorScheme.primary;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate category_model selection
    if (_selectedCategoryResult == null) {
      snackbarService.showError(
        'Category Required',
        description: 'Please select a category_model for this task',
      );
      return;
    }

    // Validate time range
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime) ||
        endDateTime.isAtSameMomentAs(startDateTime)) {
      snackbarService.showError(
        'Invalid Time Range',
        description: 'End time must be after start time',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_isEditMode) {
        await _updateTask();
      } else {
        await _createTask();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _createTask() async {
    try {
      logI('📝 Creating new task: ${_nameController.text.trim()}');

      snackbarService.showLoading('Creating task...');

      final provider = context.read<DayTaskProvider>();

      final success = await provider.createTask(
        taskName: _nameController.text.trim(),
        taskDescription: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        taskDate: _selectedDate,
        startTime: _startTime,
        endTime: _endTime,
        priority: _selectedPriority,
        // Add category_model information
        categoryId: _selectedCategoryResult!.categoryId,
        categoryType: _selectedCategoryResult!.categoryType,
        subTypes: _selectedCategoryResult!.subType,
      );

      snackbarService.hideLoading();

      if (!mounted) return;

      if (success) {
        logI('✅ Task created successfully');
        Navigator.pop(context);
        snackbarService.showSuccess(
          '✅ Task Created!',
          description: _nameController.text.trim(),
        );
      } else {
        throw Exception(provider.error ?? 'Failed to create task');
      }
    } catch (e, stack) {
      logE('❌ Error creating task', error: e, stackTrace: stack);
      snackbarService.hideLoading();
      snackbarService.showError(
        'Create Failed',
        description: e.toString(),
      );
    }
  }

  Future<void> _updateTask() async {
    try {
      logI('✏️ Updating task: ${widget.task!.id}');

      snackbarService.showLoading('Updating task...');

      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final updatedTask = widget.task!.copyWith(
        aboutTask: AboutTask(
          taskName: _nameController.text.trim(),
          taskDescription: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        ),
        indicators: Indicators(
          status: widget.task!.indicators.status,
          priority: _selectedPriority,
        ),
        timeline: Timeline(
          taskDate: _selectedDate.toIso8601String().split('T')[0],
          startingTime: startDateTime,
          endingTime: endDateTime,
          completionTime: widget.task!.timeline.completionTime,
          overdue: widget.task!.timeline.overdue,
          isUnspecified: widget.task!.timeline.isUnspecified,
        ),
        updatedAt: DateTime.now(),
        // TODO: Add category_model fields if your DayTaskModel supports them
      );

      final provider = context.read<DayTaskProvider>();
      final success = await provider.updateTask(updatedTask);

      snackbarService.hideLoading();

      if (!mounted) return;

      if (success) {
        logI('✅ Task updated successfully');
        Navigator.pop(context);
        snackbarService.showSuccess(
          '✅ Task Updated!',
          description: _nameController.text.trim(),
        );
      } else {
        throw Exception(provider.error ?? 'Failed to update task');
      }
    } catch (e, stack) {
      logE('❌ Error updating task', error: e, stackTrace: stack);
      snackbarService.hideLoading();
      snackbarService.showError(
        'Update Failed',
        description: e.toString(),
      );
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (time != null) {
      setState(() => _startTime = time);
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(context: context, initialTime: _endTime);

    if (time != null) {
      setState(() => _endTime = time);
    }
  }

  Widget _buildModernPrioritySelector(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = const [
      ('low', Colors.green, 'Low', Icons.flag_outlined),
      ('medium', Colors.blue, 'Medium', Icons.flag),
      ('high', Colors.orange, 'High', Icons.flag),
      ('urgent', Colors.red, 'Urgent', Icons.priority_high_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: options
            .map(
              (opt) => Expanded(
                child: _buildPriorityChip(
                  value: opt.$1,
                  color: opt.$2,
                  label: opt.$3,
                  icon: opt.$4,
                  theme: theme,
                  isDark: isDark,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPriorityChip({
    required String value,
    required Color color,
    required String label,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
  }) {
    final isSelected = _selectedPriority == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPriority = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: !isSelected
              ? (isDark ? Colors.transparent : Colors.white)
              : null,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : Border.all(
                  color: theme.dividerColor.withOpacity(0.1),
                  width: 1.5,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color.withOpacity(0.7),
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isEditMode
                            ? [colorScheme.secondary, colorScheme.tertiary]
                            : [colorScheme.primary, colorScheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_isEditMode
                                      ? colorScheme.secondary
                                      : colorScheme.primary)
                                  .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isEditMode ? Icons.edit_rounded : Icons.add_task_rounded,
                      color: colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditMode ? 'Edit Task' : 'Create New Task',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isEditMode
                              ? 'Update task details'
                              : 'Add a new task to your schedule',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: colorScheme.outlineVariant),

            // Form Content
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    CustomTextField.singleline(
                      controller: _nameController,
                      label: 'Task Name',
                      hint: 'Enter task name',
                      maxLength: 300,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter task name';
                        }
                        if (value.trim().length < 3) {
                          return 'Task name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Task Description
                    CustomTextField.multiline(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Enter task description (optional)',
                      maxLines: 4,
                      maxLength: 500,
                    ),

                    const SizedBox(height: 24),

                    // Category Selection
                    Text(
                      'Category',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectCategory,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedCategoryResult != null
                              ? _parseColor(
                                  _selectedCategoryResult!.categoryColor,
                                ).withOpacity(0.1)
                              : colorScheme.surfaceContainerHighest.withOpacity(
                                  0.5,
                                ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedCategoryResult != null
                                ? _parseColor(
                                    _selectedCategoryResult!.categoryColor,
                                  )
                                : colorScheme.outline.withOpacity(0.3),
                            width: _selectedCategoryResult != null ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _selectedCategoryResult != null
                                    ? _parseColor(
                                        _selectedCategoryResult!.categoryColor,
                                      ).withOpacity(0.2)
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _selectedCategoryResult?.categoryIcon ?? '📁',
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedCategoryResult != null
                                        ? _selectedCategoryResult!.categoryType
                                        : 'Select Category',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _selectedCategoryResult != null
                                          ? _parseColor(
                                              _selectedCategoryResult!
                                                  .categoryColor,
                                            )
                                          : colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (_selectedCategoryResult?.subType != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _parseColor(
                                          _selectedCategoryResult!
                                              .categoryColor,
                                        ).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _parseColor(
                                            _selectedCategoryResult!
                                                .categoryColor,
                                          ).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        _selectedCategoryResult!.subType!,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: _parseColor(
                                            _selectedCategoryResult!
                                                .categoryColor,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else
                                    Text(
                                      'Tap to select category_model',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Arrow
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Priority Section
                    Text(
                      'Priority',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildModernPrioritySelector(context),

                    const SizedBox(height: 24),

                    // Schedule Section
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Schedule',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Date Picker
                    _buildDateTimeTile(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value:
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      onTap: _selectDate,
                      colorScheme: colorScheme,
                    ),

                    const SizedBox(height: 8),

                    // Start Time Picker
                    _buildDateTimeTile(
                      icon: Icons.access_time_rounded,
                      label: 'Start Time',
                      value: _startTime.format(context),
                      onTap: _selectStartTime,
                      colorScheme: colorScheme,
                    ),

                    const SizedBox(height: 8),

                    // End Time Picker
                    _buildDateTimeTile(
                      icon: Icons.access_time_filled_rounded,
                      label: 'End Time',
                      value: _endTime.format(context),
                      onTap: _selectEndTime,
                      colorScheme: colorScheme,
                    ),

                    const SizedBox(height: 24),

                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isEditMode
                                  ? 'Changes will be saved immediately'
                                  : 'Task will be created with Pending status',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
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

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      icon: _isSubmitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : Icon(
                              _isEditMode
                                  ? Icons.save_rounded
                                  : Icons.add_task_rounded,
                            ),
                      label: Text(
                        _isSubmitting
                            ? (_isEditMode ? 'Updating...' : 'Creating...')
                            : (_isEditMode ? 'Saves Changes' : 'Create Task'),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _buildDateTimeTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
