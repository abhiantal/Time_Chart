// lib/features/bucket/message_bubbles/checklist_feedback_view_dialog.dart

import 'package:flutter/material.dart';
import 'package:the_time_chart/helpers/card_color_helper.dart';
import 'package:the_time_chart/features/personal/bucket_model/models/bucket_model.dart';
import 'package:the_time_chart/media_utility/media_display.dart';
import 'package:the_time_chart/media_utility/universal_media_service.dart';

/// Views feedback for completed checklist tasks
class ChecklistFeedbackViewDialog extends StatelessWidget {
  final ChecklistItem item;
  final BucketModel bucket;

  const ChecklistFeedbackViewDialog({
    super.key,
    required this.item,
    required this.bucket,
  });

  static Future<void> show(
    BuildContext context,
    ChecklistItem item,
    BucketModel bucket,
  ) {
    return showDialog(
      context: context,
      builder: (context) =>
          ChecklistFeedbackViewDialog(item: item, bucket: bucket),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = CardColorHelper.getProgressColor(
      bucket.metadata.averageProgress.toInt(),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: screenHeight * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme, cardColor),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: _buildContent(theme, context, cardColor, isDark),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '✓ Task Completed',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.task,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
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

  Widget _buildContent(
    ThemeData themeData,
    BuildContext context,
    Color cardColor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Stats Row
        _buildQuickStatsRow(themeData, cardColor),
        const SizedBox(height: 24),

        // Points Earned Card (Prominent)
        if (item.points > 0) ...[
          _buildPointsCard(themeData, cardColor, item.points, isDark),
          const SizedBox(height: 24),
        ],

        // Feedback Section
        if (item.feedbacks.isNotEmpty) ...[
          _buildSection(
            theme: themeData,
            cardColor: cardColor,
            isDark: isDark,
            title: 'Feedback History',
            icon: Icons.history_rounded,
            child: Column(
              children: item.feedbacks.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFeedbackCard(themeData, f, isDark),
              )).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Performance Metrics
        _buildSection(
          theme: themeData,
          cardColor: cardColor,
          isDark: isDark,
          title: 'Performance Metrics',
          icon: Icons.analytics_rounded,
          child: _buildPerformanceMetrics(themeData, cardColor, isDark),
        ),
        const SizedBox(height: 24),

        // Task Details
        _buildSection(
          theme: themeData,
          cardColor: cardColor,
          isDark: isDark,
          title: 'Task Details',
          icon: Icons.assignment_rounded,
          child: _buildTaskDetails(themeData, cardColor, isDark),
        ),
        const SizedBox(height: 24),

        // Media Gallery
        if (item.allMedia.isNotEmpty) ...[
          _buildSection(
            theme: themeData,
            cardColor: cardColor,
            isDark: isDark,
            title: 'Attachments',
            icon: Icons.collections_rounded,
            trailing: _buildMediaCount(themeData, cardColor),
            child: _buildMediaSection(context, isDark),
          ),
          const SizedBox(height: 24),
        ],

        // Completion Timestamp
        if (item.date != null)
          _buildCompletionTimestamp(themeData, cardColor, isDark),
      ],
    );
  }

  Widget _buildQuickStatsRow(ThemeData theme, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardColor.withValues(alpha: 0.08),
            cardColor.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cardColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              theme,
              cardColor,
              bucket.metadata.averageRating.toStringAsFixed(1),
              'Rating',
              Icons.star_rounded,
            ),
          ),
          _buildVerticalDivider(cardColor),
          Expanded(
            child: _buildStatItem(
              theme,
              cardColor,
              '${bucket.metadata.averageProgress.toInt()}%',
              'Progress',
              Icons.trending_up_rounded,
            ),
          ),
          _buildVerticalDivider(cardColor),
          Expanded(
            child: _buildStatItem(
              theme,
              cardColor,
              '${bucket.metadata.totalPointsEarned}',
              'Total Pts',
              Icons.diamond_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    Color color,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(Color color) {
    return Container(
      height: 50,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: color.withValues(alpha: 0.2),
    );
  }

  Widget _buildPointsCard(
    ThemeData theme,
    Color accentColor,
    int points,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.15),
            accentColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Points Earned',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+$points',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'pts',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: accentColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.emoji_events_rounded,
            color: accentColor.withValues(alpha: 0.3),
            size: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required ThemeData theme,
    required Color cardColor,
    required bool isDark,
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: cardColor),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            if (trailing != null) ...[const Spacer(), trailing],
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildMediaCount(ThemeData theme, Color cardColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${item.allMedia.length} files',
        style: theme.textTheme.labelSmall?.copyWith(
          color: cardColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(ThemeData theme, ChecklistFeedback feedback, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (feedback.isAiVerified ?? false) 
              ? Colors.green.withValues(alpha: 0.3) 
              : theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (feedback.isAiVerified != null)
                Icon(
                  feedback.isAiVerified! ? Icons.verified : Icons.info_outline,
                  size: 14,
                  color: feedback.isAiVerified! ? Colors.green : Colors.orange,
                ),
              const SizedBox(width: 4),
              Text(
                feedback.isAiVerified == true ? 'AI Verified' : 'Pending',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: feedback.isAiVerified == true ? Colors.green : Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${feedback.timestamp.day}/${feedback.timestamp.month}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            feedback.text,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(
    ThemeData theme,
    Color accentColor,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          _buildMetricTile(
            theme,
            accentColor,
            'Overall Rating',
            bucket.metadata.averageRating.toStringAsFixed(1),
            Icons.star_rounded,
            showDivider: true,
          ),
          _buildMetricTile(
            theme,
            accentColor,
            'Progress',
            '${bucket.metadata.averageProgress.toInt()}%',
            Icons.donut_large_rounded,
            showDivider: true,
          ),
          _buildMetricTile(
            theme,
            accentColor,
            'Points Earned',
            '${bucket.metadata.totalPointsEarned}',
            Icons.workspace_premium_rounded,
            showDivider: bucket.metadata.rewardPackage != null,
          ),
          if (bucket.metadata.rewardPackage != null) ...[
            _buildMetricTile(
              theme,
              accentColor,
              'Achievement Tag',
              bucket.metadata.rewardPackage!.tagName,
              Icons.local_offer_rounded,
              showDivider: true,
            ),
            _buildMetricTile(
              theme,
              accentColor,
              'Reward Earned',
              bucket.metadata.rewardPackage!.rewardDisplayName,
              Icons.diamond_outlined,
              showDivider: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    ThemeData theme,
    Color color,
    String label,
    String value,
    IconData icon, {
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 60,
            endIndent: 16,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
      ],
    );
  }

  Widget _buildTaskDetails(ThemeData theme, Color accentColor, bool isDark) {
    final statusText = item.done ? 'Completed' : 'Pending';
    final statusColor = item.done
        ? const Color(0xFF43E97B)
        : const Color(0xFFFFE082);
    final dateText = item.date != null ? _formatDate(item.date!) : '—';

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          _buildDetailTile(
            theme,
            accentColor,
            'Task Name',
            item.task,
            Icons.task_alt_rounded,
            showDivider: true,
          ),
          _buildDetailTileWithBadge(
            theme,
            statusColor,
            'Status',
            statusText,
            Icons.flag_rounded,
            showDivider: true,
          ),
          _buildDetailTile(
            theme,
            accentColor,
            'Points Value',
            '${item.points} pts',
            Icons.stars_rounded,
            showDivider: true,
          ),
          _buildDetailTile(
            theme,
            accentColor,
            'Completion Date',
            dateText,
            Icons.calendar_today_rounded,
            showDivider: true,
          ),
          _buildDetailTile(
            theme,
            accentColor,
            'Attachments',
            '${item.allMedia.length} file${item.allMedia.length != 1 ? 's' : ''}',
            Icons.attach_file_rounded,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(
    ThemeData theme,
    Color color,
    String label,
    String value,
    IconData icon, {
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 60,
            endIndent: 16,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
      ],
    );
  }

  Widget _buildDetailTileWithBadge(
    ThemeData theme,
    Color color,
    String label,
    String value,
    IconData icon, {
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        value,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 60,
            endIndent: 16,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
      ],
    );
  }

  Widget _buildMediaSection(BuildContext context, bool isDark) {
    return FutureBuilder<List<EnhancedMediaFile>>(
      future: _getSignedMediaFiles(item.allMedia),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    size: 32,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No media available',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: EnhancedMediaDisplay(
            mediaFiles: snapshot.data!,
            config: MediaDisplayConfig(
              layoutMode: MediaLayoutMode.grid,
              gridColumns: 3,
              mediaBucket: MediaBucket.bucketMedia,
              borderRadius: 12,
              spacing: 8,
              allowDelete: false,
              showFileName: false,
              showFileSize: false,
              showDate: false,
            ),
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

  Widget _buildCompletionTimestamp(
    ThemeData theme,
    Color accentColor,
    bool isDark,
  ) {
    final completedDate = item.date!;
    final formattedDate = _formatDate(completedDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.08),
            accentColor.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Completed on $formattedDate',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, BuildContext context) {
    final accentColor = CardColorHelper.getProgressColor(
      bucket.metadata.averageProgress.toInt(),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Done',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
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

/// add in this  import 'package:the_time_chart/reward_tags/reward_scratch_card.dart';
///
/// and fix my error and more batter
