// ============================================================
// FILE: lib/features/detail_screens/shared/detail_shared_widgets.dart
// Self-contained — NO shared_widgets imports
// Uses only: CardColorHelper, AdvancedProgressIndicator,
//            TaskMetricIndicator, EnhancedMediaDisplay
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:the_time_chart/helpers/card_color_helper.dart';

// ============================================================
// DESIGN CONSTANTS (replaces AppDimens)
// ============================================================
class DS {
  DS._();
  static const double p4  = 4;
  static const double p8  = 8;
  static const double p12 = 12;
  static const double p16 = 16;
  static const double p20 = 20;
  static const double p24 = 24;
  static const double p32 = 32;
  static const double r8  = 8;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;
  static const double r100 = 100;
}

// ============================================================
// COLOR HELPERS (replaces AppColors)
// ============================================================
class DC {
  DC._();
  static const Color completed  = Color(0xFF4CAF50);
  static const Color inProgress = Color(0xFF2196F3);
  static const Color pending    = Color(0xFFFF9800);
  static const Color missed     = Color(0xFFF44336);
  static const Color cancelled  = Color(0xFF9E9E9E);
  static const Color gold       = Color(0xFFFFB300);
  static const Color purple     = Color(0xFF9C27B0);
  static const Color cyan       = Color(0xFF00BCD4);

  static Color forStatus(String s) {
    switch (s.toLowerCase().replaceAll(' ', '')) {
      case 'completed':  return completed;
      case 'inprogress': return inProgress;
      case 'missed':     return missed;
      case 'cancelled':  return cancelled;
      case 'postponed':  return Color(0xFF7B1FA2);
      default:           return pending;
    }
  }

  static Color forPriority(String p) {
    switch (p.toLowerCase()) {
      case 'low':    return Color(0xFF66BB6A);
      case 'medium': return Color(0xFF42A5F5);
      case 'high':   return Color(0xFFFF7043);
      case 'urgent': return Color(0xFFE53935);
      default:       return Color(0xFF42A5F5);
    }
  }

  static Color forProgress(int p) {
    if (p >= 100) return completed;
    if (p >= 80)  return Color(0xFF43E97B);
    if (p >= 60)  return cyan;
    if (p >= 40)  return Color(0xFF42A5F5);
    if (p >= 20)  return Color(0xFFFF9800);
    return missed;
  }
}

// ============================================================
// DATE / STRING UTILITIES (replaces DateFormatter)
// ============================================================
class DF {
  DF._();
  static String fmt(dynamic d, {String p = 'MMM dd, yyyy'}) {
    if (d == null) return '—';
    try {
      final dt = d is DateTime ? d : DateTime.parse(d.toString());
      return DateFormat(p).format(dt);
    } catch (_) { return d?.toString() ?? '—'; }
  }
  static String short(dynamic d)   => fmt(d, p: 'MMM dd');
  static String full(dynamic d)    => fmt(d, p: 'EEE, MMM dd yyyy');
  static String time(dynamic d)    => fmt(d, p: 'hh:mm a');
  static String smart(dynamic d) {
    if (d == null) return '—';
    try {
      final dt = d is DateTime ? d : DateTime.parse(d.toString());
      final diff = DateTime.now().difference(dt).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      if (diff < 7)  return '$diff days ago';
      return fmt(dt, p: 'MMM dd');
    } catch (_) { return d.toString(); }
  }
  static String daysLeft(dynamic end) {
    if (end == null) return '—';
    try {
      final dt = end is DateTime ? end : DateTime.parse(end.toString());
      final d = dt.difference(DateTime.now()).inDays;
      if (d < 0)  return '${(-d)}d overdue';
      if (d == 0) return 'Due today';
      return '${d}d left';
    } catch (_) { return '—'; }
  }
  static String duration(int days) {
    if (days >= 365) return '${(days/365).toStringAsFixed(1)} yrs';
    if (days >= 30)  return '${(days/30).floor()} months';
    return '$days days';
  }
}

extension StrX on String {
  String get cap => isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  String get titleCase => split(' ').map((w) => w.cap).join(' ');
  String get statusLabel {
    switch (toLowerCase().replaceAll(' ','')) {
      case 'inprogress': return 'In Progress';
      default: return titleCase;
    }
  }
}

// ============================================================
// DETAIL APP BAR  (replaces TaskDetailAppBar)
// ============================================================
class _TabDef { final String label; final IconData icon; const _TabDef(this.label, this.icon); }
_TabDef tabDef(String l, IconData i) => _TabDef(l, i);

class DetailAppBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final TabController tabController;
  final List<_TabDef> tabs;
  final String status;
  final List<Widget> actions;

  const DetailAppBar({
    Key? key,
    required this.title, required this.subtitle,
    required this.gradientColors, required this.tabController,
    required this.tabs, required this.status, this.actions = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors.length >= 2
              ? gradientColors
              : [Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: top),
          Padding(
            padding: const EdgeInsets.fromLTRB(DS.p4, DS.p4, DS.p8, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      Text(subtitle,
                        style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: DS.p8, vertical: DS.p4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(DS.r100),
                  ),
                  child: Text(status.statusLabel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10),
                  ),
                ),
                ...actions.map((a) => Padding(padding: const EdgeInsets.only(left: DS.p8), child: a)),
              ],
            ),
          ),
          const SizedBox(height: DS.p8),
          TabBar(
            controller: tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.5),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            indicator: UnderlineTabIndicator(
              borderSide: const BorderSide(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: DS.p8),
            tabs: tabs.map((t) => Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.icon, size: 14),
                  const SizedBox(width: 5),
                  Text(t.label),
                ],
              ),
            )).toList(),
          ),
          const SizedBox(height: DS.p4),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION CARD  (replaces DetailSectionCard)
// ============================================================
class DSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<Widget> children;
  final Widget? trailing;
  final EdgeInsetsGeometry? childPadding;

  const DSectionCard({
    Key? key,
    required this.title, required this.icon,
    required this.accentColor, required this.children,
    this.trailing, this.childPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(DS.r16),
        border: Border.all(color: accentColor.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0,3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(DS.p16, DS.p4, DS.p12, DS.p12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(DS.p8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(DS.r8),
                  ),
                  child: Icon(icon, color: accentColor, size: 17),
                ),
                const SizedBox(width: DS.p12),
                Expanded(
                  child: Text(title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.3)),
          Padding(
            padding: childPadding ?? const EdgeInsets.all(DS.p8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }
}

// helper constant not in DS
extension _DSX on DS { static double get p14 => 14; }
// Quick fix — add p14 to DS class body isn't possible post-definition; use literal 14 inline.

// ============================================================
// INFO TILE  (replaces DetailInfoTile)
// ============================================================
class DInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final VoidCallback? onTap;

  const DInfoTile({
    Key? key,
    required this.icon, required this.label, required this.value,
    this.color, this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DS.r12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DS.p8, horizontal: DS.p8),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(DS.r8)),
              child: Icon(icon, color: c, size: 17),
            ),
            const SizedBox(width: DS.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.45)),
                  ),
                  const SizedBox(height: 1),
                  Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (onTap != null) Icon(Icons.arrow_forward_ios_rounded, size: 11, color: c.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HORIZONTAL PROGRESS BAR  (replaces MiniProgressBar)
// ============================================================
class HProgressBar extends StatefulWidget {
  final double progress;
  final double height;
  final Color color;
  final bool showPercent;

  const HProgressBar({
    Key? key,
    required this.progress,
    this.height = 8,
    required this.color,
    this.showPercent = false,
  }) : super(key: key);

  @override
  State<HProgressBar> createState() => _HProgressBarState();
}

class _HProgressBarState extends State<HProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _a = Tween<double>(begin: 0, end: widget.progress.clamp(0, 100) / 100)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _a,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: widget.height,
                child: LinearProgressIndicator(
                  value: _a.value,
                  backgroundColor: widget.color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation(widget.color),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ),
        if (widget.showPercent) ...[
          const SizedBox(width: DS.p8),
          Text('${widget.progress.toInt()}%',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: widget.color),
          ),
        ],
      ],
    );
  }
}

// ============================================================
// STAR RATING  (replaces RatingStars)
// ============================================================
class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  const StarRating({Key? key, required this.rating, this.size = 18}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half   = !filled && (i < rating);
        return Icon(
          filled ? Icons.star_rounded : (half ? Icons.star_half_rounded : Icons.star_border_rounded),
          size: size, color: DC.gold,
        );
      }),
    );
  }
}

// ============================================================
// WORK DAYS ROW  (replaces WorkDaysRow)
// ============================================================
class WorkDaysRow extends StatelessWidget {
  final List<String> workDays;
  final Color color;

  const WorkDaysRow({Key? key, required this.workDays, required this.color}) : super(key: key);

  static const _s = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  static const _f = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];

  bool _on(String s) => workDays.any((d) {
    final dl = d.toLowerCase();
    return dl.startsWith(s.toLowerCase()) || _f[_s.indexOf(s)].toLowerCase() == dl;
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _s.map((d) {
        final on = _on(d);
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: on ? color : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                boxShadow: on ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 6, offset: const Offset(0,2))] : null,
              ),
              child: Center(
                child: Text(d[0],
                  style: TextStyle(
                    color: on ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.3),
                    fontWeight: FontWeight.w800, fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(d,
              style: TextStyle(
                fontSize: 8,
                color: on ? color : theme.colorScheme.onSurface.withOpacity(0.3),
                fontWeight: on ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ============================================================
// EMPTY STATE  (replaces EmptyStateWidget)
// ============================================================
class DEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const DEmptyState({Key? key, required this.title, required this.message, required this.icon, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DS.p32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(DS.p24),
              decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(icon, size: 48, color: color.withOpacity(0.45)),
            ),
            const SizedBox(height: DS.p16),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.5))),
            const SizedBox(height: DS.p8),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4), height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SMALL BADGE
// ============================================================
class DBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const DBadge({Key? key, required this.label, required this.color, this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(DS.r100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 10, color: color), const SizedBox(width: 3)],
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ============================================================
// PENDING DATE CHIPS
// ============================================================
class PendingDatesRow extends StatelessWidget {
  final List<String> dates;
  final Color color;

  const PendingDatesRow({Key? key, required this.dates, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (dates.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pending Dates',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.45), fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: DS.p8),
        Wrap(
          spacing: DS.p8, runSpacing: DS.p4,
          children: dates.map((d) {
            String disp = d;
            try { disp = DF.short(DateTime.parse(d)); } catch (_) {}
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DS.r100),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(disp, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ============================================================
// PENALTY BANNER
// ============================================================
class DPenaltyBanner extends StatelessWidget {
  final int points;
  final String reason;

  const DPenaltyBanner({Key? key, required this.points, required this.reason}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DS.p8, vertical: DS.p4),
      padding: const EdgeInsets.all(DS.p12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.07),
        borderRadius: BorderRadius.circular(DS.r12),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 18),
          const SizedBox(width: DS.p8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('-$points pts Penalty',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.error),
                ),
                Text(reason,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// REWARD BANNER  (replaces RewardBanner)
// Uses CardColorHelper.getTierColor / getTierEmoji
// ============================================================
class DRewardBanner extends StatefulWidget {
  final bool earned;
  final String tierName;
  final int tierLevel;
  final String tagName;
  final String tagReason;
  final String suggestion;
  final Color tierColor;
  final String tierEmoji;
  final int points;

  const DRewardBanner({
    Key? key,
    required this.earned, required this.tierName, required this.tierLevel,
    required this.tagName, required this.tagReason, required this.suggestion,
    required this.tierColor, required this.tierEmoji, required this.points,
  }) : super(key: key);

  factory DRewardBanner.from({
    required bool earned, required String tier, required int tierLevel,
    required String tagName, required String tagReason, required String suggestion,
    required String? rewardColor, required int points,
  }) {
    Color c;
    try {
      c = (rewardColor != null && rewardColor.isNotEmpty)
          ? Color(int.parse('FF${rewardColor.replaceAll('#', '')}', radix: 16))
          : CardColorHelper.getTierColor(tier);
    } catch (_) { c = CardColorHelper.getTierColor(tier); }
    return DRewardBanner(
      earned: earned, tierName: tier.isEmpty ? 'None' : tier.cap,
      tierLevel: tierLevel, tagName: tagName, tagReason: tagReason,
      suggestion: suggestion, tierColor: c,
      tierEmoji: CardColorHelper.getTierEmoji(tier), points: points,
    );
  }

  @override State<DRewardBanner> createState() => _DRewardBannerState();
}

class _DRewardBannerState extends State<DRewardBanner> with SingleTickerProviderStateMixin {
  late AnimationController _sh;

  @override
  void initState() {
    super.initState();
    _sh = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    if (widget.earned) _sh.repeat();
  }

  @override void dispose() { _sh.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!widget.earned) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p8),
        padding: const EdgeInsets.all(DS.p16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(DS.r16),
          border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Text('⭐', style: TextStyle(fontSize: 28)),
            const SizedBox(width: DS.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No Reward Yet',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.suggestion.isNotEmpty ? widget.suggestion : widget.tagReason,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _sh,
      builder: (_, child) => Container(
        margin: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.tierColor, widget.tierColor.withOpacity(0.7), widget.tierColor],
            stops: [(_sh.value - 0.3).clamp(0.0, 1.0), _sh.value, (_sh.value + 0.3).clamp(0.0, 1.0)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(DS.r20),
          boxShadow: [BoxShadow(color: widget.tierColor.withOpacity(0.35), blurRadius: 16, offset: const Offset(0,6))],
        ),
        child: child,
      ),
      child: Padding(
        padding: const EdgeInsets.all(DS.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.tierEmoji, style: const TextStyle(fontSize: 34)),
                const SizedBox(width: DS.p12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(DS.r100),
                        ),
                        child: Text('TIER ${widget.tierLevel}',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(widget.tagName.isNotEmpty ? widget.tagName : widget.tierName,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: DS.p12, vertical: DS.p8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(DS.r12),
                  ),
                  child: Column(
                    children: [
                      Text('+${widget.points}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const Text('pts', style: TextStyle(fontSize: 10, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.tagReason.isNotEmpty) ...[
              const SizedBox(height: DS.p12),
              Container(
                padding: const EdgeInsets.all(DS.p12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(DS.r12),
                ),
                child: Text(widget.tagReason,
                  style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.5),
                ),
              ),
            ],
            if (widget.suggestion.isNotEmpty) ...[
              const SizedBox(height: DS.p8),
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: Colors.white70, size: 13),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(widget.suggestion,
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TIMELINE VISUAL CARD  (replaces TimelineVisualCard)
// ============================================================
class DTimelineCard extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Color accentColor;

  const DTimelineCard({
    Key? key, required this.startDate, required this.endDate, required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    double pct = 0;
    bool overdue = false;
    String label = '—';

    if (startDate != null && endDate != null) {
      final total = endDate!.difference(startDate!).inDays;
      final elapsed = now.difference(startDate!).inDays.clamp(0, total + 9999);
      pct = total > 0 ? (elapsed / total * 100).clamp(0, 100) : 0;
      overdue = now.isAfter(endDate!);
      label = DF.daysLeft(endDate);
    }

    final barColor = overdue ? DC.missed : accentColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p8),
      padding: const EdgeInsets.all(DS.p16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(DS.r16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0,3))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _DateDot(label: 'Start', date: startDate, color: DC.inProgress, icon: Icons.play_circle_outline_rounded),
              Expanded(
                child: Column(
                  children: [
                    HProgressBar(progress: pct, height: 6, color: barColor),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: barColor.withOpacity(0.1), borderRadius: BorderRadius.circular(DS.r100),
                      ),
                      child: Text(label,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: barColor),
                      ),
                    ),
                  ],
                ),
              ),
              _DateDot(
                label: 'End', date: endDate,
                color: overdue ? DC.missed : DC.completed, icon: Icons.flag_rounded,
              ),
            ],
          ),
          if (startDate != null && endDate != null) ...[
            const SizedBox(height: DS.p12),
            Text(
              'Total: ${DF.duration(endDate!.difference(startDate!).inDays)}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4)),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateDot extends StatelessWidget {
  final String label;
  final DateTime? date;
  final Color color;
  final IconData icon;

  const _DateDot({required this.label, required this.date, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(DS.p8),
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 3),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4))),
        Text(date != null ? DF.short(date) : '—',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

// ============================================================
// SOCIAL TAB  (shared across all 3 screens)
// ============================================================
class DSocialTab extends StatelessWidget {
  final bool isPosted;
  final Map<String, dynamic>? postedInfo;
  final bool isShared;
  final Map<String, dynamic>? shareInfo;
  final Color accentColor;

  const DSocialTab({
    Key? key,
    required this.isPosted, this.postedInfo,
    required this.isShared, this.shareInfo,
    required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: DS.p16),
      children: [
        DSectionCard(
          title: 'Post Status',
          icon: isPosted ? Icons.public_rounded : Icons.public_off_rounded,
          accentColor: isPosted ? accentColor : Colors.grey,
          children: [
            DInfoTile(
              icon: isPosted ? Icons.cell_tower_rounded : Icons.cloud_off_rounded,
              label: 'Status',
              value: isPosted ? 'Posted to Community' : 'Not posted yet',
              color: isPosted ? accentColor : Colors.grey,
            ),
            if (!isPosted)
              Padding(
                padding: const EdgeInsets.fromLTRB(DS.p8, DS.p4, DS.p8, DS.p8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: const Text('Post to Community'),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.r12)),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: DS.p8),
        DSectionCard(
          title: 'Share Status',
          icon: isShared ? Icons.people_rounded : Icons.people_outline_rounded,
          accentColor: isShared ? Colors.indigo : Colors.grey,
          children: [
            DInfoTile(
              icon: isShared ? Icons.share_location_rounded : Icons.share_rounded,
              label: 'Status',
              value: isShared ? 'Shared with others' : 'Not shared with anyone',
              color: isShared ? Colors.indigo : Colors.grey,
            ),
            if (!isShared)
              Padding(
                padding: const EdgeInsets.fromLTRB(DS.p8, DS.p4, DS.p8, DS.p8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.people_alt_rounded, size: 16),
                    label: const Text('Share with a Friend'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.r12)),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: DS.p16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DS.p16),
          child: Row(
            children: [
              _SStat(icon: Icons.favorite_border_rounded, label: 'Likes', color: Colors.redAccent),
              const SizedBox(width: DS.p12),
              _SStat(icon: Icons.comment_outlined, label: 'Comments', color: Colors.blueAccent),
              const SizedBox(width: DS.p12),
              _SStat(icon: Icons.visibility_outlined, label: 'Views', color: Colors.purpleAccent),
            ],
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _SStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SStat({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(DS.p12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(DS.r12),
          border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text('—', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }
}