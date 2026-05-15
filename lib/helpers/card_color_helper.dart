// ================================================================
// FILE: lib/helpers/card_color_helper.dart
// Dynamic Color Assignment System for Task Cards & Buckets
// Supports: Priority, Status, Progress, Dark/Light Themes, Buckets
// ================================================================

import 'package:flutter/material.dart';

class CardColorHelper {
  // ================================================================
  // PRIORITY-BASED GRADIENTS (4 colors each for colorful cards)
  // ================================================================

  // LOW PRIORITY - Calm & Peaceful
  static const List<List<Color>> lowPriorityLight = [
    [
      Color(0xFFA8EDEA),
      Color(0xFFFED6E3),
      Color(0xFFFFE5EC),
      Color(0xFFD5F4E6),
    ],
    [
      Color(0xFFD3F8E2),
      Color(0xFFABEBC6),
      Color(0xFFE8F8F5),
      Color(0xFFC1F0F6),
    ],
    [
      Color(0xFFA1C4FD),
      Color(0xFFC2E9FB),
      Color(0xFFE0F7FA),
      Color(0xFFB2EBF2),
    ],
    [
      Color(0xFF96E6A1),
      Color(0xFFD4FC79),
      Color(0xFFE8F5E9),
      Color(0xFFC8E6C9),
    ],
    [
      Color(0xFFFFA69E),
      Color(0xFFFAF3DD),
      Color(0xFFFFF9E6),
      Color(0xFFFFE5B4),
    ],
  ];

  static const List<List<Color>> lowPriorityDark = [
    [
      Color(0xFF1A4D4D),
      Color(0xFF2D5F5F),
      Color(0xFF3A7070),
      Color(0xFF2A5555),
    ],
    [
      Color(0xFF1E4D3A),
      Color(0xFF2D6B4E),
      Color(0xFF3A7D5F),
      Color(0xFF2A5F47),
    ],
    [
      Color(0xFF1A3D5F),
      Color(0xFF2D5A7D),
      Color(0xFF3A6E94),
      Color(0xFF2A5270),
    ],
    [
      Color(0xFF2D5F3A),
      Color(0xFF3A7D4E),
      Color(0xFF478F5F),
      Color(0xFF357047),
    ],
    [
      Color(0xFF5F3A2D),
      Color(0xFF7D5A47),
      Color(0xFF946E5F),
      Color(0xFF705247),
    ],
  ];

  // MEDIUM PRIORITY - Balanced & Professional
  static const List<List<Color>> mediumPriorityLight = [
    [
      Color(0xFF667eea),
      Color(0xFF764ba2),
      Color(0xFF8E5FB8),
      Color(0xFF9D6FCC),
    ],
    [
      Color(0xFF4776E6),
      Color(0xFF8E54E9),
      Color(0xFFA366F0),
      Color(0xFFB478F7),
    ],
    [
      Color(0xFF6A11CB),
      Color(0xFF2575FC),
      Color(0xFF4A8DFF),
      Color(0xFF6FA5FF),
    ],
    [
      Color(0xFF00C9FF),
      Color(0xFF92FE9D),
      Color(0xFFB0FFB8),
      Color(0xFFD0FFD4),
    ],
    [
      Color(0xFF30CFD0),
      Color(0xFF330867),
      Color(0xFF4A3D7A),
      Color(0xFF61528D),
    ],
  ];

  static const List<List<Color>> mediumPriorityDark = [
    [
      Color(0xFF2D1F5F),
      Color(0xFF3D2A7D),
      Color(0xFF4D3594),
      Color(0xFF3D2A70),
    ],
    [
      Color(0xFF1F2D5F),
      Color(0xFF2A3D7D),
      Color(0xFF354D94),
      Color(0xFF2A3D70),
    ],
    [
      Color(0xFF1A1F5F),
      Color(0xFF2D3A7D),
      Color(0xFF3A4D94),
      Color(0xFF2A3A70),
    ],
    [
      Color(0xFF1F5F5F),
      Color(0xFF2A7D7D),
      Color(0xFF359494),
      Color(0xFF2A7070),
    ],
    [
      Color(0xFF1F3D5F),
      Color(0xFF1A1F3D),
      Color(0xFF2A2D4D),
      Color(0xFF1F2A47),
    ],
  ];

  // HIGH PRIORITY - Energetic & Attention-Grabbing
  static const List<List<Color>> highPriorityLight = [
    [
      Color(0xFFFF9966),
      Color(0xFFFF5E62),
      Color(0xFFFF7A70),
      Color(0xFFFF967E),
    ],
    [
      Color(0xFFF6D365),
      Color(0xFFFDA085),
      Color(0xFFFFB699),
      Color(0xFFFFCCAD),
    ],
    [
      Color(0xFFFFCC70),
      Color(0xFFC850C0),
      Color(0xFFD666CC),
      Color(0xFFE47CD8),
    ],
    [
      Color(0xFFFA709A),
      Color(0xFFFEE140),
      Color(0xFFFFF266),
      Color(0xFFFFF98C),
    ],
    [
      Color(0xFFF093FB),
      Color(0xFFF5576C),
      Color(0xFFF77085),
      Color(0xFFF9899E),
    ],
  ];

  static const List<List<Color>> highPriorityDark = [
    [
      Color(0xFF5F2D1F),
      Color(0xFF7D3A2A),
      Color(0xFF944735),
      Color(0xFF70352A),
    ],
    [
      Color(0xFF5F4D1F),
      Color(0xFF7D6B2A),
      Color(0xFF947D35),
      Color(0xFF70612A),
    ],
    [
      Color(0xFF5F3D2D),
      Color(0xFF7D5247),
      Color(0xFF94615F),
      Color(0xFF704D47),
    ],
    [
      Color(0xFF5F1F3A),
      Color(0xFF7D2A4D),
      Color(0xFF94355F),
      Color(0xFF702A47),
    ],
    [
      Color(0xFF5F2D47),
      Color(0xFF7D3A5F),
      Color(0xFF944770),
      Color(0xFF70355F),
    ],
  ];

  // URGENT PRIORITY - Critical & Immediate Action
  static const List<List<Color>> urgentPriorityLight = [
    [
      Color(0xFFEE0979),
      Color(0xFFFF6A00),
      Color(0xFFFF8533),
      Color(0xFFFFA066),
    ],
    [
      Color(0xFFF12711),
      Color(0xFFF5AF19),
      Color(0xFFF7C14D),
      Color(0xFFF9D380),
    ],
    [
      Color(0xFFFF0844),
      Color(0xFFFFB199),
      Color(0xFFFFC7B3),
      Color(0xFFFFDDCC),
    ],
    [
      Color(0xFFFF6B6B),
      Color(0xFFFFE66D),
      Color(0xFFFFF08C),
      Color(0xFFFFF7AB),
    ],
    [
      Color(0xFFF953C6),
      Color(0xFFB91D73),
      Color(0xFFD1478C),
      Color(0xFFE971A5),
    ],
  ];

  static const List<List<Color>> urgentPriorityDark = [
    [
      Color(0xFF5F1F2D),
      Color(0xFF7D2A3A),
      Color(0xFF943547),
      Color(0xFF702A35),
    ],
    [
      Color(0xFF5F2D1F),
      Color(0xFF7D4D2A),
      Color(0xFF946135),
      Color(0xFF704D2A),
    ],
    [
      Color(0xFF5F1F1F),
      Color(0xFF7D3A3A),
      Color(0xFF944D4D),
      Color(0xFF703A3A),
    ],
    [
      Color(0xFF5F1F2D),
      Color(0xFF7D3A4D),
      Color(0xFF944D61),
      Color(0xFF703A4D),
    ],
    [
      Color(0xFF5F1F3D),
      Color(0xFF7D1F2D),
      Color(0xFF942A3A),
      Color(0xFF701F2D),
    ],
  ];

  // ================================================================
  // STATUS-BASED GRADIENTS
  // ================================================================

  // PENDING - Neutral & Waiting
  static const List<List<Color>> pendingLight = [
    [
      Color(0xFFCFD8DC),
      Color(0xFFECEFF1),
      Color(0xFFF5F7F8),
      Color(0xFFE8EAED),
    ],
    [
      Color(0xFFB0BEC5),
      Color(0xFFCFD8DC),
      Color(0xFFE0E7EA),
      Color(0xFFF0F4F5),
    ],
  ];

  static const List<List<Color>> pendingDark = [
    [
      Color(0xFF2D3A3A),
      Color(0xFF3D4D4D),
      Color(0xFF4D5F5F),
      Color(0xFF3D4D4D),
    ],
    [
      Color(0xFF2D3A47),
      Color(0xFF3D4D5F),
      Color(0xFF4D5F70),
      Color(0xFF3D4D5F),
    ],
  ];

  // IN_PROGRESS - Active & Dynamic
  static const List<List<Color>> inProgressLight = [
    [
      Color(0xFF4FACFE),
      Color(0xFF00F2FE),
      Color(0xFF33F5FF),
      Color(0xFF66F8FF),
    ],
    [
      Color(0xFF89F7FE),
      Color(0xFF66A6FF),
      Color(0xFF7FB8FF),
      Color(0xFF99CAFF),
    ],
    [
      Color(0xFF0093E9),
      Color(0xFF80D0C7),
      Color(0xFF99DDD4),
      Color(0xFFB3E9E1),
    ],
  ];

  static const List<List<Color>> inProgressDark = [
    [
      Color(0xFF1F3D5F),
      Color(0xFF2A527D),
      Color(0xFF356194),
      Color(0xFF2A4D70),
    ],
    [
      Color(0xFF2D4D5F),
      Color(0xFF3A617D),
      Color(0xFF477094),
      Color(0xFF355F70),
    ],
    [
      Color(0xFF1F3D5F),
      Color(0xFF2D5270),
      Color(0xFF3A617D),
      Color(0xFF2A4D5F),
    ],
  ];

  // COMPLETED - Success & Achievement
  static const List<List<Color>> completedLight = [
    [
      Color(0xFF43E97B),
      Color(0xFF38F9D7),
      Color(0xFF5FFAE0),
      Color(0xFF85FBEA),
    ],
    [
      Color(0xFF84FAB0),
      Color(0xFF8FD3F4),
      Color(0xFFA8E0F7),
      Color(0xFFC1EDFA),
    ],
    [
      Color(0xFF6BE585),
      Color(0xFF1FCDD0),
      Color(0xFF4DD9DC),
      Color(0xFF7AE5E8),
    ],
  ];

  static const List<List<Color>> completedDark = [
    [
      Color(0xFF1F5F3A),
      Color(0xFF2A7D4D),
      Color(0xFF358F5F),
      Color(0xFF2A7047),
    ],
    [
      Color(0xFF2D5F4D),
      Color(0xFF3A7D61),
      Color(0xFF478F70),
      Color(0xFF357061),
    ],
    [
      Color(0xFF2D5F47),
      Color(0xFF3A7D5F),
      Color(0xFF478F70),
      Color(0xFF357061),
    ],
  ];

  // MISSED - Warning & Failure
  static const List<List<Color>> missedLight = [
    [
      Color(0xFFFF6B6B),
      Color(0xFFFFE66D),
      Color(0xFFFFF08C),
      Color(0xFFFFF7AB),
    ],
    [
      Color(0xFFFF9A9E),
      Color(0xFFFAD0C4),
      Color(0xFFFFDED8),
      Color(0xFFFFECE8),
    ],
    [
      Color(0xFFFF8A56),
      Color(0xFFFF6771),
      Color(0xFFFF8594),
      Color(0xFFFFA3B7),
    ],
  ];

  static const List<List<Color>> missedDark = [
    [
      Color(0xFF5F2D2D),
      Color(0xFF7D3A3A),
      Color(0xFF944747),
      Color(0xFF703A3A),
    ],
    [
      Color(0xFF5F3A3A),
      Color(0xFF7D4D4D),
      Color(0xFF945F5F),
      Color(0xFF704D4D),
    ],
    [
      Color(0xFF5F2D1F),
      Color(0xFF7D3A2A),
      Color(0xFF944735),
      Color(0xFF703A2A),
    ],
  ];

  // CANCELLED - Muted & Inactive
  static const List<List<Color>> cancelledLight = [
    [
      Color(0xFFB0BEC5),
      Color(0xFF90A4AE),
      Color(0xFFA8B8BF),
      Color(0xFFC0CCD0),
    ],
    [
      Color(0xFF9E9E9E),
      Color(0xFFBDBDBD),
      Color(0xFFCFCFCF),
      Color(0xFFE0E0E0),
    ],
  ];

  static const List<List<Color>> cancelledDark = [
    [
      Color(0xFF2D3A3A),
      Color(0xFF3A4747),
      Color(0xFF47525F),
      Color(0xFF354747),
    ],
    [
      Color(0xFF2D2D2D),
      Color(0xFF3A3A3A),
      Color(0xFF474747),
      Color(0xFF353535),
    ],
  ];

  // POSTPONED - Delayed but Active
  static const List<List<Color>> postponedLight = [
    [
      Color(0xFFFBC2EB),
      Color(0xFFA6C1EE),
      Color(0xFFBFD0F2),
      Color(0xFFD8DFF6),
    ],
    [
      Color(0xFFA18CD1),
      Color(0xFFFBC2EB),
      Color(0xFFFFD6F0),
      Color(0xFFFFEAF5),
    ],
  ];

  static const List<List<Color>> postponedDark = [
    [
      Color(0xFF3D2D5F),
      Color(0xFF4D3A7D),
      Color(0xFF5F4794),
      Color(0xFF4D3A70),
    ],
    [
      Color(0xFF3A2D5F),
      Color(0xFF4D3A7D),
      Color(0xFF5F4794),
      Color(0xFF4D3A70),
    ],
  ];

  // UPCOMING - Anticipation
  static const List<List<Color>> upcomingLight = [
    [
      Color(0xFFFFD3B6),
      Color(0xFFFFAAA5),
      Color(0xFFFFBDB8),
      Color(0xFFFFD0CC),
    ],
    [
      Color(0xFFFFAFBD),
      Color(0xFFFFC3A0),
      Color(0xFFFFD4B3),
      Color(0xFFFFE5C6),
    ],
  ];

  static const List<List<Color>> upcomingDark = [
    [
      Color(0xFF5F3D2D),
      Color(0xFF7D4D3A),
      Color(0xFF945F47),
      Color(0xFF704D3A),
    ],
    [
      Color(0xFF5F3A2D),
      Color(0xFF7D4D3A),
      Color(0xFF945F47),
      Color(0xFF704D3A),
    ],
  ];

  // SKIPPED - Intentional Skip
  static const List<List<Color>> skippedLight = [
    [
      Color(0xFFE1BEE7),
      Color(0xFFCE93D8),
      Color(0xFFDDA8E0),
      Color(0xFFECBDE8),
    ],
    [
      Color(0xFFBA68C8),
      Color(0xFFAB47BC),
      Color(0xFFC066CC),
      Color(0xFFD585DC),
    ],
  ];

  static const List<List<Color>> skippedDark = [
    [
      Color(0xFF3A2D47),
      Color(0xFF4D3A5F),
      Color(0xFF5F4770),
      Color(0xFF4D3A5F),
    ],
    [
      Color(0xFF3D2D47),
      Color(0xFF4D3A5F),
      Color(0xFF5F4770),
      Color(0xFF4D3A5F),
    ],
  ];

  // FAILED - Critical Failure
  static const List<List<Color>> failedLight = [
    [
      Color(0xFFEF5350),
      Color(0xFFE53935),
      Color(0xFFEE5F5B),
      Color(0xFFF78581),
    ],
    [
      Color(0xFFF44336),
      Color(0xFFD32F2F),
      Color(0xFFE64A40),
      Color(0xFFF96551),
    ],
  ];

  static const List<List<Color>> failedDark = [
    [
      Color(0xFF5F1F1F),
      Color(0xFF7D2A2A),
      Color(0xFF943535),
      Color(0xFF702A2A),
    ],
    [
      Color(0xFF5F1F1F),
      Color(0xFF7D2A2A),
      Color(0xFF943535),
      Color(0xFF702A2A),
    ],
  ];

  // HOLD - Paused
  static const List<List<Color>> holdLight = [
    [
      Color(0xFFFFE082),
      Color(0xFFFFD54F),
      Color(0xFFFFDD66),
      Color(0xFFFFE57D),
    ],
    [
      Color(0xFFFFCA28),
      Color(0xFFFFB300),
      Color(0xFFFFC233),
      Color(0xFFFFD166),
    ],
  ];

  static const List<List<Color>> holdDark = [
    [
      Color(0xFF5F4D1F),
      Color(0xFF7D612A),
      Color(0xFF947035),
      Color(0xFF70612A),
    ],
    [
      Color(0xFF5F4D1F),
      Color(0xFF7D612A),
      Color(0xFF947035),
      Color(0xFF70612A),
    ],
  ];

  // ================================================================
  // PROGRESS-BASED GRADIENTS (0-100%)
  // ================================================================

  // 0-20% - Just Started
  static const List<List<Color>> progress0to20Light = [
    [
      Color(0xFFFFCDD2),
      Color(0xFFF8BBD0),
      Color(0xFFFFC9D6),
      Color(0xFFFFD7DC),
    ],
    [
      Color(0xFFFFAB91),
      Color(0xFFFFCCBC),
      Color(0xFFFFD7C8),
      Color(0xFFFFE2D4),
    ],
  ];

  static const List<List<Color>> progress0to20Dark = [
    [
      Color(0xFF5F2D2D),
      Color(0xFF7D3A3A),
      Color(0xFF944747),
      Color(0xFF703A3A),
    ],
    [
      Color(0xFF5F3A2D),
      Color(0xFF7D4D3A),
      Color(0xFF945F47),
      Color(0xFF704D3A),
    ],
  ];

  // 21-40% - Getting Started
  static const List<List<Color>> progress21to40Light = [
    [
      Color(0xFFFFE082),
      Color(0xFFFFD54F),
      Color(0xFFFFDD66),
      Color(0xFFFFE57D),
    ],
    [
      Color(0xFFFFCC80),
      Color(0xFFFFB74D),
      Color(0xFFFFC566),
      Color(0xFFFFD37F),
    ],
  ];

  static const List<List<Color>> progress21to40Dark = [
    [
      Color(0xFF5F4D2D),
      Color(0xFF7D612A),
      Color(0xFF947035),
      Color(0xFF70612A),
    ],
    [
      Color(0xFF5F4D2D),
      Color(0xFF7D612A),
      Color(0xFF947035),
      Color(0xFF70612A),
    ],
  ];

  // 41-60% - Half Way
  static const List<List<Color>> progress41to60Light = [
    [
      Color(0xFFFFF59D),
      Color(0xFFFFF176),
      Color(0xFFFFF48C),
      Color(0xFFFFF7A2),
    ],
    [
      Color(0xFFFFEE58),
      Color(0xFFFFEB3B),
      Color(0xFFFFF04D),
      Color(0xFFFFF563),
    ],
  ];

  static const List<List<Color>> progress41to60Dark = [
    [
      Color(0xFF5F5F2D),
      Color(0xFF7D7D3A),
      Color(0xFF949447),
      Color(0xFF707035),
    ],
    [
      Color(0xFF5F5F1F),
      Color(0xFF7D7D2A),
      Color(0xFF949435),
      Color(0xFF70702A),
    ],
  ];

  // 61-80% - Good Progress
  static const List<List<Color>> progress61to80Light = [
    [
      Color(0xFFAED581),
      Color(0xFF9CCC65),
      Color(0xFFAED775),
      Color(0xFFC0E289),
    ],
    [
      Color(0xFF81C784),
      Color(0xFF66BB6A),
      Color(0xFF7ACC7E),
      Color(0xFF8ED792),
    ],
  ];

  static const List<List<Color>> progress61to80Dark = [
    [
      Color(0xFF3D5F2D),
      Color(0xFF4D7D3A),
      Color(0xFF5F9447),
      Color(0xFF4D7035),
    ],
    [
      Color(0xFF2D5F3A),
      Color(0xFF3A7D4D),
      Color(0xFF479461),
      Color(0xFF357047),
    ],
  ];

  // 81-99% - Almost Complete
  static const List<List<Color>> progress81to99Light = [
    [
      Color(0xFF81C784),
      Color(0xFF66BB6A),
      Color(0xFF7ACC7E),
      Color(0xFF8ED792),
    ],
    [
      Color(0xFF4CAF50),
      Color(0xFF43A047),
      Color(0xFF5FB361),
      Color(0xFF7BC67B),
    ],
  ];

  static const List<List<Color>> progress81to99Dark = [
    [
      Color(0xFF2D5F3A),
      Color(0xFF3A7D4D),
      Color(0xFF479461),
      Color(0xFF357047),
    ],
    [
      Color(0xFF1F5F2D),
      Color(0xFF2A7D3A),
      Color(0xFF359447),
      Color(0xFF2A7035),
    ],
  ];

  // 100% - Perfect Complete
  static const List<List<Color>> progress100Light = [
    [
      Color(0xFF43E97B),
      Color(0xFF38F9D7),
      Color(0xFF5FFAE0),
      Color(0xFF85FBEA),
    ],
    [
      Color(0xFF00C853),
      Color(0xFF00E676),
      Color(0xFF33EF8C),
      Color(0xFF66F8A2),
    ],
  ];

  static const List<List<Color>> progress100Dark = [
    [
      Color(0xFF1F5F3A),
      Color(0xFF2A7D4D),
      Color(0xFF358F5F),
      Color(0xFF2A7047),
    ],
    [
      Color(0xFF1F5F2D),
      Color(0xFF2A7D3A),
      Color(0xFF359447),
      Color(0xFF2A7035),
    ],
  ];

  // ================================================================
  // MAIN COLOR ASSIGNMENT METHOD
  // ================================================================

  /// Get gradient colors for a task card
  /// Priority:
  /// 1. Created (Pending/Upcoming) -> Priority Colors
  /// 2. Active (InProgress) -> Status Colors
  /// 3. Completed -> Progress Colors
  static List<Color> getTaskCardGradient({
    required String? priority,
    required String? status,
    required int? progress,
    required bool isDarkMode,
  }) {
    final safeStatus = (status ?? 'pending').toLowerCase();
    final safePriority = (priority ?? 'medium').toLowerCase();
    final safeProgress = progress ?? 0;

    // 1. COMPLETED: Use Progress Colors
    if (safeStatus == 'completed' || safeProgress == 100) {
      return _getProgressGradient(safeProgress, isDarkMode);
    }

    // 2. ACTIVE (InProgress): Use Status Colors
    if (safeStatus == 'inprogress' || safeStatus == 'in_progress') {
      return _getStatusGradient(safeStatus, isDarkMode) ??
          _getPriorityGradient(safePriority, isDarkMode);
    }

    // 3. CREATED (Pending/Upcoming): Use Priority Colors
    if (safeStatus == 'pending' || safeStatus == 'upcoming') {
      return _getPriorityGradient(safePriority, isDarkMode);
    }

    // 4. OTHERS (Missed, Failed, etc.): Use Status Colors
    final statusGradient = _getStatusGradient(safeStatus, isDarkMode);
    if (statusGradient != null) return statusGradient;

    // Default: Priority
    return _getPriorityGradient(safePriority, isDarkMode);
  }

  /// Helper to get a LinearGradient directly (for backward compatibility or specific usage)
  static Gradient getDynamicGradient(
    BuildContext context, {
    required String? recordId, // Unused but kept for signature compatibility
    required String? priority,
    required String? status,
    required int? progress,
    required double? rating, // Unused
    required DateTime? createdAt, // Unused
    required DateTime? dueDate, // Unused
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: getTaskCardGradient(
        priority: priority,
        status: status,
        progress: progress,
        isDarkMode: isDarkMode,
      ),
      begin: begin,
      end: end,
    );
  }

  // ================================================================
  // BUCKET METHODS
  // ================================================================

  static Color getBucketColor(String bucketId) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
    ];
    final index = bucketId.hashCode.abs() % colors.length;
    return colors[index];
  }

  static List<Color> getBucketGradient(String bucketId) {
    final primary = getBucketColor(bucketId);
    return [primary, primary.withOpacity(0.8)];
  }

  // ================================================================
  // HELPER METHODS
  // ================================================================

  static List<Color> _getPriorityGradient(String priority, bool isDarkMode) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return _getRandomGradient(
          isDarkMode ? urgentPriorityDark : urgentPriorityLight,
        );
      case 'high':
        return _getRandomGradient(
          isDarkMode ? highPriorityDark : highPriorityLight,
        );
      case 'medium':
        return _getRandomGradient(
          isDarkMode ? mediumPriorityDark : mediumPriorityLight,
        );
      case 'low':
        return _getRandomGradient(
          isDarkMode ? lowPriorityDark : lowPriorityLight,
        );
      default:
        return _getRandomGradient(
          isDarkMode ? mediumPriorityDark : mediumPriorityLight,
        );
    }
  }

  static List<Color>? _getStatusGradient(String status, bool isDarkMode) {
    switch (status.toLowerCase()) {
      case 'inprogress':
      case 'in_progress':
        return _getRandomGradient(
          isDarkMode ? inProgressDark : inProgressLight,
        );
      case 'completed':
        return _getRandomGradient(isDarkMode ? completedDark : completedLight);
      case 'missed':
      case 'failed':
        return _getRandomGradient(isDarkMode ? missedDark : missedLight);
      case 'cancelled':
        return _getRandomGradient(isDarkMode ? cancelledDark : cancelledLight);
      case 'postponed':
        return _getRandomGradient(isDarkMode ? postponedDark : postponedLight);
      case 'upcoming':
        return _getRandomGradient(isDarkMode ? upcomingDark : upcomingLight);
      case 'skipped':
        return _getRandomGradient(isDarkMode ? skippedDark : skippedLight);
      case 'hold':
        return _getRandomGradient(isDarkMode ? holdDark : holdLight);
      case 'pending':
        return _getRandomGradient(isDarkMode ? pendingDark : pendingLight);
      default:
        return null;
    }
  }

  static List<Color> _getProgressGradient(int progress, bool isDarkMode) {
    if (progress >= 100) {
      return _getRandomGradient(
        isDarkMode ? progress100Dark : progress100Light,
      );
    } else if (progress >= 81) {
      return _getRandomGradient(
        isDarkMode ? progress81to99Dark : progress81to99Light,
      );
    } else if (progress >= 61) {
      return _getRandomGradient(
        isDarkMode ? progress61to80Dark : progress61to80Light,
      );
    } else if (progress >= 41) {
      return _getRandomGradient(
        isDarkMode ? progress41to60Dark : progress41to60Light,
      );
    } else if (progress >= 21) {
      return _getRandomGradient(
        isDarkMode ? progress21to40Dark : progress21to40Light,
      );
    } else {
      return _getRandomGradient(
        isDarkMode ? progress0to20Dark : progress0to20Light,
      );
    }
  }

  static List<Color> _getRandomGradient(List<List<Color>> gradients) {
    final index = DateTime.now().millisecondsSinceEpoch % gradients.length;
    return gradients[index];
  }

  // ================================================================
  // SINGLE COLOR GETTERS (for simple UI elements)
  // ================================================================

  static Color getPriorityColor(String? priority) {
    switch ((priority ?? 'low').toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF7941D);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  /// Color for mood value on 1–10 scale.
  static Color moodColorForValue(double v) {
    if (v >= 9) return const Color(0xFF43E97B);
    if (v >= 7) return const Color(0xFF4FACFE);
    if (v >= 5) return const Color(0xFFFFD54F);
    if (v >= 3) return const Color(0xFFFFA726);
    return const Color(0xFFFF6B6B);
  }

  /// Emoji for mood value on 1–10 scale.
  static String moodEmojiForValue(double v) {
    if (v >= 9) return '😄';
    if (v >= 7) return '😊';
    if (v >= 5) return '😐';
    if (v >= 3) return '😔';
    return '😢';
  }

  static Color getStatusColor(String? status) {
    switch ((status ?? 'pending').toLowerCase()) {
      case 'completed':
        return const Color(0xFF43E97B);
      case 'inprogress':
      case 'in_progress':
        return const Color(0xFF4FACFE);
      case 'pending':
        return const Color(0xFFCFD8DC);
      case 'missed':
      case 'failed':
        return const Color(0xFFFF6B6B);
      case 'cancelled':
        return const Color(0xFFB0BEC5);
      case 'postponed':
        return const Color(0xFFFBC2EB);
      case 'upcoming':
        return const Color(0xFFFFD3B6);
      case 'skipped':
        return const Color(0xFFE1BEE7);
      case 'hold':
        return const Color(0xFFFFE082);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  static Color getProgressColor(int? progress) {
    final safeProgress = progress ?? 0;
    if (safeProgress >= 100) return const Color(0xFF43E97B);
    if (safeProgress >= 80) return const Color(0xFF81C784);
    if (safeProgress >= 60) return const Color(0xFFFFF59D);
    if (safeProgress >= 40) return const Color(0xFFFFE082);
    if (safeProgress >= 20) return const Color(0xFFFFCDD2);
    return const Color(0xFFFFAB91);
  }

  static Color getTierColor(String? tier) {
    switch ((tier ?? 'none').toLowerCase()) {
      case 'nova':
        return const Color(0xFFEF4444);
      case 'radiant':
        return const Color(0xFF10B981);
      case 'prism':
        return const Color(0xFF94A3B8);
      case 'crystal':
        return const Color(0xFF3B82F6);
      case 'blaze':
        return const Color(0xFFEF4444);
      case 'ember':
        return const Color(0xFF10B981);
      case 'flame':
        return const Color(0xFFFF6B35);
      case 'spark':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  static String getTierEmoji(String? tier) {
    switch ((tier ?? 'none').toLowerCase()) {
      case 'nova':
        return '🌟';
      case 'radiant':
        return '👑';
      case 'prism':
        return '🏆';
      case 'crystal':
        return '💎';
      case 'blaze':
        return '⚡';
      case 'ember':
        return '🌿';
      case 'flame':
        return '🔥';
      case 'spark':
        return '✨';
      default:
        return '⭐';
    }
  }

  static BoxDecoration getCardDecoration({
    required String? priority,
    required String? status,
    required int? progress,
    required bool isDarkMode,
    double borderRadius = 16.0,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: getTaskCardGradient(
          priority: priority,
          status: status,
          progress: progress,
          isDarkMode: isDarkMode,
        ),
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

