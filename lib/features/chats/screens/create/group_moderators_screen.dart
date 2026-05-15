import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../widgets/error_handler.dart';
import '../../widgets/common/loading_shimmer_list.dart';
import '../../widgets/common/user_avatar_cached.dart';

class GroupModeratorsScreen extends StatefulWidget {
  final String groupId;

  const GroupModeratorsScreen({super.key, required this.groupId});

  @override
  State<GroupModeratorsScreen> createState() => _GroupModeratorsScreenState();
}

class _GroupModeratorsScreenState extends State<GroupModeratorsScreen> {
  bool _isLoading = true;
  final List<ModeratorItem> _moderators = [];
  final List<MemberItem> _members = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _moderators.addAll([
          ModeratorItem(
            id: '1',
            name: 'Sarah Chen',
            role: 'Admin',
            addedDate: DateTime.now().subtract(const Duration(days: 30)),
          ),
          ModeratorItem(
            id: '2',
            name: 'Mike Johnson',
            role: 'Moderator',
            addedDate: DateTime.now().subtract(const Duration(days: 15)),
          ),
        ]);

        _members.addAll([
          MemberItem(id: '3', name: 'Alex Rivera'),
          MemberItem(id: '4', name: 'Emma Wilson'),
          MemberItem(id: '5', name: 'James Lee'),
        ]);

        _isLoading = false;
      });
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'GroupModeratorsScreen.loadData');
      setState(() => _isLoading = false);
    }
  }

  void _addModerator(MemberItem member) async {
    try {
      HapticFeedback.mediumImpact();

      setState(() {
        _moderators.add(
          ModeratorItem(
            id: member.id,
            name: member.name,
            role: 'Moderator',
            addedDate: DateTime.now(),
          ),
        );
        _members.remove(member);
      });

      ErrorHandler.showSuccessSnackbar('${member.name} added as moderator');
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'GroupModeratorsScreen.addModerator');
      ErrorHandler.showErrorSnackbar('Failed to add moderator');
    }
  }

  void _removeModerator(ModeratorItem moderator) async {
    try {
      final confirmed = await ErrorHandler.showConfirmationDialog(
        context,
        title: 'Remove Moderator',
        message:
            'Are you sure you want to remove ${moderator.name} as moderator?',
        confirmText: 'Remove',
        isDangerous: true,
      );

      if (confirmed) {
        HapticFeedback.mediumImpact();

        setState(() {
          _moderators.remove(moderator);
          _members.add(MemberItem(id: moderator.id, name: moderator.name));
        });

        ErrorHandler.showSuccessSnackbar(
          '${moderator.name} removed as moderator',
        );
      }
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'GroupModeratorsScreen.removeModerator');
      ErrorHandler.showErrorSnackbar('Failed to remove moderator');
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
          'Moderators',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const LoadingShimmerList(itemCount: 5)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Current Moderators',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ..._moderators.map(
                  (mod) => _buildModeratorTile(mod, colorScheme),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Members',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ..._members.map(
                  (member) => _buildMemberTile(member, colorScheme),
                ),
                if (_members.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No members available',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildModeratorTile(ModeratorItem mod, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: UserAvatarCached(imageUrl: null, name: mod.name, size: 40),
        title: Text(mod.name),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: mod.role == 'Admin'
                    ? Colors.amber.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                mod.role,
                style: TextStyle(
                  color: mod.role == 'Admin' ? Colors.amber : Colors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Added ${_formatDate(mod.addedDate)}',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.remove_circle_outline_rounded,
            color: colorScheme.error,
          ),
          onPressed: () => _removeModerator(mod),
        ),
      ),
    );
  }

  Widget _buildMemberTile(MemberItem member, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: UserAvatarCached(imageUrl: null, name: member.name, size: 40),
        title: Text(member.name),
        trailing: FilledButton.tonal(
          onPressed: () => _addModerator(member),
          child: const Text('Add'),
        ),
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

class ModeratorItem {
  final String id;
  final String name;
  final String role;
  final DateTime addedDate;

  ModeratorItem({
    required this.id,
    required this.name,
    required this.role,
    required this.addedDate,
  });
}

class MemberItem {
  final String id;
  final String name;

  MemberItem({required this.id, required this.name});
}
