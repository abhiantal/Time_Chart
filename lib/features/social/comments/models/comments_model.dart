import 'dart:convert';

// ============================================================
// 📁 models/social/comment_model.dart
// Complete Comment Model - Threaded comments with materialized path
// No external packages — pure Dart
// ============================================================

/// ════════════════════════════════════════════════════════════
/// COMMENT LIST CONTAINER
/// ════════════════════════════════════════════════════════════

class CommentsList {
  final String postId;
  final List<CommentModel> comments;
  final CommentModel? pinnedComment;
  final int totalCount;
  final bool isLoading;
  final int offset;
  final CommentSortBy sortBy;

  const CommentsList({
    required this.postId,
    this.comments = const [],
    this.pinnedComment,
    this.totalCount = 0,
    this.isLoading = false,
    this.offset = 0,
    this.sortBy = CommentSortBy.newest,
  });

  bool get isEmpty => comments.isEmpty && pinnedComment == null;
  bool get hasMore => comments.length < totalCount;

  CommentsList copyWith({
    String? postId,
    List<CommentModel>? comments,
    CommentModel? pinnedComment,
    int? totalCount,
    bool? isLoading,
    int? offset,
    CommentSortBy? sortBy,
  }) {
    return CommentsList(
      postId: postId ?? this.postId,
      comments: comments ?? this.comments,
      pinnedComment: pinnedComment ?? this.pinnedComment,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      offset: offset ?? this.offset,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  factory CommentsList.fromJsonList(
    String postId,
    List<dynamic> jsonList, {
    CommentSortBy sortBy = CommentSortBy.newest,
    int offset = 0,
    int limit = 20,
    int totalCount = 0,
  }) {
    final allComments = jsonList.map((j) => CommentModel.fromJson(j)).toList();

    // Extract pinned comment
    CommentModel? pinned;
    final otherComments = <CommentModel>[];

    for (final c in allComments) {
      if (c.isPinned && c.parentCommentId == null) {
        pinned = c;
      } else {
        otherComments.add(c);
      }
    }

    return CommentsList(
      postId: postId,
      comments: otherComments,
      pinnedComment: pinned,
      totalCount: totalCount > 0 ? totalCount : jsonList.length,
      sortBy: sortBy,
      offset: offset + jsonList.length,
    );
  }

  // Helpers
  CommentsList addComment(CommentModel comment) {
    return copyWith(
      comments: [comment, ...comments],
      totalCount: totalCount + 1,
    );
  }

  CommentsList removeComment(String commentId) {
    if (pinnedComment?.id == commentId) {
      return copyWith(pinnedComment: null, totalCount: totalCount - 1);
    }
    return copyWith(
      comments: comments.where((c) => c.id != commentId).toList(),
      totalCount: totalCount - 1,
    );
  }

  CommentsList pinComment(String commentId) {
    final comment = comments.firstWhere(
      (c) => c.id == commentId,
      orElse: () => CommentModel.empty(),
    );
    if (comment.isEmpty) return this;

    // If there was already a pinned comment, unpin it and add back to list
    List<CommentModel> newComments = [...comments];
    if (pinnedComment != null) {
      newComments.add(pinnedComment!.copyWith(isPinned: false));
    }

    newComments.removeWhere((c) => c.id == commentId);

    return copyWith(
      comments: newComments,
      pinnedComment: comment.copyWith(isPinned: true),
    );
  }

  CommentsList unpinComment() {
    if (pinnedComment == null) return this;

    final oldPinned = pinnedComment!.copyWith(isPinned: false);
    return copyWith(
      pinnedComment: null,
      comments: [oldPinned, ...comments], // Add back to top or sort potentially
    );
  }
}

/// ════════════════════════════════════════════════════════════
/// COMMENT INPUT STATE
/// ════════════════════════════════════════════════════════════

class CommentInputState {
  final String text;
  final bool isSubmitting;
  final CommentModel? replyingTo;
  final CommentModel? editingComment;
  final List<String> detectedMentions;
  final List<String> detectedHashtags;

  const CommentInputState({
    this.text = '',
    this.isSubmitting = false,
    this.replyingTo,
    this.editingComment,
    this.detectedMentions = const [],
    this.detectedHashtags = const [],
  });

  bool get isReplying => replyingTo != null;
  bool get isEditing => editingComment != null;
  bool get hasText => text.isNotEmpty;

  CommentInputState copyWith({
    String? text,
    bool? isSubmitting,
    CommentModel? replyingTo,
    CommentModel? editingComment,
    List<String>? detectedMentions,
    List<String>? detectedHashtags,
    bool clearReply = false,
    bool clearEdit = false,
  }) {
    return CommentInputState(
      text: text ?? this.text,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      replyingTo: clearReply ? null : (replyingTo ?? this.replyingTo),
      editingComment: clearEdit
          ? null
          : (editingComment ?? this.editingComment),
      detectedMentions: detectedMentions ?? this.detectedMentions,
      detectedHashtags: detectedHashtags ?? this.detectedHashtags,
    );
  }

  static CommentInputState replying(CommentModel comment) {
    return CommentInputState(replyingTo: comment);
  }

  static CommentInputState editing(CommentModel comment) {
    return CommentInputState(text: comment.content, editingComment: comment);
  }

  static List<String> extractMentions(String text) {
    final regex = RegExp(r'@(\w+)');
    return regex.allMatches(text).map((m) => m.group(1)!).toList();
  }

  static List<String> extractHashtags(String text) {
    final regex = RegExp(r'#(\w+)');
    return regex.allMatches(text).map((m) => m.group(1)!).toList();
  }

  // Computed property for UI binding
  ({bool isReplying, String placeholderText, String? replyToCommentId})
  get replyState {
    if (replyingTo != null) {
      final username = replyingTo!.username ?? 'user';
      return (
        isReplying: true,
        placeholderText: 'Replying to @$username',
        replyToCommentId: replyingTo!.id,
      );
    }
    return (
      isReplying: false,
      placeholderText: 'Add a comment...',
      replyToCommentId: null,
    );
  }
}

/// ════════════════════════════════════════════════════════════
/// COMMENT SORT ENUM
/// ════════════════════════════════════════════════════════════

enum CommentSortBy {
  newest,
  oldest,
  top,
  threaded;

  static CommentSortBy fromString(String? value) {
    return CommentSortBy.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CommentSortBy.newest,
    );
  }

  String get label {
    switch (this) {
      case CommentSortBy.newest:
        return 'Newest first';
      case CommentSortBy.oldest:
        return 'Oldest first';
      case CommentSortBy.top:
        return 'Top comments';
      case CommentSortBy.threaded:
        return 'Threaded';
    }
  }

  String get description {
    switch (this) {
      case CommentSortBy.newest:
        return 'Most recent comments on top';
      case CommentSortBy.oldest:
        return 'Oldest comments on top';
      case CommentSortBy.top:
        return 'Most liked comments on top';
      case CommentSortBy.threaded:
        return 'Comments with replies grouped together';
    }
  }
}

/// ════════════════════════════════════════════════════════════
/// COMMENT MEDIA (single image/gif/sticker)
/// ════════════════════════════════════════════════════════════

class CommentMedia {
  final String type; // 'image', 'gif', 'sticker'
  final String url;
  final int? width;
  final int? height;

  const CommentMedia({
    required this.type,
    required this.url,
    this.width,
    this.height,
  });

  factory CommentMedia.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const CommentMedia(type: '', url: '');
    }
    return CommentMedia(
      type: json['type'] as String? ?? 'image',
      url: json['url'] as String? ?? '',
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    };
  }

  bool get isImage => type == 'image';
  bool get isGif => type == 'gif';
  bool get isSticker => type == 'sticker';
  bool get isEmpty => url.isEmpty;
  bool get isNotEmpty => url.isNotEmpty;

  double? get aspectRatio {
    if (width == null || height == null || height == 0) return null;
    return width! / height!;
  }

  CommentMedia copyWith({String? type, String? url, int? width, int? height}) {
    return CommentMedia(
      type: type ?? this.type,
      url: url ?? this.url,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  String toString() => 'CommentMedia(type: $type, url: $url)';
}

/// ════════════════════════════════════════════════════════════
/// 🎯 MAIN COMMENT MODEL
/// ════════════════════════════════════════════════════════════

class CommentModel {
  // ──── CORE ────
  final String id;
  final String userId;
  final String postId;

  // ──── THREADING ────
  final String? parentCommentId;
  final String? replyToUserId;
  final int threadDepth;
  final String? threadPath;

  // ──── CONTENT ────
  final String content;
  final String? contentRendered;
  final List<String>? mentions;
  final List<String>? mentionedUsernames;
  final List<String>? hashtags;

  // ──── MEDIA ────
  final CommentMedia? media;

  // ──── ENGAGEMENT ────
  final Map<String, dynamic>? reactionsCountRaw;
  final int repliesCount;

  // ──── STATUS ────
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final bool isHidden;
  final bool isPinned;
  final bool isByAuthor;

  // ──── TIMESTAMPS ────
  final DateTime createdAt;
  final DateTime updatedAt;

  // ──── FEED/JOIN EXTRAS ────
  final String? username;
  final String? displayName;
  final String? profileUrl;
  final String? replyToUsername;
  final String? replyToDisplayName;
  final bool? hasReacted;
  final String? userReaction;

  // ──── LOCAL STATE ────
  final List<CommentModel> replies;
  final bool isRepliesLoaded;
  final bool isRepliesLoading;
  final bool isExpanded;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.postId,
    this.parentCommentId,
    this.replyToUserId,
    this.threadDepth = 0,
    this.threadPath,
    required this.content,
    this.contentRendered,
    this.mentions,
    this.mentionedUsernames,
    this.hashtags,
    this.media,
    this.reactionsCountRaw,
    this.repliesCount = 0,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.isHidden = false,
    this.isPinned = false,
    this.isByAuthor = false,
    required this.createdAt,
    required this.updatedAt,
    this.username,
    this.displayName,
    this.profileUrl,
    this.replyToUsername,
    this.replyToDisplayName,
    this.hasReacted,
    this.userReaction,
    this.replies = const [],
    this.isRepliesLoaded = false,
    this.isRepliesLoading = false,
    this.isExpanded = false,
  });

  // ════════════════════════════════════════════════════════════
  // FROM JSON
  // ════════════════════════════════════════════════════════════

  static Map<String, dynamic>? _parseJsonMap(dynamic val) {
    if (val == null) return null;
    if (val is Map) return Map<String, dynamic>.from(val);
    if (val is String) {
      try {
        final decoded = jsonDecode(val);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  static List<String>? _parseJsonListString(dynamic val) {
    if (val == null) return null;
    if (val is List) return val.map((e) => e.toString()).toList();
    if (val is String) {
      try {
        final decoded = jsonDecode(val);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    return null;
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      // Core
      id: json['id'] as String? ?? json['comment_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      postId: json['post_id'] as String? ?? '',

      // Threading
      parentCommentId: json['parent_comment_id'] as String?,
      replyToUserId: json['reply_to_user_id'] as String?,
      threadDepth: json['thread_depth'] as int? ?? 0,
      threadPath: json['thread_path'] as String?,

      // Content
      content: json['content'] as String? ?? '',
      contentRendered: json['content_rendered'] as String?,
      mentions: _parseJsonListString(json['mentions']),
      mentionedUsernames: _parseJsonListString(json['mentioned_usernames']),
      hashtags: _parseJsonListString(json['hashtags']),

      // Media
      media: _parseJsonMap(json['media']) != null
          ? CommentMedia.fromJson(_parseJsonMap(json['media']))
          : null,

      // Engagement
      reactionsCountRaw: _parseJsonMap(json['reactions_count']),
      repliesCount: json['replies_count'] as int? ?? 0,

      // Status
      isEdited: json['is_edited'] as bool? ?? false,
      editedAt: json['edited_at'] != null
          ? DateTime.tryParse(json['edited_at'] as String)
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
      isHidden: json['is_hidden'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      isByAuthor: json['is_by_author'] as bool? ?? false,

      // Timestamps
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),

      // Join extras
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      profileUrl: json['profile_url'] as String?,
      replyToUsername: json['reply_to_username'] as String?,
      replyToDisplayName: json['reply_to_display_name'] as String?,
      hasReacted: json['has_reacted'] as bool?,
      userReaction: json['user_reaction'] as String?,
    );
  }

  // ════════════════════════════════════════════════════════════
  // TO JSON
  // ════════════════════════════════════════════════════════════

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'post_id': postId,
      if (parentCommentId != null) 'parent_comment_id': parentCommentId,
      if (replyToUserId != null) 'reply_to_user_id': replyToUserId,
      'thread_depth': threadDepth,
      if (threadPath != null) 'thread_path': threadPath,
      'content': content,
      if (contentRendered != null) 'content_rendered': contentRendered,
      if (mentions != null) 'mentions': mentions,
      if (mentionedUsernames != null) 'mentioned_usernames': mentionedUsernames,
      if (hashtags != null) 'hashtags': hashtags,
      if (media != null) 'media': media!.toJson(),
      if (reactionsCountRaw != null) 'reactions_count': reactionsCountRaw,
      'replies_count': repliesCount,
      'is_edited': isEdited,
      if (editedAt != null) 'edited_at': editedAt!.toIso8601String(),
      'is_deleted': isDeleted,
      'is_hidden': isHidden,
      'is_pinned': isPinned,
      'is_by_author': isByAuthor,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Minimal JSON for creating a comment via add_comment()
  Map<String, dynamic> toCreateJson() {
    return {
      'p_user_id': userId,
      'p_post_id': postId,
      'p_content': content,
      if (parentCommentId != null) 'p_parent_comment_id': parentCommentId,
      if (mentions != null && mentions!.isNotEmpty) 'p_mentions': mentions,
      if (mentionedUsernames != null && mentionedUsernames!.isNotEmpty)
        'p_mentioned_usernames': mentionedUsernames,
      if (media != null) 'p_media': media!.toJson(),
    };
  }

  // ════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ════════════════════════════════════════════════════════════

  /// Is this a root-level comment?
  bool get isRoot => parentCommentId == null && threadDepth == 0;

  /// Is this a reply to another comment?
  bool get isReply => parentCommentId != null;

  /// Does this comment have replies?
  bool get hasReplies => repliesCount > 0;

  /// Does this comment have media?
  bool get hasMedia => media != null && media!.isNotEmpty;

  /// Does this comment have mentions?
  bool get hasMentions => mentions != null && mentions!.isNotEmpty;

  /// Does this comment have hashtags?
  bool get hasHashtags => hashtags != null && hashtags!.isNotEmpty;

  /// Is this comment effectively visible?
  bool get isVisible => !isDeleted && !isHidden;

  /// Display content (handles deleted/hidden states)
  String get displayContent {
    if (isDeleted) return 'This comment has been deleted';
    if (isHidden) return 'This comment is hidden';
    return content;
  }

  /// Total reactions count
  int get totalReactions {
    if (reactionsCountRaw == null) return 0;
    return reactionsCountRaw!['total'] as int? ?? 0;
  }

  /// Is this comment reacted to by current user?
  bool get isReactedByMe => hasReacted == true;

  /// Indent level for UI (pixels or multiplier)
  int get indentLevel => threadDepth;

  /// Can this comment be replied to? (max depth check)
  bool get canReply => threadDepth < 4 && !isDeleted;

  /// Time since posted
  Duration get timeSincePosted => DateTime.now().difference(createdAt);

  /// Human readable time ago
  String get timeAgo {
    final duration = timeSincePosted;
    if (duration.inSeconds < 5) return 'now';
    if (duration.inSeconds < 60) return '${duration.inSeconds}s';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m';
    if (duration.inHours < 24) return '${duration.inHours}h';
    if (duration.inDays < 7) return '${duration.inDays}d';
    if (duration.inDays < 30) return '${(duration.inDays / 7).floor()}w';
    if (duration.inDays < 365) return '${(duration.inDays / 30).floor()}mo';
    return '${(duration.inDays / 365).floor()}y';
  }

  /// Formatted reactions count
  String get formattedReactionsCount => _formatCount(totalReactions);

  /// Formatted replies count
  String get formattedRepliesCount => _formatCount(repliesCount);

  /// Reply text ("View 5 replies", "View 1 reply")
  String get viewRepliesText {
    if (repliesCount == 0) return '';
    if (repliesCount == 1) return 'View 1 reply';
    return 'View $formattedRepliesCount replies';
  }

  /// Hide replies text
  String get hideRepliesText {
    if (repliesCount == 0) return '';
    if (repliesCount == 1) return 'Hide reply';
    return 'Hide replies';
  }

  /// Display username with author badge
  String get displayUsername {
    final name = username ?? 'Unknown';
    return isByAuthor ? '$name · Author' : name;
  }

  /// Edited label
  String get editedLabel {
    if (!isEdited) return '';
    if (editedAt != null) {
      final ago = DateTime.now().difference(editedAt!);
      if (ago.inMinutes < 1) return '(edited just now)';
      if (ago.inHours < 1) return '(edited ${ago.inMinutes}m ago)';
      if (ago.inDays < 1) return '(edited ${ago.inHours}h ago)';
      return '(edited)';
    }
    return '(edited)';
  }

  /// Thread path segments for ordering
  List<String> get pathSegments {
    if (threadPath == null) return [];
    return threadPath!.split('/');
  }

  /// Reply context text ("Replying to @username")
  String? get replyContextText {
    if (replyToUsername == null) return null;
    return 'Replying to @$replyToUsername';
  }

  // ════════════════════════════════════════════════════════════
  // FORMAT HELPER
  // ════════════════════════════════════════════════════════════

  static String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 10000) {
      final formatted = (count / 1000).toStringAsFixed(1);
      return formatted.endsWith('.0')
          ? '${(count / 1000).floor()}K'
          : '${formatted}K';
    }
    if (count < 1000000) return '${(count / 1000).floor()}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  // ════════════════════════════════════════════════════════════
  // COPY WITH
  // ════════════════════════════════════════════════════════════

  CommentModel copyWith({
    String? id,
    String? userId,
    String? postId,
    String? parentCommentId,
    String? replyToUserId,
    int? threadDepth,
    String? threadPath,
    String? content,
    String? contentRendered,
    List<String>? mentions,
    List<String>? mentionedUsernames,
    List<String>? hashtags,
    CommentMedia? media,
    Map<String, dynamic>? reactionsCountRaw,
    int? repliesCount,
    bool? isEdited,
    DateTime? editedAt,
    bool? isDeleted,
    bool? isHidden,
    bool? isPinned,
    bool? isByAuthor,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? username,
    String? displayName,
    String? profileUrl,
    String? replyToUsername,
    String? replyToDisplayName,
    bool? hasReacted,
    String? userReaction,
    List<CommentModel>? replies,
    bool? isRepliesLoaded,
    bool? isRepliesLoading,
    bool? isExpanded,
    bool clearMedia = false,
    bool clearUserReaction = false,
  }) {
    return CommentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      postId: postId ?? this.postId,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replyToUserId: replyToUserId ?? this.replyToUserId,
      threadDepth: threadDepth ?? this.threadDepth,
      threadPath: threadPath ?? this.threadPath,
      content: content ?? this.content,
      contentRendered: contentRendered ?? this.contentRendered,
      mentions: mentions ?? this.mentions,
      mentionedUsernames: mentionedUsernames ?? this.mentionedUsernames,
      hashtags: hashtags ?? this.hashtags,
      media: clearMedia ? null : (media ?? this.media),
      reactionsCountRaw: reactionsCountRaw ?? this.reactionsCountRaw,
      repliesCount: repliesCount ?? this.repliesCount,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isHidden: isHidden ?? this.isHidden,
      isPinned: isPinned ?? this.isPinned,
      isByAuthor: isByAuthor ?? this.isByAuthor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      profileUrl: profileUrl ?? this.profileUrl,
      replyToUsername: replyToUsername ?? this.replyToUsername,
      replyToDisplayName: replyToDisplayName ?? this.replyToDisplayName,
      hasReacted: hasReacted ?? this.hasReacted,
      userReaction: clearUserReaction
          ? null
          : (userReaction ?? this.userReaction),
      replies: replies ?? this.replies,
      isRepliesLoaded: isRepliesLoaded ?? this.isRepliesLoaded,
      isRepliesLoading: isRepliesLoading ?? this.isRepliesLoading,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  // ════════════════════════════════════════════════════════════
  // EMPTY / DEFAULT
  // ════════════════════════════════════════════════════════════

  static CommentModel empty() {
    return CommentModel(
      id: '',
      userId: '',
      postId: '',
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  // ════════════════════════════════════════════════════════════
  // EQUALITY
  // ════════════════════════════════════════════════════════════

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CommentModel && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CommentModel(id: $id, depth: $threadDepth, path: $threadPath, replies: $repliesCount)';
}

/// ════════════════════════════════════════════════════════════
/// ADD COMMENT RESULT
/// (Response from add_comment() Supabase function)
/// ════════════════════════════════════════════════════════════

class AddCommentResult {
  final bool success;
  final String? commentId;
  final String? userId;
  final String? username;
  final String? profileUrl;
  final String? content;
  final String? parentCommentId;
  final int? threadDepth;
  final String? threadPath;
  final bool? isByAuthor;
  final CommentMedia? media;
  final DateTime? createdAt;

  const AddCommentResult({
    required this.success,
    this.commentId,
    this.userId,
    this.username,
    this.profileUrl,
    this.content,
    this.parentCommentId,
    this.threadDepth,
    this.threadPath,
    this.isByAuthor,
    this.media,
    this.createdAt,
  });

  factory AddCommentResult.fromJson(Map<String, dynamic> json) {
    return AddCommentResult(
      success: json['success'] as bool? ?? false,
      commentId: json['comment_id'] as String?,
      userId: json['user_id'] as String?,
      username: json['username'] as String?,
      profileUrl: json['profile_url'] as String?,
      content: json['content'] as String?,
      parentCommentId: json['parent_comment_id'] as String?,
      threadDepth: json['thread_depth'] as int?,
      threadPath: json['thread_path'] as String?,
      isByAuthor: json['is_by_author'] as bool?,
      media: json['media'] != null
          ? CommentMedia.fromJson(json['media'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  /// Convert result to a CommentModel for immediate UI display
  CommentModel toCommentModel({String? postId}) {
    return CommentModel(
      id: commentId ?? '',
      userId: userId ?? '',
      postId: postId ?? '',
      parentCommentId: parentCommentId,
      threadDepth: threadDepth ?? 0,
      threadPath: threadPath,
      content: content ?? '',
      media: media,
      isByAuthor: isByAuthor ?? false,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: createdAt ?? DateTime.now(),
      username: username,
      profileUrl: profileUrl,
    );
  }

  @override
  String toString() => 'AddCommentResult(success: $success, id: $commentId)';
}

/// ════════════════════════════════════════════════════════════
/// EDIT COMMENT RESULT
/// ════════════════════════════════════════════════════════════

class EditCommentResult {
  final bool success;
  final bool changed;
  final String? commentId;
  final String? oldContent;
  final String? newContent;
  final DateTime? editedAt;

  const EditCommentResult({
    required this.success,
    this.changed = false,
    this.commentId,
    this.oldContent,
    this.newContent,
    this.editedAt,
  });

  factory EditCommentResult.fromJson(Map<String, dynamic> json) {
    return EditCommentResult(
      success: json['success'] as bool? ?? false,
      changed: json['changed'] as bool? ?? false,
      commentId: json['comment_id'] as String?,
      oldContent: json['old_content'] as String?,
      newContent: json['new_content'] as String?,
      editedAt: json['edited_at'] != null
          ? DateTime.tryParse(json['edited_at'] as String)
          : null,
    );
  }

  @override
  String toString() =>
      'EditCommentResult(success: $success, changed: $changed)';
}

/// ════════════════════════════════════════════════════════════
/// DELETE COMMENT RESULT
/// ════════════════════════════════════════════════════════════

class DeleteCommentResult {
  final bool success;
  final String? commentId;
  final String? deletedBy; // 'comment_author' or 'post_author'

  const DeleteCommentResult({
    required this.success,
    this.commentId,
    this.deletedBy,
  });

  factory DeleteCommentResult.fromJson(Map<String, dynamic> json) {
    return DeleteCommentResult(
      success: json['success'] as bool? ?? false,
      commentId: json['comment_id'] as String?,
      deletedBy: json['deleted_by'] as String?,
    );
  }

  bool get deletedByPostAuthor => deletedBy == 'post_author';
  bool get deletedByCommentAuthor => deletedBy == 'comment_author';

  @override
  String toString() => 'DeleteCommentResult(success: $success, by: $deletedBy)';
}

/// ════════════════════════════════════════════════════════════
/// PIN COMMENT RESULT
/// ════════════════════════════════════════════════════════════

class PinCommentResult {
  final bool success;
  final String? commentId;
  final bool isPinned;

  const PinCommentResult({
    required this.success,
    this.commentId,
    this.isPinned = false,
  });

  factory PinCommentResult.fromJson(Map<String, dynamic> json) {
    return PinCommentResult(
      success: json['success'] as bool? ?? false,
      commentId: json['comment_id'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'PinCommentResult(success: $success, pinned: $isPinned)';
}

/// ════════════════════════════════════════════════════════════
/// HIDE COMMENT RESULT
/// ════════════════════════════════════════════════════════════

class HideCommentResult {
  final bool success;
  final String? commentId;
  final bool isHidden;

  const HideCommentResult({
    required this.success,
    this.commentId,
    this.isHidden = false,
  });

  factory HideCommentResult.fromJson(Map<String, dynamic> json) {
    return HideCommentResult(
      success: json['success'] as bool? ?? false,
      commentId: json['comment_id'] as String?,
      isHidden: json['is_hidden'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'HideCommentResult(success: $success, hidden: $isHidden)';
}

/// ════════════════════════════════════════════════════════════
/// COMMENT THREAD (root comment with loaded replies)
/// ════════════════════════════════════════════════════════════

class CommentThread {
  final CommentModel rootComment;
  final List<CommentModel> replies;
  final bool hasMoreReplies;
  final int totalReplies;

  const CommentThread({
    required this.rootComment,
    this.replies = const [],
    this.hasMoreReplies = false,
    this.totalReplies = 0,
  });

  factory CommentThread.fromRootComment(
    CommentModel root, {
    List<CommentModel> allComments = const [],
  }) {
    // Extract replies from flat list using thread_path
    final threadReplies =
        allComments
            .where(
              (c) =>
                  c.parentCommentId == root.id ||
                  (c.threadPath != null &&
                      root.threadPath != null &&
                      c.threadPath!.startsWith('${root.threadPath}/') &&
                      c.id != root.id),
            )
            .toList()
          ..sort((a, b) {
            if (a.threadPath != null && b.threadPath != null) {
              return a.threadPath!.compareTo(b.threadPath!);
            }
            return a.createdAt.compareTo(b.createdAt);
          });

    return CommentThread(
      rootComment: root.copyWith(
        replies: threadReplies,
        isRepliesLoaded: true,
        repliesCount: threadReplies.length,
      ),
      replies: threadReplies,
      totalReplies: threadReplies.length,
      // For now assume all loaded if passed in allComments
      hasMoreReplies: false,
    );
  }
}
