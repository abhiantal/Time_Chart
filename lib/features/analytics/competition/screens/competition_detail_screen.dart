// ================================================================
// FILE: lib/features/competition/screens/competition_detail_screen.dart
// Competition Detail Screen - 1v1 Comparison View
// ================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/app_snackbar.dart';
import '../../../../widgets/error_handler.dart';
import '../providers/competition_provider.dart';
import '../widgets/common/competition_animations.dart';
import '../widgets/common/competition_helpers.dart';
import '../widgets/common/competition_models.dart';
import '../widgets/common/competition_shared_widgets.dart';
import '../widgets/screen_specific/detail_widgets.dart';
import '../widgets/screen_specific/competition_charts.dart';

// ================================================================
// COMPETITION DETAIL SCREEN
// ================================================================
class CompetitionDetailScreen extends StatefulWidget {
  final String competitorId;
  final String? competitorName;

  const CompetitionDetailScreen({
    super.key,
    required this.competitorId,
    this.competitorName,
  });

  @override
  State<CompetitionDetailScreen> createState() => _CompetitionDetailScreenState();
}

class _CompetitionDetailScreenState extends State<CompetitionDetailScreen>
    with TickerProviderStateMixin, CompetitionAnimationMixin {
  late AnimationController _bgController;
  ComparisonCategory _selectedCategory = ComparisonCategory.overall;
  final Set<String> _expandedMetrics = {};
  bool _isRefreshing = false;
  // Removed unused _currentUserId

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    initCompetitionAnimations(enableFloat: true, enableGlow: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
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
      SnackbarService().showSuccess('Data refreshed');
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to refresh data');
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  void _showRemoveCompetitorDialog(CompetitionDetailData data) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 12),
            const Text('Remove Competitor'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove ${data.competitor.name} from your competition list?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeCompetitor();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeCompetitor() async {
    try {
      final provider = context.read<BattleChallengeProvider>();
      final success = await provider.removeCompetitor(widget.competitorId);

      if (success && mounted) {
        Navigator.pop(context);
        SnackbarService().showSuccess('Competitor removed successfully');
      }
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to remove competitor');
    }
  }

  void _selectCategory(ComparisonCategory category) {
    HapticFeedback.selectionClick();
    setState(() => _selectedCategory = category);
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<BattleChallengeProvider>().clearSelectedBattle();
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
            ),
          ),
        ),
        title: Consumer<BattleChallengeProvider>(
          builder: (context, provider, child) {
            final data = _buildDetailData(provider);
            if (data == null) return const Text('Battle Details');
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'You vs ${data.competitor.name}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'Updated ${provider.lastRefreshed != null ? DateHelper.timeAgo(provider.lastRefreshed!) : 'never'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
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

                final data = _buildDetailData(provider);
                if (data == null) {
                  return _buildNotFoundState(isDark);
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
                                const SizedBox(height: 10), // Reduced space since AppBar is fixed now

                                // Epic Battle Header
                                EpicBattleHeader(
                                  user: data.user,
                                  competitor: data.competitor,
                                ),

                                const SizedBox(height: 20),

                                // Live Score Tracker
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: LiveScoreProgress(
                                    userScore: data.user.totalScore,
                                    competitorScore: data.competitor.totalScore,
                                    userName: 'You',
                                    competitorName: data.competitor.name,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Category Selector
                                CategoryTabBar(
                                  selectedCategory: _selectedCategory,
                                  onCategorySelected: _selectCategory,
                                ),

                                const SizedBox(height: 24),

                                // Radar Chart
                                if (_selectedCategory == ComparisonCategory.overall)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: _buildRadarChart(isDark, data),
                                  ),

                                // Bar Chart for specific category
                                if (_selectedCategory != ComparisonCategory.overall)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: _buildCategoryChart(isDark, data),
                                  ),

                                const SizedBox(height: 24),

                                // Metric Cards
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: _buildMetricCards(data),
                                ),

                                const SizedBox(height: 24),

                                // Dual Progress Rings
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: GradientCard(
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Overall Completion',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        DualProgressRing(
                                          userProgress: data.user.completionRate,
                                          competitorProgress: data.competitor.completionRate,
                                          userLabel: 'You',
                                          competitorLabel: data.competitor.name.split(' ').first,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Winner Badge
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: WinnerStatusBadge(
                                    isUserWinning: data.isUserWinning,
                                    isTied: data.isTied,
                                    pointDifference: data.pointDifference,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Streak Comparison
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: GradientCard(
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Streak Battle',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        StreakCompareRow(
                                          userStreak: data.user.currentStreak,
                                          competitorStreak: data.competitor.currentStreak,
                                          userLongest: data.user.longestStreak,
                                          competitorLongest: data.competitor.longestStreak,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Action Buttons
                                _buildActionButtons(isDark, data),

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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildNotFoundState(bool isDark) {
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
                Icons.person_off_rounded,
                size: 48,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Competitor Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This competitor may have been removed from your list.',
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildRadarChart(bool isDark, CompetitionDetailData data) {
    return GradientCard(
      child: Column(
        children: [
          const Text(
            'Performance Comparison',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Center(
            child: RadarComparisonChart(
              datasets: data.radarData,
              labels: data.radarLabels,
              size: 250,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('You', const Color(0xFF8B5CF6)),
              _buildLegendItem(data.competitor.name, const Color(0xFF3B82F6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildCategoryChart(bool isDark, CompetitionDetailData data) {
    ChartDataPoint userPoint;
    ChartDataPoint competitorPoint;

    switch (_selectedCategory) {
      case ComparisonCategory.tasks:
        userPoint = ChartDataPoint(
          label: 'You',
          value: data.user.tasksCompletionRate,
          color: const Color(0xFF8B5CF6),
        );
        competitorPoint = ChartDataPoint(
          label: data.competitor.name,
          value: data.competitor.tasksCompletionRate,
          color: const Color(0xFF3B82F6),
        );
        break;
      case ComparisonCategory.goals:
        userPoint = ChartDataPoint(
          label: 'You',
          value: data.user.goalsProgress,
          color: const Color(0xFF8B5CF6),
        );
        competitorPoint = ChartDataPoint(
          label: data.competitor.name,
          value: data.competitor.goalsProgress,
          color: const Color(0xFF3B82F6),
        );
        break;
      case ComparisonCategory.buckets:
        userPoint = ChartDataPoint(
          label: 'You',
          value: data.user.bucketCompletionRate,
          color: const Color(0xFF8B5CF6),
        );
        competitorPoint = ChartDataPoint(
          label: data.competitor.name,
          value: data.competitor.bucketCompletionRate,
          color: const Color(0xFF3B82F6),
        );
        break;
      case ComparisonCategory.diary:
        userPoint = ChartDataPoint(
          label: 'You',
          value: (data.user.diaryEntries / 30) * 100,
          color: const Color(0xFF8B5CF6),
        );
        competitorPoint = ChartDataPoint(
          label: data.competitor.name,
          value: (data.competitor.diaryEntries / 30) * 100,
          color: const Color(0xFF3B82F6),
        );
        break;
      case ComparisonCategory.streaks:
        userPoint = ChartDataPoint(
          label: 'You',
          value: (data.user.currentStreak / 30) * 100,
          color: const Color(0xFF8B5CF6),
        );
        competitorPoint = ChartDataPoint(
          label: data.competitor.name,
          value: (data.competitor.currentStreak / 30) * 100,
          color: const Color(0xFF3B82F6),
        );
        break;
      default:
        return const SizedBox();
    }

    return GradientCard(
      child: Column(
        children: [
          Text(
            _selectedCategory.toString().split('.').last.toUpperCase(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: _buildCategoryBar(
                    label: 'You',
                    value: userPoint.value,
                    color: userPoint.color,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildCategoryBar(
                    label: data.competitor.name.split(' ').first,
                    value: competitorPoint.value,
                    color: competitorPoint.color,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar({
    required String label,
    required double value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: 140,
          width: 60,
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 140 * (value / 100).clamp(0.0, 1.0),
              width: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${value.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCards(CompetitionDetailData data) {
    return Column(
      children: data.metricComparisons.map((metric) {
        return EntryAnimationWrapper(
          index: data.metricComparisons.indexOf(metric),
          child: MetricComparisonCard(
            metric: metric,
            initiallyExpanded: _expandedMetrics.contains(metric.category),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(bool isDark, CompetitionDetailData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showRemoveCompetitorDialog(data),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_remove_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Remove',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  CompetitionDetailData? _buildDetailData(BattleChallengeProvider provider) {
    if (provider.userStats == null) return null;

    final userStats = provider.userStats!;

    // Find competitor stats
    final competitorWithProfile = provider.competitorsWithProfiles
        .firstWhere(
          (c) => c.competitor.id == widget.competitorId,
      orElse: () => throw Exception('Competitor not found'),
    );

    final competitorStats = competitorWithProfile.score!;

    return CompetitionDetailData(
      user: CompetitorData(
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
      competitor: CompetitorData(
        id: competitorStats.profile.id,
        name: competitorWithProfile.displayName,
        avatarUrl: competitorWithProfile.profileUrl,
        totalScore: competitorStats.totalPoints,
        globalRank: competitorStats.globalRank,
        currentStreak: competitorStats.currentStreak,
        longestStreak: competitorStats.longestStreak,
        completionRate: competitorStats.completionRate,
        totalRewards: competitorStats.totalRewards,
        averageRating: competitorStats.ratingAverage,
        isOwner: false,
        dailyTasksCompleted: competitorStats.tasksCompletedToday,
        dailyTasksTotal: competitorStats.tasksTotalToday,
        weeklyTasksCompleted: competitorStats.weekTasksCompleted,
        weeklyTasksTotal: competitorStats.weekTasksTotal,
        dailyCompletionRate: competitorStats.todayCompletionRate,
        weeklyCompletionRate: competitorStats.weekTasksCompletionRate,
        activeGoals: competitorStats.activeGoals,
        completedGoals: competitorStats.completedGoals,
        goalsProgress: competitorStats.goalsProgress,
        bucketsCompleted: competitorStats.bucketsCompleted,
        bucketsTotal: competitorStats.bucketsTotal,
        bucketCompletionRate: competitorStats.bucketsCompletionRate,
        diaryEntries: competitorStats.diaryEntriesThisWeek,
        moodAverage: competitorStats.moodAverage,
        lastMoodEmoji: competitorStats.diaryStats.lastdayMood?.emoji ?? '😐',
        taskPoints: competitorStats.taskScore,
        goalPoints: competitorStats.goalScore,
        bucketPoints: competitorStats.bucketScore,
        diaryPoints: competitorStats.diaryScore,
        streakPoints: competitorStats.streakScore,
      ),
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

  _BackgroundPainter({
    required this.animationValue,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isDarkMode) return;

    final paint = Paint()..color = const Color(0xFF0F0F16)..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);

    for (int i = 0; i < 3; i++) {
      final x = size.width * (0.2 + (i * 0.3));
      final y = size.height * (0.3 + math.sin(animationValue * math.pi * 2 + i) * 0.1);
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