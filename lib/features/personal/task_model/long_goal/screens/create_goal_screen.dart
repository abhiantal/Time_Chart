// lib/features/personal/task_model/long_goal/screens/create_goal_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../../widgets/app_snackbar.dart';
import '../../../../../../widgets/custom_text_field.dart';
import '../../../../../../widgets/logger.dart';
import '../../../category_model/models/category_model.dart';
import '../../../category_model/providers/category_provider.dart';
import '../../../category_model/widgets/category_picker_popup.dart';
import '../../../shared_widgets/task_form_widgets.dart';
import '../models/long_goal_model.dart';
import '../providers/long_goals_provider.dart';
import '../services/long_goal_ai_service.dart';

class CreateLongGoalScreen extends StatefulWidget {
  final LongGoalModel? initialGoal;
  const CreateLongGoalScreen({super.key, this.initialGoal});

  @override
  State<CreateLongGoalScreen> createState() => _CreateLongGoalScreenState();
}

class _CreateLongGoalScreenState extends State<CreateLongGoalScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _needCtrl = TextEditingController();
  final _motivationCtrl = TextEditingController();
  final _outcomeCtrl = TextEditingController();

  late TabController _tabs;

  bool _flexible = false;
  DateTime? _startDate;
  DateTime? _endDate;
  Set<String> _workDays = {};
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  CategoryPickerResult? _category;
  String _priority = 'medium';

  List<WeeklyGoalInput> _weeklyGoals = [];
  bool _generatingGoals = false;
  bool _saving = false;

  bool get _isEdit => widget.initialGoal != null;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) await context.read<LongGoalsProvider>().initialize(uid);
      await context.read<CategoryProvider>().loadCategoriesByType('long_goal');
      _prefill();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _titleCtrl.dispose();
    _needCtrl.dispose();
    _motivationCtrl.dispose();
    _outcomeCtrl.dispose();
    super.dispose();
  }

  void _prefill() {
    final g = widget.initialGoal;
    if (g == null) return;
    _titleCtrl.text = g.title;
    _needCtrl.text = g.description.need;
    _motivationCtrl.text = g.description.motivation;
    _outcomeCtrl.text = g.description.outcome;
    _flexible = g.timeline.isUnspecified;
    _startDate = g.timeline.startDate;
    _endDate = g.timeline.endDate;
    _workDays = Set.from(g.timeline.workSchedule.workDays);
    final slot = g.timeline.workSchedule.preferredTimeSlot;
    if (slot != null) {
      _startTime = TimeOfDay(
          hour: slot.startingTime.hour, minute: slot.startingTime.minute);
      _endTime = TimeOfDay(
          hour: slot.endingTime.hour, minute: slot.endingTime.minute);
    }
    _priority = g.indicators.priority;
    _weeklyGoals = g.indicators.weeklyPlans.map((p) {
      final n = int.tryParse(p.weekId.replaceAll('w', '')) ?? 1;
      return WeeklyGoalInput(
          weekNumber: n, weeklyGoal: p.weeklyGoal, mood: p.mood.toLowerCase());
    }).toList();
    setState(() {});
  }

  int get _weeks {
    if (_startDate == null || _endDate == null) return 0;
    return (_endDate!.difference(_startDate!).inDays / 7).round();
  }

  int get _hoursPerDay {
    if (_startTime == null || _endTime == null) return 0;
    int diff = (_endTime!.hour * 60 + _endTime!.minute) -
        (_startTime!.hour * 60 + _startTime!.minute);
    if (diff < 0) diff += 1440;
    return (diff / 60).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit goal' : 'Create goal'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Info'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Timeline'),
            Tab(icon: Icon(Icons.list_alt), text: 'Weekly goals'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _InfoTab(
                    titleCtrl: _titleCtrl,
                    needCtrl: _needCtrl,
                    motivationCtrl: _motivationCtrl,
                    outcomeCtrl: _outcomeCtrl,
                    category: _category,
                    priority: _priority,
                    onCategorySelected: (r) => setState(() => _category = r),
                    onPriorityChanged: (v) => setState(() => _priority = v),
                  ),
                  _TimelineTab(
                    flexible: _flexible,
                    startDate: _startDate,
                    endDate: _endDate,
                    workDays: _workDays,
                    startTime: _startTime,
                    endTime: _endTime,
                    weeks: _weeks,
                    hoursPerDay: _hoursPerDay,
                    onFlexibleChanged: (v) => setState(() => _flexible = v),
                    onStartDatePicked: (d) => setState(() {
                      _startDate = d;
                      if (_endDate != null && _endDate!.isBefore(d)) {
                        _endDate = d.add(const Duration(days: 7));
                      }
                    }),
                    onEndDatePicked: (d) => setState(() => _endDate = d),
                    onWorkDaysChanged: (v) => setState(() => _workDays = v),
                    onStartTimePicked: (t) => setState(() => _startTime = t),
                    onEndTimePicked: (t) => setState(() => _endTime = t),
                  ),
                  _WeeklyGoalsTab(
                    goals: _weeklyGoals,
                    generating: _generatingGoals,
                    onGenerate: _generateWeeklyGoals,
                    onClear: () => setState(() => _weeklyGoals.clear()),
                    onRemove: (i) =>
                        setState(() => _weeklyGoals.removeAt(i)),
                    onGoalChanged: (i, g) =>
                        setState(() => _weeklyGoals[i] = g),
                  ),
                ],
              ),
            ),
            _BottomBar(
              tabController: _tabs,
              saving: _saving,
              isEdit: _isEdit,
              onSubmit: _isEdit ? _save : _create,
            ),
          ],
        ),
      ),
    );
  }

  // ── Validation helpers ─────────────────────────────────────────────────────

  bool _validateBasic() {
    if (!_formKey.currentState!.validate()) {
      _tabs.animateTo(0);
      return false;
    }
    if (_category == null) {
      AppSnackbar.warning('Please select a category');
      _tabs.animateTo(0);
      return false;
    }
    return true;
  }

  bool _validateTimeline() {
    if (_flexible) return true;
    if (_startDate == null || _endDate == null) {
      AppSnackbar.warning('Please select start and end dates');
      _tabs.animateTo(1);
      return false;
    }
    if (_workDays.isEmpty) {
      AppSnackbar.warning('Select at least one work day');
      _tabs.animateTo(1);
      return false;
    }
    return true;
  }

  // ── Generate weekly goals ──────────────────────────────────────────────────

  Future<void> _generateWeeklyGoals() async {
    if (!_validateBasic() || !_validateTimeline()) return;
    setState(() => _generatingGoals = true);
    try {
      final ai = LongGoalAIService();
      final uid = Supabase.instance.client.auth.currentUser!.id;
      final generated = <WeeklyGoalInput>[];
      for (int i = 0; i < _weeks; i++) {
        final res = await ai.generateWeeklyGoal(
          userId: uid,
          goalTitle: _titleCtrl.text.trim(),
          need: _needCtrl.text.trim(),
          motivation: _motivationCtrl.text.trim(),
          outcome: _outcomeCtrl.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          workDays: _workDays.toList(),
          hoursPerDay: _hoursPerDay,
          weekNumber: i + 1,
        );
        if (res != null) {
          generated.add(WeeklyGoalInput(
            weekNumber: i + 1,
            weeklyGoal: res['weekly_goal'] ?? 'Week ${i + 1} goal',
            mood: (res['mood'] ?? 'motivated').toString().toLowerCase(),
          ));
        }
      }
      setState(() => _weeklyGoals = generated);
      AppSnackbar.success('Generated ${generated.length} weekly goals');
    } catch (e) {
      AppSnackbar.error('Generation failed: $e');
    } finally {
      if (mounted) setState(() => _generatingGoals = false);
    }
  }

  // ── Build common params ────────────────────────────────────────────────────

  (DateTime, DateTime, List<String>, DateTime?, DateTime?) _resolvedTimeline() {
    final start = _startDate ?? DateTime.now();
    final end = _endDate ?? start.add(const Duration(days: 90));
    final days = _workDays.isNotEmpty
        ? _workDays.toList()
        : ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    DateTime? startDt, endDt;
    if (_startTime != null && _endTime != null) {
      startDt = DateTime(start.year, start.month, start.day,
          _startTime!.hour, _startTime!.minute);
      endDt = DateTime(start.year, start.month, start.day,
          _endTime!.hour, _endTime!.minute);
    } else {
      startDt =
          DateTime(start.year, start.month, start.day, 9, 0);
      endDt =
          DateTime(start.year, start.month, start.day, 17, 0);
    }
    return (start, end, days, startDt, endDt);
  }

  // ── Create ─────────────────────────────────────────────────────────────────

  Future<void> _create() async {
    if (_weeklyGoals.isEmpty && !_flexible) {
      final go = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No weekly goals'),
          content: const Text(
              'Create without weekly plans? You can generate them later.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Generate first')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue')),
          ],
        ),
      );
      if (go != true) {
        _tabs.animateTo(2);
        return;
      }
    }
    if (!_validateBasic() || !_validateTimeline()) return;

    setState(() => _saving = true);
    try {
      final (start, end, days, startDt, endDt) = _resolvedTimeline();
      final plans = _weeklyGoals
          .map((g) => WeeklyPlan(
          weekId: 'w${g.weekNumber}',
          weeklyGoal: g.weeklyGoal,
          mood: g.mood,
          isCompleted: false))
          .toList();

      final created = await context.read<LongGoalsProvider>().createGoal(
        title: _titleCtrl.text.trim(),
        need: _needCtrl.text.trim(),
        motivation: _motivationCtrl.text.trim(),
        outcome: _outcomeCtrl.text.trim(),
        startDate: start,
        endDate: end,
        workDays: days,
        hoursPerDay: _hoursPerDay > 0 ? _hoursPerDay : 8,
        preferredStartTime: start,
        preferredEndTime: end,
        categoryId: _category!.categoryId,
        categoryType: _category!.categoryType,
        subTypes: _category!.subType,
        priority: _priority,
        weeklyGoals: plans,
      );

      if (created != null && mounted) {
        AppSnackbar.success('Goal created with ${plans.length} weekly plans!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      logE('Create goal error', error: e);
      AppSnackbar.error('Failed to create goal');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Save (edit) ────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_validateBasic() || !_validateTimeline()) return;
    setState(() => _saving = true);
    try {
      final (start, end, days, startDt, endDt) = _resolvedTimeline();
      final g = widget.initialGoal!;
      final existingById = {for (var p in g.indicators.weeklyPlans) p.weekId: p};
      final plans = _weeklyGoals.map((input) {
        final id = 'w${input.weekNumber}';
        final old = existingById[id];
        return old != null
            ? old.copyWith(weeklyGoal: input.weeklyGoal, mood: input.mood)
            : WeeklyPlan(
            weekId: id,
            weeklyGoal: input.weeklyGoal,
            mood: input.mood,
            isCompleted: false);
      }).toList();

      final saved = await context.read<LongGoalsProvider>().updateGoalDetails(
        goalId: g.id,
        title: _titleCtrl.text.trim(),
        need: _needCtrl.text.trim(),
        motivation: _motivationCtrl.text.trim(),
        outcome: _outcomeCtrl.text.trim(),
        startDate: _flexible ? null : start,
        endDate: _flexible ? null : end,
        workDays: _flexible ? [] : days,
        hoursPerDay: _hoursPerDay > 0 ? _hoursPerDay : null,
        preferredStartTime: startDt,
        preferredEndTime: endDt,
        categoryId: _category!.categoryId,
        categoryType: _category!.categoryType,
        subTypes: _category!.subType,
        priority: _priority,
        isUnspecified: _flexible,
        weeklyGoals: plans,
      );

      if (saved != null && mounted) {
        AppSnackbar.success('Changes saved');
        Navigator.pop(context, true);
      }
    } catch (e) {
      AppSnackbar.error('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Tab widgets ───────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController needCtrl;
  final TextEditingController motivationCtrl;
  final TextEditingController outcomeCtrl;
  final CategoryPickerResult? category;
  final String priority;
  final ValueChanged<CategoryPickerResult> onCategorySelected;
  final ValueChanged<String> onPriorityChanged;

  const _InfoTab({
    required this.titleCtrl,
    required this.needCtrl,
    required this.motivationCtrl,
    required this.outcomeCtrl,
    required this.category,
    required this.priority,
    required this.onCategorySelected,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: titleCtrl,
            label: 'Goal title',
            hint: 'e.g., Build a personal portfolio',
            prefixIcon: Icons.flag_outlined,
            required: true,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Title is required';
              if (v.trim().length < 5) return 'At least 5 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TaskFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TaskSectionHeader(
                    icon: Icons.category_rounded, title: 'Category'),
                const SizedBox(height: 12),
                TaskCategoryTile(
                  selected: category,
                  categoryFor: 'long_goal',
                  onSelected: onCategorySelected,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField.multiline(
            controller: needCtrl,
            label: 'What do you need?',
            hint: 'e.g., An online portfolio to showcase my work',
            maxLines: 3,
            maxLength: 300,
          ),
          const SizedBox(height: 12),
          CustomTextField.multiline(
            controller: motivationCtrl,
            label: 'Why is this important?',
            hint: 'e.g., To get freelance clients',
            maxLines: 3,
            maxLength: 300,
          ),
          const SizedBox(height: 12),
          CustomTextField.multiline(
            controller: outcomeCtrl,
            label: 'Expected outcome',
            hint: 'e.g., A fully functional website',
            maxLines: 3,
            maxLength: 300,
          ),
          const SizedBox(height: 16),
          TaskFormCard(
            child: TaskPrioritySelector(
                value: priority, onChanged: onPriorityChanged),
          ),
        ],
      ),
    );
  }
}

class _TimelineTab extends StatelessWidget {
  final bool flexible;
  final DateTime? startDate;
  final DateTime? endDate;
  final Set<String> workDays;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final int weeks;
  final int hoursPerDay;
  final ValueChanged<bool> onFlexibleChanged;
  final ValueChanged<DateTime> onStartDatePicked;
  final ValueChanged<DateTime> onEndDatePicked;
  final ValueChanged<Set<String>> onWorkDaysChanged;
  final ValueChanged<TimeOfDay> onStartTimePicked;
  final ValueChanged<TimeOfDay> onEndTimePicked;

  const _TimelineTab({
    required this.flexible,
    required this.startDate,
    required this.endDate,
    required this.workDays,
    required this.startTime,
    required this.endTime,
    required this.weeks,
    required this.hoursPerDay,
    required this.onFlexibleChanged,
    required this.onStartDatePicked,
    required this.onEndDatePicked,
    required this.onWorkDaysChanged,
    required this.onStartTimePicked,
    required this.onEndTimePicked,
  });

  Future<void> _pickTime(BuildContext ctx, bool isStart) async {
    final t = await showTimePicker(
      context: ctx,
      initialTime: (isStart ? startTime : endTime) ??
          TimeOfDay(hour: isStart ? 9 : 17, minute: 0),
    );
    if (t != null) {
      isStart ? onStartTimePicked(t) : onEndTimePicked(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flexible toggle
          Card(
            child: SwitchListTile(
              title: const Text('Flexible timeline',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Work at your own pace'),
              value: flexible,
              onChanged: onFlexibleChanged,
              secondary: Icon(
                flexible ? Icons.all_inclusive : Icons.calendar_month,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (flexible)
            Card(
              color: theme.colorScheme.primaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(children: [
                  Icon(Icons.all_inclusive, size: 48),
                  SizedBox(height: 12),
                  Text('Flexible mode — no deadline',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('AI will generate weekly milestones as you progress.',
                      textAlign: TextAlign.center),
                ]),
              ),
            )
          else ...[
            // Date range
            TaskFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TaskSectionHeader(
                      icon: Icons.date_range_rounded, title: 'Duration'),
                  const SizedBox(height: 8),
                  TaskDateTile(
                    label: 'Start date',
                    date: startDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 1095)),
                    onPicked: onStartDatePicked,
                  ),
                  const Divider(height: 16),
                  TaskDateTile(
                    label: 'End date',
                    date: endDate,
                    firstDate: startDate ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 1095)),
                    onPicked: onEndDatePicked,
                  ),
                  if (startDate != null && endDate != null) ...[
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat(label: 'Weeks', value: '$weeks'),
                        _Stat(
                            label: 'Days',
                            value:
                            '${endDate!.difference(startDate!).inDays}'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Work days
            TaskFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TaskSectionHeader(
                      icon: Icons.event_repeat_rounded, title: 'Work days'),
                  const SizedBox(height: 12),
                  TaskDaySelector(
                    selected: workDays,
                    onChanged: onWorkDaysChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Time slot
            TaskFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TaskSectionHeader(
                      icon: Icons.access_time_rounded,
                      title: 'Preferred time (optional)'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeTile(
                          label: 'Start',
                          time: startTime,
                          onTap: () => _pickTime(context, true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimeTile(
                          label: 'End',
                          time: endTime,
                          onTap: () => _pickTime(context, false),
                        ),
                      ),
                    ],
                  ),
                  if (startTime != null && endTime != null) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Chip(
                        avatar: const Icon(Icons.timer_outlined, size: 16),
                        label: Text('$hoursPerDay hours / day'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyGoalsTab extends StatelessWidget {
  final List<WeeklyGoalInput> goals;
  final bool generating;
  final VoidCallback onGenerate;
  final VoidCallback onClear;
  final ValueChanged<int> onRemove;
  final void Function(int, WeeklyGoalInput) onGoalChanged;

  const _WeeklyGoalsTab({
    required this.goals,
    required this.generating,
    required this.onGenerate,
    required this.onClear,
    required this.onRemove,
    required this.onGoalChanged,
  });

  static const _moods = ['excited', 'motivated', 'focused', 'determined'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Icon(Icons.lightbulb_outline,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                        child: Text(
                            'AI generates weekly goals from your timeline and work schedule')),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: generating ? null : onGenerate,
                  icon: generating
                      ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome),
                  label: Text(generating ? 'Generating…' : 'Generate with AI'),
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(14)),
                ),
              ),
            ],
          ),
        ),
        if (goals.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Text('${goals.length} weeks planned',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: goals.length,
              itemBuilder: (_, i) {
                final g = goals[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ExpansionTile(
                    leading: CircleAvatar(child: Text('W${g.weekNumber}')),
                    title: Text(g.weeklyGoal,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(g.mood),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            TextFormField(
                              initialValue: g.weeklyGoal,
                              decoration: const InputDecoration(
                                  labelText: 'Weekly goal',
                                  border: OutlineInputBorder()),
                              maxLines: 2,
                              onChanged: (v) => onGoalChanged(
                                  i,
                                  WeeklyGoalInput(
                                      weekNumber: g.weekNumber,
                                      weeklyGoal: v,
                                      mood: g.mood)),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: g.mood,
                              decoration: const InputDecoration(
                                  labelText: 'Mood',
                                  border: OutlineInputBorder()),
                              items: _moods
                                  .map((m) => DropdownMenuItem(
                                  value: m, child: Text(m)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null)
                                  onGoalChanged(
                                      i,
                                      WeeklyGoalInput(
                                          weekNumber: g.weekNumber,
                                          weeklyGoal: g.weeklyGoal,
                                          mood: v));
                              },
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => onRemove(i),
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red, size: 18),
                                label: const Text('Remove',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ] else
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list_alt, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No weekly goals yet'),
                  Text('Tap "Generate with AI" to create your plan'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Small helpers ─────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;
  const _TimeTile(
      {required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              time?.format(context) ?? '--:--',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ]),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final TabController tabController;
  final bool saving;
  final bool isEdit;
  final VoidCallback onSubmit;

  const _BottomBar({
    required this.tabController,
    required this.saving,
    required this.isEdit,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: tabController,
      builder: (_, __) {
        final idx = tabController.index;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2))
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                if (idx > 0) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => tabController.animateTo(idx - 1),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: saving
                        ? null
                        : () {
                      if (idx < 2) {
                        tabController.animateTo(idx + 1);
                      } else {
                        onSubmit();
                      }
                    },
                    icon: saving
                        ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : Icon(idx < 2
                        ? Icons.arrow_forward
                        : Icons.save_rounded),
                    label: Text(
                      saving
                          ? (isEdit ? 'Saving…' : 'Creating…')
                          : idx < 2
                          ? 'Next'
                          : (isEdit ? 'Save changes' : 'Create goal'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(14)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// WeeklyGoalInput model (local, same as before)
class WeeklyGoalInput {
  final int weekNumber;
  String weeklyGoal;
  String mood;
  WeeklyGoalInput(
      {required this.weekNumber,
        required this.weeklyGoal,
        required this.mood});
}
