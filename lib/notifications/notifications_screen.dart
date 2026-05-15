import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import 'package:the_time_chart/notifications/presentation/providers/notification_provider.dart';
import 'package:the_time_chart/notifications/presentation/widgets/notification_item.dart';
import 'package:the_time_chart/notifications/presentation/models/notification_model.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:the_time_chart/widgets/circular_progress_indicator.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationProvider>().loadNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const NotificationsView();
  }
}

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _filters = [
    {'name': 'All', 'icon': Icons.notifications_rounded, 'color': Colors.blue},
    {'name': 'Tasks', 'icon': Icons.task_alt_rounded, 'color': Colors.green},
    {'name': 'Social', 'icon': Icons.forum_rounded, 'color': Colors.pink},
    {'name': 'System & AI', 'icon': Icons.auto_awesome_rounded, 'color': Colors.purple},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<NotificationProvider>();
    final isDark = theme.brightness == Brightness.dark;

    // Dynamically filter and group notifications
    final grouped = _getFilteredAndGroupedNotifications(provider.notifications);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Inbox',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          if (provider.notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: IconButton(
                onPressed: () => _confirmClearAll(context, provider),
                tooltip: 'Sweep All',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.delete_sweep_rounded,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Elegant Glowing Background Blobs
          _buildBackgroundDecor(context),

          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal category selector row
                _buildFilterRow(provider.notifications),
                
                const SizedBox(height: 8),

                Expanded(
                  child: provider.isLoading && provider.notifications.isEmpty
                      ? const Center(
                          child: AdvancedProgressIndicator(
                            size: 48,
                            progress: 0.5,
                            customLabel: 'Decrypting feed...',
                            labelStyle: ProgressLabelStyle.custom,
                          ),
                        )
                      : _buildNotificationsList(grouped, provider, theme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Horizontal Category Filter Pills
  Widget _buildFilterRow(List<NotificationModel> allNotifications) {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final String name = filter['name'] as String;
          final IconData icon = filter['icon'] as IconData;
          final Color filterColor = filter['color'] as Color;
          final isSelected = _selectedFilter == name;

          // Compute count dynamically
          final count = _getFilterCount(allNotifications, name);

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedFilter = name;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? filterColor.withValues(alpha: 0.12)
                        : Theme.of(context).cardColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? filterColor.withValues(alpha: 0.35)
                          : Theme.of(context).dividerColor.withValues(alpha: 0.05),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: filterColor.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: isSelected ? filterColor : Theme.of(context).hintColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        name == 'System & AI' ? 'System & AI' : name,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).hintColor,
                              fontSize: 13,
                            ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? filterColor : Theme.of(context).hintColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$count',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: isSelected ? Colors.white : Theme.of(context).hintColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Dynamic grouping logic inside the view to avoid altering provider classes
  Map<String, List<NotificationModel>> _getFilteredAndGroupedNotifications(List<NotificationModel> notifications) {
    if (notifications.isEmpty) return {};

    // 1. Filter
    final filtered = notifications.where((notif) {
      final type = notif.type.toLowerCase();
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Tasks') {
        return type.contains('task') ||
            type.contains('remind') ||
            type.contains('overdue') ||
            type.contains('goal') ||
            type.contains('milestone') ||
            type.contains('bucket');
      }
      if (_selectedFilter == 'Social') {
        return type.contains('chat') ||
            type.contains('message') ||
            type.contains('msg') ||
            type.contains('like') ||
            type.contains('comment') ||
            type.contains('reply') ||
            type.contains('follow') ||
            type.contains('mention');
      }
      if (_selectedFilter == 'System & AI') {
        return type.contains('ai') ||
            type.contains('gpt') ||
            type.contains('token') ||
            type.contains('system') ||
            type.contains('announcement') ||
            type.contains('alert') ||
            type.contains('maintenance');
      }
      return true;
    }).toList();

    if (filtered.isEmpty) return {};

    // 2. Group
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final Map<String, List<NotificationModel>> grouped = {};

    for (final notif in filtered) {
      final d = DateTime(
        notif.createdAt.year,
        notif.createdAt.month,
        notif.createdAt.day,
      );
      final group = d.isAtSameMomentAs(today)
          ? 'Today'
          : d.isAtSameMomentAs(yesterday)
          ? 'Yesterday'
          : 'Earlier';
      grouped.putIfAbsent(group, () => []).add(notif);
    }

    for (final list in grouped.values) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return {
      if (grouped.containsKey('Today')) 'Today': grouped['Today']!,
      if (grouped.containsKey('Yesterday')) 'Yesterday': grouped['Yesterday']!,
      if (grouped.containsKey('Earlier')) 'Earlier': grouped['Earlier']!,
    };
  }

  int _getFilterCount(List<NotificationModel> notifications, String filter) {
    if (filter == 'All') return notifications.length;
    return notifications.where((notif) {
      final type = notif.type.toLowerCase();
      if (filter == 'Tasks') {
        return type.contains('task') ||
            type.contains('remind') ||
            type.contains('overdue') ||
            type.contains('goal') ||
            type.contains('milestone') ||
            type.contains('bucket');
      }
      if (filter == 'Social') {
        return type.contains('chat') ||
            type.contains('message') ||
            type.contains('msg') ||
            type.contains('like') ||
            type.contains('comment') ||
            type.contains('reply') ||
            type.contains('follow') ||
            type.contains('mention');
      }
      if (filter == 'System & AI') {
        return type.contains('ai') ||
            type.contains('gpt') ||
            type.contains('token') ||
            type.contains('system') ||
            type.contains('announcement') ||
            type.contains('alert') ||
            type.contains('maintenance');
      }
      return false;
    }).length;
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  _buildGradientBlob(
                    size: 200,
                    color: theme.primaryColor.withValues(alpha: 0.06),
                  ),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.05),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 64,
                      color: theme.primaryColor.withValues(alpha: 0.35),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: theme.primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Inbox fully cleared',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _selectedFilter == 'All'
                    ? 'No new alerts found. You are fully up to date!'
                    : 'No pending items matching the "$_selectedFilter" category.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.hintColor,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundDecor(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -80,
          child: _buildGradientBlob(
            size: 350,
            color: theme.primaryColor.withValues(alpha: 0.08),
          ),
        ),
        Positioned(
          bottom: 80,
          left: -120,
          child: _buildGradientBlob(
            size: 450,
            color: theme.colorScheme.secondary.withValues(alpha: 0.05),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientBlob({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(
    Map<String, List<NotificationModel>> grouped,
    NotificationProvider provider,
    ThemeData theme,
  ) {
    if (grouped.isEmpty) {
      return CustomScrollView(
        slivers: [_buildEmptyState(context)],
      );
    }

    final groupTitles = grouped.keys.toList();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: groupTitles.length,
      itemBuilder: (context, index) {
        final groupTitle = groupTitles[index];
        final items = grouped[groupTitle]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
              child: Row(
                children: [
                  Text(
                    groupTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${items.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...items.map(
              (notif) => NotificationItem(
                notification: notif,
                onTap: () => provider.handleTap(context, notif),
                onDelete: () => provider.deleteNotification(notif.id),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    NotificationProvider provider,
  ) async {
    final theme = Theme.of(context);

    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Clear All',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.05),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_sweep_rounded,
                      color: theme.colorScheme.error,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sweep Inbox?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'All currently visible notifications will be permanently cleared.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Sweep All',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );

    if (result == true) {
      HapticFeedback.heavyImpact();
      await provider.markAllAsRead();
      if (context.mounted) {
        AppSnackbar.success('Sweeped', description: 'Inbox fully cleared');
      }
    }
  }
}
