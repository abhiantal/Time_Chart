// lib/features/personal/shared/task_form_widgets.dart
//
// Shared form widgets used by:
//   • AddEditBucketPage
//   • AddWeeklyTaskScreen
//   • CreateLongGoalScreen
//
// Replaces ~400 lines of duplicated code across those 3 files.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../category_model/widgets/category_picker_popup.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. SECTION HEADER  (icon + title)
// ─────────────────────────────────────────────────────────────────────────────

class TaskSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const TaskSectionHeader({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: c.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: c.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. PRIORITY SELECTOR  (Low / Medium / High / Urgent)
// ─────────────────────────────────────────────────────────────────────────────

class TaskPrioritySelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const TaskPrioritySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _options = [
    ('low', Colors.green, 'Low', Icons.flag_outlined),
    ('medium', Colors.blue, 'Medium', Icons.flag),
    ('high', Colors.orange, 'High', Icons.flag),
    ('urgent', Colors.red, 'Urgent', Icons.priority_high_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TaskSectionHeader(icon: Icons.flag_rounded, title: 'Priority'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
          ),
          child: Row(
            children: _options
                .map(
                  (o) => Expanded(
                    child: _Chip(
                      opt: o,
                      selected: value == o.$1,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onChanged(o.$1);
                      },
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final (String, Color, String, IconData) opt;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.opt, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = opt.$2;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? color
              : (isDark ? Colors.transparent : Colors.white),
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              opt.$4,
              size: 20,
              color: selected ? Colors.white : color.withOpacity(0.7),
            ),
            const SizedBox(height: 4),
            Text(
              opt.$3,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. CATEGORY PICKER TILE
// ─────────────────────────────────────────────────────────────────────────────

class TaskCategoryTile extends StatelessWidget {
  final CategoryPickerResult? selected;
  final String categoryFor;
  final ValueChanged<CategoryPickerResult> onSelected;

  const TaskCategoryTile({
    super.key,
    required this.selected,
    required this.categoryFor,
    required this.onSelected,
  });

  Color _color(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  Future<void> _pick(BuildContext ctx) async {
    final result = await CategoryPickerPopup.show(
      context: ctx,
      categoryFor: categoryFor,
      initialSelection: selected,
      showSubTypeSelector: true,
      allowCreate: true,
    );
    if (result != null) onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = selected;
    final accent = s != null ? _color(s.categoryColor) : cs.outline;

    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: s != null
              ? accent.withOpacity(0.08)
              : cs.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accent.withOpacity(s != null ? 0.5 : 0.3),
            width: s != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                s?.categoryIcon ?? '📁',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: s != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.categoryType,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                        if (s.subType != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s.subType!,
                              style: TextStyle(
                                fontSize: 11,
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    )
                  : Text(
                      'Select category',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: s != null ? accent : cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. DATE PICKER TILE
// ─────────────────────────────────────────────────────────────────────────────

class TaskDateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onPicked;
  final bool clearable;

  const TaskDateTile({
    super.key,
    required this.label,
    required this.date,
    required this.onPicked,
    this.firstDate = const _epoch(),
    this.lastDate = const _farFuture(),
    this.clearable = false,
  });

  Future<void> _pick(BuildContext ctx) async {
    HapticFeedback.lightImpact();
    final picked = await showDatePicker(
      context: ctx,
      initialDate: date ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasDate = date != null;

    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: hasDate ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              hasDate ? _fmt(date!) : 'Not set',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: hasDate ? cs.primary : cs.onSurfaceVariant,
                fontWeight: hasDate ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (clearable && hasDate)
              GestureDetector(
                onTap: () => onPicked(DateTime(0)),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.close_rounded, size: 16, color: cs.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// Sentinel values as const constructors (workaround for default param limitation)
class _epoch implements DateTime {
  const _epoch();
  @override
  dynamic noSuchMethod(Invocation i) => DateTime(2020);
}

class _farFuture implements DateTime {
  const _farFuture();
  @override
  dynamic noSuchMethod(Invocation i) => DateTime(2100);
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. PRIMARY ACTION BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class TaskPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onTap;

  const TaskPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. DESTRUCTIVE (DELETE) BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class TaskDestructiveButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const TaskDestructiveButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. DAY-OF-WEEK SELECTOR  (used by WeekTask + LongGoal)
// ─────────────────────────────────────────────────────────────────────────────

class TaskDaySelector extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  static const _days = [
    ('Mon', 'Monday'),
    ('Tue', 'Tuesday'),
    ('Wed', 'Wednesday'),
    ('Thu', 'Thursday'),
    ('Fri', 'Friday'),
    ('Sat', 'Saturday'),
    ('Sun', 'Sunday'),
  ];

  const TaskDaySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _days.map((d) {
        final isOn = selected.contains(d.$2);
        return FilterChip(
          label: Text(d.$1),
          selected: isOn,
          onSelected: (v) {
            final next = Set<String>.from(selected);
            v ? next.add(d.$2) : next.remove(d.$2);
            onChanged(next);
          },
          selectedColor: cs.primary,
          checkmarkColor: cs.onPrimary,
          labelStyle: TextStyle(
            color: isOn ? cs.onPrimary : cs.onSurface,
            fontWeight: isOn ? FontWeight.bold : FontWeight.normal,
          ),
          side: BorderSide(
            color: isOn ? cs.primary : cs.outline,
            width: isOn ? 2 : 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. FORM SECTION CARD  (consistent padding + border)
// ─────────────────────────────────────────────────────────────────────────────

class TaskFormCard extends StatelessWidget {
  final Widget child;

  const TaskFormCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
      ),
      child: child,
    );
  }
}
