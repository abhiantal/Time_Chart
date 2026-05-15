// ============================================================
// 📁 providers/save_provider.dart
// Save Provider - State management for bookmark operations
// ============================================================

import 'package:flutter/foundation.dart';

import '../repositories/save_repository.dart';
import '../models/saves_model.dart';
import 'package:the_time_chart/widgets/error_handler.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';

class SaveProvider extends ChangeNotifier {
  final SaveRepository _repository;

  // State
  final Map<String, SaveButtonState> _buttonStates = {};

  SavedPostsList _savedPosts = const SavedPostsList();
  CollectionsList _collections = const CollectionsList();

  String? _currentCollectionFilter;
  String? _searchQuery;

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  SaveProvider({SaveRepository? repository})
    : _repository = repository ?? SaveRepository();

  // ════════════════════════════════════════════════════════════
  // GETTERS
  // ════════════════════════════════════════════════════════════

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  SavedPostsList get savedPosts => _savedPosts;
  CollectionsList get collections => _collections;
  String? get currentCollectionFilter => _currentCollectionFilter;
  String? get searchQuery => _searchQuery;

  int get totalSavedCount => _collections.totalSavedPosts;
  int get collectionCount => _collections.collections.length;

  // ════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ════════════════════════════════════════════════════════════

  /// Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _repository.initializeCache();
      await loadCollections();
      _isInitialized = true;
    } catch (e) {
      _error = 'Failed to initialize saves';
      ErrorHandler.showErrorSnackbar(_error!);
    }

    _isLoading = false;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // BUTTON STATE MANAGEMENT
  // ════════════════════════════════════════════════════════════

  /// Get button state for a post
  SaveButtonState getButtonState(String postId) {
    if (!_buttonStates.containsKey(postId)) {
      _buttonStates[postId] = SaveButtonState(
        postId: postId,
        isSaved: _repository.isPostSavedSync(postId),
      );
    }
    return _buttonStates[postId]!;
  }

  /// Check if a post is saved (sync - from cache)
  bool isPostSaved(String postId) {
    return _repository.isPostSavedSync(postId);
  }

  /// Initialize button states for multiple posts
  Future<void> initializeButtonStates(List<String> postIds) async {
    final statuses = await _repository.checkSaveStatusBatch(postIds);

    for (final entry in statuses.entries) {
      _buttonStates[entry.key] = SaveButtonState(
        postId: entry.key,
        isSaved: entry.value,
      );
    }

    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // ADD THESE METHODS TO YOUR EXISTING SAVE_PROVIDER
  // ════════════════════════════════════════════════════════════

  /// Search saved posts
  Future<void> searchSavedPosts(String query) async {
    if (query.isEmpty) {
      _searchQuery = null;
      await loadSavedPosts(
        collectionName: _currentCollectionFilter,
        refresh: true,
      );
      return;
    }

    _searchQuery = query;
    _isLoading = true;
    notifyListeners();

    try {
      final results = await _repository.searchSavedPosts(
        query: query,
        collectionName: _currentCollectionFilter,
      );

      _savedPosts = SavedPostsList(
        posts: results,
        collectionFilter: _currentCollectionFilter,
        totalCount: results.length,
        hasMore: false,
      );
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Search failed');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = null;
    loadSavedPosts(collectionName: _currentCollectionFilter, refresh: true);
  }

  /// Get collection names for picker
  List<String> get collectionNames => _collections.collectionNames;

  /// Check if collection name exists
  bool hasCollection(String name) => _collections.hasCollection(name);

  /// Get collection by name
  SaveCollection? getCollection(String name) => _collections.findByName(name);

  // ════════════════════════════════════════════════════════════
  // TOGGLE SAVE
  // ════════════════════════════════════════════════════════════

  /// Toggle save for a post (quick save to default collection)
  Future<ToggleSaveResult?> toggleSave(String postId) async {
    // Optimistic update
    final currentState =
        _buttonStates[postId] ?? SaveButtonState(postId: postId);
    _buttonStates[postId] = currentState.copyWith(isLoading: true);
    notifyListeners();

    try {
      final result = await _repository.toggleSave(postId: postId);

      // Update state
      _buttonStates[postId] = currentState.applyToggleResult(result);

      // Update saved posts list if needed
      if (result.isUnsaved) {
        _savedPosts = _savedPosts.removeByPostId(postId);
      }

      // Show feedback
      if (result.isSaved) {
        AppSnackbar.success('Saved');
      } else {
        AppSnackbar.info(title: 'Removed from saved');
      }

      notifyListeners();
      return result;
    } catch (e) {
      // Revert on error
      _buttonStates[postId] = currentState.copyWith(isLoading: false);
      ErrorHandler.showErrorSnackbar('Failed to save post');
      notifyListeners();
      return null;
    }
  }

  /// Save to a specific collection
  Future<ToggleSaveResult?> saveToCollection({
    required String postId,
    required String collectionName,
    String? note,
  }) async {
    final currentState =
        _buttonStates[postId] ?? SaveButtonState(postId: postId);
    _buttonStates[postId] = currentState.copyWith(isLoading: true);
    notifyListeners();

    try {
      final result = await _repository.saveToCollection(
        postId: postId,
        collectionName: collectionName,
        note: note,
      );

      _buttonStates[postId] = currentState.applyToggleResult(result);

      AppSnackbar.success('Saved to $collectionName');

      // Refresh collections
      await loadCollections();

      notifyListeners();
      return result;
    } catch (e) {
      _buttonStates[postId] = currentState.copyWith(isLoading: false);
      ErrorHandler.showErrorSnackbar('Failed to save to collection');
      notifyListeners();
      return null;
    }
  }

  /// Unsave a post
  Future<void> unsavePost(String postId) async {
    await toggleSave(postId);
  }

  // ════════════════════════════════════════════════════════════
  // SAVED POSTS
  // ════════════════════════════════════════════════════════════

  /// Load saved posts
  Future<void> loadSavedPosts({
    String? collectionName,
    bool refresh = false,
  }) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _error = null;

    if (refresh) {
      _savedPosts = const SavedPostsList();
    }

    _currentCollectionFilter = collectionName;
    notifyListeners();

    try {
      _savedPosts = await _repository.getSavedPosts(
        collectionName: collectionName,
        offset: refresh ? 0 : _savedPosts.offset,
      );

      // Update button states
      for (final post in _savedPosts.posts) {
        _buttonStates[post.postId] = SaveButtonState(
          postId: post.postId,
          isSaved: true,
          collectionName: post.collectionName,
        );
      }
    } catch (e) {
      _error = 'Failed to load saved posts';
      ErrorHandler.showErrorSnackbar(_error!);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load more saved posts (pagination)
  Future<void> loadMoreSavedPosts() async {
    if (_isLoading || !_savedPosts.hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final more = await _repository.getSavedPosts(
        collectionName: _currentCollectionFilter,
        offset: _savedPosts.offset + _savedPosts.posts.length,
      );

      _savedPosts = _savedPosts.appendPosts(more.posts);

      // Update button states
      for (final post in more.posts) {
        _buttonStates[post.postId] = SaveButtonState(
          postId: post.postId,
          isSaved: true,
          collectionName: post.collectionName,
        );
      }
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to load more');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // COLLECTIONS
  // ════════════════════════════════════════════════════════════

  /// Load collections
  Future<void> loadCollections() async {
    try {
      _collections = await _repository.getCollections();
      notifyListeners();
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to load collections');
    }
  }

  /// Filter by collection
  void filterByCollection(String? collectionName) {
    _currentCollectionFilter = collectionName;
    loadSavedPosts(collectionName: collectionName, refresh: true);
  }

  /// Clear collection filter
  void clearCollectionFilter() {
    filterByCollection(null);
  }

  /// Create a new collection
  Future<bool> createCollection({
    required String name,
    required String firstPostId,
    String? note,
  }) async {
    try {
      await _repository.createCollection(
        collectionName: name,
        firstPostId: firstPostId,
        note: note,
      );

      AppSnackbar.success('Collection "$name" created');

      // Refresh collections
      await loadCollections();

      return true;
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to create collection');
      return false;
    }
  }

  /// Rename a collection
  Future<bool> renameCollection({
    required String oldName,
    required String newName,
  }) async {
    try {
      await _repository.renameCollection(oldName: oldName, newName: newName);

      // Update local state
      _collections = _collections.renameCollection(oldName, newName);

      // Update filter if needed
      if (_currentCollectionFilter == oldName) {
        _currentCollectionFilter = newName;
      }

      // Update saved posts in memory
      _savedPosts = SavedPostsList(
        posts: _savedPosts.posts.map((p) {
          if (p.collectionName == oldName) {
            return p.copyWith(collectionName: newName);
          }
          return p;
        }).toList(),
        collectionFilter: _currentCollectionFilter,
        totalCount: _savedPosts.totalCount,
        hasMore: _savedPosts.hasMore,
        offset: _savedPosts.offset,
      );

      AppSnackbar.success('Collection renamed');

      notifyListeners();
      return true;
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to rename collection');
      return false;
    }
  }

  /// Delete a collection
  Future<bool> deleteCollection({
    required String collectionName,
    bool deleteSaves = false,
  }) async {
    try {
      final result = await _repository.deleteCollection(
        collectionName: collectionName,
        deleteSaves: deleteSaves,
      );

      // Update local state
      _collections = _collections.removeCollection(collectionName);

      // Clear filter if viewing deleted collection
      if (_currentCollectionFilter == collectionName) {
        _currentCollectionFilter = null;
      }

      // Refresh saved posts
      await loadSavedPosts(
        collectionName: _currentCollectionFilter,
        refresh: true,
      );

      if (result.savesDeleted) {
        AppSnackbar.info(
          title: 'Collection deleted',
          message: '${result.itemsAffected} saves removed',
        );
      } else {
        AppSnackbar.info(
          title: 'Collection deleted',
          message: '${result.itemsAffected} saves moved to All Saved',
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to delete collection');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // MOVE & UPDATE
  // ════════════════════════════════════════════════════════════

  /// Move a save to a different collection
  Future<bool> moveToCollection({
    required String saveId,
    required String newCollectionName,
  }) async {
    try {
      final result = await _repository.moveToCollection(
        saveId: saveId,
        newCollectionName: newCollectionName,
      );

      // Update local state
      _savedPosts = _savedPosts.movePostToCollection(saveId, newCollectionName);

      // Refresh collections counts
      await loadCollections();

      AppSnackbar.success('Moved to $newCollectionName');

      notifyListeners();
      return true;
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to move');
      return false;
    }
  }

  /// Update note on a save
  Future<bool> updateNote({required String saveId, String? note}) async {
    try {
      await _repository.updateNote(saveId: saveId, note: note);

      // Update local state
      final updatedPost = _savedPosts.posts.firstWhere(
        (p) => p.saveId == saveId,
        orElse: () => SavedPost(
          saveId: saveId,
          postId: '',
          savedAt: DateTime.now(),
          postUserId: '',
          postUsername: '',
        ),
      );

      if (updatedPost.postId.isNotEmpty) {
        _savedPosts = _savedPosts.updatePost(
          updatedPost.copyWith(note: note, clearNote: note == null),
        );
      }

      AppSnackbar.success(note != null ? 'Note saved' : 'Note removed');

      notifyListeners();
      return true;
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to update note');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // CLEANUP
  // ════════════════════════════════════════════════════════════

  /// Clear all cached data
  void clearCache() {
    _buttonStates.clear();
    _savedPosts = const SavedPostsList();
    _collections = const CollectionsList();
    _currentCollectionFilter = null;
    _searchQuery = null;
    _isLoading = false;
    _isInitialized = false;
    _error = null;
    _repository.clearCache();
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadCollections();
    await loadSavedPosts(
      collectionName: _currentCollectionFilter,
      refresh: true,
    );
  }

  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}
