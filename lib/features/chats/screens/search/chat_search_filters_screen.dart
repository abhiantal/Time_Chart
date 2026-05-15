import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatSearchFiltersScreen extends StatefulWidget {
  const ChatSearchFiltersScreen({super.key});

  @override
  State<ChatSearchFiltersScreen> createState() =>
      _ChatSearchFiltersScreenState();
}

class _ChatSearchFiltersScreenState extends State<ChatSearchFiltersScreen> {
  String? _selectedChat;
  String? _selectedSender;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _pinnedOnly = false;
  bool _hasMedia = false;
  bool _hasLinks = false;
  bool _hasMentions = false;
  String _sortBy = 'recent';

  final List<Map<String, String>> _sortOptions = [
    {'value': 'recent', 'label': 'Most Recent'},
    {'value': 'oldest', 'label': 'Oldest First'},
    {'value': 'relevance', 'label': 'Relevance'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close_rounded, color: colorScheme.onSurfaceVariant),
        ),
        title: Text(
          'Filters',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(onPressed: _applyFilters, child: const Text('Apply')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader(
            'Date Range',
            Icons.calendar_today_rounded,
            colorScheme,
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('From'),
                    subtitle: Text(
                      _dateFrom != null
                          ? '${_dateFrom!.day}/${_dateFrom!.month}/${_dateFrom!.year}'
                          : 'Any date',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () => _selectDate(context, isFrom: true),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('To'),
                    subtitle: Text(
                      _dateTo != null
                          ? '${_dateTo!.day}/${_dateTo!.month}/${_dateTo!.year}'
                          : 'Any date',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () => _selectDate(context, isFrom: false),
                    ),
                  ),
                  if (_dateFrom != null || _dateTo != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _dateFrom = null;
                          _dateTo = null;
                        });
                      },
                      child: const Text('Clear dates'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Content Type',
            Icons.filter_alt_rounded,
            colorScheme,
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Pinned messages only'),
                    value: _pinnedOnly,
                    onChanged: (value) => setState(() => _pinnedOnly = value!),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.push_pin_rounded,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    title: const Text('Has media'),
                    value: _hasMedia,
                    onChanged: (value) => setState(() => _hasMedia = value!),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.photo_library_rounded,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    title: const Text('Has links'),
                    value: _hasLinks,
                    onChanged: (value) => setState(() => _hasLinks = value!),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.link_rounded,
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    title: const Text('Has mentions'),
                    value: _hasMentions,
                    onChanged: (value) => setState(() => _hasMentions = value!),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Sort By', Icons.sort_rounded, colorScheme),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _sortOptions.map((option) {
                  return RadioListTile<String>(
                    title: Text(option['label']!),
                    value: option['value']!,
                    groupValue: _sortBy,
                    onChanged: (value) => setState(() => _sortBy = value!),
                    activeColor: colorScheme.primary,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetFilters,
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _applyFilters,
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isFrom}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  void _resetFilters() {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedChat = null;
      _selectedSender = null;
      _dateFrom = null;
      _dateTo = null;
      _pinnedOnly = false;
      _hasMedia = false;
      _hasLinks = false;
      _hasMentions = false;
      _sortBy = 'recent';
    });
  }

  void _applyFilters() {
    HapticFeedback.mediumImpact();

    final filters = <String, dynamic>{};
    if (_dateFrom != null) filters['dateFrom'] = _dateFrom!.toIso8601String();
    if (_dateTo != null) filters['dateTo'] = _dateTo!.toIso8601String();
    if (_pinnedOnly) filters['pinnedOnly'] = true;
    if (_hasMedia) filters['hasMedia'] = true;
    if (_hasLinks) filters['hasLinks'] = true;
    if (_hasMentions) filters['hasMentions'] = true;
    filters['sortBy'] = _sortBy;

    Navigator.pop(context, filters);
  }
}
