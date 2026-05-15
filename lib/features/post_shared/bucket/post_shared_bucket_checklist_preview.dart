// ============================================================================
// FILE 2: lib/features/bucket_sharing/message_bubbles/shared_bucket_checklist_preview.dart
// SCROLLABLE CHECKLIST PREVIEW (MAX 3 VISIBLE, REST SCROLLABLE)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:the_time_chart/features/post_shared/bucket/post_shared_checklist_feedback_popup.dart';
import '../../../../helpers/card_color_helper.dart';
import '../../personal/bucket_model/models/bucket_model.dart';

class SharedBucketChecklistPreview extends StatefulWidget {
  final BucketModel bucket;
  final bool isListView;
  final bool allowInteraction;

  const SharedBucketChecklistPreview({
    super.key,
    required this.bucket,
    required this.isListView,
    this.allowInteraction = false,
  });

  @override
  State<SharedBucketChecklistPreview> createState() =>
      _SharedBucketChecklistPreviewState();
}

class _SharedBucketChecklistPreviewState
    extends State<SharedBucketChecklistPreview> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = CardColorHelper.getBucketColor(widget.bucket.bucketId);

    if (widget.bucket.checklist.isEmpty) {
      return _buildEmptyState(theme, cardColor);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(theme, widget.bucket, cardColor),
        const SizedBox(height: 8),
        _buildChecklist(
          context,
          theme,
          widget.bucket,
          cardColor,
          widget.isListView,
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, Color cardColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            color: cardColor.withOpacity(0.5),
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            'No tasks added yet',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklist(
    BuildContext context,
    ThemeData theme,
    BucketModel bucket,
    Color cardColor,
    bool isListView,
  ) {
    final maxVisibleItems = 3;
    final totalItems = bucket.checklist.length;
    final showExpandButton = totalItems > maxVisibleItems;
    final itemsToShow = _isExpanded
        ? totalItems
        : (showExpandButton ? maxVisibleItems : totalItems);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...bucket.checklist.take(itemsToShow).map((item) {
          final index = bucket.checklist.indexOf(item);
          return _buildChecklistItem(
            context,
            theme,
            bucket,
            item,
            index,
            cardColor,
            isListView,
          );
        }),
        if (showExpandButton)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              width: double.infinity,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded
                        ? 'Show Less'
                        : 'Show ${totalItems - maxVisibleItems} More',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cardColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: cardColor,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
      ],
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
      onTap: widget.allowInteraction && item.done
          ? () => _handleChecklistItemTap(context, bucket, item, index)
          : null,
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
            if (item.done) ...[
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
                            Icon(
                              Icons.stars_rounded,
                              size: 10,
                              color: cardColor,
                            ),
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
            ] else if (widget.allowInteraction)
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
    if (item.done && widget.allowInteraction) {
      showDialog(
        context: context,
        builder: (context) =>
            SharedChecklistFeedbackPopup(item: item, bucket: bucket),
      );
    }
  }
}
