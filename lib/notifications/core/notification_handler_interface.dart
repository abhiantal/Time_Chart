// FILE: lib/notifications/core/notification_handler_interface.dart
// Merged Notification Handler Interface and Router logic
// ================================================================

import 'package:flutter/material.dart';
import '../../widgets/logger.dart';
import 'notification_types.dart';

// ================================================================
// HANDLER INTERFACE
// ================================================================

/// Abstract base class for notification handlers
/// All module-specific handlers must extend this
abstract class NotificationHandler {
  /// Unique handler identifier
  String get handlerId;

  /// List of notification types this handler manages
  List<NotificationType> get supportedTypes;

  /// Handle notification tap/click
  /// Return true if handled, false otherwise
  Future<bool> handleNotificationTap(
    BuildContext context,
    NotificationData data,
  );

  /// Handle notification received in foreground
  /// Return true if handled, false otherwise
  Future<bool> handleForegroundNotification(NotificationData data);

  /// Handle notification received in background
  /// Return true if handled, false otherwise
  Future<bool> handleBackgroundNotification(NotificationData data);

  /// Custom notification display logic (optional)
  /// Return null to use default display
  Future<Map<String, dynamic>?> customNotificationDisplay(
    NotificationData data,
  ) async {
    return null;
  }

  /// Check if this handler supports the given notification type
  bool supports(NotificationType type) {
    return supportedTypes.contains(type);
  }

  /// Check if this handler supports the given notification type string
  bool supportsTypeString(String type) {
    return supports(NotificationType.fromString(type));
  }

  /// Log handler activity
  void logActivity(String message) {
    logI('[$handlerId] $message');
  }
}

// ================================================================
// ROUTER
// ================================================================

class NotificationRouter {
  static final NotificationRouter _instance = NotificationRouter._internal();
  factory NotificationRouter() => _instance;
  NotificationRouter._internal();

  final List<NotificationHandler> _handlers = [];

  /// Register a notification handler
  void registerHandler(NotificationHandler handler) {
    // Check if handler already registered
    if (_handlers.any((h) => h.handlerId == handler.handlerId)) {
      logW('⚠️ Handler ${handler.handlerId} already registered');
      return;
    }

    _handlers.add(handler);
    logI('✓ Registered notification handler: ${handler.handlerId}');
    logI(
      '  Supports: ${handler.supportedTypes.map((t) => t.value).join(', ')}',
    );
  }

  /// Unregister a notification handler
  void unregisterHandler(String handlerId) {
    _handlers.removeWhere((h) => h.handlerId == handlerId);
    logI('✓ Unregistered notification handler: $handlerId');
  }

  /// Get handler for notification type
  NotificationHandler? getHandler(NotificationType type) {
    try {
      return _handlers.firstWhere((h) => h.supports(type));
    } catch (e) {
      logW('⚠️ No handler found for type: ${type.value}');
      return null;
    }
  }

  /// Get handler for notification type string
  NotificationHandler? getHandlerForTypeString(String type) {
    try {
      return _handlers.firstWhere((h) => h.supportsTypeString(type));
    } catch (e) {
      logW('⚠️ No handler found for type: $type');
      return null;
    }
  }

  /// Route notification tap
  Future<bool> routeTap(BuildContext context, NotificationData data) async {
    try {
      final handler = getHandler(data.notificationType);
      if (handler == null) {
        logW('⚠️ No handler for notification tap: ${data.type}');
        return false;
      }

      logI('→ Routing tap to ${handler.handlerId}');
      return await handler.handleNotificationTap(context, data);
    } catch (error, stackTrace) {
      logE(
        'Notification tap routing error',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Route foreground notification
  Future<bool> routeForeground(NotificationData data) async {
    try {
      final handler = getHandler(data.notificationType);
      if (handler == null) {
        logW('⚠️ No handler for foreground notification: ${data.type}');
        return false;
      }

      logI('→ Routing foreground notification to ${handler.handlerId}');
      return await handler.handleForegroundNotification(data);
    } catch (error, stackTrace) {
      logE(
        'Foreground notification routing error',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Route background notification
  Future<bool> routeBackground(NotificationData data) async {
    try {
      final handler = getHandler(data.notificationType);
      if (handler == null) {
        logW('⚠️ No handler for background notification: ${data.type}');
        return false;
      }

      logI('→ Routing background notification to ${handler.handlerId}');
      return await handler.handleBackgroundNotification(data);
    } catch (error, stackTrace) {
      logE(
        'Background notification routing error',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get custom display configuration
  Future<Map<String, dynamic>?> getCustomDisplay(NotificationData data) async {
    try {
      final handler = getHandler(data.notificationType);
      if (handler == null) return null;

      return await handler.customNotificationDisplay(data);
    } catch (error) {
      logE('Custom display error', error: error);
      return null;
    }
  }

  /// Get all registered handlers
  List<NotificationHandler> get handlers => List.unmodifiable(_handlers);

  /// Clear all handlers
  void clearHandlers() {
    _handlers.clear();
    logI('✓ All notification handlers cleared');
  }

  /// Print registered handlers
  void printHandlers() {
    logI('📋 Registered Notification Handlers:');
    for (final handler in _handlers) {
      logI('  • ${handler.handlerId}');
      logI(
        '    Types: ${handler.supportedTypes.map((t) => t.value).join(', ')}',
      );
    }
  }
}
