// ================================================================
// FILE: lib/features/mentoring/utils/mentoring_utils.dart
// Constants and Helpers for Mentoring Feature
// ================================================================

import 'package:flutter/material.dart';
import '../models/mentorship_model.dart';

// ================================================================
// PART 1: CONSTANTS
// ================================================================

/// All constants for the mentoring feature
class MentoringConstants {
  MentoringConstants._();

  // ================================================================
  // ANIMATION DURATIONS
  // ================================================================

  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 400);
  static const Duration pulseAnimation = Duration(milliseconds: 1500);
  static const Duration shimmerAnimation = Duration(milliseconds: 1200);

  // ================================================================
  // SPACING & SIZING
  // ================================================================

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  static const double borderRadiusSm = 8.0;
  static const double borderRadiusMd = 12.0;
  static const double borderRadiusLg = 16.0;
  static const double borderRadiusXl = 24.0;
  static const double borderRadiusFull = 100.0;

  static const double iconSizeSm = 16.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;
  static const double iconSizeXl = 48.0;

  static const double avatarSizeSm = 32.0;
  static const double avatarSizeMd = 48.0;
  static const double avatarSizeLg = 64.0;
  static const double avatarSizeXl = 96.0;

  static const double cardElevation = 2.0;
  static const double cardElevationHover = 4.0;

  // ================================================================
  // SCREEN NAMES (For navigation & display)
  // ================================================================

  static const Map<AccessibleScreen, String> screenRoutes = {
    AccessibleScreen.dashboard: '/dashboard',
    AccessibleScreen.mood: '/dashboard/mood',
    AccessibleScreen.rewards: '/dashboard/rewards',
    AccessibleScreen.stats: '/dashboard/stats',
  };

  // ================================================================
  // DEFAULT PERMISSIONS BY RELATIONSHIP
  // ================================================================

  static const Map<RelationshipType, MentorshipPermissions> defaultPermissions =
      {
        RelationshipType.parentChild: MentorshipPermissions(
          showPoints: true,
          showStreak: true,
          showRank: true,
          showTasks: true,
          showTaskDetails: true,
          showGoals: true,
          showGoalDetails: true,
          showMood: true,
          showDiary: false,
          showRewards: true,
          showProgress: true,
        ),
        RelationshipType.teacherStudent: MentorshipPermissions(
          showPoints: true,
          showStreak: true,
          showRank: true,
          showTasks: true,
          showTaskDetails: false,
          showGoals: true,
          showGoalDetails: false,
          showMood: false,
          showDiary: false,
          showRewards: true,
          showProgress: true,
        ),
        RelationshipType.bossEmployee: MentorshipPermissions(
          showPoints: true,
          showStreak: true,
          showRank: true,
          showTasks: true,
          showTaskDetails: true,
          showGoals: true,
          showGoalDetails: true,
          showMood: false,
          showDiary: false,
          showRewards: true,
          showProgress: true,
        ),
        RelationshipType.coachAthlete: MentorshipPermissions(
          showPoints: true,
          showStreak: true,
          showRank: true,
          showTasks: true,
          showTaskDetails: false,
          showGoals: true,
          showGoalDetails: false,
          showMood: true,
          showDiary: false,
          showRewards: true,
          showProgress: true,
        ),
        RelationshipType.accountabilityPartner: MentorshipPermissions(
          showPoints: true,
          showStreak: true,
          showRank: false,
          showTasks: true,
          showTaskDetails: false,
          showGoals: true,
          showGoalDetails: false,
          showMood: false,
          showDiary: false,
          showRewards: true,
          showProgress: true,
        ),
        RelationshipType.custom: MentorshipPermissions(
          showPoints: true,
          showStreak: true,
          showRank: true,
          showTasks: false,
          showTaskDetails: false,
          showGoals: false,
          showGoalDetails: false,
          showMood: false,
          showDiary: false,
          showRewards: true,
          showProgress: true,
        ),
      };

  // ================================================================
  // DEFAULT SCREENS BY RELATIONSHIP
  // ================================================================

  static const Map<RelationshipType, List<AccessibleScreen>> defaultScreens = {
    RelationshipType.parentChild: [
      AccessibleScreen.dashboard,
      AccessibleScreen.mood,
      AccessibleScreen.rewards,
      AccessibleScreen.stats,
    ],
    RelationshipType.teacherStudent: [
      AccessibleScreen.dashboard,
      AccessibleScreen.stats,
    ],
    RelationshipType.bossEmployee: [
      AccessibleScreen.dashboard,
      AccessibleScreen.stats,
    ],
    RelationshipType.coachAthlete: [
      AccessibleScreen.dashboard,
      AccessibleScreen.stats,
    ],
    RelationshipType.accountabilityPartner: [
      AccessibleScreen.dashboard,
      AccessibleScreen.stats,
    ],
    RelationshipType.custom: [AccessibleScreen.dashboard],
  };

  // ================================================================
  // ENCOURAGEMENT EMOJIS
  // ================================================================

  static const List<String> encouragementEmojis = [
    '👏',
    '🎉',
    '💪',
    '🌟',
    '🔥',
    '🚀',
    '💯',
    '👍',
    '❤️',
    '🏆',
    '⭐',
    '✨',
  ];

  // ================================================================
  // QUICK MESSAGES
  // ================================================================

  static const List<String> quickEncouragementMessages = [
    'Great job! Keep it up! 🎉',
    'You\'re doing amazing! 💪',
    'Proud of your progress! 🌟',
    'Keep pushing forward! 🚀',
    'You\'ve got this! 💯',
    'Fantastic work today! 👏',
    'Your dedication shows! ⭐',
    'Amazing progress! 🔥',
  ];

  // ================================================================
  // INACTIVE THRESHOLDS
  // ================================================================

  static const int defaultInactiveThresholdDays = 3;
  static const int warningInactiveThresholdDays = 5;
  static const int criticalInactiveThresholdDays = 7;

  // ================================================================
  // REQUEST EXPIRY
  // ================================================================

  static const int pendingRequestExpiryDays = 30;
  static const int reminderBeforeExpiryDays = 7;
}

// ================================================================
// PART 2: COLORS
// ================================================================

/// Color palette for mentoring feature
class MentoringColors {
  MentoringColors._();

  // ================================================================
  // STATUS COLORS
  // ================================================================

  static const Color activeLight = Color(0xFF4CAF50);
  static const Color activeDark = Color(0xFF81C784);

  static const Color pausedLight = Color(0xFFFFC107);
  static const Color pausedDark = Color(0xFFFFD54F);

  static const Color expiredLight = Color(0xFFF44336);
  static const Color expiredDark = Color(0xFFE57373);

  static const Color revokedLight = Color(0xFF212121);
  static const Color revokedDark = Color(0xFF424242);

  static const Color inactiveLight = Color(0xFF9E9E9E);
  static const Color inactiveDark = Color(0xFFBDBDBD);

  static const Color pendingLight = Color(0xFFFF9800);
  static const Color pendingDark = Color(0xFFFFB74D);

  // ================================================================
  // RELATIONSHIP COLORS
  // ================================================================

  static const Color teacherStudent = Color(0xFF2196F3);
  static const Color parentChild = Color(0xFFE91E63);
  static const Color bossEmployee = Color(0xFF673AB7);
  static const Color coachAthlete = Color(0xFF4CAF50);
  static const Color accountabilityPartner = Color(0xFF00BCD4);
  static const Color custom = Color(0xFF9E9E9E);

  // ================================================================
  // GRADIENT SETS
  // ================================================================

  static const List<Color> mentorGradientLight = [
    Color(0xFF667eea),
    Color(0xFF764ba2),
  ];

  static const List<Color> mentorGradientDark = [
    Color(0xFF2D1F5F),
    Color(0xFF3D2A7D),
  ];

  static const List<Color> menteeGradientLight = [
    Color(0xFF43E97B),
    Color(0xFF38F9D7),
  ];

  static const List<Color> menteeGradientDark = [
    Color(0xFF1F5F3A),
    Color(0xFF2A7D4D),
  ];

  static const List<Color> requestGradientLight = [
    Color(0xFFFF9966),
    Color(0xFFFF5E62),
  ];

  static const List<Color> requestGradientDark = [
    Color(0xFF5F2D1F),
    Color(0xFF7D3A2A),
  ];

  static const List<Color> liveGradientLight = [
    Color(0xFFEE0979),
    Color(0xFFFF6A00),
  ];

  static const List<Color> liveGradientDark = [
    Color(0xFF5F1F2D),
    Color(0xFF7D2A3A),
  ];

  // ================================================================
  // HELPER METHODS
  // ================================================================

  static Color getStatusColor(AccessStatus status, bool isDarkMode) {
    switch (status) {
      case AccessStatus.active:
        return isDarkMode ? activeDark : activeLight;
      case AccessStatus.paused:
        return isDarkMode ? pausedDark : pausedLight;
      case AccessStatus.expired:
        return isDarkMode ? expiredDark : expiredLight;
      case AccessStatus.revoked:
        return isDarkMode ? revokedDark : revokedLight;
      case AccessStatus.inactive:
        return isDarkMode ? inactiveDark : inactiveLight;
    }
  }

  static Color getRequestStatusColor(RequestStatus status, bool isDarkMode) {
    switch (status) {
      case RequestStatus.pending:
        return isDarkMode ? pendingDark : pendingLight;
      case RequestStatus.approved:
        return isDarkMode ? activeDark : activeLight;
      case RequestStatus.rejected:
        return isDarkMode ? expiredDark : expiredLight;
      case RequestStatus.cancelled:
        return isDarkMode ? inactiveDark : inactiveLight;
      case RequestStatus.expired:
        return isDarkMode ? revokedDark : revokedLight;
    }
  }

  static Color getRelationshipColor(RelationshipType type) {
    switch (type) {
      case RelationshipType.teacherStudent:
        return teacherStudent;
      case RelationshipType.parentChild:
        return parentChild;
      case RelationshipType.bossEmployee:
        return bossEmployee;
      case RelationshipType.coachAthlete:
        return coachAthlete;
      case RelationshipType.accountabilityPartner:
        return accountabilityPartner;
      case RelationshipType.custom:
        return custom;
    }
  }

  static List<Color> getGradient(String type, bool isDarkMode) {
    switch (type) {
      case 'mentor':
        return isDarkMode ? mentorGradientDark : mentorGradientLight;
      case 'mentee':
        return isDarkMode ? menteeGradientDark : menteeGradientLight;
      case 'request':
        return isDarkMode ? requestGradientDark : requestGradientLight;
      case 'live':
        return isDarkMode ? liveGradientDark : liveGradientLight;
      default:
        return isDarkMode ? mentorGradientDark : mentorGradientLight;
    }
  }
}

// ================================================================
// PART 3: HELPERS
// ================================================================

/// Helper functions for mentoring feature
class MentoringHelpers {
  MentoringHelpers._();

  // ================================================================
  // DISPLAY HELPERS
  // ================================================================

  /// Get display label for duration
  static String getDurationLabel(AccessDuration duration) {
    return duration.label;
  }

  /// Get description for duration
  static String getDurationDescription(AccessDuration duration) {
    return duration.description;
  }

  /// Get display label for screen
  static String getScreenLabel(AccessibleScreen screen) {
    return screen.label;
  }

  /// Get description for screen
  static String getScreenDescription(AccessibleScreen screen) {
    return screen.description;
  }

  /// Get icon for relationship type
  static IconData getRelationshipIcon(RelationshipType type) {
    return type.icon;
  }

  /// Get emoji for relationship type
  static String getRelationshipEmoji(RelationshipType type) {
    return type.emoji;
  }

  /// Get mentor label for relationship
  static String getMentorLabel(RelationshipType type) {
    return type.mentorLabel;
  }

  /// Get owner/mentee label for relationship
  static String getOwnerLabel(RelationshipType type) {
    return type.ownerLabel;
  }

  /// Get status color
  static Color getStatusColor(AccessStatus status, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return MentoringColors.getStatusColor(status, isDarkMode);
  }

  /// Get request status color
  static Color getRequestStatusColor(
    RequestStatus status,
    BuildContext context,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return MentoringColors.getRequestStatusColor(status, isDarkMode);
  }

  // ================================================================
  // TIME CALCULATIONS
  // ================================================================

  /// Calculate expiration date from duration
  static DateTime? calculateExpiresAt(
    AccessDuration duration, [
    DateTime? from,
  ]) {
    return duration.calculateExpiresAt(from);
  }

  /// Get remaining time from expiration
  static Duration? getRemainingTime(DateTime? expiresAt) {
    if (expiresAt == null) return null;
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Format remaining time for display
  static String formatRemainingTime(Duration? remaining) {
    if (remaining == null) return 'Never expires';
    if (remaining.inSeconds <= 0) return 'Expired';

    if (remaining.inDays > 365) {
      final years = (remaining.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} left';
    } else if (remaining.inDays > 30) {
      final months = (remaining.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} left';
    } else if (remaining.inDays > 0) {
      return '${remaining.inDays} day${remaining.inDays > 1 ? 's' : ''} left';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours} hour${remaining.inHours > 1 ? 's' : ''} left';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes} min left';
    } else {
      return 'Less than a minute';
    }
  }

  /// Format time ago
  static String formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Never';

    final diff = DateTime.now().difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  /// Format date for display
  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'Today';
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (date.isAfter(today.subtract(const Duration(days: 7)))) {
      return _getWeekdayName(dateTime.weekday);
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  static String _getWeekdayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  // ================================================================
  // PERMISSION HELPERS
  // ================================================================

  /// Get default permissions for relationship type
  static MentorshipPermissions getDefaultPermissions(RelationshipType type) {
    return MentoringConstants.defaultPermissions[type] ??
        const MentorshipPermissions();
  }

  /// Get default screen for relationship type
  static List<AccessibleScreen> getDefaultScreens(RelationshipType type) {
    return MentoringConstants.defaultScreens[type] ??
        [AccessibleScreen.dashboard];
  }

  /// Check if all screens are selected
  static bool hasAllScreens(List<AccessibleScreen> screens) {
    return screens.length >= AccessibleScreen.values.length;
  }

  /// Get visible screen count
  static int getVisibleScreensCount(List<AccessibleScreen> screens) {
    return screens.length;
  }

  /// Format screen for display
  static String formatScreensList(List<AccessibleScreen> screens) {
    if (hasAllScreens(screens)) return 'All Screens';
    if (screens.isEmpty) return 'No screen';
    if (screens.length == 1) return screens.first.label;
    if (screens.length == 2) {
      return '${screens[0].label} & ${screens[1].label}';
    }
    return '${screens.length} screen';
  }

  // ================================================================
  // VALIDATION HELPERS
  // ================================================================

  /// Check if connection is accessible now
  static bool canAccessNow(MentorshipConnection connection) {
    if (!connection.isActive) return false;
    if (connection.isExpired) return false;
    return true;
  }

  /// Check if mentee is inactive
  static bool isMenteeInactive(MentorshipConnection connection) {
    if (connection.lastViewedAt == null) return false;
    final daysSinceView = DateTime.now()
        .difference(connection.lastViewedAt!)
        .inDays;
    return daysSinceView >= connection.inactiveThresholdDays;
  }

  /// Get inactivity level (0: active, 1: warning, 2: critical)
  static int getInactivityLevel(MentorshipConnection connection) {
    if (connection.lastViewedAt == null) return 0;

    final daysSinceView = DateTime.now()
        .difference(connection.lastViewedAt!)
        .inDays;

    if (daysSinceView >= MentoringConstants.criticalInactiveThresholdDays) {
      return 2;
    } else if (daysSinceView >=
        MentoringConstants.warningInactiveThresholdDays) {
      return 1;
    }
    return 0;
  }

  /// Check if connection is expiring soon
  static bool isExpiringSoon(MentorshipConnection connection) {
    if (!connection.hasExpiration) return false;
    final remaining = connection.remainingTime;
    if (remaining == null) return false;
    return remaining.inDays <= MentoringConstants.reminderBeforeExpiryDays &&
        remaining.inDays > 0;
  }

  // ================================================================
  // UI HELPERS
  // ================================================================

  /// Get badge count text (e.g., "99+" for large numbers)
  static String formatBadgeCount(int count) {
    if (count <= 0) return '';
    if (count > 99) return '99+';
    return count.toString();
  }

  /// Get initials from name
  static String getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Get avatar color from name/id
  static Color getAvatarColor(String? identifier) {
    if (identifier == null || identifier.isEmpty) {
      return Colors.grey;
    }

    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFFE91E63),
      const Color(0xFF673AB7),
      const Color(0xFF4CAF50),
      const Color(0xFF00BCD4),
      const Color(0xFFFF9800),
      const Color(0xFF795548),
      const Color(0xFF607D8B),
      const Color(0xFF9C27B0),
      const Color(0xFF3F51B5),
    ];

    final index = identifier.hashCode.abs() % colors.length;
    return colors[index];
  }

  /// Get status icon
  static IconData getStatusIcon(AccessStatus status) {
    switch (status) {
      case AccessStatus.active:
        return Icons.check_circle;
      case AccessStatus.paused:
        return Icons.pause_circle;
      case AccessStatus.expired:
        return Icons.timer_off;
      case AccessStatus.revoked:
        return Icons.cancel;
      case AccessStatus.inactive:
        return Icons.radio_button_unchecked;
    }
  }

  /// Get request status icon
  static IconData getRequestStatusIcon(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Icons.hourglass_empty;
      case RequestStatus.approved:
        return Icons.check_circle;
      case RequestStatus.rejected:
        return Icons.cancel;
      case RequestStatus.cancelled:
        return Icons.remove_circle;
      case RequestStatus.expired:
        return Icons.timer_off;
    }
  }

  // ================================================================
  // GRADIENT HELPERS
  // ================================================================

  /// Get gradient decoration for cards
  static BoxDecoration getCardDecoration({
    required BuildContext context,
    required String type,
    double borderRadius = 16.0,
    double elevation = 2.0,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = MentoringColors.getGradient(type, isDarkMode);

    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: colors.first.withAlpha((255 * 0.3).toInt()),
          blurRadius: elevation * 4,
          offset: Offset(0, elevation * 2),
        ),
      ],
    );
  }

  /// Get relationship gradient
  static LinearGradient getRelationshipGradient(
    RelationshipType type, {
    bool isDarkMode = false,
  }) {
    final baseColor = MentoringColors.getRelationshipColor(type);

    return LinearGradient(
      colors: [
        baseColor,
        isDarkMode
            ? baseColor.withAlpha((255 * 0.6).toInt())
            : baseColor.withAlpha((255 * 0.8).toInt()),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Get live indicator gradient
  static LinearGradient getLiveGradient(bool isDarkMode) {
    return LinearGradient(
      colors: isDarkMode
          ? MentoringColors.liveGradientDark
          : MentoringColors.liveGradientLight,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // ================================================================
  // ENCOURAGEMENT HELPERS
  // ================================================================

  /// Get random encouragement emoji
  static String getRandomEncouragementEmoji() {
    final emojis = MentoringConstants.encouragementEmojis;
    final index = DateTime.now().millisecondsSinceEpoch % emojis.length;
    return emojis[index];
  }

  /// Get random quick message
  static String getRandomQuickMessage() {
    final messages = MentoringConstants.quickEncouragementMessages;
    final index = DateTime.now().millisecondsSinceEpoch % messages.length;
    return messages[index];
  }

  // ================================================================
  // SNAPSHOT HELPERS
  // ================================================================

  /// Check if snapshot is fresh (less than 5 minutes old)
  static bool isSnapshotFresh(DateTime? capturedAt) {
    if (capturedAt == null) return false;
    final age = DateTime.now().difference(capturedAt);
    return age.inMinutes < 5;
  }

  /// Get snapshot age label
  static String getSnapshotAgeLabel(DateTime? capturedAt) {
    if (capturedAt == null) return 'No data';

    final age = DateTime.now().difference(capturedAt);

    if (age.inMinutes < 1) return 'Just now';
    if (age.inMinutes < 5) return 'Fresh';
    if (age.inMinutes < 60) return '${age.inMinutes}m old';
    if (age.inHours < 24) return '${age.inHours}h old';
    return '${age.inDays}d old';
  }

  /// Get snapshot freshness color
  static Color getSnapshotFreshnessColor(
    DateTime? capturedAt,
    bool isDarkMode,
  ) {
    if (capturedAt == null) {
      return isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400;
    }

    final age = DateTime.now().difference(capturedAt);

    if (age.inMinutes < 5) {
      return isDarkMode ? Colors.green.shade400 : Colors.green;
    } else if (age.inHours < 1) {
      return isDarkMode ? Colors.blue.shade400 : Colors.blue;
    } else if (age.inHours < 24) {
      return isDarkMode ? Colors.orange.shade400 : Colors.orange;
    }
    return isDarkMode ? Colors.red.shade400 : Colors.red;
  }

  // ================================================================
  // SORT HELPERS
  // ================================================================

  /// Sort connections by activity
  static List<MentorshipConnection> sortByActivity(
    List<MentorshipConnection> connections,
  ) {
    return List.from(connections)..sort((a, b) {
      // Active first
      if (a.isActive && !b.isActive) return -1;
      if (!a.isActive && b.isActive) return 1;

      // Then by last viewed
      final aViewed = a.lastViewedAt ?? DateTime(1970);
      final bViewed = b.lastViewedAt ?? DateTime(1970);
      return bViewed.compareTo(aViewed);
    });
  }

  /// Sort connections by name
  static List<MentorshipConnection> sortByRelationship(
    List<MentorshipConnection> connections,
  ) {
    return List.from(connections)..sort((a, b) {
      return a.relationshipType.index.compareTo(b.relationshipType.index);
    });
  }

  /// Sort connections by expiry (soonest first)
  static List<MentorshipConnection> sortByExpiry(
    List<MentorshipConnection> connections,
  ) {
    return List.from(connections)..sort((a, b) {
      // No expiry goes last
      if (a.expiresAt == null && b.expiresAt == null) return 0;
      if (a.expiresAt == null) return 1;
      if (b.expiresAt == null) return -1;
      return a.expiresAt!.compareTo(b.expiresAt!);
    });
  }

  // ================================================================
  // FILTER HELPERS
  // ================================================================

  /// Filter active connections
  static List<MentorshipConnection> filterActive(
    List<MentorshipConnection> connections,
  ) {
    return connections.where((c) => c.isActive).toList();
  }

  /// Filter paused connections
  static List<MentorshipConnection> filterPaused(
    List<MentorshipConnection> connections,
  ) {
    return connections.where((c) => c.isPaused).toList();
  }

  /// Filter by relationship type
  static List<MentorshipConnection> filterByRelationship(
    List<MentorshipConnection> connections,
    RelationshipType type,
  ) {
    return connections.where((c) => c.relationshipType == type).toList();
  }

  /// Filter connections needing attention
  static List<MentorshipConnection> filterNeedingAttention(
    List<MentorshipConnection> connections,
  ) {
    return connections.where((c) {
      if (!c.canAccess) return false;
      return isMenteeInactive(c) || isExpiringSoon(c);
    }).toList();
  }

  // ================================================================
  // SEARCH HELPERS
  // ================================================================

  /// Search connections by query
  static List<MentorshipConnection> searchConnections(
    List<MentorshipConnection> connections,
    String query,
  ) {
    if (query.isEmpty) return connections;

    final lowerQuery = query.toLowerCase();
    return connections.where((c) {
      final label = c.relationshipLabel?.toLowerCase() ?? '';
      final type = c.relationshipType.label.toLowerCase();
      return label.contains(lowerQuery) || type.contains(lowerQuery);
    }).toList();
  }
}

// ================================================================
// PART 4: EXTENSIONS
// ================================================================

/// Extensions for BuildContext
extension MentoringContextExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;
}

/// Extensions for Color
extension MentoringColorExtension on Color {
  Color get withLightOpacity => withValues(alpha: 0.1);
  Color get withMediumOpacity => withValues(alpha: 0.3);
  Color get withHeavyOpacity => withValues(alpha: 0.6);
}

/// Extensions for Duration
extension MentoringDurationExtension on Duration {
  String get formatted => MentoringHelpers.formatRemainingTime(this);

  bool get isExpired => inSeconds <= 0;

  bool get isExpiringSoon => inDays <= 7 && inDays > 0;
}

/// Extensions for DateTime
extension MentoringDateTimeExtension on DateTime {
  String get timeAgo => MentoringHelpers.formatTimeAgo(this);

  String get formatted => MentoringHelpers.formatDate(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }
}
