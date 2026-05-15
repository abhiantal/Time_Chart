// ================================================================
// FILE: lib/notifications/presentation/repository/notification_repository.dart
// COMPLETE REWRITE — circular dependency removed
//
// FIX 2: markAsRead() no longer calls FirebaseNotificationCore.
//         Badge updates are the provider's responsibility.
// ================================================================

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:the_time_chart/services/powersync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../widgets/logger.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final _powerSync = PowerSyncService();
  final _supabase = Supabase.instance.client;

  static const String _tableInbox = 'notifications';
  static const String _tokenTable = 'fcm_tokens';

  // Cache to prevent redundant platform channel calls
  static String? _cachedDeviceInfo;
  static String? _cachedAppVersion;

  // ================================================================
  // FCM TOKEN MANAGEMENT
  // ================================================================

  Future<bool> saveFCMToken({
    required String userId,
    required String token,
    String? deviceInfo,
    String? appVersion,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final deviceInfoData = deviceInfo ?? await _getDeviceInfo();
      final appVersionData = appVersion ?? await _getAppVersion();
      final platform = _getPlatform();

      final existing = await _supabase
          .from(_tokenTable)
          .select('id, token')
          .eq('user_id', userId)
          .eq('token', token)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from(_tokenTable)
            .update({
              'platform': platform,
              'device_info': deviceInfoData,
              'app_version': appVersionData,
              'is_active': true,
              'updated_at': now,
            })
            .eq('id', existing['id'] as String);
        logI('✓ FCM token updated');
      } else {
        await _supabase.from(_tokenTable).insert({
          'id': const Uuid().v4(),
          'user_id': userId,
          'token': token,
          'platform': platform,
          'device_info': deviceInfoData,
          'app_version': appVersionData,
          'is_active': true,
          'created_at': now,
          'updated_at': now,
        });
        logI('✓ FCM token saved');
      }
      return true;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') ||
          msg.contains('Failed host lookup') ||
          msg.contains('HandshakeException')) {
        logW('📡 Save FCM token: network unavailable');
        return false;
      }
      logE('❌ Save FCM token error', error: e);
      return false;
    }
  }

  Future<bool> removeFCMToken(String userId) async {
    try {
      await _supabase
          .from(_tokenTable)
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
      logI('✓ FCM token deactivated');
      return true;
    } catch (e) {
      logE('❌ Remove FCM token error', error: e);
      return false;
    }
  }

  // ================================================================
  // INBOX — WRITE
  // ================================================================

  Future<void> saveToInbox({
    required String userId,
    required String type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final id = const Uuid().v4();
      final now = DateTime.now().toIso8601String();
      final info = {'title': title, 'body': body, 'type': type, 'data': data};

      await _powerSync.insert(_tableInbox, {
        'id': id,
        'user_id': userId,
        'notification_info': jsonEncode(info),
        'is_read': 0,
        'read_at': null,
        'created_at': now,
        'metadata': jsonEncode({'source': 'fcm', 'platform': _getPlatform()}),
      });

      logI('✓ Notification saved to inbox: $id');
    } catch (e, st) {
      logE('❌ saveToInbox error', error: e, stackTrace: st);
    }
  }

  Future<void> queueNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.from('notification_queue').insert({
        'id': const Uuid().v4(),
        'user_id': userId,
        'type': type,
        'title': title,
        'body': body,
        'data': data ?? {},
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      logI('✓ Notification queued for $userId');
    } catch (e, st) {
      logE('❌ queueNotification error', error: e, stackTrace: st);
    }
  }

  // ================================================================
  // INBOX — READ
  // ================================================================

  Stream<List<NotificationModel>> watchNotifications(
    String userId, {
    DateTime? before,
  }) {
    try {
      String query = 'SELECT * FROM $_tableInbox WHERE user_id = ?';
      final List<dynamic> params = [userId];

      if (before != null) {
        query += ' AND created_at < ?';
        params.add(before.toIso8601String());
      }
      query += ' ORDER BY created_at DESC LIMIT 50';

      return _powerSync.watchQuery(query, parameters: params).map((results) {
        return results
            .map(
              (row) => NotificationModel.fromSyncedTable(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();
      });
    } catch (e, st) {
      logE('❌ watchNotifications error', error: e, stackTrace: st);
      return Stream.value([]);
    }
  }

  Future<List<NotificationModel>> getNotifications(
    String userId, {
    DateTime? before,
  }) async {
    try {
      String query = 'SELECT * FROM $_tableInbox WHERE user_id = ?';
      final List<dynamic> params = [userId];

      if (before != null) {
        query += ' AND created_at < ?';
        params.add(before.toIso8601String());
      }
      query += ' ORDER BY created_at DESC LIMIT 50';

      final results = await _powerSync.executeQuery(query, parameters: params);
      return results
          .map(
            (row) => NotificationModel.fromSyncedTable(
              Map<String, dynamic>.from(row),
            ),
          )
          .toList();
    } catch (e, st) {
      logE('❌ getNotifications error', error: e, stackTrace: st);
      return [];
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final result = await _powerSync.querySingle(
        'SELECT COUNT(*) as count FROM $_tableInbox WHERE user_id = ? AND (is_read = 0 OR is_read IS NULL)',
        parameters: [userId],
      );
      return (result?['count'] as int?) ?? 0;
    } catch (e) {
      logE('❌ getUnreadCount error', error: e);
      return 0;
    }
  }

  // ================================================================
  // INBOX — DELETE / MARK READ
  //
  // FIX 2: markAsRead() does NOT call FirebaseNotificationCore.
  //         Badge is updated by NotificationProvider after this returns.
  // ================================================================

  Future<void> markAsRead(String notificationId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Security: verify ownership
      final existing = await _powerSync.querySingle(
        'SELECT user_id FROM $_tableInbox WHERE id = ?',
        parameters: [notificationId],
      );

      if (existing != null && existing['user_id'] != currentUserId) {
        logW('⚠️ Security: attempt to delete another user\'s notification');
        return;
      }

      await _powerSync.delete(_tableInbox, notificationId);

      // Cloud cleanup — non-critical
      try {
        await _supabase
            .from('notification_logs')
            .delete()
            .eq('id', notificationId)
            .maybeSingle();
      } catch (_) {}

      logI('✓ Notification deleted: $notificationId');

      // ❌ NO FirebaseNotificationCore().updateBadgeCount() here.
      //    The provider calls updateBadgeCount() after this method returns.
    } catch (e, st) {
      logE('❌ markAsRead error', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != userId) {
        logW('⚠️ Security: markAllAsRead called with different userId');
        return;
      }
      await _powerSync.execute('DELETE FROM $_tableInbox WHERE user_id = ?', [
        userId,
      ]);
      logI('✓ All notifications deleted for $userId');
    } catch (e, st) {
      logE('❌ markAllAsRead error', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _powerSync.delete(_tableInbox, notificationId);
      logI('✓ Notification deleted: $notificationId');
    } catch (e, st) {
      logE('❌ deleteNotification error', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ================================================================
  // PLATFORM HELPERS
  // ================================================================

  String _getPlatform() {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isMacOS) return 'macos';
      return 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  Future<String> _getDeviceInfo() async {
    if (_cachedDeviceInfo != null) return _cachedDeviceInfo!;
    try {
      final plugin = DeviceInfoPlugin();
      Map<String, dynamic> info = {};

      if (kIsWeb) {
        final w = await plugin.webBrowserInfo;
        info = {
          'browser': w.browserName.name,
          'platform': w.platform,
          'userAgent': w.userAgent,
        };
      } else if (Platform.isAndroid) {
        final a = await plugin.androidInfo;
        info = {
          'brand': a.brand,
          'model': a.model,
          'androidVersion': a.version.release,
          'sdkInt': a.version.sdkInt,
          'isPhysicalDevice': a.isPhysicalDevice,
        };
      } else if (Platform.isIOS) {
        final i = await plugin.iosInfo;
        info = {
          'name': i.name,
          'model': i.model,
          'systemVersion': i.systemVersion,
          'isPhysicalDevice': i.isPhysicalDevice,
        };
      }

      _cachedDeviceInfo = jsonEncode(info);
      return _cachedDeviceInfo!;
    } catch (e) {
      logW('⚠️ Could not get device info: $e');
      return jsonEncode({'error': 'unavailable'});
    }
  }

  Future<String> _getAppVersion() async {
    if (_cachedAppVersion != null) return _cachedAppVersion!;
    try {
      final pkg = await PackageInfo.fromPlatform();
      _cachedAppVersion = '${pkg.version}+${pkg.buildNumber}';
      return _cachedAppVersion!;
    } catch (e) {
      logW('⚠️ Could not get app version: $e');
      return 'unknown';
    }
  }
}
