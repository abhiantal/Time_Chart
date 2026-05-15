import 'dart:convert';
import 'package:the_time_chart/features/chats/model/chat_member_model.dart';
import 'package:the_time_chart/features/chats/model/chat_message_model.dart';

enum ChatType {
  oneOnOne,
  group,
  community,
  broadcast;

  static ChatType fromString(String value) {
    return ChatType.values.firstWhere(
      (e) => e.name == value || e.name == value.replaceAll('_', ''),
      orElse: () => ChatType.oneOnOne,
    );
  }

  String toJson() {
    switch (this) {
      case ChatType.oneOnOne:
        return 'one_on_one';
      case ChatType.group:
        return 'group';
      case ChatType.community:
        return 'community';
      case ChatType.broadcast:
        return 'broadcast';
    }
  }
}

enum ChatVisibility {
  public,
  private;

  static ChatVisibility fromString(String value) {
    return ChatVisibility.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChatVisibility.private,
    );
  }

  String toJson() => name;
}

enum ChatPermission {
  all,
  admins,
  owner;

  static ChatPermission fromString(String value) {
    return ChatPermission.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChatPermission.all,
    );
  }

  String toJson() => name;
}

class ChatModel {
  final String id;
  final ChatType type;
  final String? name; // For groups
  final String? avatar;
  final String? description;
  final ChatVisibility visibility;

  // Permissions
  final ChatPermission whoCanSend;
  final ChatPermission whoCanAddMembers;

  // Settings
  final bool disappearingMessages;
  final int? disappearingDuration; // in seconds
  final Map<String, dynamic> metadata;

  // Metrics
  final int totalMembers;
  final DateTime? lastMessageAt;

  // Metadata
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // -- Computed / joined fields --
  final ChatMessageModel? lastMessage;
  final int unreadCount;
  final int unreadMentions;
  final bool isPinned;
  final bool isMuted;
  final bool isArchived;
  final ChatMemberRole? myRole;
  final List<ChatMemberModel> members; // Only loaded if needed

  // joined user fields for 1:1 chats
  final String? otherUserId;
  final String? otherUserFullName;
  final String? otherUserName;
  final String? otherUserAvatarUrl;

  // UI override for drafts or custom previews
  final String? previewOverride;

  const ChatModel({
    required this.id,
    required this.type,
    this.name,
    this.avatar,
    this.description,
    this.visibility = ChatVisibility.private,
    this.whoCanSend = ChatPermission.all,
    this.whoCanAddMembers = ChatPermission.admins,
    this.disappearingMessages = false,
    this.disappearingDuration,
    this.metadata = const {},
    this.totalMembers = 0,
    this.lastMessageAt,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.unreadMentions = 0,
    this.isPinned = false,
    this.isMuted = false,
    this.isArchived = false,
    this.myRole,
    this.members = const [],
    this.otherUserId,
    this.otherUserFullName,
    this.otherUserName,
    this.otherUserAvatarUrl,
    this.previewOverride,
  });

  bool get isGroup => type == ChatType.group || type == ChatType.community;
  bool get isOneOnOne => type == ChatType.oneOnOne;
  bool get isCommunity => type == ChatType.community;
  bool get isBroadcast => type == ChatType.broadcast;
  bool get isPublic => visibility == ChatVisibility.public;

  bool get amIAdmin =>
      myRole == ChatMemberRole.admin || myRole == ChatMemberRole.owner;
  bool get amIOwner => myRole == ChatMemberRole.owner;

  // Display name for UI
  String get displayName {
    if (isOneOnOne) {
      final dn = otherUserFullName ?? otherUserName;
      if (dn != null && dn.isNotEmpty && dn != 'Unknown') return dn;
      if (name != null && name!.isNotEmpty && name != 'Unknown') return name!;
      
      // Check metadata for other_user_name
      final metaName = metadata['other_user_full_name'] ?? metadata['other_username'] ?? metadata['other_user_name'];
      if (metaName != null && metaName.toString().isNotEmpty) return metaName.toString();

      // Fallback to ID prefix if name is missing
      final otherId = otherUserId;
      if (otherId != null && otherId.length > 4) {
        return 'User ${otherId.substring(0, 4)}';
      }
      return 'Unknown';
    }
    return name ?? 'Group';
  }

  // Get community rules from metadata
  String? get rules {
    final rawRules = metadata['rules'];
    if (rawRules == null) return null;
    if (rawRules is String) return rawRules.isEmpty ? null : rawRules;
    if (rawRules is List) {
      if (rawRules.isEmpty) return null;
      return rawRules.join('\n');
    }
    return null;
  }

  List<String> get rulesList {
    final rawRules = metadata['rules'];
    if (rawRules is List) return List<String>.from(rawRules);
    if (rawRules is String && rawRules.isNotEmpty) return [rawRules];
    return [];
  }

  String? get banner => metadata['banner'] as String?;


  String? get otherUserAvatar {
    if (!isOneOnOne) return avatar;
    return otherUserAvatarUrl ?? avatar;
  }

  String get lastMessagePreview {
    if (previewOverride != null) return previewOverride!;
    if (lastMessage == null) return 'No messages';
    if (lastMessage!.isDeleted) return 'Message deleted';

    switch (lastMessage!.type) {
      case ChatMessageType.text:
        return lastMessage!.textContent ?? '';
      case ChatMessageType.image:
        return '📷 Image';
      case ChatMessageType.video:
        return '🎥 Video';
      case ChatMessageType.audio:
      case ChatMessageType.voice:
        return '🎤 Voice message';
      case ChatMessageType.document:
        return '📄 Document';
      case ChatMessageType.location:
        return '📍 Location';
      case ChatMessageType.contact:
        return '👤 Contact';
      case ChatMessageType.sharedContent:
        return '🔗 Shared content';
      case ChatMessageType.system:
        return 'System message';
    }
  }

  // -- Logic --

  // Check if a user created this chat
  bool isCreatedBy(String userId) => createdBy == userId;

  // Alias for backward compatibility
  ChatModel get chat => this;

  bool canUserSend(String userId, String userRole) {
    if (amIOwner) return true;
    if (userRole == 'owner') return true;

    switch (whoCanSend) {
      case ChatPermission.all:
        return true;
      case ChatPermission.admins:
        return userRole == 'admin';
      case ChatPermission.owner:
        return false; // Owner handled above
    }
  }

  bool canUserAddMembers(String userId, String userRole) {
    if (userRole == 'owner') return true;

    switch (whoCanAddMembers) {
      case ChatPermission.all:
        return true;
      case ChatPermission.admins:
        return userRole == 'admin';
      case ChatPermission.owner:
        return false;
    }
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert int to bool
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

    return ChatModel(
      id: json['id'] as String,
      type: ChatType.fromString(json['type'] as String? ?? 'one_on_one'),
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      description: json['description'] as String?,
      visibility: ChatVisibility.fromString(
        json['visibility'] as String? ?? 'private',
      ),
      whoCanSend: ChatPermission.fromString(
        json['who_can_send'] as String? ?? 'all',
      ),
      whoCanAddMembers: ChatPermission.fromString(
        json['who_can_add_members'] as String? ?? 'admins',
      ),

      // FIX: Use toBool() instead of direct cast
      disappearingMessages: toBool(json['disappearing_messages']) ?? false,

      disappearingDuration: json['disappearing_duration'] as int?,
      metadata: json['metadata'] is String
          ? Map<String, dynamic>.from(jsonDecode(json['metadata']))
          : json['metadata'] as Map<String, dynamic>? ?? {},
      totalMembers: json['total_members'] as int? ?? 0,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'].toString())?.toLocal()
          : null,
      createdBy: json['created_by'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'].toString())?.toLocal() ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'].toString())?.toLocal() ??
          DateTime.now(),

      // FIX: Use toBool() for all boolean fields
      unreadCount: json['unread_count'] as int? ?? 0,
      unreadMentions: json['unread_mentions'] as int? ?? 0,
      isPinned: toBool(json['is_pinned']) ?? false,
      isMuted: toBool(json['is_muted']) ?? false,
      isArchived: toBool(json['is_archived']) ?? false,

      myRole: json['member_role'] != null
          ? ChatMemberRole.fromString(json['member_role'])
          : null,

      otherUserId: json['other_user_id'] as String?,
      otherUserFullName: json['other_full_name'] as String?,
      otherUserName: json['other_username'] as String?,
      otherUserAvatarUrl: json['other_avatar_url'] as String?,

      // Attempt to parse lastMessage from joined data or direct field
      lastMessage: json['last_message_data'] != null
          ? ChatMessageModel.fromJson(
              json['last_message_data'] is String
                  ? jsonDecode(json['last_message_data'])
                  : Map<String, dynamic>.from(json['last_message_data']),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toJson(),
      'name': name,
      'avatar': avatar,
      'description': description,
      'visibility': visibility.toJson(),
      'who_can_send': whoCanSend.toJson(),
      'who_can_add_members': whoCanAddMembers.toJson(),
      'disappearing_messages': disappearingMessages,
      'disappearing_duration': disappearingDuration,
      'metadata': metadata,
      'total_members': totalMembers,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  // -- ChatListItem Compatibility Getters --
  bool get hasUnread => unreadCount > 0;
  String? get displayAvatar => otherUserAvatar;
  DateTime? get lastMessageTime => lastMessage?.sentAt ?? updatedAt;
  
  // Create a membership-like object for backward compatibility if needed
  ChatMemberModel get membership => ChatMemberModel(
    id: 'current_user',
    chatId: id,
    userId: 'current_user',
    role: myRole ?? ChatMemberRole.member,
    isPinned: isPinned,
    isMuted: isMuted,
    isArchived: isArchived,
    unreadCount: unreadCount,
    unreadMentions: unreadMentions,
    joinedAt: createdAt, // Approximate
  );

  ChatModel copyWith({
    String? id,
    ChatType? type,
    String? name,
    String? avatar,
    String? description,
    ChatVisibility? visibility,
    ChatPermission? whoCanSend,
    ChatPermission? whoCanAddMembers,
    bool? disappearingMessages,
    int? disappearingDuration,
    Map<String, dynamic>? metadata,
    int? totalMembers,
    DateTime? lastMessageAt,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    ChatMessageModel? lastMessage,
    int? unreadCount,
    int? unreadMentions,
    bool? isPinned,
    bool? isMuted,
    bool? isArchived,
    ChatMemberRole? myRole,
    List<ChatMemberModel>? members,
    String? otherUserId,
    String? otherUserFullName,
    String? otherUserName,
    String? otherUserAvatarUrl,
    String? previewOverride,
  }) {
    return ChatModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      description: description ?? this.description,
      visibility: visibility ?? this.visibility,
      whoCanSend: whoCanSend ?? this.whoCanSend,
      whoCanAddMembers: whoCanAddMembers ?? this.whoCanAddMembers,
      disappearingMessages: disappearingMessages ?? this.disappearingMessages,
      disappearingDuration: disappearingDuration ?? this.disappearingDuration,
      metadata: metadata ?? this.metadata,
      totalMembers: totalMembers ?? this.totalMembers,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      unreadMentions: unreadMentions ?? this.unreadMentions,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
      myRole: myRole ?? this.myRole,
      members: members ?? this.members,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserFullName: otherUserFullName ?? this.otherUserFullName,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatarUrl: otherUserAvatarUrl ?? this.otherUserAvatarUrl,
      previewOverride: previewOverride ?? this.previewOverride,
    );
  }
}

/// Generic result wrapper for Chat operations
class ChatResult<T> {
  final bool success;
  final T? data;
  final String? error;

  ChatResult.success(this.data) : success = true, error = null;
  ChatResult.fail(this.error) : success = false, data = null;
}

/// Progress of a media upload
class ChatUploadProgress {
  final String id;
  final double progress; // 0.0 to 1.0
  final bool isComplete;
  final String? error;
  final ChatUploadState state;

  ChatUploadProgress({
    required this.id,
    this.progress = 0.0,
    this.isComplete = false,
    this.error,
    this.state = ChatUploadState.uploading,
  });
}

enum ChatUploadState {
  queued, uploading, processing, completed, failed, cancelled;
  bool get isActive => this == uploading || this == processing || this == queued;
}

enum NotificationLevel {
  all,
  mentions,
  none,
  mute;

  static NotificationLevel fromString(String value) {
    return NotificationLevel.values.firstWhere(
      (e) => e.name == value || e.name == value.replaceAll('Only', ''),
      orElse: () => NotificationLevel.all,
    );
  }

  String toJson() => name;
}

enum SystemEventType {
  chatCreated, memberJoined, memberLeft, memberAdded, memberRemoved,
  memberPromoted, memberDemoted, chatRenamed, chatDescriptionChanged,
  chatAvatarChanged, chatSettingsChanged, messagesPinned, messagesUnpinned,
  disappearingEnabled, disappearingDisabled, nameChanged, avatarChanged;
  
  String toJson() => name;
}

enum SearchResultType {
  chat, contact, message, media, link, file, mention;

  String toJson() => name;
}

class ChatSearchResult {
  final String id;
  final SearchResultType type;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final DateTime? timestamp;
  final Map<String, dynamic>? metadata;

  final ChatModel? chat;
  final ChatMessageModel? message;

  ChatSearchResult({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.timestamp,
    this.metadata,
    this.chat,
    this.message,
  });

  String get chatName => chat?.name ?? title;
  String? get senderName => message?.senderName ?? title;
  String get highlightedText => subtitle ?? '';
  String? get avatarUrl => imageUrl ?? message?.senderAvatar ?? chat?.avatar;
  String? get thumbnailUrl => imageUrl ?? message?.metadata['thumbnail_url'] as String? ?? avatarUrl;
  String get chatId => metadata?['chat_id'] ?? chat?.id ?? (message?.chatId ?? id);
  String? get senderId => metadata?['sender_id'] ?? message?.senderId;

  bool get isVideo => type == SearchResultType.media && message?.type == ChatMessageType.video;
  bool get isAudio => type == SearchResultType.media && message?.type == ChatMessageType.audio;
  bool get isImage => type == SearchResultType.media && message?.type == ChatMessageType.image;
}

class MessageSearchResult {
  final ChatMessageModel? message;
  final String? subtitle;
  final String? senderName;

  const MessageSearchResult({
    this.message,
    this.subtitle,
    this.senderName,
  });
}

class ExtractedLink {
  final String? title;
  final String url;
  final String messageId;
  final String chatId;
  final DateTime timestamp;

  const ExtractedLink({
    this.title,
    required this.url,
    required this.messageId,
    required this.chatId,
    required this.timestamp,
  });
}

class ChatSearchFilter {
  final SearchResultType? type;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? senderId;
  final ChatMessageType? messageType;
  final SharedContentType? sharedContentType;
  final bool? pinnedOnly;
  final bool? hasAttachments;
  final bool? hasLinks;
  final bool? hasMentions;

  const ChatSearchFilter({
    this.type,
    this.startDate,
    this.endDate,
    this.senderId,
    this.messageType,
    this.sharedContentType,
    this.pinnedOnly,
    this.hasAttachments,
    this.hasLinks,
    this.hasMentions,
  });

  bool get hasFilters =>
      type != null || startDate != null || endDate != null || senderId != null ||
      messageType != null || sharedContentType != null || pinnedOnly == true ||
      hasAttachments == true || hasLinks == true || hasMentions == true;
}

class SearchHistoryEntry {
  final String id;
  final String query;
  final DateTime timestamp;
  final SearchResultType? resultType;

  SearchHistoryEntry({required this.id, required this.query, required this.timestamp, this.resultType});
}

enum ReportTargetType { user, group, community, message; String toJson() => name; }
enum ReportReason { spam, harassment, inappropriate, violence, hateSpeech, copyright, other; String toJson() => name; }

class ChatListState {
  final bool isLoading;
  final String? error;

  const ChatListState({this.isLoading = false, this.error});
}
