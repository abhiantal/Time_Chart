import 'dart:convert';

// Simplified but fully compatible PostModel.dart

class PostModel {
  final String id;
  final String userId;
  final String? username;
  final String? displayName;
  final String? profileUrl;
  final PostType postType; 
  final String? caption;
  final PostMediaList media;

  // COMPATIBILITY GETTER - mapping PostType to ContentType
  ContentType get contentType {
    if (postType == PostType.poll) return ContentType.poll;
    if (postType == PostType.day_task) return ContentType.day_task;
    if (postType == PostType.week_task) return ContentType.week_task;
    if (postType == PostType.long_goal) return ContentType.long_goal;
    if (postType == PostType.bucket) return ContentType.bucket;
    if (postType == PostType.reel) return ContentType.reel;
    if (postType == PostType.story) return ContentType.reel;
    if (postType == PostType.advertisement) return ContentType.advertisement;
    
    if (media.isNotEmpty) {
      final first = media.first;
      if (first.type == 'video' || first.type == 'reel') return ContentType.video;
      if (media.length > 1) return ContentType.carousel;
      return ContentType.image;
    }
    
    return ContentType.text;
  }

  // Interactions
  final int likesCount;
  final Map<String, dynamic>? reactionsCountRaw;
  final int commentsCount;
  final int viewsCount;
  final bool hasReacted;
  final String? userReaction;
  final bool hasSaved;

  // Source / Shared
  final String? sourceType;
  final String? sourceId;
  final String? sourceMode;
  final Map<String, dynamic>? sourceData;

  final DateTime publishedAt;
  final List<dynamic> editHistory;

  final PollData? pollData;
  final ArticleData? articleData;
  final PostVisibility visibility;
  final AdData? adData;
  
  // Missing fields restored for compatibility
  final PostLocation? location;
  final LinkPreview? linkPreview;
  final StoryData? storyData;
  final ReelAudioData? reelAudio;
  final ReelEffects reelEffects;

  // COMPATIBILITY PLACEHOLDERS
  bool get isDeleted => false;
  String? get originalPostId => null;
  List<String> get hashtags => [];
  List<String> get mentionedUsernames => [];
  bool get hasReelAudio => reelAudio != null;
  bool get hasLinkPreview => linkPreview != null;
  int get durationSeconds => 0;

  bool get allowComments => true;
  bool get allowReactions => true;
  bool get allowSaves => true;
  bool get isPinned => false;

  PostModel({
    required this.id,
    required this.userId,
    this.username,
    this.displayName,
    this.profileUrl,
    required this.postType,
    this.caption,
    required this.media,
    this.likesCount = 0,
    this.reactionsCountRaw,
    this.commentsCount = 0,
    this.viewsCount = 0,
    this.hasReacted = false,
    this.userReaction,
    this.hasSaved = false,
    this.sourceType,
    this.sourceId,
    this.sourceMode,
    this.sourceData,
    required this.publishedAt,
    this.editHistory = const [],
    this.pollData,
    this.articleData,
    this.visibility = PostVisibility.public,
    this.adData,
    this.location,
    this.linkPreview,
    this.storyData,
    this.reelAudio,
    this.reelEffects = const ReelEffects(),
  });

  PostModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? displayName,
    String? profileUrl,
    PostType? postType,
    String? caption,
    PostMediaList? media,
    int? likesCount,
    Map<String, dynamic>? reactionsCountRaw,
    int? commentsCount,
    int? viewsCount,
    bool? hasReacted,
    String? userReaction,
    bool? hasSaved,
    String? sourceType,
    String? sourceId,
    String? sourceMode,
    Map<String, dynamic>? sourceData,
    DateTime? publishedAt,
    List<dynamic>? editHistory,
    PollData? pollData,
    ArticleData? articleData,
    PostVisibility? visibility,
    AdData? adData,
    PostLocation? location,
    LinkPreview? linkPreview,
    StoryData? storyData,
    ReelAudioData? reelAudio,
    ReelEffects? reelEffects,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      profileUrl: profileUrl ?? this.profileUrl,
      postType: postType ?? this.postType,
      caption: caption ?? this.caption,
      media: media ?? this.media,
      likesCount: likesCount ?? this.likesCount,
      reactionsCountRaw: reactionsCountRaw ?? this.reactionsCountRaw,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      hasReacted: hasReacted ?? this.hasReacted,
      userReaction: userReaction ?? this.userReaction,
      hasSaved: hasSaved ?? this.hasSaved,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      sourceMode: sourceMode ?? this.sourceMode,
      sourceData: sourceData ?? this.sourceData,
      publishedAt: publishedAt ?? this.publishedAt,
      editHistory: editHistory ?? this.editHistory,
      pollData: pollData ?? this.pollData,
      articleData: articleData ?? this.articleData,
      visibility: visibility ?? this.visibility,
      adData: adData ?? this.adData,
      location: location ?? this.location,
      linkPreview: linkPreview ?? this.linkPreview,
      storyData: storyData ?? this.storyData,
      reelAudio: reelAudio ?? this.reelAudio,
      reelEffects: reelEffects ?? this.reelEffects,
    );
  }

  static bool _asBool(dynamic val, [bool defaultValue = false]) {
    if (val == null) return defaultValue;
    if (val is bool) return val;
    if (val is int) return val == 1;
    return defaultValue;
  }


  factory PostModel.fromJson(Map<String, dynamic> json) {
    final reactions = _parseJsonMap(json['reactions_count']) ?? {};
    final pollMap = _parseJsonMap(json['poll_data']);
    final articleMap = _parseJsonMap(json['article_data']);
    final adDataMap = _parseJsonMap(json['ad_data']);
    final locationMap = _parseJsonMap(json['location_data'] ?? json['location']);
    final linkMap = _parseJsonMap(json['link_preview']);
    final storyMap = _parseJsonMap(json['story_data']);
    final audioMap = _parseJsonMap(json['reel_audio']);

    return PostModel(
      id: json['id'] ?? json['post_id'] ?? '',
      userId: json['user_id'] ?? '',
      username: json['username'] ?? json['user_profiles']?['username'],
      displayName: json['display_name'] ?? json['user_profiles']?['display_name'],
      profileUrl: json['profile_url'] ?? json['user_profiles']?['profile_url'],
      postType: _parsePostType(json['post_type'], json['source_type']),
      caption: json['caption'] ?? json['content_text'],
      media: PostMediaList.fromJson(json['media']),
      likesCount: reactions['total'] ?? json['likes_count'] ?? 0,
      reactionsCountRaw: reactions,
      commentsCount: json['comments_count'] ?? 0,
      viewsCount: json['views_count'] ?? 0,
      hasReacted: _asBool(json['has_reacted']),
      userReaction: json['user_reaction'],
      hasSaved: _asBool(json['has_saved']),
      sourceType: json['source_type'],
      sourceId: json['source_id'],
      sourceMode: json['source_mode'],
      sourceData: _parseJsonMap(json['source_snapshot']),
      publishedAt: _parseDateTime(json['published_at']),
      editHistory: _parseJsonList(json['edit_history']),
      pollData: pollMap != null ? PollData.fromJson(pollMap) : null,
      articleData: articleMap != null ? ArticleData.fromJson(articleMap) : null,
      visibility: _parseVisibility(json['visibility']),
      adData: adDataMap != null ? AdData.fromJson(adDataMap) : null,
      location: locationMap != null ? PostLocation.fromJson(locationMap) : null,
      linkPreview: linkMap != null ? LinkPreview.fromJson(linkMap) : null,
      storyData: storyMap != null ? StoryData.fromJson(storyMap) : null,
      reelAudio: audioMap != null ? ReelAudioData.fromJson(audioMap) : null,
      reelEffects: ReelEffects.fromJson(_parseJsonbRaw(json['reel_effects'])),
    );
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val;
    String s = val.toString();
    if (s.isEmpty) return DateTime.now();

    // Handle space between date and time (standard in some DBs)
    if (s.contains(' ') && !s.contains('T')) {
      s = s.replaceFirst(' ', 'T');
    }

    // Ensure it's treated as UTC if no offset exists (standard for our DB)
    if (!s.contains('Z') && !s.contains('+') && !s.contains('-')) {
      s += 'Z';
    }
    return DateTime.tryParse(s)?.toLocal() ?? DateTime.now();
  }

  static PostType _parsePostType(dynamic type, [dynamic sourceType]) {
    if (type == null) return PostType.text;
    final t = type.toString().toLowerCase();
    final st = sourceType?.toString().toLowerCase();
    
    // Mapping for consolidated types (Backend only allows text, image, video, poll)
    if (t == 'post' || t == 'repost' || t == 'shared' || t == 'article') return PostType.text;
    
    // If it's a generic backend type but has a specific source, use source for granularity
    if ((t == 'text' || t == 'image') && st != null && st != 'post' && st != 'text' && st != 'shared') {
      return PostType.values.firstWhere(
        (e) => e.name.toLowerCase() == st, 
        orElse: () => t == 'image' ? PostType.image : PostType.text
      );
    }

    if (t == 'reel' || t == 'story' || t == 'video') return PostType.video;
    
    return PostType.values.firstWhere(
      (e) => e.name.toLowerCase() == t, 
      orElse: () => PostType.text
    );
  }

  static PostVisibility _parseVisibility(dynamic val) {
    if (val == null) return PostVisibility.public;
    final s = val.toString().toLowerCase();
    return PostVisibility.values.firstWhere((e) => e.name == s, orElse: () => PostVisibility.public);
  }

  // UI Helpers
  String get timeAgo {
    final duration = DateTime.now().difference(publishedAt);
    if (duration.inMinutes < 1) return 'now';
    if (duration.inHours < 1) return '${duration.inMinutes}m';
    if (duration.inDays < 1) return '${duration.inHours}h';
    return '${duration.inDays}d';
  }

  bool get hasMedia => media.isNotEmpty;
  bool get hasVideo => media.any((m) => m.isVideo);
  bool get isReel => postType == PostType.reel || (media.isNotEmpty && media.first.type == 'reel');
  bool get isStory => postType == PostType.story || (media.isNotEmpty && media.first.type == 'story');
  bool get isShared => sourceType != null;
  String? get firstImageUrl => media.isNotEmpty ? media.first.url : null;
  bool get isLive => sourceMode == 'live';
  PostMetrics get metrics => PostMetrics(
    views: viewsCount,
    likesCount: likesCount,
    savesCount: hasSaved ? 1 : 0,
    impressions: viewsCount,
    commentsCount: commentsCount,
    sharesCount: 0,
  );
  PostReactionsCount get reactionsCount => PostReactionsCount(total: likesCount);
  Content get content => Content(text: caption ?? '', media: media);
  bool get isEdited => editHistory.isNotEmpty;
  bool get isSponsored => adData != null;
  int get savesCount => hasSaved ? 1 : 0;
  int get sharesCount => 0;
  DateTime get createdAt => publishedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'username': username,
    'display_name': displayName,
    'profile_url': profileUrl,
    'post_type': postType.name,
    'caption': caption,
    'media': media.toJson(),
    'reactions_count': reactionsCountRaw,
    'comments_count': commentsCount,
    'views_count': viewsCount,
    'has_reacted': hasReacted,
    'user_reaction': userReaction,
    'has_saved': hasSaved,
    'source_type': sourceType,
    'source_id': sourceId,
    'source_mode': sourceMode,
    'source_snapshot': sourceData,
    'published_at': publishedAt.toIso8601String(),
    'edit_history': {'items': editHistory},
    'poll_data': pollData?.toJson(),
    'article_data': articleData?.toJson(),
    'visibility': visibility.name,
    'ad_data': adData != null ? {'id': adData!.id, 'title': adData!.title} : null, // Simplified for now
    'location': location?.toJson(),
    'link_preview': linkPreview?.toJson(),
    'story_data': storyData?.toJson(),
    'reel_effects': reelEffects.toJson(),
  };
}

enum PostType { text, image, video, poll, advertisement, day_task, long_goal, week_task, bucket, reel, story, post, shared }
enum ContentType { text, image, video, poll, day_task, long_goal, week_task, bucket, reel, vlog, link, carousel, advertisement }
enum PostVisibility { public, followers, following, private }
enum PostStatus { draft, published, scheduled, archived }

extension PostTypeExtension on PostType { String get name => toString().split('.').last; }
extension ContentTypeExtension on ContentType {
  String get name => toString().split('.').last;
  String toLowerCase() => name.toLowerCase();
  String toUpperCase() => name.toUpperCase();
}

class PostMediaList {
  final List<PostMedia> items;

  const PostMediaList({this.items = const []});

  factory PostMediaList.fromJson(dynamic json) {
    final v = _parseJsonbRaw(json);
    if (v == null) return const PostMediaList();
    if (v is List) {
      return PostMediaList(
        items: v.map((e) => PostMedia.fromJson(e)).toList(),
      );
    }
    if (v is Map<String, dynamic>) {
      final items = v['items'] ?? v['media_items'] ?? v['media'];
      if (items is List) {
        return PostMediaList(
          items: items.map((e) => PostMedia.fromJson(e)).toList(),
        );
      }
    }
    return const PostMediaList();
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((e) => e.toJson()).toList(),
  };

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get length => items.length;
  PostMedia get first => items.first;
  bool any(bool Function(PostMedia) test) => items.any(test);
  Iterable<T> map<T>(T Function(PostMedia) f) => items.map(f);
  T firstWhere<T extends PostMedia>(bool Function(PostMedia) test, {PostMedia Function()? orElse}) {
    return items.firstWhere(test, orElse: orElse) as T;
  }
}

class PostMedia {
  final String url;
  final String type;
  final String? thumbnail;
  final String id;

  PostMedia({required this.url, required this.type, this.id = '', this.thumbnail});

  factory PostMedia.fromJson(dynamic v) {
    final json = _parseJsonMap(v) ?? {};
    if (json.isEmpty && v is String) {
       return PostMedia(url: v, type: 'image');
    }
    return PostMedia(
      url: json['url']?.toString() ?? '',
      type: json['type']?.toString() ?? 'image',
      id: json['id']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString(),
    );
  }

  bool get isVideo => type == 'video' || type == 'reel';
  ContentType get contentType => isVideo ? ContentType.video : ContentType.image;

  Map<String, dynamic> toJson() => {'url': url, 'type': type, 'id': id, 'thumbnail': thumbnail};
}

class PollData {
  final String question;
  final List<PollOption> options;
  final List<String> voters;
  final DateTime? endsAt;

  PollData({
    required this.question,
    required this.options,
    this.voters = const [],
    this.endsAt,
  });

  factory PollData.fromJson(Map<String, dynamic> json) {
    return PollData(
      question: json['question'] ?? '',
      options: _parseJsonbList(
        json['options'],
        (e) => PollOption.fromJson(e),
      ),
      voters: _parseJsonbStringList(json['voters']),
      endsAt: json['ends_at'] != null || json['endsAt'] != null
          ? DateTime.tryParse(json['ends_at'] ?? json['endsAt'])
          : null,
    );
  }

  int get totalVotes => options.fold(0, (sum, o) => sum + o.votes);

  bool get isEnded => endsAt != null && endsAt!.isBefore(DateTime.now());

  bool hasUserVoted(String userId) => voters.contains(userId);

  String? getUserVote(String userId) {
    for (final option in options) {
      if (option.voters.contains(userId)) return option.id;
    }
    return null;
  }

  double getOptionPercent(String optionId) {
    if (totalVotes == 0) return 0.0;
    final option = options.firstWhere((o) => o.id == optionId,
        orElse: () => PollOption(id: '', text: ''));
    return (option.votes / totalVotes) * 100;
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': {'items': options.map((e) => e.toJson()).toList()},
        'voters': {'items': voters},
        'ends_at': endsAt?.toIso8601String(),
      };
}

class PollOption {
  final String id;
  final String text;
  final int votes;
  final List<String> voters;

  PollOption({
    required this.id,
    required this.text,
    this.votes = 0,
    this.voters = const [],
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    final votersList = _parseJsonbStringList(json['voters']);
    return PollOption(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      votes: json['votes'] ?? votersList.length,
      voters: votersList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'votes': votes,
        'voters': {'items': voters},
      };
}

class ArticleData {
  final String title;
  final String content;
  final String? coverImage;
  final String? category;
  final String? author;
  final int? readTime;

  ArticleData({required this.title, required this.content, this.coverImage, this.category, this.author, this.readTime});

  factory ArticleData.fromJson(Map<String, dynamic> json) => ArticleData(
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    coverImage: json['coverImage'] ?? json['cover_image'],
    category: json['category'],
    author: json['author'],
    readTime: json['readTime'] ?? json['read_time'],
  );
  Map<String, dynamic> toJson() => {'title': title, 'content': content, 'coverImage': coverImage, 'category': category, 'author': author, 'readTime': readTime};
}

class AdData {
  final String id;
  final String title;
  final String? advertiserName;
  final String? ctaText;
  final String? ctaType;
  final String? ctaUrl;
  final bool hasCta;

  AdData({required this.id, required this.title, this.advertiserName, this.ctaText, this.ctaType, this.ctaUrl, this.hasCta = true});

  factory AdData.fromJson(Map<String, dynamic> json) => AdData(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    advertiserName: json['advertiser_name'] ?? json['advertiserName'],
    ctaText: json['cta_text'] ?? json['ctaText'],
    ctaType: json['cta_type'] ?? json['ctaType'],
    ctaUrl: json['cta_url'] ?? json['ctaUrl'],
    hasCta: json['hasCta'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'advertiser_name': advertiserName,
    'cta_text': ctaText,
    'cta_type': ctaType,
    'cta_url': ctaUrl,
    'hasCta': hasCta,
  };
}

class PostLocation {
  final double latitude;
  final double longitude;
  final String? name;
  bool get hasName => name != null && name!.isNotEmpty;

  PostLocation({required this.latitude, required this.longitude, this.name});
  factory PostLocation.fromJson(Map<String, dynamic> json) => PostLocation(
    latitude: (json['latitude'] ?? json['lat'] ?? 0.0).toDouble(),
    longitude: (json['longitude'] ?? json['lng'] ?? 0.0).toDouble(),
    name: json['name'],
  );
  Map<String, dynamic> toJson() => {'latitude': latitude, 'longitude': longitude, 'name': name};
}

class LinkPreview {
  final String url;
  final String? title;
  final String? image;
  LinkPreview({required this.url, this.title, this.image});
  factory LinkPreview.fromJson(Map<String, dynamic> json) => LinkPreview(url: json['url'] ?? '', title: json['title'], image: json['image']);
  Map<String, dynamic> toJson() => {'url': url, 'title': title, 'image': image};
}

class StoryData {
  final int duration;
  StoryData({this.duration = 5});
  factory StoryData.fromJson(Map<String, dynamic> json) => StoryData(duration: json['duration'] ?? 5);
  Map<String, dynamic> toJson() => {'duration': duration};
}

class ReelAudioData {
  final String title;
  ReelAudioData({required this.title});
  factory ReelAudioData.fromJson(Map<String, dynamic> json) => ReelAudioData(title: json['title'] ?? '');
  Map<String, dynamic> toJson() => {'title': title};
}

class ReelEffects {
  final List<ReelEffect> items;

  const ReelEffects({this.items = const []});

  factory ReelEffects.fromJson(dynamic json) {
    if (json == null) return const ReelEffects();
    if (json is List) {
      return ReelEffects(items: json.map((e) => ReelEffect.fromJson(e)).toList());
    }
    if (json is Map<String, dynamic>) {
      return ReelEffects(
        items: (json['items'] as List? ?? [])
            .map((e) => ReelEffect.fromJson(e))
            .toList(),
      );
    }
    return const ReelEffects();
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((e) => e.toJson()).toList(),
  };

  bool get isEmpty => items.isEmpty;
  int get length => items.length;
  Iterable<T> map<T>(T Function(ReelEffect) f) => items.map(f);
}

class ReelEffect {
  final String name;
  ReelEffect({required this.name});
  factory ReelEffect.fromJson(Map<String, dynamic> json) => ReelEffect(name: json['name'] ?? '');
  Map<String, dynamic> toJson() => {'name': name};
}

class PostMetrics {
  final int views;
  final int likesCount;
  final int savesCount;
  final int impressions;
  final int commentsCount;
  final int sharesCount;
  PostMetrics({required this.views, required this.likesCount, required this.savesCount, required this.impressions, this.commentsCount = 0, this.sharesCount = 0});
}

class PostReactionsCount {
  final int total;
  PostReactionsCount({required this.total});
}

class Content {
  final String text;
  final PostMediaList media;
  Content({required this.text, required this.media});
}

class FeedPost {
  final PostModel post;
  final String? username;
  final String? displayName;
  final String? profileUrl;
  bool get hasReacted => post.hasReacted;
  String? get userReaction => post.userReaction;

  FeedPost({required this.post, this.username, this.displayName, this.profileUrl});

  FeedPost copyWith({PostModel? post, String? username, String? displayName, String? profileUrl}) => FeedPost(
    post: post ?? this.post,
    username: username ?? this.username,
    displayName: displayName ?? this.displayName,
    profileUrl: profileUrl ?? this.profileUrl,
  );

  String get id => post.id;
}

class ExplorePost {
  final PostModel post;
  ExplorePost({required this.post});
  factory ExplorePost.fromJson(Map<String, dynamic> json) => ExplorePost(post: PostModel.fromJson(json));
}

class StoryGroup {
  final String userId;
  final List<PostModel> stories;
  StoryGroup({required this.userId, required this.stories});
}
// ================================================================
// HELPER FUNCTIONS
// ================================================================

Map<String, dynamic>? _parseJsonMap(dynamic val) {
  if (val == null) return null;
  if (val is Map) return Map<String, dynamic>.from(val);
  if (val is String && val.isNotEmpty) {
    try {
      return Map<String, dynamic>.from(jsonDecode(val));
    } catch (_) {}
  }
  return null;
}

List<dynamic> _parseJsonList(dynamic val) {
  if (val == null) return [];
  if (val is List) return val;
  if (val is Map<String, dynamic> && val['items'] != null) {
    return val['items'] as List<dynamic>;
  }
  if (val is String && val.isNotEmpty) {
    try {
      final decoded = jsonDecode(val);
      if (decoded is List) return decoded;
      if (decoded is Map<String, dynamic> && decoded['items'] != null) {
        return decoded['items'] as List<dynamic>;
      }
    } catch (_) {}
  }
  return [];
}

dynamic _parseJsonbRaw(dynamic v) {
  if (v == null) return null;
  if (v is Map || v is List) return v;
  if (v is String && v.isNotEmpty) {
    try {
      return jsonDecode(v);
    } catch (_) {}
  }
  return v;
}

List<T> _parseJsonbList<T>(
  dynamic json,
  T Function(Map<String, dynamic>) fromJson,
) {
  final v = _parseJsonbRaw(json);
  if (v == null) return [];
  if (v is List) {
    return v
        .whereType<Map<String, dynamic>>()
        .map((e) => fromJson(e))
        .toList();
  }
  if (v is Map<String, dynamic> && v['items'] != null) {
    final items = v['items'] as List;
    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => fromJson(e))
        .toList();
  }
  return [];
}

List<String> _parseJsonbStringList(dynamic json) {
  final v = _parseJsonbRaw(json);
  if (v == null) return [];
  if (v is List) {
    return List<String>.from(v.map((e) => e.toString()));
  }
  if (v is Map<String, dynamic> && v['items'] != null) {
    return List<String>.from((v['items'] as List).map((e) => e.toString()));
  }
  return [];
}
