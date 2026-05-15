// ================================================================
// FILE: lib/notifications/handlers/system_notification_handler.dart
// Handles all system-related notifications
// ================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/logger.dart';
import '../core/notification_handler_interface.dart';
import '../core/notification_types.dart';

class SystemNotificationHandler extends NotificationHandler {
  @override
  String get handlerId => 'system_handler';

  @override
  List<NotificationType> get supportedTypes => [
    NotificationType.systemUpdate,
    NotificationType.announcement,
    NotificationType.maintenance,
    NotificationType.systemAlert,
  ];

  @override
  Future<bool> handleNotificationTap(
    BuildContext context,
    NotificationData data,
  ) async {
    logI('⚙️ System notification tapped: ${data.type}');

    switch (data.notificationType) {
      case NotificationType.systemUpdate:
        await _handleUpdateNotification(context, data);
        break;

      case NotificationType.announcement:
        await _handleAnnouncement(context, data);
        break;

      case NotificationType.maintenance:
        await _handleMaintenance(context, data);
        break;

      default:
        context.goNamed('personalNav');
        return true;
    }

    // Show snackbar for important system notifications
    if (data.notificationType == NotificationType.maintenance) {
      snackbarService.showWarning(data.title, description: data.body);
    }
    return true;
  }

  @override
  Future<bool> handleForegroundNotification(NotificationData data) async {
    logI('⚙️ System notification in foreground: ${data.type}');

    return true;

    return true;
  }

  @override
  Future<bool> handleBackgroundNotification(NotificationData data) async {
    logI('⚙️ System notification in background: ${data.type}');

    // Handle system updates, maintenance schedules

    return true;
  }

  @override
  Future<Map<String, dynamic>?> customNotificationDisplay(
    NotificationData data,
  ) async {
    String emoji;
    bool playSound;

    switch (data.notificationType) {
      case NotificationType.systemUpdate:
        emoji = '🔄';
        playSound = false;
        break;
      case NotificationType.announcement:
        emoji = '📢';
        playSound = false;
        break;
      case NotificationType.maintenance:
        emoji = '🔧';
        playSound = true;
        break;
      case NotificationType.systemAlert:
        emoji = '🚨';
        playSound = true;
        break;
      default:
        emoji = 'ℹ️';
        playSound = false;
    }

    return {
      'icon': '@mipmap/ic_notification',
      'playSound': playSound,
      'title': '$emoji ${data.title}',
      'body': data.body,
    };
  }

  // ================================================================
  // HANDLERS
  // ================================================================

  Future<void> _handleUpdateNotification(
    BuildContext context,
    NotificationData data,
  ) async {
    logI('→ Handling update notification');

    final isForced = data.data['forced'] == true;

    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: !isForced,
        builder: (context) => AlertDialog(
          title: const Text('Update Available'),
          content: Text(data.body),
          actions: [
            if (!isForced)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Later'),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Update Now'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleAnnouncement(
    BuildContext context,
    NotificationData data,
  ) async {
    logI('→ Handling announcement');

    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(data.title),
          content: SingleChildScrollView(child: Text(data.body)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleMaintenance(
    BuildContext context,
    NotificationData data,
  ) async {
    logI('→ Handling maintenance notification');

    final startTime = data.data['startTime'] ?? 'Soon';
    
    if (context.mounted) {
      snackbarService.showWarning(
        'Scheduled Maintenance',
        description: 'Starting: $startTime',
      );
    }
  }
}
