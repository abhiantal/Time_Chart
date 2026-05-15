// ================================================================
// FILE: lib/features/mentoring/repositories/mentorship_repository.dart
// Repository for mentorship_connections table
// ================================================================

import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../../../../../services/powersync_service.dart';
import '../../../../../services/supabase_service.dart';
import '../../../../../widgets/error_handler.dart';
import '../../../../../widgets/logger.dart';
import 'package:the_time_chart/user_profile/create_edit_profile/profile_models.dart';
import 'package:the_time_chart/user_profile/create_edit_profile/profile_repository.dart';

import '../models/mentorship_model.dart';

class MentorshipRepository {
  final _powerSync = PowerSyncService();
  static const String _tableName = 'mentorship_connections';

  // Singleton
  static final MentorshipRepository _instance =
      MentorshipRepository._internal();
  factory MentorshipRepository() => _instance;
  MentorshipRepository._internal();

  String get currentUserId => _powerSync.currentUserId ?? '';

  final _jsonbColumns = [
    'allowed_screens',
    'permissions',
    'cached_snapshot',
    'last_notified',
  ];

  // ================================================================
  // CREATE OPERATIONS
  // ================================================================

  /// Create a new access request (mentor requests to see owner's data)
  Future<MentorshipConnection?> createAccessRequest(
    MentorshipConnection connection,
  ) async {
    try {
      logI(
        '📝 Creating access request: ${connection.mentorId} → ${connection.ownerId}',
      );

      final data = connection.toInsertJson();
      data['id'] = const Uuid().v4();
      data['request_type'] = RequestType.requestAccess.value;
      data['request_status'] = RequestStatus.pending.value;
      data['access_status'] = AccessStatus.inactive.value;
      data['requested_at'] = DateTime.now().toIso8601String();

      final processedData = _processJsonbFields(data);
      await _powerSync.insert(_tableName, processedData);

      logI('✅ Access request created: ${data['id']}');
      ErrorHandler.showSuccessSnackbar('Access request sent successfully');

      return connection.copyWith(id: data['id']);
    } catch (e, stack) {
      logE('❌ Error creating access request', error: e, stackTrace: stack);
      ErrorHandler.showErrorSnackbar('Failed to send access request');
      return null;
    }
  }

  /// Create a share offer (owner offers to share with mentor)
  Future<MentorshipConnection?> createShareOffer(
    MentorshipConnection connection,
  ) async {
    try {
      logI(
        '📤 Creating share offer: ${connection.ownerId} → ${connection.mentorId}',
      );

      final now = DateTime.now();
      final data = connection.toInsertJson();
      data['id'] = const Uuid().v4();
      data['request_type'] = RequestType.offerShare.value;
      data['request_status'] = RequestStatus.approved.value;
      data['access_status'] = AccessStatus.active.value;
      data['requested_at'] = now.toIso8601String();
      data['responded_at'] = now.toIso8601String();
      data['starts_at'] = now.toIso8601String();

      // Calculate expiration
      final duration = AccessDuration.fromString(data['duration'] as String?);
      final expiresAt = duration.calculateExpiresAt(now);
      if (expiresAt != null) {
        data['expires_at'] = expiresAt.toIso8601String();
      }

      final processedData = _processJsonbFields(data);
      await _powerSync.insert(_tableName, processedData);

      logI('✅ Share offer created: ${data['id']}');
      ErrorHandler.showSuccessSnackbar('Access shared successfully');

      return connection.copyWith(
        id: data['id'],
        requestStatus: RequestStatus.approved,
        accessStatus: AccessStatus.active,
        startsAt: now,
        expiresAt: expiresAt,
      );
    } catch (e, stack) {
      logE('❌ Error creating share offer', error: e, stackTrace: stack);
      ErrorHandler.showErrorSnackbar('Failed to share access');
      return null;
    }
  }

  // ================================================================
  // READ OPERATIONS
  // ================================================================

  /// Get connection by ID
  Future<MentorshipConnection?> getById(String connectionId) async {
    try {
      if (connectionId.isEmpty) {
        logW('⚠️ getById called with empty ID');
        return null;
      }

      final result = await _powerSync.executeQuery(
        'SELECT * FROM $_tableName WHERE id = ? LIMIT 1',
        parameters: [connectionId],
      );

      Map<String, dynamic> rawData;

      if (result.isEmpty) {
        logI(
          '🔍 Connection $connectionId not found locally, checking Supabase...',
        );
        final supabase = SupabaseService();
        if (!supabase.isInitialized) return null;

        final remoteResult = await supabase.client
            .from(_tableName)
            .select()
            .eq('id', connectionId)
            .maybeSingle();

        if (remoteResult == null) return null;
        rawData = remoteResult;
      } else {
        rawData = result.first;
      }

      final parsed = _parseJsonbFields(rawData);
      return MentorshipConnection.fromJson(parsed);
    } catch (e, stack) {
      logE('❌ Error getting connection by ID', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Get my mentors (people who can view my data - I am owner)
  Future<List<MentorshipConnection>> getMyMentors(String userId) async {
    try {
      if (userId.isEmpty) {
        logW('⚠️ getMyMentors called with empty userId');
        return [];
      }

      logI('📥 Fetching mentors for user: $userId');

      final results = await _powerSync.executeQuery(
        '''
        SELECT * FROM $_tableName 
        WHERE owner_id = ? 
        AND request_status = 'approved'
        ORDER BY updated_at DESC
        ''',
        parameters: [userId],
      );

      final connections = results.map((row) {
        final parsed = _parseJsonbFields(row);
        return MentorshipConnection.fromJson(parsed);
      }).toList();

      logI('✅ Fetched ${connections.length} mentors');
      return connections;
    } catch (e, stack) {
      logE('❌ Error fetching mentors', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get my mentees (people whose data I can view - I am mentor)
  Future<List<MentorshipConnection>> getMyMentees(String userId) async {
    try {
      if (userId.isEmpty) {
        logW('⚠️ getMyMentees called with empty userId');
        return [];
      }

      logI('📥 Fetching mentees for user: $userId');

      final results = await _powerSync.executeQuery(
        '''
        SELECT * FROM $_tableName 
        WHERE mentor_id = ? 
        AND request_status = 'approved'
        ORDER BY updated_at DESC
        ''',
        parameters: [userId],
      );

      final connections = results.map((row) {
        final parsed = _parseJsonbFields(row);
        return MentorshipConnection.fromJson(parsed);
      }).toList();

      logI('✅ Fetched ${connections.length} mentees');
      return connections;
    } catch (e, stack) {
      logE('❌ Error fetching mentees', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get incoming requests (pending requests where I am owner)
  Future<List<MentorshipConnection>> getIncomingRequests(
    String userId, {
    RequestStatus? status,
  }) async {
    try {
      if (userId.isEmpty) {
        logW('⚠️ getIncomingRequests called with empty userId');
        return [];
      }

      logI('📥 Fetching incoming requests for user: $userId');

      final String statusClause = status != null
          ? "AND request_status = '${status.value}'"
          : "";
      final results = await _powerSync.executeQuery(
        '''
        SELECT * FROM $_tableName 
        WHERE owner_id = ? 
        $statusClause
        AND request_type = 'request_access'
        ORDER BY requested_at DESC
        ''',
        parameters: [userId],
      );

      final connections = results.map((row) {
        final parsed = _parseJsonbFields(row);
        return MentorshipConnection.fromJson(parsed);
      }).toList();

      logI('✅ Fetched ${connections.length} incoming requests');
      return connections;
    } catch (e, stack) {
      logE('❌ Error fetching incoming requests', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get outgoing requests (pending requests where I am mentor)
  Future<List<MentorshipConnection>> getOutgoingRequests(
    String userId, {
    RequestStatus? status,
  }) async {
    try {
      if (userId.isEmpty) {
        logW('⚠️ getOutgoingRequests called with empty userId');
        return [];
      }

      logI('📥 Fetching outgoing requests for user: $userId');

      final String statusClause = status != null
          ? "AND request_status = '${status.value}'"
          : "";
      final results = await _powerSync.executeQuery(
        '''
        SELECT * FROM $_tableName 
        WHERE mentor_id = ? 
        $statusClause
        AND request_type = 'request_access'
        ORDER BY requested_at DESC
        ''',
        parameters: [userId],
      );

      final connections = results.map((row) {
        final parsed = _parseJsonbFields(row);
        return MentorshipConnection.fromJson(parsed);
      }).toList();

      logI('✅ Fetched ${connections.length} outgoing requests');
      return connections;
    } catch (e, stack) {
      logE('❌ Error fetching outgoing requests', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get pending offers to me (where I am mentor and owner offered)
  Future<List<MentorshipConnection>> getPendingOffersToMe(String userId) async {
    try {
      if (userId.isEmpty) return [];

      final results = await _powerSync.executeQuery(
        '''
        SELECT * FROM $_tableName 
        WHERE mentor_id = ? 
        AND request_status = 'pending'
        AND request_type = 'offer_share'
        ORDER BY requested_at DESC
        ''',
        parameters: [userId],
      );

      return results.map((row) {
        final parsed = _parseJsonbFields(row);
        return MentorshipConnection.fromJson(parsed);
      }).toList();
    } catch (e, stack) {
      logE('❌ Error fetching pending offers', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get active connection for a specific pair
  Future<MentorshipConnection?> getActiveConnectionForPair(
    String ownerId,
    String mentorId,
  ) async {
    try {
      if (ownerId.isEmpty || mentorId.isEmpty) return null;

      final result = await _powerSync.executeQuery(
        '''
        SELECT * FROM $_tableName 
        WHERE owner_id = ? 
        AND mentor_id = ?
        AND access_status = 'active'
        LIMIT 1
        ''',
        parameters: [ownerId, mentorId],
      );

      Map<String, dynamic> rawData;

      if (result.isEmpty) {
        logI(
          '🔍 Active connection for pair ($ownerId, $mentorId) not found locally, checking Supabase...',
        );
        final supabase = SupabaseService();
        if (!supabase.isInitialized) return null;

        final remoteResult = await supabase.client
            .from(_tableName)
            .select()
            .eq('owner_id', ownerId)
            .eq('mentor_id', mentorId)
            .eq('access_status', 'active')
            .maybeSingle();

        if (remoteResult == null) return null;
        rawData = remoteResult;
      } else {
        rawData = result.first;
      }

      final parsed = _parseJsonbFields(rawData);
      return MentorshipConnection.fromJson(parsed);
    } catch (e, stack) {
      logE('❌ Error getting connection for pair', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Get any connection for a specific pair (active or not)
  Future<MentorshipConnection?> getConnectionForPair(
    String ownerId,
    String mentorId,
  ) async {
    try {
      if (ownerId.isEmpty || mentorId.isEmpty) return null;

      final result = await _powerSync.executeQuery(
        '''
        SELECT * FROM $_tableName 
        WHERE owner_id = ? 
        AND mentor_id = ?
        LIMIT 1
        ''',
        parameters: [ownerId, mentorId],
      );

      if (result.isEmpty) return null;

      final parsed = _parseJsonbFields(result.first);
      return MentorshipConnection.fromJson(parsed);
    } catch (e, stack) {
      logE('❌ Error getting connection for pair', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Get mentorship leaderboard for a user
  Future<Map<String, int>> getStats(String userId) async {
    try {
      if (userId.isEmpty) return {};

      final results = await _powerSync.executeQuery(
        '''
        SELECT 
          COUNT(*) FILTER (WHERE owner_id = ? AND request_status = 'approved') as total_mentors,
          COUNT(*) FILTER (WHERE owner_id = ? AND access_status = 'active') as active_mentors,
          COUNT(*) FILTER (WHERE owner_id = ? AND request_status = 'pending' AND request_type = 'request_access') as pending_incoming,
          COUNT(*) FILTER (WHERE mentor_id = ? AND request_status = 'approved') as total_mentees,
          COUNT(*) FILTER (WHERE mentor_id = ? AND access_status = 'active') as active_mentees,
          COUNT(*) FILTER (WHERE mentor_id = ? AND request_status = 'pending' AND request_type = 'request_access') as pending_outgoing,
          COUNT(*) FILTER (WHERE mentor_id = ? AND request_status = 'pending' AND request_type = 'offer_share') as pending_offers
        FROM $_tableName
        WHERE owner_id = ? OR mentor_id = ?
        ''',
        parameters: [
          userId,
          userId,
          userId,
          userId,
          userId,
          userId,
          userId,
          userId,
          userId,
        ],
      );

      if (results.isEmpty) return {};

      final row = results.first;
      return {
        'total_mentors': _parseInt(row['total_mentors']),
        'active_mentors': _parseInt(row['active_mentors']),
        'pending_incoming': _parseInt(row['pending_incoming']),
        'total_mentees': _parseInt(row['total_mentees']),
        'active_mentees': _parseInt(row['active_mentees']),
        'pending_outgoing': _parseInt(row['pending_outgoing']),
        'pending_offers': _parseInt(row['pending_offers']),
      };
    } catch (e, stack) {
      logE('❌ Error fetching leaderboard', error: e, stackTrace: stack);
      return {};
    }
  }

  // ================================================================
  // UPDATE OPERATIONS
  // ================================================================

  /// Update a connection
  Future<MentorshipConnection?> update(MentorshipConnection connection) async {
    try {
      if (connection.id.isEmpty) {
        logW('⚠️ update called with empty ID');
        return null;
      }

      logI('🔄 Updating connection: ${connection.id}');

      final data = connection.toJson();
      data.remove('created_at');
      data['updated_at'] = DateTime.now().toIso8601String();

      final processedData = _processJsonbFields(data);
      await _powerSync.update(_tableName, processedData, connection.id);

      logI('✅ Connection updated');
      return connection.copyWith(updatedAt: DateTime.now());
    } catch (e, stack) {
      logE('❌ Error updating connection', error: e, stackTrace: stack);
      ErrorHandler.showErrorSnackbar('Failed to update connection');
      return null;
    }
  }

  /// Approve a request
  Future<bool> approveRequest(
    String connectionId, {
    MentorshipPermissions? customPermissions,
    List<AccessibleScreen>? customScreens,
    String? responseMessage,
  }) async {
    try {
      if (connectionId.isEmpty) {
        logW('⚠️ approveRequest called with empty ID');
        return false;
      }

      logI('✅ Approving request: $connectionId');

      final connection = await getById(connectionId);
      if (connection == null) {
        ErrorHandler.showErrorSnackbar('Connection not found');
        return false;
      }

      if (connection.ownerId != currentUserId) {
        ErrorHandler.showErrorSnackbar('Only the owner can approve requests');
        return false;
      }

      if (connection.requestStatus != RequestStatus.pending) {
        ErrorHandler.showErrorSnackbar('Can only approve pending requests');
        return false;
      }

      final now = DateTime.now();
      final expiresAt = connection.duration.calculateExpiresAt(now);

      final data = <String, dynamic>{
        'request_status': RequestStatus.approved.value,
        'access_status': AccessStatus.active.value,
        'responded_at': now.toIso8601String(),
        'starts_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      if (expiresAt != null) {
        data['expires_at'] = expiresAt.toIso8601String();
      }

      if (responseMessage != null) {
        data['response_message'] = responseMessage;
      }

      if (customPermissions != null) {
        data['permissions'] = jsonEncode(customPermissions.toJson());
      }

      if (customScreens != null) {
        data['allowed_screens'] = jsonEncode(
          AllowedScreens(screens: customScreens).toJson(),
        );
      }

      await _powerSync.update(_tableName, data, connectionId);

      logI('✅ Request approved');
      ErrorHandler.showSuccessSnackbar('Request approved successfully');
      return true;
    } catch (e, stack) {
      logE('❌ Error approving request', error: e, stackTrace: stack);
      ErrorHandler.showErrorSnackbar('Failed to approve request');
      return false;
    }
  }

  /// Reject a request
  Future<bool> rejectRequest(
    String connectionId, {
    String? responseMessage,
  }) async {
    try {
      if (connectionId.isEmpty) {
        logW('⚠️ rejectRequest called with empty ID');
        return false;
      }

      logI('❌ Rejecting request: $connectionId');

      final connection = await getById(connectionId);
      if (connection == null) {
        ErrorHandler.showErrorSnackbar('Connection not found');
        return false;
      }

      if (connection.ownerId != currentUserId) {
        ErrorHandler.showErrorSnackbar('Only the owner can reject requests');
        return false;
      }

      if (connection.requestStatus != RequestStatus.pending) {
        ErrorHandler.showErrorSnackbar('Can only reject pending requests');
        return false;
      }

      final now = DateTime.now();
      final data = <String, dynamic>{
        'request_status': RequestStatus.rejected.value,
        'access_status': AccessStatus.inactive.value,
        'responded_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      if (responseMessage != null) {
        data['response_message'] = responseMessage;
      }

      await _powerSync.update(_tableName, data, connectionId);

      logI('✅ Request rejected');
      ErrorHandler.showSuccessSnackbar('Request rejected');
      return true;
    } catch (e, stack) {
      logE('❌ Error rejecting request', error: e, stackTrace: stack);
      ErrorHandler.showErrorSnackbar('Failed to reject request');
      return false;
    }
  }

  /// Cancel a request (by the requester)
  Future<bool> cancelRequest(String connectionId) async {
    try {
      if (connectionId.isEmpty) {
        logW('⚠️ cancelRequest called with empty ID');
        return false;
      }

      logI('🚫 Cancelling request: $connectionId');

      final connection = await getById(connectionId);
      if (connection == null) {
        ErrorHandler.showErrorSnackbar('Connection not found');
        return false;
      }

      if (connection.mentorId != currentUserId) {
        ErrorHandler.showErrorSnackbar('Only the requester can cancel');
        return false;
      }

      if (connection.requestStatus != RequestStatus.pending) {
        ErrorHandler.showErrorSnackbar('Can only cancel pending requests');
        return false;
      }

      await _powerSync.update(_tableName, {
        'request_status': RequestStatus.cancelled.value,
        'updated_at': DateTime.now().toIso8601String(),
      }, connectionId);

      logI('✅ Request cancelled');
      ErrorHandler.showSuccessSnackbar('Request cancelled');
      return true;
    } catch (e, stack) {
      logE('❌ Error cancelling request', error: e, stackTrace: stack);
      ErrorHandler.showErrorSnackbar('Failed to cancel request');
      return false;
    }
  }

  /// Revoke access
  Future<bool> revokeAccess(String connectionId) async {
    try {
      if (connectionId.isEmpty) {
        logW('⚠️ revokeAccess called with empty ID');
        return false;
      }

      logI('⛔ Revoking access: $connectionId');

      final connection = await getById(connectionId);
      if (connection == null) {
        ErrorHandler.showErrorSnackbar('Connection not found');
        return false;
      }

      // Both the owner and the mentor can revoke access
      if (connection.ownerId != currentUserId &&
          connection.mentorId != currentUserId) {
        ErrorHandler.showErrorSnackbar('Only participants can revoke access');
        return false;
      }

      await _powerSync.update(_tableName, {
        'access_status': AccessStatus.revoked.value,
        'updated_at': DateTime.now().toIso8601String(),
      }, connectionId);

      logI('✅ Access revoked');
      ErrorHandler.showSuccessSnackbar('Access revoked');
      return true;
    } catch (e, stack) {
      logE('❌ Error revoking access', error: e, stackTrace: stack);
      ErrorHandler.showErrorSnackbar('Failed to revoke access');
      return false;
    }
  }

  /// Pause access
  Future<bool> pauseAccess(String connectionId) async {
    try {
      if (connectionId.isEmpty) return false;

      logI('⏸️ Pausing access: $connectionId');

      final connection = await getById(connectionId);
      if (connection == null) {
        ErrorHandler.showErrorSnackbar('Connection not found');
        return false;
      }

      if (connection.ownerId != currentUserId) {
        ErrorHandler.showErrorSnackbar('Only the owner can pause access');
        return false;
      }

      if (connection.accessStatus != AccessStatus.active) {
        ErrorHandler.showErrorSnackbar('Can only pause active access');
        return false;
      }

      await _powerSync.update(_tableName, {
        'access_status': AccessStatus.paused.value,
        'updated_at': DateTime.now().toIso8601String(),
      }, connectionId);

      logI('✅ Access paused');
      ErrorHandler.showSuccessSnackbar('Access paused');
      return true;
    } catch (e, stack) {
      logE('❌ Error pausing access', error: e, stackTrace: stack);
      ErrorHandler.showErrorSnackbar('Failed to pause access');
      return false;
    }
  }

  /// Resume access
  Future<bool> resumeAccess(String connectionId) async {
    try {
      if (connectionId.isEmpty) return false;

      logI('▶️ Resuming access: $connectionId');

      final connection = await getById(connectionId);
      if (connection == null) {
        ErrorHandler.showErrorSnackbar('Connection not found');
        return false;
      }

      if (connection.ownerId != currentUserId) {
        ErrorHandler.showErrorSnackbar('Only the owner can resume access');
        return false;
      }

      if (connection.accessStatus != AccessStatus.paused) {
        ErrorHandler.showErrorSnackbar('Can only resume paused access');
        return false;
      }

      // Check if expired
      if (connection.isExpired) {
        ErrorHandler.showErrorSnackbar('Cannot resume expired access');
        return false;
      }

      await _powerSync.update(_tableName, {
        'access_status': AccessStatus.active.value,
        'updated_at': DateTime.now().toIso8601String(),
      }, connectionId);

      logI('✅ Access resumed');
      ErrorHandler.showSuccessSnackbar('Access resumed');
      return true;
    } catch (e, stack) {
      logE('❌ Error resuming access', error: e, stackTrace: stack);
      ErrorHandler.showErrorSnackbar('Failed to resume access');
      return false;
    }
  }

  /// Update permissions
  Future<bool> updatePermissions(
    String connectionId, {
    MentorshipPermissions? permissions,
    List<AccessibleScreen>? screens,
    bool? isLiveEnabled,
  }) async {
    try {
      if (connectionId.isEmpty) return false;

      logI('🔧 Updating permissions: $connectionId');

      final connection = await getById(connectionId);
      if (connection == null) {
        ErrorHandler.showErrorSnackbar('Connection not found');
        return false;
      }

      if (connection.ownerId != currentUserId) {
        ErrorHandler.showErrorSnackbar('Only the owner can update permissions');
        return false;
      }

      final data = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (permissions != null) {
        data['permissions'] = jsonEncode(permissions.toJson());
      }

      if (screens != null) {
        data['allowed_screens'] = jsonEncode(
          AllowedScreens(screens: screens).toJson(),
        );
      }

      if (isLiveEnabled != null) {
        data['is_live_enabled'] = isLiveEnabled ? 1 : 0;
      }

      await _powerSync.update(_tableName, data, connectionId);

      logI('✅ Permissions updated');
      ErrorHandler.showSuccessSnackbar('Permissions updated');
      return true;
    } catch (e, stack) {
      logE('❌ Error updating permissions', error: e, stackTrace: stack);
      ErrorHandler.showErrorSnackbar('Failed to update permissions');
      return false;
    }
  }

  /// Extend duration
  Future<bool> extendDuration(
    String connectionId,
    AccessDuration newDuration,
  ) async {
    try {
      if (connectionId.isEmpty) return false;

      logI('⏱️ Extending duration: $connectionId to ${newDuration.label}');

      final connection = await getById(connectionId);
      if (connection == null) {
        ErrorHandler.showErrorSnackbar('Connection not found');
        return false;
      }

      if (connection.ownerId != currentUserId) {
        ErrorHandler.showErrorSnackbar('Only the owner can extend duration');
        return false;
      }

      final now = DateTime.now();
      final expiresAt = newDuration.calculateExpiresAt(now);

      final data = <String, dynamic>{
        'duration': newDuration.value,
        'access_status': AccessStatus.active.value,
        'updated_at': now.toIso8601String(),
      };

      if (expiresAt != null) {
        data['expires_at'] = expiresAt.toIso8601String();
      } else {
        data['expires_at'] = null;
      }

      await _powerSync.update(_tableName, data, connectionId);

      logI('✅ Duration extended');
      ErrorHandler.showSuccessSnackbar(
        'Duration extended to ${newDuration.label}',
      );
      return true;
    } catch (e, stack) {
      logE('❌ Error extending duration', error: e, stackTrace: stack);
      ErrorHandler.showErrorSnackbar('Failed to extend duration');
      return false;
    }
  }

  /// Log a view access
  Future<bool> logView(String connectionId, {String? screen}) async {
    try {
      if (connectionId.isEmpty) return false;

      final connection = await getById(connectionId);
      if (connection == null) return false;

      if (connection.mentorId != currentUserId) {
        logW('⚠️ Only mentor can log views');
        return false;
      }

      if (connection.accessStatus != AccessStatus.active) {
        logW('⚠️ Cannot log view for inactive connection');
        return false;
      }

      // Check expiration
      if (connection.isExpired) {
        await _powerSync.update(_tableName, {
          'access_status': AccessStatus.expired.value,
          'updated_at': DateTime.now().toIso8601String(),
        }, connectionId);
        return false;
      }

      final data = <String, dynamic>{
        'view_count': connection.viewCount + 1,
        'last_viewed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (screen != null) {
        data['last_viewed_screen'] = screen;
      }

      await _powerSync.update(_tableName, data, connectionId);

      logI('✅ View logged for: $connectionId');
      return true;
    } catch (e, stack) {
      logE('❌ Error logging view', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Update cached snapshot
  Future<bool> updateSnapshot(
    String connectionId,
    Map<String, dynamic> snapshot,
  ) async {
    try {
      if (connectionId.isEmpty) return false;

      logI('📸 Updating snapshot: $connectionId');

      await _powerSync.update(_tableName, {
        'cached_snapshot': jsonEncode(
          snapshot,
          toEncodable: (item) {
            if (item is DateTime) return item.toIso8601String();
            return item;
          },
        ),
        'snapshot_captured_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, connectionId);

      logI('✅ Snapshot updated');
      return true;
    } catch (e, stack) {
      logE('❌ Error updating snapshot', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Send encouragement
  Future<bool> sendEncouragement(
    String connectionId, {
    String type = 'emoji',
    String? message,
  }) async {
    try {
      if (connectionId.isEmpty) return false;

      logI('👏 Sending encouragement: $connectionId');

      final connection = await getById(connectionId);
      if (connection == null) {
        ErrorHandler.showErrorSnackbar('Connection not found');
        return false;
      }

      if (connection.mentorId != currentUserId) {
        ErrorHandler.showErrorSnackbar(
          'Only the mentor can send encouragement',
        );
        return false;
      }

      await _powerSync.update(_tableName, {
        'last_encouragement_at': DateTime.now().toIso8601String(),
        'last_encouragement_type': type,
        'last_encouragement_message': message,
        'encouragement_count': connection.encouragementCount + 1,
        'updated_at': DateTime.now().toIso8601String(),
      }, connectionId);

      logI('✅ Encouragement sent');
      ErrorHandler.showSuccessSnackbar('Encouragement sent! 👏');
      return true;
    } catch (e, stack) {
      logE('❌ Error sending encouragement', error: e, stackTrace: stack);
      ErrorHandler.showErrorSnackbar('Failed to send encouragement');
      return false;
    }
  }

  // ================================================================
  // DELETE OPERATIONS
  // ================================================================

  /// Delete a connection
  Future<bool> delete(String connectionId) async {
    try {
      if (connectionId.isEmpty) return false;

      logI('🗑️ Deleting connection: $connectionId');

      await _powerSync.delete(_tableName, connectionId);

      logI('✅ Connection deleted');
      return true;
    } catch (e, stack) {
      logE('❌ Error deleting connection', error: e, stackTrace: stack);
      ErrorHandler.showErrorSnackbar('Failed to delete connection');
      return false;
    }
  }

  // ================================================================
  // STREAM OPERATIONS
  // ================================================================

  /// Watch my mentors
  Stream<List<MentorshipConnection>> watchMyMentors(String userId) {
    return _powerSync
        .watchQuery(
          '''
          SELECT * FROM $_tableName 
          WHERE owner_id = ? 
          AND request_status = 'approved'
          ORDER BY updated_at DESC
          ''',
          parameters: [userId],
        )
        .map(
          (results) => results.map((row) {
            final parsed = _parseJsonbFields(row);
            return MentorshipConnection.fromJson(parsed);
          }).toList(),
        )
        .handleError((error, stackTrace) {
          logE('Error watching mentors', error: error, stackTrace: stackTrace);
          return <MentorshipConnection>[];
        });
  }

  /// Watch my mentees
  Stream<List<MentorshipConnection>> watchMyMentees(String userId) {
    return _powerSync
        .watchQuery(
          '''
          SELECT * FROM $_tableName 
          WHERE mentor_id = ? 
          AND request_status = 'approved'
          ORDER BY updated_at DESC
          ''',
          parameters: [userId],
        )
        .map(
          (results) => results.map((row) {
            final parsed = _parseJsonbFields(row);
            return MentorshipConnection.fromJson(parsed);
          }).toList(),
        )
        .handleError((error, stackTrace) {
          logE('Error watching mentees', error: error, stackTrace: stackTrace);
          return <MentorshipConnection>[];
        });
  }

  /// Watch incoming requests
  Stream<List<MentorshipConnection>> watchIncomingRequests(String userId) {
    return _powerSync
        .watchQuery(
          '''
          SELECT * FROM $_tableName 
          WHERE owner_id = ? 
          AND request_type = 'request_access'
          ORDER BY requested_at DESC
          ''',
          parameters: [userId],
        )
        .map(
          (results) => results.map((row) {
            final parsed = _parseJsonbFields(row);
            return MentorshipConnection.fromJson(parsed);
          }).toList(),
        )
        .handleError((error, stackTrace) {
          logE(
            'Error watching incoming requests',
            error: error,
            stackTrace: stackTrace,
          );
          return <MentorshipConnection>[];
        });
  }

  /// Watch outgoing requests
  Stream<List<MentorshipConnection>> watchOutgoingRequests(String userId) {
    return _powerSync
        .watchQuery(
          '''
          SELECT * FROM $_tableName 
          WHERE mentor_id = ? 
          AND request_type = 'request_access'
          ORDER BY requested_at DESC
          ''',
          parameters: [userId],
        )
        .map(
          (results) => results.map((row) {
            final parsed = _parseJsonbFields(row);
            return MentorshipConnection.fromJson(parsed);
          }).toList(),
        )
        .handleError((error, stackTrace) {
          logE(
            'Error watching outgoing requests',
            error: error,
            stackTrace: stackTrace,
          );
          return <MentorshipConnection>[];
        });
  }

  /// Watch a specific connection
  Stream<MentorshipConnection?> watchById(String connectionId) {
    return _powerSync
        .watchQuery(
          'SELECT * FROM $_tableName WHERE id = ? LIMIT 1',
          parameters: [connectionId],
        )
        .map((results) {
          if (results.isEmpty) return null;
          final parsed = _parseJsonbFields(results.first);
          return MentorshipConnection.fromJson(parsed);
        })
        .handleError((error, stackTrace) {
          logE(
            'Error watching connection',
            error: error,
            stackTrace: stackTrace,
          );
          return null;
        });
  }

  // ================================================================
  // VALIDATION OPERATIONS
  // ================================================================

  /// Check if mentor can view a specific screen of owner
  Future<bool> canViewScreen(
    String mentorId,
    String ownerId,
    String screenName,
  ) async {
    try {
      final connection = await getActiveConnectionForPair(ownerId, mentorId);
      if (connection == null) return false;
      if (connection.isExpired) return false;
      return connection.canViewScreenByName(screenName);
    } catch (e, stack) {
      logE('❌ Error checking screen access', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Check if mentor has any active access to owner
  Future<bool> hasActiveAccess(String mentorId, String ownerId) async {
    try {
      final connection = await getActiveConnectionForPair(ownerId, mentorId);
      return connection != null && !connection.isExpired;
    } catch (e, stack) {
      logE('❌ Error checking active access', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Check and update expired connections
  Future<void> checkExpiredConnections() async {
    try {
      logI('⏰ Checking expired connections');

      await _powerSync.execute(
        '''
        UPDATE $_tableName 
        SET access_status = 'expired', updated_at = ?
        WHERE access_status = 'active'
        AND expires_at IS NOT NULL
        AND expires_at < ?
        ''',
        [DateTime.now().toIso8601String(), DateTime.now().toIso8601String()],
      );

      // Also expire old pending requests
      await _powerSync.execute(
        '''
        UPDATE $_tableName 
        SET request_status = 'expired', updated_at = ?
        WHERE request_status = 'pending'
        AND requested_at < ?
        ''',
        [
          DateTime.now().toIso8601String(),
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        ],
      );

      logI('✅ Expired connections updated');
    } catch (e, stack) {
      logE('❌ Error checking expired connections', error: e, stackTrace: stack);
    }
  }

  // ================================================================
  // SEARCH OPERATIONS
  // ================================================================

  /// Search for users by name or email
  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      logI('🔍 Searching users with query: $query');
      return await ProfileRepository().searchProfiles(query);
    } catch (e, stack) {
      logE('❌ Error searching users', error: e, stackTrace: stack);
      return [];
    }
  }

  // ================================================================
  // HELPER METHODS
  // ================================================================

  Map<String, dynamic> _processJsonbFields(Map<String, dynamic> data) {
    final processed = <String, dynamic>{};

    data.forEach((key, value) {
      if (_jsonbColumns.contains(key) && (value is Map || value is List)) {
        try {
          processed[key] = jsonEncode(
            value,
            toEncodable: (item) {
              if (item is DateTime) return item.toIso8601String();
              return item;
            },
          );
        } catch (e) {
          logE('JSON encode error for $key', error: e);
          processed[key] = '{}';
        }
      } else if (value is DateTime) {
        processed[key] = value.toIso8601String();
      } else if (value is bool) {
        processed[key] = value ? 1 : 0;
      } else {
        processed[key] = value;
      }
    });

    return processed;
  }

  Map<String, dynamic> _parseJsonbFields(Map<String, dynamic> data) {
    final parsed = Map<String, dynamic>.from(data);

    for (final column in _jsonbColumns) {
      if (parsed[column] is String) {
        try {
          parsed[column] = jsonDecode(parsed[column] as String);
        } catch (_) {
          // Keep as string if parsing fails
        }
      }
    }

    return parsed;
  }

  int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}
