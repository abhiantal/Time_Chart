import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../widgets/error_handler.dart';
import '../../widgets/common/empty_state_illustration.dart';
import '../../widgets/common/loading_shimmer_list.dart';
import '../../widgets/common/user_avatar_cached.dart';

class GroupBannedUsersScreen extends StatefulWidget {
  final String groupId;

  const GroupBannedUsersScreen({super.key, required this.groupId});

  @override
  State<GroupBannedUsersScreen> createState() => _GroupBannedUsersScreenState();
}

class _GroupBannedUsersScreenState extends State<GroupBannedUsersScreen> {
  bool _isLoading = true;
  final List<BannedUser> _bannedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadBannedUsers();
  }

  Future<void> _loadBannedUsers() async {
    try {
      setState(() => _isLoading = true);

      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _bannedUsers.addAll([
          BannedUser(
            id: '1',
            name: 'John Doe',
            username: '@johndoe',
            bannedBy: 'Sarah Chen',
            bannedAt: DateTime.now().subtract(const Duration(days: 5)),
            reason: 'Harassment',
          ),
          BannedUser(
            id: '2',
            name: 'Jane Smith',
            username: '@janesmith',
            bannedBy: 'Mike Johnson',
            bannedAt: DateTime.now().subtract(const Duration(days: 10)),
            reason: 'Spam',
          ),
        ]);
        _isLoading = false;
      });
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'GroupBannedUsersScreen.loadBannedUsers');
      setState(() => _isLoading = false);
    }
  }

  void _unbanUser(BannedUser user) async {
    try {
      final confirmed = await ErrorHandler.showConfirmationDialog(
        context,
        title: 'Unban User',
        message: 'Are you sure you want to unban ${user.name}?',
        confirmText: 'Unban',
        isDangerous: false,
      );

      if (confirmed) {
        HapticFeedback.mediumImpact();
        ErrorHandler.showLoading('Unbanning...');

        await Future.delayed(const Duration(milliseconds: 500));

        setState(() {
          _bannedUsers.remove(user);
        });

        ErrorHandler.hideLoading();
        ErrorHandler.showSuccessSnackbar('${user.name} unbanned');
      }
    } catch (e, st) {
      ErrorHandler.hideLoading();
      ErrorHandler.handleError(e, st, 'GroupBannedUsersScreen.unbanUser');
      ErrorHandler.showErrorSnackbar('Failed to unban user');
    }
  }

  void _viewBanDetails(BannedUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _BanDetailsSheet(user: user, onUnban: () => _unbanUser(user)),
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
          'Banned Users',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const LoadingShimmerList(itemCount: 3)
          : _bannedUsers.isEmpty
          ? EmptyStateIllustration(
              type: EmptyStateType.custom,
              icon: Icons.block_rounded,
              title: 'No Banned Users',
              description: 'Users you ban will appear here',
              compact: true,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bannedUsers.length,
              itemBuilder: (context, index) {
                final user = _bannedUsers[index];
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
                  child: InkWell(
                    onTap: () => _viewBanDetails(user),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              UserAvatarCached(
                                imageUrl: null,
                                name: user.name,
                                size: 48,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: colorScheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.block_rounded,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.username,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Banned by ${user.bannedBy} • ${_formatDate(user.bannedAt)}',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: () => _unbanUser(user),
                            child: const Text('Unban'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays} days ago';
  }
}

class BannedUser {
  final String id;
  final String name;
  final String username;
  final String bannedBy;
  final DateTime bannedAt;
  final String reason;

  BannedUser({
    required this.id,
    required this.name,
    required this.username,
    required this.bannedBy,
    required this.bannedAt,
    required this.reason,
  });
}

class _BanDetailsSheet extends StatelessWidget {
  final BannedUser user;
  final VoidCallback onUnban;

  const _BanDetailsSheet({required this.user, required this.onUnban});

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
            child: Column(
              children: [
                Stack(
                  children: [
                    UserAvatarCached(imageUrl: null, name: user.name, size: 80),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.block_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  user.username,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                _buildInfoRow(
                  'Banned by',
                  user.bannedBy,
                  Icons.person_rounded,
                  colorScheme,
                ),
                _buildInfoRow(
                  'Date',
                  _formatDateTime(user.bannedAt),
                  Icons.calendar_today_rounded,
                  colorScheme,
                ),
                _buildInfoRow(
                  'Reason',
                  user.reason,
                  Icons.warning_rounded,
                  colorScheme,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onUnban();
                        },
                        child: const Text('Unban'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(flex: 2, child: Text(value)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
