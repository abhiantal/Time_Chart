import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../widgets/error_handler.dart';
import '../../widgets/common/empty_state_illustration.dart';
import '../../widgets/common/loading_shimmer_list.dart';

class ReportedContentScreen extends StatefulWidget {
  const ReportedContentScreen({super.key});

  @override
  State<ReportedContentScreen> createState() => _ReportedContentScreenState();
}

class _ReportedContentScreenState extends State<ReportedContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  final List<ReportedItem> _pendingReports = [];
  final List<ReportedItem> _resolvedReports = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    try {
      setState(() => _isLoading = true);

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _pendingReports.addAll([
          ReportedItem(
            id: '1',
            type: 'message',
            content: 'This message contains inappropriate content',
            reporterId: 'user1',
            reporterName: 'Sarah Chen',
            reportedId: 'message123',
            reportedContent: 'You are all idiots',
            reason: 'Harassment',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            status: 'pending',
            severity: 'high',
          ),
          ReportedItem(
            id: '2',
            type: 'user',
            content: 'Suspicious account behavior',
            reporterId: 'user2',
            reporterName: 'Mike Johnson',
            reportedId: 'user456',
            reportedName: 'John Doe',
            reason: 'Spam',
            timestamp: DateTime.now().subtract(const Duration(hours: 5)),
            status: 'pending',
            severity: 'medium',
          ),
          ReportedItem(
            id: '3',
            type: 'community',
            content: 'Community rules violation',
            reporterId: 'user3',
            reporterName: 'Alex Rivera',
            reportedId: 'community789',
            reportedName: 'Gaming Community',
            reason: 'Inappropriate content',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            status: 'pending',
            severity: 'low',
          ),
        ]);

        _resolvedReports.addAll([
          ReportedItem(
            id: '4',
            type: 'message',
            content: 'Spam message reported',
            reporterId: 'user4',
            reporterName: 'Emma Wilson',
            reportedId: 'message456',
            reportedContent: 'Check out this amazing product...',
            reason: 'Spam',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            resolvedAt: DateTime.now().subtract(const Duration(days: 1)),
            resolvedBy: 'Admin',
            action: 'Removed',
            status: 'resolved',
            severity: 'medium',
          ),
        ]);

        _isLoading = false;
      });
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'ReportedContentScreen.loadReports');
      setState(() => _isLoading = false);
    }
  }

  void _resolveReport(ReportedItem report, String action) async {
    try {
      HapticFeedback.mediumImpact();
      ErrorHandler.showLoading('Processing...');

      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        report.status = 'resolved';
        report.resolvedAt = DateTime.now();
        report.resolvedBy = 'Admin';
        report.action = action;
        _pendingReports.remove(report);
        _resolvedReports.insert(0, report);
      });

      ErrorHandler.hideLoading();
      ErrorHandler.showSuccessSnackbar('Report ${action.toLowerCase()}');
    } catch (e, st) {
      ErrorHandler.hideLoading();
      ErrorHandler.handleError(e, st, 'ReportedContentScreen.resolveReport');
      ErrorHandler.showErrorSnackbar('Failed to process report');
    }
  }

  void _showReportDetails(ReportedItem report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReportDetailsSheet(
        report: report,
        onResolve: (action) => _resolveReport(report, action),
      ),
    );
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
          'Reported Content',
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
                  const Text('Pending'),
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
                      '${_pendingReports.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingShimmerList(itemCount: 5)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReportsList(_pendingReports, theme, colorScheme),
                _buildReportsList(
                  _resolvedReports,
                  theme,
                  colorScheme,
                  isResolved: true,
                ),
              ],
            ),
    );
  }

  Widget _buildReportsList(
    List<ReportedItem> reports,
    ThemeData theme,
    ColorScheme colorScheme, {
    bool isResolved = false,
  }) {
    if (reports.isEmpty) {
      return EmptyStateIllustration(
        type: EmptyStateType.custom,
        icon: isResolved
            ? Icons.check_circle_outline_rounded
            : Icons.report_outlined,
        title: isResolved ? 'No Resolved Reports' : 'No Pending Reports',
        description: isResolved
            ? 'Resolved reports will appear here'
            : 'All clear! No pending reports to review',
        compact: true,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return _ReportCard(
          report: report,
          onTap: () => _showReportDetails(report),
          onResolve: isResolved
              ? null
              : (action) => _resolveReport(report, action),
          colorScheme: colorScheme,
        );
      },
    );
  }
}

class ReportedItem {
  final String id;
  final String type;
  final String content;
  final String reporterId;
  final String reporterName;
  final String reportedId;
  String? reportedName;
  String? reportedContent;
  final String reason;
  final DateTime timestamp;
  DateTime? resolvedAt;
  String? resolvedBy;
  String? action;
  String status;
  final String severity;

  ReportedItem({
    required this.id,
    required this.type,
    required this.content,
    required this.reporterId,
    required this.reporterName,
    required this.reportedId,
    this.reportedName,
    this.reportedContent,
    required this.reason,
    required this.timestamp,
    this.resolvedAt,
    this.resolvedBy,
    this.action,
    required this.status,
    required this.severity,
  });
}

class _ReportCard extends StatelessWidget {
  final ReportedItem report;
  final VoidCallback onTap;
  final Function(String)? onResolve;
  final ColorScheme colorScheme;

  const _ReportCard({
    required this.report,
    required this.onTap,
    this.onResolve,
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
          color: _getSeverityColor(report.severity).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                      color: _getTypeColor(report.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(report.type),
                      color: _getTypeColor(report.type),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.type.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _getTypeColor(report.type),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatTime(report.timestamp),
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
                      color: _getSeverityColor(
                        report.severity,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      report.severity.toUpperCase(),
                      style: TextStyle(
                        color: _getSeverityColor(report.severity),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(report.content, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Reported by: ${report.reporterName}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.label_rounded,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Reason: ${report.reason}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (onResolve != null)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: onResolve,
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'Removed',
                          child: Row(
                            children: [
                              Icon(Icons.delete_rounded, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Remove Content'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'Warning',
                          child: Row(
                            children: [
                              Icon(Icons.warning_rounded, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Send Warning'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'Dismissed',
                          child: Row(
                            children: [
                              Icon(Icons.check_rounded, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Dismiss Report'),
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

  Color _getSeverityColor(String severity) {
    switch (severity) {
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

class _ReportDetailsSheet extends StatelessWidget {
  final ReportedItem report;
  final Function(String) onResolve;

  const _ReportDetailsSheet({required this.report, required this.onResolve});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Report Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection('Report Information', [
                    _buildInfoRow(
                      'Reported by',
                      report.reporterName,
                      Icons.person_rounded,
                      colorScheme.primary,
                    ),
                    _buildInfoRow(
                      'Type',
                      report.type.toUpperCase(),
                      _getTypeIcon(report.type),
                      colorScheme.primary,
                    ),
                    _buildInfoRow(
                      'Reason',
                      report.reason,
                      Icons.label_rounded,
                      colorScheme.primary,
                    ),
                    _buildInfoRow(
                      'Time',
                      _formatDateTime(report.timestamp),
                      Icons.access_time_rounded,
                      colorScheme.primary,
                    ),
                    _buildInfoRow(
                      'Severity',
                      report.severity.toUpperCase(),
                      Icons.warning_rounded,
                      _getSeverityColor(report.severity),
                    ),
                  ], colorScheme),
                  const SizedBox(height: 20),
                  _buildInfoSection('Reported Content', [
                    if (report.type == 'message' &&
                        report.reportedContent != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(report.reportedContent!),
                      ),
                    if (report.type == 'user' && report.reportedName != null)
                      _buildInfoRow(
                        'User',
                        report.reportedName!,
                        Icons.person_rounded,
                        colorScheme.primary,
                      ),
                    if (report.type == 'community' &&
                        report.reportedName != null)
                      _buildInfoRow(
                        'Community',
                        report.reportedName!,
                        Icons.group_rounded,
                        colorScheme.primary,
                      ),
                  ], colorScheme),
                  const SizedBox(height: 20),
                  _buildInfoSection('Reporter Information', [
                    _buildInfoRow(
                      'ID',
                      report.reporterId,
                      Icons.badge_rounded,
                      colorScheme.primary,
                    ),
                    _buildInfoRow(
                      'Previous reports',
                      '3 reports',
                      Icons.history_rounded,
                      colorScheme.primary,
                    ),
                    _buildInfoRow(
                      'Trust score',
                      '85%',
                      Icons.verified_rounded,
                      Colors.green,
                    ),
                  ], colorScheme),
                  const SizedBox(height: 24),
                  if (report.status == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onResolve('Dismissed');
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Dismiss'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onResolve('Warning');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Warn'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (report.status == 'pending')
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onResolve('Removed');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Remove Content'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    List<Widget> children,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(flex: 2, child: Text(value)),
        ],
      ),
    );
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

  Color _getSeverityColor(String severity) {
    switch (severity) {
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
