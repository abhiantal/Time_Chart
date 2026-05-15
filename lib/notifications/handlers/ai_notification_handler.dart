// ================================================================
// FILE: lib/notifications/handlers/ai_notification_handler.dart
// Handles AI-related notifications (token warnings, limits, etc.)
// ================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/logger.dart';
import '../core/notification_handler_interface.dart';
import '../core/notification_types.dart';

class AiNotificationHandler implements NotificationHandler {
  @override
  String get handlerId => 'ai_notifications';

  @override
  List<NotificationType> get supportedTypes => [
    NotificationType.aiTokenWarning,
    NotificationType.aiTokenLimit,
    NotificationType.aiTokenLimitReached,
    NotificationType.aiInsightReady,
  ];

  // ================================================================
  // TAP - Handle notification tap (navigate to relevant screen)
  // ================================================================

  @override
  Future<bool> handleNotificationTap(
    BuildContext context,
    NotificationData data,
  ) async {
    logI('🤖 AI Notification tapped: ${data.type}');

    // Navigate to AI settings or token usage screen
    // Currently redirecting to User Profile as a fallback for settings
    try {
      context.goNamed('settingsScreen');
      return true;
    } catch (e) {
      logE('❌ Navigation to AI settings failed: $e');
      return false;
    }
  }

  // ================================================================
  // FOREGROUND - Display notification when app is active
  // ================================================================

  @override
  Future<bool> handleForegroundNotification(NotificationData data) async {
    logI('🤖 AI Notification (Foreground): ${data.type}');

    switch (data.notificationType) {
      case NotificationType.aiTokenWarning:
        _handleTokenWarning(data);
        break;

      case NotificationType.aiTokenLimit:
      case NotificationType.aiTokenLimitReached:
        _handleTokenLimitReached(data);
        break;

      case NotificationType.aiInsightReady:
        logI('🤖 AI Insight is ready');
        break;

      default:
        logW('⚠️ Unknown AI notification type: ${data.type}');
        return false;
    }

    return true; // Handled
  }

  // ================================================================
  // BACKGROUND - Handle notification when app is in background
  // ================================================================

  @override
  Future<bool> handleBackgroundNotification(NotificationData data) async {
    logI('🤖 AI Notification (Background): ${data.type}');

    // Background actions can be limited - just log for now
    // You could update local cache, show badge, etc.

    return true; // Handled
  }

  // ================================================================
  // CUSTOM DISPLAY (Optional)
  // ================================================================

  @override
  Future<Map<String, dynamic>?> customNotificationDisplay(
    NotificationData data,
  ) async {
    // Return custom styling for different notification types
    switch (data.notificationType) {
      case NotificationType.aiTokenWarning:
        return {
          'icon': '@drawable/ic_warning',
          'playSound': true,
          'title': '⚠️ ${data.title}',
          'body': data.body,
        };

      case NotificationType.aiTokenLimit:
      case NotificationType.aiTokenLimitReached:
        return {
          'icon': '@drawable/ic_error',
          'playSound': true,
          'title': '🚫 ${data.title}',
          'body': data.body,
        };

      case NotificationType.aiInsightReady:
        return {
          'icon': '@drawable/ic_ai_insight',
          'playSound': true,
          'title': '🤖 ${data.title}',
          'body': data.body,
        };

      default:
        return null; // Use default display
    }
  }

  // ================================================================
  // PRIVATE HANDLERS
  // ================================================================

  void _handleTokenWarning(NotificationData data) {
    final percentage = data.data['percentage'] ?? 90;
    final remaining = data.data['remaining'] ?? 0;

    logI('⚠️ Token Warning: $percentage% used, $remaining remaining');

    // You can trigger additional actions here:
    // - Show badge on settings icon
    // - Update local state
    // - Show in-app banner
  }

  void _handleTokenLimitReached(NotificationData data) {
    final hoursUntilReset = data.data['hours_until_reset'] ?? 12;

    logI('🚫 Token Limit Reached. Resets in $hoursUntilReset hours');

    // Actions:
    // - Disable AI features temporarily
    // - Show upgrade prompt (if premium)
    // - Update UI state
  }

  void _handleTokenReset(NotificationData data) {
    final newQuota = data.data['new_quota'] ?? 10000;

    logI('✅ Tokens Reset. New quota: $newQuota');

    // Actions:
    // - Re-enable AI features
    // - Clear warning states
    // - Notify user they can use AI again
  }

  void _handleQuotaUpdated(NotificationData data) {
    final oldQuota = data.data['old_quota'] ?? 0;
    final newQuota = data.data['new_quota'] ?? 0;

    logI('📊 Quota Updated: $oldQuota → $newQuota');

    // Actions:
    // - Update local quota display
    // - Show congratulations if upgrade
  }

  void _handleServiceError(NotificationData data) {
    final errorMessage = data.data['error_message'] ?? 'Unknown error';
    final provider = data.data['provider'] ?? 'Unknown';

    logE('AI Service Error', error: '$provider: $errorMessage');

    // Actions:
    // - Log to analytics
    // - Show error to user
    // - Retry if applicable
  }

  // ================================================================
  // INHERITED METHODS
  // ================================================================

  /// Check if this handler supports the given notification type
  @override
  bool supports(NotificationType type) {
    return supportedTypes.contains(type);
  }

  /// Check if this handler supports the given notification type string
  @override
  bool supportsTypeString(String type) {
    return supports(NotificationType.fromString(type));
  }

  /// Log handler activity
  @override
  void logActivity(String message) {
    logI('[$handlerId] $message');
  }
}
