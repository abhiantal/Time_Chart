// ================================================================
// FILE: lib/features/chat/widgets/search/search_history_list.dart
// PURPOSE: Display recent search history
// STYLE: WhatsApp-style search history
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';

class SearchHistoryList extends StatelessWidget {
  const SearchHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        final history = provider.searchHistory;

        if (history.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Recent searches',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: provider.clearHistory,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: history.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
              itemBuilder: (context, index) {
                final entry = history[index];
                return ListTile(
                  leading: Icon(
                    Icons.history_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  title: Text(entry.query),
                  trailing: IconButton(
                    onPressed: () => provider.deleteHistoryEntry(entry.id),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () => provider.searchFromHistory(entry),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
