// lib/features/bucket/message_bubbles/checklist_feedback_add_dialog.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:the_time_chart/media_utility/media_display.dart';
import 'package:the_time_chart/media_utility/media_picker.dart';
import 'package:the_time_chart/media_utility/universal_media_service.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:the_time_chart/widgets/custom_text_field.dart';
import 'package:the_time_chart/widgets/logger.dart';
import 'package:the_time_chart/helpers/card_color_helper.dart';
import 'package:the_time_chart/features/personal/bucket_model/models/bucket_model.dart';
import 'package:the_time_chart/features/personal/bucket_model/providers/bucket_provider.dart';
import 'package:the_time_chart/features/personal/bucket_model/services/bucket_ai_service.dart';

/// Dialog for adding feedback when completing a checklist item
class ChecklistFeedbackAddDialog extends StatefulWidget {
  final BucketModel bucket;
  final ChecklistItem item;
  final int itemIndex;

  const ChecklistFeedbackAddDialog({
    super.key,
    required this.bucket,
    required this.item,
    required this.itemIndex,
  });

  static Future<bool?> show(
    BuildContext context,
    BucketModel bucket,
    ChecklistItem item,
    int itemIndex,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChecklistFeedbackAddDialog(
        bucket: bucket,
        item: item,
        itemIndex: itemIndex,
      ),
    );
  }

  @override
  State<ChecklistFeedbackAddDialog> createState() =>
      _ChecklistFeedbackAddDialogState();
}

class _ChecklistFeedbackAddDialogState
    extends State<ChecklistFeedbackAddDialog> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final _uploadedUrls = <String>[];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _isSaving = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    final cardColor = CardColorHelper.getProgressColor(
      widget.bucket.metadata.averageProgress.toInt(),
    );

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(theme),
          _buildHeader(theme, cardColor),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: _buildContent(theme, cardColor),
                ),
              ),
            ),
          ),
          _buildFooter(theme, cardColor),
        ],
      ),
    );
  }

  /// Builds the drag handle indicator
  Widget _buildHandle(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Builds the header section with task information
  Widget _buildHeader(ThemeData theme, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.task_alt, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete Task',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.task,
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

  /// Builds the main content area with form fields
  Widget _buildContent(ThemeData theme, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.item.feedbacks.isNotEmpty) ...[
          Text(
            'Previous Feedback',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.item.feedbacks.map((f) => _buildFeedbackTile(theme, f, accentColor)),
          const Divider(height: 32),
        ],

        Text(
          'Add New Feedback',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Share your experience with this task',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),

        // Feedback Field
        CustomTextField(
          controller: _feedbackController,
          label: 'Feedback',
          hint: 'How did it go? What did you learn?',
          prefixIcon: Icons.comment,
          maxLines: 5,
          minLines: 3,
          maxLength: 500,
          validator: (value) {
            if (_uploadedUrls.isEmpty && (value == null || value.trim().isEmpty)) {
              return 'Please add feedback or media';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        // Media Section
        _buildMediaSection(theme, accentColor),
      ],
    );
  }

  Widget _buildFeedbackTile(ThemeData theme, ChecklistFeedback feedback, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (feedback.isAiVerified ?? false) ? Colors.green.withValues(alpha: 0.3) : theme.dividerColor,
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
                  size: 16,
                  color: feedback.isAiVerified! ? Colors.green : Colors.orange,
                ),
              const SizedBox(width: 4),
              Text(
                feedback.isAiVerified == true ? 'AI Verified' : 'Pending/Refined',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: feedback.isAiVerified == true ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(feedback.timestamp),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(feedback.text, style: theme.textTheme.bodyMedium),
          if (feedback.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: feedback.mediaUrls.length,
                itemBuilder: (context, i) => Container(
                  width: 40,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    image: DecorationImage(
                      image: NetworkImage(feedback.mediaUrls[i]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Builds the media attachment section
  Widget _buildMediaSection(ThemeData theme, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library, size: 20, color: accentColor),
            const SizedBox(width: 8),
            Text(
              'Attach Media (Optional)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (_uploadedUrls.isNotEmpty)
              Text(
                '${_uploadedUrls.length} file${_uploadedUrls.length > 1 ? 's' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_uploadedUrls.isEmpty)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _isUploading ? null : _pickMedia,
            child: Container(
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.7,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: _isUploading
                  ? CircularProgressIndicator(
                      value: _uploadProgress == 0 ? null : _uploadProgress,
                      color: accentColor,
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          color: accentColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Attach Media',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          )
        else
          EnhancedMediaDisplay(
            mediaFiles: _uploadedUrls
                .asMap()
                .entries
                .map(
                  (e) => EnhancedMediaFile.fromUrl(
                    id: 'media_${e.key}',
                    url: e.value,
                  ),
                )
                .toList(),
            isLoading: _isUploading,
            config: const MediaDisplayConfig(
              layoutMode: MediaLayoutMode.grid,
              gridColumns: 3,
              mediaBucket: MediaBucket.bucketMedia,
              borderRadius: 12,
              spacing: 8,
              maxHeight: 220,
              allowDelete: true,
              showFileName: false,
              showFileSize: false,
              showDate: false,
            ),
            onDelete: (id) {
              final idx = int.tryParse(id.split('_').last);
              if (idx != null && idx >= 0 && idx < _uploadedUrls.length) {
                setState(() => _uploadedUrls.removeAt(idx));
              }
            },
            onAddMedia: _isUploading ? null : _pickMedia,
          ),
      ],
    );
  }

  /// Builds the footer with action buttons
  Widget _buildFooter(ThemeData theme, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveAndComplete,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_circle, size: 20),
              label: Text(_isSaving ? 'Saving...' : 'Complete Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMedia() async {
    try {
      final file = await EnhancedMediaPicker.pickMedia(
        context,
        config: MediaPickerConfig(
          allowCamera: true,
          allowGallery: true,
          allowImage: true,
          allowVideo: true,
          allowAudio: false,
          allowDocument: false,
          autoCompress: true,
        ),
      );

      if (file != null) {
        final f = File(file.path);
        setState(() {
          _isUploading = true;
          _uploadProgress = 0.1;
        });
        // Upload to bucket media and store public URLs
        final urls = await UniversalMediaService().uploadBucketMedia([f]);
        if (urls.isNotEmpty) {
          setState(() {
            _uploadedUrls.addAll(urls);
            _uploadProgress = 1.0;
            _isUploading = false;
          });
          snackbarService.showSuccess('Media uploaded');
        } else {
          setState(() {
            _uploadProgress = 0.0;
            _isUploading = false;
          });
          snackbarService.showError('Upload failed');
        }
      }
    } catch (e) {
      logE('Error picking media: $e');
      snackbarService.showError('Failed to pick media');
    }
  }

  Future<void> _saveAndComplete() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isSaving = true;
      });

      final provider = context.read<BucketProvider>();
      final aiService = BucketAiService();
      final userId = widget.bucket.userId;

      // 1. AI Verification
      final verification = await aiService.verifyFeedback(
        taskDescription: widget.item.task,
        feedbackText: _feedbackController.text.trim(),
        mediaUrls: _uploadedUrls,
        userId: userId,
        bucketId: widget.bucket.id,
      );

      // 2. Create new feedback entry
      final newFeedback = ChecklistFeedback(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: _feedbackController.text.trim(),
        mediaUrls: _uploadedUrls.toList(),
        timestamp: DateTime.now(),
        isAiVerified: verification.success,
        aiFeedback: verification.feedback,
      );

      // 3. Update checklist item
      final updatedFeedbacks = List<ChecklistFeedback>.from(widget.item.feedbacks)
        ..add(newFeedback);
      
      final updatedItem = widget.item.copyWith(
        done: true, // Mark as done when at least one feedback is added
        feedbacks: updatedFeedbacks,
        date: DateTime.now(),
      );

      // 4. Update in bucket's checklist
      final updatedChecklist = List<ChecklistItem>.from(widget.bucket.checklist);
      updatedChecklist[widget.itemIndex] = updatedItem;

      // 5. Update bucket (recalculateRewards is usually called in provider or repository)
      final updatedBucket = widget.bucket.copyWith(checklist: updatedChecklist);
      final success = await provider.updateBucket(updatedBucket);

      if (success && mounted) {
        Navigator.pop(context, true);
        if (verification.success) {
          AppSnackbar.success('Feedback verified and saved!');
        } else {
          AppSnackbar.warning('Feedback saved but verification failed: ${verification.feedback}');
        }
      }
    } catch (e, stackTrace) {
      logE('Error completing task: $e', error: e, stackTrace: stackTrace);
      AppSnackbar.error('Failed to save feedback');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Note: Individual item points are now handled in BucketModel.recalculateRewards()
  // based on word count, media count, etc.
}
