// ================================================================
// FILE: lib/features/competition/screens/competition_overview_screen.dart
// Competition Overview Screen - Main Dashboard
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import '../../../../widgets/error_handler.dart';
import '../../../../widgets/feature_info_widgets.dart';
import '../providers/competition_provider.dart';
import '../widgets/common/competition_animations.dart';
import '../widgets/common/competition_models.dart';
import '../widgets/common/competition_shared_widgets.dart';
import '../widgets/screen_specific/overview_widgets.dart';
import '../widgets/screen_specific/competition_charts.dart';
import 'competition_detail_screen.dart';
import 'my_competition_data_screen.dart';
import 'add_competitor_sheet.dart';

// ================================================================
// COMPETITION OVERVIEW SCREEN
// ================================================================
class CompetitionOverviewScreen extends StatefulWidget {
  final String? userId;

  const CompetitionOverviewScreen({
    super.key,
    this.userId,
  });

  @override
  State<CompetitionOverviewScreen> createState() => _CompetitionOverviewScreenState();
}

class _CompetitionOverviewScreenState extends State<CompetitionOverviewScreen>
    with TickerProviderStateMixin, CompetitionAnimationMixin {
  late AnimationController _bgController;
  String? _selectedCompetitorId;

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

  void _navigateToMyData() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyCompetitionDataScreen(userId: widget.userId),
      ),
    );
  }

  void _showAddCompetitorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCompetitorSheet(
        onCompetitorAdded: () {
          context.read<BattleChallengeProvider>().refresh();
        },
      ),
    );
  }

  Future<void> _refreshData() async {
    await context.read<BattleChallengeProvider>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Battle Arena',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          // Help Button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(
                Icons.help_outline_rounded,
                color: isDark ? Colors.white70 : Colors.black54,
                size: 22,
              ),
              onPressed: () => FeatureInfoCard.showEliteDialog(
                context,
                EliteFeatures.competition,
              ),
            ),
          ),
          Consumer<BattleChallengeProvider>(
            builder: (context, provider, child) {
              final data = _buildOverviewData(provider);
              if (data == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: _navigateToMyData,
                  child: PulseAvatar(
                    imageUrl: data.currentUser.avatarUrl,
                    name: data.currentUser.name,
                    size: 36,
                    borderGradient: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    showPulse: true,
                  ),
                ),
              );
            },
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

                final data = _buildOverviewData(provider);
                if (data == null || data.competitors.isEmpty) {
                  return _buildEmptyState(isDark, provider);
                }

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  color: const Color(0xFF8B5CF6),
                  backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
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
                                const SizedBox(height: 80), // Space for AppBar

                                // Stats Summary
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: StatsSummaryCard(
                                    totalPoints: data.currentUser.totalScore,
                                    totalRewards: data.currentUser.totalRewards,
                                    completionRate: data.currentUser.completionRate,
                                    currentStreak: data.currentUser.currentStreak,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Score Comparison Chart
                                if (data.competitors.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: BarComparisonChart(
                                      data: data.scoreComparisonData,
                                      height: 250,
                                      title: 'Score Comparison',
                                      onBarTap: (index) {
                                        if (index == 0) {
                                          _navigateToMyData();
                                        } else if (index - 1 < data.topCompetitors.length) {
                                          final competitor = data.topCompetitors[index - 1];
                                          _navigateToDetail(competitor.id, competitor.name);
                                        }
                                      },
                                    ),
                                  ),

                                const SizedBox(height: 24),

                                // Competitor Avatars
                                if (data.competitors.isNotEmpty)
                                  CompetitorAvatarStrip(
                                    competitors: data.competitors,
                                    selectedId: _selectedCompetitorId,
                                    onTap: (competitor) {
                                      setState(() => _selectedCompetitorId = competitor.id);
                                      context.pushNamed(
                                        'otherUserProfileScreen',
                                        pathParameters: {'userId': competitor.id},
                                      );
                                    },
                                    onAddTap: _showAddCompetitorSheet,
                                    maxDisplay: 5,
                                  ),

                                const SizedBox(height: 24),

                                // Progress Grid
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: _buildProgressGrid(data, isDark),
                                ),

                                const SizedBox(height: 24),

                                // Activity Timeline
                                if (data.recentActivities.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: _buildTimelineSection(data, isDark),
                                  ),
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
            'Loading your battle data...',
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

  Widget _buildEmptyState(bool isDark, BattleChallengeProvider provider) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          children: [
            FeatureInfoCard(feature: EliteFeatures.competition),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _showAddCompetitorSheet,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text(
                'Add Your First Competitor',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                elevation: 10,
                shadowColor: const Color(0xFF8B5CF6).withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressGrid(CompetitionOverviewData data, bool isDark) {
    final user = data.currentUser;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: [
        ProgressGridCard(
          title: 'Tasks',
          icon: Icons.task_alt_rounded,
          progress: user.tasksCompletionRate,
          value: '${user.completedTasks}/${user.totalTasks}',
          subtitle: '${user.dailyCompletionRate.toStringAsFixed(0)}% today',
          gradientColors: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          onTap: () {
            // Navigate to tasks detail
          },
        ),
        ProgressGridCard(
          title: 'Goals',
          icon: Icons.flag_rounded,
          progress: user.goalsProgress,
          value: '${user.completedGoals}/${user.activeGoals}',
          subtitle: '${user.goalsProgress.toStringAsFixed(0)}% complete',
          gradientColors: const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
          onTap: () {
            // Navigate to goals detail
          },
        ),
        ProgressGridCard(
          title: 'Buckets',
          icon: Icons.inventory_2_rounded,
          progress: user.bucketCompletionRate,
          value: '${user.bucketsCompleted}/${user.bucketsTotal}',
          subtitle: '${user.bucketCompletionRate.toStringAsFixed(0)}% done',
          gradientColors: const [Color(0xFFF97316), Color(0xFFFBBF24)],
          onTap: () {
            // Navigate to buckets detail
          },
        ),
        ProgressGridCard(
          title: 'Streak',
          icon: Icons.local_fire_department_rounded,
          progress: (user.currentStreak / 30) * 100,
          value: '${user.currentStreak}d',
          subtitle: 'Longest: ${user.longestStreak}d',
          gradientColors: const [Color(0xFFEF4444), Color(0xFFF97316)],
          onTap: () {
            // Navigate to streak detail
          },
        ),
      ],
    );
  }

  Widget _buildTimelineSection(CompetitionOverviewData data, bool isDark) {
    return GradientCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Activity Timeline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              const LiveIndicator(),
            ],
          ),
          const SizedBox(height: 20),
          ...data.recentActivities.take(5).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            return EntryAnimationWrapper(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ActivityTimelineTile(
                  event: event,
                  isSelected: false,
                  onTap: () {
                    // Navigation removed per user request
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  CompetitionOverviewData? _buildOverviewData(BattleChallengeProvider provider) {
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

    return CompetitionOverviewData(
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

  _BackgroundPainter({
    required this.animationValue,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isDarkMode) return;

    final paint = Paint()
      ..color = const Color(0xFF0F0F16)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, paint);

    // Ambient glows
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