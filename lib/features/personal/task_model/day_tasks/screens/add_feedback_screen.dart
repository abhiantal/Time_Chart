import 'dart:io';
import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:video_compress/video_compress.dart';
import '../../../../../../widgets/app_snackbar.dart';
import '../../../../../../widgets/custom_text_field.dart';
import '../../../../../../widgets/logger.dart';
import '../../../../../media_utility/media_display.dart';
import '../../../../../media_utility/media_picker.dart';
import '../../../../../media_utility/universal_media_service.dart';
import '../models/day_task_model.dart';
import '../providers/day_task_provider.dart';

class AddFeedbackScreen extends StatefulWidget {
  final DayTaskModel task;
  final DateTime? selectedDate;

  const AddFeedbackScreen({super.key, required this.task, this.selectedDate});

  @override
  State<AddFeedbackScreen> createState() => _AddFeedbackScreenState();
}

class _AddFeedbackScreenState extends State<AddFeedbackScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();

  final List<EnhancedMediaFile> _uploadedMediaFiles = [];
  bool _isSubmitting = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
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

  @override
  void dispose() {
    _feedbackController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  DateTime get _selectedDate => widget.selectedDate ?? DateTime.now();

  String get _dayName => DateFormat('EEEE').format(_selectedDate);

  bool get _isSubmissionAllowed {
    final now = DateTime.now();
    final start = widget.task.timeline.startingTime;
    final taskDate = DateTime.parse(widget.task.timeline.taskDate);
    final endOfDay = DateTime(
      taskDate.year,
      taskDate.month,
      taskDate.day,
      23,
      59,
      59,
    );

    if (now.isAfter(endOfDay)) return false;
    if (now.isBefore(start)) return false;
    if (widget.task.indicators.status == 'completed') return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final allowed = _isSubmissionAllowed;

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
                      onPressed: _isSubmitting || _isUploading || !allowed
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
                        backgroundColor: allowed
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        foregroundColor: allowed
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
    final feedbackCount = widget.task.feedback.comments.length;
    final blocked = widget.task.indicators.status == 'completed';

    final now = DateTime.now();
    final start = widget.task.timeline.startingTime;
    final endOfDay = DateTime(
      DateTime.parse(widget.task.timeline.taskDate).year,
      DateTime.parse(widget.task.timeline.taskDate).month,
      DateTime.parse(widget.task.timeline.taskDate).day,
      23,
      59,
      59,
    );

    Color bannerColor;
    IconData bannerIcon;
    String bannerText;

    if (blocked) {
      bannerColor = colorScheme.tertiary;
      bannerIcon = Icons.check_circle_rounded;
      bannerText = 'Task completed. Feedback is disabled.';
    } else if (now.isAfter(endOfDay)) {
      bannerColor = colorScheme.error;
      bannerIcon = Icons.event_busy_rounded;
      bannerText = 'Task day ended. Feedback is locked.';
    } else if (now.isBefore(start)) {
      bannerColor = colorScheme.error;
      bannerIcon = Icons.timer_rounded;
      bannerText = 'Too early. Feedback opens at start time.';
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
            bannerColor.withOpacity(isDark ? 0.2 : 0.15),
            bannerColor.withOpacity(isDark ? 0.1 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bannerColor.withOpacity(0.2),
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
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                  colorScheme.primaryContainer.withOpacity(0.3),
                  colorScheme.secondaryContainer.withOpacity(0.2),
                ]
              : [colorScheme.primaryContainer, colorScheme.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withOpacity(isDark ? 0.3 : 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(isDark ? 0.1 : 0.15),
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
                  color: colorScheme.primary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.task_alt_rounded,
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
                      value: '${widget.task.metadata.progress}%',
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    _buildMiniStat(
                      icon: Icons.star_rounded,
                      value: widget.task.metadata.pointsEarned.toString(),
                      color: Colors.amber,
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
        color: color.withOpacity(0.15),
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
    final feedbackCount = widget.task.feedback.comments.length;
    final dayPoints = widget.task.metadata.pointsEarned;
    final dayProgress = widget.task.metadata.progress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
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
        color: color.withOpacity(0.1),
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
            mediaBucket: MediaBucket.dailyTaskMedia,
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

  /// Pick media using EnhancedMediaPicker
  Future<void> _pickMedia() async {
    if (_uploadedMediaFiles.length >= 10) {
      snackbarService.showWarning(
        'Maximum Limit Reached',
        description: 'You can only upload up to 10 media files',
      );
      return;
    }

    try {
      logI('📸 Opening enhanced media picker...');

      final XFile? media = await EnhancedMediaPicker.pickMedia(
        context,
        config: const MediaPickerConfig(
          allowCamera: true,
          allowGallery: false,
          allowDocument: false,
          allowImage: true,
          allowVideo: true,
          allowAudio: true,
          autoCompress: true,
          imageQuality: 70,
          videoQuality: VideoQuality.LowQuality,
          maxFileSizeMB: 10,
        ),
      );

      if (media != null) {
        logI('✅ Media selected: ${media.path}');

        final file = File(media.path);
        if (!await file.exists()) {
          throw Exception('Selected file does not exist');
        }

        await _uploadSingleMediaAndAdd(media);
      }
    } catch (e, stack) {
      logE('Failed to pick media', error: e, stackTrace: stack);
      snackbarService.showError(
        'Failed to pick media',
        description: e.toString(),
      );
    }
  }

  /// Upload single media and add to list
  Future<void> _uploadSingleMediaAndAdd(XFile selectedMedia) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final mediaUrl = await _uploadSingleMedia(selectedMedia);

      if (mediaUrl != null) {
        final mediaFile = EnhancedMediaFile.fromUrl(
          id: 'media_${mediaUrl.hashCode}',
          url: mediaUrl,
        );

        setState(() {
          _uploadedMediaFiles.add(mediaFile);
        });

        snackbarService.showSuccess(
          'Media Uploaded',
          description:
              '${_uploadedMediaFiles.length} file(s) uploaded successfully',
        );
      }
    } catch (e, stack) {
      logE('Upload error', error: e, stackTrace: stack);
      snackbarService.showError('Upload Failed', description: e.toString());
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  /// Upload single media file using UniversalMediaService
  Future<String?> _uploadSingleMedia(XFile selectedMedia) async {
    try {
      logI('📤 Uploading: ${selectedMedia.name}');

      setState(() => _uploadProgress = 0.3);

      final file = File(selectedMedia.path);

      setState(() => _uploadProgress = 0.6);

      // Use UniversalMediaService for upload
      final uploadedUrls = await mediaService.uploadTaskMedia(
        files: [file],
        taskType: 'daily',
        taskId: widget.task.id,
      );

      if (uploadedUrls.isEmpty) {
        throw Exception('Upload failed');
      }

      logI('✅ Upload successful!');
      setState(() => _uploadProgress = 1.0);

      return uploadedUrls.first;
    } catch (e, stack) {
      logE(
        'Upload error for ${selectedMedia.name}',
        error: e,
        stackTrace: stack,
      );

      if (e.toString().contains('mime type') &&
          e.toString().contains('not supported')) {
        snackbarService.showError(
          'Unsupported File Type',
          description: 'This file format is not supported.',
        );
      }

      return null;
    }
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

  /// Submit feedback with multiple media URLs (comma-separated)
  Future<void> _submitFeedback() async {
    logI('📝 Starting feedback submission...');

    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      logW('❌ Form validation failed');
      return;
    }

    if (!_isSubmissionAllowed) {
      snackbarService.showWarning(
        'Feedback locked',
        description: 'You cannot submit feedback right now.',
      );
      return;
    }

    final hasText = _feedbackController.text.trim().isNotEmpty;
    if (!hasText && _uploadedMediaFiles.isEmpty) {
      snackbarService.showWarning(
        'Empty Feedback',
        description: 'Please add media',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentCount = widget.task.feedback.comments.length;
      final feedbackNumber = (currentCount + 1).toString();

      logI('📝 Creating comment object');
      logI('  - Feedback Number: $feedbackNumber');
      logI('  - Media files: ${_uploadedMediaFiles.length}');

      // Create comma-separated URLs
      final mediaUrls = _uploadedMediaFiles.map((file) => file.url).join(',');

      logI('💾 Saving to database...');
      snackbarService.showLoading('Saving feedback...');

      final provider = context.read<DayTaskProvider>();
      final success = await provider.addFeedback(
        taskId: widget.task.id,
        feedbackText: _feedbackController.text.trim(),
        mediaUrl: mediaUrls.isEmpty ? null : mediaUrls,
      );

      snackbarService.hideLoading();

      if (!mounted) return;

      if (success) {
        logI('✅ Database update successful');
        await provider.loadTasks();

        Navigator.pop(context);

        snackbarService.showSuccess(
          '✅ Feedback Added!',
          description: _uploadedMediaFiles.isNotEmpty
              ? 'Feedback #$feedbackNumber with ${_uploadedMediaFiles.length} file(s) saved'
              : 'Feedback #$feedbackNumber saved successfully',
        );

        logI('🎉 Feedback submission complete!');
      } else {
        final errorMsg = provider.error ?? 'Database update failed';
        if (errorMsg.contains('Please wait')) {
          snackbarService.showWarning('Media Cooldown', description: errorMsg);
        } else {
          throw Exception(errorMsg);
        }
      }
    } catch (e, stack) {
      logE('❌ Feedback submission failed', error: e, stackTrace: stack);

      if (mounted) {
        snackbarService.hideLoading();
        snackbarService.showError(
          'Failed to Saves Feedback',
          description: 'Failed to generate feedback.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
