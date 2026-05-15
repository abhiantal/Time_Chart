// lib/features/bucket/screens_widgets/bucket_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/Authentication/auth_provider.dart';
import 'package:the_time_chart/features/personal/bucket_model/providers/bucket_provider.dart';
import 'package:the_time_chart/features/personal/bucket_model/widgets/bucket_card_widget.dart';
import 'package:the_time_chart/widgets/logger.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import '../../../../widgets/feature_info_widgets.dart';

class BucketListScreen extends StatefulWidget {
  /// Screen for displaying the list of user buckets with filtering and leaderboard
  const BucketListScreen({super.key});

  @override
  State<BucketListScreen> createState() => _BucketListScreenState();
}

class _BucketListScreenState extends State<BucketListScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isGridView = false;
  late AnimationController _fabController;
  late AnimationController _headerController;
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;
  
  // ── Feature Info Data ──
  // Relocated to EliteFeatures.buckets

  @override
  /// Initializes animations and loads bucket data
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBuckets();
      _fabController.forward();
      _headerController.forward();
    });
  }

  @override
  /// Disposes controllers and listeners to prevent memory leaks
  void dispose() {
    _fabController.dispose();
    _headerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Updates the scroll offset state for UI reactivity
  void _onScroll() {
    // Show title when scrolled past 150 pixels
    final showTitle =
        _scrollController.hasClients && _scrollController.offset > 150;
    if (showTitle != _showTitle) {
      setState(() => _showTitle = showTitle);
    }

    // Infinite scroll: Load more when reaching near the bottom (500px threshold)
    if (_scrollController.hasClients) {
      final threshold = _scrollController.position.maxScrollExtent - 500;
      if (_scrollController.offset >= threshold) {
        context.read<BucketProvider>().loadMoreBuckets();
      }
    }
  }

  /// Loads the user's buckets from the provider with error handling
  Future<void> _loadBuckets() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        logE('No user logged in');
        return;
      }

      final provider = context.read<BucketProvider>();
      await provider.loadBuckets(userId);
    } catch (e, stackTrace) {
      logE('Error loading buckets: $e', error: e, stackTrace: stackTrace);
      if (mounted) {
        AppSnackbar.error('Error loading buckets: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  /// Builds the main scaffold with sliver scroll view
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadBuckets,
            edgeOffset: 140,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // SliverAppBar with Header and Stats
                _buildSliverAppBar(theme, colorScheme),

                // Bottom Padding
                const SliverToBoxAdapter(child: SizedBox(height: 15)),

                // Content
                _isLoading
                    ? SliverToBoxAdapter(
                        child: SizedBox(
                          height: 300,
                          child: _buildLoadingState(theme),
                        ),
                      )
                    : Consumer<BucketProvider>(
                        builder: (context, provider, child) {
                          if (provider.buckets.isEmpty) {
                            return SliverToBoxAdapter(
                              child: _buildEmptyState(theme, colorScheme),
                            );
                          }
                          return _isGridView
                              ? _buildGridSliver(provider, theme, colorScheme)
                              : _buildListSliver(provider, theme, colorScheme);
                        },
                      ),

                // Loading more indicator
                Consumer<BucketProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading && provider.buckets.isNotEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  },
                ),

                // Bottom Padding
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: _buildFAB(theme, colorScheme),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SLIVER APP BAR - Contains Header and Stats
  // ============================================================
  /// Builds the collapsible sliver app bar with header and leaderboard
  Widget _buildSliverAppBar(ThemeData theme, ColorScheme colorScheme) {
    return Consumer<BucketProvider>(
      builder: (context, provider, child) {
        final bool showStats = provider.buckets.isNotEmpty || _isLoading;
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

          // Collapsed Title (shows when scrolled)
          title: AnimatedOpacity(
            opacity: _showTitle ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Text(
              'My Buckets',
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
      },
    );
  }

  /// Builds the content within the expanded app bar area
  Widget _buildExpandedContent(
    ThemeData theme,
    ColorScheme colorScheme,
    BucketProvider provider,
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

              if (showStats && provider.buckets.isNotEmpty) ...[
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

  /// Builds the header row with title and view toggle
  Widget _buildHeaderRow(
    ThemeData theme,
    ColorScheme colorScheme,
    BucketProvider provider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // LEFT SIDE
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Buckets',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${provider.totalBuckets} '
              '${provider.totalBuckets == 1 ? 'bucket' : 'buckets'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),

        // RIGHT SIDE
        Row(
          children: [
            _buildViewToggle(theme, colorScheme),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the toggle button for switching between list and grid views
  Widget _buildViewToggle(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            icon: Icons.view_list_rounded,
            isSelected: !_isGridView,
            onTap: () => setState(() => _isGridView = false),
            colorScheme: colorScheme,
          ),
          _buildToggleButton(
            icon: Icons.grid_view_rounded,
            isSelected: _isGridView,
            onTap: () => setState(() => _isGridView = true),
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  /// Builds a single toggle button with animation
  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // ============================================================
  // STATS CONTENT - Inside SliverAppBar
  // ============================================================
  /// Builds the statistics content area showing overall progress
  Widget _buildStatsContent(
    BuildContext context,
    BucketProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final progress = provider.averageProgress / 100;

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
                  colorScheme.primaryContainer.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.15),
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
                        backgroundColor: colorScheme.onPrimaryContainer
                            .withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(Colors.transparent),
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
                        child: TweenAnimationBuilder<int>(
                          tween: IntTween(
                            begin: 0,
                            end: provider.averageProgress.toInt(),
                          ),
                          duration: const Duration(milliseconds: 1000),
                          builder: (context, value, _) {
                            return Text(
                              '$value%',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            );
                          },
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
                        '${provider.completedBucketsCount} of ${provider.totalBuckets} completed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 1000),
                          builder: (context, value, _) {
                            return LinearProgressIndicator(
                              value: value,
                              minHeight: 6,
                              backgroundColor: colorScheme.onPrimaryContainer
                                  .withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation(
                                colorScheme.primary,
                              ),
                            );
                          },
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
          height: 90, //
          child: Row(
            children: [
              _buildCompactStatChip(
                value: '${provider.totalBuckets}',
                label: 'Total',
                icon: Icons.folder_rounded,
                color: colorScheme.secondary,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              _buildCompactStatChip(
                value: '${provider.activeBucketsCount}',
                label: 'Active',
                icon: Icons.play_arrow_rounded,
                color: colorScheme.primary,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              _buildCompactStatChip(
                value: '${provider.completedBucketsCount}',
                label: 'Done',
                icon: Icons.check_circle_rounded,
                color: Colors.green,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              _buildCompactStatChip(
                value:
                    '${provider.totalBuckets - provider.completedBucketsCount - provider.activeBucketsCount}',
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

  /// Builds a compact statistic chip for the leaderboard row
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 3),
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
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING STATE
  // ============================================================
  /// Builds the loading spinner when buckets are being fetched
  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading buckets...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the empty state view when no buckets exist
  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            FeatureInfoCard(feature: EliteFeatures.buckets),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [EliteFeatures.buckets.color, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: EliteFeatures.buckets.color.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),

            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LIST VIEW - Using BucketCardWidget
  // ============================================================
  /// Builds the vertical list view of buckets
  Widget _buildListSliver(
    BucketProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final bucket = provider.buckets[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SizedBox(
              height: 600, // Fixed height for list view cards
              child: BucketCardWidget(
                bucket: bucket,
                isListView: true,
                onTap: () {
                  context.goNamed(
                    'bucketDetailScreen',
                    pathParameters: {'bucketId': bucket.bucketId},
                    extra: bucket,
                  );
                },
              ),
            ),
          );
        }, childCount: provider.buckets.length),
      ),
    );
  }

  // ============================================================
  // GRID VIEW - Using BucketCardWidget
  // ============================================================
  /// Builds the grid view of buckets
  Widget _buildGridSliver(
    BucketProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65, // Adjusted for BucketCardWidget content
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final bucket = provider.buckets[index];
          return BucketCardWidget(
            bucket: bucket,
            isListView: false, // Grid/compact mode
            onTap: () {
              context.goNamed(
                'bucketDetailScreen',
                pathParameters: {'bucketId': bucket.bucketId},
                extra: bucket,
              );
            },
          );
        }, childCount: provider.buckets.length),
      ),
    );
  }

  // ============================================================
  // FAB
  // ============================================================
  /// Builds the animated floating action button for creating new buckets
  Widget _buildFAB(ThemeData theme, ColorScheme colorScheme) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
      child: FloatingActionButton.extended(
        heroTag: 'bucket_list_add_fab',
        onPressed: () => context.goNamed('addEditBucketPage'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Bucket'),
      ),
    );
  }
}
