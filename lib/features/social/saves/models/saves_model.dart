// ============================================================
// 📁 models/social/save_model.dart
// Complete Save/Bookmark Model - Collections + personal notes
// No external packages — pure Dart
// ============================================================

/// ════════════════════════════════════════════════════════════
/// DEFAULT COLLECTION NAME
/// ════════════════════════════════════════════════════════════

const String kDefaultCollectionName = 'All Saved';

/// ════════════════════════════════════════════════════════════
/// SAVE ACTION ENUM
/// ════════════════════════════════════════════════════════════

enum SaveAction {
  saved,
  unsaved;

  static SaveAction fromString(String? value) {
    return SaveAction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SaveAction.saved,
    );
  }

  bool get isSaved => this == SaveAction.saved;
  bool get isUnsaved => this == SaveAction.unsaved;
}

/// ════════════════════════════════════════════════════════════
/// 🎯 MAIN SAVE MODEL
/// ════════════════════════════════════════════════════════════

class SaveModel {
  final String id;
  final String userId;
  final String postId;
  final String collectionName;
  final String? note;
  final DateTime createdAt;

  const SaveModel({
    required this.id,
    required this.userId,
    required this.postId,
    this.collectionName = kDefaultCollectionName,
    this.note,
    required this.createdAt,
  });

  // ════════════════════════════════════════════════════════════
  // FROM JSON
  // ════════════════════════════════════════════════════════════

  factory SaveModel.fromJson(Map<String, dynamic> json) {
    return SaveModel(
      id: json['id'] as String? ?? json['save_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      postId: json['post_id'] as String? ?? '',
      collectionName:
          json['collection_name'] as String? ?? kDefaultCollectionName,
      note: json['note'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
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
      'collection_name': collectionName,
      if (note != null) 'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Minimal JSON for creating via toggle_save()
  Map<String, dynamic> toCreateJson() {
    return {
      'user_id': userId,
      'post_id': postId,
      'collection_name': collectionName,
      if (note != null) 'note': note,
    };
  }

  // ════════════════════════════════════════════════════════════
  // COMPUTED
  // ════════════════════════════════════════════════════════════

  /// Is in default collection?
  bool get isInDefaultCollection => collectionName == kDefaultCollectionName;

  /// Has personal note?
  bool get hasNote => note != null && note!.isNotEmpty;

  /// Time since saved
  Duration get timeSinceSaved => DateTime.now().difference(createdAt);

  /// Human readable time ago
  String get timeAgo {
    final d = timeSinceSaved;
    if (d.inSeconds < 60) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    if (d.inDays < 30) return '${(d.inDays / 7).floor()}w ago';
    if (d.inDays < 365) return '${(d.inDays / 30).floor()}mo ago';
    return '${(d.inDays / 365).floor()}y ago';
  }

  /// Formatted date
  String get formattedDate {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[createdAt.month]} ${createdAt.day}, ${createdAt.year}';
  }

  // ════════════════════════════════════════════════════════════
  // COPY WITH
  // ════════════════════════════════════════════════════════════

  SaveModel copyWith({
    String? id,
    String? userId,
    String? postId,
    String? collectionName,
    String? note,
    DateTime? createdAt,
    bool clearNote = false,
  }) {
    return SaveModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      postId: postId ?? this.postId,
      collectionName: collectionName ?? this.collectionName,
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ════════════════════════════════════════════════════════════
  // EMPTY
  // ════════════════════════════════════════════════════════════

  static SaveModel empty() {
    return SaveModel(id: '', userId: '', postId: '', createdAt: DateTime.now());
  }

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  // ════════════════════════════════════════════════════════════
  // EQUALITY
  // ════════════════════════════════════════════════════════════

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SaveModel && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SaveModel(id: $id, post: $postId, collection: $collectionName)';
}

/// ════════════════════════════════════════════════════════════
/// TOGGLE SAVE RESULT
/// (Response from toggle_save() Supabase function)
/// ════════════════════════════════════════════════════════════

class ToggleSaveResult {
  final bool success;
  final SaveAction action;
  final String postId;
  final String? collection;

  const ToggleSaveResult({
    required this.success,
    required this.action,
    required this.postId,
    this.collection,
  });

  factory ToggleSaveResult.fromJson(Map<String, dynamic> json) {
    return ToggleSaveResult(
      success: json['success'] as bool? ?? false,
      action: SaveAction.fromString(json['action'] as String?),
      postId: json['post_id'] as String? ?? '',
      collection: json['collection'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'action': action.name,
      'post_id': postId,
      if (collection != null) 'collection': collection,
    };
  }

  bool get isSaved => action.isSaved;
  bool get isUnsaved => action.isUnsaved;

  @override
  String toString() =>
      'ToggleSaveResult(action: ${action.name}, post: $postId)';
}

/// ════════════════════════════════════════════════════════════
/// SAVED POST (from get_saved_posts() — save + post data)
/// ════════════════════════════════════════════════════════════

class SavedPost {
  // ──── SAVE DATA ────
  final String saveId;
  final String postId;
  final String collectionName;
  final String? note;
  final DateTime savedAt;

  // ──── POST DATA ────
  final String postUserId;
  final String postUsername;
  final String? postDisplayName;
  final String? postProfileUrl;
  final String? postType;
  final String? contentType;
  final String? caption;
  final List<Map<String, dynamic>>? media;
  final Map<String, dynamic>? reactionsCount;
  final int commentsCount;
  final DateTime? publishedAt;

  const SavedPost({
    required this.saveId,
    required this.postId,
    this.collectionName = kDefaultCollectionName,
    this.note,
    required this.savedAt,
    required this.postUserId,
    required this.postUsername,
    this.postDisplayName,
    this.postProfileUrl,
    this.postType,
    this.contentType,
    this.caption,
    this.media,
    this.reactionsCount,
    this.commentsCount = 0,
    this.publishedAt,
  });

  factory SavedPost.fromJson(Map<String, dynamic> json) {
    return SavedPost(
      saveId: json['save_id'] as String? ?? '',
      postId: json['post_id'] as String? ?? '',
      collectionName:
          json['collection_name'] as String? ?? kDefaultCollectionName,
      note: json['note'] as String?,
      savedAt:
          DateTime.tryParse(json['saved_at'] as String? ?? '') ??
          DateTime.now(),
      postUserId: json['post_user_id'] as String? ?? '',
      postUsername: json['post_username'] as String? ?? '',
      postDisplayName: json['post_display_name'] as String?,
      postProfileUrl: json['post_profile_url'] as String?,
      postType: json['post_type'] as String?,
      contentType: json['content_type'] as String?,
      caption: json['caption'] as String? ?? json['content_text'] as String?,
      media: (json['media'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      reactionsCount: json['reactions_count'] as Map<String, dynamic>?,
      commentsCount: json['comments_count'] as int? ?? 0,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'save_id': saveId,
      'post_id': postId,
      'collection_name': collectionName,
      if (note != null) 'note': note,
      'saved_at': savedAt.toIso8601String(),
      'post_user_id': postUserId,
      'post_username': postUsername,
      if (postDisplayName != null) 'post_display_name': postDisplayName,
      if (postProfileUrl != null) 'post_profile_url': postProfileUrl,
      if (postType != null) 'post_type': postType,
      if (contentType != null) 'content_type': contentType,
      if (caption != null) 'caption': caption,
      if (media != null) 'media': media,
      if (reactionsCount != null) 'reactions_count': reactionsCount,
      'comments_count': commentsCount,
      if (publishedAt != null) 'published_at': publishedAt!.toIso8601String(),
    };
  }

  // ──── COMPUTED ────

  bool get hasNote => note != null && note!.isNotEmpty;
  bool get hasMedia => media != null && media!.isNotEmpty;
  bool get hasText => caption != null && caption!.isNotEmpty;
  bool get isInDefaultCollection => collectionName == kDefaultCollectionName;

  /// Total reactions
  int get totalReactions => reactionsCount?['total'] as int? ?? 0;

  /// First media thumbnail URL
  String? get thumbnailUrl {
    if (media == null || media!.isEmpty) return null;
    final first = media!.first;
    return first['thumbnail_url'] as String? ?? first['url'] as String?;
  }

  /// Content preview (truncated)
  String get contentPreview {
    if (caption == null || caption!.isEmpty) return '';
    if (caption!.length <= 100) return caption!;
    return '${caption!.substring(0, 100)}...';
  }

  /// Time since saved
  String get savedTimeAgo {
    final d = DateTime.now().difference(savedAt);
    if (d.inSeconds < 60) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    if (d.inDays < 30) return '${(d.inDays / 7).floor()}w ago';
    if (d.inDays < 365) return '${(d.inDays / 30).floor()}mo ago';
    return '${(d.inDays / 365).floor()}y ago';
  }

  /// Post type icon hint
  String get typeIcon {
    switch (postType) {
      case 'reel':
        return '🎬';
      case 'story':
        return '📸';
      case 'article':
        return '📝';
      case 'shared':
        return '🔗';
      default:
        return '';
    }
  }

  SavedPost copyWith({
    String? saveId,
    String? postId,
    String? collectionName,
    String? note,
    DateTime? savedAt,
    String? postUserId,
    String? postUsername,
    String? postDisplayName,
    String? postProfileUrl,
    String? postType,
    String? contentType,
    String? caption,
    List<Map<String, dynamic>>? media,
    Map<String, dynamic>? reactionsCount,
    int? commentsCount,
    DateTime? publishedAt,
    bool clearNote = false,
  }) {
    return SavedPost(
      saveId: saveId ?? this.saveId,
      postId: postId ?? this.postId,
      collectionName: collectionName ?? this.collectionName,
      note: clearNote ? null : (note ?? this.note),
      savedAt: savedAt ?? this.savedAt,
      postUserId: postUserId ?? this.postUserId,
      postUsername: postUsername ?? this.postUsername,
      postDisplayName: postDisplayName ?? this.postDisplayName,
      postProfileUrl: postProfileUrl ?? this.postProfileUrl,
      postType: postType ?? this.postType,
      contentType: contentType ?? this.contentType,
      caption: caption ?? this.caption,
      media: media ?? this.media,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SavedPost && saveId == other.saveId;

  @override
  int get hashCode => saveId.hashCode;

  @override
  String toString() =>
      'SavedPost(save: $saveId, post: $postId, collection: $collectionName)';
}

/// ════════════════════════════════════════════════════════════
/// COLLECTION MODEL (from get_user_collections())
/// ════════════════════════════════════════════════════════════

class SaveCollection {
  final String name;
  final int postCount;
  final DateTime? latestSavedAt;
  final Map<String, dynamic>? latestPostThumbnail;

  const SaveCollection({
    required this.name,
    this.postCount = 0,
    this.latestSavedAt,
    this.latestPostThumbnail,
  });

  factory SaveCollection.fromJson(Map<String, dynamic> json) {
    return SaveCollection(
      name: json['collection_name'] as String? ?? kDefaultCollectionName,
      postCount: json['post_count'] as int? ?? 0,
      latestSavedAt: json['latest_saved_at'] != null
          ? DateTime.tryParse(json['latest_saved_at'] as String)
          : null,
      latestPostThumbnail:
          json['latest_post_thumbnail'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'collection_name': name,
      'post_count': postCount,
      if (latestSavedAt != null)
        'latest_saved_at': latestSavedAt!.toIso8601String(),
      if (latestPostThumbnail != null)
        'latest_post_thumbnail': latestPostThumbnail,
    };
  }

  // ──── COMPUTED ────

  /// Is this the default "All Saved" collection?
  bool get isDefault => name == kDefaultCollectionName;

  /// Can this collection be renamed/deleted?
  bool get isEditable => !isDefault;

  /// Thumbnail URL from latest post
  String? get thumbnailUrl {
    if (latestPostThumbnail == null) return null;
    return latestPostThumbnail!['thumbnail_url'] as String? ??
        latestPostThumbnail!['url'] as String?;
  }

  /// Has thumbnail?
  bool get hasThumbnail => thumbnailUrl != null;

  /// Post count text
  String get postCountText {
    if (postCount == 0) return 'Empty';
    if (postCount == 1) return '1 post';
    return '$postCount posts';
  }

  /// Formatted post count
  String get formattedPostCount {
    if (postCount < 1000) return postCount.toString();
    if (postCount < 1000000) {
      return '${(postCount / 1000).toStringAsFixed(1)}K';
    }
    return '${(postCount / 1000000).toStringAsFixed(1)}M';
  }

  /// Last updated time ago
  String? get lastUpdatedAgo {
    if (latestSavedAt == null) return null;
    final d = DateTime.now().difference(latestSavedAt!);
    if (d.inHours < 1) return 'Updated just now';
    if (d.inHours < 24) return 'Updated ${d.inHours}h ago';
    if (d.inDays < 7) return 'Updated ${d.inDays}d ago';
    if (d.inDays < 30) return 'Updated ${(d.inDays / 7).floor()}w ago';
    return 'Updated ${(d.inDays / 30).floor()}mo ago';
  }

  SaveCollection copyWith({
    String? name,
    int? postCount,
    DateTime? latestSavedAt,
    Map<String, dynamic>? latestPostThumbnail,
  }) {
    return SaveCollection(
      name: name ?? this.name,
      postCount: postCount ?? this.postCount,
      latestSavedAt: latestSavedAt ?? this.latestSavedAt,
      latestPostThumbnail: latestPostThumbnail ?? this.latestPostThumbnail,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SaveCollection && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'SaveCollection(name: $name, posts: $postCount)';
}

/// ════════════════════════════════════════════════════════════
/// MOVE SAVE RESULT
/// (Response from move_save_to_collection())
/// ════════════════════════════════════════════════════════════

class MoveSaveResult {
  final bool success;
  final String saveId;
  final String oldCollection;
  final String newCollection;

  const MoveSaveResult({
    required this.success,
    required this.saveId,
    required this.oldCollection,
    required this.newCollection,
  });

  factory MoveSaveResult.fromJson(Map<String, dynamic> json) {
    return MoveSaveResult(
      success: json['success'] as bool? ?? false,
      saveId: json['save_id'] as String? ?? '',
      oldCollection: json['old_collection'] as String? ?? '',
      newCollection: json['new_collection'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'save_id': saveId,
      'old_collection': oldCollection,
      'new_collection': newCollection,
    };
  }

  @override
  String toString() => 'MoveSaveResult($oldCollection → $newCollection)';
}

/// ════════════════════════════════════════════════════════════
/// UPDATE NOTE RESULT
/// (Response from update_save_note())
/// ════════════════════════════════════════════════════════════

class UpdateNoteResult {
  final bool success;
  final String saveId;
  final String? note;

  const UpdateNoteResult({
    required this.success,
    required this.saveId,
    this.note,
  });

  factory UpdateNoteResult.fromJson(Map<String, dynamic> json) {
    return UpdateNoteResult(
      success: json['success'] as bool? ?? false,
      saveId: json['save_id'] as String? ?? '',
      note: json['note'] as String?,
    );
  }

  @override
  String toString() =>
      'UpdateNoteResult(save: $saveId, note: ${note != null ? "set" : "cleared"})';
}

/// ════════════════════════════════════════════════════════════
/// RENAME COLLECTION RESULT
/// (Response from rename_collection())
/// ════════════════════════════════════════════════════════════

class RenameCollectionResult {
  final bool success;
  final String oldName;
  final String newName;
  final int itemsUpdated;

  const RenameCollectionResult({
    required this.success,
    required this.oldName,
    required this.newName,
    this.itemsUpdated = 0,
  });

  factory RenameCollectionResult.fromJson(Map<String, dynamic> json) {
    return RenameCollectionResult(
      success: json['success'] as bool? ?? false,
      oldName: json['old_name'] as String? ?? '',
      newName: json['new_name'] as String? ?? '',
      itemsUpdated: json['items_updated'] as int? ?? 0,
    );
  }

  @override
  String toString() =>
      'RenameCollectionResult($oldName → $newName, $itemsUpdated items)';
}

/// ════════════════════════════════════════════════════════════
/// DELETE COLLECTION RESULT
/// (Response from delete_collection())
/// ════════════════════════════════════════════════════════════

class DeleteCollectionResult {
  final bool success;
  final String collection;
  final String action; // 'deleted_with_saves' or 'moved_to_default'
  final int itemsAffected;

  const DeleteCollectionResult({
    required this.success,
    required this.collection,
    required this.action,
    this.itemsAffected = 0,
  });

  factory DeleteCollectionResult.fromJson(Map<String, dynamic> json) {
    return DeleteCollectionResult(
      success: json['success'] as bool? ?? false,
      collection: json['collection'] as String? ?? '',
      action: json['action'] as String? ?? '',
      itemsAffected: json['items_affected'] as int? ?? 0,
    );
  }

  bool get savesDeleted => action == 'deleted_with_saves';
  bool get savesMovedToDefault => action == 'moved_to_default';

  @override
  String toString() =>
      'DeleteCollectionResult(collection: $collection, action: $action, affected: $itemsAffected)';
}

/// ════════════════════════════════════════════════════════════
/// SAVED POSTS LIST (paginated)
/// ════════════════════════════════════════════════════════════

class SavedPostsList {
  final List<SavedPost> posts;
  final String? collectionFilter;
  final int totalCount;
  final bool hasMore;
  final int offset;
  final bool isLoading;

  const SavedPostsList({
    this.posts = const [],
    this.collectionFilter,
    this.totalCount = 0,
    this.hasMore = false,
    this.offset = 0,
    this.isLoading = false,
  });

  factory SavedPostsList.fromJsonList(
    List<dynamic> jsonList, {
    String? collectionFilter,
    int offset = 0,
    int limit = 20,
  }) {
    final posts = jsonList
        .map((e) => SavedPost.fromJson(e as Map<String, dynamic>))
        .toList();
    return SavedPostsList(
      posts: posts,
      collectionFilter: collectionFilter,
      totalCount: posts.length,
      hasMore: posts.length >= limit,
      offset: offset,
    );
  }

  // ──── COMPUTED ────

  bool get isEmpty => posts.isEmpty;
  bool get isNotEmpty => posts.isNotEmpty;
  bool get isFilteredByCollection => collectionFilter != null;

  /// Posts with notes only
  List<SavedPost> get postsWithNotes => posts.where((p) => p.hasNote).toList();

  /// Posts with media only
  List<SavedPost> get postsWithMedia => posts.where((p) => p.hasMedia).toList();

  /// Group posts by collection
  Map<String, List<SavedPost>> get groupedByCollection {
    final grouped = <String, List<SavedPost>>{};
    for (final post in posts) {
      grouped.putIfAbsent(post.collectionName, () => []).add(post);
    }
    return grouped;
  }

  /// Get unique collection names from loaded posts
  List<String> get collectionNames {
    final names = posts.map((p) => p.collectionName).toSet().toList();
    // Ensure default is first
    names.remove(kDefaultCollectionName);
    return [kDefaultCollectionName, ...names];
  }

  /// Append more posts (pagination)
  SavedPostsList appendPosts(List<SavedPost> morePosts) {
    return SavedPostsList(
      posts: [...posts, ...morePosts],
      collectionFilter: collectionFilter,
      totalCount: totalCount + morePosts.length,
      hasMore: morePosts.length >= 20,
      offset: offset + morePosts.length,
    );
  }

  /// Remove a saved post (after unsaving)
  SavedPostsList removePost(String saveId) {
    return SavedPostsList(
      posts: posts.where((p) => p.saveId != saveId).toList(),
      collectionFilter: collectionFilter,
      totalCount: (totalCount - 1).clamp(0, totalCount),
      hasMore: hasMore,
      offset: offset,
    );
  }

  /// Remove by post ID
  SavedPostsList removeByPostId(String postId) {
    return SavedPostsList(
      posts: posts.where((p) => p.postId != postId).toList(),
      collectionFilter: collectionFilter,
      totalCount: (totalCount - 1).clamp(0, totalCount),
      hasMore: hasMore,
      offset: offset,
    );
  }

  /// Update a saved post (after moving collection, updating note)
  SavedPostsList updatePost(SavedPost updated) {
    return SavedPostsList(
      posts: posts
          .map((p) => p.saveId == updated.saveId ? updated : p)
          .toList(),
      collectionFilter: collectionFilter,
      totalCount: totalCount,
      hasMore: hasMore,
      offset: offset,
    );
  }

  /// Move post to different collection (optimistic)
  SavedPostsList movePostToCollection(String saveId, String newCollection) {
    final updated = posts.map((p) {
      if (p.saveId == saveId) {
        return p.copyWith(collectionName: newCollection);
      }
      return p;
    }).toList();

    // If filtering by collection, remove moved post from view
    if (collectionFilter != null && collectionFilter != newCollection) {
      return SavedPostsList(
        posts: updated.where((p) => p.saveId != saveId).toList(),
        collectionFilter: collectionFilter,
        totalCount: (totalCount - 1).clamp(0, totalCount),
        hasMore: hasMore,
        offset: offset,
      );
    }

    return SavedPostsList(
      posts: updated,
      collectionFilter: collectionFilter,
      totalCount: totalCount,
      hasMore: hasMore,
      offset: offset,
    );
  }

  SavedPostsList copyWith({
    List<SavedPost>? posts,
    String? collectionFilter,
    int? totalCount,
    bool? hasMore,
    int? offset,
    bool? isLoading,
    bool clearFilter = false,
  }) {
    return SavedPostsList(
      posts: posts ?? this.posts,
      collectionFilter: clearFilter
          ? null
          : (collectionFilter ?? this.collectionFilter),
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  String toString() =>
      'SavedPostsList(count: ${posts.length}/$totalCount, filter: ${collectionFilter ?? "all"})';
}

/// ════════════════════════════════════════════════════════════
/// COLLECTIONS LIST (all user collections)
/// ════════════════════════════════════════════════════════════

class CollectionsList {
  final List<SaveCollection> collections;
  final bool isLoading;

  const CollectionsList({this.collections = const [], this.isLoading = false});

  factory CollectionsList.fromJsonList(List<dynamic> jsonList) {
    final collections = jsonList
        .map((e) => SaveCollection.fromJson(e as Map<String, dynamic>))
        .toList();
    return CollectionsList(collections: collections);
  }

  // ──── COMPUTED ────

  bool get isEmpty => collections.isEmpty;
  bool get isNotEmpty => collections.isNotEmpty;

  /// Total saved posts across all collections
  int get totalSavedPosts => collections.fold(0, (sum, c) => sum + c.postCount);

  /// Collection count (excluding default)
  int get customCollectionCount =>
      collections.where((c) => !c.isDefault).length;

  /// Default collection
  SaveCollection? get defaultCollection =>
      collections.where((c) => c.isDefault).firstOrNull;

  /// Custom collections only
  List<SaveCollection> get customCollections =>
      collections.where((c) => !c.isDefault).toList();

  /// Collection names for dropdown/picker
  List<String> get collectionNames => collections.map((c) => c.name).toList();

  /// Find collection by name
  SaveCollection? findByName(String name) {
    try {
      return collections.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  /// Does collection name exist?
  bool hasCollection(String name) => collections.any((c) => c.name == name);

  /// Add a new collection (optimistic)
  CollectionsList addCollection(SaveCollection collection) {
    if (hasCollection(collection.name)) return this;
    return CollectionsList(collections: [...collections, collection]);
  }

  /// Remove a collection (optimistic)
  CollectionsList removeCollection(String name) {
    if (name == kDefaultCollectionName) return this;
    return CollectionsList(
      collections: collections.where((c) => c.name != name).toList(),
    );
  }

  /// Rename a collection (optimistic)
  CollectionsList renameCollection(String oldName, String newName) {
    return CollectionsList(
      collections: collections.map((c) {
        if (c.name == oldName) return c.copyWith(name: newName);
        return c;
      }).toList(),
    );
  }

  /// Update collection post count
  CollectionsList updateCount(String name, int delta) {
    return CollectionsList(
      collections: collections.map((c) {
        if (c.name == name) {
          return c.copyWith(
            postCount: (c.postCount + delta).clamp(0, c.postCount + delta),
          );
        }
        return c;
      }).toList(),
    );
  }

  CollectionsList copyWith({
    List<SaveCollection>? collections,
    bool? isLoading,
  }) {
    return CollectionsList(
      collections: collections ?? this.collections,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  String toString() =>
      'CollectionsList(count: ${collections.length}, total posts: $totalSavedPosts)';
}

/// ════════════════════════════════════════════════════════════
/// SAVE STATE (local UI state for a single post's save button)
/// ════════════════════════════════════════════════════════════

class SaveButtonState {
  final String postId;
  final bool isSaved;
  final String? collectionName;
  final bool isLoading;

  const SaveButtonState({
    required this.postId,
    this.isSaved = false,
    this.collectionName,
    this.isLoading = false,
  });

  factory SaveButtonState.fromPostData(String postId, {bool? hasSaved}) {
    return SaveButtonState(postId: postId, isSaved: hasSaved ?? false);
  }

  // ──── COMPUTED ────

  /// Icon hint (bookmark filled or outline)
  String get iconHint => isSaved ? 'bookmark_filled' : 'bookmark_outline';

  /// Tooltip text
  String get tooltipText => isSaved ? 'Saved' : 'Save';

  /// Apply toggle result
  SaveButtonState applyToggleResult(ToggleSaveResult result) {
    return SaveButtonState(
      postId: postId,
      isSaved: result.isSaved,
      collectionName: result.collection,
      isLoading: false,
    );
  }

  SaveButtonState copyWith({
    String? postId,
    bool? isSaved,
    String? collectionName,
    bool? isLoading,
  }) {
    return SaveButtonState(
      postId: postId ?? this.postId,
      isSaved: isSaved ?? this.isSaved,
      collectionName: collectionName ?? this.collectionName,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  String toString() => 'SaveButtonState(post: $postId, saved: $isSaved)';
}

/// ════════════════════════════════════════════════════════════
/// SAVE TO COLLECTION DIALOG STATE
/// ════════════════════════════════════════════════════════════

class SaveToCollectionState {
  final String postId;
  final List<SaveCollection> collections;
  final String selectedCollection;
  final String? note;
  final bool isCreatingNew;
  final String newCollectionName;
  final bool isLoading;

  const SaveToCollectionState({
    required this.postId,
    this.collections = const [],
    this.selectedCollection = kDefaultCollectionName,
    this.note,
    this.isCreatingNew = false,
    this.newCollectionName = '',
    this.isLoading = false,
  });

  // ──── COMPUTED ────

  /// Currently selected collection name
  String get targetCollection =>
      isCreatingNew ? newCollectionName : selectedCollection;

  /// Is the new collection name valid?
  bool get isNewNameValid =>
      newCollectionName.trim().isNotEmpty &&
      newCollectionName.trim().length >= 2 &&
      !collections.any(
        (c) => c.name.toLowerCase() == newCollectionName.trim().toLowerCase(),
      );

  /// Can submit?
  bool get canSubmit => !isLoading && targetCollection.isNotEmpty;

  /// Validation error for new name
  String? get newNameError {
    if (!isCreatingNew) return null;
    if (newCollectionName.trim().isEmpty) return 'Enter a name';
    if (newCollectionName.trim().length < 2) return 'Name too short';
    if (collections.any(
      (c) => c.name.toLowerCase() == newCollectionName.trim().toLowerCase(),
    )) {
      return 'Collection already exists';
    }
    return null;
  }

  SaveToCollectionState copyWith({
    String? postId,
    List<SaveCollection>? collections,
    String? selectedCollection,
    String? note,
    bool? isCreatingNew,
    String? newCollectionName,
    bool? isLoading,
    bool clearNote = false,
  }) {
    return SaveToCollectionState(
      postId: postId ?? this.postId,
      collections: collections ?? this.collections,
      selectedCollection: selectedCollection ?? this.selectedCollection,
      note: clearNote ? null : (note ?? this.note),
      isCreatingNew: isCreatingNew ?? this.isCreatingNew,
      newCollectionName: newCollectionName ?? this.newCollectionName,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  String toString() =>
      'SaveToCollectionState(post: $postId, target: $targetCollection)';
}
