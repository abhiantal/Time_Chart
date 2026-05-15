// lib/features/bucket/message_bubbles/bucket_card_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_time_chart/media_utility/media_display.dart';
import 'package:the_time_chart/media_utility/universal_media_service.dart';
import 'package:the_time_chart/reward_tags/reward_scratch_card.dart';
import 'package:the_time_chart/widgets/bar_progress_indicator.dart';
import 'package:the_time_chart/widgets/metric_indicators.dart';
import 'package:the_time_chart/features/personal/bucket_model/models/bucket_model.dart';
import 'package:the_time_chart/features/personal/bucket_model/widgets/bucket_options_menu.dart';
import 'package:the_time_chart/features/personal/bucket_model/widgets/checklist_preview.dart';
import 'package:provider/provider.dart';

import '../../category_model/models/category_model.dart';
import '../../category_model/providers/category_provider.dart';

class BucketCardWidget extends StatefulWidget {
  final BucketModel bucket;
  final bool isListView;
  final VoidCallback? onTap;

  const BucketCardWidget({
    super.key,
    required this.bucket,
    this.isListView = false,
    this.onTap,
  });

  @override
  State<BucketCardWidget> createState() => _BucketCardWidgetState();
}

class _BucketCardWidgetState extends State<BucketCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verticalMargin = widget.isListView ? 0.0 : 0.0;
    final isCompact = !widget.isListView;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: verticalMargin),
        child: Material(
          elevation: widget.isListView ? 2.0 : 3.0,
          borderRadius: BorderRadius.circular(widget.isListView ? 20 : 16),
          shadowColor: Colors.black.withValues(alpha: 0.1),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.isListView ? 20 : 10),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 2.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.isListView ? 20 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(theme, isCompact),
                  const SizedBox(height: 8),
                  if (widget.isListView)
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: _buildBody(theme, isCompact),
                      ),
                    )
                  else
                    _buildBody(theme, isCompact),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the header section with title, gradient and menu
  Widget _buildHeader(ThemeData theme, bool isCompact) {
    final paddingValue = isCompact ? 8.0 : (widget.isListView ? 16.0 : 12.0);
    final rightPadding = isCompact ? 8.0 : (widget.isListView ? 12.0 : 8.0);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Use model's getCardGradient method
    final bucketGradient = widget.bucket.getCardGradient(
      isDarkMode: isDarkMode,
    );

    // Handle "null" string title gracefully
    final displayTitle =
        widget.bucket.title == 'null' || widget.bucket.title.isEmpty
        ? 'Untitled Bucket'
        : widget.bucket.title;

    // Use model's hasReward getter
    final hasEarnedReward = widget.bucket.hasReward;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bucketGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        paddingValue,
        paddingValue,
        rightPadding,
        paddingValue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMediaPreview(theme, isCompact),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isCompact ? 14.0 : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.isListView &&
                        widget.bucket.subTypes != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.bucket.subTypes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (hasEarnedReward && widget.bucket.rewardPackage != null)
                Padding(
                  padding: EdgeInsets.only(right: isCompact ? 4.0 : 6.0),
                  child: PremiumRewardBox(
                    taskId: widget.bucket.bucketId,
                    taskType: 'bucket',
                    taskTitle: displayTitle,
                    rewardPackage: widget.bucket.rewardPackage!,
                    width: isCompact ? 36 : 40,
                    height: isCompact ? 36 : 40,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              IconButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  final renderBox = context.findRenderObject() as RenderBox;
                  final offset = renderBox.localToGlobal(Offset.zero);
                  final position = Offset(
                    offset.dx + renderBox.size.width,
                    offset.dy,
                  );
                  showBucketOptionsMenu(
                    context: context,
                    bucket: widget.bucket,
                    position: position,
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: isCompact ? 20.0 : (widget.isListView ? 22.0 : 20.0),
                  ),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 4.0 : 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: TaskMetricIndicatorRow(
                  indicators: [
                    TaskMetricIndicator(
                      type: TaskMetricType.status,
                      value: widget.bucket.isCompleted
                          ? 'completed'
                          : 'in_progress',
                      size: isCompact ? 20 : 24,
                      adaptToTheme: true,
                    ),
                    TaskMetricIndicator(
                      type: TaskMetricType.priority,
                      value: widget.bucket.metadata.priority,
                      size: isCompact ? 20 : 24,
                      adaptToTheme: true,
                    ),
                    if (widget.bucket.socialInfo?.isPosted == true)
                      TaskMetricIndicator(
                        type: TaskMetricType.posted,
                        value: {
                          'live':
                              widget.bucket.socialInfo?.posted?.live ?? false,
                        },
                        size: isCompact ? 20 : 24,
                        adaptToTheme: true,
                      ),
                    if (widget.bucket.shareInfo?.isShare == true)
                      TaskMetricIndicator(
                        type: TaskMetricType.shared,
                        value: {
                          'live':
                              widget.bucket.shareInfo?.shareId?.live ?? false,
                          'count': 1,
                        },
                        size: isCompact ? 20 : 24,
                        adaptToTheme: true,
                      ),
                  ],
                  spacing: isCompact ? 2.0 : 4.0,
                  alignment: MainAxisAlignment.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Calculates the completion percentage of the bucket's checklist
  double _completionPercentage() {
    if (widget.bucket.checklist.isEmpty) return 0.0;
    final completed = widget.bucket.checklist.where((c) => c.done).length;
    return (completed / widget.bucket.checklist.length) * 100;
  }

  /// Builds the media preview widget showing an image or category_model icon
  Widget _buildMediaPreview(ThemeData theme, bool isCompact) {
    final mediaSize = isCompact ? 40.0 : (widget.isListView ? 60.0 : 50.0);

    if (widget.bucket.details.mediaUrl.isEmpty) {
      return Container(
        width: mediaSize,
        height: mediaSize,
        padding: EdgeInsets.all(
          isCompact ? 8.0 : (widget.isListView ? 12.0 : 10.0),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            _getCategoryEmoji(context),
            style: TextStyle(
              fontSize: isCompact ? 20.0 : (widget.isListView ? 28.0 : 24.0),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final firstMedia = widget.bucket.details.mediaUrl.first;

    return Container(
      width: mediaSize,
      height: mediaSize,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: EnhancedMediaDisplay(
          mediaFiles: [
            EnhancedMediaFile.fromUrl(id: 'bucket_preview', url: firstMedia),
          ],
          config: MediaDisplayConfig(
            layoutMode: MediaLayoutMode.single,
            mediaBucket: MediaBucket.bucketMedia,
            allowDelete: false,
            allowFullScreen: true,
            showFileName: false,
            showFileSize: false,
            showDate: false,
            borderRadius: 10,
            imageFit: BoxFit.cover,
            enableAnimations: false,
            showDetails: false,
          ),
        ),
      ),
    );
  }

  /// Builds the tags section displaying the reward tag
  Widget _buildTags(ThemeData theme, bool isCompact) {
    if (!widget.bucket.hasReward || widget.bucket.tagName.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sell_outlined,
            size: isCompact ? 12 : 14,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 4),
          Text(
            widget.bucket.tagName.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the main body content of the bucket card
  Widget _buildBody(ThemeData theme, bool isCompact) {
    final bodyPadding = isCompact ? 5.0 : (widget.isListView ? 10.0 : 18.0);
    final completionPercent = _completionPercentage();

    return Container(
      color: theme.colorScheme.surface,
      padding: EdgeInsets.all(bodyPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProgressSection(theme, isCompact, completionPercent),
          if (widget.bucket.hasReward && widget.bucket.tagName.isNotEmpty) ...[
            SizedBox(height: isCompact ? 8.0 : 12.0),
            _buildTags(theme, isCompact),
          ],
          if (widget.bucket.checklist.isNotEmpty) ...[
            SizedBox(height: isCompact ? 8.0 : 16.0),
            buildChecklistPreview(
              context,
              theme,
              widget.bucket,
              widget.isListView,
            ),
          ],
          const SizedBox(height: 8),
          _buildActionButtons(theme, isCompact),
        ],
      ),
    );
  }

  /// Builds the progress section with indicators and leaderboard
  Widget _buildProgressSection(
    ThemeData theme,
    bool isCompact,
    double completionPercent,
  ) {
    // Use model's progressColor getter
    final cardColor = widget.bucket.progressColor;

    final completedTasks = widget.bucket.checklist
        .where((item) => item.done)
        .length;
    final totalTasks = widget.bucket.checklist.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: isCompact ? 16.0 : 0.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: isCompact ? 16.0 : 18.0,
                  color: cardColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Progress',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 12.0 : 14.0,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${completionPercent.toInt()}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                  fontSize: isCompact ? 14.0 : 16.0,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isCompact ? 16.0 : 10.0),
        CustomProgressIndicator(
          progress: completionPercent / 100,
          progressBarName: '',
          width: double.infinity,
          baseHeight: isCompact ? 6.0 : (widget.isListView ? 10.0 : 8.0),
          progressColor: cardColor,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          progressLabelDisplay: ProgressLabelDisplay.none,
          animated: true,
          borderRadius: 4,
          borderWidth: 0,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
        ),
        SizedBox(height: isCompact ? 16.0 : 10.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: isCompact ? 14.0 : 16.0,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      totalTasks > 0
                          ? '$completedTasks/$totalTasks tasks completed'
                          : 'No tasks yet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: isCompact ? 11.0 : 12.0,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            if (!isCompact && widget.bucket.timeline.dueDate != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: cardColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: isCompact ? 12.0 : 14.0,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getTimeLeftText(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Generates a human-readable string for remaining time until due date
  String _getTimeLeftText() {
    final dueDate = widget.bucket.timeline.dueDate;
    if (dueDate == null) return 'No deadline';

    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) return 'Overdue';
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return '1 day';
    if (difference.inDays < 7) return '${difference.inDays} days';
    if (difference.inDays < 30) {
      return '${(difference.inDays / 7).ceil()} weeks';
    }
    return '${(difference.inDays / 30).ceil()} months';
  }

  /// Builds the action buttons for interacting with the bucket
  Widget _buildActionButtons(ThemeData theme, bool isCompact) {
    final isDarkMode = theme.brightness == Brightness.dark;
    // Use model's getCardGradient method
    final bucketGradient = widget.bucket.getCardGradient(
      isDarkMode: isDarkMode,
    );

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bucketGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: widget.onTap,
              icon: Icon(
                Icons.visibility_rounded,
                size: isCompact ? 16.0 : (widget.isListView ? 20.0 : 18.0),
                color: Colors.white,
              ),
              label: Text(
                isCompact
                    ? 'View'
                    : (widget.isListView ? 'View Details' : 'Details'),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: isCompact ? 13.0 : 14.0,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(
                  vertical: isCompact ? 6.0 : (widget.isListView ? 12.0 : 8.0),
                  horizontal: 16.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: Size(
                  double.infinity,
                  isCompact ? 34.0 : (widget.isListView ? 44.0 : 40.0),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Retrieves the emoji icon associated with the bucket's category_model
  String _getCategoryEmoji(BuildContext context) {
    // Try provider cache first
    try {
      final provider = Provider.of<CategoryProvider>(context, listen: false);
      final all = provider.allCategories;
      final catId = widget.bucket.categoryId;
      if (catId != null) {
        final match = all.firstWhere(
          (c) => c.id == catId,
          orElse: () => Category(
            id: '',
            categoryFor: 'bucket',
            categoryType: widget.bucket.categoryType ?? 'bucket',
            color: '#4CAF50',
            icon: CategoryForType.getIcon(
              widget.bucket.categoryType ?? 'bucket',
            ),
          ),
        );
        if (match.id.isNotEmpty && match.icon.isNotEmpty) {
          return match.icon;
        }
      }
    } catch (_) {}
    // Fallback to type-based icon
    return CategoryForType.getIcon(widget.bucket.categoryType ?? 'bucket');
  }
}
