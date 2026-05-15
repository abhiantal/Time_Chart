import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_time_chart/features/chats/model/chat_invite_model.dart';
import 'package:the_time_chart/features/chats/model/chat_model.dart';

class ChatInviteRepository {
  final SupabaseClient _supabase;

  ChatInviteRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  // --------------------------------------------------------------------------
  // UTILITIES
  // --------------------------------------------------------------------------

  bool isInviteLink(String text) {
    return text.contains('/join/') || text.contains('chat.invite');
  }

  String? extractCodeFromLink(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null) return null;

    if (uri.pathSegments.contains('join')) {
      final index = uri.pathSegments.indexOf('join');
      if (index + 1 < uri.pathSegments.length) {
        return uri.pathSegments[index + 1];
      }
    }
    return uri.queryParameters['code'];
  }

  // --------------------------------------------------------------------------
  // ACTIONS
  // --------------------------------------------------------------------------

  Future<ChatResult<ChatInviteModel>> createInvite({
    required String chatId,
    ChatInviteType type = ChatInviteType.multiUse,
    int? maxUses,
    DateTime? expiresAt,
  }) async {
    try {
      final response = await _supabase.rpc(
        'create_chat_invite',
        params: {
          'p_chat_id': chatId,
          'p_type': type.toJson(),
          'p_max_uses': maxUses,
          'p_expires_at': expiresAt?.toUtc().toIso8601String(),
        },
      );

      ChatInviteModel invite;
      if (response is Map) {
        invite = ChatInviteModel.fromJson(Map<String, dynamic>.from(response));
      } else {
        invite = await _fetchInviteById(response.toString());
      }
      return ChatResult.success(invite);
    } catch (e) {
      return ChatResult.fail(e.toString());
    }
  }

  Future<ChatResult<ChatInviteModel>> createQuickInvite({
    required String chatId,
    required InvitePreset preset,
  }) async {
    int? maxUses = preset.maxUses;
    DateTime? expiresAt;

    if (preset.duration != null) {
      expiresAt = DateTime.now().add(preset.duration!);
    }

    return createInvite(chatId: chatId, maxUses: maxUses, expiresAt: expiresAt);
  }

  Future<ChatInviteModel?> getInviteByCode(String code) async {
    final response = await _supabase
        .rpc('get_chat_invite_by_code', params: {'p_code': code})
        .maybeSingle();

    if (response == null) return null;
    return ChatInviteModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<InviteLinkInfo> previewInvite(String code) async {
    final invite = await getInviteByCode(code);
    if (invite == null) {
      return InviteLinkInfo(isValid: false, error: 'Invalid or expired code');
    }
    return InviteLinkInfo(isValid: true, invite: invite);
  }

  Future<JoinResult> joinViaCode(String code) async {
    try {
      if (_supabase.auth.currentUser == null) {
        return JoinResult.fail('Not authenticated');
      }

      final result = await _supabase.rpc(
        'join_chat_via_invite',
        params: {'p_code': code, 'p_user_id': _supabase.auth.currentUser!.id},
      );

      return JoinResult.success(result.toString());
    } catch (e) {
      return JoinResult.fail(e.toString());
    }
  }

  Future<JoinResult> joinViaLink(String link) async {
    final code = extractCodeFromLink(link);
    if (code == null) return JoinResult.fail('Invalid link');
    return joinViaCode(code);
  }

  Future<ChatResult<void>> revokeInvite(String inviteId) async {
    try {
      await _supabase.rpc(
        'revoke_chat_invite',
        params: {
          'p_invite_id': inviteId,
          'p_user_id': _supabase.auth.currentUser!.id,
        },
      );
      // Return success with null data
      return ChatResult.success(null);
    } catch (e) {
      return ChatResult.fail(e.toString());
    }
  }

  Future<List<ChatInviteModel>> getChatInvites(
    String chatId, {
    bool activeOnly = true,
  }) async {
    var builder = _supabase.from('chat_invites').select().eq('chat_id', chatId);

    if (activeOnly) {
      builder = builder.eq('is_active', true);
    }

    final response = await builder.order('created_at', ascending: false);
    return (response as List).map((e) => ChatInviteModel.fromJson(e)).toList();
  }

  Future<ChatInviteModel> _fetchInviteById(String id) async {
    final response = await _supabase
        .from('chat_invites')
        .select()
        .eq('id', id)
        .single();
    return ChatInviteModel.fromJson(response);
  }

  void dispose() {}
}
