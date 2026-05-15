// ============================================================
// 📁 models/social/follow_model.dart
// Complete Follow Model - Social graph with relationship types
// No external packages — pure Dart
// ============================================================

/// ════════════════════════════════════════════════════════════
/// FOLLOW STATUS ENUM
/// ════════════════════════════════════════════════════════════

enum FollowStatus {
  active,
  pending,
  blocked;

  static FollowStatus fromString(String? value) {
    return FollowStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FollowStatus.active,
    );
  }

  static FollowStatus? tryFromString(String? value) {
    if (value == null) return null;
    try {
      return FollowStatus.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return null;
    }
  }

  String get label {
    switch (this) {
      case FollowStatus.active:
        return 'Following';
      case FollowStatus.pending:
        return 'Requested';
      case FollowStatus.blocked:
        return 'Blocked';
    }
  }

  String get description {
    switch (this) {
      case FollowStatus.active:
        return 'You are following this user';
      case FollowStatus.pending:
        return 'Follow request sent, waiting for approval';
      case FollowStatus.blocked:
        return 'This user is blocked';
    }
  }

  bool get isActive => this == FollowStatus.active;
  bool get isPending => this == FollowStatus.pending;
  bool get isBlocked => this == FollowStatus.blocked;
}

/// ════════════════════════════════════════════════════════════
/// RELATIONSHIP TYPE ENUM
/// ════════════════════════════════════════════════════════════

enum FollowRelationship {
  follow,
  closeFriend,
  favorite,
  muted,
  restricted;

  String get value {
    switch (this) {
      case FollowRelationship.follow:
        return 'follow';
      case FollowRelationship.closeFriend:
        return 'close_friend';
      case FollowRelationship.favorite:
        return 'favorite';
      case FollowRelationship.muted:
        return 'muted';
      case FollowRelationship.restricted:
        return 'restricted';
    }
  }

  static FollowRelationship fromString(String? value) {
    switch (value) {
      case 'close_friend':
        return FollowRelationship.closeFriend;
      case 'favorite':
        return FollowRelationship.favorite;
      case 'muted':
        return FollowRelationship.muted;
      case 'restricted':
        return FollowRelationship.restricted;
      case 'follow':
      default:
        return FollowRelationship.follow;
    }
  }

  String get label {
    switch (this) {
      case FollowRelationship.follow:
        return 'Following';
      case FollowRelationship.closeFriend:
        return 'Close Friend';
      case FollowRelationship.favorite:
        return 'Favorite';
      case FollowRelationship.muted:
        return 'Muted';
      case FollowRelationship.restricted:
        return 'Restricted';
    }
  }

  String get description {
    switch (this) {
      case FollowRelationship.follow:
        return 'Regular follow — see posts in feed';
      case FollowRelationship.closeFriend:
        return 'Close friend — see close friends stories';
      case FollowRelationship.favorite:
        return 'Favorite — posts shown first in feed';
      case FollowRelationship.muted:
        return 'Muted — still following but hidden from feed';
      case FollowRelationship.restricted:
        return 'Restricted — limited interactions';
    }
  }

  String get emoji {
    switch (this) {
      case FollowRelationship.follow:
        return '👤';
      case FollowRelationship.closeFriend:
        return '⭐';
      case FollowRelationship.favorite:
        return '❤️';
      case FollowRelationship.muted:
        return '🔇';
      case FollowRelationship.restricted:
        return '🚫';
    }
  }

  int get feedPriority {
    switch (this) {
      case FollowRelationship.favorite:
        return 10;
      case FollowRelationship.closeFriend:
        return 5;
      case FollowRelationship.follow:
        return 0;
      case FollowRelationship.restricted:
        return -5;
      case FollowRelationship.muted:
        return -10;
    }
  }

  bool get showsInFeed {
    switch (this) {
      case FollowRelationship.follow:
      case FollowRelationship.closeFriend:
      case FollowRelationship.favorite:
        return true;
      case FollowRelationship.muted:
      case FollowRelationship.restricted:
        return false;
    }
  }
}

/// ════════════════════════════════════════════════════════════
/// FOLLOW ACTION ENUM (result of toggle_follow)
/// ════════════════════════════════════════════════════════════

enum FollowAction {
  followed,
  unfollowed,
  requested,
  accepted,
  rejected,
  blocked,
  unblocked;

  static FollowAction fromString(String? value) {
    return FollowAction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FollowAction.followed,
    );
  }

  String get label {
    switch (this) {
      case FollowAction.followed:
        return 'Following';
      case FollowAction.unfollowed:
        return 'Unfollowed';
      case FollowAction.requested:
        return 'Requested';
      case FollowAction.accepted:
        return 'Accepted';
      case FollowAction.rejected:
        return 'Rejected';
      case FollowAction.blocked:
        return 'Blocked';
      case FollowAction.unblocked:
        return 'Unblocked';
    }
  }
}

/// ════════════════════════════════════════════════════════════
/// NOTIFICATION PREFERENCES (per follow)
/// ════════════════════════════════════════════════════════════

class FollowNotificationPrefs {
  final bool posts;
  final bool stories;
  final bool reels;
  final bool live;
  final bool all;

  const FollowNotificationPrefs({
    this.posts = true,
    this.stories = true,
    this.reels = true,
    this.live = true,
    this.all = true,
  });

  factory FollowNotificationPrefs.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FollowNotificationPrefs();
    return FollowNotificationPrefs(
      posts: json['posts'] as bool? ?? true,
      stories: json['stories'] as bool? ?? true,
      reels: json['reels'] as bool? ?? true,
      live: json['live'] as bool? ?? true,
      all: json['all'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'posts': posts,
      'stories': stories,
      'reels': reels,
      'live': live,
      'all': all,
    };
  }

  /// Are all notifications enabled?
  bool get allEnabled => posts && stories && reels && live;

  /// Are all notifications disabled?
  bool get allDisabled => !posts && !stories && !reels && !live;

  /// Count of enabled notification types
  int get enabledCount {
    int count = 0;
    if (posts) count++;
    if (stories) count++;
    if (reels) count++;
    if (live) count++;
    return count;
  }

  /// Summary text
  String get summaryText {
    if (allEnabled) return 'All notifications on';
    if (allDisabled) return 'All notifications off';
    final enabled = <String>[];
    if (posts) enabled.add('Posts');
    if (stories) enabled.add('Stories');
    if (reels) enabled.add('Reels');
    if (live) enabled.add('Live');
    return enabled.join(', ');
  }

  FollowNotificationPrefs copyWith({
    bool? posts,
    bool? stories,
    bool? reels,
    bool? live,
    bool? all,
  }) {
    return FollowNotificationPrefs(
      posts: posts ?? this.posts,
      stories: stories ?? this.stories,
      reels: reels ?? this.reels,
      live: live ?? this.live,
      all: all ?? this.all,
    );
  }

  /// Toggle all on/off
  FollowNotificationPrefs toggleAll(bool enabled) {
    return FollowNotificationPrefs(
      posts: enabled,
      stories: enabled,
      reels: enabled,
      live: enabled,
      all: enabled,
    );
  }

  @override
  String toString() => 'FollowNotificationPrefs($summaryText)';
}

/// ════════════════════════════════════════════════════════════
/// 🎯 MAIN FOLLOW MODEL
/// ════════════════════════════════════════════════════════════

class FollowModel {
  final String id;
  final String followerId;
  final String followingId;
  final FollowStatus status;
  final FollowRelationship relationship;
  final FollowNotificationPrefs notifications;
  final bool showInFeed;
  final int feedPriority;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FollowModel({
    required this.id,
    required this.followerId,
    required this.followingId,
    this.status = FollowStatus.active,
    this.relationship = FollowRelationship.follow,
    this.notifications = const FollowNotificationPrefs(),
    this.showInFeed = true,
    this.feedPriority = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // ════════════════════════════════════════════════════════════
  // FROM JSON
  // ════════════════════════════════════════════════════════════

  factory FollowModel.fromJson(Map<String, dynamic> json) {
    return FollowModel(
      id: json['id'] as String? ?? '',
      followerId: json['follower_id'] as String? ?? '',
      followingId: json['following_id'] as String? ?? '',
      status: FollowStatus.fromString(json['status'] as String?),
      relationship: FollowRelationship.fromString(
        json['relationship'] as String?,
      ),
      notifications: FollowNotificationPrefs.fromJson(
        json['notifications'] as Map<String, dynamic>?,
      ),
      showInFeed: json['show_in_feed'] as bool? ?? true,
      feedPriority: json['feed_priority'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  // ════════════════════════════════════════════════════════════
  // TO JSON
  // ════════════════════════════════════════════════════════════

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'follower_id': followerId,
      'following_id': followingId,
      'status': status.name,
      'relationship': relationship.value,
      'notifications': notifications.toJson(),
      'show_in_feed': showInFeed,
      'feed_priority': feedPriority,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ════════════════════════════════════════════════════════════
  // COMPUTED
  // ════════════════════════════════════════════════════════════

  bool get isActive => status.isActive;
  bool get isPending => status.isPending;
  bool get isBlocked => status.isBlocked;

  bool get isCloseFriend => relationship == FollowRelationship.closeFriend;
  bool get isFavorite => relationship == FollowRelationship.favorite;
  bool get isMuted => relationship == FollowRelationship.muted;
  bool get isRestricted => relationship == FollowRelationship.restricted;
  bool get isRegularFollow => relationship == FollowRelationship.follow;

  /// How long following
  Duration get followDuration => DateTime.now().difference(createdAt);

  /// Time since following text
  String get followingSince {
    final d = followDuration;
    if (d.inDays < 1) return 'Today';
    if (d.inDays < 7) return '${d.inDays}d ago';
    if (d.inDays < 30) return '${(d.inDays / 7).floor()}w ago';
    if (d.inDays < 365) return '${(d.inDays / 30).floor()}mo ago';
    return '${(d.inDays / 365).floor()}y ago';
  }

  // ════════════════════════════════════════════════════════════
  // COPY WITH
  // ════════════════════════════════════════════════════════════

  FollowModel copyWith({
    String? id,
    String? followerId,
    String? followingId,
    FollowStatus? status,
    FollowRelationship? relationship,
    FollowNotificationPrefs? notifications,
    bool? showInFeed,
    int? feedPriority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FollowModel(
      id: id ?? this.id,
      followerId: followerId ?? this.followerId,
      followingId: followingId ?? this.followingId,
      status: status ?? this.status,
      relationship: relationship ?? this.relationship,
      notifications: notifications ?? this.notifications,
      showInFeed: showInFeed ?? this.showInFeed,
      feedPriority: feedPriority ?? this.feedPriority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ════════════════════════════════════════════════════════════
  // EMPTY
  // ════════════════════════════════════════════════════════════

  static FollowModel empty() {
    return FollowModel(
      id: '',
      followerId: '',
      followingId: '',
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
      identical(this, other) || other is FollowModel && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'FollowModel(id: $id, ${followerId}→${followingId}, status: ${status.name}, rel: ${relationship.value})';
}

/// ════════════════════════════════════════════════════════════
/// TOGGLE FOLLOW RESULT
/// (Response from toggle_follow() Supabase function)
/// ════════════════════════════════════════════════════════════

class ToggleFollowResult {
  final bool success;
  final FollowAction action;
  final FollowStatus? status;
  final String followerId;
  final String followingId;

  const ToggleFollowResult({
    required this.success,
    required this.action,
    this.status,
    required this.followerId,
    required this.followingId,
  });

  factory ToggleFollowResult.fromJson(Map<String, dynamic> json) {
    return ToggleFollowResult(
      success: json['success'] as bool? ?? false,
      action: FollowAction.fromString(json['action'] as String?),
      status: FollowStatus.tryFromString(json['status'] as String?),
      followerId: json['follower_id'] as String? ?? '',
      followingId: json['following_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'action': action.name,
      if (status != null) 'status': status!.name,
      'follower_id': followerId,
      'following_id': followingId,
    };
  }

  bool get isFollowed => action == FollowAction.followed;
  bool get isUnfollowed => action == FollowAction.unfollowed;
  bool get isRequested => action == FollowAction.requested;
  bool get isNowFollowing => isFollowed;
  bool get isNowPending => isRequested;
  bool get isNowNotFollowing => isUnfollowed;

  @override
  String toString() =>
      'ToggleFollowResult(action: ${action.name}, status: ${status?.name})';
}

/// ════════════════════════════════════════════════════════════
/// FOLLOW REQUEST RESULT
/// (Response from respond_follow_request())
/// ════════════════════════════════════════════════════════════

class FollowRequestResult {
  final bool success;
  final FollowAction action;

  const FollowRequestResult({required this.success, required this.action});

  factory FollowRequestResult.fromJson(Map<String, dynamic> json) {
    return FollowRequestResult(
      success: json['success'] as bool? ?? false,
      action: FollowAction.fromString(json['action'] as String?),
    );
  }

  bool get isAccepted => action == FollowAction.accepted;
  bool get isRejected => action == FollowAction.rejected;

  @override
  String toString() => 'FollowRequestResult(action: ${action.name})';
}

/// ════════════════════════════════════════════════════════════
/// UPDATE RELATIONSHIP RESULT
/// ════════════════════════════════════════════════════════════

class UpdateRelationshipResult {
  final bool success;
  final FollowRelationship relationship;
  final bool showInFeed;
  final int feedPriority;

  const UpdateRelationshipResult({
    required this.success,
    required this.relationship,
    this.showInFeed = true,
    this.feedPriority = 0,
  });

  factory UpdateRelationshipResult.fromJson(Map<String, dynamic> json) {
    return UpdateRelationshipResult(
      success: json['success'] as bool? ?? false,
      relationship: FollowRelationship.fromString(
        json['relationship'] as String?,
      ),
      showInFeed: json['show_in_feed'] as bool? ?? true,
      feedPriority: json['feed_priority'] as int? ?? 0,
    );
  }

  @override
  String toString() =>
      'UpdateRelationshipResult(rel: ${relationship.value}, feed: $showInFeed)';
}

/// ════════════════════════════════════════════════════════════
/// BLOCK USER RESULT
/// ════════════════════════════════════════════════════════════

class BlockUserResult {
  final bool success;
  final FollowAction action;
  final String? targetUserId;

  const BlockUserResult({
    required this.success,
    required this.action,
    this.targetUserId,
  });

  factory BlockUserResult.fromJson(Map<String, dynamic> json) {
    return BlockUserResult(
      success: json['success'] as bool? ?? false,
      action: FollowAction.fromString(json['action'] as String?),
      targetUserId:
          json['blocked_user_id'] as String? ??
          json['unblocked_user_id'] as String?,
    );
  }

  bool get isBlocked => action == FollowAction.blocked;
  bool get isUnblocked => action == FollowAction.unblocked;

  @override
  String toString() =>
      'BlockUserResult(action: ${action.name}, target: $targetUserId)';
}

/// ════════════════════════════════════════════════════════════
/// FOLLOW STATUS CHECK
/// (Response from check_follow_status())
/// ════════════════════════════════════════════════════════════

class FollowStatusCheck {
  final bool iFollow;
  final String? iFollowStatus;
  final String? iFollowRelationship;
  final bool theyFollow;
  final String? theyFollowStatus;
  final bool isMutual;
  final bool isBlocked;
  final bool isPending;

  const FollowStatusCheck({
    this.iFollow = false,
    this.iFollowStatus,
    this.iFollowRelationship,
    this.theyFollow = false,
    this.theyFollowStatus,
    this.isMutual = false,
    this.isBlocked = false,
    this.isPending = false,
  });

  factory FollowStatusCheck.fromJson(Map<String, dynamic> json) {
    return FollowStatusCheck(
      iFollow: json['i_follow'] as bool? ?? false,
      iFollowStatus: json['i_follow_status'] as String?,
      iFollowRelationship: json['i_follow_relationship'] as String?,
      theyFollow: json['they_follow'] as bool? ?? false,
      theyFollowStatus: json['they_follow_status'] as String?,
      isMutual: json['is_mutual'] as bool? ?? false,
      isBlocked: json['is_blocked'] as bool? ?? false,
      isPending: json['is_pending'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'i_follow': iFollow,
      'i_follow_status': iFollowStatus,
      'i_follow_relationship': iFollowRelationship,
      'they_follow': theyFollow,
      'they_follow_status': theyFollowStatus,
      'is_mutual': isMutual,
      'is_blocked': isBlocked,
      'is_pending': isPending,
    };
  }

  // ──── COMPUTED ────

  /// Are we friends (mutual follow)?
  bool get areFriends => isMutual;

  /// Am I following them?
  bool get amFollowing => iFollow;
  bool get isFollowing => iFollow;

  /// Are they following me?
  bool get isFollowingMe => theyFollow;

  /// My relationship type with them
  FollowRelationship? get myRelationship {
    if (iFollowRelationship == null) return null;
    return FollowRelationship.fromString(iFollowRelationship);
  }

  /// Button text for follow button
  String get followButtonText {
    if (isBlocked) return 'Blocked';
    if (isPending) return 'Requested';
    if (iFollow) return 'Following';
    if (theyFollow) return 'Follow Back';
    return 'Follow';
  }

  /// Button style hint
  String get followButtonStyle {
    if (isBlocked) return 'blocked';
    if (isPending) return 'pending';
    if (iFollow) return 'following';
    if (theyFollow) return 'follow_back';
    return 'follow';
  }

  /// Relationship badge text
  String? get relationshipBadge {
    if (isMutual) return 'Friends';
    if (iFollow && myRelationship == FollowRelationship.closeFriend) {
      return 'Close Friend';
    }
    if (theyFollow && !iFollow) return 'Follows you';
    return null;
  }

  /// Can I see their content?
  bool get canSeeContent => iFollow && !isBlocked;

  /// Can I interact with them?
  bool get canInteract => !isBlocked;

  /// Should I see follow back prompt?
  bool get showFollowBack => theyFollow && !iFollow && !isBlocked;

  FollowStatusCheck copyWith({
    bool? iFollow,
    String? iFollowStatus,
    String? iFollowRelationship,
    bool? theyFollow,
    String? theyFollowStatus,
    bool? isMutual,
    bool? isBlocked,
    bool? isPending,
  }) {
    return FollowStatusCheck(
      iFollow: iFollow ?? this.iFollow,
      iFollowStatus: iFollowStatus ?? this.iFollowStatus,
      iFollowRelationship: iFollowRelationship ?? this.iFollowRelationship,
      theyFollow: theyFollow ?? this.theyFollow,
      theyFollowStatus: theyFollowStatus ?? this.theyFollowStatus,
      isMutual: isMutual ?? this.isMutual,
      isBlocked: isBlocked ?? this.isBlocked,
      isPending: isPending ?? this.isPending,
    );
  }

  /// Empty / not checked
  static const FollowStatusCheck none = FollowStatusCheck();

  @override
  String toString() =>
      'FollowStatusCheck(iFollow: $iFollow, theyFollow: $theyFollow, mutual: $isMutual, blocked: $isBlocked)';
}

/// ════════════════════════════════════════════════════════════
/// FOLLOWER USER (from get_followers())
/// ════════════════════════════════════════════════════════════

class FollowerUser {
  final String followId;
  final String userId;
  final String username;
  final String? serverDisplayName;
  final String? profileUrl;
  final Map<String, dynamic>? userInfo;
  final DateTime followedAt;
  final bool isFollowingBack;
  final bool isMutual;

  const FollowerUser({
    required this.followId,
    required this.userId,
    required this.username,
    this.serverDisplayName,
    this.profileUrl,
    this.userInfo,
    required this.followedAt,
    this.isFollowingBack = false,
    this.isMutual = false,
  });

  factory FollowerUser.fromJson(Map<String, dynamic> json) {
    return FollowerUser(
      followId: json['follow_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      serverDisplayName: json['display_name'] as String?,
      profileUrl: json['profile_url'] as String?,
      userInfo: json['user_info'] as Map<String, dynamic>?,
      followedAt:
          DateTime.tryParse(json['followed_at'] as String? ?? '') ??
          DateTime.now(),
      isFollowingBack: json['is_following_back'] as bool? ?? false,
      isMutual: json['is_mutual'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'follow_id': followId,
      'user_id': userId,
      'username': username,
      if (serverDisplayName != null) 'display_name': serverDisplayName,
      if (profileUrl != null) 'profile_url': profileUrl,
      if (userInfo != null) 'user_info': userInfo,
      'followed_at': followedAt.toIso8601String(),
      'is_following_back': isFollowingBack,
      'is_mutual': isMutual,
    };
  }

  // ──── COMPUTED ────

  /// Display name from DB, user_info or username
  String get displayName {
    if (serverDisplayName != null && serverDisplayName!.isNotEmpty) return serverDisplayName!;
    if (userInfo != null) {
      final fullName = userInfo!['full_name'] as String?;
      if (fullName != null && fullName.isNotEmpty) return fullName;
    }
    return username;
  }

  /// Bio from user_info
  String? get bio => userInfo?['bio'] as String?;

  /// Is verified from user_info
  bool get isVerified => userInfo?['is_verified'] as bool? ?? false;

  /// Follow button text
  String get actionButtonText {
    if (isFollowingBack) return 'Following';
    if (isMutual) return 'Friends';
    return 'Follow Back';
  }

  /// Time since they followed
  String get followedTimeAgo {
    final d = DateTime.now().difference(followedAt);
    if (d.inDays < 1) return 'Today';
    if (d.inDays < 7) return '${d.inDays}d ago';
    if (d.inDays < 30) return '${(d.inDays / 7).floor()}w ago';
    if (d.inDays < 365) return '${(d.inDays / 30).floor()}mo ago';
    return '${(d.inDays / 365).floor()}y ago';
  }

  FollowerUser copyWith({
    String? followId,
    String? userId,
    String? username,
    String? serverDisplayName,
    String? profileUrl,
    Map<String, dynamic>? userInfo,
    DateTime? followedAt,
    bool? isFollowingBack,
    bool? isMutual,
  }) {
    return FollowerUser(
      followId: followId ?? this.followId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      serverDisplayName: serverDisplayName ?? this.serverDisplayName,
      profileUrl: profileUrl ?? this.profileUrl,
      userInfo: userInfo ?? this.userInfo,
      followedAt: followedAt ?? this.followedAt,
      isFollowingBack: isFollowingBack ?? this.isFollowingBack,
      isMutual: isMutual ?? this.isMutual,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FollowerUser && userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() => 'FollowerUser(user: $username, mutual: $isMutual)';
}

/// ════════════════════════════════════════════════════════════
/// FOLLOWING USER (from get_following())
/// ════════════════════════════════════════════════════════════

class FollowingUser {
  final String followId;
  final String userId;
  final String username;
  final String? profileUrl;
  final Map<String, dynamic>? userInfo;
  final FollowRelationship relationship;
  final bool showInFeed;
  final DateTime followedAt;
  final bool isMutual;

  const FollowingUser({
    required this.followId,
    required this.userId,
    required this.username,
    this.profileUrl,
    this.userInfo,
    this.relationship = FollowRelationship.follow,
    this.showInFeed = true,
    required this.followedAt,
    this.isMutual = false,
  });

  factory FollowingUser.fromJson(Map<String, dynamic> json) {
    return FollowingUser(
      followId: json['follow_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      profileUrl: json['profile_url'] as String?,
      userInfo: json['user_info'] as Map<String, dynamic>?,
      relationship: FollowRelationship.fromString(
        json['relationship'] as String?,
      ),
      showInFeed: json['show_in_feed'] as bool? ?? true,
      followedAt:
          DateTime.tryParse(json['followed_at'] as String? ?? '') ??
          DateTime.now(),
      isMutual: json['is_mutual'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'follow_id': followId,
      'user_id': userId,
      'username': username,
      if (profileUrl != null) 'profile_url': profileUrl,
      if (userInfo != null) 'user_info': userInfo,
      'relationship': relationship.value,
      'show_in_feed': showInFeed,
      'followed_at': followedAt.toIso8601String(),
      'is_mutual': isMutual,
    };
  }

  // ──── COMPUTED ────

  String get displayName {
    if (userInfo != null) {
      final fullName = userInfo!['full_name'] as String?;
      if (fullName != null && fullName.isNotEmpty) return fullName;
    }
    return username;
  }

  String? get bio => userInfo?['bio'] as String?;
  bool get isVerified => userInfo?['is_verified'] as bool? ?? false;

  bool get isCloseFriend => relationship == FollowRelationship.closeFriend;
  bool get isFavorite => relationship == FollowRelationship.favorite;
  bool get isMuted => relationship == FollowRelationship.muted;
  bool get isRestricted => relationship == FollowRelationship.restricted;

  /// Relationship badge
  String? get badge {
    switch (relationship) {
      case FollowRelationship.closeFriend:
        return '⭐ Close Friend';
      case FollowRelationship.favorite:
        return '❤️ Favorite';
      case FollowRelationship.muted:
        return '🔇 Muted';
      case FollowRelationship.restricted:
        return '🚫 Restricted';
      case FollowRelationship.follow:
        return null;
    }
  }

  String get followedTimeAgo {
    final d = DateTime.now().difference(followedAt);
    if (d.inDays < 1) return 'Today';
    if (d.inDays < 7) return '${d.inDays}d ago';
    if (d.inDays < 30) return '${(d.inDays / 7).floor()}w ago';
    if (d.inDays < 365) return '${(d.inDays / 30).floor()}mo ago';
    return '${(d.inDays / 365).floor()}y ago';
  }

  FollowingUser copyWith({
    String? followId,
    String? userId,
    String? username,
    String? profileUrl,
    Map<String, dynamic>? userInfo,
    FollowRelationship? relationship,
    bool? showInFeed,
    DateTime? followedAt,
    bool? isMutual,
  }) {
    return FollowingUser(
      followId: followId ?? this.followId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      profileUrl: profileUrl ?? this.profileUrl,
      userInfo: userInfo ?? this.userInfo,
      relationship: relationship ?? this.relationship,
      showInFeed: showInFeed ?? this.showInFeed,
      followedAt: followedAt ?? this.followedAt,
      isMutual: isMutual ?? this.isMutual,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowingUser && userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() =>
      'FollowingUser(user: $username, rel: ${relationship.value})';
}

/// ════════════════════════════════════════════════════════════
/// FOLLOW SUGGESTION (from get_follow_suggestions())
/// ════════════════════════════════════════════════════════════

class FollowSuggestion {
  final String userId;
  final String username;
  final String? profileUrl;
  final Map<String, dynamic>? userInfo;
  final int mutualFollowersCount;
  final String reason;

  const FollowSuggestion({
    required this.userId,
    required this.username,
    this.profileUrl,
    this.userInfo,
    this.mutualFollowersCount = 0,
    this.reason = 'mutual_connections',
  });

  factory FollowSuggestion.fromJson(Map<String, dynamic> json) {
    return FollowSuggestion(
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      profileUrl: json['profile_url'] as String?,
      userInfo: json['user_info'] as Map<String, dynamic>?,
      mutualFollowersCount: json['mutual_followers_count'] as int? ?? 0,
      reason: json['reason'] as String? ?? 'mutual_connections',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      if (profileUrl != null) 'profile_url': profileUrl,
      if (userInfo != null) 'user_info': userInfo,
      'mutual_followers_count': mutualFollowersCount,
      'reason': reason,
    };
  }

  // ──── COMPUTED ────

  String get displayName {
    if (userInfo != null) {
      final fullName = userInfo!['full_name'] as String?;
      if (fullName != null && fullName.isNotEmpty) return fullName;
    }
    return username;
  }

  String? get bio => userInfo?['bio'] as String?;
  bool get isVerified => userInfo?['is_verified'] as bool? ?? false;

  /// Suggestion reason text
  String get reasonText {
    switch (reason) {
      case 'mutual_connections':
        if (mutualFollowersCount == 0) return 'Suggested for you';
        if (mutualFollowersCount == 1) return '1 mutual connection';
        return '$mutualFollowersCount mutual connections';
      case 'similar_interests':
        return 'Similar interests';
      case 'popular':
        return 'Popular on the platform';
      case 'contacts':
        return 'From your contacts';
      default:
        return 'Suggested for you';
    }
  }

  bool get hasMutualConnections => mutualFollowersCount > 0;

  FollowSuggestion copyWith({
    String? userId,
    String? username,
    String? profileUrl,
    Map<String, dynamic>? userInfo,
    int? mutualFollowersCount,
    String? reason,
  }) {
    return FollowSuggestion(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      profileUrl: profileUrl ?? this.profileUrl,
      userInfo: userInfo ?? this.userInfo,
      mutualFollowersCount: mutualFollowersCount ?? this.mutualFollowersCount,
      reason: reason ?? this.reason,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowSuggestion && userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() =>
      'FollowSuggestion(user: $username, mutual: $mutualFollowersCount)';
}

/// ════════════════════════════════════════════════════════════
/// FOLLOW REQUEST (pending follow request)
/// ════════════════════════════════════════════════════════════

class FollowRequest {
  final String followId;
  final String userId;
  final String username;
  final String? profileUrl;
  final Map<String, dynamic>? userInfo;
  final DateTime requestedAt;
  final bool isMutual; // they also follow me

  const FollowRequest({
    required this.followId,
    required this.userId,
    required this.username,
    this.profileUrl,
    this.userInfo,
    required this.requestedAt,
    this.isMutual = false,
  });

  factory FollowRequest.fromJson(Map<String, dynamic> json) {
    return FollowRequest(
      followId: json['follow_id'] as String? ?? json['id'] as String? ?? '',
      userId:
          json['user_id'] as String? ?? json['follower_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      profileUrl: json['profile_url'] as String?,
      userInfo: json['user_info'] as Map<String, dynamic>?,
      requestedAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      isMutual: json['is_mutual'] as bool? ?? false,
    );
  }

  // ──── COMPUTED ────

  String get displayName {
    if (userInfo != null) {
      final fullName = userInfo!['full_name'] as String?;
      if (fullName != null && fullName.isNotEmpty) return fullName;
    }
    return username;
  }

  String? get bio => userInfo?['bio'] as String?;
  bool get isVerified => userInfo?['is_verified'] as bool? ?? false;

  String get timeAgo {
    final d = DateTime.now().difference(requestedAt);
    if (d.inDays < 1) return 'Today';
    if (d.inDays < 7) return '${d.inDays}d ago';
    if (d.inDays < 30) return '${(d.inDays / 7).floor()}w ago';
    return '${(d.inDays / 30).floor()}mo ago';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowRequest && userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() => 'FollowRequest(user: $username, at: $timeAgo)';
}

/// ════════════════════════════════════════════════════════════
/// FOLLOWERS LIST (paginated)
/// ════════════════════════════════════════════════════════════

class FollowersList {
  final List<FollowerUser> users;
  final int totalCount;
  final bool hasMore;
  final int offset;
  final String? searchQuery;
  final bool isLoading;

  const FollowersList({
    this.users = const [],
    this.totalCount = 0,
    this.hasMore = false,
    this.offset = 0,
    this.searchQuery,
    this.isLoading = false,
  });

  factory FollowersList.fromJsonList(
    List<dynamic> jsonList, {
    int offset = 0,
    int limit = 50,
    String? searchQuery,
  }) {
    final users = jsonList
        .map((e) => FollowerUser.fromJson(e as Map<String, dynamic>))
        .toList();
    return FollowersList(
      users: users,
      totalCount: users.length,
      hasMore: users.length >= limit,
      offset: offset,
      searchQuery: searchQuery,
    );
  }

  bool get isEmpty => users.isEmpty;
  bool get isNotEmpty => users.isNotEmpty;

  /// Mutual followers only
  List<FollowerUser> get mutualFollowers =>
      users.where((u) => u.isMutual).toList();

  /// Non-mutual followers (not following back)
  List<FollowerUser> get nonMutualFollowers =>
      users.where((u) => !u.isFollowingBack).toList();

  /// Count of mutual followers
  int get mutualCount => mutualFollowers.length;

  /// Append more users (pagination)
  FollowersList appendUsers(FollowersList more) {
    return FollowersList(
      users: [...users, ...more.users],
      totalCount: totalCount + more.totalCount,
      hasMore: more.hasMore,
      offset: more.offset,
      searchQuery: searchQuery,
    );
  }

  /// Remove a user (after unfollowing them back, etc.)
  FollowersList removeUser(String userId) {
    return FollowersList(
      users: users.where((u) => u.userId != userId).toList(),
      totalCount: (totalCount - 1).clamp(0, totalCount),
      hasMore: hasMore,
      offset: offset,
      searchQuery: searchQuery,
    );
  }

  /// Update a user in the list
  FollowersList updateUser(FollowerUser updated) {
    return FollowersList(
      users: users
          .map((u) => u.userId == updated.userId ? updated : u)
          .toList(),
      totalCount: totalCount,
      hasMore: hasMore,
      offset: offset,
      searchQuery: searchQuery,
    );
  }

  FollowersList copyWith({
    List<FollowerUser>? users,
    int? totalCount,
    bool? hasMore,
    int? offset,
    String? searchQuery,
    bool? isLoading,
  }) {
    return FollowersList(
      users: users ?? this.users,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  String toString() =>
      'FollowersList(count: ${users.length}/$totalCount, mutual: $mutualCount)';
}

/// ════════════════════════════════════════════════════════════
/// FOLLOWING LIST (paginated)
/// ════════════════════════════════════════════════════════════

class FollowingList {
  final List<FollowingUser> users;
  final int totalCount;
  final bool hasMore;
  final int offset;
  final FollowRelationship? filterRelationship;
  final String? searchQuery;
  final bool isLoading;

  const FollowingList({
    this.users = const [],
    this.totalCount = 0,
    this.hasMore = false,
    this.offset = 0,
    this.filterRelationship,
    this.searchQuery,
    this.isLoading = false,
  });

  factory FollowingList.fromJsonList(
    List<dynamic> jsonList, {
    int offset = 0,
    int limit = 50,
    FollowRelationship? filterRelationship,
    String? searchQuery,
  }) {
    final users = jsonList
        .map((e) => FollowingUser.fromJson(e as Map<String, dynamic>))
        .toList();
    return FollowingList(
      users: users,
      totalCount: users.length,
      hasMore: users.length >= limit,
      offset: offset,
      filterRelationship: filterRelationship,
      searchQuery: searchQuery,
    );
  }

  bool get isEmpty => users.isEmpty;
  bool get isNotEmpty => users.isNotEmpty;

  /// Filter by relationship type
  List<FollowingUser> byRelationship(FollowRelationship rel) =>
      users.where((u) => u.relationship == rel).toList();

  List<FollowingUser> get closeFriends =>
      byRelationship(FollowRelationship.closeFriend);
  List<FollowingUser> get favorites =>
      byRelationship(FollowRelationship.favorite);
  List<FollowingUser> get muted => byRelationship(FollowRelationship.muted);
  List<FollowingUser> get restricted =>
      byRelationship(FollowRelationship.restricted);
  List<FollowingUser> get regularFollowing =>
      byRelationship(FollowRelationship.follow);

  /// Counts by relationship
  int get closeFriendsCount => closeFriends.length;
  int get favoritesCount => favorites.length;
  int get mutedCount => muted.length;
  int get restrictedCount => restricted.length;

  FollowingList appendUsers(FollowingList more) {
    return FollowingList(
      users: [...users, ...more.users],
      totalCount: totalCount + more.totalCount,
      hasMore: more.hasMore,
      offset: more.offset,
      filterRelationship: filterRelationship,
      searchQuery: searchQuery,
    );
  }

  FollowingList removeUser(String userId) {
    return FollowingList(
      users: users.where((u) => u.userId != userId).toList(),
      totalCount: (totalCount - 1).clamp(0, totalCount),
      hasMore: hasMore,
      offset: offset,
      filterRelationship: filterRelationship,
      searchQuery: searchQuery,
    );
  }

  FollowingList updateUser(FollowingUser updated) {
    return FollowingList(
      users: users
          .map((u) => u.userId == updated.userId ? updated : u)
          .toList(),
      totalCount: totalCount,
      hasMore: hasMore,
      offset: offset,
      filterRelationship: filterRelationship,
      searchQuery: searchQuery,
    );
  }

  FollowingList copyWith({
    List<FollowingUser>? users,
    int? totalCount,
    bool? hasMore,
    int? offset,
    FollowRelationship? filterRelationship,
    String? searchQuery,
    bool? isLoading,
  }) {
    return FollowingList(
      users: users ?? this.users,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      filterRelationship: filterRelationship ?? this.filterRelationship,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  String toString() =>
      'FollowingList(count: ${users.length}/$totalCount, filter: ${filterRelationship?.value ?? "all"})';
}

/// ════════════════════════════════════════════════════════════
/// SOCIAL COUNTS (for profile display)
/// ════════════════════════════════════════════════════════════

class SocialCounts {
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int competitionsCount;

  const SocialCounts({
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.competitionsCount = 0,
  });

  factory SocialCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SocialCounts();
    return SocialCounts(
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      postsCount: json['posts_count'] as int? ?? 0,
      competitionsCount: json['competitions_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followers_count': followersCount,
      'following_count': followingCount,
      'posts_count': postsCount,
      'competitions_count': competitionsCount,
    };
  }

  String get formattedFollowers => _format(followersCount);
  String get formattedFollowing => _format(followingCount);
  String get formattedPosts => _format(postsCount);
  String get formattedCompetitions => _format(competitionsCount);

  static String _format(int count) {
    if (count < 1000) return count.toString();
    if (count < 10000) {
      final f = (count / 1000).toStringAsFixed(1);
      return f.endsWith('.0') ? '${(count / 1000).floor()}K' : '${f}K';
    }
    if (count < 1000000) return '${(count / 1000).floor()}K';
    final f = (count / 1000000).toStringAsFixed(1);
    return f.endsWith('.0') ? '${(count / 1000000).floor()}M' : '${f}M';
  }

  SocialCounts copyWith({
    int? followersCount,
    int? followingCount,
    int? postsCount,
    int? competitionsCount,
  }) {
    return SocialCounts(
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      competitionsCount: competitionsCount ?? this.competitionsCount,
    );
  }

  @override
  String toString() =>
      'SocialCounts(followers: $followersCount, following: $followingCount, posts: $postsCount, competitions: $competitionsCount)';
}

/// ════════════════════════════════════════════════════════════
/// FOLLOW BUTTON STATE (local UI state)
/// ════════════════════════════════════════════════════════════

class FollowButtonState {
  final String targetUserId;
  final bool isFollowing;
  final bool isPending;
  final bool isBlocked;
  final bool isLoading;
  final bool isMutual;
  final FollowRelationship? relationship;

  const FollowButtonState({
    required this.targetUserId,
    this.isFollowing = false,
    this.isPending = false,
    this.isBlocked = false,
    this.isLoading = false,
    this.isMutual = false,
    this.relationship,
  });

  factory FollowButtonState.fromStatusCheck(
    String targetUserId,
    FollowStatusCheck check,
  ) {
    return FollowButtonState(
      targetUserId: targetUserId,
      isFollowing: check.iFollow,
      isPending: check.isPending,
      isBlocked: check.isBlocked,
      isMutual: check.isMutual,
      relationship: check.myRelationship,
    );
  }

  // ──── COMPUTED ────

  /// Button text
  String get buttonText {
    if (isLoading) return '...';
    if (isBlocked) return 'Blocked';
    if (isPending) return 'Requested';
    if (isFollowing) return 'Following';
    if (isMutual) return 'Friends';
    return 'Follow';
  }

  /// Button style key
  String get styleKey {
    if (isBlocked) return 'blocked';
    if (isPending) return 'pending';
    if (isFollowing) return 'following';
    return 'follow';
  }

  /// Is the primary action "Follow"?
  bool get isPrimaryAction => !isFollowing && !isPending && !isBlocked;

  /// Apply toggle result
  FollowButtonState applyToggleResult(ToggleFollowResult result) {
    return FollowButtonState(
      targetUserId: targetUserId,
      isFollowing: result.isFollowed,
      isPending: result.isRequested,
      isBlocked: false,
      isLoading: false,
      isMutual: isMutual,
      relationship: relationship,
    );
  }

  FollowButtonState copyWith({
    String? targetUserId,
    bool? isFollowing,
    bool? isPending,
    bool? isBlocked,
    bool? isLoading,
    bool? isMutual,
    FollowRelationship? relationship,
  }) {
    return FollowButtonState(
      targetUserId: targetUserId ?? this.targetUserId,
      isFollowing: isFollowing ?? this.isFollowing,
      isPending: isPending ?? this.isPending,
      isBlocked: isBlocked ?? this.isBlocked,
      isLoading: isLoading ?? this.isLoading,
      isMutual: isMutual ?? this.isMutual,
      relationship: relationship ?? this.relationship,
    );
  }

  @override
  String toString() =>
      'FollowButtonState(target: $targetUserId, following: $isFollowing, pending: $isPending)';
}

/// ════════════════════════════════════════════════════════════
/// RELATIONSHIP OPTION (for settings bottom sheet)
/// ════════════════════════════════════════════════════════════

class RelationshipOption {
  final FollowRelationship relationship;
  final bool isSelected;

  const RelationshipOption({
    required this.relationship,
    this.isSelected = false,
  });

  String get label => relationship.label;
  String get description => relationship.description;
  String get emoji => relationship.emoji;
  bool get showsInFeed => relationship.showsInFeed;

  /// Get all options with current selection
  static List<RelationshipOption> allOptions({FollowRelationship? selected}) {
    return FollowRelationship.values
        .map(
          (r) => RelationshipOption(relationship: r, isSelected: r == selected),
        )
        .toList();
  }

  RelationshipOption copyWith({
    FollowRelationship? relationship,
    bool? isSelected,
  }) {
    return RelationshipOption(
      relationship: relationship ?? this.relationship,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  String toString() =>
      'RelationshipOption(${relationship.value}, selected: $isSelected)';
}
