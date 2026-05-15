import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_time_chart/features/social/views/models/post_views_model.dart';

class AnalyticsChart extends StatefulWidget {
  final List<DailyViewData> dailyData;
  final List<SourceBreakdownItem> sourceBreakdown;
  final List<DeviceBreakdownItem> deviceBreakdown;
  final VideoEngagement? videoEngagement;
  final double height;
  final bool showLegend;
  final bool animated;

  const AnalyticsChart({
    super.key,
    required this.dailyData,
    this.sourceBreakdown = const [],
    this.deviceBreakdown = const [],
    this.videoEngagement,
    this.height = 200,
    this.showLegend = true,
    this.animated = true,
  });

  @override
  State<AnalyticsChart> createState() => _AnalyticsChartState();
}

class _AnalyticsChartState extends State<AnalyticsChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedMetric = 'views'; // 'views' or 'unique'
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    if (widget.animated) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Metric selector
          if (widget.dailyData.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildMetricChip(context, 'Views', 'views', Icons.visibility),
                  const SizedBox(width: 8),
                  _buildMetricChip(context, 'Unique', 'unique', Icons.people),
                ],
              ),
            ),

          // Chart
          SizedBox(
            height: widget.height,
            child: Row(
              children: [
                // Y-axis labels
                _buildYAxis(theme),

                // Bars
                Expanded(child: _buildChart(theme)),
              ],
            ),
          ),

          // X-axis labels
          if (widget.dailyData.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 32),
              child: Row(
                children: widget.dailyData.map((data) {
                  final index = widget.dailyData.indexOf(data);
                  final isLast = index == widget.dailyData.length - 1;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: isLast ? 0 : 4),
                      child: Text(
                        data.shortDate,
                        style: theme.textScheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Legend
          if (widget.showLegend && widget.sourceBreakdown.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: widget.sourceBreakdown.map((item) {
                  return _buildLegendItem(
                    context,
                    item.source.label,
                    Color(
                      int.parse(item.colorHex.substring(1), radix: 16) +
                          0xFF000000,
                    ),
                    '${item.percentage.toStringAsFixed(0)}%',
                  );
                }).toList(),
              ),
            ),

          // Video engagement
          if (widget.videoEngagement != null && widget.videoEngagement!.hasData)
            _buildVideoEngagement(theme),
        ],
      ),
    );
  }

  Widget _buildMetricChip(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final isSelected = _selectedMetric == value;
    final theme = Theme.of(context);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedMetric = value);
          HapticFeedback.selectionClick();
        }
      },
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : null,
      ),
    );
  }

  Widget _buildYAxis(ThemeData theme) {
    final maxValue = _selectedMetric == 'views'
        ? (widget.dailyData.isEmpty
              ? 0
              : widget.dailyData
                    .map((d) => d.views)
                    .reduce((a, b) => a > b ? a : b))
        : (widget.dailyData.isEmpty
              ? 0
              : widget.dailyData
                    .map((d) => d.uniqueViews)
                    .reduce((a, b) => a > b ? a : b));

    final intervals = [
      maxValue,
      maxValue * 0.75,
      maxValue * 0.5,
      maxValue * 0.25,
      0,
    ];

    return SizedBox(
      width: 40,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: intervals.map((value) {
          return Text(
            _formatYValue(value),
            style: theme.textScheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(ThemeData theme) {
    if (widget.dailyData.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: theme.textScheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final maxValue = _selectedMetric == 'views'
        ? (widget.dailyData.isEmpty
              ? 0
              : widget.dailyData
                    .map((d) => d.views)
                    .reduce((a, b) => a > b ? a : b))
        : (widget.dailyData.isEmpty
              ? 0
              : widget.dailyData
                    .map((d) => d.uniqueViews)
                    .reduce((a, b) => a > b ? a : b));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: widget.dailyData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final isHovered = _hoveredIndex == index;

        final value = _selectedMetric == 'views'
            ? data.views
            : data.uniqueViews;
        final height = maxValue > 0
            ? (value / maxValue) * (widget.height - 40)
            : 0.0;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == widget.dailyData.length - 1 ? 0 : 4,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Tooltip on hover
                if (isHovered)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      value.toString(),
                      style: theme.textScheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),

                // Bar
                GestureDetector(
                  onTap: () {
                    // Show detailed breakdown
                  },
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hoveredIndex = index),
                    onExit: (_) => setState(() => _hoveredIndex = null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: height > 0 ? height : 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: isHovered
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    Color color,
    String percentage,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textScheme.bodySmall),
        const SizedBox(width: 4),
        Text(
          percentage,
          style: Theme.of(context).textScheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoEngagement(ThemeData theme) {
    final video = widget.videoEngagement!;

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Video Engagement',
                style: theme.textScheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildVideoMetric(
                  theme,
                  'Avg. Watch Time',
                  video.formattedAvgWatchTime,
                  Icons.timer,
                ),
              ),
              Expanded(
                child: _buildVideoMetric(
                  theme,
                  'Completion Rate',
                  video.formattedCompletionRate,
                  Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: video.completionRate / 100,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getCompletionColor(video.completionRate),
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoMetric(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textScheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textScheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Color _getCompletionColor(double rate) {
    if (rate >= 70) return Colors.green;
    if (rate >= 40) return Colors.amber;
    if (rate >= 20) return Colors.orange;
    return Colors.red;
  }

  String _formatYValue(num value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}

extension _ThemeTextScheme on ThemeData {
  TextTheme get textScheme => textTheme;
}
