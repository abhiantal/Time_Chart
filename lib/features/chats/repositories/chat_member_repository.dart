import 'dart:async';
import 'package:the_time_chart/widgets/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_time_chart/features/chats/model/chat_member_model.dart';
import 'package:the_time_chart/features/chats/model/chat_model.dart';
import 'package:the_time_chart/services/powersync_service.dart';
import 'package:the_time_chart/core/exceptions/app_exception.dart';

class ChatMemberRepository {
  final SupabaseClient _supabase;
  final PowerSyncService _powerSync;

  String? _currentUserId;

  ChatMemberRepository({SupabaseClient? supabase, PowerSyncService? powerSync})
    : _supabase = supabase ?? Supabase.instance.client,
      _powerSync = powerSync ?? PowerSyncService();

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  String? get currentUserId => _currentUserId ?? _supabase.auth.currentUser?.id;

  // ----------------------------------------------------------------------
  // QUERIES
  // ----------------------------------------------------------------------

  Future<ChatMemberModel?> getMyMembership(String chatId) async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      if (_powerSync.isReady) {
        final row = await _powerSync.db.getOptional(
          r'SELECT * FROM chat_members WHERE chat_id = ? AND user_id = ?',
          [chatId, userId],
        );
        if (row != null) {
          return ChatMemberModel.fromJson(Map<String, dynamic>.from(row));
        }
      }

      final data = await _supabase
          .from('chat_members')
          .select()
          .eq('chat_id', chatId)
          .eq('user_id', userId)
          .maybeSingle();

      if (data != null) {
        return ChatMemberModel.fromJson(data);
      }
    } catch (e) {
      logE('Error fetching membership for $chatId', error: e);
    }
    return null;
  }

  Future<ChatMemberModel?> getMember(String chatId, String userId) async {
    if (!_powerSync.isReady) return null;
    final row = await _powerSync.db.getOptional(
      r'''
      SELECT 
        cm.*,
        p.username as username,
        p.profile_url as avatar_url,
        COALESCE(p.display_name, p.username, 'user_' || SUBSTR(cm.user_id, 1, 4)) as full_name
      FROM chat_members cm
      LEFT JOIN user_profiles p ON cm.user_id = p.user_id
      WHERE cm.chat_id = ? AND cm.user_id = ?
      ''',
      [chatId, userId],
    );
    if (row == null) return null;
    return ChatMemberModel.fromJson(Map<String, dynamic>.from(row));
  }

  Stream<List<ChatMemberModel>> watchChatMembers(String chatId) {
    if (!_powerSync.isReady) return Stream.value([]);
    return _powerSync.db
        .watch(
          r'''
      SELECT 
        cm.*,
        p.username as username,
        p.profile_url as avatar_url,
        COALESCE(p.display_name, p.username, 'user_' || SUBSTR(cm.user_id, 1, 4)) as full_name
      FROM chat_members cm
      LEFT JOIN user_profiles p ON cm.user_id = p.user_id
      WHERE cm.chat_id = ? AND cm.is_active = 1
      ''',
          parameters: [chatId],
        )
        .map((rows) {
          return rows
              .map(
                (row) =>
                    ChatMemberModel.fromJson(Map<String, dynamic>.from(row)),
              )
              .toList();
        });
  }

  // ----------------------------------------------------------------------
  // SETTINGS & ACTIONS
  // ----------------------------------------------------------------------

  Future<void> updateMemberSetting({
    required String chatId,
    required String column,
    required dynamic value,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw AppException("User not authenticated");

    // 1. Optimistic UI update in PowerSync
    try {
      await _powerSync.db.execute(
        'UPDATE chat_members SET $column = ?, updated_at = ? WHERE chat_id = ? AND user_id = ?',
        [value, DateTime.now().toUtc().toIso8601String(), chatId, userId],
      );
    } catch (e) {
      logE('Error updating $column locally', error: e);
    }

    // 2. Sync to Supabase
    try {
      await _supabase
          .from('chat_members')
          .update({
            column: value,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .match({'chat_id': chatId, 'user_id': userId});
    } catch (e) {
      logE('Error updating $column in Supabase', error: e);
      throw AppException("Failed to sync $column to server.", originalError: e);
    }
  }

  Future<void> toggleMute(
    String chatId,
    bool isMuted, {
    Duration? muteDuration,
  }) async {
    // If muteDuration is provided, we should calculate the until timestamp
    // For now, simple bool is fine, but we can store the until in metadata
    if (isMuted && muteDuration != null) {
      final until = DateTime.now().add(muteDuration).toUtc().toIso8601String();
      await updateMemberSetting(
        chatId: chatId,
        column: 'mute_until',
        value: until,
      );
    } else {
      await updateMemberSetting(
        chatId: chatId,
        column: 'mute_until',
        value: null,
      );
    }
    await updateMemberSetting(
      chatId: chatId,
      column: 'is_muted',
      value: isMuted ? 1 : 0,
    );
  }

  Future<void> togglePin(String chatId, bool isPinned) async {
    await updateMemberSetting(
      chatId: chatId,
      column: 'is_pinned',
      value: isPinned ? 1 : 0,
    );
  }

  Future<void> toggleArchive(String chatId, bool isArchived) async {
    await updateMemberSetting(
      chatId: chatId,
      column: 'is_archived',
      value: isArchived ? 1 : 0,
    );
  }

  Future<void> toggleBlock(String chatId, bool isBlocked) async {
    await updateMemberSetting(
      chatId: chatId,
      column: 'is_blocked',
      value: isBlocked ? 1 : 0,
    );
  }

  Future<void> updateRole(
    String chatId,
    String targetUserId,
    String newRole,
  ) async {
    try {
      await _supabase.from('chat_members').update({'role': newRole}).match({
        'chat_id': chatId,
        'user_id': targetUserId,
      });
    } catch (e) {
      throw AppException("Failed to update member role", originalError: e);
    }
  }

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

  Future<ChatResult<void>> addMembers(
    String chatId,
    List<String> userIds,
  ) async {
    try {
      final List<Map<String, dynamic>> membersToInsert = userIds
          .map(
            (userId) => {
              'chat_id': chatId,
              'user_id': userId,
              'role': 'member',
              'joined_at': DateTime.now().toUtc().toIso8601String(),
              'is_active': 1,
            },
          )
          .toList();

      await _supabase.from('chat_members').insert(membersToInsert);
      return ChatResult.success(null);
    } catch (e) {
      return ChatResult.fail(e.toString());
    }
  }

  Future<void> removeMember(String chatId, String targetUserId) async {
    try {
      await _supabase
          .from('chat_members')
          .update({
            'is_active': 0,
            'left_at': DateTime.now().toUtc().toIso8601String(),
          })
          .match({'chat_id': chatId, 'user_id': targetUserId});
    } catch (e) {
      throw AppException("Failed to remove member", originalError: e);
    }
  }
}
