import 'package:the_time_chart/media_utility/media_asset_model.dart';

enum AttachmentType {
  image,
  video,
  audio,
  voice,
  document;

  static AttachmentType fromString(String value) {
    return AttachmentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AttachmentType.document,
    );
  }

  String toJson() => name;
}

class ChatMessageAttachmentModel {
  final String id;
  final String messageId;
  final String? chatId; // Optional, auto-set by DB trigger
  final AttachmentType type;

  final String url;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;

  final int? width;
  final int? height;
  final int? duration; // seconds

  final int sortOrder;
  final DateTime createdAt;

  const ChatMessageAttachmentModel({
    required this.id,
    required this.messageId,
    this.chatId,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.width,
    this.height,
    this.duration,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory ChatMessageAttachmentModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageAttachmentModel(
      id: json['id']?.toString() ?? '',
      messageId: json['message_id']?.toString() ?? '',
      chatId: json['chat_id']?.toString(),
      type: AttachmentType.fromString(json['type']?.toString() ?? 'document'),
      url: json['url']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString(),
      fileName: json['file_name']?.toString(),
      fileSize: json['file_size'] is int
          ? json['file_size'] as int
          : int.tryParse(json['file_size']?.toString() ?? ''),
      mimeType: json['mime_type']?.toString(),
      width: json['width'] is int
          ? json['width'] as int
          : int.tryParse(json['width']?.toString() ?? ''),
      height: json['height'] is int
          ? json['height'] as int
          : int.tryParse(json['height']?.toString() ?? ''),
      duration: json['duration'] is int
          ? json['duration'] as int
          : int.tryParse(json['duration']?.toString() ?? ''),
      sortOrder: json['sort_order'] is int
          ? json['sort_order'] as int
          : int.tryParse(json['sort_order']?.toString() ?? '') ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'chat_id': chatId,
      'type': type.toJson(),
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'width': width,
      'height': height,
      'duration': duration,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ChatMessageAttachmentModel copyWith({
    String? id,
    String? messageId,
    String? chatId,
    AttachmentType? type,
    String? url,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    String? mimeType,
    int? width,
    int? height,
    int? duration,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return ChatMessageAttachmentModel(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      type: type ?? this.type,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      duration: duration ?? this.duration,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convenience getters
  bool get isVideo => type == AttachmentType.video;
  bool get isVoice =>
      type == AttachmentType.voice || type == AttachmentType.audio;
  bool get isAudio => type == AttachmentType.audio;
  bool get isImage => type == AttachmentType.image;
  bool get isDocument => type == AttachmentType.document;

  String get formattedDuration {
    if (duration == null) return '0:00';
    final m = duration! ~/ 60;
    final s = duration! % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  EnhancedMediaFile toEnhancedMediaFile() {
    MediaFileType mediaType;
    switch (type) {
      case AttachmentType.image:
        mediaType = MediaFileType.image;
        break;
      case AttachmentType.video:
        mediaType = MediaFileType.video;
        break;
      case AttachmentType.audio:
      case AttachmentType.voice:
        mediaType = MediaFileType.audio;
        break;
      case AttachmentType.document:
        mediaType = MediaFileType.document;
        break;
    }

    return EnhancedMediaFile(
      id: id,
      url: url,
      type: mediaType,
      fileName: fileName,
      size: fileSize,
      uploadedAt: createdAt,
      thumbnailUrl: thumbnailUrl,
      duration: duration != null ? Duration(seconds: duration!) : null,
      isLocal: false,
    );
  }
}
