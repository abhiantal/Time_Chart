import 'dart:convert';
import 'package:the_time_chart/features/chats/model/chat_model.dart';
import 'package:the_time_chart/features/chats/model/chat_attachment_model.dart';

enum ChatMessageType {
  text,
  image,
  video,
  audio,
  voice,
  document,
  location,
  contact,
  sharedContent,
  system;

  static ChatMessageType fromString(String value) {
    if (value == 'shared_content') return ChatMessageType.sharedContent;
    return ChatMessageType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChatMessageType.text,
    );
  }

  String toJson() {
    if (this == ChatMessageType.sharedContent) return 'shared_content';
    return name;
  }
}

enum SharedContentType {
  dayTask,
  weeklyTask,
  longGoal,
  bucketModel,
  diaryEntry,
  post,
  profile,
  chatTask,
  chatPoll;

  static SharedContentType? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'day_task':
        return SharedContentType.dayTask;
      case 'weekly_task':
        return SharedContentType.weeklyTask;
      case 'long_goal':
        return SharedContentType.longGoal;
      case 'bucket_model':
        return SharedContentType.bucketModel;
      case 'diary_entry':
        return SharedContentType.diaryEntry;
      case 'post':
        return SharedContentType.post;
      case 'profile':
        return SharedContentType.profile;
      case 'chat_task':
        return SharedContentType.chatTask;
      case 'chat_poll':
        return SharedContentType.chatPoll;
      default:
        return null;
    }
  }

  String? toJson() {
    switch (this) {
      case SharedContentType.dayTask:
        return 'day_task';
      case SharedContentType.weeklyTask:
        return 'weekly_task';
      case SharedContentType.longGoal:
        return 'long_goal';
      case SharedContentType.bucketModel:
        return 'bucket_model';
      case SharedContentType.diaryEntry:
        return 'diary_entry';
      case SharedContentType.post:
        return 'post';
      case SharedContentType.profile:
        return 'profile';
      case SharedContentType.chatTask:
        return 'chat_task';
      case SharedContentType.chatPoll:
        return 'chat_poll';
    }
  }
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed;

  static MessageStatus fromString(String value) {
    return MessageStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageStatus.sent,
    );
  }

  String toJson() => name;
}

enum RealtimeConnectionState {
  connected,
  connecting,
  reconnecting,
  disconnected,
  error,
}

enum RealtimeMessageEventType {
  newMessage,
  messageEdited,
  messageDeleted,
  reactionUpdated,
  messagePinned,
  messageUnpinned,
  typingStarted,
  typingStopped,
}

class RealtimeMessageEvent {
  final String chatId;
  final RealtimeMessageEventType type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  RealtimeMessageEvent({
    required this.chatId,
    required this.type,
    required this.payload,
    required this.timestamp,
  });

  factory RealtimeMessageEvent.fromJson(Map<String, dynamic> json) {
    return RealtimeMessageEvent(
      chatId: json['chat_id'] ?? '',
      type: RealtimeMessageEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RealtimeMessageEventType.newMessage,
      ),
      payload: json['payload'] ?? {},
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

class ReadReceipt {
  final String chatId;
  final String userId;
  final String messageId;
  final DateTime readAt;

  ReadReceipt({
    required this.chatId,
    required this.userId,
    required this.messageId,
    required this.readAt,
  });

  static ReadReceipt fromJson(Map<String, dynamic> json) {
    return ReadReceipt(
      chatId: json['chat_id'],
      userId: json['user_id'],
      messageId: json['message_id'],
      readAt: DateTime.parse(json['read_at']),
    );
  }
}

enum UserPresence { online, away, offline, busy }

class MessageReactions {
  final Map<String, int> counts;
  final Map<String, List<String>> userIds;
  final bool hasMyReaction;

  const MessageReactions({
    this.counts = const {},
    this.userIds = const {},
    this.hasMyReaction = false,
  });

  factory MessageReactions.fromJson(dynamic json, {String? userId}) {
    if (json == null) return const MessageReactions();

    Map<String, dynamic> raw;
    if (json is String) {
      if (json.isEmpty || json == '{}') return const MessageReactions();
      try {
        raw = Map<String, dynamic>.from(jsonDecode(json));
      } catch (_) {
        return const MessageReactions();
      }
    } else if (json is Map) {
      raw = Map<String, dynamic>.from(json);
    } else {
      return const MessageReactions();
    }

    final Map<String, int> counts = {};
    final Map<String, List<String>> userIds = {};
    bool hasMyReaction = false;

    raw.forEach((emoji, users) {
      if (users is List) {
        final list = users.map((e) => e.toString()).toList();
        userIds[emoji] = list;
        counts[emoji] = list.length;
        if (userId != null && list.contains(userId)) {
          hasMyReaction = true;
        }
      }
    });

    return MessageReactions(
      counts: counts,
      userIds: userIds,
      hasMyReaction: hasMyReaction,
    );
  }

  bool get isEmpty => counts.isEmpty;

  bool hasUserReacted(String emoji, String userId) {
    return userIds[emoji]?.contains(userId) ?? false;
  }

  Map<String, dynamic> get raw => userIds;
}

class MentionedUsers {
  final List<String> userIds;

  const MentionedUsers({this.userIds = const []});

  factory MentionedUsers.fromJson(dynamic json) {
    if (json == null) return const MentionedUsers();
    if (json is List) {
      return MentionedUsers(userIds: json.map((e) => e.toString()).toList());
    }
    if (json is Map<String, dynamic>) {
      return MentionedUsers(
        userIds: (json['user_ids'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
    }
    return const MentionedUsers();
  }

  Map<String, dynamic> toJson() => {
    'user_ids': userIds,
  };

  bool get isEmpty => userIds.isEmpty;
  int get length => userIds.length;
}

class ChatMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final ChatMessageType type;
  final String? textContent;
  final Map<String, dynamic> metadata;

  // Reply
  final String? replyToId;
  final ChatMessageModel? replyToMessage; // Hydrated

  // Forward
  final String? forwardedFromMessageId;
  final int forwardCount;

  // Shared Content
  final SharedContentType? sharedContentType;
  final String? sharedContentId;
  final String? sharedContentMode;
  final Map<String, dynamic>? sharedContentSnapshot;

  // System Events
  final String?
  systemEventTypeRaw; // Renamed from systemEventType to avoid collision
  final Map<String, dynamic>? systemEventData;

  // Reactions
  final MessageReactions reactions;

  // Mentions
  final MentionedUsers mentionedUserIds;

  // State
  final bool isEdited;
  final bool isDeleted;
  final bool isPinned;
  final DateTime? pinnedAt;
  final String? pinnedBy;
  final MessageStatus status;

  // Timestamps
  final DateTime sentAt;
  final DateTime? editedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? starredAt;

  final List<ChatMessageAttachmentModel> attachments;

  // -- Join/Computed --
  final String? senderName;
  final String? senderAvatar;
  final bool isMine; // Computed at runtime

  const ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.type = ChatMessageType.text,
    this.textContent,
    this.metadata = const {},
    this.replyToId,
    this.replyToMessage,
    this.forwardedFromMessageId,
    this.forwardCount = 0,
    this.sharedContentType,
    this.sharedContentId,
    this.sharedContentMode = 'live',
    this.sharedContentSnapshot,
    this.systemEventTypeRaw,
    this.systemEventData,
    this.reactions = const MessageReactions(),
    this.mentionedUserIds = const MentionedUsers(),
    this.isEdited = false,
    this.isDeleted = false,
    this.isPinned = false,
    this.pinnedAt,
    this.pinnedBy,
    this.status = MessageStatus.sent,
    required this.sentAt,
    this.editedAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.starredAt,
    this.senderName,
    this.senderAvatar,
    this.isMine = false,
    this.attachments = const [],
  });

  factory ChatMessageModel.text({
    required String id,
    required String chatId,
    required String senderId,
    required String text,
    Map<String, dynamic> metadata = const {},
    String? replyToId,
    DateTime? sentAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? starredAt,
  }) {
    final now = DateTime.now();
    return ChatMessageModel(
      id: id,
      chatId: chatId,
      senderId: senderId,
      type: ChatMessageType.text,
      textContent: text,
      metadata: metadata,
      replyToId: replyToId,
      sentAt: sentAt ?? now,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      starredAt: starredAt,
    );
  }

  bool get hasText => textContent != null && textContent!.isNotEmpty;
  bool get hasSharedContent =>
      sharedContentType != null &&
      sharedContentId != null &&
      type == ChatMessageType.sharedContent;
  bool get isSystem => type == ChatMessageType.system;
  bool get isForwarded => forwardedFromMessageId != null;
  bool get hasReactions => !reactions.isEmpty;
  bool get isMediaMessage =>
      type == ChatMessageType.image ||
      type == ChatMessageType.video ||
      type == ChatMessageType.audio ||
      type == ChatMessageType.voice ||
      type == ChatMessageType.document;
  bool get isSharedContent => type == ChatMessageType.sharedContent;

  // Metadata Getters
  String? get contactName => metadata['contact_name'];
  String? get contactPhone => metadata['contact_phone'];
  String? get contactUserId => metadata['contact_user_id'];
  double? get locationLat => metadata['location_lat'] is double
      ? metadata['location_lat']
      : double.tryParse(metadata['location_lat']?.toString() ?? '');
  double? get locationLng => metadata['location_lng'] is double
      ? metadata['location_lng']
      : double.tryParse(metadata['location_lng']?.toString() ?? '');
  String? get locationName => metadata['location_name'];
  String? get locationAddress => metadata['location_address'];

  SystemEventType? get systemEventType {
    if (!isSystem) return null;

    // Check both metadata (legacy) and direct field
    final eventTypeStr =
        systemEventTypeRaw ?? metadata['event_type'] as String?;
    if (eventTypeStr == null) return null;

    try {
      return SystemEventType.values.firstWhere(
        (e) => e.name == eventTypeStr,
        orElse: () => SystemEventType.chatCreated,
      );
    } catch (e) {
      return null;
    }
  }

  ChatMessageAttachmentModel? get placeholderAttachment {
    if (attachments.isNotEmpty) return attachments.first;

    // Fallback to metadata
    if (metadata['url'] != null || metadata['attachment_url'] != null) {
      final url = metadata['url'] ?? metadata['attachment_url'];
      final typeStr =
          metadata['attachment_type'] ??
          (type == ChatMessageType.image
              ? 'image'
              : type == ChatMessageType.video
              ? 'video'
              : type == ChatMessageType.audio
              ? 'audio'
              : type == ChatMessageType.voice
              ? 'voice'
              : 'document');

      return ChatMessageAttachmentModel(
        id: 'placeholder_$id',
        messageId: id,
        type: AttachmentType.fromString(typeStr),
        url: url,
        fileName: metadata['file_name'] ?? metadata['name'],
        fileSize: metadata['file_size'] ?? metadata['size'],
        width: metadata['width'],
        height: metadata['height'],
        duration: metadata['duration'],
        mimeType: metadata['mime_type'],
        createdAt: createdAt,
      );
    }
    return null;
  }

  String get previewText {
    if (isDeleted) {
      return '🚫 This message was deleted';
    }
    switch (type) {
      case ChatMessageType.text:
        return textContent ?? '';
      case ChatMessageType.image:
        return '📷 Image';
      case ChatMessageType.video:
        return '🎥 Video';
      case ChatMessageType.audio:
        return '🎤 Audio';
      case ChatMessageType.voice:
        return '🎤 Voice Message';
      case ChatMessageType.document:
        return '📎 Document';
      case ChatMessageType.location:
        return '📍 Location';
      case ChatMessageType.contact:
        return '👤 Contact';
      case ChatMessageType.sharedContent:
        if (sharedContentType == SharedContentType.chatTask) {
          return '📋 Task: ${sharedContentSnapshot?['title'] ?? 'Task'}';
        }
        return '🔗 Shared Content';
      case ChatMessageType.system:
        return systemEventTypeRaw ?? 'System Message';
    }
  }

  factory ChatMessageModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final senderId = json['sender_id']?.toString() ?? '';

    // Helper function to safely convert int/string to bool
    bool? toBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        if (value.toLowerCase() == 'true' || value == '1') return true;
        if (value.toLowerCase() == 'false' || value == '0') return false;
      }
      return false; // default
    }

    // Helper to safely parse JSONB fields (Map or String)
    Map<String, dynamic> parseJsonMap(dynamic value) {
      if (value == null) return {};
      if (value is Map) return Map<String, dynamic>.from(value);
      if (value is String) {
        if (value.isEmpty || value == '{}') return {};
        try {
          final decoded = jsonDecode(value); // Requires import 'dart:convert'
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }
      return {};
    }

    // Parse attachments from json_group_array or from wrapper object
    List<ChatMessageAttachmentModel> attachmentsList = [];
    final rawAttachments = json['attachments'] ?? json['attachments_data'];
    
    if (rawAttachments != null) {
      try {
        final List<dynamic> decoded;
        
        if (rawAttachments is Map<String, dynamic> && rawAttachments['items'] != null) {
          decoded = rawAttachments['items'] as List;
        } else if (rawAttachments is String) {
          if (rawAttachments.isNotEmpty && rawAttachments != '[]' && rawAttachments != '[null]') {
            final parsed = jsonDecode(rawAttachments);
            decoded = parsed is List ? parsed : (parsed is Map && parsed['items'] != null ? (parsed['items'] as List) : []);
          } else {
            decoded = [];
          }
        } else if (rawAttachments is List) {
          decoded = rawAttachments;
        } else {
          decoded = [];
        }

        attachmentsList = decoded
            .where((e) => e != null && e is Map)
            .map((e) => ChatMessageAttachmentModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (e) {
        print('Error parsing attachments for message ${json['id']}: $e');
      }
    }

    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      chatId: json['chat_id']?.toString() ?? '',
      senderId: senderId,
      type: ChatMessageType.fromString(json['type'] as String? ?? 'text'),
      textContent: json['text_content'] as String?,
      metadata: parseJsonMap(json['metadata']),
      replyToId: json['reply_to_id'] as String?,
      forwardedFromMessageId: json['forwarded_from_message_id'] as String?,
      forwardCount: json['forward_count'] as int? ?? 0,
      sharedContentType: SharedContentType.fromString(
        json['shared_content_type'] as String?,
      ),
      sharedContentId: json['shared_content_id'] as String?,
      sharedContentMode: json['shared_content_mode'] as String? ?? 'live',
      sharedContentSnapshot:
          parseJsonMap(json['shared_content_snapshot']).isEmpty
          ? null
          : parseJsonMap(json['shared_content_snapshot']),
      systemEventTypeRaw: json['system_event_type'] as String?,
      systemEventData: parseJsonMap(json['system_event_data']).isEmpty
          ? null
          : parseJsonMap(json['system_event_data']),
      reactions: MessageReactions.fromJson(
        json['reactions'],
        userId: currentUserId,
      ),
      mentionedUserIds: MentionedUsers.fromJson(json['mentioned_user_ids']),
      isEdited: toBool(json['is_edited']) ?? false,
      isDeleted: toBool(json['is_deleted']) ?? false,
      isPinned: toBool(json['is_pinned']) ?? false,
      pinnedAt: json['pinned_at'] != null
          ? DateTime.tryParse(json['pinned_at'].toString())
          : null,
      pinnedBy: json['pinned_by'] as String?,
      status: MessageStatus.fromString(json['status'] as String? ?? 'sent'),
      sentAt:
          DateTime.tryParse(json['sent_at'].toString())?.toLocal() ??
          DateTime.now(),
      editedAt: json['edited_at'] != null
          ? DateTime.tryParse(json['edited_at'].toString())
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      createdAt:
          DateTime.tryParse(json['created_at'].toString())?.toLocal() ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'].toString())?.toLocal() ??
          DateTime.now(),

      // Hydration
      senderName: json['sender_name'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
      isMine: currentUserId != null && senderId == currentUserId,
      replyToMessage: json['reply_message'] != null
          ? ChatMessageModel.fromJson(
              json['reply_message'] as Map<String, dynamic>,
            )
          : null,
      attachments: attachmentsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'type': type.toJson(),
      'text_content': textContent,
      'metadata': metadata,
      'reply_to_id': replyToId,
      'forwarded_from_message_id': forwardedFromMessageId,
      'shared_content_type': sharedContentType?.toJson(),
      'shared_content_id': sharedContentId,
      'shared_content_mode': sharedContentMode,
      'shared_content_snapshot': sharedContentSnapshot,
      'system_event_type': systemEventTypeRaw,
      'system_event_data': systemEventData,
      'reactions': reactions.raw, // Access raw map
      'mentioned_user_ids': mentionedUserIds.toJson(),
      'is_edited': isEdited,
      'is_deleted': isDeleted,
      'is_pinned': isPinned,
      'pinned_at': pinnedAt?.toIso8601String(),
      'pinned_by': pinnedBy,
      'status': status.toJson(),
      'sent_at': sentAt.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'starred_at': starredAt?.toIso8601String(),
      'attachments': {'items': attachments.map((e) => e.toJson()).toList()},
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    ChatMessageType? type,
    String? textContent,
    Map<String, dynamic>? metadata,
    String? replyToId,
    ChatMessageModel? replyToMessage,
    String? forwardedFromMessageId,
    SharedContentType? sharedContentType,
    String? sharedContentId,
    String? sharedContentMode,
    Map<String, dynamic>? sharedContentSnapshot,
    String? systemEventTypeRaw,
    Map<String, dynamic>? systemEventData,
    MessageReactions? reactions,
    MentionedUsers? mentionedUserIds,
    bool? isEdited,
    bool? isDeleted,
    bool? isPinned,
    DateTime? pinnedAt,
    String? pinnedBy,
    MessageStatus? status,
    DateTime? sentAt,
    DateTime? editedAt,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? starredAt,
    String? senderName,
    String? senderAvatar,
    bool? isMine,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      textContent: textContent ?? this.textContent,
      metadata: metadata ?? this.metadata,
      replyToId: replyToId ?? this.replyToId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      forwardedFromMessageId:
          forwardedFromMessageId ?? this.forwardedFromMessageId,
      sharedContentType: sharedContentType ?? this.sharedContentType,
      sharedContentId: sharedContentId ?? this.sharedContentId,
      sharedContentMode: sharedContentMode ?? this.sharedContentMode,
      sharedContentSnapshot:
          sharedContentSnapshot ?? this.sharedContentSnapshot,
      systemEventTypeRaw: systemEventTypeRaw ?? this.systemEventTypeRaw,
      systemEventData: systemEventData ?? this.systemEventData,
      reactions: reactions ?? this.reactions,
      mentionedUserIds: mentionedUserIds ?? this.mentionedUserIds,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      editedAt: editedAt ?? this.editedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      starredAt: starredAt ?? this.starredAt,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      isMine: isMine ?? this.isMine,
    );
  }

}
