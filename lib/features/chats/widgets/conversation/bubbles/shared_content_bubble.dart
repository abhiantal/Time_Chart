// ================================================================
// FILE: lib/features/chats/widgets/conversation/bubbles/shared_content_bubble.dart
// PURPOSE: Shared content message bubble (tasks, buckets, etc.)
// STYLE: WhatsApp style using MessageBubbleBase and specific widgets
// ================================================================

import 'package:flutter/material.dart';
import 'package:the_time_chart/features/chats/model/chat_message_model.dart';
import 'message_bubble_base.dart';
import 'chat_task_bubble.dart';
import 'chat_poll_bubble.dart';
import '../../../../personal/task_model/week_task/models/week_task_model.dart';
import '../../../../personal/task_model/day_tasks/models/day_task_model.dart';
import '../../../../personal/task_model/day_tasks/repositories/day_task_repository.dart';
import '../../../../personal/task_model/week_task/repositories/week_task_repository.dart';
import '../../../../personal/task_model/long_goal/models/long_goal_model.dart';
import '../../../../personal/task_model/long_goal/repositories/long_goals_repository.dart';
import '../../../../personal/bucket_model/models/bucket_model.dart';
import '../../../../personal/bucket_model/repositories/bucket_repository.dart';

import '../../../../social/post/models/post_model.dart';
import '../../../../social/post/repositories/post_repository.dart';
import '../../../../social/post/widgets/post_card.dart';

// Premium Post Shared Widgets
import '../../../../post_shared/day_task/post_shared_day_task_card.dart';
import '../../../../post_shared/week_task/post_shared_week_task_card.dart';
import '../../../../post_shared/long_goal/post_shared_long_goal_card.dart';
import '../../../../post_shared/bucket/post_shared_bucket_card.dart';

class SharedContentMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final String? senderName;
  final String? senderAvatar;
  final bool showName;
  final bool showAvatar;

  const SharedContentMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onLongPress,
    this.onDoubleTap,
    this.senderName,
    this.senderAvatar,
    this.showName = false,
    this.showAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    if (message.sharedContentType == SharedContentType.chatTask) {
      return ChatTaskBubble(
        message: message,
        isMe: isMe,
        onLongPress: onLongPress,
        onDoubleTap: onDoubleTap,
        senderName: senderName,
        senderAvatar: senderAvatar,
        showName: showName,
        showAvatar: showAvatar,
      );
    }

    if (message.sharedContentType == SharedContentType.chatPoll) {
      return ChatPollBubble(
        message: message,
        isMe: isMe,
        onLongPress: onLongPress,
        onDoubleTap: onDoubleTap,
        senderName: senderName,
        senderAvatar: senderAvatar,
        showName: showName,
        showAvatar: showAvatar,
      );
    }

    // Wrap in WhatsApp-style base with "Forwarded" or context if needed
    return MessageBubbleBase(
      message: message,
      isMe: isMe,
      showName: showName,
      showAvatar: showAvatar,
      senderName: senderName,
      senderAvatar: senderAvatar,
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSharedContext(context),
          const SizedBox(height: 8),
          _LiveSharedContentWidget(
            message: message,
            isMe: isMe,
            onLongPress: onLongPress,
            onDoubleTap: onDoubleTap,
            senderName: senderName,
            senderAvatar: senderAvatar,
          ),
          if (message.textContent != null && message.textContent!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message.textContent!,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSharedContext(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = this.isMe;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isMe ? Colors.white : theme.primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getSharedContentIcon(message.sharedContentType),
            size: 14,
            color: isMe ? Colors.white70 : theme.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            'Shared ${_getSharedContentTitle(message.sharedContentType)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isMe ? Colors.white70 : theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSharedContentIcon(SharedContentType? type) {
    switch (type) {
      case SharedContentType.dayTask:
      case SharedContentType.weeklyTask:
      case SharedContentType.longGoal:
        return Icons.check_circle_outline_rounded;
      case SharedContentType.bucketModel:
        return Icons.folder_open_rounded;
      case SharedContentType.diaryEntry:
        return Icons.book_outlined;
      case SharedContentType.post:
        return Icons.dynamic_feed_rounded;
      case SharedContentType.profile:
        return Icons.person_outline_rounded;
      default:
        return Icons.share_rounded;
    }
  }

  String _getSharedContentTitle(SharedContentType? type) {
    switch (type) {
      case SharedContentType.dayTask:
        return 'Daily Task';
      case SharedContentType.weeklyTask:
        return 'Weekly Task';
      case SharedContentType.longGoal:
        return 'Long Term Goal';
      case SharedContentType.bucketModel:
        return 'Bucket';
      case SharedContentType.diaryEntry:
        return 'Diary Entry';
      case SharedContentType.post:
        return 'Post';
      case SharedContentType.profile:
        return 'Profile';
      default:
        return 'Shared Content';
    }
  }
}

class _LiveSharedContentWidget extends StatefulWidget {
  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final String? senderName;
  final String? senderAvatar;

  const _LiveSharedContentWidget({
    required this.message,
    required this.isMe,
    this.onLongPress,
    this.onDoubleTap,
    this.senderName,
    this.senderAvatar,
  });

  @override
  State<_LiveSharedContentWidget> createState() =>
      _LiveSharedContentWidgetState();
}

class _LiveSharedContentWidgetState extends State<_LiveSharedContentWidget> {
  Future<dynamic>? _dataFuture;

  @override
  void initState() {
    super.initState();
    _initFuture();
  }

  void _initFuture() {
    final type = widget.message.sharedContentType;
    final id = widget.message.sharedContentId;

    if (id == null || id.isEmpty) return;

    switch (type) {
      case SharedContentType.dayTask:
        _dataFuture = DayTaskRepository().getTaskById(id);
        break;
      case SharedContentType.weeklyTask:
        _dataFuture = WeekTaskRepository().getTaskById(id);
        break;
      case SharedContentType.longGoal:
        _dataFuture = LongGoalsRepository().getGoalById(id: id);
        break;
      case SharedContentType.bucketModel:
        _dataFuture = BucketRepository().getBucket(id);
        break;
      case SharedContentType.post:
        _dataFuture = PostRepository().getFeedPostById(id);
        break;
      default:
        _dataFuture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.message.sharedContentType;

    switch (type) {
      case SharedContentType.dayTask:
        return _buildDayTask();
      case SharedContentType.weeklyTask:
        return _buildWeekTask();
      case SharedContentType.longGoal:
        return _buildLongGoal();
      case SharedContentType.bucketModel:
        return _buildBucket();
      case SharedContentType.post:
        return _buildPost();
      default:
        return _buildUnavailablePlaceholder('Content');
    }
  }

  Widget _buildDayTask() {
    if (_dataFuture == null) return _buildDayTaskFallback();

    return FutureBuilder<dynamic>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer(150);
        }
        if (snapshot.hasData && snapshot.data != null) {
          final task = snapshot.data as DayTaskModel;
          return PostSharedDayTaskCard(
            task: task,
          );
        }
        return _buildDayTaskFallback();
      },
    );
  }

  Widget _buildDayTaskFallback() {
    if (widget.message.sharedContentSnapshot == null ||
        widget.message.sharedContentSnapshot!.isEmpty) {
      return _buildUnavailablePlaceholder('Task');
    }
    try {
      final task = DayTaskModel.fromJson(widget.message.sharedContentSnapshot!);
      return PostSharedDayTaskCard(
        task: task,
      );
    } catch (e) {
      debugPrint('DayTask Parse Error: $e');
      return _buildUnavailablePlaceholder('Task');
    }
  }

  Widget _buildWeekTask() {
    if (_dataFuture == null) return _buildWeekTaskFallback();

    return FutureBuilder<dynamic>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer(180);
        }
        if (snapshot.hasData && snapshot.data != null) {
          final task = snapshot.data as WeekTaskModel;
          return PostSharedWeekTaskCard(
            task: task,
            isLive: true,
          );
        }
        return _buildWeekTaskFallback();
      },
    );
  }

  Widget _buildWeekTaskFallback() {
    if (widget.message.sharedContentSnapshot == null ||
        widget.message.sharedContentSnapshot!.isEmpty) {
      return _buildUnavailablePlaceholder('Weekly Plan');
    }
    try {
      final task = WeekTaskModel.fromJson(
        widget.message.sharedContentSnapshot!,
      );
      return PostSharedWeekTaskCard(
        task: task,
        isLive: false,
      );
    } catch (e) {
      debugPrint('WeekTask Parse Error: $e');
      return _buildUnavailablePlaceholder('Weekly Plan');
    }
  }

  Widget _buildLongGoal() {
    if (_dataFuture == null) return _buildLongGoalFallback();

    return FutureBuilder<dynamic>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer(180);
        }
        if (snapshot.hasData && snapshot.data != null) {
          final goal = snapshot.data as LongGoalModel;
          return PostSharedLongGoalCard(
            goal: goal,
            isLive: true,
          );
        }
        return _buildLongGoalFallback();
      },
    );
  }

  Widget _buildLongGoalFallback() {
    if (widget.message.sharedContentSnapshot == null ||
        widget.message.sharedContentSnapshot!.isEmpty) {
      return _buildUnavailablePlaceholder('Long Term Goal');
    }
    try {
      final goal = LongGoalModel.fromJson(widget.message.sharedContentSnapshot!);
      return PostSharedLongGoalCard(
        goal: goal,
        isLive: false,
      );
    } catch (e) {
      debugPrint('LongGoal Parse Error: $e');
      return _buildUnavailablePlaceholder('Long Term Goal');
    }
  }

  Widget _buildBucket() {
    if (_dataFuture == null) return _buildBucketFallback();

    return FutureBuilder<dynamic>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer(120);
        }
        if (snapshot.hasData && snapshot.data != null) {
          final bucket = snapshot.data as BucketModel;
          return SharedBucketCardView(
            bucket: bucket,
          );
        }
        return _buildBucketFallback();
      },
    );
  }

  Widget _buildPost() {
    if (_dataFuture == null) return _buildPostFallback();

    return FutureBuilder<dynamic>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer(200);
        }
        if (snapshot.hasData && snapshot.data != null) {
          final feedPost = snapshot.data as FeedPost;
          return PostCard(
            post: feedPost,
            currentUserId: widget.message.senderId, // or actual viewer? usually message bubble context
          );
        }
        return _buildPostFallback();
      },
    );
  }

  Widget _buildPostFallback() {
    if (widget.message.sharedContentSnapshot == null ||
        widget.message.sharedContentSnapshot!.isEmpty) {
      return _buildUnavailablePlaceholder('Post');
    }
    try {
      // If we have a snapshot, we can try to render it, but for now we fallback to unavailable
      // because we prefer live data for posts
      return _buildUnavailablePlaceholder('Shared Post');
    } catch (e) {
      debugPrint('Post Parse Error: $e');
      return _buildUnavailablePlaceholder('Post');
    }
  }

  Widget _buildBucketFallback() {
    if (widget.message.sharedContentSnapshot == null ||
        widget.message.sharedContentSnapshot!.isEmpty) {
      return _buildUnavailablePlaceholder('Bucket');
    }
    try {
      final bucket = BucketModel.fromJson(widget.message.sharedContentSnapshot!);
      return SharedBucketCardView(
        bucket: bucket,
      );
    } catch (e) {
      debugPrint('Bucket Parse Error: $e');
      return _buildUnavailablePlaceholder('Bucket');
    }
  }

  Widget _buildLoadingShimmer(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildUnavailablePlaceholder(String type) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
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
            '$type no longer available',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
