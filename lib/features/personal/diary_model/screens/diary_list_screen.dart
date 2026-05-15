// lib/features/diary/screens_widgets/diary_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../../../../widgets/error_handler.dart';
import '../../../../../helpers/card_color_helper.dart';
import '../../../../../widgets/circular_progress_indicator.dart';
import '../../../../../widgets/logger.dart';
import '../repositories/diary_repository.dart';
import '../models/diary_entry_model.dart';
import '../../../../widgets/feature_info_widgets.dart';

class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key});

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen>
    with TickerProviderStateMixin {
  final _diaryRepo = DiaryRepository();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<DiaryEntryModel> _allEntries = [];
  List<DiaryEntryModel> _filteredEntries = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  DateTimeRange? _dateRange;
  String? _selectedMood;
  StreamSubscription<List<DiaryEntryModel>>? _entriesSubscription;

  late AnimationController _listAnimationController;
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;

  final List<String> _filterOptions = [
    'all',
    'this_week',
    'this_month',
    'with_mood',
    'with_summary',
    'favorites',
    'pinned',
  ];

  final List<String> _moodOptions = [
    'Great',
    'Good',
    'Okay',
    'Bad',
    'Terrible',
  ];

  @override
  void initState() {
    super.initState();
    logI('📚 Initializing DiaryListScreen');

    _initAnimations();
    _setupEntriesStream();

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _entriesSubscription?.cancel();
    _listAnimationController.dispose();
    _searchAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _searchAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.easeOut,
      ),
    );
  }

  void _setupEntriesStream() {
    try {
      logD('Setting up diary entries stream...');
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        logE('❌ No authenticated user');
        ErrorHandler.showErrorSnackbar('Please log in to view entries');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      _entriesSubscription = _diaryRepo
          .watchUserEntries(userId, limit: 100)
          .listen(
            (entries) {
              if (mounted) {
                setState(() {
                  _allEntries = entries;
                  _applyFilters();
                  _isLoading = false;
                });

                if (!_listAnimationController.isAnimating &&
                    !_listAnimationController.isCompleted) {
                  _listAnimationController.forward();
                }
                logI('✅ Stream updated with ${_allEntries.length} entries');
              }
            },
            onError: (e, stackTrace) {
              logE(
                '❌ Error streaming entries',
                error: e,
                stackTrace: stackTrace,
              );
              if (mounted) {
                setState(() => _isLoading = false);
                ErrorHandler.showErrorSnackbar('Failed to load entries');
              }
            },
          );
    } catch (e, stackTrace) {
      logE(
        '❌ Error setting up entries stream',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showErrorSnackbar('Failed to load entries');
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    logD(
      'Applying filters: query="$_searchQuery", filter="$_selectedFilter", mood="\$_selectedMood"',
    );

    List<DiaryEntryModel> result = List.from(_allEntries);

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      result = result.where((entry) {
        final title = entry.title?.toLowerCase() ?? '';
        final content = entry.content?.toLowerCase() ?? '';
        final dateStr = DateFormat(
          'MMMM d yyyy EEEE',
        ).format(entry.entryDate).toLowerCase();
        final moodLabel = entry.mood?.label?.toLowerCase() ?? '';

        return title.contains(_searchQuery) ||
            content.contains(_searchQuery) ||
            dateStr.contains(_searchQuery) ||
            moodLabel.contains(_searchQuery);
      }).toList();
    }

    // Apply time filter
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'this_week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        result = result
            .where(
              (e) => e.entryDate.isAfter(
                startOfWeek.subtract(const Duration(days: 1)),
              ),
            )
            .toList();
        break;
      case 'this_month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        result = result
            .where(
              (e) => e.entryDate.isAfter(
                startOfMonth.subtract(const Duration(days: 1)),
              ),
            )
            .toList();
        break;
      case 'with_mood':
        result = result.where((e) => e.hasMood).toList();
        break;
      case 'with_summary':
        result = result
            .where((e) => e.aiSummary != null && e.aiSummary!.isNotEmpty)
            .toList();
        break;
      case 'favorites':
        result = result.where((e) => e.isFavorite).toList();
        break;
      case 'pinned':
        result = result.where((e) => e.isPinned).toList();
        break;
    }

    // Apply date range
    if (_dateRange != null) {
      result = result
          .where(
            (e) =>
                e.entryDate.isAfter(
                  _dateRange!.start.subtract(const Duration(days: 1)),
                ) &&
                e.entryDate.isBefore(
                  _dateRange!.end.add(const Duration(days: 1)),
                ),
          )
          .toList();
    }

    // Apply mood filter
    if (_selectedMood != null) {
      result = result
          .where(
            (e) => e.mood?.label?.toLowerCase() == _selectedMood!.toLowerCase(),
          )
          .toList();
    }

    // Sort by date (newest first)
    result.sort((a, b) => b.entryDate.compareTo(a.entryDate));

    setState(() {
      _filteredEntries = result;
    });

    logD('Filtered to ${_filteredEntries.length} entries');
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _searchAnimationController.forward();
      } else {
        _searchAnimationController.reverse();
        _searchController.clear();
        _searchQuery = '';
        _applyFilters();
      }
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: Theme.of(context).colorScheme),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _applyFilters();
      });
      logD('Date range selected: ${picked.start} to ${picked.end}');
    }
  }

  void _clearDateRange() {
    setState(() {
      _dateRange = null;
      _applyFilters();
    });
  }

  void _navigateToEntry(DiaryEntryModel entry) {
    if (entry.id.isEmpty) {
      logE('❌ Cannot navigate to entry: ID is empty');
      ErrorHandler.showErrorSnackbar('Cannot open entry: Invalid ID');
      return;
    }

    logD('Navigating to entry: ${entry.id}');
    try {
      context.pushNamed(
        'diaryEntryDetailScreen',
        pathParameters: {'entryId': entry.id},
        extra: entry,
      );
    } catch (e) {
      logE('❌ Navigation error', error: e);
      ErrorHandler.showErrorSnackbar('Navigation failed: ${e.toString()}');
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(theme),
          _buildFilterChips(theme),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredEntries.isEmpty
            ? _buildEmptyState(theme)
            : _buildEntriesList(theme),
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: true,
      centerTitle: false,
      expandedHeight: _isSearching ? 130 : 100,
      backgroundColor: theme.colorScheme.surface,
      title: _isSearching
          ? null
          : Text(
              'My Diary',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
      flexibleSpace: _isSearching
          ? FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.only(
                  top: 100,
                  left: 16,
                  right: 16,
                  bottom: 8,
                ),
                child: FadeTransition(
                  opacity: _searchAnimation,
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search entries...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      actions: [
        IconButton(
          onPressed: () => FeatureInfoCard.showEliteDialog(
            context,
            EliteFeatures.diary,
          ),
          icon: Icon(
            Icons.help_outline_rounded,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            size: 22,
          ),
          tooltip: 'How It Works',
        ),
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: _toggleSearch,
          tooltip: _isSearching ? 'Close Search' : 'Search',
        ),
        IconButton(
          icon: const Icon(Icons.date_range),
          onPressed: _selectDateRange,
          tooltip: 'Filter by Date',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filter by Mood',
          onSelected: (value) {
            setState(() {
              _selectedMood = value == 'clear_mood' ? null : value;
              _applyFilters();
            });
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'clear_mood', child: Text('All Moods')),
            const PopupMenuDivider(),
            ..._moodOptions.map(
              (mood) => PopupMenuItem(
                value: mood,
                child: Row(
                  children: [
                    Text(_getMoodEmoji(mood)),
                    const SizedBox(width: 8),
                    Text(mood),
                    if (_selectedMood == mood)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, size: 18),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._filterOptions.map(
                    (filter) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_getFilterLabel(filter)),
                        selected: _selectedFilter == filter,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = selected ? filter : 'all';
                            _applyFilters();
                          });
                          HapticFeedback.selectionClick();
                        },
                        avatar: _selectedFilter == filter
                            ? const Icon(Icons.check, size: 18)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_dateRange != null) ...[
              const SizedBox(height: 8),
              Chip(
                avatar: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                ),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: _clearDateRange,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${_filteredEntries.length} ${_filteredEntries.length == 1 ? 'entry' : 'entries'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_searchQuery.isNotEmpty ||
                    _selectedFilter != 'all' ||
                    _dateRange != null ||
                    _selectedMood != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                        _selectedFilter = 'all';
                        _dateRange = null;
                        _selectedMood = null;
                        _filteredEntries = _allEntries;
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear All'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: FeatureInfoCard(feature: EliteFeatures.diary),
      ),
    );
  }

  Widget _buildEntriesList(ThemeData theme) {
    // Group entries by month
    final groupedEntries = <String, List<DiaryEntryModel>>{};
    for (final entry in _filteredEntries) {
      final monthKey = DateFormat('MMMM yyyy').format(entry.entryDate);
      groupedEntries.putIfAbsent(monthKey, () => []).add(entry);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: groupedEntries.length,
      itemBuilder: (context, groupIndex) {
        final monthKey = groupedEntries.keys.elementAt(groupIndex);
        final monthEntries = groupedEntries[monthKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      monthKey,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${monthEntries.length} ${monthEntries.length == 1 ? 'entry' : 'entries'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Entries for this month
            ...monthEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final diaryEntry = entry.value;
              return _buildEntryCard(
                theme,
                diaryEntry,
                groupIndex * 10 + index,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildEntryCard(ThemeData theme, DiaryEntryModel entry, int index) {
    final decoration = CardColorHelper.getCardDecoration(
      priority: entry.mood?.label,
      status: entry.aiSummary != null ? 'completed' : 'in_progress',
      progress: _calculateProgress(entry),
      isDarkMode: Theme.of(context).brightness == Brightness.dark,
      borderRadius: 16,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 300)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Container(
          decoration: decoration,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToEntry(entry),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Badge
                        Container(
                          width: 56,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${entry.entryDate.day}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat(
                                  'EEE',
                                ).format(entry.entryDate).toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.title ?? 'Untitled Entry',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Status badges
                                  if (entry.isPinned)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.push_pin,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  if (entry.isFavorite)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.favorite,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                              if (entry.content != null &&
                                  entry.content!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  entry.content!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Mood Emoji
                        if (entry.hasMood)
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                entry.mood?.emoji ?? '😊',
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Footer Row
                    Row(
                      children: [
                        // Metrics
                        if (entry.aiSummary != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'AI',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (entry.hasQnA) ...[
                          if (entry.aiSummary != null) const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.question_answer,
                                  size: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${entry.shotQna!.length}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        // Progress Indicator
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: AdvancedProgressIndicator(
                            progress: _calculateProgress(entry) / 100,
                            size: 36,
                            strokeWidth: 3,
                            shape: ProgressShape.circular,
                            labelStyle: ProgressLabelStyle.none,
                            backgroundColor: Colors.white.withOpacity(0.25),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.white.withOpacity(0.8),
                          size: 24,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'All';
      case 'this_week':
        return 'This Week';
      case 'this_month':
        return 'This Month';
      case 'with_mood':
        return 'With Mood';
      case 'with_summary':
        return 'AI Summarized';
      case 'favorites':
        return 'Favorites';
      case 'pinned':
        return 'Pinned';
      default:
        return filter;
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'great':
        return '😄';
      case 'good':
        return '😊';
      case 'okay':
        return '😐';
      case 'bad':
        return '😔';
      case 'terrible':
        return '😢';
      default:
        return '😊';
    }
  }

  int _calculateProgress(DiaryEntryModel entry) {
    int progress = 0;
    if (entry.title?.isNotEmpty ?? false) progress += 20;
    if (entry.hasMood) progress += 20;
    if ((entry.content?.length ?? 0) > 0) {
      progress += ((entry.content!.length / 500) * 40).clamp(0, 40).toInt();
    }
    if (entry.hasQnA) {
      final answered = entry.shotQna!.where((q) => q.isAnswered).length;
      progress += ((answered / entry.shotQna!.length) * 20).toInt();
    }
    return progress.clamp(0, 100);
  }
}
