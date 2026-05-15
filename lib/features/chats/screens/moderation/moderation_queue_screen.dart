import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../widgets/error_handler.dart';
import '../../widgets/common/loading_shimmer_list.dart';

class ModerationQueueScreen extends StatefulWidget {
  const ModerationQueueScreen({super.key});

  @override
  State<ModerationQueueScreen> createState() => _ModerationQueueScreenState();
}

class _ModerationQueueScreenState extends State<ModerationQueueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  final List<QueueItem> _messageQueue = [];
  final List<QueueItem> _userQueue = [];
  final List<QueueItem> _communityQueue = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadQueue();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQueue() async {
    try {
      setState(() => _isLoading = true);

      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _messageQueue.addAll([
          QueueItem(
            id: 'm1',
            type: 'message',
            content: 'User reported message for harassment',
            submittedBy: 'Sarah Chen',
            submittedAt: DateTime.now().subtract(const Duration(hours: 1)),
            priority: 'high',
            status: 'pending',
          ),
          QueueItem(
            id: 'm2',
            type: 'message',
            content: 'Spam message reported',
            submittedBy: 'Mike Johnson',
            submittedAt: DateTime.now().subtract(const Duration(hours: 3)),
            priority: 'medium',
            status: 'pending',
          ),
        ]);

        _userQueue.addAll([
          QueueItem(
            id: 'u1',
            type: 'user',
            content: 'User reported for fake account',
            submittedBy: 'Alex Rivera',
            submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
            priority: 'medium',
            status: 'pending',
          ),
        ]);

        _communityQueue.addAll([
          QueueItem(
            id: 'c1',
            type: 'community',
            content: 'Community reported for inappropriate name',
            submittedBy: 'Emma Wilson',
            submittedAt: DateTime.now().subtract(const Duration(hours: 5)),
            priority: 'low',
            status: 'pending',
          ),
        ]);

        _isLoading = false;
      });
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'ModerationQueueScreen.loadQueue');
      setState(() => _isLoading = false);
    }
  }

  void _processItem(QueueItem item, String action) async {
    try {
      HapticFeedback.mediumImpact();
      ErrorHandler.showLoading('Processing...');

      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        switch (item.type) {
          case 'message':
            _messageQueue.remove(item);
            break;
          case 'user':
            _userQueue.remove(item);
            break;
          case 'community':
            _communityQueue.remove(item);
            break;
        }
      });

      ErrorHandler.hideLoading();
      ErrorHandler.showSuccessSnackbar('Item ${action.toLowerCase()}');
    } catch (e, st) {
      ErrorHandler.hideLoading();
      ErrorHandler.handleError(e, st, 'ModerationQueueScreen.processItem');
      ErrorHandler.showErrorSnackbar('Failed to process item');
    }
  }

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
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          'Moderation Queue',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Messages'),
                  if (_messageQueue.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_messageQueue.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Users'),
                  if (_userQueue.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_userQueue.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Communities'),
                  if (_communityQueue.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_communityQueue.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingShimmerList(itemCount: 5)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildQueueList(_messageQueue, theme, colorScheme),
                _buildQueueList(_userQueue, theme, colorScheme),
                _buildQueueList(_communityQueue, theme, colorScheme),
              ],
            ),
    );
  }

  Widget _buildQueueList(
    List<QueueItem> items,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.done_all_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Queue Empty',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No items waiting for moderation',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _QueueCard(
          item: item,
          onProcess: (action) => _processItem(item, action),
          colorScheme: colorScheme,
        );
      },
    );
  }
}

class QueueItem {
  final String id;
  final String type;
  final String content;
  final String submittedBy;
  final DateTime submittedAt;
  final String priority;
  final String status;

  QueueItem({
    required this.id,
    required this.type,
    required this.content,
    required this.submittedBy,
    required this.submittedAt,
    required this.priority,
    required this.status,
  });
}

class _QueueCard extends StatelessWidget {
  final QueueItem item;
  final Function(String) onProcess;
  final ColorScheme colorScheme;

  const _QueueCard({
    required this.item,
    required this.onProcess,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getPriorityColor(item.priority).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTypeColor(item.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(item.type),
                    color: _getTypeColor(item.type),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.type.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _getTypeColor(item.type),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatTime(item.submittedAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(
                      item.priority,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.priority.toUpperCase(),
                    style: TextStyle(
                      color: _getPriorityColor(item.priority),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(item.content),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Reported by: ${item.submittedBy}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: onProcess,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'Approve',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Approve'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'Reject',
                      child: Row(
                        children: [
                          Icon(Icons.cancel_rounded, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Reject'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'Escalate',
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8),
                          Text('Escalate'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'message':
        return Colors.blue;
      case 'user':
        return Colors.purple;
      case 'community':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'message':
        return Icons.message_rounded;
      case 'user':
        return Icons.person_rounded;
      case 'community':
        return Icons.group_rounded;
      default:
        return Icons.report_rounded;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}
