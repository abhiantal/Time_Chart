import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../../widgets/error_handler.dart';

class ReportMessageScreen extends StatefulWidget {
  final String messageId;
  final String? messageContent;
  final String? senderName;

  const ReportMessageScreen({
    super.key,
    required this.messageId,
    this.messageContent,
    this.senderName,
  });

  @override
  State<ReportMessageScreen> createState() => _ReportMessageScreenState();
}

class _ReportMessageScreenState extends State<ReportMessageScreen> {
  String? _selectedReason;
  String? _additionalDetails;
  bool _includeMessage = true;
  bool _isSubmitting = false;

  final List<ReportReason> _reasons = [
    ReportReason(
      'harassment',
      'Harassment',
      'Bullying, intimidation, or targeted attacks',
    ),
    ReportReason('spam', 'Spam', 'Unsolicited promotional content'),
    ReportReason(
      'inappropriate',
      'Inappropriate content',
      'NSFW, explicit, or offensive material',
    ),
    ReportReason(
      'violence',
      'Violence or threats',
      'Threats of physical harm or violence',
    ),
    ReportReason(
      'hate_speech',
      'Hate speech',
      'Discrimination based on identity',
    ),
    ReportReason(
      'copyright',
      'Copyright infringement',
      'Unauthorized use of copyrighted material',
    ),
    ReportReason('other', 'Other', 'Something else not listed'),
  ];

  void _submitReport() async {
    if (_selectedReason == null) {
      ErrorHandler.showErrorSnackbar('Please select a reason');
      return;
    }

    try {
      setState(() => _isSubmitting = true);
      HapticFeedback.mediumImpact();
      ErrorHandler.showLoading('Submitting report...');

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      ErrorHandler.hideLoading();

      if (mounted) {
        ErrorHandler.showSuccessSnackbar('Report submitted successfully');
        Navigator.pop(context);
      }
    } catch (e, st) {
      ErrorHandler.hideLoading();
      ErrorHandler.handleError(e, st, 'ReportMessageScreen.submitReport');
      ErrorHandler.showErrorSnackbar('Failed to submit report');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          'Report Message',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (widget.messageContent != null || widget.senderName != null)
                Card(
                  elevation: 0,
                  color: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.senderName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person_rounded,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'From: ${widget.senderName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (widget.messageContent != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(widget.messageContent!),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Why are you reporting this message?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ..._reasons.map(
                (reason) => _buildReasonTile(reason, theme, colorScheme),
              ),
              const SizedBox(height: 24),
              CustomTextField.multiline(
                label: 'Additional details (optional)',
                hint: 'Provide more information...',
                maxLines: 4,
                onChanged: (value) => _additionalDetails = value,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Include reported message'),
                subtitle: const Text(
                  'Share the message content with moderators',
                ),
                value: _includeMessage,
                onChanged: (value) => setState(() => _includeMessage = value),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.message_rounded,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your report is anonymous. We\'ll review it and take appropriate action.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Submit Report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReasonTile(
    ReportReason reason,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isSelected = _selectedReason == reason.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isSelected
          ? colorScheme.primary.withValues(alpha: 0.1)
          : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        title: Text(
          reason.title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? colorScheme.primary : null,
          ),
        ),
        subtitle: Text(reason.description),
        value: reason.id,
        groupValue: _selectedReason,
        onChanged: (value) => setState(() => _selectedReason = value),
        activeColor: colorScheme.primary,
      ),
    );
  }
}

class ReportReason {
  final String id;
  final String title;
  final String description;

  ReportReason(this.id, this.title, this.description);
}
