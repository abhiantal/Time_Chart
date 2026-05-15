import 'dart:convert'; // Add this import

import 'package:the_time_chart/widgets/error_handler.dart';
import 'package:the_time_chart/widgets/logger.dart';
import '../models/category_model.dart';
import 'package:the_time_chart/services/powersync_service.dart';
import 'package:the_time_chart/services/supabase_service.dart';

/// Repository for managing task categories in PowerSync (Offline-First)
class CategoryRepository {
  final PowerSyncService _powerSync;
  final SupabaseService _supabase;
  static const String _tableName = 'categories';

  static final CategoryRepository _instance = CategoryRepository._internal();
  factory CategoryRepository({PowerSyncService? powerSync, SupabaseService? supabase}) {
    return _instance;
  }

  CategoryRepository._internal({PowerSyncService? powerSync, SupabaseService? supabase})
      : _powerSync = powerSync ?? PowerSyncService(),
        _supabase = supabase ?? SupabaseService();

  /// Gets the current authenticated user ID
  String? get _currentUserId => _supabase.currentUserId;

  /// Get categories by type
  Future<List<Category>> getCategoriesByType(String categoryFor) async {
    try {
      final userId = _currentUserId;

      // Fetch global categories
      final globalResults = await _powerSync.executeQuery(
        'SELECT * FROM $_tableName WHERE category_for = ? AND is_global = ? ORDER BY category_type',
        parameters: [categoryFor, 1], // 1 for true
      );

      List<Category> globalCategories = globalResults
          .map((row) => Category.fromJson(_rowToModel(row)))
          .toList();

      // Fetch user categories if logged in
      List<Category> userCategories = [];
      if (userId != null) {
        final userResults = await _powerSync.executeQuery(
          'SELECT * FROM $_tableName WHERE category_for = ? AND user_id = ? AND is_global = ? ORDER BY category_type',
          parameters: [categoryFor, userId, 0], // 0 for false
        );

        userCategories = userResults
            .map((row) => Category.fromJson(_rowToModel(row)))
            .toList();
      }

      // If empty locally and online, fetch from Supabase
      if ((globalCategories.isEmpty && userCategories.isEmpty) && _powerSync.isOnline) {
        logI('Local categories empty. Fetching from Supabase cloud directly for type: $categoryFor');
        try {
          final cloudCategories = await _fetchCategoriesFromSupabase(categoryFor);
          if (cloudCategories.isNotEmpty) {
            for (var category in cloudCategories) {
              await _saveCategoryLocally(category);
            }
            globalCategories = cloudCategories.where((c) => c.isGlobal).toList();
            userCategories = cloudCategories.where((c) => c.userId == userId && !c.isGlobal).toList();
          }
        } catch (e) {
          logW('Failed to fetch/save categories from Supabase directly: $e');
        }
      }

      // Combine and return (user categories first, then global)
      return [...userCategories, ...globalCategories];
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Fetch categories');
      return [];
    }
  }

  /// Get all categories
  Future<List<Category>> getAllCategories() async {
    try {
      final userId = _currentUserId;

      // Fetch global categories
      final globalResults = await _powerSync.executeQuery(
        'SELECT * FROM $_tableName WHERE is_global = ? ORDER BY category_for, category_type',
        parameters: [1],
      );

      List<Category> globalCategories = globalResults
          .map((row) => Category.fromJson(_rowToModel(row)))
          .toList();

      // Fetch user categories if logged in
      List<Category> userCategories = [];
      if (userId != null) {
        final userResults = await _powerSync.executeQuery(
          'SELECT * FROM $_tableName WHERE user_id = ? AND is_global = ? ORDER BY category_for, created_at DESC',
          parameters: [userId, 0],
        );

        userCategories = userResults
            .map((row) => Category.fromJson(_rowToModel(row)))
            .toList();
      }

      // If empty locally and online, fetch from Supabase
      if ((globalCategories.isEmpty && userCategories.isEmpty) && _powerSync.isOnline) {
        logI('Local categories empty. Fetching all categories from Supabase cloud directly');
        try {
          final cloudCategories = await _fetchAllCategoriesFromSupabase();
          if (cloudCategories.isNotEmpty) {
            for (var category in cloudCategories) {
              await _saveCategoryLocally(category);
            }
            globalCategories = cloudCategories.where((c) => c.isGlobal).toList();
            userCategories = cloudCategories.where((c) => c.userId == userId && !c.isGlobal).toList();
          }
        } catch (e) {
          logW('Failed to fetch/save all categories from Supabase directly: $e');
        }
      }

      return [...userCategories, ...globalCategories];
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Fetch all categories');
      return [];
    }
  }

  /// Get only global categories
  Future<List<Category>> getGlobalCategories() async {
    try {
      final results = await _powerSync.executeQuery(
        'SELECT * FROM $_tableName WHERE is_global = ? ORDER BY category_for, category_type',
        parameters: [1],
      );

      return results.map((row) => Category.fromJson(_rowToModel(row))).toList();
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Fetch global categories');
      return [];
    }
  }

  /// Get only user's custom categories
  Future<List<Category>> getUserCategories() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return [];

      final results = await _powerSync.executeQuery(
        'SELECT * FROM $_tableName WHERE user_id = ? AND is_global = ? ORDER BY category_for, created_at DESC',
        parameters: [userId, 0],
      );

      return results.map((row) => Category.fromJson(_rowToModel(row))).toList();
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Fetch user categories');
      return [];
    }
  }

  /// Create a new user category_model
  Future<Category?> createCategory({
    required String categoryFor,
    required String categoryType,
    List<String>? subTypes,
    String? description,
    String? color,
    String? icon,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null || userId.toString().trim().isEmpty) {
        logE(
          '❌ Action denied: Cannot create category without active user session',
        );
        ErrorHandler.showErrorSnackbar(
          'You must be logged in to create a category',
          title: 'Session Error',
        );
        return null;
      }

      // Check if category_model already exists
      final exists = await categoryExists(categoryType, categoryFor);
      if (exists) {
        throw Exception('Category "$categoryType" already exists');
      }

      final now = DateTime.now().toIso8601String();

      final insertData = {
        'user_id': userId,
        'category_for': categoryFor,
        'category_type': categoryType,
        'sub_types': jsonEncode({'items': subTypes ?? []}),
        'description': description,
        'color': color ?? '#4CAF50',
        'icon': icon ?? '📁',
        'is_global': 0,
        'is_active': 1,
        'sort_order': 0,
        'metadata': jsonEncode({}),
        'created_at': now,
        'updated_at': now,
      };

      final id = await _powerSync.insert(_tableName, insertData);

      logI('✅ Category created locally: $id');

      // Return the created category_model
      return Category(
        id: id,
        userId: userId,
        categoryFor: categoryFor,
        categoryType: categoryType,
        subTypes: subTypes ?? [],
        description: description,
        color: color ?? '#4CAF50',
        icon: icon ?? '📁',
        isGlobal: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Create category_model');
      return null;
    }
  }

  /// Update user category_model
  Future<Category?> updateCategory({
    required String categoryId,
    String? categoryType,
    List<String>? subTypes,
    String? description,
    String? color,
    String? icon,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (categoryType != null) updates['category_type'] = categoryType;
      if (subTypes != null) {
        updates['sub_types'] = jsonEncode({'items': subTypes});
      }
      if (description != null) updates['description'] = description;
      if (color != null) updates['color'] = color;
      if (icon != null) updates['icon'] = icon;
      
      // Always update updated_at
      updates['updated_at'] = DateTime.now().toIso8601String();

      if (updates.isEmpty) return null;

      await _powerSync.update(_tableName, updates, categoryId);

      logI('✅ Category updated: $categoryId');

      // Fetch the full updated record to return
      final result = await _powerSync.getById(_tableName, categoryId);
      if (result != null) {
        return Category.fromJson(_rowToModel(result));
      }
      return null;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Update category');
      return null;
    }
  }

  /// Delete user category_model (Syncs to Cloud automatically)
  Future<void> deleteCategory(String categoryId) async {
    try {
      // PowerSync handles the cloud deletion automatically via sync
      await _powerSync.delete(_tableName, categoryId);
      logI('✅ Category deleted: $categoryId');
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Delete category');
      throw Exception('Failed to delete category: $e');
    }
  }

  /// Add sub-type to existing category_model
  Future<Category?> addSubType(String categoryId, String newSubType) async {
    try {
      final result = await _powerSync.getById(_tableName, categoryId);

      if (result == null) return null;

      final category = Category.fromJson(_rowToModel(result));
      final updatedSubTypes = [...category.subTypes];

      if (!updatedSubTypes.contains(newSubType)) {
        updatedSubTypes.add(newSubType);
      } else {
        return category; // Already exists
      }

      return await updateCategory(
        categoryId: categoryId,
        subTypes: updatedSubTypes,
      );
    } catch (e, stackTrace) {
      logE('Failed to add sub-type', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Remove sub-type from category_model
  Future<Category?> removeSubType(
    String categoryId,
    String subTypeToRemove,
  ) async {
    try {
      final result = await _powerSync.getById(_tableName, categoryId);

      if (result == null) return null;

      final category = Category.fromJson(_rowToModel(result));
      final updatedSubTypes = category.subTypes
          .where((st) => st != subTypeToRemove)
          .toList();

      return await updateCategory(
        categoryId: categoryId,
        subTypes: updatedSubTypes,
      );
    } catch (e, stackTrace) {
      logE('Failed to remove sub-type', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Search categories
  Future<List<Category>> searchCategories(
    String query, {
    String? categoryFor,
  }) async {
    try {
      final userId = _currentUserId;
      final params = <dynamic>[];

      // Build query parts
      String sql =
          'SELECT * FROM $_tableName WHERE (category_type LIKE ? OR description LIKE ?)';
      params.add('%$query%');
      params.add('%$query%');

      // Filter by category_for
      if (categoryFor != null) {
        sql += ' AND category_for = ?';
        params.add(categoryFor);
      }

      // Filter by user/global (Global OR (User AND ID))
      if (userId != null) {
        sql += ' AND (is_global = ? OR user_id = ?)';
        params.add(1);
        params.add(userId);
      } else {
        sql += ' AND is_global = ?';
        params.add(1);
      }

      sql += ' ORDER BY category_type';

      final results = await _powerSync.executeQuery(sql, parameters: params);

      return results.map((row) => Category.fromJson(_rowToModel(row))).toList();
    } catch (e, stackTrace) {
      logE('Failed to search categories', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Check if category_model exists for user
  Future<bool> categoryExists(String categoryType, String categoryFor) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return false;

      final results = await _powerSync.executeQuery(
        'SELECT id FROM $_tableName WHERE category_type = ? AND category_for = ? AND user_id = ?',
        parameters: [categoryType, categoryFor, userId],
      );

      return results.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Helper to convert SQLite row to Model JSON
  Map<String, dynamic> _rowToModel(Map<String, dynamic> row) {
    // PowerSyncService.parseJsonbFields handles JSON decoding if we used it,
    // but here we might have manual decoding or the service handles it.
    // Since we are using executeQuery which returns Map<String, dynamic>,
    // and PowerSyncService.insert/update handles encoding.
    // However, executeQuery returns raw rows.

    // We should use parseJsonbFields if we had a list of jsonb columns.
    // Here 'sub_types' is a JSON list.

    final map = _powerSync.parseJsonbFields(row, ['sub_types']);

    // FIX: Handle Postgres Array format if it failed to parse as JSON
    // Postgres arrays come as strings: "{Value 1,Value 2}" or "{\"Value 1\",\"Value 2\"}"
    if (map['sub_types'] is String) {
      String value = map['sub_types'];
      value = value.trim();

      // If it looks like a JSON array, try parsing it as JSON first
      if (value.startsWith('[') && value.endsWith(']')) {
        try {
          map['sub_types'] = List<String>.from(jsonDecode(value));
        } catch (_) {
          map['sub_types'] = <String>[];
        }
      }
      // Handle Postgres Array format {item1,item2}
      else if (value.startsWith('{') && value.endsWith('}')) {
        try {
          // Remove the curly braces
          final content = value.substring(1, value.length - 1);

          if (content.isEmpty) {
            map['sub_types'] = <String>[];
          } else {
            final List<String> result = [];
            final StringBuffer current = StringBuffer();
            bool inQuote = false;

            for (int i = 0; i < content.length; i++) {
              final char = content[i];

              if (char == '"') {
                // Toggle quote state, but don't add the quote char itself if it's a delimiter
                // However, we might need to handle escaped quotes if they exist.
                // For simplicity in this context, we assume standard CSV-like behavior for PG arrays.
                if (i > 0 && content[i - 1] == '\\') {
                  // It's an escaped quote, remove backslash and add quote
                  // (Not implementing full parser here, but basic handling)
                  current.write('"');
                } else {
                  inQuote = !inQuote;
                }
              } else if (char == ',' && !inQuote) {
                // End of item
                result.add(current.toString().trim());
                current.clear();
              } else {
                current.write(char);
              }
            }
            // Add last item
            result.add(current.toString().trim());

            map['sub_types'] = result;
          }
        } catch (e) {
          logE('Error parsing category_model sub_types: $value', error: e);
          map['sub_types'] = <String>[];
        }
      } else {
        // Fallback if it's just a raw string (shouldn't happen for array type but safety first)
        map['sub_types'] = <String>[];
      }
    }

    // Convert boolean integer/string fields to booleans defensively
    if (map['is_global'] is int) {
      map['is_global'] = (map['is_global'] as int) == 1;
    } else if (map['is_global'] is String) {
      final s = map['is_global'].toString().toLowerCase().trim();
      map['is_global'] = s == '1' || s == 'true';
    } else if (map['is_global'] is bool) {
      // already a boolean
    } else if (map['is_global'] != null) {
      map['is_global'] = map['is_global'].toString().toLowerCase() == 'true' ||
          map['is_global'].toString() == '1';
    }

    return map;
  }

  List<String> _parseJsonbStringList(dynamic v) {
    if (v == null) return [];
    if (v is List) {
      return List<String>.from(v.map((e) => e.toString()));
    }
    if (v is String && v.isNotEmpty) {
      try {
        final decoded = jsonDecode(v);
        if (decoded is List) {
          return List<String>.from(decoded.map((e) => e.toString()));
        }
      } catch (_) {}
    }
    return [];
  }

  /// Saves a category locally in PowerSync SQLite database
  Future<void> _saveCategoryLocally(Category category) async {
    try {
      final localData = {
        'id': category.id,
        'user_id': category.userId,
        'category_for': category.categoryFor,
        'category_type': category.categoryType,
        'sub_types': jsonEncode({'items': category.subTypes}),
        'description': category.description,
        'color': category.color,
        'icon': category.icon,
        'is_global': category.isGlobal ? 1 : 0,
        'is_active': 1,
        'sort_order': 0,
        'metadata': jsonEncode({}),
        'created_at': category.createdAt.toIso8601String(),
        'updated_at': category.updatedAt.toIso8601String(),
      };
      
      await _powerSync.put(_tableName, localData);
      logI('✓ Saved category ${category.categoryType} locally in PowerSync SQLite');
    } catch (e, stackTrace) {
      logW('Failed to save category locally: $e', error: e, stackTrace: stackTrace);
    }
  }

  /// Fetches categories from Supabase directly
  Future<List<Category>> _fetchCategoriesFromSupabase(String categoryFor) async {
    try {
      final userId = _currentUserId;
      
      var query = _supabase.client
          .from(_tableName)
          .select()
          .eq('category_for', categoryFor);
          
      if (userId != null) {
        query = query.or('is_global.eq.true,user_id.eq.$userId');
      } else {
        query = query.eq('is_global', true);
      }
      
      final response = await query;
      if (response == null) return [];
      
      final List<dynamic> list = response as List<dynamic>;
      
      return list.map((json) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(json);
        if (map['sub_types'] is String) {
          map['sub_types'] = _parseJsonbStringList(map['sub_types']);
        }
        return Category.fromJson(map);
      }).toList();
    } catch (e, stackTrace) {
      logE('Error fetching categories from Supabase: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Fetches all categories from Supabase directly
  Future<List<Category>> _fetchAllCategoriesFromSupabase() async {
    try {
      final userId = _currentUserId;
      
      var query = _supabase.client.from(_tableName).select();
      
      if (userId != null) {
        query = query.or('is_global.eq.true,user_id.eq.$userId');
      } else {
        query = query.eq('is_global', true);
      }
      
      final response = await query;
      if (response == null) return [];
      
      final List<dynamic> list = response as List<dynamic>;
      
      return list.map((json) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(json);
        if (map['sub_types'] is String) {
          map['sub_types'] = _parseJsonbStringList(map['sub_types']);
        }
        return Category.fromJson(map);
      }).toList();
    } catch (e, stackTrace) {
      logE('Error fetching all categories from Supabase: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }
}
