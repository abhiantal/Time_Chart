// lib/features/personal/task_model/week_task/screens/add_weekly_task_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/features/personal/task_model/week_task/models/week_task_model.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';

import '../../../../../../Authentication/auth_provider.dart';
import '../../../../../../widgets/app_snackbar.dart';
import '../../../../../../widgets/custom_text_field.dart';
import '../../../../../../widgets/logger.dart';
import '../../../../../media_utility/media_picker.dart';
import '../../../../../media_utility/universal_media_service.dart';
import '../../../category_model/widgets/category_picker_popup.dart';
import '../../../shared_widgets/task_form_widgets.dart';
import '../providers/week_task_provider.dart';
import '../widgets/time_slot_manager_dialog.dart';

class AddWeeklyTaskScreen extends StatefulWidget {
  final WeekTaskModel? existingTask;
  const AddWeeklyTaskScreen({super.key, this.existingTask});

  @override
  State<AddWeeklyTaskScreen> createState() => _AddWeeklyTaskScreenState();
}

class _AddWeeklyTaskScreenState extends State<AddWeeklyTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  Set<String> _selectedDays = {};
  String _priority = 'medium';
  CategoryPickerResult? _category;

  String? _mediaUrl;
  File? _localMedia;
  bool _uploading = false;
  bool _submitting = false;

  List<TimeSlot> _slots = [];
  TimeSlot? _selectedSlot;
  bool _loadingSlots = false;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  DateTime _duration = DateTime(0, 1, 1, 1, 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadSlots();
      _prefill();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    setState(() => _loadingSlots = true);
    try {
      final s = await TimeSlotPreferences.loadTimeSlots();
      setState(() {
        _slots = s;
        if (s.isNotEmpty && _selectedSlot == null) {
          _selectedSlot = s.first;
          _syncDuration();
        }
      });
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  void _prefill() {
    final t = widget.existingTask;
    if (t == null) return;
    _nameCtrl.text = t.aboutTask.taskName;
    _descCtrl.text = t.aboutTask.taskDescription ?? '';
    _mediaUrl = t.aboutTask.mediaUrl;
    _selectedDays = t.timeline.taskDays
        .split(',')
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty)
        .map((d) => d[0].toUpperCase() + d.substring(1))
        .toSet();
    _priority = t.indicators.priority;
    _startDate = t.timeline.startingDate;
    _endDate = t.timeline.expectedEndingDate;
    _duration = t.timeline.taskDuration;
    setState(() {});
  }

  void _syncDuration() {
    if (_selectedSlot == null) return;
    final s = _parseTime(_selectedSlot!.startTime);
    final e = _parseTime(_selectedSlot!.endTime);
    if (s == null || e == null) return;
    int diff = (e.hour * 60 + e.minute) - (s.hour * 60 + s.minute);
    if (diff < 0) diff += 1440;
    setState(() => _duration = DateTime(0, 1, 1, diff ~/ 60, diff % 60));
  }

  TimeOfDay? _parseTime(String raw) {
    try {
      raw = raw.trim();
      final isPm = raw.toUpperCase().contains('PM');
      final isAm = raw.toUpperCase().contains('AM');
      final clean = raw
          .toUpperCase()
          .replaceAll('AM', '')
          .replaceAll('PM', '')
          .trim();
      final parts = clean.split(':');
      if (parts.length != 2) return null;
      int h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      if ((isPm || isAm)) {
        if (isPm && h != 12) h += 12;
        if (isAm && h == 12) h = 0;
      }
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingTask != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit weekly task' : 'Add weekly task'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: (_uploading || _submitting) ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                _submitting ? 'Saving...' : (isEdit ? 'Update' : 'Save'),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loadingSlots
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Time slot status ──
                    _SlotStatusBanner(
                      slotCount: _slots.length,
                      onManage: _manageSlots,
                    ),
                    const SizedBox(height: 14),

                                        // ── Category ──
                    TaskFormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TaskSectionHeader(
                            icon: Icons.category_rounded,
                            title: 'Category',
                          ),
                          const SizedBox(height: 12),
                          TaskCategoryTile(
                            selected: _category,
                            categoryFor: 'weekly_task',
                            onSelected: (r) => setState(() => _category = r),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                                        // ── Task info ──
                    TaskFormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TaskSectionHeader(
                            icon: Icons.task_rounded,
                            title: 'Task info',
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            controller: _nameCtrl,
                            label: 'Task name',
                            hint: 'e.g., Morning workout',
                            prefixIcon: Icons.task_alt_rounded,
                            required: true,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Task name is required'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          CustomTextField.multiline(
                            controller: _descCtrl,
                            label: 'Description (optional)',
                            maxLines: 3,
                            maxLength: 500,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                                        // ── Days ──
                    TaskFormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TaskSectionHeader(
                            icon: Icons.event_repeat_rounded,
                            title: 'Scheduled days',
                          ),
                          const SizedBox(height: 12),
                          TaskDaySelector(
                            selected: _selectedDays,
                            onChanged: (v) => setState(() => _selectedDays = v),
                          ),
                          if (_selectedDays.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Select at least one day',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                                        // ── Time slot ──
                    TaskFormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TaskSectionHeader(
                            icon: Icons.schedule_rounded,
                            title: 'Time slot',
                          ),
                          const SizedBox(height: 12),
                          if (_slots.isEmpty)
                            _NoSlotsPrompt(onCreate: _manageSlots)
                          else
                            _SlotList(
                              slots: _slots,
                              selected: _selectedSlot,
                              onSelect: (s) {
                                setState(() => _selectedSlot = s);
                                _syncDuration();
                              },
                              onManage: _manageSlots,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                                        // ── Priority ──
                    TaskFormCard(
                      child: TaskPrioritySelector(
                        value: _priority,
                        onChanged: (v) => setState(() => _priority = v),
                      ),
                    ),
                    const SizedBox(height: 14),

                                        // ── Timeline dates ──
                    TaskFormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TaskSectionHeader(
                            icon: Icons.date_range_rounded,
                            title: 'Timeline',
                          ),
                          const SizedBox(height: 4),
                          TaskDateTile(
                            label: 'Starting date',
                            date: _startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            onPicked: (d) => setState(() => _startDate = d),
                          ),
                          const Divider(height: 8),
                          TaskDateTile(
                            label: 'Expected ending date',
                            date: _endDate,
                            firstDate: _startDate,
                            lastDate: DateTime(2100),
                            onPicked: (d) => setState(() => _endDate = d),
                          ),
                          const Divider(height: 8),
                          InkWell(
                            onTap: _pickDuration,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 20,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Task duration',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    WeekTaskModel.formatDurationHMS(_duration),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                                        // ── Media ──
                    TaskFormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TaskSectionHeader(
                            icon: Icons.photo_library_rounded,
                            title: 'Media (optional)',
                          ),
                          const SizedBox(height: 12),
                          if (_mediaUrl != null)
                            _MediaPreview(
                              url: _mediaUrl!,
                              localFile: _localMedia,
                              onRemove: () => setState(() {
                                _mediaUrl = null;
                                _localMedia = null;
                              }),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: _uploading ? null : _pickMedia,
                              icon: _uploading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.add_photo_alternate_rounded,
                                    ),
                              label: Text(
                                _uploading ? 'Uploading...' : 'Add photo / video',
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    TaskPrimaryButton(
                      label: isEdit ? 'Save changes' : 'Create task',
                      icon: isEdit
                          ? Icons.save_rounded
                          : Icons.add_task_rounded,
                      loading: _submitting,
                      onTap: _submit,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

                      // ── Actions ──

  Future<void> _manageSlots() async {
    await showDialog(
      context: context,
      builder: (_) => TimeSlotManagerDialog(
        timeSlots: _slots,
        onSave: (s) async {
          await TimeSlotPreferences.saveTimeSlots(s);
          await _loadSlots();
          AppSnackbar.success('Time slots updated');
        },
      ),
    );
  }

  Future<void> _pickDuration() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _duration.hour, minute: _duration.minute),
      helpText: 'Set duration (h : m)',
      initialEntryMode: TimePickerEntryMode.inputOnly,
    );
    if (t != null) {
      setState(() => _duration = DateTime(0, 1, 1, t.hour, t.minute));
    }
  }

  Future<void> _pickMedia() async {
    setState(() => _uploading = true);
    try {
      final file = await EnhancedMediaPicker.pickMedia(
        context,
        config: const MediaPickerConfig(
          allowCamera: true,
          allowGallery: true,
          allowImage: true,
          allowVideo: true,
          autoCompress: true,
          imageQuality: 70,
          videoQuality: VideoQuality.LowQuality,
          maxFileSizeMB: 50,
        ),
      );
      if (file == null) return;
      final f = File(file.path);
      final urls = await mediaService.uploadTaskMedia(
        files: [f],
        taskType: 'weekly',
      );
      if (urls.isNotEmpty) {
        setState(() {
          _mediaUrl = urls.first;
          _localMedia = f;
        });
        AppSnackbar.success('Media uploaded');
      }
    } catch (e) {
      AppSnackbar.error('Upload failed');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      AppSnackbar.error('Select at least one day');
      return;
    }
    if (_category == null) {
      AppSnackbar.error('Please select a category');
      return;
    }
    if (_slots.isEmpty) {
      AppSnackbar.error('Create time slots first');
      await _manageSlots();
      return;
    }
    if (_selectedSlot == null) {
      AppSnackbar.error('Please select a time slot');
      return;
    }

    setState(() => _submitting = true);
    try {
      final start = _parseTime(_selectedSlot!.startTime)!;
      final end = _parseTime(_selectedSlot!.endTime)!;
      final now = DateTime.now();
      final startDt = DateTime(
        now.year,
        now.month,
        now.day,
        start.hour,
        start.minute,
      );
      final endDt = DateTime(
        now.year,
        now.month,
        now.day,
        end.hour,
        end.minute,
      );

      final provider = context.read<WeekTaskProvider>();
      bool ok;

      if (widget.existingTask != null) {
        final updated = widget.existingTask!.copyWith(
          aboutTask: AboutTask(
            taskName: _nameCtrl.text.trim(),
            taskDescription: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            mediaUrl: _mediaUrl,
          ),
          indicators: Indicators(
            status: widget.existingTask!.indicators.status,
            priority: _priority,
          ),
          timeline: TaskTimeline(
            taskDays: _selectedDays.join(', '),
            startingDate: _startDate,
            expectedEndingDate: _endDate,
            startingTime: startDt,
            endingTime: endDt,
            taskDuration: _duration,
          ),
        );
        ok = await provider.updateTask(updated);
      } else {
        final userId = context.read<AuthProvider>().currentUser?.id;
        if (userId == null) throw Exception('Not authenticated');
        final task = WeekTaskModel(
          id: const Uuid().v4(),
          userId: userId,
          categoryId: _category!.categoryId,
          categoryType: _category!.categoryType,
          subTypes: _category!.subType ?? '',
          aboutTask: AboutTask(
            taskName: _nameCtrl.text.trim(),
            taskDescription: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            mediaUrl: _mediaUrl,
          ),
          indicators: Indicators(status: 'pending', priority: _priority),
          timeline: TaskTimeline(
            taskDays: _selectedDays.join(', '),
            startingDate: _startDate,
            expectedEndingDate: _endDate,
            startingTime: startDt,
            endingTime: endDt,
            taskDuration: _duration,
          ),
          feedback: WeekTaskFeedback(dailyProgress: const []),
          summary: WeeklySummary.empty,
          socialInfo: const SocialInfo(isPosted: false),
          shareInfo: const ShareInfo(isShare: false),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        ok = await provider.createTask(task);
      }

      if (ok && mounted) {
        AppSnackbar.success(
          widget.existingTask != null ? 'Task updated!' : 'Task created!',
        );
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      logE('Submit weekly task error', error: e);
      AppSnackbar.error('Failed to save task');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

// ── File-local sub-widgets ──────────────────────────────────────────────────────

class _SlotStatusBanner extends StatelessWidget {
  final int slotCount;
  final VoidCallback onManage;
  const _SlotStatusBanner({required this.slotCount, required this.onManage});

  @override
  Widget build(BuildContext context) {
    final hasSlots = slotCount > 0;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: hasSlots
            ? cs.primaryContainer.withValues(alpha: 0.4)
            : cs.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasSlots
              ? cs.primary.withValues(alpha: 0.3)
              : cs.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasSlots ? Icons.check_circle_outline : Icons.warning_outlined,
            color: hasSlots ? cs.primary : cs.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasSlots
                  ? '$slotCount slot${slotCount != 1 ? 's' : ''} configured'
                  : 'No time slots - create some first',
              style: TextStyle(
                color: hasSlots ? cs.onPrimaryContainer : cs.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, size: 20),
            color: hasSlots ? cs.primary : cs.error,
            onPressed: onManage,
            tooltip: 'Manage slots',
          ),
        ],
      ),
    );
  }
}

class _NoSlotsPrompt extends StatelessWidget {
  final VoidCallback onCreate;
  const _NoSlotsPrompt({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Text('No slots available. Create at least one.'),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: const Text('Create time slots'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }
}

class _SlotList extends StatelessWidget {
  final List<TimeSlot> slots;
  final TimeSlot? selected;
  final ValueChanged<TimeSlot> onSelect;
  final VoidCallback onManage;
  const _SlotList({
    required this.slots,
    required this.selected,
    required this.onSelect,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: onManage,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add new slot'),
        ),
        const SizedBox(height: 10),
        ...slots.asMap().entries.map((e) {
          final s = e.value;
          final isOn = selected == s;
          return GestureDetector(
            onTap: () => onSelect(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isOn ? cs.primary.withValues(alpha: 0.12) : cs.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isOn ? cs.primary : cs.outline.withValues(alpha: 0.3),
                  width: isOn ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: isOn ? cs.primary : cs.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${s.startTime} - ${s.endTime}',
                      style: TextStyle(
                        fontWeight: isOn ? FontWeight.bold : FontWeight.normal,
                        color: isOn ? cs.primary : cs.onSurface,
                      ),
                    ),
                  ),
                  if (isOn)
                    Icon(
                      Icons.check_circle_rounded,
                      color: cs.primary,
                      size: 18,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _MediaPreview extends StatelessWidget {
  final String url;
  final File? localFile;
  final VoidCallback onRemove;
  const _MediaPreview({
    required this.url,
    required this.localFile,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: localFile != null
              ? Image.file(
                  localFile!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Image.network(
                  url,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
