import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../widgets/error_handler.dart';
import '../../widgets/common/empty_state_illustration.dart';
import '../../widgets/common/loading_shimmer_list.dart';
import '../../widgets/common/user_avatar_cached.dart';

class GroupJoinRequestsScreen extends StatefulWidget {
  final String groupId;

  const GroupJoinRequestsScreen({super.key, required this.groupId});

  @override
  State<GroupJoinRequestsScreen> createState() =>
      _GroupJoinRequestsScreenState();
}

class _GroupJoinRequestsScreenState extends State<GroupJoinRequestsScreen> {
  bool _isLoading = true;
  final List<JoinRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      setState(() => _isLoading = true);

      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _requests.addAll([
          JoinRequest(
            id: '1',
            userId: 'user1',
            name: 'Sarah Chen',
            username: '@sarahc',
            requestDate: DateTime.now().subtract(const Duration(hours: 2)),
            reason: 'I\'m a Flutter developer and would love to join!',
          ),
          JoinRequest(
            id: '2',
            userId: 'user2',
            name: 'Mike Johnson',
            username: '@mikej',
            requestDate: DateTime.now().subtract(const Duration(days: 1)),
            reason: 'Interested in learning more about this community',
          ),
        ]);
        _isLoading = false;
      });
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'GroupJoinRequestsScreen.loadRequests');
      setState(() => _isLoading = false);
    }
  }

  void _approveRequest(JoinRequest request) async {
    try {
      HapticFeedback.mediumImpact();
      ErrorHandler.showLoading('Approving...');

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _requests.remove(request);
      });

      ErrorHandler.hideLoading();
      ErrorHandler.showSuccessSnackbar('${request.name} approved');
    } catch (e, st) {
      ErrorHandler.hideLoading();
      ErrorHandler.handleError(e, st, 'GroupJoinRequestsScreen.approveRequest');
      ErrorHandler.showErrorSnackbar('Failed to approve request');
    }
  }

  void _declineRequest(JoinRequest request) async {
    try {
      HapticFeedback.mediumImpact();
      ErrorHandler.showLoading('Declining...');

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _requests.remove(request);
      });

      ErrorHandler.hideLoading();
      ErrorHandler.showSuccessSnackbar('Request declined');
    } catch (e, st) {
      ErrorHandler.hideLoading();
      ErrorHandler.handleError(e, st, 'GroupJoinRequestsScreen.declineRequest');
      ErrorHandler.showErrorSnackbar('Failed to decline request');
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
          'Join Requests',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const LoadingShimmerList(itemCount: 3)
          : _requests.isEmpty
          ? EmptyStateIllustration(
              type: EmptyStateType.custom,
              icon: Icons.person_add_rounded,
              title: 'No Pending Requests',
              description: 'People who request to join will appear here',
              compact: true,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final request = _requests[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            UserAvatarCached(
                              imageUrl: null,
                              name: request.name,
                              size: 48,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    request.username,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(request.reason),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Requested ${_formatTime(request.requestDate)}',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _declineRequest(request),
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Decline'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.error,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _approveRequest(request),
                                icon: const Icon(Icons.check_rounded),
                                label: const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays} days ago';
  }
}

class JoinRequest {
  final String id;
  final String userId;
  final String name;
  final String username;
  final DateTime requestDate;
  final String reason;

  JoinRequest({
    required this.id,
    required this.userId,
    required this.name,
    required this.username,
    required this.requestDate,
    required this.reason,
  });
}
