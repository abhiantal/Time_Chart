// ================================================================
// FILE: lib/notifications/presentation/providers/notification_provider.dart
// COMPLETE REWRITE
//
// FIX 2: Badge updateBadgeCount() called HERE after repo operations,
//         NOT inside the repository. Provider owns badge lifecycle.
// ================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../widgets/logger.dart';
import '../../../Authentication/auth_provider.dart';
import '../models/notification_model.dart';
import '../repository/notification_repository.dart';
import '../../core/notification_types.dart';
import '../../notification_setup.dart';
import '../../core/firebase_notification_core.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<List<NotificationModel>>? _subscription;
  String? _currentUserId;
  bool _isDisposed = false;

  NotificationProvider({NotificationRepository? repository})
    : _repository = repository ?? NotificationRepository() {
    _init();
  }

  // ── Getters ───────────────────────────────────────────────────
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasNotifications => _notifications.isNotEmpty;

  // In the delete-on-read system every item in the list is unread
  int get unreadCount => _notifications.length;
  bool get hasUnread => _notifications.isNotEmpty;

  // ── Init ──────────────────────────────────────────────────────
  void _init() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _currentUserId = user.id;
      _subscribeToNotifications(user.id);
    } else {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Called by ChangeNotifierProxyProvider when AuthProvider changes
  void updateAuth(AuthProvider auth) {
    updateUserId(auth.currentUser?.id);
  }

  void updateUserId(String? userId) {
    if (userId == _currentUserId) return;
    _currentUserId = userId;
    _subscription?.cancel();
    _subscription = null;

    if (userId != null) {
      _subscribeToNotifications(userId);
    } else {
      _notifications = [];
      _isLoading = false;
      _error = null;
      _safeNotifyListeners();
    }
  }

  void _subscribeToNotifications(String userId) {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    _subscription?.cancel();
    _subscription = _repository
        .watchNotifications(userId)
        .listen(
          (data) {
            _notifications = data;
            _isLoading = false;
            _error = null;
            _safeNotifyListeners();
            logI('✅ Notifications: ${data.length} items');
          },
          onError: (e, st) {
            _error = e.toString();
            _isLoading = false;
            logE('❌ Notification stream error', error: e, stackTrace: st);
            _safeNotifyListeners();
          },
        );
  }

  Future<void> loadNotifications() => refresh();

  // ── Mark as read (= delete) ───────────────────────────────────
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;

    final original = _notifications[index];
    _notifications.removeAt(index);
    _safeNotifyListeners();

    try {
      await _repository.markAsRead(notificationId);
      logI('✓ Notification read: $notificationId');
      // ✅ FIX 2: Badge lives here, not in the repository
      FirebaseNotificationCore().updateBadgeCount();
    } catch (e) {
      _notifications.insert(index, original);
      _safeNotifyListeners();
      logE('❌ markAsRead failed', error: e);
    }
  }

  Future<void> markAllAsRead() async {
    if (_currentUserId == null || !hasNotifications) return;

    final originalList = List<NotificationModel>.from(_notifications);
    _notifications = [];
    _safeNotifyListeners();

    try {
      await _repository.markAllAsRead(_currentUserId!);
      logI('✓ All notifications cleared');
      // ✅ FIX 2: Badge lives here
      FirebaseNotificationCore().clearBadge();
    } catch (e) {
      _notifications = originalList;
      _safeNotifyListeners();
      logE('❌ markAllAsRead failed', error: e);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;

    final original = _notifications[index];
    _notifications.removeAt(index);
    _safeNotifyListeners();

    try {
      await _repository.deleteNotification(notificationId);
      FirebaseNotificationCore().updateBadgeCount();
    } catch (e) {
      _notifications.insert(index, original);
      _safeNotifyListeners();
      logE('❌ deleteNotification failed', error: e);
    }
  }

  // ── Tap handler ───────────────────────────────────────────────
  Future<void> handleTap(
    BuildContext context,
    NotificationModel notification,
  ) async {
    try {
      if (!notification.isRead) {
        await markAsRead(notification.id);
      }

      final data = NotificationData(
        type: notification.type,
        title: notification.title,
        body: notification.body,
        data: notification.payload,
        userId: notification.userId,
        targetId: notification.targetId,
      );

      final handled = await notificationSetup.router.routeTap(context, data);
      if (!handled) {
        logW('⚠️ Unhandled tap for type: ${notification.type}');
      }
    } catch (e, st) {
      logE('❌ handleTap error', error: e, stackTrace: st);
    }
  }

  // ── Grouping helpers ──────────────────────────────────────────
  Map<String, List<NotificationModel>> get groupedNotifications {
    if (_notifications.isEmpty) return {};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final Map<String, List<NotificationModel>> grouped = {};

    for (final notif in _notifications) {
      final d = DateTime(
        notif.createdAt.year,
        notif.createdAt.month,
        notif.createdAt.day,
      );
      final group = d.isAtSameMomentAs(today)
          ? 'Today'
          : d.isAtSameMomentAs(yesterday)
          ? 'Yesterday'
          : 'Earlier';
      grouped.putIfAbsent(group, () => []).add(notif);
    }

    for (final list in grouped.values) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    // Preserve order: Today → Yesterday → Earlier
    return {
      if (grouped.containsKey('Today')) 'Today': grouped['Today']!,
      if (grouped.containsKey('Yesterday')) 'Yesterday': grouped['Yesterday']!,
      if (grouped.containsKey('Earlier')) 'Earlier': grouped['Earlier']!,
    };
  }

  List<NotificationModel> getByType(String type) =>
      _notifications.where((n) => n.type == type).toList();

  List<NotificationModel> get todayNotifications {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _notifications.where((n) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      return d.isAtSameMomentAs(today);
    }).toList();
  }

  // ── Refresh ───────────────────────────────────────────────────
  Future<void> refresh() async {
    if (_currentUserId != null) {
      _subscribeToNotifications(_currentUserId!);
    }
  }

  void clear() {
    _notifications = [];
    _isLoading = false;
    _error = null;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
