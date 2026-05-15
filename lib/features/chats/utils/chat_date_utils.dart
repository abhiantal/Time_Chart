// ================================================================
// 📁 FILE 1: chat_date_utils.dart
// Comprehensive date/time formatting for chat UI
// Handles: timestamps, date headers, relative time, grouping
// ================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatDateUtils {
  ChatDateUtils._();

  // ── Cache for performance ─────────────────────────────────
  static DateTime? _cachedToday;
  static DateTime? _cachedYesterday;
  static int _cachedDay = -1;

  static void _ensureDateCache() {
    final now = DateTime.now();
    if (_cachedDay != now.day) {
      _cachedToday = DateTime(now.year, now.month, now.day);
      _cachedYesterday = _cachedToday!.subtract(const Duration(days: 1));
      _cachedDay = now.day;
    }
  }

  // ================================================================
  // MESSAGE TIME (inside bubble) — "10:30 AM"
  // ================================================================

  /// Short time for message bubble — "10:30 AM"
  static String formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat.jm().format(dateTime.toLocal());
  }

  /// 24-hour format — "14:30"
  static String formatMessageTime24(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat.Hm().format(dateTime.toLocal());
  }

  /// Full Date Time: "15 Jan 2024, 10:30 AM"
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('d MMM y, h:mm a').format(dateTime.toLocal());
  }

  // ================================================================
  // CHAT LIST TIME (right side of tile)
  // ================================================================

  /// Smart time for chat list:
  /// Today → "10:30 AM"
  /// Yesterday → "Yesterday"
  /// This week → "Monday"
  /// This year → "Jan 15"
  /// Older → "01/15/24"
  static String formatChatListTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    _ensureDateCache();

    final local = dateTime.toLocal();
    final localDay = DateTime(local.year, local.month, local.day);

    if (localDay == _cachedToday) {
      return DateFormat.jm().format(local);
    }

    if (localDay == _cachedYesterday) {
      return 'Yesterday';
    }

    final diff = _cachedToday!.difference(localDay).inDays;

    if (diff < 7 && diff > 0) {
      return DateFormat.EEEE().format(local); // "Monday"
    }

    if (local.year == DateTime.now().year) {
      return DateFormat.MMMd().format(local); // "Jan 15"
    }

    return DateFormat.yMd().format(local); // "01/15/2024"
  }

  /// Compact version for tight spaces
  /// Today → "10:30"
  /// Yesterday → "Yest."
  /// This week → "Mon"
  /// Older → "1/15"
  static String formatChatListTimeCompact(DateTime? dateTime) {
    if (dateTime == null) return '';
    _ensureDateCache();

    final local = dateTime.toLocal();
    final localDay = DateTime(local.year, local.month, local.day);

    if (localDay == _cachedToday) {
      return DateFormat.jm().format(local);
    }

    if (localDay == _cachedYesterday) {
      return 'Yest.';
    }

    final diff = _cachedToday!.difference(localDay).inDays;

    if (diff < 7 && diff > 0) {
      return DateFormat.E().format(local); // "Mon"
    }

    if (local.year == DateTime.now().year) {
      return DateFormat('M/d').format(local); // "1/15"
    }

    return DateFormat('M/d/yy').format(local); // "1/15/24"
  }

  // ================================================================
  // DATE HEADERS (between messages)
  // ================================================================

  /// Date header text:
  /// Today → "Today"
  /// Yesterday → "Yesterday"
  /// This week → "Monday, January 15"
  /// This year → "January 15"
  /// Older → "January 15, 2023"
  static String formatDateHeader(DateTime dateTime) {
    _ensureDateCache();

    final local = dateTime.toLocal();
    final localDay = DateTime(local.year, local.month, local.day);

    if (localDay == _cachedToday) return 'Today';
    if (localDay == _cachedYesterday) return 'Yesterday';

    final diff = _cachedToday!.difference(localDay).inDays;

    if (diff < 7 && diff > 0) {
      return DateFormat('EEEE, MMMM d').format(local);
    }

    if (local.year == DateTime.now().year) {
      return DateFormat.MMMd().format(local);
    }

    return DateFormat.yMMMd().format(local);
  }

  /// Check if two dates need a date header between them
  static bool needsDateHeader(DateTime? previous, DateTime current) {
    if (previous == null) return true;
    final prevLocal = previous.toLocal();
    final currLocal = current.toLocal();
    return prevLocal.year != currLocal.year ||
        prevLocal.month != currLocal.month ||
        prevLocal.day != currLocal.day;
  }

  // ================================================================
  // RELATIVE TIME — "2 min ago", "3h ago"
  // ================================================================

  /// Relative time ago:
  /// < 1 min → "Just now"
  /// < 60 min → "5 min ago"
  /// < 24 hours → "3h ago"
  /// < 7 days → "3d ago"
  /// Otherwise → formatted date
  static String formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dateTime.toLocal());

    if (diff.isNegative) return 'Just now';
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return formatChatListTime(dateTime);
  }

  /// Very short relative: "now", "5m", "3h", "2d", "1w"
  static String formatRelativeShort(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dateTime.toLocal());

    if (diff.isNegative || diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo';
    return '${(diff.inDays / 365).floor()}y';
  }

  // ================================================================
  // ONLINE STATUS — "online", "last seen 5 min ago"
  // ================================================================

  /// Format last seen for presence display
  static String formatLastSeen(DateTime? lastSeen, {bool isOnline = false}) {
    if (isOnline) return 'online';
    if (lastSeen == null) return 'offline';

    final now = DateTime.now();
    final diff = now.difference(lastSeen.toLocal());

    if (diff.inSeconds < 60) return 'last seen just now';
    if (diff.inMinutes < 60) {
      return 'last seen ${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return 'last seen ${diff.inHours}h ago';
    }

    _ensureDateCache();
    final lastSeenDay = DateTime(lastSeen.year, lastSeen.month, lastSeen.day);

    if (lastSeenDay == _cachedYesterday) {
      return 'last seen yesterday at ${DateFormat.jm().format(lastSeen.toLocal())}';
    }

    if (diff.inDays < 7) {
      return 'last seen ${DateFormat.EEEE().format(lastSeen.toLocal())} '
          'at ${DateFormat.jm().format(lastSeen.toLocal())}';
    }

    return 'last seen ${DateFormat.MMMd().format(lastSeen.toLocal())}';
  }

  // ================================================================
  // MEDIA GALLERY GROUPING
  // ================================================================

  /// Group key for media gallery sections
  /// "Today", "Yesterday", "Mon", "Jan 15", "Jan 15, 2023"
  static String formatGalleryGroupKey(DateTime dateTime) {
    _ensureDateCache();

    final local = dateTime.toLocal();
    final localDay = DateTime(local.year, local.month, local.day);

    if (localDay == _cachedToday) return 'Today';
    if (localDay == _cachedYesterday) return 'Yesterday';

    final diff = _cachedToday!.difference(localDay).inDays;

    if (diff < 7 && diff > 0) {
      return DateFormat.EEEE().format(local);
    }

    if (local.year == DateTime.now().year) {
      return DateFormat.MMMd().format(local);
    }

    return DateFormat.yMMMd().format(local);
  }

  // ================================================================
  // DURATION FORMATTING (voice notes, videos)
  // ================================================================

  /// Format duration: "0:05", "1:30", "1:05:30"
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format seconds to duration string
  static String formatSeconds(int? seconds) {
    if (seconds == null || seconds <= 0) return '0:00';
    return formatDuration(Duration(seconds: seconds));
  }

  // ================================================================
  // DISAPPEARING MESSAGES TIMER
  // ================================================================

  /// Format disappearing message duration
  /// 86400 → "24 hours", 3600 → "1 hour", 604800 → "7 days"
  static String formatDisappearingDuration(int? seconds) {
    if (seconds == null) return 'Off';

    if (seconds < 60) return '$seconds seconds';
    if (seconds < 3600) return '${seconds ~/ 60} minutes';
    if (seconds < 86400) {
      final hours = seconds ~/ 3600;
      return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    }
    final days = seconds ~/ 86400;
    return '$days ${days == 1 ? 'day' : 'days'}';
  }

  // ================================================================
  // MUTE DURATION FORMATTING
  // ================================================================

  /// Format mute until time
  static String formatMuteUntil(DateTime? muteUntil) {
    if (muteUntil == null) return 'Until you unmute';

    final now = DateTime.now();
    if (muteUntil.isBefore(now)) return 'Expired';

    final diff = muteUntil.difference(now);

    if (diff.inHours < 24) {
      return 'For ${diff.inHours} hours';
    }
    if (diff.inDays < 7) {
      return 'For ${diff.inDays} days';
    }
    return 'Until ${DateFormat.MMMd().format(muteUntil.toLocal())}';
  }

  // ================================================================
  // INVITE EXPIRY
  // ================================================================

  /// Format invite expiry
  static String formatInviteExpiry(DateTime? expiresAt) {
    if (expiresAt == null) return 'Never expires';

    final now = DateTime.now();
    if (expiresAt.isBefore(now)) return 'Expired';

    final diff = expiresAt.difference(now);

    if (diff.inMinutes < 60) return 'Expires in ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Expires in ${diff.inHours}h';
    if (diff.inDays < 7) return 'Expires in ${diff.inDays}d';

    return 'Expires ${DateFormat.MMMd().format(expiresAt.toLocal())}';
  }

  // ================================================================
  // THEMED DATE HEADER WIDGET
  // ================================================================

  /// Build a themed date header widget
  static Widget buildDateHeader(BuildContext context, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
