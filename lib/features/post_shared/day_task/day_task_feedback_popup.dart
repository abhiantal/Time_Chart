import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../../../helpers/card_color_helper.dart';
import '../../../../media_utility/media_display.dart';
import '../../personal/task_model/day_tasks/models/day_task_model.dart';

/// Premium Swipeable Feedback Viewer for Daily Tasks
class DayTaskFeedbackPopup extends StatefulWidget {
  final DayTaskModel task;

  const DayTaskFeedbackPopup({super.key, required this.task});

  @override
  State<DayTaskFeedbackPopup> createState() => _DayTaskFeedbackPopupState();
}

class _DayTaskFeedbackPopupState extends State<DayTaskFeedbackPopup>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _closePopup() {
    HapticFeedback.lightImpact();
    _slideController.reverse().then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final comments = widget.task.feedback.comments;

    return GestureDetector(
      onTap: () {}, // Prevent dismiss on backdrop tap
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: GestureDetector(
          onTap: () {}, // Prevent event propagation
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: screenHeight * 0.88,
                  width: screenWidth,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Column(
                        children: [
                          _buildDragHandle(theme),
                          _buildHeader(theme, isDark),
                          if (comments.length > 1)
                            _buildPageIndicator(theme, isDark, comments.length),
                          Expanded(
                            child: comments.isEmpty
                                ? _buildNoFeedback(theme, isDark)
                                : PageView.builder(
                                    controller: _pageController,
                                    onPageChanged: (page) {
                                      setState(() => _currentPage = page);
                                      HapticFeedback.selectionClick();
                                    },
                                    itemCount: comments.length,
                                    itemBuilder: (context, index) {
                                      return _buildFeedbackPage(
                                        context,
                                        comments[index],
                                        index,
                                        theme,
                                        isDark,
                                      );
                                    },
                                  ),
                          ),
                          _buildBottomActions(theme, isDark, comments.length),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 48,
      height: 5,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final dateStr = DateFormat(
      'EEEE, MMMM d, yyyy',
    ).format(widget.task.timeline.startingTime);
    final isToday = _isToday(widget.task.timeline.startingTime);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF6C5CE7).withOpacity(0.3),
                  const Color(0xFF00B894).withOpacity(0.2),
                ]
              : [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Close button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _closePopup,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white : Colors.black87,
                      size: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Date and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            dateStr,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.secondary,
                                  theme.colorScheme.primary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'TODAY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          size: 14,
                          color: isDark
                              ? Colors.white70
                              : theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.task.aboutTask.taskName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? Colors.white70
                                  : theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(ThemeData theme, bool isDark, int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : theme.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Feedback ${_currentPage + 1}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '/ $totalPages',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? Colors.white54
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ...List.generate(totalPages, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      )
                    : null,
                color: isActive
                    ? null
                    : isDark
                    ? Colors.white24
                    : theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNoFeedback(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : theme.colorScheme.surfaceContainerHighest.withOpacity(
                        0.5,
                      ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Feedback Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No feedback has been added for this task',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackPage(
    BuildContext context,
    Comment comment,
    int index,
    ThemeData theme,
    bool isDark,
  ) {
    final hasMedia = comment.hasMedia;
    final hasText = comment.hasText;
    final mediaFiles = hasMedia ? _parseMediaUrls(comment.mediaUrl!) : [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feedback Number Card
          _buildFeedbackNumberCard(theme, isDark, comment, index),
          const SizedBox(height: 20),

          // Status Card
          _buildStatusCard(theme, isDark),
          const SizedBox(height: 20),

          // Feedback Content
          if (hasText) ...[
            _buildSectionHeader(
              theme,
              isDark,
              Icons.comment_rounded,
              'Feedback Details',
            ),
            const SizedBox(height: 12),
            _buildFeedbackContent(theme, isDark, comment),
            const SizedBox(height: 20),
          ],

          // Media Gallery
          if (hasMedia && mediaFiles.isNotEmpty) ...[
            _buildSectionHeader(
              theme,
              isDark,
              Icons.photo_library_rounded,
              'Attachments (${mediaFiles.length})',
            ),
            const SizedBox(height: 12),
            //  _buildMediaGallery(theme, isDark, mediaFiles),
            const SizedBox(height: 20),
          ],

          // Task Details
          _buildSectionHeader(
            theme,
            isDark,
            Icons.info_outline_rounded,
            'Task Details',
          ),
          const SizedBox(height: 12),
          _buildTaskDetails(theme, isDark),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeedbackNumberCard(
    ThemeData theme,
    bool isDark,
    Comment comment,
    int index,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [theme.colorScheme.primary.withOpacity(0.2), Colors.transparent]
              : [
                  theme.colorScheme.primary.withOpacity(0.1),
                  Colors.transparent,
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#${comment.feedbackNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('MMM d').format(comment.timestamp),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feedback Entry',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, h:mm a').format(comment.timestamp),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildFeedbackBadge(
                      icon: Icons.check_circle_rounded,
                      label: 'Verified',
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    if (comment.hasMedia)
                      _buildFeedbackBadge(
                        icon: Icons.image_rounded,
                        label: 'Media',
                        color: Colors.blue,
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

  Widget _buildFeedbackBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, bool isDark) {
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();
    final statusLabel = _getStatusLabel();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.task.metadata.isComplete
                      ? 'Task completed successfully'
                      : 'Task is ${widget.task.indicators.status}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackContent(ThemeData theme, bool isDark, Comment comment) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Text(
        comment.text,
        style: theme.textTheme.bodyLarge?.copyWith(
          height: 1.6,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMediaGallery(
    ThemeData theme,
    bool isDark,
    List<EnhancedMediaFile> mediaFiles,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: EnhancedMediaDisplay(
        mediaFiles: mediaFiles,
        config: MediaDisplayConfig(
          layoutMode: mediaFiles.length == 1
              ? MediaLayoutMode.single
              : MediaLayoutMode.grid,
          gridColumns: mediaFiles.length == 1
              ? 1
              : (mediaFiles.length == 2 ? 2 : 3),
          allowDelete: false,
          allowFullScreen: true,
          showFileName: false,
          showFileSize: false,
          showDate: false,
          spacing: 8,
          borderRadius: 12,
          imageFit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTaskDetails(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            icon: Icons.access_time_rounded,
            label: 'Time Slot',
            value:
                '${DateFormat('h:mm a').format(widget.task.timeline.startingTime)} - '
                '${DateFormat('h:mm a').format(widget.task.timeline.endingTime)}',
            theme: theme,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.category_rounded,
            label: 'Category',
            value: widget.task.categoryType,
            theme: theme,
          ),
          if (widget.task.timeline.completionTime != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.check_circle_rounded,
              label: 'Completed At',
              value: DateFormat(
                'h:mm a',
              ).format(widget.task.timeline.completionTime!),
              theme: theme,
            ),
          ],
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.stars_rounded,
            label: 'Points Earned',
            value: '${widget.task.metadata.pointsEarned}',
            theme: theme,
          ),
          if (widget.task.metadata.rating > 0) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.star_rounded,
              label: 'Rating',
              value: '${widget.task.metadata.rating}/5.0',
              theme: theme,
            ),
          ],
          if (widget.task.metadata.hasReward) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.workspace_premium_rounded,
              label: 'Reward',
              value: widget.task.metadata.rewardDisplayName,
              theme: theme,
              valueColor: widget.task.metadata.tierColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 16,
            color: valueColor ?? theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    bool isDark,
    IconData icon,
    String title,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(ThemeData theme, bool isDark, int totalPages) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
      ),
      child: totalPages > 1
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _currentPage > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                    label: const Text('Previous'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentPage < totalPages - 1
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _closePopup,
                icon: const Icon(Icons.done_rounded),
                label: const Text('Close'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  List<EnhancedMediaFile> _parseMediaUrls(String mediaUrl) {
    if (mediaUrl.isEmpty) return [];
    try {
      final urls = mediaUrl
          .split(',')
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toList();
      return urls.asMap().entries.map((entry) {
        return EnhancedMediaFile.fromUrl(
          id: 'feedback_media_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
          url: entry.value,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Color _getStatusColor() {
    return CardColorHelper.getStatusColor(widget.task.indicators.status);
  }

  IconData _getStatusIcon() {
    return switch (widget.task.indicators.status.toLowerCase()) {
      'completed' => Icons.check_circle_rounded,
      'inprogress' || 'in_progress' => Icons.pending_rounded,
      'pending' => Icons.schedule_rounded,
      'missed' || 'failed' => Icons.cancel_rounded,
      'cancelled' => Icons.block_rounded,
      'skipped' => Icons.skip_next_rounded,
      'upcoming' => Icons.upcoming_rounded,
      _ => Icons.help_outline_rounded,
    };
  }

  String _getStatusLabel() {
    return switch (widget.task.indicators.status.toLowerCase()) {
      'completed' => 'Completed',
      'inprogress' || 'in_progress' => 'In Progress',
      'pending' => 'Pending',
      'missed' => 'Missed',
      'failed' => 'Failed',
      'cancelled' => 'Cancelled',
      'skipped' => 'Skipped',
      'upcoming' => 'Upcoming',
      _ => 'Unknown',
    };
  }
}
