// ================================================================
// FILE: lib/features/personal/dashboard/utils/skeleton_widgets.dart
// Unified dashboard skeletons (cards + charts + full screen)
// ================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ================================================================
// BASE CARD SKELETON (Shimmer)
// ================================================================

class DashboardCardSkeleton extends StatefulWidget {
  final double height;
  final bool showHeader;
  final int contentLines;
  final bool showFooter;

  const DashboardCardSkeleton({
    super.key,
    this.height = 160,
    this.showHeader = true,
    this.contentLines = 3,
    this.showFooter = true,
  });

  @override
  State<DashboardCardSkeleton> createState() => _DashboardCardSkeletonState();
}

class _DashboardCardSkeletonState extends State<DashboardCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    duration: const Duration(milliseconds: 1300),
    vsync: this,
  )..repeat();

  late final Animation<double> _a = Tween<double>(
    begin: -2,
    end: 2,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOutSine));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final base = isDark
        ? t.colorScheme.surfaceContainerHighest
        : Colors.grey[300]!;
    final hi = isDark ? t.colorScheme.surface : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _a,
      builder: (context, _) {
        return Container(
          height: widget.height,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showHeader) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _box(width: 140, height: 18, base: base, hi: hi),
                    _box(
                      width: 70,
                      height: 22,
                      radius: 999,
                      base: base,
                      hi: hi,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final lineH = 22.0;
                    final possible = (c.maxHeight / lineH).floor();
                    final count = math.max(
                      0,
                      math.min(widget.contentLines, possible),
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(count, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _box(
                            width: i == count - 1 ? 200 : double.infinity,
                            height: 12,
                            radius: 8,
                            base: base,
                            hi: hi,
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
              if (widget.showFooter) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    _box(width: 90, height: 30, radius: 10, base: base, hi: hi),
                    const SizedBox(width: 12),
                    _box(width: 90, height: 30, radius: 10, base: base, hi: hi),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _box({
    required double width,
    required double height,
    double radius = 10,
    required Color base,
    required Color hi,
  }) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(_a.value - 1, 0),
          end: Alignment(_a.value + 1, 0),
          colors: [base, hi, base],
          stops: const [0, 0.5, 1],
        ),
      ),
    );
  }
}

// ================================================================
// SPECIFIC CARD SKELETONS
// ================================================================

class OverviewCardSkeleton extends StatelessWidget {
  final bool compact;
  const OverviewCardSkeleton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) => DashboardCardSkeleton(
    height: compact ? 110 : 220,
    contentLines: compact ? 1 : 5,
    showFooter: !compact,
  );
}

class TodayTasksCardSkeleton extends StatelessWidget {
  const TodayTasksCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const DashboardCardSkeleton(
    height: 320,
    contentLines: 6,
    showFooter: true,
  );
}

class ActiveItemsCardSkeleton extends StatelessWidget {
  final bool compact;
  const ActiveItemsCardSkeleton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) => DashboardCardSkeleton(
    height: compact ? 180 : 240,
    contentLines: compact ? 3 : 5,
    showFooter: false,
  );
}

class StreaksCardSkeleton extends StatelessWidget {
  final bool compact;
  const StreaksCardSkeleton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) => DashboardCardSkeleton(
    height: compact ? 140 : 220,
    contentLines: compact ? 2 : 4,
    showFooter: !compact,
  );
}

class MoodCardSkeleton extends StatelessWidget {
  final bool compact;
  const MoodCardSkeleton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) => DashboardCardSkeleton(
    height: compact ? 140 : 240,
    contentLines: compact ? 2 : 4,
    showFooter: !compact,
  );
}

class RewardsCardSkeleton extends StatelessWidget {
  final bool compact;
  const RewardsCardSkeleton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) => DashboardCardSkeleton(
    height: compact ? 140 : 240,
    contentLines: compact ? 2 : 4,
    showFooter: !compact,
  );
}

class CategoryStatsCardSkeleton extends StatelessWidget {
  const CategoryStatsCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const DashboardCardSkeleton(
    height: 240,
    contentLines: 5,
    showFooter: false,
  );
}

// ================================================================
// CHART SKELETON
// ================================================================

enum ChartType { line, pie, bar, calendar }

class ChartLoadingSkeleton extends StatefulWidget {
  final double height;
  final ChartType type;

  const ChartLoadingSkeleton({
    super.key,
    this.height = 300,
    this.type = ChartType.line,
  });

  @override
  State<ChartLoadingSkeleton> createState() => _ChartLoadingSkeletonState();
}

class _ChartLoadingSkeletonState extends State<ChartLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    duration: const Duration(milliseconds: 1300),
    vsync: this,
  )..repeat();

  late final Animation<double> _a = Tween<double>(
    begin: -2,
    end: 2,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOutSine));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final base = isDark
        ? t.colorScheme.surfaceContainerHighest
        : Colors.grey[300]!;
    final hi = isDark ? t.colorScheme.surface : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) {
        return Container(
          height: widget.height,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _box(140, 18, base, hi),
                  const Spacer(),
                  _box(70, 22, base, hi, radius: 999),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(child: _chartArea(base, hi)),
            ],
          ),
        );
      },
    );
  }

  Widget _chartArea(Color base, Color hi) {
    switch (widget.type) {
      case ChartType.pie:
        return Center(child: _box(140, 140, base, hi, radius: 999));
      case ChartType.bar:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(8, (i) {
            final h = 30.0 + ((i * 17) % 90);
            return _box(18, h, base, hi, radius: 6);
          }),
        );
      case ChartType.calendar:
        return Column(
          children: List.generate(3, (_) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  10,
                  (_) => _box(18, 18, base, hi, radius: 5),
                ),
              ),
            );
          }),
        );
      case ChartType.line:
        return CustomPaint(
          painter: _LineSkeletonPainter(shimmerX: _a.value, base: base, hi: hi),
          size: Size.infinite,
        );
    }
  }

  Widget _box(double w, double h, Color base, Color hi, {double radius = 10}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(_a.value - 1, 0),
          end: Alignment(_a.value + 1, 0),
          colors: [base, hi, base],
          stops: const [0, 0.5, 1],
        ),
      ),
    );
  }
}

class _LineSkeletonPainter extends CustomPainter {
  final double shimmerX;
  final Color base;
  final Color hi;

  _LineSkeletonPainter({
    required this.shimmerX,
    required this.base,
    required this.hi,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const points = 12;
    for (int i = 0; i < points; i++) {
      final x = (i / (points - 1)) * size.width;
      final y = size.height * (0.25 + 0.5 * math.sin(i * 0.7 + shimmerX));
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = base.withOpacity(0.55);

    canvas.drawPath(path, basePaint);

    final shimmerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..shader = LinearGradient(
        begin: Alignment(shimmerX - 1, 0),
        end: Alignment(shimmerX + 1, 0),
        colors: [Colors.transparent, hi.withOpacity(0.55), Colors.transparent],
      ).createShader(Offset.zero & size);

    canvas.drawPath(path, shimmerPaint);
  }

  @override
  bool shouldRepaint(covariant _LineSkeletonPainter oldDelegate) =>
      oldDelegate.shimmerX != shimmerX ||
      oldDelegate.base != base ||
      oldDelegate.hi != hi;
}

// ================================================================
// FULL DASHBOARD SKELETON
// ================================================================

class FullDashboardSkeleton extends StatelessWidget {
  const FullDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 8),
          OverviewCardSkeleton(),
          TodayTasksCardSkeleton(),
          ActiveItemsCardSkeleton(),
          ChartLoadingSkeleton(type: ChartType.line),
          CategoryStatsCardSkeleton(),
          MoodCardSkeleton(),
          StreaksCardSkeleton(),
          RewardsCardSkeleton(),
          SizedBox(height: 60),
        ],
      ),
    );
  }
}
