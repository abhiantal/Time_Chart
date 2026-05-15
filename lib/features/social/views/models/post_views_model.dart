// ============================================================
// 📁 models/social/post_view_model.dart
// Complete Post View/Analytics Model - View tracking + ad clicks
// No external packages — pure Dart
// ============================================================

/// ════════════════════════════════════════════════════════════
/// VIEW SOURCE ENUM
/// ════════════════════════════════════════════════════════════

enum ViewSource {
  feed,
  profile,
  explore,
  search,
  hashtag,
  share,
  direct,
  ad,
  story,
  reel;

  static ViewSource fromString(String? value) {
    return ViewSource.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ViewSource.feed,
    );
  }

  static ViewSource? tryFromString(String? value) {
    if (value == null) return null;
    try {
      return ViewSource.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return null;
    }
  }

  String get label {
    switch (this) {
      case ViewSource.feed:
        return 'Home Feed';
      case ViewSource.profile:
        return 'Profile';
      case ViewSource.explore:
        return 'Explore';
      case ViewSource.search:
        return 'Search';
      case ViewSource.hashtag:
        return 'Hashtag';
      case ViewSource.share:
        return 'Shared Link';
      case ViewSource.direct:
        return 'Direct URL';
      case ViewSource.ad:
        return 'Ad Placement';
      case ViewSource.story:
        return 'Story';
      case ViewSource.reel:
        return 'Reels Feed';
    }
  }

  String get emoji {
    switch (this) {
      case ViewSource.feed:
        return '🏠';
      case ViewSource.profile:
        return '👤';
      case ViewSource.explore:
        return '🔍';
      case ViewSource.search:
        return '🔎';
      case ViewSource.hashtag:
        return '#️⃣';
      case ViewSource.share:
        return '🔗';
      case ViewSource.direct:
        return '🔗';
      case ViewSource.ad:
        return '📢';
      case ViewSource.story:
        return '📸';
      case ViewSource.reel:
        return '🎬';
    }
  }

  /// Color hex for charts
  String get colorHex {
    switch (this) {
      case ViewSource.feed:
        return '#2196F3';
      case ViewSource.profile:
        return '#4CAF50';
      case ViewSource.explore:
        return '#FF9800';
      case ViewSource.search:
        return '#9C27B0';
      case ViewSource.hashtag:
        return '#00BCD4';
      case ViewSource.share:
        return '#E91E63';
      case ViewSource.direct:
        return '#607D8B';
      case ViewSource.ad:
        return '#F44336';
      case ViewSource.story:
        return '#FF5722';
      case ViewSource.reel:
        return '#673AB7';
    }
  }
}

/// ════════════════════════════════════════════════════════════
/// DEVICE TYPE ENUM
/// ════════════════════════════════════════════════════════════

enum DeviceType {
  mobile,
  tablet,
  desktop;

  static DeviceType? fromString(String? value) {
    if (value == null) return null;
    try {
      return DeviceType.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return DeviceType.mobile;
    }
  }

  String get label {
    switch (this) {
      case DeviceType.mobile:
        return 'Mobile';
      case DeviceType.tablet:
        return 'Tablet';
      case DeviceType.desktop:
        return 'Desktop';
    }
  }

  String get emoji {
    switch (this) {
      case DeviceType.mobile:
        return '📱';
      case DeviceType.tablet:
        return '📲';
      case DeviceType.desktop:
        return '💻';
    }
  }

  String get colorHex {
    switch (this) {
      case DeviceType.mobile:
        return '#2196F3';
      case DeviceType.tablet:
        return '#4CAF50';
      case DeviceType.desktop:
        return '#FF9800';
    }
  }
}

/// ════════════════════════════════════════════════════════════
/// PLATFORM ENUM
/// ════════════════════════════════════════════════════════════

enum ViewPlatform {
  ios,
  android,
  web;

  static ViewPlatform? fromString(String? value) {
    if (value == null) return null;
    try {
      return ViewPlatform.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return ViewPlatform.android;
    }
  }

  String get label {
    switch (this) {
      case ViewPlatform.ios:
        return 'iOS';
      case ViewPlatform.android:
        return 'Android';
      case ViewPlatform.web:
        return 'Web';
    }
  }

  String get emoji {
    switch (this) {
      case ViewPlatform.ios:
        return '🍎';
      case ViewPlatform.android:
        return '🤖';
      case ViewPlatform.web:
        return '🌐';
    }
  }

  String get colorHex {
    switch (this) {
      case ViewPlatform.ios:
        return '#007AFF';
      case ViewPlatform.android:
        return '#3DDC84';
      case ViewPlatform.web:
        return '#FF9800';
    }
  }
}

/// ════════════════════════════════════════════════════════════
/// VIEW RECORD ACTION ENUM
/// ════════════════════════════════════════════════════════════

enum ViewRecordAction {
  recorded,
  updated,
  skippedOwnPost;

  static ViewRecordAction fromString(String? value) {
    switch (value) {
      case 'recorded':
        return ViewRecordAction.recorded;
      case 'updated':
        return ViewRecordAction.updated;
      case 'skipped_own_post':
        return ViewRecordAction.skippedOwnPost;
      default:
        return ViewRecordAction.recorded;
    }
  }

  bool get isNew => this == ViewRecordAction.recorded;
  bool get isUpdate => this == ViewRecordAction.updated;
  bool get isSkipped => this == ViewRecordAction.skippedOwnPost;
}

/// ════════════════════════════════════════════════════════════
/// 🎯 MAIN POST VIEW MODEL
/// ════════════════════════════════════════════════════════════

class PostViewModel {
  final String id;
  final String postId;
  final String? userId;
  final DateTime viewDate;
  final ViewSource? viewSource;
  final int? viewDurationSeconds;
  final int? viewPercent;
  final bool? completed;
  final bool clickedCta;
  final DeviceType? deviceType;
  final ViewPlatform? platform;
  final DateTime createdAt;

  const PostViewModel({
    required this.id,
    required this.postId,
    this.userId,
    required this.viewDate,
    this.viewSource,
    this.viewDurationSeconds,
    this.viewPercent,
    this.completed,
    this.clickedCta = false,
    this.deviceType,
    this.platform,
    required this.createdAt,
  });

  // ════════════════════════════════════════════════════════════
  // FROM JSON
  // ════════════════════════════════════════════════════════════

  factory PostViewModel.fromJson(Map<String, dynamic> json) {
    return PostViewModel(
      id: json['id'] as String? ?? '',
      postId: json['post_id'] as String? ?? '',
      userId: json['user_id'] as String?,
      viewDate:
          DateTime.tryParse(json['view_date'] as String? ?? '') ??
          DateTime.now(),
      viewSource: ViewSource.tryFromString(json['view_source'] as String?),
      viewDurationSeconds: json['view_duration_seconds'] as int?,
      viewPercent: json['view_percent'] as int?,
      completed: json['completed'] as bool?,
      clickedCta: json['clicked_cta'] as bool? ?? false,
      deviceType: DeviceType.fromString(json['device_type'] as String?),
      platform: ViewPlatform.fromString(json['platform'] as String?),
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
      'post_id': postId,
      if (userId != null) 'user_id': userId,
      'view_date': _formatDate(viewDate),
      if (viewSource != null) 'view_source': viewSource!.name,
      if (viewDurationSeconds != null)
        'view_duration_seconds': viewDurationSeconds,
      if (viewPercent != null) 'view_percent': viewPercent,
      if (completed != null) 'completed': completed,
      'clicked_cta': clickedCta,
      if (deviceType != null) 'device_type': deviceType!.name,
      if (platform != null) 'platform': platform!.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ════════════════════════════════════════════════════════════
  // COMPUTED
  // ════════════════════════════════════════════════════════════

  /// Is this an anonymous view?
  bool get isAnonymous => userId == null;

  /// Is this an authenticated view?
  bool get isAuthenticated => userId != null;

  /// Was the video completed?
  bool get isCompleted => completed == true;

  /// Did user click the ad CTA?
  bool get hasClickedCta => clickedCta;

  /// Has view duration data?
  bool get hasDuration => viewDurationSeconds != null;

  /// Has view percent data?
  bool get hasPercent => viewPercent != null;

  /// Formatted duration "1m 30s"
  String get formattedDuration {
    if (viewDurationSeconds == null) return '—';
    final mins = viewDurationSeconds! ~/ 60;
    final secs = viewDurationSeconds! % 60;
    if (mins == 0) return '${secs}s';
    if (secs == 0) return '${mins}m';
    return '${mins}m ${secs}s';
  }

  /// Formatted view percent "75%"
  String get formattedPercent {
    if (viewPercent == null) return '—';
    return '$viewPercent%';
  }

  /// Formatted view date
  String get formattedViewDate {
    return _formatDate(viewDate);
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ════════════════════════════════════════════════════════════
  // COPY WITH
  // ════════════════════════════════════════════════════════════

  PostViewModel copyWith({
    String? id,
    String? postId,
    String? userId,
    DateTime? viewDate,
    ViewSource? viewSource,
    int? viewDurationSeconds,
    int? viewPercent,
    bool? completed,
    bool? clickedCta,
    DeviceType? deviceType,
    ViewPlatform? platform,
    DateTime? createdAt,
  }) {
    return PostViewModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      viewDate: viewDate ?? this.viewDate,
      viewSource: viewSource ?? this.viewSource,
      viewDurationSeconds: viewDurationSeconds ?? this.viewDurationSeconds,
      viewPercent: viewPercent ?? this.viewPercent,
      completed: completed ?? this.completed,
      clickedCta: clickedCta ?? this.clickedCta,
      deviceType: deviceType ?? this.deviceType,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ════════════════════════════════════════════════════════════
  // EMPTY
  // ════════════════════════════════════════════════════════════

  static PostViewModel empty() {
    return PostViewModel(
      id: '',
      postId: '',
      viewDate: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  // ════════════════════════════════════════════════════════════
  // EQUALITY
  // ════════════════════════════════════════════════════════════

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PostViewModel && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PostViewModel(id: $id, post: $postId, source: ${viewSource?.name}, duration: $formattedDuration)';
}

/// ════════════════════════════════════════════════════════════
/// RECORD VIEW RESULT
/// (Response from record_view() Supabase function)
/// ════════════════════════════════════════════════════════════

class RecordViewResult {
  final bool success;
  final String? viewId;
  final bool isNewView;
  final ViewRecordAction action;

  const RecordViewResult({
    required this.success,
    this.viewId,
    this.isNewView = true,
    this.action = ViewRecordAction.recorded,
  });

  factory RecordViewResult.fromJson(Map<String, dynamic> json) {
    return RecordViewResult(
      success: json['success'] as bool? ?? false,
      viewId: json['view_id'] as String?,
      isNewView: json['is_new_view'] as bool? ?? true,
      action: ViewRecordAction.fromString(json['action'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (viewId != null) 'view_id': viewId,
      'is_new_view': isNewView,
      'action': action.name,
    };
  }

  @override
  String toString() =>
      'RecordViewResult(success: $success, new: $isNewView, action: ${action.name})';
}

/// ════════════════════════════════════════════════════════════
/// RECORD AD CLICK RESULT
/// (Response from record_ad_click())
/// ════════════════════════════════════════════════════════════

class RecordAdClickResult {
  final bool success;
  final String postId;
  final int totalClicks;

  const RecordAdClickResult({
    required this.success,
    required this.postId,
    this.totalClicks = 0,
  });

  factory RecordAdClickResult.fromJson(Map<String, dynamic> json) {
    return RecordAdClickResult(
      success: json['success'] as bool? ?? false,
      postId: json['post_id'] as String? ?? '',
      totalClicks: json['total_clicks'] as int? ?? 0,
    );
  }

  @override
  String toString() =>
      'RecordAdClickResult(post: $postId, clicks: $totalClicks)';
}

/// ════════════════════════════════════════════════════════════
/// VIEW PROGRESS RESULT
/// (Response from update_view_progress())
/// ════════════════════════════════════════════════════════════

class ViewProgressResult {
  final bool success;
  final String postId;
  final int duration;
  final int percent;
  final bool completed;

  const ViewProgressResult({
    required this.success,
    required this.postId,
    this.duration = 0,
    this.percent = 0,
    this.completed = false,
  });

  factory ViewProgressResult.fromJson(Map<String, dynamic> json) {
    return ViewProgressResult(
      success: json['success'] as bool? ?? false,
      postId: json['post_id'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      percent: json['percent'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'ViewProgressResult(post: $postId, ${percent}%, completed: $completed)';
}

/// ════════════════════════════════════════════════════════════
/// DAILY VIEW DATA (for analytics chart)
/// ════════════════════════════════════════════════════════════

class DailyViewData {
  final DateTime date;
  final int views;
  final int uniqueViews;

  const DailyViewData({
    required this.date,
    this.views = 0,
    this.uniqueViews = 0,
  });

  factory DailyViewData.fromJson(Map<String, dynamic> json) {
    return DailyViewData(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      views: json['views'] as int? ?? 0,
      uniqueViews: json['unique_views'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': PostViewModel._formatDate(date),
      'views': views,
      'unique_views': uniqueViews,
    };
  }

  // ──── COMPUTED ────

  /// Formatted date "Jan 15"
  String get formattedDate {
    const months = [
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
    // Check if month index is valid
    if (date.month < 1 || date.month > 12) return '';
    return '${months[date.month]} ${date.day}';
  }

  /// Short date "1/15"
  String get shortDate => '${date.month}/${date.day}';

  /// Day of week "Mon"
  String get dayOfWeek {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // date.weekday is 1-7 (Mon-Sun)
    if (date.weekday < 1 || date.weekday > 7) return '';
    return days[date.weekday - 1];
  }

  /// Repeat view ratio
  double get repeatRatio {
    if (uniqueViews == 0) return 0.0;
    return views / uniqueViews;
  }

  @override
  String toString() =>
      'DailyViewData(${formattedDate}: $views views, $uniqueViews unique)';
}

/// ════════════════════════════════════════════════════════════
/// SOURCE BREAKDOWN (views by source)
/// ════════════════════════════════════════════════════════════

class SourceBreakdownItem {
  final ViewSource source;
  final int count;
  final double percentage;

  const SourceBreakdownItem({
    required this.source,
    required this.count,
    this.percentage = 0.0,
  });

  String get label => source.label;
  String get emoji => source.emoji;
  String get colorHex => source.colorHex;

  String get formattedCount {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  String get formattedPercentage => '${percentage.toStringAsFixed(1)}%';

  @override
  String toString() =>
      'SourceBreakdown(${source.name}: $count ($formattedPercentage))';
}

/// ════════════════════════════════════════════════════════════
/// DEVICE BREAKDOWN (views by device)
/// ════════════════════════════════════════════════════════════

class DeviceBreakdownItem {
  final DeviceType device;
  final int count;
  final double percentage;

  const DeviceBreakdownItem({
    required this.device,
    required this.count,
    this.percentage = 0.0,
  });

  String get label => device.label;
  String get emoji => device.emoji;
  String get colorHex => device.colorHex;

  String get formattedCount {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  String get formattedPercentage => '${percentage.toStringAsFixed(1)}%';

  @override
  String toString() =>
      'DeviceBreakdown(${device.name}: $count ($formattedPercentage))';
}

/// ════════════════════════════════════════════════════════════
/// VIDEO ENGAGEMENT DATA
/// ════════════════════════════════════════════════════════════

class VideoEngagement {
  final double avgWatchTime;
  final double avgCompletion;
  final int completedCount;
  final double completionRate;

  const VideoEngagement({
    this.avgWatchTime = 0.0,
    this.avgCompletion = 0.0,
    this.completedCount = 0,
    this.completionRate = 0.0,
  });

  factory VideoEngagement.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const VideoEngagement();
    return VideoEngagement(
      avgWatchTime: (json['avg_watch_time'] as num?)?.toDouble() ?? 0.0,
      avgCompletion: (json['avg_completion'] as num?)?.toDouble() ?? 0.0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avg_watch_time': avgWatchTime,
      'avg_completion': avgCompletion,
      'completed_count': completedCount,
      'completion_rate': completionRate,
    };
  }

  // ──── COMPUTED ────

  bool get hasData => avgWatchTime > 0 || completedCount > 0;

  /// Formatted average watch time "1m 30s"
  String get formattedAvgWatchTime {
    final totalSeconds = avgWatchTime.round();
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    if (mins == 0) return '${secs}s';
    if (secs == 0) return '${mins}m';
    return '${mins}m ${secs}s';
  }

  /// Formatted completion "75%"
  String get formattedAvgCompletion => '${avgCompletion.toStringAsFixed(1)}%';

  /// Formatted completion rate "45.5%"
  String get formattedCompletionRate => '${completionRate.toStringAsFixed(1)}%';

  /// Watch time quality label
  String get watchTimeQuality {
    if (avgWatchTime >= 30) return 'Excellent';
    if (avgWatchTime >= 15) return 'Good';
    if (avgWatchTime >= 5) return 'Average';
    return 'Low';
  }

  /// Completion quality label
  String get completionQuality {
    if (completionRate >= 70) return 'Excellent';
    if (completionRate >= 40) return 'Good';
    if (completionRate >= 20) return 'Average';
    return 'Low';
  }

  @override
  String toString() =>
      'VideoEngagement(avgWatch: $formattedAvgWatchTime, completion: $formattedCompletionRate)';
}

/// ════════════════════════════════════════════════════════════
/// 🎯 POST ANALYTICS (from get_post_analytics())
/// ════════════════════════════════════════════════════════════

class PostAnalytics {
  // ──── CORE METRICS ────
  final String postId;
  final int totalViews;
  final int uniqueViews;
  final int reactionsTotal;
  final int commentsCount;
  final int repostsCount;
  final int savesCount;
  final int sharesCount;
  final double engagementRate;

  // ──── BREAKDOWNS ────
  final List<DailyViewData> dailyViews;
  final List<SourceBreakdownItem> sourceBreakdown;
  final List<DeviceBreakdownItem> deviceBreakdown;

  // ──── VIDEO ENGAGEMENT ────
  final VideoEngagement videoEngagement;

  // ──── AD METRICS (if sponsored) ────
  final Map<String, dynamic>? adMetrics;
  final int ctaClicks;
  final double ctr;

  const PostAnalytics({
    required this.postId,
    this.totalViews = 0,
    this.uniqueViews = 0,
    this.reactionsTotal = 0,
    this.commentsCount = 0,
    this.repostsCount = 0,
    this.savesCount = 0,
    this.sharesCount = 0,
    this.engagementRate = 0.0,
    this.dailyViews = const [],
    this.sourceBreakdown = const [],
    this.deviceBreakdown = const [],
    this.videoEngagement = const VideoEngagement(),
    this.adMetrics,
    this.ctaClicks = 0,
    this.ctr = 0.0,
  });

  factory PostAnalytics.fromJson(Map<String, dynamic> json) {
    // Parse breakdowns
    // Safely handle cases where Supabase JSON might return a Map instead of List
    dynamic dailyViewsData = json['daily_views'];
    final dailyList =
        (dailyViewsData is List
                ? dailyViewsData
                : (dailyViewsData is Map ? dailyViewsData.values.toList() : []))
            .map((e) => DailyViewData.fromJson(e as Map<String, dynamic>))
            .toList();

    dynamic sourceData = json['source_breakdown'];
    final sourceList =
        (sourceData is List
                ? sourceData
                : (sourceData is Map ? sourceData.values.toList() : []))
            .map((e) {
              final s = ViewSource.tryFromString(e['source'] as String?);
              if (s == null) return null;
              return SourceBreakdownItem(
                source: s,
                count: e['count'] as int? ?? 0,
                percentage: (e['percentage'] as num?)?.toDouble() ?? 0.0,
              );
            })
            .whereType<SourceBreakdownItem>()
            .toList();

    dynamic deviceData = json['device_breakdown'];
    final deviceList =
        (deviceData is List
                ? deviceData
                : (deviceData is Map ? deviceData.values.toList() : []))
            .map((e) {
              final d = DeviceType.fromString(e['device'] as String?);
              if (d == null) return null;
              return DeviceBreakdownItem(
                device: d,
                count: e['count'] as int? ?? 0,
                percentage: (e['percentage'] as num?)?.toDouble() ?? 0.0,
              );
            })
            .whereType<DeviceBreakdownItem>()
            .toList();

    return PostAnalytics(
      postId: json['post_id'] as String? ?? '',
      totalViews: _parseInt(json['total_views']),
      uniqueViews: _parseInt(json['unique_views']),
      reactionsTotal: _parseInt(json['reactions_count']),
      commentsCount: _parseInt(json['comments_count']),
      repostsCount: _parseInt(json['reposts_count']),
      savesCount: _parseInt(json['saves_count']),
      sharesCount: _parseInt(json['shares_count']),
      engagementRate: _parseDouble(json['engagement_rate']),
      dailyViews: dailyList,
      sourceBreakdown: sourceList,
      deviceBreakdown: deviceList,
      videoEngagement: VideoEngagement.fromJson(
        json['video_engagement'] as Map<String, dynamic>?,
      ),
      adMetrics: json['ad_metrics'] as Map<String, dynamic>?,
      ctaClicks: _parseInt(json['cta_clicks']),
      ctr: _parseDouble(json['ctr']),
    );
  }

  // ──── PARSING HELPERS ────

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is Map) {
      if (value.containsKey('count')) return _parseInt(value['count']);
      int sum = 0;
      for (var v in value.values) {
        sum += _parseInt(v);
      }
      return sum;
    }
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is Map) {
      if (value.containsKey('rate')) return _parseDouble(value['rate']);
      if (value.containsKey('percentage'))
        return _parseDouble(value['percentage']);
      if (value.containsKey('count')) return _parseDouble(value['count']);
      if (value.isNotEmpty) return _parseDouble(value.values.first);
    }
    return 0.0;
  }

  // ──── COMPUTED ────

  bool get hasSourceData => sourceBreakdown.isNotEmpty;
  bool get hasDeviceData => deviceBreakdown.isNotEmpty;
  bool get hasDailyData => dailyViews.isNotEmpty;
  bool get isAd => adMetrics != null;

  String get formattedTotalViews => _formatCount(totalViews);
  String get formattedUniqueViews => _formatCount(uniqueViews);
  String get formattedReactions => _formatCount(reactionsTotal);
  String get formattedComments => _formatCount(commentsCount);
  String get formattedReproduces => _formatCount(repostsCount);
  String get formattedSaves => _formatCount(savesCount);
  String get formattedReposts => _formatCount(repostsCount);
  String get formattedCtaClicks => _formatCount(ctaClicks);

  String get formattedEngagementRate => '${engagementRate.toStringAsFixed(1)}%';
  String get formattedCtr => '${ctr.toStringAsFixed(1)}%';

  String get formattedEngagement {
    final total = reactionsTotal + commentsCount + repostsCount + savesCount;
    return _formatCount(total);
  }

  String get formattedRepeatRate {
    if (uniqueViews == 0) return '0%';
    final repeat = (totalViews - uniqueViews) / totalViews * 100;
    return '${repeat.toStringAsFixed(0)}%';
  }

  /// Views trend (mock calculation if not provided by backend)
  double get viewsTrend {
    // If not provided, we could calculate from dailyViews
    if (dailyViews.length < 2) return 0.0;
    // Compare last 7 days vs previous 7 days
    // This is just a placeholder logic, usually this comes from backend
    return 0.0;
  }

  String get trendLabel => 'vs last period';

  String get engagementQuality {
    if (engagementRate >= 5.0) return 'Excellent';
    if (engagementRate >= 3.0) return 'High';
    if (engagementRate >= 1.0) return 'Average';
    return 'Low';
  }

  String get engagementQualityColorHex {
    if (engagementRate >= 5.0) return '#4CAF50';
    if (engagementRate >= 3.0) return '#2196F3';
    if (engagementRate >= 1.0) return '#FFC107';
    return '#F44336';
  }

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

  // ──── EMPTY ────

  static PostAnalytics empty(String postId) {
    return PostAnalytics(postId: postId);
  }
}

/// ════════════════════════════════════════════════════════════
/// STORY VIEWER ITEM
/// ════════════════════════════════════════════════════════════

class StoryViewer {
  final String viewerUserId;
  final String viewerUsername;
  final String? viewerDisplayName;
  final String? viewerProfileUrl;
  final DateTime viewedAt;
  final bool? isLiked;

  const StoryViewer({
    required this.viewerUserId,
    required this.viewerUsername,
    this.viewerDisplayName,
    this.viewerProfileUrl,
    required this.viewedAt,
    this.isLiked,
  });

  factory StoryViewer.fromJson(Map<String, dynamic> json) {
    return StoryViewer(
      viewerUserId: json['user_id'] as String? ?? '',
      viewerUsername: json['username'] as String? ?? 'Unknown',
      viewerDisplayName: json['display_name'] as String?,
      viewerProfileUrl: json['profile_url'] as String?,
      viewedAt:
          DateTime.tryParse(json['viewed_at'] as String? ?? '') ??
          DateTime.now(),
      isLiked: json['is_liked'] as bool?,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(viewedAt);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}

class StoryViewersListModel {
  final String storyId;
  final List<StoryViewer> viewers;
  final int totalCount;
  final bool hasMore;
  final int offset;

  const StoryViewersListModel({
    required this.storyId,
    this.viewers = const [],
    this.totalCount = 0,
    this.hasMore = false,
    this.offset = 0,
  });

  factory StoryViewersListModel.fromJsonList(
    String storyId,
    List<dynamic> list, {
    int offset = 0,
    int limit = 50,
  }) {
    final viewers = list.map((e) => StoryViewer.fromJson(e)).toList();
    return StoryViewersListModel(
      storyId: storyId,
      viewers: viewers,
      totalCount: viewers.length, // approximate if not provided
      hasMore: viewers.length >= limit,
      offset: offset,
    );
  }

  StoryViewersListModel appendViewers(List<StoryViewer> newViewers) {
    return StoryViewersListModel(
      storyId: storyId,
      viewers: [...viewers, ...newViewers],
      totalCount: totalCount + newViewers.length,
      hasMore: newViewers.isNotEmpty,
      offset: offset + newViewers.length,
    );
  }

  String get formattedCount {
    if (totalCount < 1000) return totalCount.toString();
    return '${(totalCount / 1000).toStringAsFixed(1)}K';
  }

  String get viewerCountText {
    if (totalCount == 0) return 'No views yet';
    if (totalCount == 1) return '1 view';
    return '$totalCount views';
  }
}

/// ════════════════════════════════════════════════════════════
/// VIEW TRACKING LOCAL STATE
/// ════════════════════════════════════════════════════════════

class ViewTrackingState {
  final String postId;
  final bool isRecorded;
  final DateTime? recordedAt;
  final ViewSource source;
  final int durationSeconds;
  final int viewPercent;

  const ViewTrackingState({
    required this.postId,
    this.isRecorded = false,
    this.recordedAt,
    this.source = ViewSource.feed,
    this.durationSeconds = 0,
    this.viewPercent = 0,
  });

  bool get shouldRecord {
    if (!isRecorded) return true;
    final now = DateTime.now();
    // Allow re-recording views after 24 hours (example logic)
    // or just strict implementation: only once per day
    if (recordedAt == null) return true;
    return now.difference(recordedAt!).inHours >= 24;
  }

  ViewTrackingState updateProgress(int duration, int percent) {
    return ViewTrackingState(
      postId: postId,
      isRecorded: isRecorded,
      recordedAt: recordedAt,
      source: source,
      durationSeconds: duration,
      viewPercent: percent,
    );
  }
}
