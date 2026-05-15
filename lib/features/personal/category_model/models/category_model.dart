import 'dart:convert';

/// Model representing a task category_model
class Category {
  /// Unique identifier for the category_model
  final String id;

  /// ID of the user who owns this category_model (null for global)
  final String? userId;

  /// Context this category_model is used for (e.g., long_goal, day_task)
  final String categoryFor;

  /// The type/name of the category_model
  final String categoryType;

  /// List of sub-types associated with this category_model
  final List<String> subTypes;

  /// Optional description of the category_model
  final String? description;

  /// Color associated with the category_model (hex string)
  final String color;

  /// Icon associated with the category_model
  final String icon;

  /// Whether this is a global (system) category_model
  final bool isGlobal;

  /// Timestamp when the category_model was created
  final DateTime createdAt;

  /// Timestamp when the category_model was last updated
  final DateTime updatedAt;

  /// Creates a new [Category] instance
  Category({
    required this.id,
    this.userId,
    required this.categoryFor,
    required this.categoryType,
    this.subTypes = const [],
    this.description,
    required this.color,
    required this.icon,
    this.isGlobal = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Creates a [Category] from a JSON map
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      categoryFor: json['category_for']?.toString() ?? '',
      categoryType: json['category_type']?.toString() ?? '',
      subTypes: _parseJsonbStringList(json['sub_types']),
      description: json['description']?.toString(),
      color: json['color']?.toString() ?? '#4CAF50',
      icon: json['icon']?.toString() ?? '📁',
      isGlobal: json['is_global'] == true ||
          json['is_global'] == 1 ||
          json['is_global']?.toString().toLowerCase() == 'true' ||
          json['is_global']?.toString() == '1',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Converts the category_model to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_for': categoryFor,
      'category_type': categoryType,
      'sub_types': {'items': subTypes},
      'description': description,
      'color': color,
      'icon': icon,
      'is_global': isGlobal,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of the category_model with updated fields
  Category copyWith({
    String? id,
    String? userId,
    String? categoryFor,
    String? categoryType,
    List<String>? subTypes,
    String? description,
    String? color,
    String? icon,
    bool? isGlobal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryFor: categoryFor ?? this.categoryFor,
      categoryType: categoryType ?? this.categoryType,
      subTypes: subTypes ?? this.subTypes,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isGlobal: isGlobal ?? this.isGlobal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Helper class for category_model types constants
class CategoryForType {
  /// Category for long term goals
  static const String longGoal = 'long_goal';

  /// Category for bucket list items
  static const String bucket = 'bucket';

  /// Category for daily tasks
  static const String dayTask = 'day_task';

  /// Category for weekly tasks
  static const String weeklyTask = 'weekly_task';

  /// Category for communities
  static const String community = 'community';

  /// Category for groups
  static const String group = 'group';

  /// Returns all available category_model types
  static List<String> get all => [
    longGoal,
    bucket,
    dayTask,
    weeklyTask,
    community,
    group,
  ];

  /// Gets the display name for a category_model type
  static String getDisplayName(String type) {
    switch (type) {
      case longGoal:
        return 'Long Term Goal';
      case bucket:
        return 'Bucket List';
      case dayTask:
        return 'Daily Task';
      case weeklyTask:
        return 'Weekly Task';
      case community:
        return 'Community';
      case group:
        return 'Group';
      default:
        return type;
    }
  }

  /// Gets the icon for a category_model type
  static String getIcon(String type) {
    switch (type) {
      case longGoal:
        return '🎯';
      case bucket:
        return '⭐';
      case dayTask:
        return '✅';
      case weeklyTask:
        return '📅';
      case community:
        return '👥';
      case group:
        return '👥';
      default:
        return '📁';
    }
  }
}

List<String> _parseJsonbStringList(dynamic v) {
  if (v == null) return [];
  if (v is List) {
    return List<String>.from(v.map((e) => e.toString()));
  }
  if (v is Map) {
    if (v.containsKey('items')) {
      final items = v['items'];
      if (items is List) {
        return List<String>.from(items.map((e) => e.toString()));
      }
    }
  }
  if (v is String && v.isNotEmpty) {
    // Check for PostgreSQL native curly brace array format: {a,b,c}
    if (v.startsWith('{') && v.endsWith('}')) {
      final content = v.substring(1, v.length - 1).trim();
      if (content.isEmpty) return [];
      return content.split(',').map((e) => e.replaceAll('"', '').trim()).toList();
    }
    try {
      final decoded = jsonDecode(v);
      if (decoded is List) {
        return List<String>.from(decoded.map((e) => e.toString()));
      }
      if (decoded is Map && decoded.containsKey('items')) {
        final items = decoded['items'];
        if (items is List) {
          return List<String>.from(items.map((e) => e.toString()));
        }
      }
    } catch (_) {}
  }
  return [];
}
