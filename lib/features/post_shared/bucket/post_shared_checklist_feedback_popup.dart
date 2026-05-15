// ============================================================================
// FILE 3: lib/features/bucket_sharing/message_bubbles/shared_checklist_feedback_popup.dart
// POPUP DIALOG FOR VIEWING COMPLETED TASK FEEDBACK
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../helpers/card_color_helper.dart';
import '../../../../media_utility/media_display.dart';
import '../../../../media_utility/universal_media_service.dart';
import '../../personal/bucket_model/models/bucket_model.dart';

class SharedChecklistFeedbackPopup extends StatelessWidget {
  final ChecklistItem item;
  final BucketModel bucket;

  const SharedChecklistFeedbackPopup({
    super.key,
    required this.item,
    required this.bucket,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final cardColor = CardColorHelper.getBucketColor(bucket.bucketId);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: screenWidth > 600 ? 500 : screenWidth * 0.9,
          maxHeight: screenHeight * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme, cardColor),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildContent(theme, context, cardColor),
              ),
            ),
            _buildFooter(theme, context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Completed',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.task,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, BuildContext context, Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.feedbacks.isNotEmpty) ...[
          _buildSectionHeader(theme, cardColor, 'Feedback', Icons.comment),
          const SizedBox(height: 12),
          ...item.feedbacks.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildFeedbackCard(theme, f.text),
          )).toList(),
          const SizedBox(height: 20),
        ],

        if (item.points > 0) ...[
          _buildPointsCard(theme, cardColor, item.points),
          const SizedBox(height: 20),
        ],

        if (item.allMedia.isNotEmpty) ...[
          _buildSectionHeader(
            theme,
            cardColor,
            'Media Files',
            Icons.photo_library,
          ),
          const SizedBox(height: 12),
          _buildMediaSection(context),
          const SizedBox(height: 20),
        ],

        if (item.date != null) ...[_buildCompletionInfo(theme, cardColor)],
      ],
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    Color color,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackCard(ThemeData theme, String feedback) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Text(
        feedback,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
    );
  }

  Widget _buildPointsCard(ThemeData theme, Color accentColor, int points) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.stars_rounded, color: accentColor, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Points Earned',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                '+$points',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection(BuildContext context) {
    return FutureBuilder<List<EnhancedMediaFile>>(
      future: _getSignedMediaFiles(item.allMedia),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return EnhancedMediaDisplay(
          mediaFiles: snapshot.data!,
          config: MediaDisplayConfig(
            layoutMode: MediaLayoutMode.grid,
            gridColumns: 3,
            borderRadius: 12,
            spacing: 8,
            allowDelete: false,
            showFileName: false,
            showFileSize: false,
            showDate: false,
          ),
        );
      },
    );
  }

  Future<List<EnhancedMediaFile>> _getSignedMediaFiles(
    List<String> paths,
  ) async {
    final signedFiles = <EnhancedMediaFile>[];
    for (final path in paths) {
      final signedUrl = await UniversalMediaService().getValidAvatarUrl(path);
      if (signedUrl != null) {
        signedFiles.add(
          EnhancedMediaFile.fromUrl(
            id: path,
            url: signedUrl,
            fileName: path.split('/').last,
          ),
        );
      }
    }
    return signedFiles;
  }

  Widget _buildCompletionInfo(ThemeData theme, Color accentColor) {
    final completedDate = item.date!;
    final formattedDate = _formatDate(completedDate);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: accentColor),
          const SizedBox(width: 8),
          Text(
            'Completed on $formattedDate',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Close'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
