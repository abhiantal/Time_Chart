import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_time_chart/media_utility/universal_media_service.dart';
import 'package:the_time_chart/features/chats/model/chat_model.dart';
import 'package:the_time_chart/features/chats/model/chat_attachment_model.dart';
import 'package:the_time_chart/features/chats/repositories/chat_repository.dart';
import 'package:the_time_chart/services/powersync_service.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

class ChatMediaUploadTask {
  final String id;
  final File file;
  final AttachmentType type;
  final double progress;
  final bool isCompleted;
  final String? error;
  final String? uploadedUrl;

  const ChatMediaUploadTask({
    required this.id,
    required this.file,
    required this.type,
    this.progress = 0.0,
    this.isCompleted = false,
    this.error,
    this.uploadedUrl,
  });

  ChatMediaUploadTask copyWith({
    double? progress,
    bool? isCompleted,
    String? error,
    String? uploadedUrl,
  }) {
    return ChatMediaUploadTask(
      id: id,
      file: file,
      type: type,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error ?? this.error,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
    );
  }
}

class ChatAttachmentRepository {
  final UniversalMediaService _mediaService;
  final SupabaseClient _supabase;
  final PowerSyncService _powerSync;

  // Stream controller for upload progress
  final _progressController =
      StreamController<Map<String, ChatMediaUploadTask>>.broadcast();
  final Map<String, ChatMediaUploadTask> _tasks =
      {}; // Key: Task ID (usually path hash or UUID)

  ChatAttachmentRepository({
    UniversalMediaService? mediaService,
    SupabaseClient? supabase,
    PowerSyncService? powerSync,
  }) : _mediaService = mediaService ?? UniversalMediaService(),
       _supabase = supabase ?? Supabase.instance.client,
       _powerSync = powerSync ?? PowerSyncService();

  Stream<Map<String, ChatMediaUploadTask>> get uploadProgressStream =>
      _progressController.stream;

  Future<void> initialize() async {} // Optional hook

  // --------------------------------------------------------------------------------
  // UPLOADS & SENDING
  // --------------------------------------------------------------------------------

  Future<ChatResult<String>> uploadAndSendMedia({
    required String chatId,
    required List<ChatMediaUploadTask> tasks,
    required ChatRepository chatRepo,
    String? caption,
    String? replyToId,
  }) async {
    if (tasks.isEmpty) return ChatResult.fail('No media to send');

    // Queue tasks
    for (var task in tasks) {
      _tasks[task.id] = task;
    }
    _notify();

    try {
      final List<Map<String, dynamic>> attachmentsToInsert = [];
      final messageId = const Uuid().v4();
      final String currentUserId = _supabase.auth.currentUser!.id;
      final String now = DateTime.now().toUtc().toIso8601String();
      final firstTask = tasks.first;
      final String mainMediaType = firstTask.type.toJson();
      final Map<String, dynamic> msgMetadata = {
        'url': firstTask.file.path,
        'file_name': p.basename(firstTask.file.path),
        'file_size': await firstTask.file.length(),
        'attachment_type': firstTask.type.toJson(),
      };

      for (var task in tasks) {
        attachmentsToInsert.add({
          'id': const Uuid().v4(),
          'chat_id': chatId,
          'type': task.type.toJson(),
          'url': task
              .file
              .path, // Store local path initially for offline rendering
          'file_name': p.basename(task.file.path),
          'file_size': await task.file.length(),
          'mime_type': 'application/octet-stream',
          'metadata': '{}',
          'created_at': now,
          'task': task,
        });
      }

      await _powerSync.db.writeTransaction((tx) async {
        // 1. Insert Message
        await tx.execute(
          r'''
          INSERT INTO chat_messages (
            id, chat_id, sender_id, type, text_content, reply_to_id, 
            status, created_at, sent_at, updated_at,
            is_deleted, is_pinned, is_edited, metadata
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
          [
            messageId,
            chatId,
            currentUserId,
            mainMediaType,
            caption,
            replyToId,
            'sending',
            now,
            now,
            now,
            0,
            0,
            0,
            jsonEncode(msgMetadata),
          ],
        );

        // 2. Insert Attachments
        for (var att in attachmentsToInsert) {
          await tx.execute(
            r'''
             INSERT INTO chat_message_attachments (
               id, message_id, chat_id, type, url, file_name, file_size, 
               mime_type, created_at
             ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
           ''',
            [
              att['id'],
              messageId,
              chatId,
              att['type'],
              att['url'],
              att['file_name'],
              att['file_size'],
              att['mime_type'],
              att['created_at'],
            ],
          );
        }

        // 3. Update Chat
        await tx.execute(
          r'''
          UPDATE chats 
          SET last_message_at = ?, updated_at = ?
          WHERE id = ?
        ''',
          [now, now, chatId],
        );
      });

      unawaited(
        _processBackgroundUploads(chatId, messageId, attachmentsToInsert),
      );

      return ChatResult.success(messageId);
    } catch (e) {
      // Mark failed
      for (var task in tasks) {
        if (_tasks.containsKey(task.id) && !_tasks[task.id]!.isCompleted) {
          _tasks[task.id] = _tasks[task.id]!.copyWith(error: e.toString());
        }
      }
      _notify();
      return ChatResult.fail(e.toString());
    }
  }

  Future<void> _processBackgroundUploads(
    String chatId,
    String messageId,
    List<Map<String, dynamic>> attachments,
  ) async {
    bool allSuccess = true;

    String? firstRemoteUrl;

    for (var att in attachments) {
      final task = att['task'] as ChatMediaUploadTask;
      final url = await _uploadFile(task, chatId);
      if (url == null) {
        allSuccess = false;
        continue;
      }

      if (firstRemoteUrl == null) firstRemoteUrl = url;

      await _powerSync.db.execute(
        r'''
        UPDATE chat_message_attachments
        SET url = ?
        WHERE id = ?
      ''',
        [url, att['id']],
      );

      _tasks.remove(task.id);
    }

    // Update message metadata with the first successful remote URL as fallback
    if (firstRemoteUrl != null) {
      try {
        final rows = await _powerSync.db.getAll(
          'SELECT metadata FROM chat_messages WHERE id = ?',
          [messageId],
        );
        if (rows.isNotEmpty) {
          final meta = Map<String, dynamic>.from(
            jsonDecode(rows.first['metadata'] as String? ?? '{}'),
          );
          meta['url'] = firstRemoteUrl;
          await _powerSync.db.execute(
            'UPDATE chat_messages SET metadata = ? WHERE id = ?',
            [jsonEncode(meta), messageId],
          );
        }
      } catch (_) {}
    }

    _notify();

    if (allSuccess) {
      await _powerSync.db.execute(
        r'''
         UPDATE chat_messages
         SET status = 'sent', updated_at = ?
         WHERE id = ?
       ''',
        [DateTime.now().toUtc().toIso8601String(), messageId],
      );
    } else {
      await _powerSync.db.execute(
        r'''
         UPDATE chat_messages
         SET status = 'error', updated_at = ?
         WHERE id = ?
       ''',
        [DateTime.now().toUtc().toIso8601String(), messageId],
      );
    }
  }

  Future<ChatResult<String>> uploadAndSendVoiceNote({
    required String chatId,
    required File audioFile,
    required int durationSeconds,
    required ChatRepository chatRepo,
    String? replyToId,
  }) async {
    final task = ChatMediaUploadTask(
      id: 'voice_${const Uuid().v4()}',
      file: audioFile,
      type: AttachmentType.voice,
    );
    _tasks[task.id] = task;
    _notify();

    try {
      final messageId = const Uuid().v4();
      final now = DateTime.now().toUtc().toIso8601String();
      final currentUserId = _supabase.auth.currentUser!.id;
      final attachmentId = const Uuid().v4();
      final fileSize = await audioFile.length();

      await _powerSync.db.writeTransaction((tx) async {
        // 1. Insert Message
        await tx.execute(
          r'''
            INSERT INTO chat_messages (
              id, chat_id, sender_id, type, text_content, reply_to_id, 
              status, created_at, sent_at, updated_at,
              is_deleted, is_pinned, is_edited, metadata
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            messageId,
            chatId,
            currentUserId,
            'voice',
            null,
            replyToId,
            'sending',
            now,
            now,
            now,
            0,
            0,
            0,
            jsonEncode({'duration': durationSeconds}),
          ],
        );

        // 2. Insert Attachment
        await tx.execute(
          r'''
            INSERT INTO chat_message_attachments (
              id, message_id, chat_id, type, url, file_name, file_size, 
              mime_type, created_at, duration
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            attachmentId,
            messageId,
            chatId,
            'voice',
            audioFile.path,
            'voice_note.m4a',
            fileSize,
            'audio/m4a',
            now,
            durationSeconds,
          ],
        );

        // 3. Update Chat
        await tx.execute(
          r'''
            UPDATE chats 
            SET last_message_at = ?, updated_at = ?
            WHERE id = ?
          ''',
          [now, now, chatId],
        );
      });

      unawaited(
        _processVoiceBackgroundUpload(task, chatId, messageId, attachmentId),
      );
      return ChatResult.success(messageId);
    } catch (e) {
      _tasks[task.id] = task.copyWith(error: e.toString());
      _notify();
      return ChatResult.fail(e.toString());
    }
  }

  Future<void> _processVoiceBackgroundUpload(
    ChatMediaUploadTask task,
    String chatId,
    String messageId,
    String attachmentId,
  ) async {
    final url = await _uploadFile(task, chatId);
    final now = DateTime.now().toUtc().toIso8601String();

    if (url != null) {
      await _powerSync.db.execute(
        r'''
        UPDATE chat_message_attachments
        SET url = ?
        WHERE id = ?
      ''',
        [url, attachmentId],
      );

      await _powerSync.db.execute(
        r'''
        UPDATE chat_messages
        SET status = 'sent', updated_at = ?
        WHERE id = ?
      ''',
        [now, messageId],
      );

      _tasks.remove(task.id);
      _notify();
    } else {
      await _powerSync.db.execute(
        r'''
        UPDATE chat_messages
        SET status = 'error', updated_at = ?
        WHERE id = ?
      ''',
        [now, messageId],
      );
    }
  }

  Future<ChatResult<String>> uploadAndSendDocument({
    required String chatId,
    required File file,
    required ChatRepository chatRepo,
    String? replyToId,
    String? caption,
  }) async {
    final task = ChatMediaUploadTask(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      file: file,
      type: AttachmentType.document,
    );
    return uploadAndSendMedia(
      chatId: chatId,
      tasks: [task],
      chatRepo: chatRepo,
      caption: caption,
      replyToId: replyToId,
    );
  }

  // --------------------------------------------------------------------------------
  // HELPERS
  // --------------------------------------------------------------------------------

  Future<String?> _uploadFile(ChatMediaUploadTask task, String chatId) async {
    try {
      final url = await _mediaService.uploadSingle(
        file: task.file,
        bucket: MediaBucket.chatMedia,
        customPath:
            '${_supabase.auth.currentUser?.id ?? 'unknown'}/$chatId', // Dir path starting with userId for RLS
        exactStoragePath: null,
        onProgress: (progress) {
          _tasks[task.id] = task.copyWith(progress: progress);
          _notify();
        },
      );

      if (url != null) {
        _tasks[task.id] = task.copyWith(
          progress: 1.0,
          isCompleted: true,
          uploadedUrl: url,
        );
        _notify();
      }
      return url;
    } catch (e) {
      _tasks[task.id] = task.copyWith(error: e.toString());
      _notify();
      return null;
    }
  }

  void cancelUpload(String taskId) {
    if (_tasks.containsKey(taskId)) {
      _tasks.remove(taskId);
      _notify();
    }
  }

  void _notify() {
    if (!_progressController.isClosed) {
      _progressController.add(Map.from(_tasks));
    }
  }

  void dispose() {
    _progressController.close();
  }

  // --------------------------------------------------------------------------------
  // READS
  // --------------------------------------------------------------------------------

  Future<Map<String, int>> getMediaCounts(String chatId) async {
    try {
      final response = await _supabase.rpc(
        'get_chat_media_counts',
        params: {'p_chat_id': chatId},
      );
      return Map<String, int>.from(response);
    } catch (e) {
      return {};
    }
  }

  Stream<List<ChatMessageAttachmentModel>> watchMediaGallery(String chatId) {
    return _supabase
        .from('chat_message_attachments')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .map(
          (rows) =>
              rows.map((r) => ChatMessageAttachmentModel.fromJson(r)).toList(),
        );
  }

  Future<List<ChatMessageAttachmentModel>> getMessageAttachments(
    String messageId,
  ) async {
    final response = await _supabase
        .from('chat_message_attachments')
        .select()
        .eq('message_id', messageId);
    return (response as List)
        .map((e) => ChatMessageAttachmentModel.fromJson(e))
        .toList();
  }

  Future<List<ChatMessageAttachmentModel>> getChatImages(String chatId) async {
    final rows = await _powerSync.db.getAll(
      'SELECT * FROM chat_message_attachments WHERE chat_id = ? AND type = ? ORDER BY created_at DESC',
      [chatId, 'image'],
    );
    return rows.map((e) => ChatMessageAttachmentModel.fromJson(e)).toList();
  }

  Future<List<ChatMessageAttachmentModel>> getChatVideos(String chatId) async {
    final rows = await _powerSync.db.getAll(
      'SELECT * FROM chat_message_attachments WHERE chat_id = ? AND type = ? ORDER BY created_at DESC',
      [chatId, 'video'],
    );
    return rows.map((e) => ChatMessageAttachmentModel.fromJson(e)).toList();
  }

  Future<List<ChatMessageAttachmentModel>> getChatDocuments(
    String chatId,
  ) async {
    final rows = await _powerSync.db.getAll(
      'SELECT * FROM chat_message_attachments WHERE chat_id = ? AND type = ? ORDER BY created_at DESC',
      [chatId, 'document'],
    );
    return rows.map((e) => ChatMessageAttachmentModel.fromJson(e)).toList();
  }

  Future<List<ChatMessageAttachmentModel>> getChatVoiceNotes(
    String chatId,
  ) async {
    final rows = await _powerSync.db.getAll(
      'SELECT * FROM chat_message_attachments WHERE chat_id = ? AND type = ? ORDER BY created_at DESC',
      [chatId, 'voice'],
    );
    return rows.map((e) => ChatMessageAttachmentModel.fromJson(e)).toList();
  }

  Future<File?> getFile(String url) async {
    // Use Service to get valid path (local if cached)
    final path = await _mediaService.getValidSignedUrl(url);
    if (path != null && !path.startsWith('http')) {
      return File(path);
    }
    // If still remote, try download
    if (path != null && path.startsWith('http')) {
      return await _mediaService.downloadFile(
        mediaUrl: path,
        bucket: MediaBucket.chatMedia,
      );
    }
    return null;
  }

  Future<String> getValidUrl(String pathOrUrl) async {
    // Return resolved URL (could be local path or signed URL)
    return await _mediaService.getValidSignedUrl(pathOrUrl) ?? pathOrUrl;
  }

  Future<Map<String, dynamic>> getCacheInfo() async {
    return {'size': '0 MB', 'count': 0}; // Placeholder
  }

  void clearUrlCache() {
    // No-op
  }
}
