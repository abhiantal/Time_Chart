import 'package:the_time_chart/features/chats/model/chat_message_model.dart';
import 'package:the_time_chart/features/chats/model/chat_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'dart:convert';
import 'package:the_time_chart/widgets/logger.dart';
import 'package:the_time_chart/services/powersync_service.dart';

class ChatMessageRepository {
  final SupabaseClient _supabase;
  final PowerSyncService _powerSync;

  RealtimeChannel? _activeChannel;
  final _typingController =
      StreamController<Map<String, List<String>>>.broadcast();

  String? _currentUserId;

  ChatMessageRepository({SupabaseClient? supabase, PowerSyncService? powerSync})
    : _supabase = supabase ?? Supabase.instance.client,
      _powerSync = powerSync ?? PowerSyncService();

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  String? get currentUserId => _currentUserId ?? _supabase.auth.currentUser?.id;

  Stream<Map<String, List<String>>> get typingStream =>
      _typingController.stream;

  final Map<String, List<String>> _typingMap = {};

  void sendTyping(String chatId, bool isTyping) {
    if (_activeChannel == null || currentUserId == null) return;

    _activeChannel?.sendBroadcastMessage(
      event: 'typing',
      payload: {
        'user_id': currentUserId,
        'chat_id': chatId,
        'is_typing': isTyping,
      },
    );
  }

  Stream<Map<String, List<String>>> watchTyping(String chatId) {
    return _typingController.stream;
  }

  void setChannel(RealtimeChannel channel) {
    _activeChannel = channel;
    _activeChannel!.onBroadcast(
      event: 'typing',
      callback: (payload) {
        final data = payload as Map<String, dynamic>;
        final chatId = data['chat_id'] as String;
        final userId = data['user_id'] as String;
        final isTyping = data['is_typing'] as bool;

        final chatTyping = List<String>.from(_typingMap[chatId] ?? []);

        if (isTyping) {
          if (!chatTyping.contains(userId)) chatTyping.add(userId);
        } else {
          chatTyping.remove(userId);
        }

        _typingMap[chatId] = chatTyping;
        _typingController.add(Map<String, List<String>>.from(_typingMap));
      },
    );
  }

  // ----------------------------------------------------------------------
  // MESSAGES
  // ----------------------------------------------------------------------

  Stream<List<ChatMessageModel>> watchMessages(
    String chatId, {
    int limit = 50,
  }) {
    if (!_powerSync.isReady) {
      return Stream.value([]);
    }
    return _powerSync.db
        .watch(
          r'''
      SELECT 
        m.*,
        COALESCE(p.display_name, p.username, 'user_' || SUBSTR(m.sender_id, 1, 4)) as sender_name,
        p.profile_url as sender_avatar,
        (
          SELECT json_group_array(
            json_object(
              'id', a.id,
              'message_id', a.message_id,
              'chat_id', a.chat_id,
              'type', a.type,
              'url', a.url,
              'thumbnail_url', a.thumbnail_url,
              'file_name', a.file_name,
              'file_size', a.file_size,
              'mime_type', a.mime_type,
              'width', a.width,
              'height', a.height,
              'duration', a.duration,
              'sort_order', a.sort_order,
              'created_at', a.created_at
            )
          )
          FROM chat_message_attachments a
          WHERE a.message_id = m.id
        ) as attachments_data
      FROM chat_messages m
      LEFT JOIN user_profiles p ON m.sender_id = p.user_id
      WHERE m.chat_id = ?
      ORDER BY m.sent_at DESC LIMIT ?
      ''',
          parameters: [chatId, limit],
        )
        .map((rows) {
          return rows
              .map(
                (row) => ChatMessageModel.fromJson(
                  Map<String, dynamic>.from(row),
                  currentUserId: currentUserId,
                ),
              )
              .toList();
        });
  }

  Stream<List<ChatMessageModel>> watchPinnedMessages(String chatId) {
    if (!_powerSync.isReady) return Stream.value([]);
    return _powerSync.db
        .watch(
          r'''
      SELECT 
        m.*,
        COALESCE(p.display_name, p.username, 'user_' || SUBSTR(m.sender_id, 1, 4)) as sender_name,
        p.profile_url as sender_avatar,
        (
          SELECT json_group_array(
            json_object(
              'id', a.id,
              'message_id', a.message_id,
              'chat_id', a.chat_id,
              'type', a.type,
              'url', a.url,
              'thumbnail_url', a.thumbnail_url,
              'file_name', a.file_name,
              'file_size', a.file_size,
              'mime_type', a.mime_type,
              'width', a.width,
              'height', a.height,
              'duration', a.duration,
              'sort_order', a.sort_order,
              'created_at', a.created_at
            )
          )
          FROM chat_message_attachments a
          WHERE a.message_id = m.id
        ) as attachments_data
      FROM chat_messages m 
      LEFT JOIN user_profiles p ON m.sender_id = p.user_id
      WHERE m.chat_id = ? AND m.is_pinned = 1 AND m.is_deleted = 0
      ORDER BY m.pinned_at DESC
      ''',
          parameters: [chatId],
        )
        .map((rows) {
          return rows
              .map(
                (row) => ChatMessageModel.fromJson(
                  Map<String, dynamic>.from(row),
                  currentUserId: currentUserId,
                ),
              )
              .toList();
        });
  }

  // ----------------------------------------------------------------------
  // WRITES
  // ----------------------------------------------------------------------

  Future<void> markAsRead(String chatId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      if (_powerSync.isReady) {
        await _powerSync.db.execute(
          r'UPDATE chat_members SET unread_count = 0, unread_mentions = 0, last_read_at = ? WHERE chat_id = ? AND user_id = ?',
          [DateTime.now().toUtc().toIso8601String(), chatId, userId],
        );
      }
    } catch (e) {
      logW('Local markAsRead error: $e');
    }

    try {
      await _supabase.rpc(
        'mark_chat_as_read',
        params: {'p_chat_id': chatId, 'p_user_id': userId},
      );
    } catch (e) {
      logE('Remote markAsRead error', error: e);
    }
  }

  Future<String> sendMessage({
    required String chatId,
    required String text,
    String? replyToId,
    List<String>? mentionedUserIds,
  }) async {
    if (currentUserId == null) throw 'Not authenticated';

    final messageId = const Uuid().v4();
    final now = DateTime.now().toUtc().toIso8601String();

    try {
      await _powerSync.db.writeTransaction((tx) async {
        await tx.execute(
          r'''
          INSERT INTO chat_messages (
            id, chat_id, sender_id, type, text_content, reply_to_id, 
            mentioned_user_ids, status, created_at, sent_at, updated_at,
            is_deleted, is_pinned, is_edited,
            shared_content_type, shared_content_id, shared_content_snapshot
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
          [
            messageId,
            chatId,
            currentUserId,
            'text',
            text,
            replyToId,
            mentionedUserIds != null ? jsonEncode(mentionedUserIds) : null,
            'sending',
            now,
            now,
            now,
            0,
            0,
            0,
            null, // type
            null, // id
            null, // snapshot
          ],
        );
        // ...

        await tx.execute(
          'UPDATE chats SET last_message_at = ?, updated_at = ? WHERE id = ?',
          [now, now, chatId],
        );
      });

      return messageId;
    } catch (e) {
      logE('Error sending message', error: e);
      rethrow;
    }
  }

  Future<void> deleteMessageForEveryone(String messageId) async {
    try {
      await _powerSync.db.execute(
        'UPDATE chat_messages SET is_deleted = 1, text_content = null WHERE id = ?',
        [messageId],
      );
    } catch (_) {}

    try {
      await _supabase.rpc(
        'delete_chat_message',
        params: {
          'p_message_id': messageId,
          'p_user_id': currentUserId,
          'p_for_everyone': true,
        },
      );
    } catch (e) {
      logE('Backend message deletion error', error: e);
    }
  }

  Future<void> deleteMessageForMe(String messageId) async {
    try {
      await _supabase.rpc(
        'delete_chat_message',
        params: {
          'p_message_id': messageId,
          'p_user_id': currentUserId,
          'p_for_everyone': false,
        },
      );
    } catch (e) {
      logE('Backend message deletion for me error', error: e);
    }
  }

  Future<void> pinMessage(String messageId, bool pinned) async {
    try {
      await _supabase.rpc(
        'toggle_pin_message',
        params: {'p_message_id': messageId, 'p_user_id': currentUserId},
      );
    } catch (e) {
      logE('Error pinning message remote', error: e);
    }

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _powerSync.db.execute(
        'UPDATE chat_messages SET is_pinned = ?, pinned_at = ?, pinned_by = ? WHERE id = ?',
        [
          pinned ? 1 : 0,
          pinned ? now : null,
          pinned ? currentUserId : null,
          messageId,
        ],
      );
    } catch (_) {}
  }

  Future<String> sendSharedContent({
    required String chatId,
    required String type,
    String? contentId,
    String? textContent,
    Map<String, dynamic>? snapshot,
    String? replyToId,
  }) async {
    if (currentUserId == null) throw 'Not authenticated';

    final messageId = const Uuid().v4();
    final now = DateTime.now().toUtc().toIso8601String();

    try {
      await _powerSync.db.writeTransaction((tx) async {
        await tx.execute(
          r'''
          INSERT INTO chat_messages (
            id, chat_id, sender_id, type, text_content, reply_to_id, 
            status, created_at, sent_at, updated_at,
            is_deleted, is_pinned, is_edited,
            shared_content_type, shared_content_id, shared_content_snapshot
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
          [
            messageId,
            chatId,
            currentUserId,
            'shared_content',
            textContent,
            replyToId,
            'sending',
            now,
            now,
            now,
            0,
            0,
            0,
            type,
            contentId,
            snapshot != null ? jsonEncode(snapshot) : null,
          ],
        );

        await tx.execute(
          'UPDATE chats SET last_message_at = ?, updated_at = ? WHERE id = ?',
          [now, now, chatId],
        );
      });

      return messageId;
    } catch (e) {
      logE('Error sending shared content', error: e);
      rethrow;
    }
  }

  Future<void> voteInPoll({
    required String messageId,
    required String optionId,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw 'Not authenticated';

    // 1. Fetch current message snapshot
    final rows = await _powerSync.db.getAll(
      'SELECT shared_content_snapshot FROM chat_messages WHERE id = ?',
      [messageId],
    );
    if (rows.isEmpty) throw 'Message not found';

    final rawSnapshot = rows.first['shared_content_snapshot'];
    if (rawSnapshot == null) throw 'Poll snapshot not found';

    Map<String, dynamic> snapshot;
    if (rawSnapshot is Map) {
      snapshot = Map<String, dynamic>.from(rawSnapshot);
    } else if (rawSnapshot is String) {
      if (rawSnapshot.isEmpty || rawSnapshot == '{}')
        throw 'Poll snapshot is empty';
      try {
        final decoded = jsonDecode(rawSnapshot);
        if (decoded is Map) {
          snapshot = Map<String, dynamic>.from(decoded);
        } else if (decoded is String) {
          // Handle potential double-encoding
          final doubleDecoded = jsonDecode(decoded);
          if (doubleDecoded is Map) {
            snapshot = Map<String, dynamic>.from(doubleDecoded);
          } else {
            throw 'Invalid poll snapshot format (not a map after double-decode)';
          }
        } else {
          throw 'Invalid poll snapshot format (not a map)';
        }
      } catch (e) {
        throw 'Failed to parse poll snapshot: $e';
      }
    } else {
      throw 'Unexpected poll snapshot type: ${rawSnapshot.runtimeType}';
    }

    final optionsList = snapshot['options'];
    if (optionsList == null || optionsList is! List)
      throw 'Options not found in snapshot';

    final List<Map<String, dynamic>> options = [];
    final List list = optionsList as List;
    for (var i = 0; i < list.length; i++) {
      final e = list[i];
      if (e is Map) {
        options.add(Map<String, dynamic>.from(e));
      } else if (e is String) {
        options.add({'id': 'legacy_$i', 'text': e, 'votes': 0});
      }
    }

    // 2. Update local vote count and tracking
    // We should ideally prevent double voting in the DB, but for simple MVP:
    var totalVotes = snapshot['total_votes'] ?? 0;
    var found = false;
    for (var opt in options) {
      if (opt['id'] == optionId) {
        opt['votes'] = (opt['votes'] ?? 0) + 1;
        totalVotes += 1;
        found = true;
        break;
      }
    }

    if (!found) throw 'Option not found';

    snapshot['options'] = options;
    snapshot['total_votes'] = totalVotes;

    // 3. Persist local update
    await _powerSync.db.execute(
      'UPDATE chat_messages SET shared_content_snapshot = ? WHERE id = ?',
      [jsonEncode(snapshot), messageId],
    );

    // 4. Remote update (Real-world: should call a clever RPC or server side function)
    // For now, we update the snapshot via standard RPC if available, or just rely on PS.
    try {
      await _supabase
          .from('chat_messages')
          .update({'shared_content_snapshot': snapshot})
          .eq('id', messageId);
    } catch (e) {
      logE('Remote poll vote error', error: e);
    }
  }

  Future<ChatResult<String>> toggleReaction(
    String messageId,
    String emoji,
  ) async {
    try {
      final result = await _supabase.rpc<String>(
        'toggle_message_reaction',
        params: {
          'p_message_id': messageId,
          'p_user_id': currentUserId,
          'p_emoji': emoji,
        },
      );
      return ChatResult.success(result);
    } catch (e) {
      return ChatResult.fail(e.toString());
    }
  }

  Future<ChatResult<String>> forwardMessage({
    required String messageId,
    required String toChatId,
  }) async {
    try {
      if (currentUserId == null) return ChatResult.fail('Not authenticated');
      final msgId = await _supabase.rpc<String>(
        'forward_chat_message',
        params: {
          'p_message_id': messageId,
          'p_to_chat_id': toChatId,
          'p_sender_id': currentUserId,
        },
      );
      return ChatResult.success(msgId);
    } catch (e) {
      return ChatResult.fail(e.toString());
    }
  }

  Future<void> clearChatHistory(String chatId) async {
    if (currentUserId == null) return;
    try {
      await _powerSync.db.execute(
        'DELETE FROM chat_messages WHERE chat_id = ?',
        [chatId],
      );
      try {
        await _supabase.rpc(
          'clear_chat_history',
          params: {'p_chat_id': chatId, 'p_user_id': currentUserId},
        );
      } catch (_) {
        await _supabase.from('chat_messages').delete().eq('chat_id', chatId);
      }
    } catch (e) {
      logE('Error clearing history', error: e);
      rethrow;
    }
  }

  // ----------------------------------------------------------------------
  // SEARCH
  // ----------------------------------------------------------------------

  Future<List<ChatMessageModel>> searchInChat(
    String chatId,
    String query,
  ) async {
    if (!_powerSync.isReady) return [];

    // Using simple ILIKE for search in local DB
    final rows = await _powerSync.db.getAll(
      'SELECT * FROM chat_messages WHERE chat_id = ? AND text_content LIKE ? ORDER BY sent_at DESC',
      [chatId, '%$query%'],
    );

    return rows
        .map(
          (e) => ChatMessageModel.fromJson(
            Map<String, dynamic>.from(e),
            currentUserId: currentUserId,
          ),
        )
        .toList();
  }
}
