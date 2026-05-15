import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../../widgets/error_handler.dart';
import '../../widgets/common/user_avatar_cached.dart';

class ReportUserScreen extends StatefulWidget {
  final String userId;
  final String? userName;
  final String? userAvatar;

  const ReportUserScreen({
    super.key,
    required this.userId,
    this.userName,
    this.userAvatar,
  });

  @override
  State<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportReasonItem {
  final String id;
  final String title;
  final String description;

  const _ReportReasonItem(this.id, this.title, this.description);
}

class _ReportUserScreenState extends State<ReportUserScreen> {
  String? _selectedReason;
  String? _additionalDetails;
  bool _blockUser = false;
  bool _isSubmitting = false;

  final List<_ReportReasonItem> _reasons = const [
    _ReportReasonItem(
      'harassment',
      'Harassment',
      'Bullying, intimidation, or targeted attacks',
    ),
    _ReportReasonItem('spam', 'Spam', 'Unsolicited promotional content'),
    _ReportReasonItem('fake', 'Fake account', 'Impersonation or fake identity'),
    _ReportReasonItem(
      'inappropriate',
      'Inappropriate content',
      'Profile contains offensive material',
    ),
    _ReportReasonItem('scam', 'Scam or fraud', 'Attempting to defraud others'),
    _ReportReasonItem(
      'hate_speech',
      'Hate speech',
      'Promoting hatred or discrimination',
    ),
    _ReportReasonItem('other', 'Other', 'Something else not listed'),
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
        ErrorHandler.showSuccessSnackbar(
          _blockUser
              ? 'User reported and blocked'
              : 'Report submitted successfully',
        );
        Navigator.pop(context);
      }
    } catch (e, st) {
      ErrorHandler.hideLoading();
      ErrorHandler.handleError(e, st, 'ReportUserScreen.submitReport');
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
          'Report User',
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
              Center(
                child: Column(
                  children: [
                    UserAvatarCached(
                      imageUrl: widget.userAvatar,
                      name: widget.userName ?? 'User',
                      size: 80,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.userName ??
                          'User ${widget.userId.substring(0, 6)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Why are you reporting this user?',
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
              Card(
                elevation: 0,
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Also block this user'),
                        subtitle: const Text(
                          'They won\'t be able to contact you',
                        ),
                        value: _blockUser,
                        onChanged: (value) =>
                            setState(() => _blockUser = value),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.block_rounded,
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
    _ReportReasonItem reason,
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
