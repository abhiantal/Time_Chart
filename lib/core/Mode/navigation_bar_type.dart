// lib/user_settings/models/navigation_bar_type.dart
import 'package:flutter/material.dart';

enum NavigationBarType { personal, social }

extension NavigationBarTypeExtension on NavigationBarType {
  String get displayName {
    switch (this) {
      case NavigationBarType.personal:
        return 'Personal Growth';
      case NavigationBarType.social:
        return 'Social Feed';
    }
  }

  IconData get icon {
    switch (this) {
      case NavigationBarType.personal:
        return Icons.psychology_outlined;
      case NavigationBarType.social:
        return Icons.groups_outlined;
    }
  }

  String get description {
    switch (this) {
      case NavigationBarType.personal:
        return 'Task management, diary, and growth tools';
      case NavigationBarType.social:
        return 'Social feeds, reels, and community features';
    }
  }

  Color getPrimaryColor(bool isDark) {
    switch (this) {
      case NavigationBarType.personal:
        return isDark ? Colors.tealAccent[400]! : Colors.blue[600]!;
      case NavigationBarType.social:
        return const Color(0xFFE91E63);
    }
  }
}
