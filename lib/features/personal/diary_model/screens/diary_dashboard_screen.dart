import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/user_settings/providers/settings_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import 'dart:async';

import '../../../../widgets/error_handler.dart' show ErrorHandler;
import '../../../../../widgets/bar_progress_indicator.dart';
import '../../../../../widgets/logger.dart';
import '../../../../../widgets/metric_indicators.dart';
import '../../task_model/tasks_sidebar.dart';
import '../models/diary_entry_model.dart';
import '../repositories/diary_repository.dart';

import '../../../../widgets/feature_info_widgets.dart';
import '../../../../services/security_service.dart';
import 'package:flutter/foundation.dart'; // For compute

class DiaryDashboardScreen extends StatefulWidget {
  const DiaryDashboardScreen({super.key});

  @override
  State<DiaryDashboardScreen> createState() => _DiaryDashboardScreenState();
}

class _DiaryDashboardScreenState extends State<DiaryDashboardScreen>
    with TickerProviderStateMixin {
  final _diaryRepo = DiaryRepository();
  final _scrollController = ScrollController();

  List<DiaryEntryModel> _allEntries = [];
  bool _isLoading = true;
  bool _hasTodayEntry = false;
  DiaryEntryModel? _todayEntry;
  StreamSubscription<List<DiaryEntryModel>>? _entriesSubscription;

  // Statistics
  int _totalEntries = 0;
  int _weeklyEntries = 0;
  int _monthlyEntries = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  double _averageMood = 0;
  Map<String, int> _moodDistribution = {};
  int _totalWords = 0;
  double _consistencyScore = 0.0;
  int _entryNumber = 0;

  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    logI('📊 Initializing DiaryDashboardScreen');

    _initAnimations();
    // Check auth after frame to have context for dialog
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuth());
    _setupDashboardStream();
  }

  @override
  void dispose() {
    _entriesSubscription?.cancel();
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    final provider = context.read<SettingsProvider>();
    final security = provider.security;

    if (security.requireAuthFor.diary) {
      final authenticated = await SecurityService().verifyIdentity(
        context: context,
        title: 'Diary Access Locked',
        message: 'Please verify your identity to view your private diary.',
      );

      if (!authenticated) {
        if (mounted) Navigator.pop(context);
      }
    }
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
  }

  String? _getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  void _setupDashboardStream() {
    try {
      logD('Setting up dashboard stream...');
      final userId = _getCurrentUserId();

      if (userId == null) {
        logW('No user logged in');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      _entriesSubscription = _diaryRepo
          .watchUserEntries(
            userId,
            limit: 100,
          ) // Scalability: Reduced from 1000
          .listen(
            (entries) {
              if (mounted) {
                _allEntries = entries;
                _calculateStatistics(entries);

                setState(() {
                  _isLoading = false;
                });

                if (!_fadeController.isAnimating &&
                    !_fadeController.isCompleted) {
                  _fadeController.forward();
                  _slideController.forward();
                }



                logI(
                  '✅ Dashboard stream updated successfully with ${entries.length} entries',
                );
              }
            },
            onError: (e, stackTrace) {
              logE(
                '❌ Error in dashboard stream',
                error: e,
                stackTrace: stackTrace,
              );
              if (mounted) {
                setState(() => _isLoading = false);
                ErrorHandler.showErrorSnackbar('Failed to load dashboard');
              }
            },
          );
    } catch (e, stackTrace) {
      logE(
        '❌ Error setting up dashboard stream',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showErrorSnackbar('Failed to load dashboard');
      }
    }
  }

  Future<void> _calculateStatistics(List<DiaryEntryModel> entries) async {
    // Scalability: Move heavy processing to background thread
    final stats = await compute(_heavyStatsCalculation, entries);

    if (!mounted) return;

    setState(() {
      _totalEntries = stats.totalEntries;
      _weeklyEntries = stats.weeklyEntries;
      _monthlyEntries = stats.monthlyEntries;
      _currentStreak = stats.currentStreak;
      _longestStreak = stats.longestStreak;
      _averageMood = stats.averageMood;
      _moodDistribution = stats.moodDistribution;
      _totalWords = stats.totalWords;

      // Update entry-specific derived values
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      try {
        _todayEntry = entries.firstWhere((e) => _isSameDay(e.entryDate, today));
        _hasTodayEntry = true;
        _consistencyScore = _todayEntry?.metadata?.consistencyScore ?? 0.0;
        _entryNumber = _todayEntry?.entryNumber ?? 0;
      } catch (e) {
        _todayEntry = null;
        _hasTodayEntry = false;
        if (entries.isNotEmpty) {
          final latest = entries.first;
          _consistencyScore = latest.metadata?.consistencyScore ?? 0.0;
          _entryNumber = latest.entryNumber;
        }
      }
    });

    logD('Stats calculation completed in Isolate');
  }

  void _calculateStreak(List<DiaryEntryModel> entries) {
    if (entries.isEmpty) {
      _currentStreak = 0;
      _longestStreak = 0;
      return;
    }

    final sorted = List<DiaryEntryModel>.from(entries)
      ..sort((a, b) => b.entryDate.compareTo(a.entryDate));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int streak = 0;
    DateTime checkDate = today;

    bool foundStart = false;
    for (final entry in sorted) {
      final entryDate = DateTime(
        entry.entryDate.year,
        entry.entryDate.month,
        entry.entryDate.day,
      );
      if (_isSameDay(entryDate, today) ||
          _isSameDay(entryDate, today.subtract(const Duration(days: 1)))) {
        foundStart = true;
        checkDate = entryDate;
        break;
      }
    }

    if (!foundStart) {
      _currentStreak = 0;
    } else {
      while (true) {
        final hasEntry = sorted.any((e) => _isSameDay(e.entryDate, checkDate));
        if (hasEntry) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      _currentStreak = streak;
    }

    int longest = 0;
    int current = 0;
    DateTime? lastDate;

    for (final entry in sorted.reversed) {
      final entryDate = DateTime(
        entry.entryDate.year,
        entry.entryDate.month,
        entry.entryDate.day,
      );

      if (lastDate == null ||
          entryDate.difference(lastDate).inDays == 1 ||
          _isSameDay(entryDate, lastDate)) {
        current++;
      } else {
        longest = math.max(longest, current);
        current = 1;
      }
      lastDate = entryDate;
    }
    longest = math.max(longest, current);
    _longestStreak = longest;
  }

  void _calculateMoodStats(List<DiaryEntryModel> entries) {
    final entriesWithMood = entries
        .where((e) => e.mood != null && e.mood!.label != null)
        .toList();

    if (entriesWithMood.isEmpty) {
      _averageMood = 0;
      _moodDistribution = {};
      return;
    }

    final totalMood = entriesWithMood.fold<double>(
      0,
      (sum, e) => sum + e.mood!.rating.toDouble(),
    );
    _averageMood = totalMood / entriesWithMood.length;

    _moodDistribution = {};
    for (final entry in entriesWithMood) {
      final label = entry.mood!.label ?? 'Unknown';
      _moodDistribution[label] = (_moodDistribution[label] ?? 0) + 1;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _navigateToNewEntry() {
    logD('Navigating to new entry');
    HapticFeedback.mediumImpact();
    context.pushNamed('diaryEntryScreen');
  }

  void _navigateToEntryList() {
    logD('Navigating to entry list');
    context.pushNamed('diaryListScreen');
  }

  void _navigateToEntry(DiaryEntryModel entry) {
    logD('Navigating to entry: ${entry.id}');
    context.pushNamed(
      'diaryEntryDetailScreen',
      pathParameters: {'entryId': entry.id},
      extra: entry,
    );
  }

  void _editTodayEntry() {
    if (_todayEntry != null) {
      logD('Editing today${_todayEntry!.id}');
      HapticFeedback.mediumImpact();
      context.pushNamed('diaryEntryScreen', extra: _todayEntry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Stack(
        children: [
          Container(
            color: colorScheme.surface,
            child: _isLoading
                ? _buildLoadingState(theme)
                : RefreshIndicator(
                    onRefresh: () async {},
                    color: colorScheme.primary,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        _buildSliverAppBar(theme),
                        SliverToBoxAdapter(
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Today's Status Card
                                    _buildTodayStatusCard(theme),
                                    const SizedBox(height: 20),

                                    // Quick Stats Row
                                    _buildQuickStatsRow(theme),
                                    const SizedBox(height: 20),

                                    // Consistency Card (Attendance)
                                    RepaintBoundary(
                                      child: _buildConsistencyCard(theme),
                                    ),
                                    const SizedBox(height: 20),

                                    // Streak Card
                                    RepaintBoundary(
                                      child: _buildStreakCard(theme),
                                    ),
                                    const SizedBox(height: 20),

                                    // Mood Analytics Card
                                    RepaintBoundary(
                                      child: _buildMoodAnalyticsCard(theme),
                                    ),
                                    const SizedBox(height: 20),

                                    // Writing Stats Card
                                    _buildWritingStatsCard(theme),
                                    const SizedBox(height: 20),

                                    // Weekly Calendar
                                    _buildWeeklyCalendar(theme),
                                    const SizedBox(height: 100),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildFloatingActionButton(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: theme.colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '📖 Loading your diary...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fetching your memories',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📔 ', style: TextStyle(fontSize: 20)),
            Text(
              'My Diary',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),

        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        expandedTitleScale: 1.2,
        background: const DashboardHeaderBackground(),
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.dashboard_outlined,
          color: Colors.blueAccent,
          size: 22,
        ),
        onPressed: () => TaskSidebarController.to.toggleSidebar(),
      ),
      actions: [
        IconButton(
          onPressed: () =>
              FeatureInfoCard.showEliteDialog(context, EliteFeatures.diary),
          icon: Icon(
            Icons.help_outline_rounded,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            size: 22,
          ),
          tooltip: 'How It Works',
        ),
      ],
    );
  }

  Widget _buildTodayStatusCard(ThemeData theme) {
    final now = DateTime.now();
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _hasTodayEntry ? 1.0 : _pulseAnimation.value,
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: _hasTodayEntry
                ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                : [colorScheme.primary, colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (_hasTodayEntry ? Colors.green : colorScheme.primary)
                  .withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: _hasTodayEntry ? _editTodayEntry : _navigateToNewEntry,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Left Side - Date and Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            DateFormat('EEEE').format(now),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          DateFormat('MMMM d').format(now),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          '${now.year}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _hasTodayEntry
                                    ? Icons.check_circle
                                    : Icons.pending_actions,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _hasTodayEntry
                                    ? 'Entry Complete! ✨'
                                    : 'Waiting for your story',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right Side - Action Button
                  Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          _hasTodayEntry ? Icons.edit_note : Icons.add,
                          color: _hasTodayEntry
                              ? Colors.green
                              : colorScheme.primary,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _hasTodayEntry ? 'Edit Entry' : 'Write Now',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            icon: Icons.numbers_rounded,
            value: '#$_entryNumber',
            label: 'Total Entries',
            color: theme.colorScheme.primary,
            gradient: [
              theme.colorScheme.primary.withValues(alpha: 0.1),
              theme.colorScheme.primary.withValues(alpha: 0.05),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            icon: Icons.verified_user_rounded,
            value: '${_consistencyScore.toStringAsFixed(1)}%',
            label: 'Consistency',
            color: Colors.orange,
            gradient: [
              Colors.orange.withValues(alpha: 0.1),
              Colors.orange.withValues(alpha: 0.05),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            icon: Icons.text_fields_rounded,
            value: _totalWords.toString(),
            label: 'Words',
            color: theme.colorScheme.secondary,
            gradient: [
              theme.colorScheme.secondary.withValues(alpha: 0.1),
              theme.colorScheme.secondary.withValues(alpha: 0.05),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConsistencyCard(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final isGood = _consistencyScore >= 75;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isGood
              ? Colors.green.withValues(alpha: 0.3)
              : colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Rate',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your diary consistency score',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isGood
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isGood ? 'Excellent' : 'Needs Improvement',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isGood ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: _consistencyScore / 100,
                    strokeWidth: 12,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: isGood ? Colors.green : Colors.orange,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_consistencyScore.toInt()}%',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isGood ? Colors.green : Colors.orange,
                      ),
                    ),
                    Text(
                      'Consistency',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Keep writing every day to maintain a 100% attendance record, just like a star student! 🌟',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(ThemeData theme) {
    final streakPercentage = (_currentStreak % 7) / 7;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Streak Fire Icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 40)),
                  Positioned(
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Streak',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentStreak == 1
                        ? '1 Day Strong!'
                        : '$_currentStreak Days Strong! 💪',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Next milestone: 7 days',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${7 - (_currentStreak % 7)} days to go',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: streakPercentage,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Best: $_longestStreak days',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodAnalyticsCard(ThemeData theme) {
    if (_moodDistribution.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mood,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Mood Data Yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add mood to your entries to see analytics',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insights,
                  size: 24,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mood Analytics',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your emotional patterns',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Average Mood Score
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getMoodColor(_getMoodLabel(_averageMood)).withValues(alpha: 0.1),
                  _getMoodColor(_getMoodLabel(_averageMood)).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(
                  _getMoodEmoji(_getMoodLabel(_averageMood)),
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Average Mood',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${_averageMood.toStringAsFixed(1)}/10',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getMoodColor(_getMoodLabel(_averageMood)),
                        ),
                      ),
                    ],
                  ),
                ),
                TaskMetricIndicator(
                  type: TaskMetricType.rating,
                  value: _averageMood / 2,
                  size: 20,
                  showLabel: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Mood Distribution
          ...['Amazing', 'Good', 'Okay', 'Sad', 'Rough'].map((mood) {
            final count = _moodDistribution[mood] ?? 0;
            final total = _moodDistribution.values.fold<int>(
              0,
              (a, b) => a + b,
            );
            final percentage = total > 0 ? count / total : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(
                    _getMoodEmoji(mood),
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 55,
                    child: Text(
                      mood,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: CustomProgressIndicator(
                      progress: percentage.clamp(0.0, 1.0),
                      progressBarName: '',
                      baseHeight: 10,
                      borderRadius: 5,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      gradientColors: [
                        _getMoodColor(mood).withOpacity(0.7),
                        _getMoodColor(mood),
                      ],
                      animationDuration: const Duration(milliseconds: 600),
                      animated: true,
                      progressLabelDisplay: ProgressLabelDisplay.none,
                      padding: EdgeInsets.zero,
                      margin: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 30,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$count',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getMoodColor(mood),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWritingStatsCard(ThemeData theme) {
    final avgWords = _totalEntries > 0
        ? (_totalWords / _totalEntries).round()
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit_note,
                  size: 24,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Writing Stats',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your writing journey',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildWritingStat(
                  theme,
                  icon: Icons.article,
                  value: _formatNumber(_totalWords),
                  label: 'Total Words',
                  color: Colors.blue,
                ),
              ),
              Container(
                height: 60,
                width: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildWritingStat(
                  theme,
                  icon: Icons.text_fields,
                  value: '$avgWords',
                  label: 'Avg/Entry',
                  color: Colors.green,
                ),
              ),
              Container(
                height: 60,
                width: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildWritingStat(
                  theme,
                  icon: Icons.auto_stories,
                  value: '${(_totalWords / 250).round()}',
                  label: 'Pages',
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // FIXED: Changed '\$number' to '\$number'
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return '$number';
  }

  Widget _buildWritingStat(
    ThemeData theme, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyCalendar(ThemeData theme) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get the start of the current week (Monday)
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  size: 24,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Week',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekStart.add(const Duration(days: 6)))}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekDays.map((day) {
              final hasEntry = _allEntries.any(
                (e) => _isSameDay(e.entryDate, day),
              );
              final isToday = _isSameDay(day, today);
              final isFuture = day.isAfter(today);

              return GestureDetector(
                onTap: hasEntry
                    ? () {
                        final entry = _allEntries.firstWhere(
                          (e) => _isSameDay(e.entryDate, day),
                        );
                        _navigateToEntry(entry);
                      }
                    : isToday || !isFuture
                    ? _navigateToNewEntry
                    : null,
                child: Column(
                  children: [
                    Text(
                      DateFormat('E').format(day).substring(0, 2),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isToday
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: isToday
                            ? LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withValues(alpha: 0.8),
                                ],
                              )
                            : hasEntry
                            ? const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                              )
                            : null,
                        color: isToday || hasEntry
                            ? null
                            : isFuture
                            ? theme.colorScheme.surfaceContainerHighest
                                  .withOpacity(0.5)
                            : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: isToday && !hasEntry
                            ? Border.all(
                                color: theme.colorScheme.primary,
                                width: 2,
                              )
                            : null,
                        boxShadow: (isToday || hasEntry)
                            ? [
                                BoxShadow(
                                  color:
                                      (hasEntry
                                              ? Colors.green
                                              : theme.colorScheme.primary)
                                          .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: hasEntry
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: isToday
                                      ? Colors.white
                                      : isFuture
                                      ? theme.colorScheme.onSurfaceVariant
                                            .withOpacity(0.5)
                                      : theme.colorScheme.error,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(theme, Colors.green, 'Completed'),
              const SizedBox(width: 20),
              _buildLegendItem(theme, theme.colorScheme.primary, 'Today'),
              const SizedBox(width: 20),
              _buildLegendItem(
                theme,
                theme.colorScheme.error.withValues(alpha: 0.5),
                'Missed',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(ThemeData theme, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // View All Button
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                heroTag: 'view_all',
                onPressed: _navigateToEntryList,
                backgroundColor: theme.colorScheme.surface,
                foregroundColor: theme.colorScheme.onSurface,
                elevation: 0,
                icon: const Icon(Icons.list_alt),
                label: const Text(
                  'View All',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Add Entry Button
          Expanded(
            flex: 2,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _hasTodayEntry ? 1.0 : _pulseAnimation.value,
                  child: child,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: _hasTodayEntry
                        ? [Colors.green, Colors.green.shade700]
                        : [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_hasTodayEntry
                                  ? Colors.green
                                  : theme.colorScheme.primary)
                              .withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  heroTag: 'add_entry',
                  onPressed: _hasTodayEntry
                      ? _editTodayEntry
                      : _navigateToNewEntry,
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  icon: Icon(_hasTodayEntry ? Icons.edit : Icons.add),
                  label: Text(
                    _hasTodayEntry ? 'Edit Today' : 'Write Entry',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'amazing':
        return '😄';
      case 'great':
        return '😄';
      case 'good':
        return '😊';
      case 'okay':
        return '😐';
      case 'sad':
        return '😔';
      case 'bad':
        return '😔';
      case 'rough':
        return '😢';
      case 'terrible':
        return '😢';
      default:
        return '😊';
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'amazing':
        return const Color(0xFF4CAF50);
      case 'great':
        return const Color(0xFF4CAF50);
      case 'good':
        return const Color(0xFF8BC34A);
      case 'okay':
        return const Color(0xFFFFC107);
      case 'sad':
        return const Color(0xFFFF9800);
      case 'bad':
        return const Color(0xFFFF9800);
      case 'rough':
        return const Color(0xFFF44336);
      case 'terrible':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  String _getMoodLabel(double averageMood) {
    if (averageMood >= 9) return 'Amazing';
    if (averageMood >= 7) return 'Good';
    if (averageMood >= 5) return 'Okay';
    if (averageMood >= 3) return 'Sad';
    return 'Rough';
  }
}

// ================================================================
// 📊 STATS ISOLATE LOGIC
// ================================================================

class DiaryStats {
  final int totalEntries;
  final int weeklyEntries;
  final int monthlyEntries;
  final int currentStreak;
  final int longestStreak;
  final double averageMood;
  final Map<String, int> moodDistribution;
  final int totalWords;

  DiaryStats({
    required this.totalEntries,
    required this.weeklyEntries,
    required this.monthlyEntries,
    required this.currentStreak,
    required this.longestStreak,
    required this.averageMood,
    required this.moodDistribution,
    required this.totalWords,
  });
}

DiaryStats _heavyStatsCalculation(List<DiaryEntryModel> entries) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekAgo = today.subtract(const Duration(days: 7));
  final monthAgo = today.subtract(const Duration(days: 30));

  final totalEntries = entries.length;

  final weeklyEntries = entries
      .where(
        (e) =>
            e.entryDate.isAfter(weekAgo) ||
            _isSameDayStatic(e.entryDate, weekAgo),
      )
      .length;

  final monthlyEntries = entries
      .where(
        (e) =>
            e.entryDate.isAfter(monthAgo) ||
            _isSameDayStatic(e.entryDate, monthAgo),
      )
      .length;

  // Streak Calculation
  int currentStreak = 0;
  int longestStreak = 0;

  if (entries.isNotEmpty) {
    final sorted = List<DiaryEntryModel>.from(entries)
      ..sort((a, b) => b.entryDate.compareTo(a.entryDate));

    // Current Streak
    bool foundStart = false;
    DateTime checkDate = today;
    for (final entry in sorted) {
      final entryDate = DateTime(
        entry.entryDate.year,
        entry.entryDate.month,
        entry.entryDate.day,
      );
      if (_isSameDayStatic(entryDate, today) ||
          _isSameDayStatic(
            entryDate,
            today.subtract(const Duration(days: 1)),
          )) {
        foundStart = true;
        checkDate = entryDate;
        break;
      }
    }

    if (foundStart) {
      int streak = 0;
      while (true) {
        final dateToSearch = checkDate;
        final hasEntry = sorted.any(
          (e) => _isSameDayStatic(e.entryDate, dateToSearch),
        );
        if (hasEntry) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      currentStreak = streak;
    }

    // Longest Streak
    int longest = 0;
    int current = 0;
    DateTime? lastDate;
    for (final entry in sorted.reversed) {
      final entryDate = DateTime(
        entry.entryDate.year,
        entry.entryDate.month,
        entry.entryDate.day,
      );
      if (lastDate == null ||
          entryDate.difference(lastDate).inDays == 1 ||
          _isSameDayStatic(entryDate, lastDate)) {
        current++;
      } else {
        longest = math.max(longest, current);
        current = 1;
      }
      lastDate = entryDate;
    }
    longestStreak = math.max(longest, current);
  }

  // Mood Stats
  final entriesWithMood = entries
      .where((e) => e.mood != null && e.mood!.label != null)
      .toList();
  double averageMood = 0;
  Map<String, int> moodDistribution = {};

  if (entriesWithMood.isNotEmpty) {
    final totalMoodRating = entriesWithMood.fold<double>(
      0,
      (sum, e) => sum + e.mood!.rating.toDouble(),
    );
    averageMood = totalMoodRating / entriesWithMood.length;
    for (final entry in entriesWithMood) {
      final label = entry.mood!.label ?? 'Unknown';
      moodDistribution[label] = (moodDistribution[label] ?? 0) + 1;
    }
  }

  // Word Count
  final totalWords = entries.fold(0, (sum, e) {
    if (e.content == null || e.content!.isEmpty) return sum;
    return sum +
        e.content!.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
  });

  return DiaryStats(
    totalEntries: totalEntries,
    weeklyEntries: weeklyEntries,
    monthlyEntries: monthlyEntries,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    averageMood: averageMood,
    moodDistribution: moodDistribution,
    totalWords: totalWords,
  );
}

bool _isSameDayStatic(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

// ================================================================
// 🎨 OPTIMIZED UI COMPONENTS
// ================================================================

class DashboardHeaderBackground extends StatelessWidget {
  const DashboardHeaderBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
