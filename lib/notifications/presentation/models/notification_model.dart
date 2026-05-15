import 'dart:convert';

/// Immutable models representing a notification.
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.payload,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  /// Factory method to create a NotificationModel from JSON (PowerSync/Supabase).
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? 'No Title',
      body: json['body'] as String? ?? '',
      payload: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : (json['data'] is String ? jsonDecode(json['data'] as String) : {}),
      type: json['notification_type'] as String? ?? 'system',
      isRead: json['opened'] == 1 || json['opened'] == true,
      createdAt: DateTime.parse(json['sent_at'] as String),
      readAt: json['opened_at'] != null
          ? DateTime.parse(json['opened_at'] as String)
          : null,
    );
  }

  /// Factory method to create a NotificationModel from the synced 'notifications' table (PowerSync).
  factory NotificationModel.fromSyncedTable(Map<String, dynamic> json) {
    // Parse the 'notification_info' JSONB column
    final info = json['notification_info'] is String
        ? jsonDecode(json['notification_info'] as String)
        : (json['notification_info'] as Map<String, dynamic>? ?? {});

    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: info['title'] as String? ?? 'Notification',
      body: info['body'] as String? ?? '',
      payload: info['data'] is Map
          ? Map<String, dynamic>.from(info['data'] as Map)
          : (info['data'] is String ? jsonDecode(info['data'] as String) : {}),
      type: info['type'] as String? ?? 'system',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
    );
  }

  /// Converts the models to JSON for potential serialization.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'data': payload,
      'notification_type': type,
      'opened': isRead,
      'sent_at': createdAt.toIso8601String(),
      'opened_at': readAt?.toIso8601String(),
    };
  }

  /// Creates a copy of the models with updated fields.
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    Map<String, dynamic>? payload,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      payload: payload ?? this.payload,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  String get senderName =>
      payload['sender_name'] as String? ??
      payload['name'] as String? ??
      'Someone';

  String? get senderAvatar =>
      payload['sender_avatar'] as String? ??
      payload['avatar_url'] as String?;

  String? get senderId =>
      payload['sender_id'] as String? ?? payload['author_id'] as String?;

  String? get targetId =>
      payload['targetId'] as String? ??
      payload['id'] as String? ??
      payload['post_id'] as String? ??
      payload['chat_id'] as String? ??
      payload['taskId'] as String? ??
      payload['goalId'] as String? ??
      payload['bucketId'] as String?;

  String? get thumbnailUrl =>
      payload['thumbnail_url'] as String? ??
      payload['post_thumbnail'] as String? ??
      payload['image_url'] as String? ??
      payload['media_url'] as String?;

  bool get isInteraction =>
      type == 'like' ||
      type == 'comment' ||
      type == 'follow' ||
      type == 'mention';

  bool get isChat => type == 'chat' || type == 'message';
}
