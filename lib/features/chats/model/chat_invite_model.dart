import 'package:the_time_chart/features/chats/model/chat_model.dart';

enum ChatInviteType {
  oneTime,
  multiUse,
  permanent;

  static ChatInviteType fromString(String value) {
    return ChatInviteType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChatInviteType.multiUse,
    );
  }

  String toJson() => name;
}

class ChatInviteModel {
  final String id;
  final String chatId;
  final String code; // The shareable code/slug
  final ChatInviteType type;

  final int? maxUses;
  final int usedCount;

  final DateTime? expiresAt;
  final DateTime createdAt;
  final String createdBy;

  final bool isActive;
  final bool isRevoked;

  // Hydrated
  final ChatModel? chat; // Preview info

  const ChatInviteModel({
    required this.id,
    required this.chatId,
    required this.code,
    required this.type,
    this.maxUses,
    this.usedCount = 0,
    this.expiresAt,
    required this.createdAt,
    required this.createdBy,
    this.isActive = true,
    this.isRevoked = false,
    this.chat,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isLimitReached => maxUses != null && usedCount >= maxUses!;
  bool get isValid => isActive && !isRevoked && !isExpired && !isLimitReached;

  // Added getters
  String get shareUrl =>
      'https://thetimechart.com/join/$code'; // Placeholder URL logic
  int get usesCount => usedCount;
  int? get remainingUses => maxUses != null ? maxUses! - usedCount : null;
  String get invitedRole =>
      'Member'; // Default role for now, or fetch from Type if applicable
  bool get isMaxedOut => maxUses != null && usedCount >= maxUses!;

  String get expiryText {
    if (expiresAt == null) return 'Never expires';
    return isExpired
        ? 'Expired'
        : 'Expires on ${expiresAt!.day}/${expiresAt!.month}/${expiresAt!.year}';
  }

  String get usageText {
    if (maxUses == null) return 'Unlimited uses';
    return '$usedCount / $maxUses uses';
  }

  String get statusText {
    if (isRevoked) return 'Revoked';
    if (isExpired) return 'Expired';
    if (isMaxedOut) return 'Limit Reached';
    return 'Active';
  }

  factory ChatInviteModel.fromJson(Map<String, dynamic> json) {
    bool? toBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        if (value.toLowerCase() == 'true' || value == '1') return true;
        if (value.toLowerCase() == 'false' || value == '0') return false;
      }
      return false;
    }

    return ChatInviteModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      code: json['code'] as String,
      type: ChatInviteType.fromString(json['type'] as String? ?? 'multi_use'),
      maxUses: json['max_uses'] as int?,
      usedCount: json['used_count'] as int? ?? 0,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())?.toLocal()
          : null,
      createdAt:
          DateTime.tryParse(json['created_at'].toString())?.toLocal() ??
          DateTime.now(),
      createdBy: json['created_by'] as String,
      isActive: toBool(json['is_active']) ?? true,
      isRevoked: toBool(json['is_revoked']) ?? false,
      chat: json['chat'] != null ? ChatModel.fromJson(json['chat']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'code': code,
      'type': type.toJson(),
      'max_uses': maxUses,
      'used_count': usedCount,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'is_active': isActive,
      'is_revoked': isRevoked,
    };
  }

  ChatInviteModel copyWith({
    String? id,
    String? chatId,
    String? code,
    ChatInviteType? type,
    int? maxUses,
    int? usedCount,
    DateTime? expiresAt,
    DateTime? createdAt,
    String? createdBy,
    bool? isActive,
    bool? isRevoked,
    ChatModel? chat,
  }) {
    return ChatInviteModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      code: code ?? this.code,
      type: type ?? this.type,
      maxUses: maxUses ?? this.maxUses,
      usedCount: usedCount ?? this.usedCount,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      isRevoked: isRevoked ?? this.isRevoked,
      chat: chat ?? this.chat,
    );
  }
}

class InvitePreset {
  final String Label;
  final Duration? duration;
  final int? maxUses;
  final String? role;

  const InvitePreset({
    required this.Label,
    this.duration,
    this.maxUses,
    this.role,
  });

  static const oneHour = InvitePreset(Label: '1 Hour', duration: Duration(hours: 1));
  static const oneDay = InvitePreset(Label: '1 Day', duration: Duration(days: 1));
  static const oneWeek = InvitePreset(Label: '7 Days', duration: Duration(days: 7));
  static const oneMonth = InvitePreset(Label: '1 Month', duration: Duration(days: 30));
  static const permanent = InvitePreset(Label: 'No Limit');
  static const unlimited = InvitePreset(Label: 'No Limit');
  static const oneUse = InvitePreset(Label: '1 Use', maxUses: 1);
  static const singleUse = InvitePreset(Label: 'Single Use', maxUses: 1);
  static const tenUses = InvitePreset(Label: '10 Uses', maxUses: 10);
  static const adminInvite = InvitePreset(
    Label: 'Admin Invite',
    maxUses: 1,
    duration: Duration(days: 1),
    role: 'admin',
  );
}

class InviteLinkInfo {
  final bool isValid;
  final ChatInviteModel? invite;
  final String? error;
  final String? joinMetadata;

  InviteLinkInfo({this.isValid = false, this.invite, this.error, this.joinMetadata});

  String? get chatName => invite?.chat?.name;
  String? get chatAvatar => invite?.chat?.avatar;
  int? get memberCount => invite?.chat?.totalMembers;
  String? get creatorName => invite?.createdBy;
}

class JoinResult {
  final bool success;
  final String? chatId;
  final String? chatName;
  final String? error;

  JoinResult.success(this.chatId, {this.chatName}) : success = true, error = null;
  JoinResult.fail(this.error) : success = false, chatId = null, chatName = null;
}
