// lib/features/week_task/screens_widgets/add_feedback_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:video_compress/video_compress.dart';
import '../../../../../../widgets/custom_text_field.dart';
import '../../../../../../widgets/logger.dart';
import '../../../../../media_utility/media_picker.dart';
import '../../../../../media_utility/media_display.dart';
import '../../../../../media_utility/universal_media_service.dart';
import '../../../../../../widgets/app_snackbar.dart';
import '../models/week_task_model.dart';
import '../repositories/week_task_repository.dart';

class AddWeeklyFeedbackScreen extends StatefulWidget {
  final WeekTaskModel task;
  final DateTime? selectedDate;

  const AddWeeklyFeedbackScreen({
    super.key,
    required this.task,
    this.selectedDate,
  });

  @override
  State<AddWeeklyFeedbackScreen> createState() =>
      _AddWeeklyFeedbackScreenState();
}

class _AddWeeklyFeedbackScreenState extends State<AddWeeklyFeedbackScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final List<EnhancedMediaFile> _uploadedMediaFiles = [];
  final _repository = WeekTaskRepository();

  bool _isSubmitting = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Cooldown tracking removed
  bool _canAddFeedback = true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkCooldown();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  Future<void> _checkCooldown() async {
    // Cooldown logic removed per requirements
    setState(() {
      _canAddFeedback = true;
    });
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  DateTime get _selectedDate => widget.selectedDate ?? DateTime.now();

  String get _dayName => DateFormat('EEEE').format(_selectedDate);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final allowed = _isSubmissionAllowed();

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0D1117) : colorScheme.surface,
        appBar: _buildAppBar(theme, colorScheme, allowed),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Date & Status Banner
                _buildDateStatusBanner(theme, colorScheme, isDark),
                const SizedBox(height: 20),

                // Task Info Card
                _buildTaskInfoCard(theme, colorScheme, isDark),
                const SizedBox(height: 24),

                // Cooldown Banner (if active)
                if (!_canAddFeedback) ...[
                  _buildCooldownBanner(theme, colorScheme),
                  const SizedBox(height: 20),
                ],

                // Today's Progress Summary
                _buildTodayProgressSummary(theme, colorScheme, isDark),
                const SizedBox(height: 24),

                // Media Section
                _buildMediaUpload(context),
                const SizedBox(height: 24),

                // Custom Feedback TextField
                _buildFeedbackTextField(theme, colorScheme),
                const SizedBox(height: 24),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilledButton.icon(
                      onPressed:
                          _isSubmitting ||
                              _isUploading ||
                              !allowed ||
                              !_canAddFeedback
                          ? null
                          : _submitFeedback,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(_isSubmitting ? 'Saving...' : 'Submit'),
                      style: FilledButton.styleFrom(
                        backgroundColor: allowed && _canAddFeedback
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        foregroundColor: allowed && _canAddFeedback
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    ThemeData theme,
    ColorScheme colorScheme,
    bool allowed,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Feedback'),
          Text(
            _dayName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateStatusBanner(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final isScheduled = widget.task.timeline.scheduledDays.any(
      (d) => d.toLowerCase() == _dayName.toLowerCase(),
    );
    final existingProgress = widget.task.getProgressForDate(_selectedDate);
    final feedbackCount = existingProgress?.feedbacks.length ?? 0;

    Color bannerColor;
    IconData bannerIcon;
    String bannerText;

    if (widget.task.indicators.status == 'completed') {
      bannerColor = colorScheme.tertiary;
      bannerIcon = Icons.check_circle_rounded;
      bannerText = 'Task completed. Feedback is disabled.';
    } else if (!isScheduled) {
      bannerColor = colorScheme.error;
      bannerIcon = Icons.event_busy_rounded;
      bannerText = 'This day is not scheduled for this task.';
    } else if (feedbackCount > 0) {
      bannerColor = colorScheme.primary;
      bannerIcon = Icons.history_rounded;
      bannerText =
          '$feedbackCount feedback${feedbackCount > 1 ? 's' : ''} added today. Add more!';
    } else {
      bannerColor = const Color(0xFF10B981);
      bannerIcon = Icons.add_task_rounded;
      bannerText = 'Ready to add your first feedback for today!';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            bannerColor.withValues(alpha: isDark ? 0.2 : 0.15),
            bannerColor.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(bannerIcon, color: bannerColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: bannerColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bannerText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCooldownBanner(ThemeData theme, ColorScheme colorScheme) {
    return const SizedBox.shrink();
  }

  Widget _buildTaskInfoCard(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  colorScheme.primaryContainer.withValues(alpha: 0.3),
                  colorScheme.secondaryContainer.withValues(alpha: 0.2),
                ]
              : [colorScheme.primaryContainer, colorScheme.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.calendar_view_week_rounded,
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
                  widget.task.aboutTask.taskName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMiniStat(
                      icon: Icons.trending_up_rounded,
                      value: '${widget.task.summary.progress}%',
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    _buildMiniStat(
                      icon: Icons.star_rounded,
                      value: widget.task.summary.rating.toStringAsFixed(1),
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 12),
                    _buildMiniStat(
                      icon: Icons.check_circle_rounded,
                      value: '${widget.task.totalCompletedDays}',
                      color: const Color(0xFF10B981),
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

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayProgressSummary(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final todayProgress = widget.task.getProgressForDate(_selectedDate);
    final feedbackCount = todayProgress?.feedbacks.length ?? 0;
    final dayPoints = todayProgress?.dailyMetrics.pointsEarned ?? 0;
    final dayProgress = todayProgress?.dailyMetrics.progress ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today_rounded, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Today\'s Progress',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProgressStat(
                  theme: theme,
                  label: 'Feedbacks',
                  value: '$feedbackCount',
                  icon: Icons.feedback_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressStat(
                  theme: theme,
                  label: 'Points',
                  value: '+$dayPoints',
                  icon: Icons.stars_rounded,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressStat(
                  theme: theme,
                  label: 'Progress',
                  value: '$dayProgress%',
                  icon: Icons.show_chart_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat({
    required ThemeData theme,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
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
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaUpload(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Media (Optional)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  '+5 points per media',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (_uploadedMediaFiles.isNotEmpty)
              Text(
                '${_uploadedMediaFiles.length}/10 files',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        EnhancedMediaDisplay(
          mediaFiles: _uploadedMediaFiles,
          isLoading: _isUploading,
          config: MediaDisplayConfig(
            layoutMode: MediaLayoutMode.grid,
            gridColumns: 3,
            mediaBucket: MediaBucket.weeklyTaskMedia,
            borderRadius: 12,
            spacing: 8,
            allowDelete: !_isSubmitting && !_isUploading,
            allowFullScreen: true,
            showFileName: false,
            showFileSize: true,
            showDate: false,
            imageFit: BoxFit.cover,
          ),
          onDelete: (mediaId) {
            setState(() {
              _uploadedMediaFiles.removeWhere((file) => file.id == mediaId);
            });
            snackbarService.showInfo(
              'Media Removed',
              description: _uploadedMediaFiles.isEmpty
                  ? 'All media removed'
                  : '${_uploadedMediaFiles.length} file(s) remaining',
            );
          },
          onAddMedia:
              _uploadedMediaFiles.length < 10 && !_isSubmitting && !_isUploading
              ? _pickMedia
              : null,
          emptyMessage: 'No media attached',
        ),

        if (_uploadedMediaFiles.isNotEmpty &&
            _uploadedMediaFiles.length < 10 &&
            !_isSubmitting &&
            !_isUploading) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickMedia,
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: Text('Add More Media (${_uploadedMediaFiles.length}/10)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],

        if (_isUploading) ...[
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: _uploadProgress,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Uploading... ${(_uploadProgress * 100).toInt()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFeedbackTextField(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_note_rounded, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Your Feedback',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '+10 points',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF10B981),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CustomTextField.multiline(
          controller: _feedbackController,
          label: 'Feedback',
          hint: 'Share your thoughts, progress, or challenges...',
          maxLines: 6,
          maxLength: 1000,
          required: _uploadedMediaFiles.isEmpty,
          validator: (value) {
            if (_uploadedMediaFiles.isEmpty &&
                (value == null || value.trim().isEmpty)) {
              return 'Please enter feedback or add media';
            }
            return null;
          },
        ),
      ],
    );
  }

  bool _isSubmissionAllowed() {
    final dayName = _dayName.toLowerCase();
    final isScheduled = widget.task.timeline.scheduledDays.any(
      (d) => d.toLowerCase() == dayName,
    );
    final isCompleted = widget.task.indicators.status == 'completed';

    return isScheduled && !isCompleted && _canAddFeedback;
  }

  Future<void> _pickMedia() async {
    if (_uploadedMediaFiles.length >= 10) {
      snackbarService.showWarning(
        'Maximum Limit Reached',
        description: 'You can only upload up to 10 media files',
      );
      return;
    }

    try {
      HapticFeedback.lightImpact();

      final file = await EnhancedMediaPicker.pickMedia(
        context,
        config: const MediaPickerConfig(
          allowCamera: true,
          allowGallery: false,
          allowImage: true,
          allowVideo: true,
          allowAudio: true,
          allowDocument: false,
          autoCompress: true,
          imageQuality: 70,
          videoQuality: VideoQuality.LowQuality,
          maxFileSizeMB: 50,
        ),
      );

      if (file != null) {
        setState(() {
          _isUploading = true;
          _uploadProgress = 0.1;
        });

        final f = File(file.path);

        // Upload using UniversalMediaService
        final urls = await mediaService.uploadTaskMedia(
          files: [f],
          taskType: 'weekly',
          taskId: widget.task.id,
        );
        final url = urls.isNotEmpty ? urls.first : null;

        if (url != null && mounted) {
          setState(() {
            _uploadedMediaFiles.add(
              EnhancedMediaFile.fromUrl(id: 'media_${url.hashCode}', url: url),
            );
            _uploadProgress = 1.0;
            _isUploading = false;
          });
          HapticFeedback.mediumImpact();
          snackbarService.showSuccess('Media uploaded! +5 points');
        } else {
          setState(() {
            _uploadProgress = 0.0;
            _isUploading = false;
          });
          snackbarService.showError('Upload failed');
        }
      }
    } catch (e) {
      logE('Error picking media', error: e);
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
        snackbarService.showError('Failed to pick media');
      }
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isSubmissionAllowed()) {
      snackbarService.showError('Feedback not allowed');
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      // Submit each media URL as separate feedback if multiple
      // Or submit text with first media URL
      if (_uploadedMediaFiles.isNotEmpty) {
        // Add media feedback (uses repository directly for proper structure)
        for (final media in _uploadedMediaFiles) {
          await _repository.addMediaFeedback(
            taskId: widget.task.id,
            date: _selectedDate,
            mediaUrl: media.url,
          );
        }
      }

      // Add final text if provided
      final feedbackText = _feedbackController.text.trim();
      if (feedbackText.isNotEmpty) {
        await _repository.addFinalText(
          taskId: widget.task.id,
          date: _selectedDate,
          text: feedbackText,
        );
      }

      // Reload tasks to get updated data

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pop(context);

        final totalPoints =
            (_uploadedMediaFiles.length * 5) +
            (feedbackText.isNotEmpty ? 10 : 0);

        snackbarService.showSuccess(
          'Feedback added! ðŸŽ‰',
          description: '+$totalPoints points earned',
        );
      }
    } catch (e) {
      logE('Error submitting feedback', error: e);
      if (mounted) {
        snackbarService.showError('Failed to add feedback');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
