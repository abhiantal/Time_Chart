import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../../widgets/feature_info_widgets.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';

import '../../../../../widgets/error_handler.dart';
import '../../../../../../widgets/logger.dart';
import '../../tasks_sidebar.dart';
import '../models/long_goal_model.dart';
import '../providers/long_goals_provider.dart';
import '../widgets/long_goal_calendar_widget.dart';
import '../widgets/goal_filter_widget.dart';
import '../widgets/long_goal_card.dart';
import '../widgets/long_goals_options_menu.dart';

class LongGoalsHomeScreen extends StatefulWidget {
  const LongGoalsHomeScreen({super.key});

  @override
  State<LongGoalsHomeScreen> createState() => _LongGoalsHomeScreenState();
}

class _LongGoalsHomeScreenState extends State<LongGoalsHomeScreen>
    with TickerProviderStateMixin {
  // Filter state
  GoalFilterModel _currentFilter = GoalFilterModel.empty;

  // ── Feature Info Data ──
  // Relocated to EliteFeatures.longGoals

  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  late AnimationController _headerAnimationController;
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeController();
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _headerAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Show title when scrolled past 150 pixels
    final showTitle =
        _scrollController.hasClients && _scrollController.offset > 150;
    if (showTitle != _showTitle) {
      setState(() => _showTitle = showTitle);
    }

    if (_scrollController.offset > 200 && !_showBackToTop) {
      setState(() => _showBackToTop = true);
    } else if (_scrollController.offset <= 200 && _showBackToTop) {
      setState(() => _showBackToTop = false);
    }
  }

  Future<void> _initializeController() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        ErrorHandler.logError('User not authenticated', null);
        if (mounted) {
          AppSnackbar.error('Authentication Required');
        }
        return;
      }

      logI('🔑 Initializing provider with userId: $userId');
      final provider = context.read<LongGoalsProvider>();
      await provider.initialize(userId);
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Error initializing controller');
      if (mounted) {
        AppSnackbar.error('Initialization Failed');
      }
    }
  }

  Future<void> _loadGoals() async {
    try {
      final provider = context.read<LongGoalsProvider>();
      await provider.loadUserGoals();
    } catch (e) {
      ErrorHandler.logError('Error reloading goals: $e', null);
    }
  }

  Future<void> _openFilterPopup() async {
    final result = await showGoalFilterPopup(
      context: context,
      currentFilter: _currentFilter,
    );

    if (result != null) {
      setState(() {
        _currentFilter = result;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _currentFilter = GoalFilterModel.empty;
    });
  }

  List<LongGoalModel> _filterGoals(List<LongGoalModel> goals) {
    var filtered = goals;

    if (_currentFilter.searchQuery.isNotEmpty) {
      final query = _currentFilter.searchQuery.toLowerCase();
      filtered = filtered.where((goal) {
        return goal.title.toLowerCase().contains(query) ||
            goal.description.need.toLowerCase().contains(query) ||
            goal.description.motivation.toLowerCase().contains(query);
      }).toList();
    }

    if (_currentFilter.startDate != null && _currentFilter.endDate != null) {
      filtered = filtered.where((goal) {
        if (goal.timeline.isUnspecified ||
            goal.timeline.startDate == null ||
            goal.timeline.endDate == null) {
          return false;
        }
        return goal.timeline.startDate!.isBefore(
              _currentFilter.endDate!.add(const Duration(days: 1)),
            ) &&
            goal.timeline.endDate!.isAfter(
              _currentFilter.startDate!.subtract(const Duration(days: 1)),
            );
      }).toList();
    }

    if (_currentFilter.category != null) {
      filtered = filtered
          .where((goal) => goal.categoryType == _currentFilter.category)
          .toList();
    }

    if (_currentFilter.priority != null) {
      filtered = filtered
          .where(
            (goal) =>
                goal.indicators.priority.toLowerCase() ==
                _currentFilter.priority!.toLowerCase(),
          )
          .toList();
    }

    if (_currentFilter.status != null) {
      filtered = filtered
          .where(
            (goal) =>
                goal.indicators.status.toLowerCase() ==
                _currentFilter.status!.toLowerCase(),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        body: Consumer<LongGoalsProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const _LoadingState();
            }
            return _buildContent(provider);
          },
        ),
        floatingActionButton: _buildFloatingButtons(),
      ),
    );
  }

  Widget _buildContent(LongGoalsProvider provider) {
    final filteredGoals = _filterGoals(provider.goals);

    if (provider.goals.isEmpty && !_currentFilter.hasActiveFilters) {
      return CustomScrollView(
        slivers: [
          _buildSliverAppBar(provider),
          SliverFillRemaining(child: _buildEmptyState()),
        ],
      );
    }

    if (filteredGoals.isEmpty && _currentFilter.hasActiveFilters) {
      return CustomScrollView(
        slivers: [
          _buildSliverAppBar(provider),
          SliverFillRemaining(child: _buildNoResultsState()),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGoals,
      edgeOffset: 140,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          _buildSliverAppBar(provider),
          // Active filters bar
          if (_currentFilter.hasActiveFilters)
            SliverToBoxAdapter(
              child: _buildActiveFiltersBar(Theme.of(context)),
            ),
          // Quick filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildQuickFilters(),
            ),
          ),
          // Goals section header
          SliverToBoxAdapter(
            child: _buildGoalsSectionHeader(filteredGoals.length),
          ),
          // Goals list (list-only view)
          _buildListSliver(filteredGoals),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ============================================================
  // SLIVER APP BAR - Contains Header and Stats
  // ============================================================
  Widget _buildSliverAppBar(LongGoalsProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool showStats = provider.goals.isNotEmpty || provider.isLoading;
    final double expandedHeight = showStats ? 340 : 140;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      stretch: true,
      elevation: 0,
      scrolledUnderElevation: 4,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.primary,
      leading: _buildAnimatedLeadingButton(theme),

      // Collapsed Title (shows when scrolled)
      title: AnimatedOpacity(
        opacity: _showTitle ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          'My Goals',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: _buildExpandedContent(
          theme,
          colorScheme,
          provider,
          showStats,
        ),
      ),
    );
  }

  Widget _buildListSliver(List<LongGoalModel> goals) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 400 + (index * 80)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 40 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: LongGoalCard(
                goal: goals[index],
                onTap: () => _navigateToDetail(goals[index].goalId),
                onCalendarTap: () => _showGoalCalendar(goals[index]),
                onAddFeedbackTap: () => _navigateToAddFeedback(goals[index]),
              ),
            ),
          );
        }, childCount: goals.length),
      ),
    );
  }

  Widget _buildExpandedContent(
    ThemeData theme,
    ColorScheme colorScheme,
    LongGoalsProvider provider,
    bool showStats,
  ) {
    return Container(
      decoration: BoxDecoration(color: colorScheme.surface),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              _buildHeaderRow(theme, colorScheme, provider),

              if (showStats && provider.goals.isNotEmpty) ...[
                const SizedBox(height: 20),
                // Stats Section
                Expanded(
                  child: _buildStatsContent(
                    context,
                    provider,
                    theme,
                    colorScheme,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(
    ThemeData theme,
    ColorScheme colorScheme,
    LongGoalsProvider provider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // LEFT SIDE
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Goals',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${provider.goals.length} '
              '${provider.goals.length == 1 ? 'goal' : 'goals'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedLeadingButton(ThemeData theme) {
    return AnimatedBuilder(
      animation: _headerAnimationController,
      builder: (context, child) {
        final opacity = _headerAnimationController.value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.5 + (_headerAnimationController.value * 0.5),
          child: Opacity(
            opacity: opacity,
            child: IconButton(
              icon: const Icon(
                Icons.dashboard_outlined,
                color: Colors.blueAccent,
                size: 22,
              ),
              onPressed: () => TaskSidebarController.to.toggleSidebar(),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // STATS CONTENT - Styled like Bucket Screen
  // ============================================================
  Widget _buildStatsContent(
    BuildContext context,
    LongGoalsProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final activeGoals = provider.filterGoals(status: 'inProgress');
    final completedCount = provider.filterGoals(status: 'completed').length;
    final activeCount = activeGoals.length;
    final totalCount = provider.goals.length;
    final avgProgress = activeGoals.isNotEmpty
        ? activeGoals.fold<double>(
                0.0,
                (sum, goal) => sum + goal.analysis.averageProgress,
              ) /
              activeGoals.length
        : 0.0;
    
    final progress = avgProgress / 100;

    return Column(
      children: [
        // Compact Progress Row
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.primaryContainer.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Circular Progress - Smaller
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 8,
                        backgroundColor:
                            colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.transparent),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return CircularProgressIndicator(
                            value: value,
                            strokeWidth: 8,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation(
                              colorScheme.primary,
                            ),
                          );
                        },
                      ),
                      Center(
                        child: Text(
                          '${avgProgress.toInt()}%',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Overall Progress',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedCount of $totalCount goals completed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor:
                              colorScheme.onPrimaryContainer.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(
                            colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Stats Row - 4 compact cards in a row
        SizedBox(
          height: 90,
          child: Row(
            children: [
              _buildCompactStatChip(
                value: '$totalCount',
                label: 'Total',
                icon: Icons.flag_rounded,
                color: colorScheme.secondary,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              _buildCompactStatChip(
                value: '$activeCount',
                label: 'Active',
                icon: Icons.rocket_launch_rounded,
                color: colorScheme.primary,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              _buildCompactStatChip(
                value: '$completedCount',
                label: 'Done',
                icon: Icons.check_circle_rounded,
                color: Colors.green,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              _buildCompactStatChip(
                value: '${totalCount - completedCount - activeCount}',
                label: 'Pending',
                icon: Icons.schedule_rounded,
                color: Colors.orange,
                theme: theme,
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStatChip({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 3),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildActiveFiltersBar(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.filter_alt_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            if (_currentFilter.searchQuery.isNotEmpty)
              _buildFilterChip(
                icon: Icons.search,
                label: '"${_currentFilter.searchQuery}"',
                onRemove: () {
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(searchQuery: '');
                  });
                },
              ),
            if (_currentFilter.startDate != null &&
                _currentFilter.endDate != null)
              _buildFilterChip(
                icon: Icons.date_range,
                label:
                    '${_formatDate(_currentFilter.startDate!)} - ${_formatDate(_currentFilter.endDate!)}',
                onRemove: () {
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(
                      clearStartDate: true,
                      clearEndDate: true,
                    );
                  });
                },
              ),
            if (_currentFilter.category != null)
              _buildFilterChip(
                icon: Icons.category,
                label: _currentFilter.category!,
                onRemove: () {
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(
                      clearCategory: true,
                    );
                  });
                },
              ),
            if (_currentFilter.priority != null)
              _buildFilterChip(
                icon: Icons.flag,
                label: _currentFilter.priority!.toUpperCase(),
                color: _getPriorityColor(_currentFilter.priority!),
                onRemove: () {
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(
                      clearPriority: true,
                    );
                  });
                },
              ),
            if (_currentFilter.status != null)
              _buildFilterChip(
                icon: Icons.timeline,
                label: _formatStatusLabel(_currentFilter.status!),
                onRemove: () {
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(clearStatus: true);
                  });
                },
              ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required VoidCallback onRemove,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InputChip(
        avatar: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: chipColor),
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: chipColor,
          ),
        ),
        deleteIcon: Icon(Icons.close_rounded, size: 16, color: chipColor),
        onDeleted: onRemove,
        backgroundColor: chipColor.withValues(alpha: 0.08),
        side: BorderSide(color: chipColor.withValues(alpha: 0.3)),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildQuickFilters() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _QuickFilterChip(
            label: 'All',
            icon: Icons.apps_rounded,
            isSelected: _currentFilter == GoalFilterModel.empty,
            onTap: _clearFilters,
          ),
          const SizedBox(width: 10),
          _QuickFilterChip(
            label: 'Active',
            icon: Icons.play_circle_outline_rounded,
            isSelected: _currentFilter.status == 'inProgress',
            color: Colors.blue,
            onTap: () {
              setState(() {
                _currentFilter = GoalFilterModel(status: 'inProgress');
              });
            },
          ),
          const SizedBox(width: 10),
          _QuickFilterChip(
            label: 'Urgent',
            icon: Icons.local_fire_department_rounded,
            isSelected: _currentFilter.priority == 'urgent',
            color: Colors.red,
            onTap: () {
              setState(() {
                _currentFilter = GoalFilterModel(priority: 'urgent');
              });
            },
          ),
          const SizedBox(width: 10),
          _QuickFilterChip(
            label: 'High Priority',
            icon: Icons.arrow_upward_rounded,
            isSelected: _currentFilter.priority == 'high',
            color: Colors.orange,
            onTap: () {
              setState(() {
                _currentFilter = GoalFilterModel(priority: 'high');
              });
            },
          ),
          const SizedBox(width: 10),
          _QuickFilterChip(
            label: 'Completed',
            icon: Icons.check_circle_outline_rounded,
            isSelected: _currentFilter.status == 'completed',
            color: Colors.green,
            onTap: () {
              setState(() {
                _currentFilter = GoalFilterModel(status: 'completed');
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSectionHeader(int count) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.list_alt_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Goals',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _openFilterPopup,
            icon: const Icon(Icons.sort_rounded, size: 18),
            label: const Text('Sort'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FeatureInfoCard(feature: EliteFeatures.longGoals),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 64,
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'No Goals Found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Try adjusting your filters\nto find what you\'re looking for',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all_rounded),
                  label: const Text('Clear Filters'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _openFilterPopup,
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Adjust'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showBackToTop)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FloatingActionButton.small(
              heroTag: 'backToTop',
              onPressed: () {
                HapticFeedback.lightImpact();
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.arrow_upward_rounded,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ScaleTransition(
          scale: _fabAnimation,
          child: FloatingActionButton.extended(
            heroTag: 'createGoal',
            onPressed: () {
              HapticFeedback.mediumImpact();
              _navigateToCreate();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Goal'),
          ),
        ),
      ],
    );
  }

  // Navigation methods
  Future<void> _navigateToCreate() async {
    final result = await context.push('/personalNav/CreateLongGoalScreen');

    if (result == true) {
      await _loadGoals();
    }
  }

  void _navigateToDetail(String goalId) {
    context.go('/personalNav/LongGoalDetailScreen/$goalId');
  }

  // NEW: Navigate to add feedback screen
  void _navigateToAddFeedback(LongGoalModel goal, {DateTime? date}) {
    LongGoalsOptionsMenu.navigateToAddFeedback(context, goal, date: date);
  }

  Future<void> _showGoalCalendar(LongGoalModel goal) async {
    await showDialog(
      context: context,
      builder: (context) => LongGoalCalendarWidget(
        goal: goal,
        onAddFeedback: (date) => LongGoalsOptionsMenu.navigateToAddFeedback(
          context,
          goal,
          date: date,
        ),
      ),
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  String _formatStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'inprogress':
        return 'In Progress';
      case 'onhold':
        return 'On Hold';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'normal':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// ============================================
// PRIVATE WIDGETS
// ============================================

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your goals...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _QuickFilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [chipColor, chipColor.withValues(alpha: 0.8)],
                  )
                : null,
            color: isSelected
                ? null
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: chipColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
