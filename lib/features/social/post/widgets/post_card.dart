import 'package:flutter/material.dart';
import 'package:the_time_chart/media_utility/universal_media_service.dart';
import '../models/post_model.dart';
import 'base_post_card.dart';
import 'post_card/text_post_card.dart';
import 'post_card/media_post_card.dart';
import 'post_card/poll_post_card.dart';
import 'post_card/reel_post_card.dart';
import 'post_card/advertisement_post_card.dart';
import '../../../personal/task_model/day_tasks/models/day_task_model.dart';
import '../../../personal/task_model/long_goal/models/long_goal_model.dart';
import '../../../personal/task_model/week_task/models/week_task_model.dart';
import '../../../personal/bucket_model/models/bucket_model.dart';
import '../../../post_shared/day_task/post_shared_day_task_card.dart';
import '../../../personal/task_model/day_tasks/repositories/day_task_repository.dart';
import '../../../post_shared/long_goal/post_shared_long_goal_card.dart';
import '../../../post_shared/week_task/post_shared_week_task_card.dart';
import '../../../post_shared/bucket/post_shared_bucket_card.dart';
import '../../../personal/task_model/week_task/repositories/week_task_repository.dart';
import '../../../personal/task_model/long_goal/repositories/long_goals_repository.dart';
import '../../../personal/bucket_model/repositories/bucket_repository.dart';
import 'helper/post_content.dart';
import '../../../../../media_utility/media_asset_model.dart';
import '../../../../../media_utility/media_display.dart';

class PostCard extends StatelessWidget {
  final FeedPost post;
  final String currentUserId;
  final bool isInDetailView;
  final VoidCallback? onTap;
  final VoidCallback? onCommentPressed;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onNextReel;
  final VoidCallback? onPreviousReel;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    this.isInDetailView = false,
    this.onTap,
    this.onCommentPressed,
    this.onMenuPressed,
    this.onNextReel,
    this.onPreviousReel,
  });

  @override
  Widget build(BuildContext context) {
    if (post.post.isReel) {
      return ReelPostCard(
        post: post,
        currentUserId: currentUserId,
        onCommentPressed: onCommentPressed,
        onMenuPressed: onMenuPressed,
        onNextReel: onNextReel,
        onPreviousReel: onPreviousReel,
      );
    }

    FeedPost resolvedPost = post;
    ContentType contentType = resolvedPost.post.contentType;

    // Override if we have a custom shared source - Prioritize shared cards over media/text
    if (resolvedPost.post.sourceType != null &&
        (resolvedPost.post.sourceData != null ||
            resolvedPost.post.sourceId != null)) {
      final source = resolvedPost.post.sourceType!.toLowerCase();
      if (source == 'day_task' || source == 'daytask') {
        contentType = ContentType.day_task;
      } else if (source == 'week_task' ||
          source == 'weekly_task' ||
          source == 'weeklytask') {
        contentType = ContentType.week_task;
      } else if (source == 'long_goal' || source == 'longgoal') {
        contentType = ContentType.long_goal;
      } else if (source == 'bucket' ||
          source == 'bucket_model' ||
          source == 'bucketmodel') {
        contentType = ContentType.bucket;
      }
    }

    switch (contentType) {
      case ContentType.image:
      case ContentType.video:
      case ContentType.vlog:
      case ContentType.carousel:
        return MediaPostCard(
          post: resolvedPost,
          currentUserId: currentUserId,
          isInDetailView: isInDetailView,
          onTap: onTap,
          onCommentPressed: onCommentPressed,
          onMenuPressed: onMenuPressed,
        );
      case ContentType.poll:
        return PollPostCard(
          post: resolvedPost,
          currentUserId: currentUserId,
          isInDetailView: isInDetailView,
          onTap: onTap,
          onCommentPressed: onCommentPressed,
          onMenuPressed: onMenuPressed,
        );
      case ContentType.day_task:
        return BasePostCard(
          post: resolvedPost,
          currentUserId: currentUserId,
          onTap: onTap,
          onCommentPressed: onCommentPressed,
          onMenuPressed: onMenuPressed,
          content: _CustomTaskContent(
            post: resolvedPost,
            child: _LiveDayTaskCard(post: resolvedPost),
          ),
        );
      case ContentType.long_goal:
        return BasePostCard(
          post: resolvedPost,
          currentUserId: currentUserId,
          onTap: onTap,
          onCommentPressed: onCommentPressed,
          onMenuPressed: onMenuPressed,
          content: _CustomTaskContent(
            post: resolvedPost,
            child: _LiveLongGoalCard(post: resolvedPost),
          ),
        );
      case ContentType.week_task:
        return BasePostCard(
          post: resolvedPost,
          currentUserId: currentUserId,
          onTap: onTap,
          onCommentPressed: onCommentPressed,
          onMenuPressed: onMenuPressed,
          content: _CustomTaskContent(
            post: resolvedPost,
            child: _LiveWeekTaskCard(post: resolvedPost),
          ),
        );
      case ContentType.bucket:
        return BasePostCard(
          post: resolvedPost,
          currentUserId: currentUserId,
          onTap: onTap,
          onCommentPressed: onCommentPressed,
          onMenuPressed: onMenuPressed,
          content: _CustomTaskContent(
            post: resolvedPost,
            child: _LiveBucketCard(post: resolvedPost),
          ),
        );
      case ContentType.advertisement:
        return AdvertisementPostCard(
          post: resolvedPost,
          currentUserId: currentUserId,
          isInDetailView: isInDetailView,
          onTap: onTap,
          onCommentPressed: onCommentPressed,
          onMenuPressed: onMenuPressed,
        );
      default:
        return TextPostCard(
          post: resolvedPost,
          currentUserId: currentUserId,
          isInDetailView: isInDetailView,
          onTap: onTap,
          onCommentPressed: onCommentPressed,
          onMenuPressed: onMenuPressed,
        );
    }
  }
}

class _CustomTaskContent extends StatefulWidget {
  final FeedPost post;
  final Widget child;

  const _CustomTaskContent({required this.post, required this.child});

  @override
  State<_CustomTaskContent> createState() => _CustomTaskContentState();
}

class _CustomTaskContentState extends State<_CustomTaskContent> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final mediaList = widget.post.post.media;
    final mediaFiles = mediaList
        .map(
          (m) => EnhancedMediaFile.fromUrl(
            id: m.id.isNotEmpty ? m.id : m.url,
            url: m.url,
            fileName: m.url.split('/').last,
            thumbnailUrl: m.thumbnail,
          ),
        )
        .toList();

    Widget? contentWidget;
    if (widget.post.post.caption?.isNotEmpty == true) {
      contentWidget = PostContent(
        text: widget.post.post.caption!,
        hashtags: widget.post.post.hashtags,
        mentions: widget.post.post.mentionedUsernames,
        isExpanded: _isExpanded,
        onExpandToggle: () => setState(() => _isExpanded = !_isExpanded),
        maxLines: 6,
      );
    }

    if (contentWidget == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: widget.child,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        contentWidget,
        if (mediaList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: EnhancedMediaDisplay(
              mediaFiles: mediaFiles,
              config: MediaDisplayConfig(
                layoutMode: mediaFiles.length == 1
                    ? MediaLayoutMode.single
                    : MediaLayoutMode.carousel,
                mediaBucket: MediaBucket.socialMedia,
                allowFullScreen: true,
                allowDelete: false,
                maxHeight: 380,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: widget.child,
        ),
        const SizedBox(height: 4), // Reduced from 8 to 4
      ],
    );
  }
}

class _LiveBucketCard extends StatelessWidget {
  final FeedPost post;
  const _LiveBucketCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final sourceId = post.post.sourceId;
    if (sourceId == null || sourceId.isEmpty) return _buildFallback();

    return FutureBuilder<BucketModel?>(
      future: BucketRepository().getBucket(sourceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer();
        }
        if (snapshot.hasData && snapshot.data != null) {
          return SharedBucketCardView(
            bucket: snapshot.data!,
            allowInteraction: true,
            isListView: true,
            margin: EdgeInsets.zero,
          );
        }
        return _buildFallback();
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildFallback() {
    if (post.post.sourceData == null || post.post.sourceData!.isEmpty) {
      return _buildUnavailablePlaceholder('Bucket');
    }
    try {
      final bucket = BucketModel.fromJson(post.post.sourceData!);
      return SharedBucketCardView(
        bucket: bucket,
        allowInteraction: true,
        isListView: true,
        margin: EdgeInsets.zero,
      );
    } catch (e) {
      return _buildUnavailablePlaceholder('Bucket');
    }
  }

  Widget _buildUnavailablePlaceholder(String type) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Text(
            '$type information no longer available',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LiveDayTaskCard extends StatelessWidget {
  final FeedPost post;
  const _LiveDayTaskCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final sourceId = post.post.sourceId;
    if (sourceId == null || sourceId.isEmpty) return _buildFallback();

    return FutureBuilder<DayTaskModel?>(
      future: DayTaskRepository().getTaskById(sourceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer();
        }
        if (snapshot.hasData && snapshot.data != null) {
          return PostSharedDayTaskCard(
            task: snapshot.data!,
            margin: EdgeInsets.zero,
          );
        }
        return _buildFallback();
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildFallback() {
    if (post.post.sourceData == null || post.post.sourceData!.isEmpty) {
      return _buildUnavailablePlaceholder('Task');
    }
    try {
      final task = DayTaskModel.fromJson(post.post.sourceData!);
      return PostSharedDayTaskCard(task: task, margin: EdgeInsets.zero);
    } catch (e) {
      return _buildUnavailablePlaceholder('Task');
    }
  }

  Widget _buildUnavailablePlaceholder(String type) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_busy_rounded, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Text(
            '$type information no longer available',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LiveLongGoalCard extends StatelessWidget {
  final FeedPost post;
  const _LiveLongGoalCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final sourceId = post.post.sourceId;
    if (sourceId == null || sourceId.isEmpty) return _buildFallback();

    return FutureBuilder<LongGoalModel?>(
      future: LongGoalsRepository().getGoalById(id: sourceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer();
        }
        if (snapshot.hasData && snapshot.data != null) {
          return PostSharedLongGoalCard(
            goal: snapshot.data!,
            isLive: post.post.isLive,
            margin: EdgeInsets.zero,
          );
        }
        return _buildFallback();
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildFallback() {
    if (post.post.sourceData == null || post.post.sourceData!.isEmpty) {
      return _buildUnavailablePlaceholder('Goal');
    }
    try {
      final goal = LongGoalModel.fromJson(post.post.sourceData!);
      return PostSharedLongGoalCard(
        goal: goal,
        isLive: post.post.isLive,
        margin: EdgeInsets.zero,
      );
    } catch (e) {
      return _buildUnavailablePlaceholder('Goal');
    }
  }

  Widget _buildUnavailablePlaceholder(String type) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_outlined, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Text(
            '$type information no longer available',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LiveWeekTaskCard extends StatelessWidget {
  final FeedPost post;
  const _LiveWeekTaskCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final sourceId = post.post.sourceId;
    if (sourceId == null || sourceId.isEmpty) return _buildFallback();

    return FutureBuilder<WeekTaskModel?>(
      future: WeekTaskRepository().getTaskById(sourceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer();
        }
        if (snapshot.hasData && snapshot.data != null) {
          return PostSharedWeekTaskCard(
            task: snapshot.data!,
            isLive: post.post.isLive,
            margin: EdgeInsets.zero,
          );
        }
        return _buildFallback();
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildFallback() {
    if (post.post.sourceData == null || post.post.sourceData!.isEmpty) {
      return _buildUnavailablePlaceholder('Weekly Plan');
    }
    try {
      final task = WeekTaskModel.fromJson(post.post.sourceData!);
      return PostSharedWeekTaskCard(
        task: task,
        isLive: post.post.isLive,
        margin: EdgeInsets.zero,
      );
    } catch (e) {
      return _buildUnavailablePlaceholder('Weekly Plan');
    }
  }

  Widget _buildUnavailablePlaceholder(String type) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.view_week_outlined, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Text(
            '$type information no longer available',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
