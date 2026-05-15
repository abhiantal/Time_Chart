import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../widgets/error_handler.dart';

class GroupPermissionsScreen extends StatefulWidget {
  const GroupPermissionsScreen({super.key});

  @override
  State<GroupPermissionsScreen> createState() => _GroupPermissionsScreenState();
}

class _GroupPermissionsScreenState extends State<GroupPermissionsScreen> {
  String _whoCanSend = 'all';
  String _whoCanAddMembers = 'admins';
  String _whoCanEditInfo = 'admins';
  String _whoCanPin = 'admins';
  bool _allowReactions = true;
  bool _allowReplies = true;
  bool _allowForwarding = true;

  final List<Map<String, String>> _permissionOptions = [
    {'value': 'all', 'label': 'All members'},
    {'value': 'admins', 'label': 'Admins only'},
    {'value': 'owner', 'label': 'Owner only'},
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
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          'Permissions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(onPressed: _savePermissions, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader(
            'Message Permissions',
            Icons.message_rounded,
            colorScheme,
          ),
          const SizedBox(height: 8),
          _buildPermissionCard(
            'Who can send messages',
            _whoCanSend,
            (value) => setState(() => _whoCanSend = value),
            Icons.send_rounded,
            colorScheme,
          ),
          const SizedBox(height: 16),
          _buildPermissionCard(
            'Who can add members',
            _whoCanAddMembers,
            (value) => setState(() => _whoCanAddMembers = value),
            Icons.person_add_rounded,
            colorScheme,
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(
            'Admin Permissions',
            Icons.admin_panel_settings_rounded,
            colorScheme,
          ),
          const SizedBox(height: 8),
          _buildPermissionCard(
            'Who can edit group info',
            _whoCanEditInfo,
            (value) => setState(() => _whoCanEditInfo = value),
            Icons.edit_rounded,
            colorScheme,
          ),
          const SizedBox(height: 16),
          _buildPermissionCard(
            'Who can pin messages',
            _whoCanPin,
            (value) => setState(() => _whoCanPin = value),
            Icons.push_pin_rounded,
            colorScheme,
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(
            'Message Features',
            Icons.featured_play_list_rounded,
            colorScheme,
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Allow reactions'),
                    subtitle: const Text('Members can react to messages'),
                    value: _allowReactions,
                    onChanged: (value) =>
                        setState(() => _allowReactions = value),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.emoji_emotions_rounded,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    title: const Text('Allow replies'),
                    subtitle: const Text('Members can reply to messages'),
                    value: _allowReplies,
                    onChanged: (value) => setState(() => _allowReplies = value),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.reply_rounded,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    title: const Text('Allow forwarding'),
                    subtitle: const Text('Members can forward messages'),
                    value: _allowForwarding,
                    onChanged: (value) =>
                        setState(() => _allowForwarding = value),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.forward_rounded,
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildPermissionCard(
    String title,
    String value,
    Function(String) onChanged,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
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
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._permissionOptions.map(
              (option) => RadioListTile<String>(
                title: Text(option['label']!),
                value: option['value']!,
                groupValue: value,
                onChanged: (val) => onChanged(val!),
                activeColor: colorScheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _savePermissions() {
    HapticFeedback.mediumImpact();
    ErrorHandler.showSuccessSnackbar('Permissions updated');
    Navigator.pop(context);
  }
}
