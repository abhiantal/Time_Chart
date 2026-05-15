// ================================================================
// FILE: lib/features/competition/screens/my_competition_data_screen.dart
// My Competition Data Screen - Multi-Comparison View
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'dart:math' as math;

import '../../../../widgets/error_handler.dart';
import '../providers/competition_provider.dart';
import '../widgets/common/competition_animations.dart';
import '../widgets/common/competition_helpers.dart';
import '../widgets/common/competition_models.dart';
import '../widgets/common/competition_shared_widgets.dart';
import '../widgets/screen_specific/my_data_widgets.dart';
import '../widgets/screen_specific/competition_charts.dart';
import 'competition_detail_screen.dart';

// ================================================================
// MY COMPETITION DATA SCREEN
// ================================================================
class MyCompetitionDataScreen extends StatefulWidget {
  final String? userId;

  const MyCompetitionDataScreen({super.key, this.userId});

  @override
  State<MyCompetitionDataScreen> createState() =>
      _MyCompetitionDataScreenState();
}

class _MyCompetitionDataScreenState extends State<MyCompetitionDataScreen>
    with TickerProviderStateMixin, CompetitionAnimationMixin {
  late AnimationController _bgController;
  late AnimationController _barController;

  ComparisonCategory _selectedCategory = ComparisonCategory.overall;
  final Set<String> _expandedSections = {'leaderboard', 'tasks'};
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _barController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    initCompetitionAnimations(enableFloat: true, enableGlow: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barController.forward();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _barController.dispose();
    disposeCompetitionAnimations();
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();

    try {
      final provider = context.read<BattleChallengeProvider>();
      await provider.refresh();
      _barController.forward(from: 0);
      SnackbarService().showSuccess('Data refreshed');
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to refresh data');
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  void _selectCategory(ComparisonCategory category) {
    HapticFeedback.selectionClick();
    setState(() => _selectedCategory = category);
  }

  void _toggleSection(String sectionId) {
    setState(() {
      if (_expandedSections.contains(sectionId)) {
        _expandedSections.remove(sectionId);
      } else {
        _expandedSections.add(sectionId);
      }
    });
  }

  void _navigateToDetail(String competitorId, String competitorName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompetitionDetailScreen(
          competitorId: competitorId,
          competitorName: competitorName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0F)
          : const Color(0xFFF8F9FF),
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _BackgroundPainter(
                  animationValue: _bgController.value,
                  isDarkMode: isDark,
                ),
              );
            },
          ),

          // Main Content
          SafeArea(
            child: Consumer<BattleChallengeProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && !provider.hasChallenge) {
                  return _buildLoadingState(isDark);
                }

                if (provider.error != null && !provider.hasChallenge) {
                  return _buildErrorState(isDark, provider.error!);
                }

                final data = _buildMyData(provider);
                if (data == null) {
                  return _buildEmptyState(isDark, provider);
                }

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  color: const Color(0xFF8B5CF6),
                  child: AnimatedBuilder(
                    animation: entryAnimationsListenable,
                    builder: (context, child) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Opacity(
                          opacity: fadeIn,
                          child: Transform.translate(
                            offset: Offset(0, slideUp),
                            child: Column(
                              children: [
                                // App Bar
                                _buildAppBar(isDark, data, provider),

                                const SizedBox(height: 16),

                                // Live Leaderboard
                                if (_expandedSections.contains('leaderboard'))
                                  _buildLeaderboardSection(isDark, data),

                                const SizedBox(height: 24),

                                // Category Selector
                                _buildCategorySelector(isDark),

                                const SizedBox(height: 24),

                                // Multi-Bar Chart
                                _buildBarChart(isDark, data),

                                const SizedBox(height: 24),

                                // Metrics Table
                                if (_expandedSections.contains('tasks'))
                                  _buildMetricsTable(isDark, data),

                                const SizedBox(height: 24),

                                // Head-to-Head Cards
                                _buildHeadToHeadSection(isDark, data),

                                const SizedBox(height: 24),

                                // Category Breakdown
                                _buildCategoryBreakdown(isDark, data),

                                const SizedBox(height: 24),

                                // Streak Comparison
                                _buildStreakComparison(isDark, data),

                                const SizedBox(height: 24),

                                // Rewards Comparison
                                _buildRewardsComparison(isDark, data),

                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
    bool isDark,
    MyCompetitionData data,
    BattleChallengeProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white : Colors.black87,
                size: 22,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerText(
                  text: '⚔️ Battle Comparison',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  colors: const [
                    Color(0xFF8B5CF6),
                    Color(0xFFEC4899),
                    Color(0xFF3B82F6),
                  ],
                ),
                Text(
                  'You vs ${data.competitors.length} competitors',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),

          // Refresh button
          GestureDetector(
            onTap: _refreshData,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isRefreshing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
          ),

          const SizedBox(width: 8),

          // Filter button
          GestureDetector(
            onTap: () => _toggleSection('leaderboard'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _expandedSections.contains('leaderboard')
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: isDark ? Colors.white : Colors.black87,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection(bool isDark, MyCompetitionData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GradientCard(
        gradientColors: const [
          Color(0xFF8B5CF6),
          Color(0xFFEC4899),
          Color(0xFF3B82F6),
        ],
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: const [
                    Color(0xFF8B5CF6),
                    Color(0xFFEC4899),
                    Color(0xFF3B82F6),
                  ].map((c) => c.withValues(alpha: 0.15)).toList(),
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🏆 LIVE LEADERBOARD',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '${data.allParticipants.length} participants competing',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const LiveIndicator(),
                ],
              ),
            ),

            // Leaderboard rows
            ...data.leaderboard.asMap().entries.map((entry) {
              final index = entry.key;
              final leaderboardEntry = entry.value;
              return EntryAnimationWrapper(
                index: index,
                child: LiveLeaderboardRow(
                  entry: leaderboardEntry,
                  index: index,
                ),
              );
            }),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    final categories = [
      ComparisonCategory.overall,
      ComparisonCategory.tasks,
      ComparisonCategory.goals,
      ComparisonCategory.buckets,
      ComparisonCategory.diary,
      ComparisonCategory.streaks,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.map<Widget>((category) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: CategoryChip(
              category: category,
              isSelected: _selectedCategory == category,
              onTap: () => _selectCategory(category),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarChart(bool isDark, MyCompetitionData data) {
    final barData = data.getBarChartData(_selectedCategory);
    final maxValue = barData
        .map((d) => d.value)
        .reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GradientCard(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedCategory
                          .toString()
                          .split('.')
                          .last
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Score Comparison',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Max: ${ScoreHelper.format(maxValue.toInt())}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bar Chart
            SizedBox(
              height: 240,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: barData.map((point) {
                  final normalizedHeight = maxValue > 0
                      ? (point.value / maxValue) * 140
                      : 0.0;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Tooltip
                          if (point.value > 0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: point.isUser
                                    ? point.color.withValues(alpha: 0.15)
                                    : (isDark
                                          ? Colors.white10
                                          : Colors.black.withValues(alpha: 0.05)),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: point.color.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                ScoreHelper.format(point.value.toInt()),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ),

                          // Bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.easeOutCubic,
                            height: normalizedHeight,
                            width: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: point.isUser
                                    ? const [
                                        Color(0xFF8B5CF6),
                                        Color(0xFFEC4899),
                                      ]
                                    : const [
                                        Color(0xFF3B82F6),
                                        Color(0xFF06B6D4),
                                      ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                                bottom: Radius.circular(4),
                              ),
                              boxShadow: point.isUser
                                  ? [
                                      BoxShadow(
                                        color: point.color.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Name
                          Text(
                            point.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: point.isUser
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              color: isDark
                                  ? (point.isUser
                                        ? Colors.white
                                        : Colors.white54)
                                  : (point.isUser
                                        ? Colors.black87
                                        : Colors.black45),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsTable(bool isDark, MyCompetitionData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              'DETAILED METRICS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white54 : Colors.black45,
                letterSpacing: 1.5,
              ),
            ),
          ),
          MetricsTable(
            participants: data.allParticipants,
            category: _selectedCategory,
          ),
        ],
      ),
    );
  }

  Widget _buildHeadToHeadSection(bool isDark, MyCompetitionData data) {
    if (data.competitors.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              'HEAD TO HEAD',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white54 : Colors.black45,
                letterSpacing: 1.5,
              ),
            ),
          ),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: data.competitors.length,
              itemBuilder: (context, index) {
                final competitor = data.competitors[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: HeadToHeadCard(
                    user: data.currentUser,
                    competitor: competitor,
                    onTap: () =>
                        _navigateToDetail(competitor.id, competitor.name),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(bool isDark, MyCompetitionData data) {
    final distributionData = DataAggregator.getDistributionData(
      data.allParticipants,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GradientCard(
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart_rounded,
                  color: isDark ? Colors.white70 : Colors.black54,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'POINT BREAKDOWN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white54 : Colors.black45,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: PieDistributionChart(
                    data: distributionData,
                    size: 150,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: distributionData.map((d) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: d.color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                d.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ),
                            Text(
                              ScoreHelper.format(d.value.toInt()),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakComparison(bool isDark, MyCompetitionData data) {
    final streaks = data.streakComparison;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              '🔥 STREAK WAR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white54 : Colors.black45,
                letterSpacing: 1.5,
              ),
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: streaks.length,
              itemBuilder: (context, index) {
                final streak = streaks[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: StreakWarCard(
                    name: streak.name,
                    current: streak.current,
                    longest: streak.longest,
                    isUser: streak.isUser,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsComparison(bool isDark, MyCompetitionData data) {
    final rewards = data.rewardsComparison;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              '🏅 HALL OF FAME',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white54 : Colors.black45,
                letterSpacing: 1.5,
              ),
            ),
          ),
          ...rewards.map((reward) => RewardsCompareRow(data: reward)),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: const Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading battle data...',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ErrorHandler.formatErrorMessage(error),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<BattleChallengeProvider>().refresh();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, BattleChallengeProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 48,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Data Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add competitors to see detailed comparison data.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  MyCompetitionData? _buildMyData(BattleChallengeProvider provider) {
    if (provider.userStats == null) return null;

    final userStats = provider.userStats!;

    // Build competitors list
    final competitors = provider.competitorsWithProfiles.map((c) {
      final stats = c.score!;
      return CompetitorData(
        id: c.competitor.id,
        name: c.displayName,
        avatarUrl: c.profileUrl,
        totalScore: stats.totalPoints,
        globalRank: stats.globalRank,
        currentStreak: stats.currentStreak,
        longestStreak: stats.longestStreak,
        completionRate: stats.completionRate,
        totalRewards: stats.totalRewards,
        averageRating: stats.ratingAverage,
        isOwner: false,
        dailyTasksCompleted: stats.tasksCompletedToday,
        dailyTasksTotal: stats.tasksTotalToday,
        weeklyTasksCompleted: stats.weekTasksCompleted,
        weeklyTasksTotal: stats.weekTasksTotal,
        dailyCompletionRate: stats.todayCompletionRate,
        weeklyCompletionRate: stats.weekTasksCompletionRate,
        activeGoals: stats.activeGoals,
        completedGoals: stats.completedGoals,
        goalsProgress: stats.goalsProgress,
        bucketsCompleted: stats.bucketsCompleted,
        bucketsTotal: stats.bucketsTotal,
        bucketCompletionRate: stats.bucketsCompletionRate,
        diaryEntries: stats.diaryEntriesThisWeek,
        moodAverage: stats.moodAverage,
        lastMoodEmoji: stats.diaryStats.lastdayMood?.emoji ?? '😐',
        taskPoints: stats.taskScore,
        goalPoints: stats.goalScore,
        bucketPoints: stats.bucketScore,
        diaryPoints: stats.diaryScore,
        streakPoints: stats.streakScore,
      );
    }).toList();

    return MyCompetitionData(
      currentUser: CompetitorData(
        id: userStats.profile.id,
        name: userStats.displayName,
        avatarUrl: userStats.profileUrl,
        totalScore: userStats.totalPoints,
        globalRank: userStats.globalRank,
        currentStreak: userStats.currentStreak,
        longestStreak: userStats.longestStreak,
        completionRate: userStats.completionRate,
        totalRewards: userStats.totalRewards,
        averageRating: userStats.ratingAverage,
        isOwner: true,
        dailyTasksCompleted: userStats.tasksCompletedToday,
        dailyTasksTotal: userStats.tasksTotalToday,
        weeklyTasksCompleted: userStats.weekTasksCompleted,
        weeklyTasksTotal: userStats.weekTasksTotal,
        dailyCompletionRate: userStats.todayCompletionRate,
        weeklyCompletionRate: userStats.weekTasksCompletionRate,
        activeGoals: userStats.activeGoals,
        completedGoals: userStats.completedGoals,
        goalsProgress: userStats.goalsProgress,
        bucketsCompleted: userStats.bucketsCompleted,
        bucketsTotal: userStats.bucketsTotal,
        bucketCompletionRate: userStats.bucketsCompletionRate,
        diaryEntries: userStats.diaryEntriesThisWeek,
        moodAverage: userStats.moodAverage,
        lastMoodEmoji: userStats.diaryStats.lastdayMood?.emoji ?? '😐',
        taskPoints: userStats.taskScore,
        goalPoints: userStats.goalScore,
        bucketPoints: userStats.bucketScore,
        diaryPoints: userStats.diaryScore,
        streakPoints: userStats.streakScore,
      ),
      competitors: competitors,
      lastUpdated: DateTime.now(),
    );
  }
}

// ================================================================
// BACKGROUND PAINTER
// ================================================================
class _BackgroundPainter extends CustomPainter {
  final double animationValue;
  final bool isDarkMode;

  _BackgroundPainter({required this.animationValue, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isDarkMode) return;

    final paint = Paint()
      ..color = const Color(0xFF0F0F16)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);

    for (int i = 0; i < 3; i++) {
      final x = size.width * (0.2 + (i * 0.3));
      final y =
          size.height *
          (0.3 + math.sin(animationValue * math.pi * 2 + i) * 0.1);
      final radius = 200.0;

      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            (i == 0
                    ? const Color(0xFF8B5CF6)
                    : i == 1
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFEC4899))
                .withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

      canvas.drawCircle(Offset(x, y), radius, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}
