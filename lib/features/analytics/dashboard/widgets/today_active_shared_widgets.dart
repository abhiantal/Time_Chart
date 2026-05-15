// ================================================================
// FILE: today_active_shared_widgets.dart
// Shared widgets used by BOTH:
//   • today_detail_screen.dart
//   • active_items_detail_screen.dart
//
// Uses: CustomProgressIndicator  → bar_progress_indicator.dart
//       AdvancedProgressIndicator → message_bubbles/advanced_progress_indicator.dart
//       shared_widgets.dart
// ================================================================

import 'package:flutter/material.dart';

// ── Progress widgets ─────────────────────────────────────────────
import '../../../../widgets/bar_progress_indicator.dart';

// ── Shared ───────────────────────────────────────────────────────
import '../../../../widgets/circular_progress_indicator.dart';
import '../widgets/shared_widgets.dart';
import '../../../../helpers/card_color_helper.dart';

// ================================================================
// 1. SECTION LABEL
// ================================================================

class TASectionLabel extends StatelessWidget {
  final String label;
  final Color? color;

  const TASectionLabel({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return Row(children: [
      Container(
        width: 3,
        height: 16,
        decoration:
        BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 8),
      Text(label,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.1)),
    ]);
  }
}

// ================================================================
// 2. CARD SHELL  (neutral surface container)
// ================================================================

class TACardShell extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final List<Color>? gradient;
  final EdgeInsets? padding;

  const TACardShell({
    super.key,
    required this.child,
    this.accentColor,
    this.gradient,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient != null
            ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient!)
            : null,
        color: gradient == null
            ? (isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surface)
            : null,
        borderRadius: BorderRadius.circular(18),
        border: accentColor != null
            ? Border.all(color: accentColor!.withOpacity(0.22))
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.28 : 0.07),
              blurRadius: 16,
              offset: const Offset(0, 5)),
        ],
      ),
      child: child,
    );
  }
}

// ================================================================
// 3. ITEM CARD SHELL  (tinted, border turns red when overdue)
// ================================================================

class TAItemCardShell extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  final bool isDark;
  final bool isOverdue;
  final VoidCallback? onTap;

  const TAItemCardShell({
    super.key,
    required this.child,
    required this.accentColor,
    required this.isDark,
    this.isOverdue = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isOverdue ? const Color(0xFFEF4444) : accentColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withOpacity(isDark ? 0.18 : 0.10),
              accentColor.withOpacity(isDark ? 0.06 : 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: borderColor.withOpacity(isOverdue ? 0.55 : 0.22),
              width: isOverdue ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
                color: accentColor.withOpacity(0.09),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ================================================================
// 4. PROGRESS ROW  (label · % value · CustomProgressIndicator bar)
// ================================================================

class TAProgressRow extends StatelessWidget {
  final int progress;
  final Color color;
  final bool isDark;
  final String? label;

  const TAProgressRow({
    super.key,
    required this.progress,
    required this.color,
    required this.isDark,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label ?? 'Progress',
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5))),
        Text('$progress%',
            style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800, color: color)),
      ]),
      const SizedBox(height: 5),
      CustomProgressIndicator(
        progress: (progress / 100).clamp(0.0, 1.0),
        progressBarName: '',
        orientation: ProgressOrientation.horizontal,
        baseHeight: 8,
        maxHeightIncrease: 3,
        gradientColors: [color, color.withOpacity(0.55)],
        backgroundColor: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.grey.shade200,
        borderRadius: 6,
        progressLabelDisplay: ProgressLabelDisplay.none,
        nameLabelPosition: LabelPosition.bottom,
        animateNameLabel: false,
        animationDuration: const Duration(milliseconds: 1200),
        animationCurve: Curves.easeOutCubic,
      ),
    ]);
  }
}

// ================================================================
// 5. HERO STAT COLUMN + DIVIDER  (white text, used in both headers)
// ================================================================

class TAHeroStat extends StatelessWidget {
  final String value, label, icon;
  const TAHeroStat(
      {super.key,
        required this.value,
        required this.label,
        required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: const TextStyle(fontSize: 13)),
      const SizedBox(height: 2),
      Text(value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800)),
      Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 8,
              fontWeight: FontWeight.w500)),
    ]),
  );
}

class TAHeroDiv extends StatelessWidget {
  const TAHeroDiv({super.key});
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: Colors.white.withOpacity(0.22));
}

// ================================================================
// 6. HERO STRIP  (frosted row of TAHeroStats used in both headers)
// ================================================================

class TAHeroStrip extends StatelessWidget {
  final List<Widget> children; // mix of TAHeroStat + TAHeroDiv

  const TAHeroStrip({super.key, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.13),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(children: children),
  );
}

// ================================================================
// 7. TASK CARD HEADER  (title + status/priority/overdue row + points)
// ================================================================

class TATaskCardHeader extends StatelessWidget {
  final String title;
  final String status;
  final String? priority;
  final bool isOverdue;
  final int points;
  final String? reward;

  const TATaskCardHeader({
    super.key,
    required this.title,
    required this.status,
    this.priority,
    this.isOverdue = false,
    required this.points,
    this.reward,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Wrap(spacing: 6, runSpacing: 4, children: [
            StatusBadge(status: status),
            if (priority != null) TAPriorityBadge(priority: priority!),
            if (isOverdue) const TAOverdueBadge(),
          ]),
        ]),
      ),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        PointsBadge(points: points, animate: false),
        if (reward != null) ...[
          const SizedBox(height: 4),
          RewardBadge(
              tier: reward!,
              emoji: CardColorHelper.getTierEmoji(reward!)),
        ],
      ]),
    ]);
  }
}

// ================================================================
// 8. INFO PILL  (label + value chip — stats/overdue/on-track)
// ================================================================

class TAInfoPill extends StatelessWidget {
  final String label, value;
  final Color color;

  const TAInfoPill(
      {super.key,
        required this.label,
        required this.value,
        required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
              text: '$label  ',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: color.withOpacity(0.65), fontSize: 9)),
          TextSpan(
              text: value,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

// ================================================================
// 9. STAT TILE  (used in grid stats for both screens)
// ================================================================

class TAStatTile extends StatelessWidget {
  final String emoji, label, value;
  final Color color;

  const TAStatTile(
      {super.key,
        required this.emoji,
        required this.label,
        required this.value,
        required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.1 : 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 17)),
            Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800, color: color)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 9)),
            ]),
          ]),
    );
  }
}

// ================================================================
// 10. OVERDUE BADGE
// ================================================================

class TAOverdueBadge extends StatelessWidget {
  const TAOverdueBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFEF4444).withOpacity(0.14),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
    ),
    child: const Text('⚠️ OVERDUE',
        style: TextStyle(
            color: Color(0xFFEF4444),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4)),
  );
}

// ================================================================
// 11. PRIORITY BADGE
// ================================================================

class TAPriorityBadge extends StatelessWidget {
  final String priority;
  const TAPriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = CardColorHelper.getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(priority.toUpperCase(),
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5)),
    );
  }
}

// ================================================================
// 12. PENALTY BADGE
// ================================================================

class TAPenaltyBadge extends StatelessWidget {
  const TAPenaltyBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [
      Icon(Icons.warning_rounded, size: 12, color: theme.colorScheme.error),
      const SizedBox(width: 4),
      Text('Penalty Applied',
          style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w700,
              fontSize: 10)),
    ]);
  }
}

// ================================================================
// 13. TIME CHIP  (start – end display for scheduled tasks)
// ================================================================

class TATimeChip extends StatelessWidget {
  final DateTime start;
  final DateTime? end;

  const TATimeChip({super.key, required this.start, this.end});

  static String _fmt(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = end != null ? '${_fmt(start)} – ${_fmt(end!)}' : _fmt(start);
    return Row(children: [
      Icon(Icons.schedule_rounded,
          size: 12,
          color: theme.colorScheme.onSurface.withOpacity(0.45)),
      const SizedBox(width: 4),
      Text(label,
          style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w600)),
    ]);
  }
}

// ================================================================
// 14. ARC PROGRESS CARD  (AdvancedProgressIndicator arc + right col)
// Used by goal/long-goal cards in both screens
// ================================================================

class TAArcProgressCard extends StatelessWidget {
  final int progress;
  final Color color;
  final bool isDark;
  final Widget rightChild;

  const TAArcProgressCard({
    super.key,
    required this.progress,
    required this.color,
    required this.isDark,
    required this.rightChild,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      AdvancedProgressIndicator(
        progress: (progress / 100).clamp(0.0, 1.0),
        size: 54,
        strokeWidth: 5.5,
        shape: ProgressShape.circular,
        gradientColors: [color, color.withOpacity(0.55)],
        backgroundColor: isDark
            ? Colors.white.withOpacity(0.07)
            : Colors.grey.shade200,
        labelStyle: ProgressLabelStyle.custom,
        customLabel: '$progress%',
        labelTextStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w900, color: color, fontSize: 11),
        animationDuration: const Duration(milliseconds: 1300),
      ),
      const SizedBox(width: 16),
      Expanded(child: rightChild),
    ],
  );
}

// ================================================================
// 15. CATEGORY BAR ROW  (emoji · label · count · CustomProgressBar)
// Used in stats cards of both screens
// ================================================================

class TACategoryBarRow extends StatelessWidget {
  final String emoji, label;
  final int count, maxCount;
  final Color color;
  final bool isDark;

  const TACategoryBarRow({
    super.key,
    required this.emoji,
    required this.label,
    required this.count,
    required this.maxCount,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = maxCount > 0 ? count / maxCount : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(label,
              style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7))),
        ]),
        Text(count.toString(),
            style: theme.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w800, color: color)),
      ]),
      const SizedBox(height: 5),
      CustomProgressIndicator(
        progress: fraction.clamp(0.0, 1.0),
        progressBarName: '',
        orientation: ProgressOrientation.horizontal,
        baseHeight: 7,
        maxHeightIncrease: 2,
        gradientColors: [color, color.withOpacity(0.55)],
        backgroundColor: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.shade200,
        borderRadius: 5,
        progressLabelDisplay: ProgressLabelDisplay.none,
        nameLabelPosition: LabelPosition.bottom,
        animateNameLabel: false,
        animationDuration: const Duration(milliseconds: 1200),
        animationCurve: Curves.easeOutCubic,
      ),
    ]);
  }
}