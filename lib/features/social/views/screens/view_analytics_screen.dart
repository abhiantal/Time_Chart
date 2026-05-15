import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:the_time_chart/features/social/post/models/post_model.dart';
import 'package:the_time_chart/features/social/views/models/post_views_model.dart';
import 'package:the_time_chart/features/social/views/providers/post_view_provider.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:the_time_chart/widgets/error_handler.dart';
import 'package:the_time_chart/widgets/logger.dart';
import '../widgets/analytics_chart.dart';

class ViewAnalyticsScreen extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String currentUserId;
  final PostModel? post;

  const ViewAnalyticsScreen({
    super.key,
    required this.postId,
    required this.postOwnerId,
    required this.currentUserId,
    this.post,
  });

  @override
  State<ViewAnalyticsScreen> createState() => _ViewAnalyticsScreenState();
}

class _ViewAnalyticsScreenState extends State<ViewAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  PostAnalytics? _analytics;
  bool _isOwner = false;
  int _selectedDays = 30;

  final List<_TimeRangeOption> _timeRanges = const [
    _TimeRangeOption(label: '7D', days: 7),
    _TimeRangeOption(label: '30D', days: 30),
    _TimeRangeOption(label: '90D', days: 90),
  ];

  @override
  void initState() {
    super.initState();
    _isOwner = widget.postOwnerId == widget.currentUserId;
    _tabController = TabController(length: _isOwner ? 3 : 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final provider = context.read<PostViewProvider>();
      final analytics = await provider.loadAnalytics(
        postId: widget.postId,
        days: _selectedDays,
      );

      if (mounted) {
        setState(() {
          _analytics = analytics;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      logE('Failed to load analytics', error: e, stackTrace: stack);
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showErrorSnackbar('Failed to load analytics');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Insights'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Overview'),
            const Tab(text: 'Engagement'),
            if (_isOwner) const Tab(text: 'Audience'),
          ],
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (days) {
              setState(() => _selectedDays = days);
              _loadAnalytics();
            },
            itemBuilder: (context) => _timeRanges.map((range) {
              return PopupMenuItem(
                value: range.days,
                child: Row(
                  children: [
                    if (_selectedDays == range.days)
                      Icon(
                        Icons.check,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    const SizedBox(width: 8),
                    Text(range.label),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState(theme)
          : _analytics == null
          ? _buildErrorState(theme)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(theme),
                _buildEngagementTab(theme),
                if (_isOwner) _buildAudienceTab(theme),
              ],
            ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key metrics cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _buildMetricCard(
                theme,
                label: 'Total Views',
                value: _analytics!.formattedTotalViews,
                icon: Icons.visibility,
                color: theme.colorScheme.primary,
                trend: _analytics!.viewsTrend,
                trendLabel: _analytics!.trendLabel,
              ),
              _buildMetricCard(
                theme,
                label: 'Unique Views',
                value: _analytics!.formattedUniqueViews,
                icon: Icons.people,
                color: theme.colorScheme.secondary,
                subValue: _analytics!.formattedRepeatRate,
                subLabel: 'repeat rate',
              ),
              _buildMetricCard(
                theme,
                label: 'Avg. Time',
                value: _analytics!.videoEngagement.formattedAvgWatchTime,
                icon: Icons.timer,
                color: Colors.orange,
              ),
              _buildMetricCard(
                theme,
                label: 'Completion',
                value: _analytics!.videoEngagement.formattedCompletionRate,
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Views chart
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.show_chart,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Views over time',
                        style: theme.textScheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AnalyticsChart(
                    dailyData: _analytics!.dailyViews,
                    height: 180,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Source breakdown
          if (_analytics!.hasSourceData)
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.pie_chart,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Where views came from',
                          style: theme.textScheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AnalyticsChart(
                      sourceBreakdown: _analytics!.sourceBreakdown,
                      height: 160,
                      dailyData: [],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEngagementTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Engagement metrics
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _buildMetricCard(
                theme,
                label: 'Engagement Rate',
                value: _analytics!.formattedEngagementRate,
                icon: Icons.analytics,
                color: Colors.purple,
              ),
              _buildMetricCard(
                theme,
                label: 'Total Engagement',
                value: _analytics!.formattedEngagement,
                icon: Icons.people,
                color: Colors.teal,
              ),
              _buildMetricCard(
                theme,
                label: 'Reactions',
                value: _analytics!.formattedReactions,
                icon: Icons.favorite,
                color: Colors.red,
              ),
              _buildMetricCard(
                theme,
                label: 'Comments',
                value: _analytics!.formattedComments,
                icon: Icons.chat_bubble,
                color: Colors.blue,
              ),
              _buildMetricCard(
                theme,
                label: 'Reposts',
                value: _analytics!.formattedReposts,
                icon: Icons.repeat,
                color: Colors.green,
              ),
              _buildMetricCard(
                theme,
                label: 'Saves',
                value: _analytics!.formattedSaves,
                icon: Icons.bookmark,
                color: Colors.amber,
              ),
              if (_analytics!.isAd) ...[
                _buildMetricCard(
                  theme,
                  label: 'CTA Clicks',
                  value: _analytics!.formattedCtaClicks,
                  icon: Icons.touch_app,
                  color: Colors.orange,
                ),
                _buildMetricCard(
                  theme,
                  label: 'CTR',
                  value: _analytics!.formattedCtr,
                  icon: Icons.ads_click,
                  color: Colors.indigo,
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          // Engagement quality
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Engagement Quality',
                    style: theme.textScheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(
                                  _analytics!.engagementQualityColorHex
                                      .substring(1),
                                  radix: 16,
                                ) +
                                0xFF000000,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _analytics!.engagementQuality,
                        style: theme.textScheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_analytics!.engagementRate / 20).clamp(0.0, 1.0),
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(
                          int.parse(
                                _analytics!.engagementQualityColorHex.substring(
                                  1,
                                ),
                                radix: 16,
                              ) +
                              0xFF000000,
                        ),
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Low',
                        style: theme.textScheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Excellent',
                        style: theme.textScheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device breakdown
          if (_analytics!.hasDeviceData)
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.devices,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Device Breakdown',
                          style: theme.textScheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AnalyticsChart(
                      deviceBreakdown: _analytics!.deviceBreakdown,
                      height: 160,
                      showLegend: true,
                      dailyData: [],
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Top locations (if available)
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Top Locations',
                        style: theme.textScheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      // This would come from real data
                      final locations = [
                        'United States',
                        'United Kingdom',
                        'India',
                      ];
                      final percentages = [45, 22, 15];

                      return Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                locations[index].substring(0, 2),
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  locations[index],
                                  style: theme.textScheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: percentages[index] / 100,
                                    backgroundColor: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.primary,
                                    ),
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${percentages[index]}%',
                            style: theme.textScheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    double? trend,
    String? trendLabel,
    String? subValue,
    String? subLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: trend > 0
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend > 0 ? Icons.trending_up : Icons.trending_down,
                        size: 12,
                        color: trend > 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${trend > 0 ? '+' : ''}${trend.toStringAsFixed(0)}%',
                        style: theme.textScheme.labelSmall?.copyWith(
                          color: trend > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textScheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textScheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (subValue != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  subValue,
                  style: theme.textScheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subLabel != null) ...[
                  const SizedBox(width: 2),
                  Text(
                    subLabel,
                    style: theme.textScheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading insights...',
            style: theme.textScheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 64,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to load insights',
              style: theme.textScheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This post may not have enough data yet',
              style: theme.textScheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadAnalytics,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeRangeOption {
  final String label;
  final int days;

  const _TimeRangeOption({required this.label, required this.days});
}

extension _ThemeTextScheme on ThemeData {
  TextTheme get textScheme => textTheme;
}
