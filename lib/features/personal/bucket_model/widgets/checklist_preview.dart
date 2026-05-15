// lib/features/bucket/message_bubbles/checklist_preview.dart

import 'package:flutter/material.dart';
import '../../../../helpers/card_color_helper.dart';
import '../models/bucket_model.dart';
import 'checklist_feedback_view_dialog.dart';
import 'checklist_feedback_add_dialog.dart';

/// Build checklist preview for bucket card with horizontal scrolling
Widget buildChecklistPreview(
  BuildContext context,
  ThemeData theme,
  BucketModel bucket,
  bool isListView,
) {
  // Get dynamic color for this bucket
  final cardColor = CardColorHelper.getBucketColor(bucket.bucketId);

  if (bucket.checklist.isEmpty) {
    return _buildEmptyState(theme, cardColor);
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildHeader(theme, bucket, cardColor),
      const SizedBox(height: 8),
      _buildScrollableChecklist(context, theme, bucket, cardColor, isListView),
    ],
  );
}

Widget _buildScrollableChecklist(
  BuildContext context,
  ThemeData theme,
  BucketModel bucket,
  Color cardColor,
  bool isListView,
) {
  final maxVisibleItems = 3;
  // Reduced height estimate for cleaner layout
  final estimatedItemHeight = 64.0;
  final spacing = 8.0;
  final maxHeight =
      (estimatedItemHeight * maxVisibleItems) + (spacing * maxVisibleItems);

  // Determine if we need scrolling (more than 3 items)
  final needsScrolling = bucket.checklist.length > maxVisibleItems;

  return ConstrainedBox(
    constraints: BoxConstraints(maxHeight: needsScrolling ? maxHeight : 1000),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ListView.builder(
        shrinkWrap: true,
        primary: false,
        physics: needsScrolling
            ? const BouncingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: bucket.checklist.length,
        itemBuilder: (context, index) {
          return _buildChecklistItem(
            context,
            theme,
            bucket,
            bucket.checklist[index],
            index,
            cardColor,
            isListView,
          );
        },
      ),
    ),
  );
}

Widget _buildEmptyState(ThemeData theme, Color cardColor) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(Icons.checklist, color: cardColor.withOpacity(0.6), size: 20),
        const SizedBox(width: 8),
        Text(
          'No tasks yet',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

Widget _buildHeader(ThemeData theme, BucketModel bucket, Color cardColor) {
  final completedCount = bucket.checklist.where((item) => item.done).length;
  final totalCount = bucket.checklist.length;

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Icon(Icons.checklist_rounded, size: 18, color: cardColor),
          const SizedBox(width: 6),
          Text(
            'Tasks',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$completedCount/$totalCount',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cardColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),

      // Show view all button if more than 3 items
      // if (bucket.checklist.length > 3)
      //   TextButton(
      //     onPressed: () {
      //       // You can add navigation to full checklist view here
      //     },
      //     style: TextButton.styleFrom(
      //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      //       minimumSize: Size.zero,
      //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      //     ),
      //     child: Text(
      //       'View All',
      //       style: theme.textTheme.bodySmall?.copyWith(
      //         color: cardColor,
      //         fontWeight: FontWeight.bold,
      //         fontSize: 11,
      //       ),
      //     ),
      //   ),
    ],
  );
}

Widget _buildChecklistItem(
  BuildContext context,
  ThemeData theme,
  BucketModel bucket,
  ChecklistItem item,
  int index,
  Color cardColor,
  bool isListView,
) {
  return GestureDetector(
    onTap: () => _handleChecklistItemTap(context, bucket, item, index),
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(
        horizontal: isListView ? 10 : 8,
        vertical: isListView ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: item.done
            ? cardColor.withOpacity(0.1)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: item.done
            ? Border.all(color: cardColor.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Checkbox (disabled - shows status only)
          IgnorePointer(
            ignoring: true,
            child: Transform.scale(
              scale: 0.85,
              child: Checkbox(
                value: item.done,
                onChanged: null,
                activeColor: cardColor,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          // Task text
          Expanded(
            child: Text(
              item.task,
              style: theme.textTheme.bodySmall?.copyWith(
                decoration: item.done ? TextDecoration.lineThrough : null,
                decorationColor: theme.colorScheme.onSurface.withOpacity(0.3),
                decorationThickness: 2,
                color: item.done
                    ? theme.colorScheme.onSurface.withOpacity(0.5)
                    : theme.colorScheme.onSurface,
                fontSize: isListView ? 13 : 12,
                fontWeight: item.done ? FontWeight.normal : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          // Status indicators
          if (item.done) ...[
            // Has feedback badge
            if (item.feedbacks.isNotEmpty)
              Tooltip(
                message: 'Has feedback',
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.verified, size: 14, color: cardColor),
                ),
              ),

            // Points badge with animation
            if (item.points > 0) ...[
              const SizedBox(width: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars_rounded, size: 10, color: cardColor),
                          const SizedBox(width: 2),
                          Text(
                            '${item.points}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cardColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ] else
            // Not done - show arrow with tap hint
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
        ],
      ),
    ),
  );
}

void _handleChecklistItemTap(
  BuildContext context,
  BucketModel bucket,
  ChecklistItem item,
  int index,
) {
  if (item.done) {
    // Show feedback view dialog
    ChecklistFeedbackViewDialog.show(context, item, bucket);
  } else {
    // Show feedback add dialog
    ChecklistFeedbackAddDialog.show(context, bucket, item, index);
  }
}
