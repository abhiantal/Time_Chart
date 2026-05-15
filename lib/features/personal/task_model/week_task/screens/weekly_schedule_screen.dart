// lib/features/personal/post_shared/task_model/week_task/screens_widgets/weekly_schedule_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../widgets/circular_progress_indicator.dart';
import '../../tasks_sidebar.dart';
import '../models/week_task_model.dart';
import '../widgets/grid_task_card.dart';
import '../widgets/time_slot_manager_dialog.dart';
import 'package:provider/provider.dart';
import '../providers/week_task_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../widgets/logger.dart';
import '../../../../../widgets/feature_info_widgets.dart';

class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen>
    with TickerProviderStateMixin {
  // Scroll Controllers
  final ScrollController _mainVerticalController = ScrollController();
  final ScrollController _mainHorizontalController = ScrollController();
  final ScrollController _timeSlotVerticalController = ScrollController();
  final ScrollController _dayHeaderHorizontalController = ScrollController();
  final ScrollController _gridVerticalController = ScrollController();
  bool _isSyncingScroll = false;

  // Animation Controllers
  late AnimationController _fabAnimationController;
  late AnimationController _headerAnimationController;
  late AnimationController _statsAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _statsScaleAnimation;

  DateTime _viewDate = DateTime.now();

  // ── ── Feature Info Data ── ──
  // Relocated to EliteFeatures.weekTasks

  void _nextWeek() {
    setState(() {
      _viewDate = _viewDate.add(const Duration(days: 7));
    });
  }

  void _previousWeek() {
    setState(() {
      _viewDate = _viewDate.subtract(const Duration(days: 7));
    });
  }

  // Time slots
  List<TimeSlot> timeSlots = [];
  bool _isLoadingSlots = true;

  final List<Map<String, dynamic>> dayData = [
    {
      'name': 'Monday',
      'short': 'Mon',
      'emoji': '💼',
      'color': Color(0xFF667eea),
    },
    {
      'name': 'Tuesday',
      'short': 'Tue',
      'emoji': '📌',
      'color': Color(0xFF764ba2),
    },
    {
      'name': 'Wednesday',
      'short': 'Wed',
      'emoji': '🎯',
      'color': Color(0xFF43E97B),
    },
    {
      'name': 'Thursday',
      'short': 'Thu',
      'emoji': '⚡',
      'color': Color(0xFFF5AF19),
    },
    {
      'name': 'Friday',
      'short': 'Fri',
      'emoji': '🚀',
      'color': Color(0xFFFA709A),
    },
    {
      'name': 'Saturday',
      'short': 'Sat',
      'emoji': '🎉',
      'color': Color(0xFF00BCD4),
    },
    {
      'name': 'Sunday',
      'short': 'Sun',
      'emoji': '☀️',
      'color': Color(0xFFFF6B6B),
    },
  ];

  @override
  void initState() {
    super.initState();
    _initController();
    _loadTimeSlots();
    _setupScrollSynchronization();
    _initAnimations();
    HapticFeedback.lightImpact();
  }

  void _initController() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final provider = Provider.of<WeekTaskProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (userId != null) {
        provider.setUserId(userId);
      } else {
        provider.loadTasks();
      }
    });
  }

  void _initAnimations() {
    // FAB Animation
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // Header Animation
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerSlideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Stats Animation
    _statsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _statsScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _statsAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _headerAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _statsAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _fabAnimationController.forward();
    });
  }

  Future<void> _loadTimeSlots() async {
    setState(() => _isLoadingSlots = true);
    final slots = await TimeSlotPreferences.loadTimeSlots();
    final sortedSlots = _sortTimeSlots(slots);
    setState(() {
      timeSlots = sortedSlots;
      _isLoadingSlots = false;
    });
  }

  List<TimeSlot> _sortTimeSlots(List<TimeSlot> slots) {
    final sorted = List<TimeSlot>.from(slots);
    sorted.sort((a, b) {
      final timeA = _parseTime(a.startTime);
      final timeB = _parseTime(b.startTime);
      return timeA.compareTo(timeB);
    });
    return sorted;
  }

  int _parseTime(dynamic time) {
    try {
      if (time is DateTime) return time.hour * 60 + time.minute;
      if (time is! String) return 0;

      final timeUpper = time.trim().toUpperCase();
      final hasAMPM = timeUpper.contains('AM') || timeUpper.contains('PM');
      final isPM = timeUpper.contains('PM');
      final cleanTime = timeUpper
          .replaceAll('AM', '')
          .replaceAll('PM', '')
          .trim();
      final parts = cleanTime.split(':');

      if (parts.length != 2) return 0;

      int hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;

      if (hasAMPM) {
        if (isPM && hours != 12) hours += 12;
        if (!isPM && hours == 12) hours = 0;
      }

      return hours * 60 + minutes;
    } catch (e) {
      return 0;
    }
  }

  void _setupScrollSynchronization() {
    _mainHorizontalController.addListener(() {
      if (_dayHeaderHorizontalController.hasClients &&
          _dayHeaderHorizontalController.offset !=
              _mainHorizontalController.offset) {
        _dayHeaderHorizontalController.jumpTo(_mainHorizontalController.offset);
      }
    });

    _gridVerticalController.addListener(() {
      if (_isSyncingScroll) return;
      _isSyncingScroll = true;
      if (_timeSlotVerticalController.hasClients &&
          _timeSlotVerticalController.offset !=
              _gridVerticalController.offset) {
        _timeSlotVerticalController.jumpTo(_gridVerticalController.offset);
      }
      _isSyncingScroll = false;
    });

    _timeSlotVerticalController.addListener(() {
      if (_isSyncingScroll) return;
      _isSyncingScroll = true;
      if (_gridVerticalController.hasClients &&
          _gridVerticalController.offset !=
              _timeSlotVerticalController.offset) {
        _gridVerticalController.jumpTo(_timeSlotVerticalController.offset);
      }
      _isSyncingScroll = false;
    });
  }

  @override
  void dispose() {
    _mainHorizontalController.dispose();
    _mainVerticalController.dispose();
    _timeSlotVerticalController.dispose();
    _dayHeaderHorizontalController.dispose();
    _gridVerticalController.dispose();
    _fabAnimationController.dispose();
    _headerAnimationController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }

  List<TimeSlot> _getEffectiveTimeSlots(WeekTaskProvider provider) {
    if (timeSlots.isEmpty && provider.tasks.isEmpty) return timeSlots;

    final allSlots = <TimeSlot>{...timeSlots};

    for (final task in provider.tasks) {
      if (!task.isActive && task.indicators.status != 'completed') continue;

      final taskStartStr = _formatTime(task.timeline.startingTime);
      final taskEndStr = _formatTime(task.timeline.endingTime);

      final taskStart = _parseTime(taskStartStr);
      final taskEnd = _parseTime(taskEndStr);

      bool isCovered = false;
      for (final slot in allSlots) {
        final slotStart = _parseTime(slot.startTime);
        final slotEnd = _parseTime(slot.endTime);
        if (taskStart < slotEnd && taskEnd > slotStart) {
          isCovered = true;
          break;
        }
      }

      if (!isCovered && taskStart < taskEnd) {
        allSlots.add(TimeSlot(startTime: taskStartStr, endTime: taskEndStr));
      }
    }

    return _sortTimeSlots(allSlots.toList());
  }

  void _showTimeSlotManager() {
    HapticFeedback.lightImpact();
    final provider = Provider.of<WeekTaskProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => TimeSlotManagerDialog(
        timeSlots: _getEffectiveTimeSlots(provider),
        onSave: (newSlots) async {
          final sortedNewSlots = _sortTimeSlots(newSlots);

          // Identify slots that were removed or modified
          final lostSlots = timeSlots.where((oldSlot) =>
          !sortedNewSlots.any((newSlot) =>
          newSlot.startTime == oldSlot.startTime &&
              newSlot.endTime == oldSlot.endTime
          )
          ).toList();

          if (lostSlots.isNotEmpty) {
            final provider = Provider.of<WeekTaskProvider>(context, listen: false);
            final allTasksToDelete = <String>{};

            for (final lostSlot in lostSlots) {
              // Find tasks that overlap with the removed slot
              final tasksForSlot = provider.tasks.where((task) {
                final taskStart = _parseTime(task.timeline.startingTime);
                final taskEnd = _parseTime(task.timeline.endingTime);
                final slotStart = _parseTime(lostSlot.startTime);
                final slotEnd = _parseTime(lostSlot.endTime);

                return taskStart < slotEnd && taskEnd > slotStart;
              });

              for (final task in tasksForSlot) {
                allTasksToDelete.add(task.id);
              }
            }

            if (allTasksToDelete.isNotEmpty) {
              logI('🗑️  Cleaning up ${allTasksToDelete.length} tasks for removed time slots');
              for (final taskId in allTasksToDelete) {
                await provider.deleteTask(taskId);
              }
              // Force reload to ensure status and points match
              await provider.loadTasks();
            }
          }

          setState(() => timeSlots = sortedNewSlots);
          await TimeSlotPreferences.saveTimeSlots(sortedNewSlots);
        },
      ),
    );
  }

  void _navigateToAddTask() {
    HapticFeedback.lightImpact();
    context.push('/personalNav/addWeeklyTask');
  }

  int _getWeekNumber(DateTime date) {
    final dayOfYear = int.parse(DateFormat('D').format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<WeekTaskProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading || _isLoadingSlots) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
            body: Center(child: _buildLoadingState(colorScheme, isDark)),
          );
        }

        final effectiveSlots = _getEffectiveTimeSlots(provider);

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
          body: CustomScrollView(
            controller: _mainVerticalController,
            slivers: [
              _buildSliverAppBar(theme, colorScheme, isDark, provider),
              SliverFillRemaining(
                hasScrollBody: true,
                child: provider.tasks.isEmpty
                    ? _buildEmptyState(colorScheme, isDark)
                    : _buildTimetableGrid(colorScheme, isDark, effectiveSlots),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // SLIVER APP BAR - COMPLETELY REDESIGNED
  // ============================================================
  Widget _buildSliverAppBar(
      ThemeData theme,
      ColorScheme colorScheme,
      bool isDark,
      WeekTaskProvider provider,
      ) {
    final totalTasks = provider.tasks.length;
    final activeTasks = provider.inProgressTasks.length;
    final completedTasks = provider.completedTasks.length;
    final pendingTasks = provider.pendingTasks.length;
    final missedTasks = provider.tasksNeedingAttention.length;
    final todayTasks = provider.todayTasks.length;

    final avgProgress = totalTasks > 0
        ? (completedTasks / totalTasks) * 100
        : 0.0;
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

    final bool showStats = totalTasks > 0;
    final double expandedHeight = showStats ? 330 : 210;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      collapsedHeight: kToolbarHeight,
      pinned: true,
      floating: false,
      stretch: true,
      elevation: 0,
      scrolledUnderElevation: 8,
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      surfaceTintColor: colorScheme.primary,

      // --------------------
      // LEADING
      // --------------------
      leading: AnimatedBuilder(
        animation: _headerAnimationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_headerSlideAnimation.value, 0),
            child: Opacity(
              opacity: _headerAnimationController.value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: IconButton(
          icon: const Icon(
            Icons.dashboard_outlined,
            color: Colors.blueAccent,
            size: 22,
          ),
          onPressed: () => TaskSidebarController.to.toggleSidebar(),
        ),
      ),

      // --------------------
      // TITLE
      // --------------------
      centerTitle: true,
      title: AnimatedBuilder(
        animation: _headerAnimationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -_headerSlideAnimation.value / 2),
            child: Opacity(
              opacity: _headerAnimationController.value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: Text(
          'Weekly Schedule',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: colorScheme.onSurface,
          ),
        ),
      ),

      // --------------------
      // ACTIONS
      // --------------------
      actionsPadding: const EdgeInsets.only(right: 8),
      actions: [
        AnimatedBuilder(
          animation: _headerAnimationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(-_headerSlideAnimation.value, 0),
              child: Opacity(
                opacity: _headerAnimationController.value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAnimatedIconButton(
                icon: Icons.add_rounded,
                onTap: _navigateToAddTask,
                colorScheme: colorScheme,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildAnimatedIconButton(
                icon: Icons.tune_rounded,
                onTap: _showTimeSlotManager,
                colorScheme: colorScheme,
                isDark: isDark,
                badge: _getEffectiveTimeSlots(provider).length.toString(),
              ),
            ],
          ),
        ),
      ],

      // --------------------
      // FLEXIBLE SPACE
      // --------------------
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top, //+ kToolbarHeight,
          ),
          child: _buildExpandedContent(
            theme: theme,
            colorScheme: colorScheme,
            isDark: isDark,
            totalTasks: totalTasks,
            activeTasks: activeTasks,
            completedTasks: completedTasks,
            pendingTasks: pendingTasks,
            missedTasks: missedTasks,
            todayTasks: todayTasks,
            avgProgress: avgProgress,
            completionRate: completionRate,
            showStats: showStats,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required bool isDark,
    String? badge,
  }) {
    return Material(
      color: isDark
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
          : colorScheme.primaryContainer.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: colorScheme.primary, size: 22),
              if (badge != null)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCountBadge(int count, ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: isDark ? 0.4 : 0.6),
            colorScheme.secondaryContainer.withValues(alpha: isDark ? 0.3 : 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_note_rounded, size: 14, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isDark,
    required int totalTasks,
    required int activeTasks,
    required int completedTasks,
    required int pendingTasks,
    required int missedTasks,
    required int todayTasks,
    required double avgProgress,
    required double completionRate,
    required bool showStats,
  }) {
    final now = DateTime.now();
    final weekNumber = _getWeekNumber(_viewDate);
    final startOfWeek =
    _viewDate.subtract(Duration(days: _viewDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF161B22), const Color(0xFF0D1117)]
              : [Colors.white, const Color(0xFFF8FAFC)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 56, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Week Info Header
            AnimatedBuilder(
              animation: _headerAnimationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _headerSlideAnimation.value),
                  child: Opacity(
                    opacity: _headerAnimationController.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: _buildWeekInfoCard(
                theme: theme,
                colorScheme: colorScheme,
                isDark: isDark,
                weekNumber: weekNumber,
                startOfWeek: startOfWeek,
                endOfWeek: endOfWeek,
                now: now,
                todayTasks: todayTasks,
              ),
            ),

            if (showStats) ...[
              const SizedBox(height: 12),
              // Main Progress Section
              AnimatedBuilder(
                animation: _statsAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * _statsScaleAnimation.value),
                    child: Opacity(
                      opacity: _statsScaleAnimation.value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: _buildStatsGrid(
                  theme: theme,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  totalTasks: totalTasks,
                  activeTasks: activeTasks,
                  completedTasks: completedTasks,
                  pendingTasks: pendingTasks,
                  missedTasks: missedTasks,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeekInfoCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isDark,
    required int weekNumber,
    required DateTime startOfWeek,
    required DateTime endOfWeek,
    required DateTime now,
    required int todayTasks,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
            colorScheme.primaryContainer.withValues(alpha: 0.15),
            colorScheme.secondaryContainer.withValues(alpha: 0.1),
          ]
              : [
            colorScheme.primaryContainer.withValues(alpha: 0.5),
            colorScheme.secondaryContainer.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _previousWeek,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
            tooltip: 'Previous Week',
          ),
          const SizedBox(width: 4),
          // Week Number Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'WEEK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$weekNumber',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Week Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d, yyyy').format(endOfWeek)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.today_rounded,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('EEEE').format(now),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (todayTasks > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF10B981).withValues(alpha: 0.2),
                              const Color(0xFF059669).withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$todayTasks today',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          _buildTaskCountBadge(todayTasks, colorScheme, isDark),
          const SizedBox(width: 4),
          IconButton(
            onPressed: _nextWeek,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
            tooltip: 'Next Week',
          ),
        ],
      ),
    );
  }


  Widget _buildStatsGrid({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isDark,
    required int totalTasks,
    required int activeTasks,
    required int completedTasks,
    required int pendingTasks,
    required int missedTasks,
  }) {
    return SizedBox(
      height: 95,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.folder_rounded,
              value: '$totalTasks',
              label: 'Total',
              colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
              isDark: isDark,
              colorScheme: colorScheme,
              theme: theme,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              icon: Icons.play_arrow_rounded,
              value: '$activeTasks',
              label: 'Active',
              colors: [colorScheme.primary, colorScheme.secondary],
              isDark: isDark,
              colorScheme: colorScheme,
              theme: theme,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle_rounded,
              value: '$completedTasks',
              label: 'Done',
              colors: [const Color(0xFF10B981), const Color(0xFF059669)],
              isDark: isDark,
              colorScheme: colorScheme,
              theme: theme,
            ),
          ),
          if (missedTasks > 0) ...[
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.warning_rounded,
                value: '$missedTasks',
                label: 'Missed',
                colors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                isDark: isDark,
                colorScheme: colorScheme,
                theme: theme,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required List<Color> colors,
    required bool isDark,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors[0].withValues(alpha: isDark ? 0.2 : 0.15),
              colors[1].withValues(alpha: isDark ? 0.1 : 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors[0].withValues(alpha: isDark ? 0.3 : 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: isDark ? 0.1 : 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors[0].withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOADING STATE
  // ============================================================
  Widget _buildLoadingState(ColorScheme colorScheme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: isDark ? 0.3 : 0.5),
                  colorScheme.secondaryContainer.withValues(
                    alpha: isDark ? 0.2 : 0.3,
                  ),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: AdvancedProgressIndicator(
              progress: 0.7,
              size: 60,
              strokeWidth: 6,
              shape: ProgressShape.circular,
              foregroundColor: colorScheme.primary,
              gradientColors: [colorScheme.primary, colorScheme.secondary],
              labelStyle: ProgressLabelStyle.none,
              animated: true,
              showGlow: true,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your schedule...',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Organizing your week ✨',
            style: TextStyle(color: colorScheme.outline, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================
  Widget _buildEmptyState(ColorScheme colorScheme, bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FeatureInfoCard(feature: EliteFeatures.weekTasks),

          ],
        ),
      ),
    );
  }

  // ============================================================
  // TIMETABLE GRID (Keep existing implementation)
  // ============================================================
  Widget _buildTimetableGrid(ColorScheme colorScheme, bool isDark, List<TimeSlot> effectiveSlots) {
    const double dayHeaderHeight = 120;
    const double timeSlotWidth = 80;
    const double cellHeight = 150;
    const double cellWidth = 200;

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          height: dayHeaderHeight,
          margin: const EdgeInsets.symmetric(horizontal: 1.0),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Container(
                  width: timeSlotWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.1),
                        colorScheme.secondary.withValues(alpha: isDark ? 0.1 : 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border(
                      right: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 24,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'TIME',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _dayHeaderHorizontalController,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      children: dayData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        final startOfWeek = _viewDate.subtract(Duration(days: _viewDate.weekday - 1));
                        final targetDate = startOfWeek.add(Duration(days: index));
                        final now = DateTime.now();
                        final isToday = now.year == targetDate.year &&
                            now.month == targetDate.month &&
                            now.day == targetDate.day;

                        return _buildDayHeader(
                          data: data,
                          index: index,
                          isToday: isToday,
                          colorScheme: colorScheme,
                          cellWidth: cellWidth,
                          dayHeaderHeight: dayHeaderHeight,
                          isDark: isDark,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: timeSlotWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isDark
                              ? colorScheme.surfaceContainerHigh
                              : colorScheme.surfaceContainerHighest.withOpacity(
                            0.5,
                          ),
                          isDark
                              ? colorScheme.surfaceContainerHighest.withOpacity(
                            0.5,
                          )
                              : Colors.white,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      border: Border(
                        right: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: SingleChildScrollView(
                      controller: _timeSlotVerticalController,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        children: effectiveSlots.asMap().entries.map((entry) {
                          final index = entry.key;
                          final slot = entry.value;
                          final isCurrentSlot = _isCurrentTimeSlot(slot);

                          return _buildTimeSlotCell(
                            slot: slot,
                            index: index,
                            isCurrentSlot: isCurrentSlot,
                            colorScheme: colorScheme,
                            cellHeight: cellHeight,
                            isDark: isDark,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _gridVerticalController,
                      physics: const ClampingScrollPhysics(),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _mainHorizontalController,
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          children: effectiveSlots.asMap().entries.map((timeEntry) {
                            final timeIndex = timeEntry.key;
                            final timeSlot = timeEntry.value;

                            return Row(
                              children: dayData.asMap().entries.map((dayEntry) {
                                final dayIndex = dayEntry.key;
                                final dayName =
                                dayEntry.value['name'] as String;

                                return _buildGridCell(
                                  dayName: dayName,
                                  dayData: dayEntry.value,
                                  timeSlot: timeSlot,
                                  dayIndex: dayIndex,
                                  timeIndex: timeIndex,
                                  colorScheme: colorScheme,
                                  cellWidth: cellWidth,
                                  cellHeight: cellHeight,
                                  isDark: isDark,
                                );
                              }).toList(),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayHeader({
    required Map<String, dynamic> data,
    required int index,
    required bool isToday,
    required ColorScheme colorScheme,
    required double cellWidth,
    required double dayHeaderHeight,
    required bool isDark,
  }) {
    final dayColor = data['color'] as Color;

    return Container(
      width: cellWidth,
      height: dayHeaderHeight,
      decoration: BoxDecoration(
        gradient: isToday
            ? LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.2),
            colorScheme.primary.withValues(alpha: isDark ? 0.05 : 0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        )
            : null,
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isToday
                      ? [colorScheme.primary, colorScheme.secondary]
                      : [dayColor.withValues(alpha: 0.2), dayColor.withValues(alpha: 0.1)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: isToday
                    ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                    : null,
              ),
              child: Text(
                data['emoji'] as String,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data['name'] as String,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isToday
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: isToday
                    ? LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                )
                    : null,
                color: isToday ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _getDateForDay(index + 1),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isToday ? Colors.white : colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotCell({
    required TimeSlot slot,
    required int index,
    required bool isCurrentSlot,
    required ColorScheme colorScheme,
    required double cellHeight,
    required bool isDark,
  }) {
    return Container(
      height: cellHeight,
      decoration: BoxDecoration(
        gradient: isCurrentSlot
            ? LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.15),
            colorScheme.primary.withValues(alpha: isDark ? 0.04 : 0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        )
            : null,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          left: isCurrentSlot
              ? BorderSide(color: colorScheme.primary, width: 3)
              : BorderSide.none,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: isCurrentSlot
                ? LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.2),
                colorScheme.secondary.withValues(alpha: 0.1),
              ],
            )
                : null,
            color: isCurrentSlot
                ? null
                : (isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
            border: isCurrentSlot
                ? Border.all(color: colorScheme.primary.withValues(alpha: 0.3))
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _formatTime(slot.startTime),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isCurrentSlot
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isCurrentSlot
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : colorScheme.outlineVariant.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 12,
                  color: isCurrentSlot
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  _formatTime(slot.endTime),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isCurrentSlot
                        ? colorScheme.primary.withValues(alpha: 0.8)
                        : colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCell({
    required String dayName,
    required Map<String, dynamic> dayData,
    required TimeSlot timeSlot,
    required int dayIndex,
    required int timeIndex,
    required ColorScheme colorScheme,
    required double cellWidth,
    required double cellHeight,
    required bool isDark,
  }) {
    final startOfWeek =
    _viewDate.subtract(Duration(days: _viewDate.weekday - 1));
    final targetDate = startOfWeek.add(Duration(days: dayIndex));
    final tasks = _getTasksForCell(targetDate, timeSlot);
    final isTodayInView = DateTime.now().year == targetDate.year &&
        DateTime.now().month == targetDate.month &&
        DateTime.now().day == targetDate.day;
    final isCurrentSlot = _isCurrentTimeSlot(timeSlot);
    final dayColor = dayData['color'] as Color;

    return Container(
      width: cellWidth,
      height: cellHeight,
      decoration: BoxDecoration(
        gradient: _getCellGradient(
          colorScheme,
          isTodayInView,
          isCurrentSlot,
          dayColor,
          isDark,
        ),
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: _buildCellContent(tasks, colorScheme, dayColor, isDark, dayIndex),
    );
  }

  Gradient? _getCellGradient(
      ColorScheme colorScheme,
      bool isToday,
      bool isCurrentSlot,
      Color dayColor,
      bool isDark,
      ) {
    if (isToday && isCurrentSlot) {
      return LinearGradient(
        colors: [
          colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.12),
          colorScheme.primary.withValues(alpha: isDark ? 0.03 : 0.04),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (isCurrentSlot) {
      return LinearGradient(
        colors: [
          colorScheme.primaryContainer.withValues(alpha: isDark ? 0.06 : 0.08),
          Colors.transparent,
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
    } else if (isToday) {
      return LinearGradient(
        colors: [
          dayColor.withValues(alpha: isDark ? 0.04 : 0.06),
          dayColor.withValues(alpha: isDark ? 0.01 : 0.02),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
    return null;
  }

  Widget _buildCellContent(
      List<WeekTaskModel> tasks,
      ColorScheme colorScheme,
      Color dayColor,
      bool isDark,
      int dayIndex,
      ) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    final startOfWeek =
    _viewDate.subtract(Duration(days: _viewDate.weekday - 1));
    final targetDate = startOfWeek.add(Duration(days: dayIndex));

    if (tasks.length == 1) {
      return Padding(
        padding: const EdgeInsets.all(6),
        child: GridTaskCard(task: tasks[0], date: targetDate),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Stack(
        children: [
          GridTaskCard(task: tasks[0], date: targetDate),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '+${tasks.length - 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isCurrentTimeSlot(TimeSlot slot) {
    try {
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;
      final slotStart = _parseTime(slot.startTime);
      final slotEnd = _parseTime(slot.endTime);
      return currentMinutes >= slotStart && currentMinutes < slotEnd;
    } catch (e) {
      return false;
    }
  }

  List<WeekTaskModel> _getTasksForCell(DateTime date, TimeSlot timeSlot) {
    final provider = context.read<WeekTaskProvider>();
    return provider.tasks.where((task) {
      if (!task.timeline.isScheduledDate(date)) return false;

      final taskStart = _parseTime(task.timeline.startingTime);
      final taskEnd = _parseTime(task.timeline.endingTime);
      final slotStart = _parseTime(timeSlot.startTime);
      final slotEnd = _parseTime(timeSlot.endTime);

      return taskStart < slotEnd && taskEnd > slotStart;
    }).toList();
  }

  String _formatTime(dynamic time) {
    try {
      if (time is DateTime) {
        final hour = time.hour;
        final minute = time.minute;
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
      }

      if (time is! String) return time.toString();

      final cleanTime = time.trim().toUpperCase();
      if (cleanTime.contains('AM') || cleanTime.contains('PM')) {
        return cleanTime;
      }

      final parts = cleanTime.split(':');
      if (parts.length != 2) return time;

      int hours = int.tryParse(parts[0]) ?? 0;
      final minutes = parts[1];

      final period = hours >= 12 ? 'PM' : 'AM';
      if (hours > 12) hours -= 12;
      if (hours == 0) hours = 12;

      return '$hours:$minutes $period';
    } catch (e) {
      return time.toString();
    }
  }

  String _getDateForDay(int weekday) {
    final startOfWeek =
    _viewDate.subtract(Duration(days: _viewDate.weekday - 1));
    final targetDate = startOfWeek.add(Duration(days: weekday - 1));

    // Format the date as dd/MM/yyyy
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(targetDate);
  }
}
