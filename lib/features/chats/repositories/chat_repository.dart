import 'dart:async';
import 'dart:convert';
import 'package:the_time_chart/widgets/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:the_time_chart/features/chats/model/chat_member_model.dart';
import 'package:the_time_chart/features/chats/model/chat_model.dart';
import 'package:the_time_chart/features/chats/model/chat_message_model.dart';
import 'package:the_time_chart/user_profile/create_edit_profile/profile_repository.dart';
import 'package:the_time_chart/services/powersync_service.dart';

class ChatRepository {
  final SupabaseClient _supabase;
  final PowerSyncService _powerSync;

  String? _currentUserId;

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  ChatRepository({SupabaseClient? supabase, PowerSyncService? powerSync})
    : _supabase = supabase ?? Supabase.instance.client,
      _powerSync = powerSync ?? PowerSyncService();

  PowerSyncService? getCurrentPowerSync() => _powerSync;

  Future<void> deleteChat(String chatId) async {
    try {
      final userId = currentUserId;
      // 1. Local delete: remove the membership entirely.
      // This immediately removes it from watchChatList queries locally,
      // and circumvents the PowerSync cloud rule schema issue where `is_active` isn't pulled.
      // PowerSync will sync this as a safe DELETE on chat_members.
      if (userId != null) {
        await _powerSync.execute(
          'DELETE FROM chat_members WHERE chat_id = ? AND user_id = ?', 
          [chatId, userId]
        );
      }
      
      // 2. Remote delete via RPC
      await _supabase.rpc('delete_chat', params: {'p_chat_id': chatId});
    } catch (e) {
      logE('Error deleting chat: $chatId', error: e);
      rethrow;
    }
  }

  Future<void> markAsRead(String chatId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _powerSync.execute(
        r'UPDATE chat_members SET unread_count = 0, unread_mentions = 0, last_read_at = ? WHERE chat_id = ? AND user_id = ?',
        [DateTime.now().toUtc().toIso8601String(), chatId, userId],
      );
    } catch (e) {
      logW('Local markAsRead error: $e');
    }

    try {
      await _supabase.rpc('mark_chat_as_read', params: {
        'p_chat_id': chatId,
        'p_user_id': userId,
      });
    } catch (e) {
      logE('Remote markAsRead error', error: e);
    }
  }

  String? get currentUserId => _currentUserId ?? _supabase.auth.currentUser?.id;

  // ----------------------------------------------------------------------
  // CHAT LIST
  // ----------------------------------------------------------------------

  Stream<List<ChatModel>> watchChatList() {
    final userId = currentUserId;

    return _powerSync
        .watchQuery(
          r'''
      SELECT 
        c.*, 
        cm.role as member_role,
        cm.unread_count,
        cm.unread_mentions,
        cm.is_pinned,
        cm.is_muted,
        cm.is_archived,
        COALESCE(cm2.user_id, json_extract(c.metadata, '$.other_user_id')) as other_user_id,
        COALESCE(p.display_name, json_extract(c.metadata, '$.other_user_full_name')) as other_full_name,
        COALESCE(p.username, json_extract(c.metadata, '$.other_username')) as other_username,
        COALESCE(p.profile_url, json_extract(c.metadata, '$.other_avatar_url')) as other_avatar_url,
        m.id as lm_id,
        m.type as lm_type,
        m.text_content as lm_text_content,
        m.sender_id as lm_sender_id,
        m.created_at as lm_created_at,
        m.sent_at as lm_sent_at,
        m.is_deleted as lm_is_deleted
      FROM chats c
      INNER JOIN chat_members cm ON cm.chat_id = c.id AND cm.user_id = ? AND cm.is_active = 1
      -- Join to find the 'other' participant in 1:1 chats
      LEFT JOIN chat_members cm2 ON c.id = cm2.chat_id AND cm2.user_id != ? AND c.type = 'one_on_one'
      -- Robust join to user_profiles with fallback to metadata
      LEFT JOIN user_profiles p ON p.user_id = COALESCE(cm2.user_id, json_extract(c.metadata, '$.other_user_id'))
      -- Join to get the last message data directly
      LEFT JOIN (
        SELECT id, chat_id, type, text_content, sender_id, created_at, sent_at, is_deleted
        FROM chat_messages m1
        WHERE m1.created_at = (
          SELECT MAX(created_at) FROM chat_messages m2 WHERE m2.chat_id = m1.chat_id
        )
      ) m ON c.id = m.chat_id
      ORDER BY cm.is_pinned DESC, c.last_message_at DESC
    ''',
          parameters: [userId, userId],
        )
        .map((rows) {
          logI('watchChatList returned ${rows.length} rows');
          for (var r in rows) {
              logI('   -> Chat ID: ${r['id']} | is_active: ${r['is_active']} | role: ${r['member_role']} | type: ${r['type']}');
          }
          if (rows.isEmpty) {
            _powerSync.db.getAll('SELECT count(*) as count FROM chats').then((
              res,
            ) {
              logI('🔍 Debug: Total global chats: ${res.first['count']}');
            });
            _powerSync.db
                .getAll(
                  'SELECT count(*) as count FROM chat_members WHERE user_id = ?',
                  [userId],
                )
                .then((res) {
                  logI(
                    '🔍 Debug: Total memberships for user: ${res.first['count']}',
                  );
                });
          }
          final chats = rows.map((row) {
            final map = Map<String, dynamic>.from(row);

            // Map the flattened last message fields back into an object
            if (map['lm_id'] != null) {
              map['last_message_data'] = {
                'id': map['lm_id'],
                'chat_id': map['id'], // chat ID
                'type': map['lm_type'],
                'text_content': map['lm_text_content'],
                'sender_id': map['lm_sender_id'],
                'created_at': map['lm_created_at'],
                'sent_at': map['lm_sent_at'],
                'is_deleted': map['lm_is_deleted'] == 1,
              };
            }

            // For 1:1 chats, use the other user's name and avatar
            if (map['type'] == 'one_on_one') {
              final otherName = map['other_full_name'] ?? map['other_username'];
              if (otherName != null) {
                map['name'] = otherName;
              }
              if (map['other_avatar_url'] != null) {
                map['avatar'] = map['other_avatar_url'];
              }
              // crucial: other_user_id for online status and hydration
              if (map['other_user_id'] != null) {
                final meta = map['metadata'] is String
                    ? (jsonDecode(map['metadata']) as Map<String, dynamic>)
                    : (map['metadata'] as Map<String, dynamic>? ?? {});
                meta['other_user_id'] = map['other_user_id'];
                map['metadata'] = meta;
              }
            }
            return ChatModel.fromJson(map);
          }).toList();

          // Background hydration for missing profiles
          _hydrateProfiles(chats);

          return chats;
        });
  }

  /// Fetch chat rules from metadata
  Future<List<String>> getChatRules(String chatId) async {
    try {
      if (_powerSync.isReady) {
        final row = await _powerSync.db.getOptional('SELECT metadata FROM chats WHERE id = ?', [chatId]);
        if (row != null && row['metadata'] != null) {
          final meta = row['metadata'] is String 
              ? jsonDecode(row['metadata'] as String) as Map<String, dynamic>
              : row['metadata'] as Map<String, dynamic>;
          if (meta['rules'] != null) {
            return List<String>.from(meta['rules'] as List);
          }
        }
      }

      final data = await _supabase.from('chats').select('metadata').eq('id', chatId).maybeSingle();
      if (data != null && data['metadata'] != null) {
        final meta = data['metadata'] as Map<String, dynamic>;
        if (meta['rules'] != null) {
          return List<String>.from(meta['rules'] as List);
        }
      }
    } catch (e) {
      logE('Error fetching chat rules: $chatId', error: e);
    }
    return [];
  }

  /// Update chat rules in metadata
  Future<void> setChatRules(String chatId, List<String> rules) async {
    try {
      final data = await _supabase.from('chats').select('metadata').eq('id', chatId).single();
      final meta = Map<String, dynamic>.from(data['metadata'] as Map? ?? {});
      meta['rules'] = rules;

      await _supabase.from('chats').update({'metadata': meta}).eq('id', chatId);
      
      if (_powerSync.isReady) {
        await _powerSync.db.execute('UPDATE chats SET metadata = ? WHERE id = ?', [jsonEncode(meta), chatId]);
      }
    } catch (e) {
      logE('Error setting chat rules: $chatId', error: e);
      rethrow;
    }
  }

  /// Check if current user is admin
  Future<bool> isCurrentUserAdmin(String chatId) async {
    final userId = currentUserId;
    if (userId == null) return false;
    
    try {
      if (_powerSync.isReady) {
        final row = await _powerSync.db.getOptional(
          'SELECT role FROM chat_members WHERE chat_id = ? AND user_id = ?',
          [chatId, userId]
        );
        if (row != null) {
          final role = ChatMemberRole.fromString(row['role'] as String);
          return role.isAdmin;
        }
      }

      final data = await _supabase
          .from('chat_members')
          .select('role')
          .eq('chat_id', chatId)
          .eq('user_id', userId)
          .maybeSingle();
      
      if (data != null) {
        final role = ChatMemberRole.fromString(data['role'] as String);
        return role.isAdmin;
      }
    } catch (e) {
      logE('Error checking admin status: $chatId', error: e);
    }
    return false;
  }

  /// Trigger background profile fetch for chats with missing participant info
  void _hydrateProfiles(List<ChatModel> chats) {
    for (final chat in chats) {
      if (chat.type == ChatType.oneOnOne) {
        final otherId = chat.otherUserId;
        if (otherId != null &&
            (chat.otherUserFullName == null ||
                chat.otherUserFullName == 'Unknown' ||
                chat.otherUserFullName!.isEmpty)) {
          // Trigger profile fetch in background
          ProfileRepository().getProfileById(otherId).then((profile) async {
            if (profile != null) {
              logI('💧 Successfully fetched profile for hydration: ${profile.displayName} ($otherId)');
              try {
                // Use PowerSyncService.insert/update to ensure watchers are triggered and cache invalidated
                final exists = await _powerSync.exists('user_profiles', otherId);
                final profileData = profile.toLocalJson();
                
                if (exists) {
                   await _powerSync.update('user_profiles', profileData, otherId);
                } else {
                   await _powerSync.insert('user_profiles', profileData);
                }
                
                // Also update the chat metadata locally to cache the name/avatar
                // This ensures that even if the join on user_profiles is slow or fails,
                // the ChatModel will have the info in its metadata.
                final chatUpdateSql = '''
                  UPDATE chats 
                  SET metadata = json_patch(metadata, ?) 
                  WHERE id = ?
                ''';
                final metaPatch = jsonEncode({
                  'other_user_full_name': profile.displayName,
                  'other_username': profile.username,
                  'other_avatar_url': profile.profileUrl,
                });
                await _powerSync.execute(chatUpdateSql, [metaPatch, chat.id]);
                
                logI('✅ Hydration successful for: ${profile.displayName}');
              } catch (e) {
                logE('❌ Hydration error', error: e);
              }
            } else {
               logW('⚠️ Hydration failed: Profile not found for $otherId');
            }
          });
        }
      }
    }
  }

  Stream<int> watchTotalUnreadCount() {
    if (currentUserId == null || !_powerSync.isReady) return Stream.value(0);
    return _powerSync.db
        .watch(
          r'SELECT SUM(unread_count) as total FROM chat_members WHERE user_id = ? AND is_active = 1',
          parameters: [currentUserId],
        )
        .map((rows) {
          if (rows.isEmpty) return 0;
          return (rows.first['total'] as num?)?.toInt() ?? 0;
        });
  }

  Future<int> getTotalUnreadCount(String userId) async {
    if (!_powerSync.isReady) return 0;
    try {
      final res = await _powerSync.db.getOptional(
        r'SELECT SUM(unread_count) as total FROM chat_members WHERE user_id = ? AND is_active = 1',
        [userId],
      );
      if (res == null) return 0;
      return (res['total'] as num?)?.toInt() ?? 0;
    } catch (e) {
      logW('Error getting total unread count: $e');
      return 0;
    }
  }

  // ----------------------------------------------------------------------
  // CHAT CREATION
  // ----------------------------------------------------------------------

  Future<ChatResult<String>> getOrCreateDirectChat(String otherUserId) async {
    if (currentUserId == null) return ChatResult.fail('Not authenticated');

    try {
      final chatId = await _supabase.rpc<String>(
        'get_or_create_direct_chat',
        params: {'p_user1_id': currentUserId, 'p_user2_id': otherUserId},
      );
      return ChatResult.success(chatId);
    } catch (e) {
      return ChatResult.fail(e.toString());
    }
  }

  Future<ChatResult<String>> createGroupChat({
    required String name,
    required List<String> memberUserIds,
    String? avatar,
    String? description,
  }) async {
    if (currentUserId == null) return ChatResult.fail('Not authenticated');

    try {
      final chatId = await _supabase.rpc<String>(
        'create_group_chat',
        params: {
          'p_creator_id': currentUserId,
          'p_name': name,
          'p_member_ids': memberUserIds,
          'p_avatar': avatar,
          'p_description': description,
        },
      );

      return ChatResult.success(chatId);
    } catch (e) {
      return ChatResult.fail(e.toString());
    }
  }

  Future<ChatResult<String>> createCommunityChat({
    required String name,
    required String categoryId,
    String? avatar,
    String? banner,
    String? description,
    bool requireApproval = false,
    List<String>? rules,
    ChatVisibility visibility = ChatVisibility.public,
  }) async {
    if (currentUserId == null) return ChatResult.fail('Not authenticated');

    try {
      // 1. Create the chat record
      final chatData = {
        'type': 'community',
        'name': name,
        'description': description,
        'avatar': avatar,
        'visibility': visibility.toJson(),
        'created_by': currentUserId,
        'who_can_send': 'all', // default
        'who_can_add_members': requireApproval ? 'admins' : 'all',
        'metadata': {
          'category_id': categoryId,
          'require_approval': requireApproval,
          'rules': rules ?? [],
          'banner': banner,
        },
        'total_members': 1,
        'last_message_at': DateTime.now().toUtc().toIso8601String(),
      };

      final chat = await _supabase
          .from('chats')
          .insert(chatData)
          .select()
          .single();

      final chatId = chat['id'] as String;

      // 2. Add the creator as an admin/owner
      await _supabase.from('chat_members').insert({
        'chat_id': chatId,
        'user_id': currentUserId,
        'role': 'owner',
        'is_active': true,
        'unread_count': 0,
        'joined_at': DateTime.now().toUtc().toIso8601String(),
      });

      return ChatResult.success(chatId);
    } catch (e) {
      logE('Error creating community', error: e);
      return ChatResult.fail(e.toString());
    }
  }

  Future<ChatResult<String>> sendSharedContent({
    required String chatId,
    required SharedContentType contentType,
    required String contentId, // Changed from dynamic content to String contentId
    String? caption,
    String mode = 'live',
  }) async {
    final userId = currentUserId;
    if (userId == null) return ChatResult.fail('Not authenticated');

    try {
      final messageId = const Uuid().v4();
      final now = DateTime.now().toUtc().toIso8601String();

      if (_powerSync.isReady) {
        await _powerSync.db.execute(
          '''
          INSERT INTO chat_messages (
            id, chat_id, sender_id, type, text_content, 
            shared_content_type, shared_content_id, shared_content_mode,
            sent_at, created_at, updated_at, status
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'sent')
          ''',
          [
            messageId,
            chatId,
            userId,
            ChatMessageType.sharedContent.toJson(),
            caption,
            contentType.toJson(),
            contentId,
            mode,
            now,
            now,
            now,
          ],
        );
      }

      // Remote insert via RPC to ensure all triggers/logic are executed
      await _supabase.rpc('share_content_in_chat', params: {
        'p_chat_id': chatId,
        'p_sender_id': userId,
        'p_content_type': contentType.toJson(),
        'p_content_id': contentId,
        'p_mode': mode,
        'p_text_content': caption,
      });

      return ChatResult.success(messageId);
    } catch (e) {
      logE('sendSharedContent error', error: e);
      return ChatResult.fail(e.toString());
    }
  }

  Future<ChatResult<void>> addMembers(
    String chatId,
    List<String> userIds,
  ) async {
    if (currentUserId == null) return ChatResult.fail('Not authenticated');

    try {
      final rows = userIds
          .map(
            (uid) => {
              'chat_id': chatId,
              'user_id': uid,
              'role': 'member', // Default role
              // 'is_active': true, // Default should be true in DB
            },
          )
          .toList();

      await _supabase.from('chat_members').insert(rows);
      return ChatResult.success(null);
    } catch (e) {
      return ChatResult.fail(e.toString());
    }
  }

  // ----------------------------------------------------------------------
  // CHAT DETAILS
  // ----------------------------------------------------------------------

  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final result = await _powerSync.querySingle(
        r'''
      SELECT 
        c.id, 
        c.type, 
        c.name, 
        c.avatar, 
        c.description,
        c.visibility,
        c.who_can_send,
        c.who_can_add_members,
        c.disappearing_messages,
        c.disappearing_duration,
        c.metadata,
        c.total_members,
        c.last_message_at,
        c.created_by,
        c.created_at,
        c.updated_at,
        -- Join with chat_members for user-specific fields
        cm.role as member_role,
        cm.is_pinned,
        cm.is_muted,
        cm.is_archived,
        cm.unread_count,
        cm.unread_mentions,
        COALESCE(cm2.user_id, json_extract(c.metadata, '$.other_user_id')) as other_user_id,
        COALESCE(p.display_name, json_extract(c.metadata, '$.other_user_full_name')) as other_full_name,
        COALESCE(p.username, json_extract(c.metadata, '$.other_username')) as other_username,
        COALESCE(p.profile_url, json_extract(c.metadata, '$.other_avatar_url')) as other_avatar_url
      FROM chats c
      LEFT JOIN chat_members cm ON cm.chat_id = c.id AND cm.user_id = ?
      -- Join to find the 'other' participant in 1:1 chats
      LEFT JOIN chat_members cm2 ON c.id = cm2.chat_id AND cm2.user_id != ? AND c.type = 'one_on_one'
      -- Robust join to user_profiles with fallback to metadata
      LEFT JOIN user_profiles p ON p.user_id = COALESCE(cm2.user_id, json_extract(c.metadata, '$.other_user_id'))
      WHERE c.id = ?
    ''',
        parameters: [currentUserId, currentUserId, chatId],
      );

      if (result != null) {
        final map = _convertBooleans(result);
        if (map['type'] == 'one_on_one') {
          final otherName = map['other_full_name'] ?? map['other_username'];
          if (otherName != null) {
            map['name'] = otherName;
          }
          if (map['other_avatar_url'] != null) {
            map['avatar'] = map['other_avatar_url'];
          }
          // Crucial: other_user_id
          if (map['other_user_id'] != null) {
            final meta = map['metadata'] is String
                ? (jsonDecode(map['metadata']) as Map<String, dynamic>)
                : (map['metadata'] as Map<String, dynamic>? ?? {});
            meta['other_user_id'] = map['other_user_id'];
            map['metadata'] = meta;
          }
        }
        return ChatModel.fromJson(map);
      }

      if (currentUserId == null) return null;

      final remote = await _supabase
          .from('chats')
          .select('''
            *,
            chat_members!inner(*)
          ''')
          .eq('id', chatId)
          .eq('chat_members.user_id', currentUserId!)
          .maybeSingle();

      if (remote == null) return null;

      final map = Map<String, dynamic>.from(remote);
      final members = map['chat_members'] as List?;
      if (members != null && members.isNotEmpty) {
        final m = Map<String, dynamic>.from(members.first as Map);
        map['member_role'] = m['role'];
        map['is_pinned'] = m['is_pinned'];
        map['is_muted'] = m['is_muted'];
        map['is_archived'] = m['is_archived'];
        map['unread_count'] = m['unread_count'];
        map['unread_mentions'] = m['unread_mentions'];
      }
      map.remove('chat_members');

      // Manual fallback fetch for 1:1 chat other user
      if (map['type'] == 'one_on_one') {
        try {
          final otherMember = await _supabase
              .from('chat_members')
              .select('user_id')
              .eq('chat_id', chatId)
              .neq('user_id', currentUserId!)
              .limit(1)
              .maybeSingle();

          if (otherMember != null) {
            final otherUserId = otherMember['user_id'] as String;

            // Fetch profile
            final profile = await _supabase
                .from('user_profiles')
                .select('username, profile_url')
                .eq('user_id', otherUserId)
                .maybeSingle();

            if (profile != null) {
              map['name'] = profile['username'];
              map['avatar'] = profile['profile_url'];

              // Also ensure metadata has other_user_id
              final metadata = map['metadata'] as Map<String, dynamic>? ?? {};
              metadata['other_user_id'] = otherUserId;
              map['metadata'] = metadata;
            }
          }
        } catch (e) {
          logE('Error fetching other user profile (fallback)', error: e);
        }
      }

      return ChatModel.fromJson(_convertBooleans(map));
    } catch (e) {
      logE('Error fetching chat $chatId', error: e);
      return null;
    }
  }

  Stream<ChatModel?> watchChat(String chatId) {
    if (currentUserId == null) return Stream.value(null);
    return _powerSync
        .watchQuery(
          r'''
      SELECT 
        c.id, 
        c.type, 
        c.name, 
        c.avatar, 
        c.description,
        c.visibility,
        c.who_can_send,
        c.who_can_add_members,
        c.disappearing_messages,
        c.disappearing_duration,
        c.metadata,
        c.total_members,
        c.last_message_at,
        c.created_by,
        c.created_at,
        c.updated_at,
        -- Join with chat_members for user-specific fields
        cm.role as member_role,
        cm.is_pinned,
        cm.is_muted,
        cm.is_archived,
        cm.unread_count,
        cm.unread_mentions,
        COALESCE(cm2.user_id, json_extract(c.metadata, '$.other_user_id')) as other_user_id,
        COALESCE(p.display_name, json_extract(c.metadata, '$.other_user_full_name')) as other_full_name,
        COALESCE(p.username, json_extract(c.metadata, '$.other_username')) as other_username,
        COALESCE(p.profile_url, json_extract(c.metadata, '$.other_avatar_url')) as other_avatar_url
      FROM chats c
      LEFT JOIN chat_members cm ON cm.chat_id = c.id AND cm.user_id = ?
      -- Join to find the 'other' participant in 1:1 chats
      LEFT JOIN chat_members cm2 ON c.id = cm2.chat_id AND cm2.user_id != ? AND c.type = 'one_on_one'
      -- Robust join to user_profiles with fallback to metadata
      LEFT JOIN user_profiles p ON p.user_id = COALESCE(cm2.user_id, json_extract(c.metadata, '$.other_user_id'))
      WHERE c.id = ?
    ''',
          parameters: [currentUserId, currentUserId, chatId],
        )
        .map((rows) {
          if (rows.isEmpty) return null;
          final map = _convertBooleans(Map<String, dynamic>.from(rows.first));
          if (map['type'] == 'one_on_one') {
            final otherName = map['other_full_name'] ?? map['other_username'];
            if (otherName != null) {
              map['name'] = otherName;
            }
            if (map['other_avatar_url'] != null) {
              map['avatar'] = map['other_avatar_url'];
            }
            if (map['other_user_id'] != null) {
              final meta = map['metadata'] is String
                  ? (jsonDecode(map['metadata']) as Map<String, dynamic>)
                  : (map['metadata'] as Map<String, dynamic>? ?? {});
              meta['other_user_id'] = map['other_user_id'];
              map['metadata'] = meta;
            }
          }
          return ChatModel.fromJson(map);
        });
  }

  // ----------------------------------------------------------------------
  // HELPERS
  // ----------------------------------------------------------------------

  Map<String, dynamic> _convertBooleans(Map<String, dynamic> data) {
    final converted = Map<String, dynamic>.from(data);
    const boolFields = [
      'disappearing_messages',
      'is_pinned',
      'is_muted',
      'is_archived',
      'is_edited',
      'is_deleted',
    ];
    for (final field in boolFields) {
      if (converted.containsKey(field) && converted[field] is int) {
        converted[field] = converted[field] == 1;
      }
    }
    return converted;
  }

  // ----------------------------------------------------------------------
  // COMMUNITY DISCOVERY
  // ----------------------------------------------------------------------

  /// Fetch public communities with optional category and search filtering
  Future<List<ChatModel>> getPublicCommunities({
    String? categoryId,
    String? query,
    int limit = 20,
    String? sortBy = 'total_members', // 'total_members' or 'created_at'
  }) async {
    try {
      if (_powerSync.isReady) {
        String sql = "SELECT * FROM chats WHERE type = 'community' AND visibility = 'public'";
        List<dynamic> params = [];

        if (categoryId != null) {
          sql += " AND json_extract(metadata, '\$.category_id') = ?";
          params.add(categoryId);
        }

        if (query != null && query.isNotEmpty) {
          sql += " AND (name LIKE ? OR description LIKE ?)";
          params.add('%$query%');
          params.add('%$query%');
        }

        if (sortBy == 'total_members') {
          sql += " ORDER BY total_members DESC";
        } else {
          sql += " ORDER BY created_at DESC";
        }

        sql += " LIMIT ?";
        params.add(limit);

        final rows = await _powerSync.db.getAll(sql, params);
        return rows.map((row) => ChatModel.fromJson(_convertBooleans(Map<String, dynamic>.from(row)))).toList();
      }

      // Remote fallback if PowerSync is not ready or for deep search
      dynamic supabaseQuery = _supabase
          .from('chats')
          .select()
          .eq('type', 'community')
          .eq('visibility', 'public');

      if (categoryId != null) {
        supabaseQuery = supabaseQuery.eq('metadata->>category_id', categoryId);
      }

      if (query != null && query.isNotEmpty) {
        supabaseQuery = supabaseQuery.or('name.ilike.%$query%,description.ilike.%$query%');
      }

      if (sortBy == 'total_members') {
        supabaseQuery = supabaseQuery.order('total_members', ascending: false);
      } else {
        supabaseQuery = supabaseQuery.order('created_at', ascending: false);
      }

      final data = await supabaseQuery.limit(limit);
      return (data as List).map((json) => ChatModel.fromJson(_convertBooleans(Map<String, dynamic>.from(json)))).toList();
    } catch (e) {
      logE('Error fetching public communities', error: e);
      return [];
    }
  }

  /// Fetch trending communities (most members)
  Future<List<ChatModel>> getTrendingCommunities({int limit = 10}) async {
    return getPublicCommunities(limit: limit, sortBy: 'total_members');
  }

  /// Fetch featured communities (using specialized flag or high member count)
  Future<List<ChatModel>> getFeaturedCommunities({int limit = 5}) async {
    // For now, featured = trending among ones that have a banner
    try {
      if (_powerSync.isReady) {
        final rows = await _powerSync.db.getAll(
          "SELECT * FROM chats WHERE type = 'community' AND visibility = 'public' AND json_extract(metadata, '\$.banner') IS NOT NULL ORDER BY total_members DESC LIMIT ?",
          [limit]
        );
        if (rows.isNotEmpty) {
          return rows.map((row) => ChatModel.fromJson(_convertBooleans(Map<String, dynamic>.from(row)))).toList();
        }
      }
      return getTrendingCommunities(limit: limit);
    } catch (e) {
      return getTrendingCommunities(limit: limit);
    }
  }

  /// Fetch new and upcoming communities
  Future<List<ChatModel>> getNewCommunities({int limit = 10}) async {
    return getPublicCommunities(limit: limit, sortBy: 'created_at');
  }

  /// Join a public community
  Future<ChatResult<void>> joinCommunity(String chatId) async {
    final userId = currentUserId;
    if (userId == null) return ChatResult.fail('Not authenticated');

    try {
      await _supabase.from('chat_members').insert({
        'chat_id': chatId,
        'user_id': userId,
        'role': 'member',
        'is_active': true,
        'joined_at': DateTime.now().toUtc().toIso8601String(),
      });
      return ChatResult.success(null);
    } catch (e) {
      logE('Error joining community', error: e);
      return ChatResult.fail(e.toString());
    }
  }

  // ----------------------------------------------------------------------
  // CHAT UPDATES
  // ----------------------------------------------------------------------

  Future<void> updateChatInfo({
    required String chatId,
    String? name,
    String? description,
    String? avatar,
    String? banner,
    ChatVisibility? visibility,
  }) async {
    final updates = <String, dynamic>{'updated_at': DateTime.now().toUtc().toIso8601String()};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (avatar != null) updates['avatar'] = avatar;
    if (visibility != null) updates['visibility'] = visibility.toJson();

    if (banner != null) {
      final currentChatData = await _supabase.from('chats').select('metadata').eq('id', chatId).single();
      final meta = Map<String, dynamic>.from(currentChatData['metadata'] as Map? ?? {});
      meta['banner'] = banner;
      updates['metadata'] = meta;
    }

    await _supabase.from('chats').update(updates).eq('id', chatId);
  }

  Future<void> updateChatMetadata(String chatId, Map<String, dynamic> metadata) async {
    try {
      // 1. Remote update
      await _supabase.from('chats').update({'metadata': metadata}).eq('id', chatId);
      
      // 2. Local update for immediate UI feedback
      if (_powerSync.isReady) {
        await _powerSync.db.execute(
          'UPDATE chats SET metadata = ? WHERE id = ?', 
          [jsonEncode(metadata), chatId]
        );
      }
    } catch (e) {
      logE('Error updating chat metadata: $chatId', error: e);
      rethrow;
    }
  }
}
