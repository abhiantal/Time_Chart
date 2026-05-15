import 'package:flutter/material.dart';

class CreateChatUIHelper {
  static Widget buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary.withValues(alpha: 0.8),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          fontSize: 11,
        ),
      ),
    );
  }

  static Widget buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    Widget? trailing,
    bool enabled = true,
    bool isDanger = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final finalIconColor = isDanger ? colorScheme.error : iconColor;

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: finalIconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: finalIconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDanger ? colorScheme.error : null,
                      ),
                    ),
                    if (subtitle != null)
                       Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              trailing ?? Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }

  static Widget buildMenuDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 64,
      endIndent: 20,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }

  static Widget buildContainer({
    required BuildContext context,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}
