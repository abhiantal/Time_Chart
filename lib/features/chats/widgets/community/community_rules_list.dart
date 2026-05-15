// ================================================================
// COMMUNITY RULES LIST - Production Ready (FINAL FIX)
// Displays community rules with edit capabilities
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommunityRulesList extends StatelessWidget {
  final List<String> rules;
  final bool isEditable;
  final Function(int index)? onRuleTap;
  final Function(int index)? onRuleDelete;
  final Function()? onAddRule;
  final bool showEmptyState;
  final Function(int oldIndex, int newIndex)? onRuleReorder;

  const CommunityRulesList({
    super.key,
    required this.rules,
    this.isEditable = false,
    this.onRuleTap,
    this.onRuleDelete,
    this.onAddRule,
    this.showEmptyState = true,
    this.onRuleReorder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (rules.isEmpty && showEmptyState) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.gavel_rounded,
                  size: 32,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No rules yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Community guidelines will appear here',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (isEditable && onAddRule != null) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onAddRule!();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add First Rule'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return _buildRulesList(theme, colorScheme);
  }

  Widget _buildRulesList(ThemeData theme, ColorScheme colorScheme) {
    // If not editable, use regular ListView
    if (!isEditable || onRuleReorder == null) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rules.length,
        itemBuilder: (context, index) {
          return _buildRuleTile(index, theme, colorScheme);
        },
      );
    }

    // If editable with reorder, use ReorderableListView
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rules.length,
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        onRuleReorder!(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        return _buildRuleTile(index, theme, colorScheme);
      },
    );
  }

  Widget _buildRuleTile(int index, ThemeData theme, ColorScheme colorScheme) {
    final rule = rules[index];

    return Container(
      key: ValueKey('rule_$index'),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
        title: Text(
          rule,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        trailing: isEditable
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onRuleTap?.call(index);
                    },
                    icon: Icon(
                      Icons.edit_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onRuleDelete?.call(index);
                    },
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: colorScheme.error,
                    ),
                  ),
                  if (rules.length > 1 && onRuleReorder != null)
                    Icon(
                      Icons.drag_handle_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              )
            : null,
        onTap: isEditable ? () => onRuleTap?.call(index) : null,
      ),
    );
  }
}
