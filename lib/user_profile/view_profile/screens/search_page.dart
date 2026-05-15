// ================================================================
// FILE: lib/user_profile/search_page.dart
// User profile search screen with proper state management
// ================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../widgets/app_snackbar.dart';
import '../../../widgets/logger.dart';
import '../../create_edit_profile/profile_models.dart';
import '../../create_edit_profile/profile_provider.dart';
import '../../create_edit_profile/profile_widgets.dart';

/// Screen for searching user profiles.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Local state for search
  List<UserProfile> _searchResults = [];
  bool _isSearching = false;
  String? _error;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Auto-focus on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Debounced search to avoid too many requests
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _error = null;
      });
      return;
    }

    // Show loading immediately
    setState(() {
      _isSearching = true;
      _error = null;
    });

    // Debounce the actual search
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query.trim());
    });
  }

  /// Perform the actual search
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    logD('Searching for: "$query"');

    try {
      final provider = context.read<ProfileProvider>();
      final results = await provider.searchProfiles(query, limit: 30);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _error = null;
        });

        logI('Found ${results.length} users for "$query"');
      }
    } catch (e, s) {
      logE('Search failed', error: e, stackTrace: s);

      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _error = 'Search failed. Please try again.';
        });
      }
    }
  }

  /// Clear search
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
      _error = null;
    });
    _focusNode.requestFocus();
    logI('Search cleared');
  }

  /// Navigate to user profile
  void _openUserProfile(UserProfile user) {
    if (user.id.isEmpty && user.userId.isEmpty) {
      logE('Cannot navigate to profile: User ID is empty');
      AppSnackbar.error('Error', description: 'User profile is invalid.');
      return;
    }

    final userId = user.userId.isNotEmpty ? user.userId : user.id;
    logI('Navigating to user profile: $userId (${user.username})');

    try {
      // Check if it's the current user
      final provider = context.read<ProfileProvider>();
      if (provider.isMyProfile(userId)) {
        context.pushNamed('myProfile');
      } else {
        context.pushNamed(
          'otherUserProfileScreen',
          pathParameters: {'userId': userId},
        );
      }
    } catch (e, s) {
      logE('Navigation error', error: e, stackTrace: s);
      AppSnackbar.error(
        'Failed to open profile',
        description: 'Please try again later.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(appBar: _buildAppBar(theme), body: _buildBody(theme));
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      titleSpacing: 0,
      title: Container(
        margin: const EdgeInsets.only(right: 8),
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search users by name or email...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            border: InputBorder.none,
            prefixIcon: _isSearching
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  )
                : Icon(
                    Icons.search_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
          style: theme.textTheme.bodyLarge,
          textInputAction: TextInputAction.search,
          onChanged: _onSearchChanged,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _performSearch(value.trim());
            }
          },
        ),
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          TextButton(onPressed: _clearSearch, child: const Text('Clear')),
      ],
    );
  }

  Widget _buildBody(ThemeData theme) {
    // Error state
    if (_error != null) {
      return _buildErrorState(theme);
    }

    // Empty search query
    if (_searchController.text.trim().isEmpty) {
      return _buildEmptyQueryState(theme);
    }

    // Loading state
    if (_isSearching && _searchResults.isEmpty) {
      return _buildLoadingState(theme);
    }

    // No results
    if (_searchResults.isEmpty) {
      return _buildNoResultsState(theme);
    }

    // Results list
    return _buildResultsList(theme);
  }

  Widget _buildEmptyQueryState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_search_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Find People',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Search by username or email to find and connect with other users',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildSkeletonTile(theme);
      },
    );
  }

  Widget _buildSkeletonTile(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Avatar skeleton
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          // Text skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 180,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Users Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No users match "${_searchController.text}"\nTry a different search term',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Clear Search'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Search Failed',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Something went wrong',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _performSearch(_searchController.text.trim()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length + 1, // +1 for header
      itemBuilder: (context, index) {
        // Header showing result count
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Text(
                  '${_searchResults.length} ${_searchResults.length == 1 ? 'user' : 'users'} found',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_isSearching) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        final user = _searchResults[index - 1];
        return _buildUserTile(theme, user);
      },
    );
  }

  Widget _buildUserTile(ThemeData theme, UserProfile user) {
    final provider = context.read<ProfileProvider>();
    final isCurrentUser = provider.isMyProfile(
      user.userId.isNotEmpty ? user.userId : user.id,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openUserProfile(user),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              ProfileAvatar(
                imageUrl: user.profileUrl,
                fallbackText: user.username,
                size: 52,
              ),
              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username + badges
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.username,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'You',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (user.isInfluencer) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Email or Organization
                    Text(
                      user.organizationName?.isNotEmpty == true
                          ? user.organizationName!
                          : user.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Location (if available)
                    if (user.address?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              user.address!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
