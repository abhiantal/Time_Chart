// ================================================================
// FILE: lib/features/competition/widgets/screen_specific/competition_charts.dart
// All chart widgets using fl_chart
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../common/competition_models.dart' as models;
import '../common/competition_helpers.dart';
import '../common/competition_shared_widgets.dart';

// ================================================================
// BAR COMPARISON CHART
// ================================================================
class BarComparisonChart extends StatefulWidget {
  final List<models.ChartDataPoint> data;
  final double height;
  final Function(int)? onBarTap;
  final String? title;

  const BarComparisonChart({
    super.key,
    required this.data,
    this.height = 250,
    this.onBarTap,
    this.title,
  });

  @override
  State<BarComparisonChart> createState() => _BarComparisonChartState();
}

class _BarComparisonChartState extends State<BarComparisonChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.data.isEmpty) return const SizedBox.shrink();

    final maxVal = widget.data.map((e) => e.value).reduce(math.max);
    final winnerIndex = widget.data.indexWhere((e) => e.value == maxVal && e.value > 0);

    return GradientCard(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                // Legend
                Row(
                  children: [
                    _buildLegendItem('You', const Color(0xFF8B5CF6), isDark),
                    const SizedBox(width: 12),
                    _buildLegendItem('Competitors', const Color(0xFF3B82F6), isDark),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
          SizedBox(
            height: widget.height,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal == 0 ? 100 : maxVal * 1.3,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = barTouchResponse?.spot?.touchedBarGroupIndex;
                    });
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => isDark ? const Color(0xFF2A2A3A) : Colors.white,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = widget.data[group.x];
                      return BarTooltipItem(
                        '${item.label}\n',
                        TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: ScoreHelper.format(item.value.toInt()),
                            style: TextStyle(
                              color: item.color,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 80,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= widget.data.length) return const SizedBox();
                        final item = widget.data[index];
                        final isSelected = _touchedIndex == index;

                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: GestureDetector(
                            onTap: () {
                              if (widget.onBarTap != null) {
                                HapticFeedback.lightImpact();
                                widget.onBarTap!(index);
                              }
                            },
                            child: Column(
                              children: [
                                PulseAvatar(
                                  imageUrl: item.avatarUrl,
                                  name: item.label,
                                  size: 36,
                                  showPulse: isSelected && item.value > 0,
                                  borderGradient: item.isUser
                                      ? [const Color(0xFF8B5CF6), const Color(0xFFEC4899)]
                                      : [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
                                ),
                                const SizedBox(height: 6),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= widget.data.length) return const SizedBox();
                        final item = widget.data[index];
                        if (item.value == 0) return const SizedBox();

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (index == winnerIndex)
                              const Text('🏆', style: TextStyle(fontSize: 16)),
                            Text(
                              ScoreHelper.format(item.value.toInt()),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: item.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: widget.data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: item.value,
                        width: 38,
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: item.isUser
                              ? [
                                  const Color(0xFFEC4899),
                                  const Color(0xFF8B5CF6),
                                ]
                              : [
                                  const Color(0xFF06B6D4),
                                  const Color(0xFF3B82F6),
                                ],
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxVal == 0 ? 100 : maxVal * 1.3,
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// RADAR COMPARISON CHART
// ================================================================
class RadarComparisonChart extends StatelessWidget {
  final List<models.RadarDataSet> datasets;
  final List<String> labels;
  final double size;

  const RadarComparisonChart({
    super.key,
    required this.datasets,
    required this.labels,
    this.size = 250,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: size,
      width: size,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          radarBorderData: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          tickBorderData: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          getTitle: (index, angle) {
            return RadarChartTitle(
              text: labels[index],
              // angle: angle, // Remove if not supported
            );
          },
          titlePositionPercentageOffset: 0.2,
          radarTouchData: RadarTouchData(
            touchCallback: (FlTouchEvent event, response) {},
          ),
          dataSets: datasets.map((dataset) => RadarDataSet(
            dataEntries: dataset.values.map((v) => RadarEntry(value: v)).toList(),
            fillColor: dataset.color.withOpacity(0.3),
            borderColor: dataset.color,
            borderWidth: 2,
          )).toList(),
          radarBackgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}

// ================================================================
// PIE DISTRIBUTION CHART
// ================================================================
class PieDistributionChart extends StatelessWidget {
  final List<models.ChartDataPoint> data;
  final double size;

  const PieDistributionChart({
    super.key,
    required this.data,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = data.fold<double>(0, (sum, item) => sum + item.value);

    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: size * 0.3,
              sections: data.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final percentage = total > 0 ? (item.value / total * 100) : 0;

                return PieChartSectionData(
                  value: item.value,
                  color: item.color,
                  radius: size * 0.35,
                  title: '${percentage.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  titlePositionPercentageOffset: 0.6,
                  badgeWidget: index == 0 ? null : Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      item.label[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  badgePositionPercentageOffset: 0.8,
                );
              }).toList(),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  Text(
                    ScoreHelper.format(total.toInt()),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// LINE TREND CHART
// ================================================================
class LineTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final List<Color> lineColors;
  final List<String> legends;
  final List<String> xLabels;
  final double height;

  const LineTrendChart({
    super.key,
    required this.data,
    required this.lineColors,
    required this.legends,
    required this.xLabels,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 20,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: isDark ? Colors.white10 : Colors.black12,
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: isDark ? Colors.white10 : Colors.black12,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= xLabels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      xLabels[value.toInt()],
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          minX: 0,
          maxX: xLabels.length - 1,
          minY: 0,
          maxY: 100,
          lineBarsData: data.asMap().entries.map((entry) {
            final index = entry.key;
            final points = entry.value['points'] as List<FlSpot>;

            return LineChartBarData(
              spots: points,
              isCurved: true,
              color: lineColors[index % lineColors.length],
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: lineColors[index % lineColors.length],
                    strokeWidth: 2,
                    strokeColor: isDark ? Colors.white : Colors.black,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: lineColors[index % lineColors.length].withOpacity(0.1),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ================================================================
// HEAT MAP CALENDAR
// ================================================================
class HeatMapCalendar extends StatelessWidget {
  final List<bool> data;
  final DateTime startDate;
  final double cellSize;

  const HeatMapCalendar({
    super.key,
    required this.data,
    required this.startDate,
    this.cellSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weeks = (data.length / 7).ceil();
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      children: [
        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays.map((day) {
            return SizedBox(
              width: cellSize,
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Calendar grid
        ...List.generate(weeks, (weekIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (dayIndex) {
                final index = weekIndex * 7 + dayIndex;
                if (index >= data.length) {
                  return SizedBox(width: cellSize, height: cellSize);
                }

                final isActive = data[index];
                final date = startDate.add(Duration(days: index));
                final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;

                return Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                      colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
                    )
                        : null,
                    color: isActive
                        ? null
                        : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    borderRadius: BorderRadius.circular(4),
                    border: isToday
                        ? Border.all(color: const Color(0xFF8B5CF6), width: 2)
                        : null,
                  ),
                  child: Center(
                    child: isActive
                        ? const Text('🔥', style: TextStyle(fontSize: 10))
                        : null,
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }
}

// ================================================================
// PROGRESS GAUGE
// ================================================================
class ProgressGauge extends StatelessWidget {
  final double value;
  final String label;
  final Color color;
  final double size;

  const ProgressGauge({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        SizedBox(
          height: size,
          width: size,
          child: Stack(
            children: [
              // Background circle
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                ),
              ),
              // Progress arc
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value / 100),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, progress, child) {
                  return CustomPaint(
                    size: Size(size, size),
                    painter: _GaugePainter(
                      progress: progress,
                      color: color,
                    ),
                  );
                },
              ),
              // Center text
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${value.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: size * 0.2,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _GaugePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ================================================================
// STACKED BAR CHART
// ================================================================
class StackedBarChart extends StatelessWidget {
  final List<models.StackedBarData> data;
  final double height;

  const StackedBarChart({
    super.key,
    required this.data,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxValue = data.fold<double>(
      0,
          (max, item) => math.max(max, item.values.fold<double>(0, (sum, v) => sum + v)),
    );

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.asMap().entries.map((entry) {
          final item = entry.value;
          final total = item.values.fold<double>(0, (sum, v) => sum + v);
          final normalizedHeight = maxValue > 0 ? total / maxValue : 0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Stacked bars
                  SizedBox(
                    height: height * 0.7 * normalizedHeight,
                    child: Stack(
                      children: [
                        for (int i = 0; i < item.values.length; i++)
                          Positioned(
                            bottom: i > 0
                                ? item.values
                                .sublist(0, i)
                                .fold<double>(0.0, (sum, v) => sum + v)
                                : 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: (item.values[i] / total) *
                                  height *
                                  0.7 *
                                  normalizedHeight,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    item.colors[i % item.colors.length],
                                    item.colors[i % item.colors.length].withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.vertical(
                                  top: i == item.values.length - 1
                                      ? const Radius.circular(8)
                                      : Radius.zero,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Label
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Total
                  Text(
                    ScoreHelper.format(total.toInt()),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class StackedBarData {
  final String label;
  final List<double> values;
  final List<Color> colors;

  StackedBarData({
    required this.label,
    required this.values,
    required this.colors,
  });
}