// lib/features/personal/post_shared/task_model/category_model/providers/category_provider.dart

import 'package:the_time_chart/Authentication/auth_provider.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:the_time_chart/widgets/logger.dart';
import '../models/category_model.dart';
import '../repositories/category_repository.dart';

/// Provider for managing category_model state
class CategoryProvider extends ChangeNotifier {
  CategoryRepository _repository = CategoryRepository();

  void updateAuth(AuthProvider auth) {
    _repository = CategoryRepository();
    notifyListeners();
  }

  // Cache for different category_model types
  final Map<String, List<Category>> _categoriesCache = {};

  bool _isLoading = false;
  String? _error;

  // Getters
  /// Whether an operation is in progress
  bool get isLoading => _isLoading;

  /// Current error message
  String? get error => _error;

  /// Get categories by type (with caching)
  List<Category> getCategoriesByType(String categoryFor) {
    return _categoriesCache[categoryFor] ?? [];
  }

  /// Get all cached categories
  List<Category> get allCategories {
    return _categoriesCache.values.expand((list) => list).toList();
  }

  /// Load categories for a specific type
  Future<void> loadCategoriesByType(
    String categoryFor, {
    bool forceRefresh = false,
  }) async {
    // Return cached data if available and not forcing refresh
    if (!forceRefresh && _categoriesCache.containsKey(categoryFor)) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final categories = await _repository.getCategoriesByType(categoryFor);
      _categoriesCache[categoryFor] = categories;
      _error = null;
    } catch (e, stackTrace) {
      _error = e.toString();
      logE('Error loading categories', error: e, stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all categories
  Future<void> loadAllCategories({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final allCategories = await _repository.getAllCategories();

      // Group by category_for
      _categoriesCache.clear();
      for (var category in allCategories) {
        if (!_categoriesCache.containsKey(category.categoryFor)) {
          _categoriesCache[category.categoryFor] = [];
        }
        _categoriesCache[category.categoryFor]!.add(category);
      }

      _error = null;
    } catch (e, stackTrace) {
      _error = e.toString();
      logE('Error loading all categories', error: e, stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create new user category_model
  Future<Category?> createCategory({
    required String categoryFor,
    required String categoryType,
    List<String>? subTypes,
    String? description,
    String? color,
    String? icon,
  }) async {
    try {
      final newCategory = await _repository.createCategory(
        categoryFor: categoryFor,
        categoryType: categoryType,
        subTypes: subTypes,
        description: description,
        color: color,
        icon: icon,
      );

      // Update cache
      if (newCategory != null) {
        if (!_categoriesCache.containsKey(categoryFor)) {
          _categoriesCache[categoryFor] = [];
        }
        _categoriesCache[categoryFor]!.add(newCategory);
        logI('Created new category_model: ${newCategory.categoryType}');
      }

      notifyListeners();
      return newCategory;
    } catch (e, stackTrace) {
      _error = e.toString();
      logE('Error creating category_model', error: e, stackTrace: stackTrace);
      notifyListeners();
      return null;
    }
  }

  /// Update category_model
  Future<bool> updateCategory({
    required String categoryId,
    String? categoryType,
    List<String>? subTypes,
    String? description,
    String? color,
    String? icon,
  }) async {
    try {
      final updatedCategory = await _repository.updateCategory(
        categoryId: categoryId,
        categoryType: categoryType,
        subTypes: subTypes,
        description: description,
        color: color,
        icon: icon,
      );

      // Update cache
      for (var categoryFor in _categoriesCache.keys) {
        final index = _categoriesCache[categoryFor]!.indexWhere(
          (c) => c.id == categoryId,
        );
        if (index != -1) {
          _categoriesCache[categoryFor]![index] = updatedCategory!;
          break;
        }
      }

      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _error = e.toString();
      logE('Error updating category_model', error: e, stackTrace: stackTrace);
      notifyListeners();
      return false;
    }
  }

  /// Delete category_model
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _repository.deleteCategory(categoryId);

      // Remove from cache
      for (var categoryFor in _categoriesCache.keys) {
        _categoriesCache[categoryFor]!.removeWhere((c) => c.id == categoryId);
      }

      logI('Deleted category_model: $categoryId');
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _error = e.toString();
      logE('Error deleting category_model', error: e, stackTrace: stackTrace);
      notifyListeners();
      return false;
    }
  }

  /// Add sub-type to category_model
  Future<bool> addSubType(String categoryId, String newSubType) async {
    try {
      final updatedCategory = await _repository.addSubType(
        categoryId,
        newSubType,
      );

      // Update cache
      for (var categoryFor in _categoriesCache.keys) {
        final index = _categoriesCache[categoryFor]!.indexWhere(
          (c) => c.id == categoryId,
        );
        if (index != -1) {
          _categoriesCache[categoryFor]![index] = updatedCategory!;
          break;
        }
      }

      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _error = e.toString();
      logE('Error adding sub-type', error: e, stackTrace: stackTrace);
      notifyListeners();
      return false;
    }
  }

  /// Remove sub-type from category_model
  Future<bool> removeSubType(String categoryId, String subType) async {
    try {
      final updatedCategory = await _repository.removeSubType(
        categoryId,
        subType,
      );

      // Update cache
      for (var categoryFor in _categoriesCache.keys) {
        final index = _categoriesCache[categoryFor]!.indexWhere(
          (c) => c.id == categoryId,
        );
        if (index != -1) {
          _categoriesCache[categoryFor]![index] = updatedCategory!;
          break;
        }
      }

      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _error = e.toString();
      logE('Error removing sub-type', error: e, stackTrace: stackTrace);
      notifyListeners();
      return false;
    }
  }

  /// Search categories
  Future<List<Category>> searchCategories(
    String query, {
    String? categoryFor,
  }) async {
    try {
      return await _repository.searchCategories(
        query,
        categoryFor: categoryFor,
      );
    } catch (e, stackTrace) {
      _error = e.toString();
      logE('Error searching categories', error: e, stackTrace: stackTrace);
      notifyListeners();
      return [];
    }
  }

  /// Refresh categories for a specific type
  Future<void> refreshCategories(String categoryFor) async {
    await loadCategoriesByType(categoryFor, forceRefresh: true);
  }

  /// Clear cache
  void clearCache() {
    _categoriesCache.clear();
    notifyListeners();
  }
}
