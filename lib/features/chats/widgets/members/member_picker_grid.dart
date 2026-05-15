// ================================================================
// FILE: lib/features/chat/widgets/members/member_picker_grid.dart
// PURPOSE: Grid of contacts to select for adding to group
// STYLE: WhatsApp-style contact picker with checkboxes
// DEPENDENCIES: user_avatar_cached.dart
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../common/user_avatar_cached.dart';

class MemberPickerGrid extends StatefulWidget {
  final List<ContactItem> contacts;
  final List<String> initialSelectedIds;
  final int maxSelection;
  final Function(List<String> selectedIds) onSelectionChanged;
  final Function()? onDone;
  final Function(String)? onSearch;

  const MemberPickerGrid({
    super.key,
    required this.contacts,
    this.initialSelectedIds = const [],
    this.maxSelection = 100,
    required this.onSelectionChanged,
    this.onDone,
    this.onSearch,
  });

  @override
  State<MemberPickerGrid> createState() => _MemberPickerGridState();
}

class _MemberPickerGridState extends State<MemberPickerGrid> {
  late Set<String> _selectedIds;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.initialSelectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredContacts = _filterContacts();
    final selectedCount = _selectedIds.length;
    final canSelectMore = selectedCount < widget.maxSelection;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.clear_rounded),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
            ),
            onChanged: (query) {
              setState(() => _searchQuery = query);
              widget.onSearch?.call(query);
            },
          ),
        ),

        // Selection info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                selectedCount > 0
                    ? '$selectedCount selected'
                    : 'Select contacts',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (selectedCount > 0)
                TextButton(
                  onPressed: () {
                    setState(() => _selectedIds.clear());
                    widget.onSelectionChanged([]);
                  },
                  child: const Text('Clear'),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Contact grid
        Expanded(
          child: filteredContacts.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];
                    final isSelected = _selectedIds.contains(contact.id);
                    final canSelect = canSelectMore || isSelected;

                    return _ContactGridItem(
                      contact: contact,
                      isSelected: isSelected,
                      canSelect: canSelect,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (isSelected) {
                            _selectedIds.remove(contact.id);
                          } else if (canSelectMore) {
                            _selectedIds.add(contact.id);
                          }
                        });
                        widget.onSelectionChanged(_selectedIds.toList());
                      },
                    );
                  },
                ),
        ),

        // Done button
        if (widget.onDone != null)
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: selectedCount > 0 ? widget.onDone : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Add $selectedCount member${selectedCount != 1 ? 's' : ''}',
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<ContactItem> _filterContacts() {
    // If external search handling is provided, rely on parent to update contacts list
    if (widget.onSearch != null) return widget.contacts;

    if (_searchQuery.isEmpty) return widget.contacts;

    final query = _searchQuery.toLowerCase();
    return widget.contacts.where((contact) {
      return contact.name.toLowerCase().contains(query) ||
          contact.username.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No contacts found'
                : 'No contacts available',
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _ContactGridItem extends StatelessWidget {
  final ContactItem contact;
  final bool isSelected;
  final bool canSelect;
  final VoidCallback onTap;

  const _ContactGridItem({
    required this.contact,
    required this.isSelected,
    required this.canSelect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: canSelect || isSelected ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                UserAvatarCached(
                  imageUrl: contact.avatar,
                  name: contact.name,
                  size: 56,
                ),
                if (isSelected)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              contact.name,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              contact.username,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class ContactItem {
  final String id;
  final String name;
  final String username;
  final String? avatar;
  final bool isOnline;

  const ContactItem({
    required this.id,
    required this.name,
    required this.username,
    this.avatar,
    this.isOnline = false,
  });
}
