import 'dart:convert';
import 'package:the_time_chart/features/chats/model/chat_model.dart';

enum ChatMemberRole {
  owner,
  admin,
  member;

  static ChatMemberRole fromString(String value) {
    return ChatMemberRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChatMemberRole.member,
    );
  }

  String toJson() => name;

  bool get isAdmin =>
      this == ChatMemberRole.admin || this == ChatMemberRole.owner;
  bool get isOwner => this == ChatMemberRole.owner;
}

class ChatMemberModel {
  final String id;
  final String chatId;
  final String userId;
  final ChatMemberRole role;

  // Settings
  final bool isPinned;
  final bool isMuted;
  final DateTime? muteUntil;
  final bool isArchived;
  final bool isBlocked;

  // Read state
  final String? lastReadMessageId;
  final DateTime? lastReadAt;
  final int unreadCount;
  final int unreadMentions;

  // Status
  final bool isActive;
  final DateTime joinedAt;
  final String? invitedBy;

  // Formatting / UI
  final ChatMemberSettings settings;
  final String? username; // Joined field
  final String? avatarUrl; // Joined field
  final String? fullName; // Joined field
  final bool isOnline; // Runtime state
  final DateTime? lastSeen; // Runtime state

  const ChatMemberModel({
    required this.id,
    required this.chatId,
    required this.userId,
    this.role = ChatMemberRole.member,
    this.isPinned = false,
    this.isMuted = false,
    this.muteUntil,
    this.isArchived = false,
    this.isBlocked = false,
    this.lastReadMessageId,
    this.lastReadAt,
    this.unreadCount = 0,
    this.unreadMentions = 0,
    this.isActive = true,
    required this.joinedAt,
    this.invitedBy,
    this.settings = const ChatMemberSettings(),
    this.username,
    this.avatarUrl,
    this.fullName,
    this.isOnline = false,
    this.lastSeen,
  });

  bool get isAdmin =>
      role == ChatMemberRole.admin || role == ChatMemberRole.owner;
  bool get isOwner => role == ChatMemberRole.owner;

  // -- Permissions based on role --
  bool get canAddMembers =>
      isAdmin; // Default rule, overridden by chat settings
  bool get canRemoveMembers => isAdmin; // Default
  bool get canEditGroupInfo => isAdmin; // Default
  bool get canPinMessages => isAdmin;
  bool get canDeleteMessages => isAdmin;
  bool get canCreateInvite => isAdmin;

  factory ChatMemberModel.fromJson(Map<String, dynamic> json) {
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

    return ChatMemberModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      userId: json['user_id'] as String,
      role: ChatMemberRole.fromString(json['role'] as String? ?? 'member'),
      isPinned: toBool(json['is_pinned']) ?? false,
      isMuted: toBool(json['is_muted']) ?? false,
      muteUntil: json['mute_until'] != null
          ? DateTime.tryParse(json['mute_until'].toString())?.toLocal()
          : null,
      isArchived: toBool(json['is_archived']) ?? false,
      isBlocked: toBool(json['is_blocked']) ?? false,
      lastReadMessageId: json['last_read_message_id'] as String?,
      lastReadAt: json['last_read_at'] != null
          ? DateTime.tryParse(json['last_read_at'].toString())?.toLocal()
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      unreadMentions: json['unread_mentions'] as int? ?? 0,
      isActive: toBool(json['is_active']) ?? true,
      joinedAt:
          DateTime.tryParse(json['joined_at'].toString())?.toLocal() ??
          DateTime.now(),
      invitedBy: json['invited_by'] as String?,
      settings: json['settings'] != null
          ? ChatMemberSettings.fromJson(
              json['settings'] is String
                  ? Map<String, dynamic>.from(jsonDecode(json['settings']))
                  : json['settings'] as Map<String, dynamic>,
            )
          : const ChatMemberSettings(),
      username: json['username'] as String?,
      avatarUrl:
          json['profile_url'] as String? ?? json['avatar_url'] as String?,
      fullName: json['full_name'] as String?,
      isOnline: false, // Set at runtime
      lastSeen: null, // Set at runtime
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'user_id': userId,
      'role': role.toJson(),
      'is_pinned': isPinned,
      'is_muted': isMuted,
      'mute_until': muteUntil?.toIso8601String(),
      'is_archived': isArchived,
      'is_blocked': isBlocked,
      'last_read_message_id': lastReadMessageId,
      'last_read_at': lastReadAt?.toIso8601String(),
      'unread_count': unreadCount,
      'unread_mentions': unreadMentions,
      'is_active': isActive,
      'joined_at': joinedAt.toIso8601String(),
      'invited_by': invitedBy,
      'settings': settings.toJson(),
    };
  }

  ChatMemberModel copyWith({
    String? id,
    String? chatId,
    String? userId,
    ChatMemberRole? role,
    bool? isPinned,
    bool? isMuted,
    DateTime? muteUntil,
    bool? isArchived,
    bool? isBlocked,
    String? lastReadMessageId,
    DateTime? lastReadAt,
    int? unreadCount,
    int? unreadMentions,
    bool? isActive,
    DateTime? joinedAt,
    String? invitedBy,
    ChatMemberSettings? settings,
    String? username,
    String? avatarUrl,
    String? fullName,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return ChatMemberModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      muteUntil: muteUntil ?? this.muteUntil,
      isArchived: isArchived ?? this.isArchived,
      isBlocked: isBlocked ?? this.isBlocked,
      lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      unreadCount: unreadCount ?? this.unreadCount,
      unreadMentions: unreadMentions ?? this.unreadMentions,
      isActive: isActive ?? this.isActive,
      joinedAt: joinedAt ?? this.joinedAt,
      invitedBy: invitedBy ?? this.invitedBy,
      settings: settings ?? this.settings,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fullName: fullName ?? this.fullName,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

class ChatMemberSettings {
  final Map<String, dynamic> _data;

  const ChatMemberSettings([this._data = const {}]);

  factory ChatMemberSettings.fromJson(Map<String, dynamic> json) =>
      ChatMemberSettings(json);

  Map<String, dynamic> toJson() => _data;

  String? get customTitle => _data['custom_title'] as String?;
  NotificationLevel get notificationLevel => NotificationLevel.fromString(
    _data['notification_level'] as String? ?? 'all',
  );
  String? get customSound => _data['custom_sound'] as String?;
}
