// ================================================================
// 📁 FILE 3: chat_file_utils.dart
// File type detection, size formatting, MIME type mapping,
// icon selection, storage path generation, validation
// ================================================================

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';

import '../model/chat_attachment_model.dart';

class ChatFileUtils {
  ChatFileUtils._();

  // ================================================================
  // FILE SIZE FORMATTING
  // ================================================================

  /// Format bytes to human-readable: "1.5 MB"
  static String formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Compact size: "1.5M", "500K"
  static String formatFileSizeCompact(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)}K';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}M';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}G';
  }

  // ================================================================
  // ATTACHMENT TYPE DETECTION
  // ================================================================

  /// Detect attachment type from file path or extension
  static AttachmentType detectType(String filePath) {
    final ext = p.extension(filePath).toLowerCase().replaceAll('.', '');
    return detectTypeFromExtension(ext);
  }

  /// Detect from file extension
  static AttachmentType detectTypeFromExtension(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');

    if (_imageExtensions.contains(ext)) return AttachmentType.image;
    if (_videoExtensions.contains(ext)) return AttachmentType.video;
    if (_audioExtensions.contains(ext)) return AttachmentType.audio;
    return AttachmentType.document;
  }

  /// Detect from MIME type
  static AttachmentType detectTypeFromMime(String? mimeType) {
    if (mimeType == null) return AttachmentType.document;

    if (mimeType.startsWith('image/')) return AttachmentType.image;
    if (mimeType.startsWith('video/')) return AttachmentType.video;
    if (mimeType.startsWith('audio/')) return AttachmentType.audio;
    return AttachmentType.document;
  }

  // ================================================================
  // FILE EXTENSION SETS
  // ================================================================

  static const Set<String> _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'svg',
    'heic',
    'heif',
    'tiff',
  };

  static const Set<String> _videoExtensions = {
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
    'flv',
    'wmv',
    'm4v',
    '3gp',
  };

  static const Set<String> _audioExtensions = {
    'mp3',
    'wav',
    'aac',
    'ogg',
    'flac',
    'm4a',
    'wma',
    'opus',
    'amr',
  };

  // ================================================================
  // FILE ICON
  // ================================================================

  /// Get themed icon for file type
  static IconData getFileIcon(String? fileName, {String? mimeType}) {
    if (fileName == null && mimeType == null) return Icons.insert_drive_file;

    final type = mimeType != null
        ? detectTypeFromMime(mimeType)
        : detectType(fileName ?? '');

    switch (type) {
      case AttachmentType.image:
        return Icons.image_rounded;
      case AttachmentType.video:
        return Icons.videocam_rounded;
      case AttachmentType.audio:
        return Icons.audiotrack_rounded;
      case AttachmentType.voice:
        return Icons.mic_rounded;
      case AttachmentType.document:
        return _getDocumentIcon(fileName);
    }
  }

  static IconData _getDocumentIcon(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file_rounded;

    final ext = p.extension(fileName).toLowerCase().replaceAll('.', '');

    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'txt':
      case 'rtf':
      case 'md':
        return Icons.text_snippet_rounded;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.folder_zip_rounded;
      case 'json':
      case 'xml':
      case 'html':
        return Icons.code_rounded;
      case 'apk':
        return Icons.android_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  /// Get themed file icon color
  static Color getFileIconColor(
    BuildContext context,
    String? fileName, {
    String? mimeType,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final type = mimeType != null
        ? detectTypeFromMime(mimeType)
        : detectType(fileName ?? '');

    switch (type) {
      case AttachmentType.image:
        return colorScheme.primary;
      case AttachmentType.video:
        return colorScheme.error;
      case AttachmentType.audio:
      case AttachmentType.voice:
        return colorScheme.tertiary;
      case AttachmentType.document:
        return _getDocumentIconColor(context, fileName);
    }
  }

  static Color _getDocumentIconColor(BuildContext context, String? fileName) {
    final colorScheme = Theme.of(context).colorScheme;
    if (fileName == null) return colorScheme.onSurfaceVariant;

    final ext = p.extension(fileName).toLowerCase().replaceAll('.', '');

    switch (ext) {
      case 'pdf':
        return const Color(0xFFD32F2F);
      case 'doc':
      case 'docx':
        return const Color(0xFF1976D2);
      case 'xls':
      case 'xlsx':
      case 'csv':
        return const Color(0xFF388E3C);
      case 'ppt':
      case 'pptx':
        return const Color(0xFFE64A19);
      case 'zip':
      case 'rar':
      case '7z':
        return const Color(0xFF795548);
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  // ================================================================
  // FILE TYPE LABEL
  // ================================================================

  /// Get human-readable file type label
  static String getFileTypeLabel(String? fileName, {String? mimeType}) {
    if (fileName == null && mimeType == null) return 'File';

    final ext = fileName != null
        ? p.extension(fileName).toLowerCase().replaceAll('.', '')
        : '';

    if (ext.isNotEmpty) return ext.toUpperCase();
    if (mimeType != null) {
      final parts = mimeType.split('/');
      return parts.length > 1 ? parts[1].toUpperCase() : parts[0].toUpperCase();
    }

    return 'File';
  }

  // ================================================================
  // ATTACHMENT DISPLAY INFO
  // ================================================================

  /// Get display name for attachment type
  static String getAttachmentTypeLabel(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return 'Photo';
      case AttachmentType.video:
        return 'Video';
      case AttachmentType.audio:
        return 'Audio';
      case AttachmentType.voice:
        return 'Voice message';
      case AttachmentType.document:
        return 'Document';
    }
  }

  /// Get emoji for attachment type
  static String getAttachmentEmoji(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return '📷';
      case AttachmentType.video:
        return '🎥';
      case AttachmentType.audio:
        return '🎵';
      case AttachmentType.voice:
        return '🎤';
      case AttachmentType.document:
        return '📄';
    }
  }

  // ================================================================
  // VALIDATION
  // ================================================================

  /// Maximum file sizes in bytes
  static const int maxImageSize = 10 * 1024 * 1024; // 10 MB
  static const int maxVideoSize = 100 * 1024 * 1024; // 100 MB
  static const int maxAudioSize = 50 * 1024 * 1024; // 50 MB
  static const int maxDocumentSize = 50 * 1024 * 1024; // 50 MB
  static const int maxVoiceNoteSize = 10 * 1024 * 1024; // 10 MB

  /// Validate file for upload
  static String? validateFile(File file, AttachmentType type) {
    if (!file.existsSync()) return 'File does not exist';

    final size = file.lengthSync();
    if (size == 0) return 'File is empty';

    final maxSize = _getMaxSize(type);
    if (size > maxSize) {
      return 'File too large. Maximum: ${formatFileSize(maxSize)}';
    }

    final ext = p.extension(file.path).toLowerCase().replaceAll('.', '');
    if (!_isAllowedExtension(ext, type)) {
      return 'File type .$ext is not supported';
    }

    return null; // Valid
  }

  static int _getMaxSize(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return maxImageSize;
      case AttachmentType.video:
        return maxVideoSize;
      case AttachmentType.audio:
        return maxAudioSize;
      case AttachmentType.voice:
        return maxVoiceNoteSize;
      case AttachmentType.document:
        return maxDocumentSize;
    }
  }

  static bool _isAllowedExtension(String ext, AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return _imageExtensions.contains(ext);
      case AttachmentType.video:
        return _videoExtensions.contains(ext);
      case AttachmentType.audio:
      case AttachmentType.voice:
        return _audioExtensions.contains(ext);
      case AttachmentType.document:
        return true; // Allow all document types
    }
  }

  // ================================================================
  // STORAGE PATH
  // ================================================================

  /// Generate Supabase storage path for a chat file
  static String generateStoragePath({
    required String userId,
    required String chatId,
    required String fileName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = p.extension(fileName);
    final safeName = p
        .basenameWithoutExtension(fileName)
        .replaceAll(RegExp(r'[^\w-]'), '_');
    return '$userId/$chatId/${safeName}_$timestamp$ext';
  }

  /// Generate thumbnail storage path
  static String generateThumbnailPath({
    required String userId,
    required String chatId,
    required String fileName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$userId/$chatId/thumbnails/thumb_$timestamp.jpg';
  }

  // ================================================================
  // THEMED FILE TILE BUILDER
  // ================================================================

  /// Build a themed file info widget
  static Widget buildFileInfo(
    BuildContext context, {
    required String fileName,
    int? fileSize,
    String? mimeType,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final icon = getFileIcon(fileName, mimeType: mimeType);
    final iconColor = getFileIconColor(context, fileName, mimeType: mimeType);
    final typeLabel = getFileTypeLabel(fileName, mimeType: mimeType);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fileName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        typeLabel,
                        if (fileSize != null) formatFileSize(fileSize),
                      ].join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.download_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
