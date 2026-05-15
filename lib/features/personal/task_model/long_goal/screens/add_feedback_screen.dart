// lib/features/long_goals/screens_widgets/add_feedback_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:video_compress/video_compress.dart';
import '../../../../../widgets/error_handler.dart';
import '../../../../../../widgets/custom_text_field.dart';
import '../../../../../../widgets/logger.dart';
import '../../../../../media_utility/media_display.dart';
import '../../../../../media_utility/media_picker.dart';
import '../../../../../media_utility/universal_media_service.dart';
import 'package:provider/provider.dart';
import '../providers/long_goals_provider.dart';
import '../models/long_goal_model.dart';

class AddLongGoalFeedbackScreen extends StatefulWidget {
  final String goalId;
  final String weekId;
  final DateTime feedbackDate; // NEW: Specific date for feedback
  final String goalTitle;
  final String weeklyGoal;
  final DailyFeedback? existingFeedback; // NEW: For editing existing feedback

  const AddLongGoalFeedbackScreen({
    super.key,
    required this.goalId,
    required this.weekId,
    required this.feedbackDate,
    required this.goalTitle,
    required this.weeklyGoal,
    this.existingFeedback,
  });

  @override
  State<AddLongGoalFeedbackScreen> createState() =>
      _AddLongGoalFeedbackScreenState();
}
class _AddLongGoalFeedbackScreenState extends State<AddLongGoalFeedbackScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();

  final List<EnhancedMediaFile> _uploadedMediaFiles = [];
  bool _isSubmitting = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  late DateTime _selectedDate;
  late String _currentWeekId;
  List<DateTime> _missedDates = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.feedbackDate;
    _currentWeekId = widget.weekId;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();

    // Pre-fill if editing existing feedback
    if (widget.existingFeedback != null) {
      _feedbackController.text = widget.existingFeedback!.feedbackText;
      if (widget.existingFeedback!.mediaUrl != null &&
          widget.existingFeedback!.mediaUrl!.isNotEmpty) {
        final urls = widget.existingFeedback!.mediaUrl!.split(',');
        for (var url in urls) {
          if (url.trim().isNotEmpty) {
            _uploadedMediaFiles.add(
              EnhancedMediaFile.fromUrl(
                id: 'media_${url.hashCode}',
                url: url.trim(),
              ),
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  // Check if feedback date is today
  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  // Check if feedback date is in the past
  bool get _isPastDate {
    return _selectedDate.isBefore(DateTime.now());
  }

  /// Pick media using EnhancedMediaPicker
  Future<void> _pickMedia() async {
    if (_uploadedMediaFiles.length >= 10) {
      ErrorHandler.showErrorSnackbar(
        'You can only upload up to 10 media files',
        title: 'Maximum Limit Reached',
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
          allowImage: true,
          allowVideo: true,
          allowDocument: false,
          autoCompress: true,
          imageQuality: 70,
          videoQuality: VideoQuality.LowQuality,
          maxFileSizeMB: 10,
        ),
      );

      if (media != null) {
        final file = File(media.path);
        if (!await file.exists()) throw Exception('Selected file missing');
        await _uploadSingleMediaAndAdd(media);
      }
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'Media pick failed');
      ErrorHandler.showErrorSnackbar('Failed to pick media');
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

        ErrorHandler.showSuccessSnackbar(
          '${_uploadedMediaFiles.length} file(s) uploaded successfully',
          title: 'Media Uploaded',
        );
      }
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Upload failed');
      ErrorHandler.showErrorSnackbar(e.toString(), title: 'Upload Failed');
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
      setState(() => _uploadProgress = 0.3);
      final file = File(selectedMedia.path);
      setState(() => _uploadProgress = 0.6);

      final uploadedUrls = await mediaService.uploadTaskMedia(
        files: [file],
        taskType: 'long',
        taskId: widget.goalId,
      );

      if (uploadedUrls.isEmpty) throw Exception('Upload failed');
      setState(() => _uploadProgress = 1.0);
      return uploadedUrls.first;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Upload error');
      return null;
    }
  }

  /// Submit feedback to backend
  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate date restrictions
    if (!_isToday && !_isPastDate) {
      ErrorHandler.showErrorSnackbar(
        'You can only add feedback for today or past dates',
        title: 'Invalid Date',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final provider = Provider.of<LongGoalsProvider>(context, listen: false);

      // Compute feedback day (epoch seconds) and feedback number (DD-MM-YYYY)
      final feedbackDay = _selectedDate.millisecondsSinceEpoch ~/ 1000;
      final feedbackNumber = DateFormat(
        'dd-MM-yyyy',
      ).format(_selectedDate);

      final mediaUrls = _uploadedMediaFiles.map((f) => f.url).join(',');
      final result = await provider.addDailyFeedback(
        goalId: widget.goalId,
        weekId: _currentWeekId,
        feedbackText: _feedbackController.text.trim(),
        mediaUrl: mediaUrls.isEmpty ? null : mediaUrls,
        feedbackDay: feedbackDay,
        feedbackCount: feedbackNumber,
      );

      if (result && context.mounted) {
        HapticFeedback.mediumImpact();
        ErrorHandler.showSuccessSnackbar(
          widget.existingFeedback != null
              ? 'Feedback updated successfully'
              : 'Feedback saved successfully',
          title: 'Success',
        );

        // Await animation completion before returning
        await _animationController.reverse();
        if (context.mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'Submit failed');
      ErrorHandler.showErrorSnackbar('Failed to save feedback');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Retrieve goal to calculate today's progress
    final provider = Provider.of<LongGoalsProvider>(context);
    LongGoalModel? currentGoal;
    try {
      currentGoal = provider.goals.firstWhere((g) => g.id == widget.goalId);
    } catch (_) {}

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0D1117) : colorScheme.surface,
        appBar: _buildAppBar(theme, colorScheme),
        body: ScaleTransition(
          scale: _scaleAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Date Selector (If missed dates available)
                    if (_missedDates.isNotEmpty)
                      _buildDateSelector(theme, colorScheme, isDark),
                    if (_missedDates.isNotEmpty) const SizedBox(height: 16),

                    // Date & Status Banner
                    _buildDateStatusBanner(theme, colorScheme, isDark),
                    const SizedBox(height: 20),

                    // Goal Info Card
                    _buildGoalInfoCard(theme, colorScheme, isDark),
                    const SizedBox(height: 24),

                    // Today's Progress Summary
                    if (currentGoal != null)
                      _buildTodayProgressSummary(
                        theme,
                        colorScheme,
                        isDark,
                        currentGoal,
                      )
                    else
                      _buildMotivationSummary(theme, colorScheme, isDark),
                    const SizedBox(height: 24),

                    // Media Section
                    _buildMediaUpload(context),
                    const SizedBox(height: 24),

                    // Custom Feedback TextField
                    _buildFeedbackTextField(theme, colorScheme),
                    const SizedBox(height: 32),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilledButton.icon(
                          onPressed: _isSubmitting || _isUploading
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
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  // ============================================
  // UI COMPONENTS
  // ============================================

  PreferredSizeWidget _buildAppBar(ThemeData theme, ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existingFeedback != null ? 'Edit Feedback' : 'Add Feedback',
          ),
          Text(
            DateFormat('EEEE').format(_selectedDate),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    // Current goal is used to find missed dates
    final provider = Provider.of<LongGoalsProvider>(context, listen: false);
    LongGoalModel? goal;
    try {
      goal = provider.goals.firstWhere((g) => g.id == widget.goalId);
    } catch (_) {}

    if (goal == null) return const SizedBox.shrink();

    // Populate missed dates if empty
    if (_missedDates.isEmpty) {
      _missedDates = goal.getMissedDates();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Combine today with missed dates
    final allOptions = [today, ..._missedDates];
    
    // Ensure _selectedDate is in options (it might be widget.feedbackDate which is already there)
    if (!allOptions.any((d) => d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day)) {
      allOptions.insert(0, _selectedDate);
    }

    return DropdownButtonFormField<DateTime>(
      value: allOptions.firstWhere(
        (d) => d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day,
        orElse: () => allOptions.first,
      ),
      decoration: InputDecoration(
        labelText: 'Select Log Date',
        prefixIcon: const Icon(Icons.calendar_month_rounded),
        filled: true,
        fillColor: isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      items: allOptions.map((date) {
        final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
        final label = isToday ? 'Today' : DateFormat('EEE, MMM d').format(date);
        return DropdownMenuItem<DateTime>(
          value: date,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday ? const Color(0xFF10B981) : colorScheme.onSurface,
            ),
          ),
        );
      }).toList(),
      onChanged: (DateTime? newDate) {
        if (newDate != null) {
          setState(() {
            _selectedDate = newDate;
            _currentWeekId = goal!.getWeekIdForDate(newDate);
            // Reset form for fresh entry on past date
            _feedbackController.clear();
            _uploadedMediaFiles.clear();
          });
        }
      },
    );
  }

  // ============================================
  // UI COMPONENTS
  // ============================================

  Widget _buildDateStatusBanner(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final bannerColor = _isToday
        ? const Color(0xFF10B981)
        : colorScheme.primary;
    final bannerIcon = _isToday ? Icons.today_rounded : Icons.history_rounded;
    final bannerText = _isToday
        ? 'Ready to log today\'s progress!'
        : 'Adding feedback for a past date.';

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

  Widget _buildGoalInfoCard(
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
            child: const Icon(
              Icons.flag_rounded,
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
                  widget.goalTitle,
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
                    Icon(
                      Icons.format_list_bulleted_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.weeklyGoal,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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
    );
  }

  Widget _buildTodayProgressSummary(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    LongGoalModel goal,
  ) {
    // 1. Calculate today's progress using the goal reference
    DailyProgress? todayProgress;
    int feedbackCount = 0;

    try {
      final week = goal.goalLog.weeklyLogs.firstWhere((w) => w.weekId == widget.weekId);
      final targetDateStr = DateFormat(
        'yyyy-MM-dd',
      ).format(_selectedDate);

      final dayFeedbacks = week.dailyFeedback.where((f) {
        return DateFormat('yyyy-MM-dd').format(f.date) == targetDateStr;
      }).toList();

      feedbackCount = dayFeedbacks.length;
      if (dayFeedbacks.isNotEmpty) {
        todayProgress = DailyProgress.calculateForDay(
          weekId: widget.weekId,
          dayFeedbacks: dayFeedbacks,
          hoursPerDay: goal.timeline.workSchedule.hoursPerDay,
        );
      }
    } catch (_) {}

    final dayPoints = todayProgress?.pointsEarned ?? 0;
    final dayProgress = todayProgress?.progress ?? 0;

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

  Widget _buildMotivationSummary(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final messages = [
      '💪 Every step counts toward your long-term goal!',
      '🌟 Progress, not perfection.',
      '🎯 Celebrate your small wins today.',
      '🚀 Consistency builds momentum.',
      '✨ Reflect on what you accomplished.',
      '🔥 Your effort today matters.',
    ];
    final message = messages[_selectedDate.day % messages.length];

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
              Icon(Icons.lightbulb_rounded, size: 20, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Motivation',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
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
          label: 'Daily Feedback',
          hint: 'What did you accomplish? What challenges did you face?',
          maxLines: 6,
          maxLength: 1000,
          required: _uploadedMediaFiles.isEmpty,
          validator: (v) {
            if (_uploadedMediaFiles.isEmpty &&
                (v == null || v.trim().isEmpty)) {
              return 'Please enter feedback or add media';
            }
            return null;
          },
        ),
      ],
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
            Text(
              'Media (Optional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
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
            mediaBucket: MediaBucket.longGoalsMedia,
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
            ErrorHandler.showSuccessSnackbar(
              _uploadedMediaFiles.isEmpty
                  ? 'All media removed'
                  : '${_uploadedMediaFiles.length} file(s) remaining',
              title: 'Media Removed',
            );
          },
          onAddMedia:
              _uploadedMediaFiles.length < 10 && !_isSubmitting && !_isUploading
              ? _pickMedia
              : null,
          emptyMessage: 'No media attached',
        ),

        // Add Media Button (shown when list is not empty)
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

        // Upload Progress Indicator
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
}
