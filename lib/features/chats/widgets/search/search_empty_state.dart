// ================================================================
// FILE: lib/features/chat/widgets/search/search_empty_state.dart
// PURPOSE: Empty state for search results
// STYLE: Clean illustration with message
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../common/empty_state_illustration.dart';

class SearchEmptyState extends StatelessWidget {
  final EmptyStateType type;
  final String? searchQuery;
  final VoidCallback? onAction;
  final bool compact;

  const SearchEmptyState({
    super.key,
    this.type = EmptyStateType.noSearchResults,
    this.searchQuery,
    this.onAction,
    this.compact = false,
  });

  const SearchEmptyState.mini({
    super.key,
    required IconData icon,
    required String text,
  }) : type = EmptyStateType.custom,
       searchQuery = null,
       onAction = null,
       compact = true;

  @override
  Widget build(BuildContext context) {
    return EmptyStateIllustration(
      type: type,
      title: _getTitle(),
      description: 'Your search returned no results.',
      compact: compact,
    );
  }

  String _getTitle() {
    if (type == EmptyStateType.noSearchResults) {
      return 'No results found';
    }
    return 'No results';
  }

  String _getDescription() {
    if (searchQuery != null) {
      return 'No results for "$searchQuery"';
    }
    return 'Try a different search term';
  }
}
