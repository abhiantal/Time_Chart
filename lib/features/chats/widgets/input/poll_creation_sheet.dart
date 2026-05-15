import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/features/chats/providers/chat_message_provider.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';

class PollCreationSheet extends StatefulWidget {
  final String chatId;

  const PollCreationSheet({super.key, required this.chatId});

  @override
  State<PollCreationSheet> createState() => _PollCreationSheetState();
}

class _PollCreationSheetState extends State<PollCreationSheet> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  final ScrollController _scrollController = ScrollController();

  int _durationMinutes = 1440; // Default 24 hours
  bool _allowMultiple = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Start with 2 options
    _addOption();
    _addOption();
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 10) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
      // Scroll to bottom after adding
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      AppSnackbar.warning('Maximum 10 options allowed');
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    } else {
      AppSnackbar.warning('Minimum 2 options required');
    }
  }

  Future<void> _submitPoll() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      AppSnackbar.warning('Please enter a question');
      return;
    }

    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (options.length < 2) {
      AppSnackbar.warning('Please provide at least 2 options');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<ChatMessageProvider>();

      await provider.sendSharedPollMessage(
        question: question,
        options: options,
        durationMinutes: _durationMinutes,
        allowMultiple: _allowMultiple,
      );

      if (mounted) {
        Navigator.pop(context, true);
        AppSnackbar.success('Poll created successfully');
      }
    } catch (e) {
      AppSnackbar.error('Failed to create poll', description: e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Create Poll',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submitPoll,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create'),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                // Question
                Text(
                  'Question',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _questionController,
                  maxLength: 100,
                  decoration: InputDecoration(
                    hintText: 'Ask a question...',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 
                      0.3,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    counterText: '',
                  ),
                  maxLines: 2,
                  minLines: 1,
                ),

                const SizedBox(height: 24),

                // Options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Options',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    if (_optionControllers.length < 10)
                      TextButton.icon(
                        onPressed: _addOption,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Option'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                ...List.generate(_optionControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _optionControllers[index],
                            decoration: InputDecoration(
                              hintText: 'Option ${index + 1}',
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        if (_optionControllers.length > 2) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _removeOption(index),
                            icon: Icon(
                              Icons.remove_circle_outline_rounded,
                              color: colorScheme.error.withValues(alpha: 0.7),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Settings
                Text(
                  'Settings',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),

                // Duration
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Poll Duration',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildDurationChip(15, '15m'),
                            const SizedBox(width: 8),
                            _buildDurationChip(60, '1h'),
                            const SizedBox(width: 8),
                            _buildDurationChip(1440, '24h'),
                            const SizedBox(width: 8),
                            _buildDurationChip(4320, '3d'),
                            const SizedBox(width: 8),
                            _buildDurationChip(10080, '1w'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Multiple Answers
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SwitchListTile(
                    value: _allowMultiple,
                    onChanged: (val) => setState(() => _allowMultiple = val),
                    title: const Text('Allow multiple answers'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip(int minutes, String label) {
    final isSelected = _durationMinutes == minutes;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (val) {
        if (val) setState(() => _durationMinutes = minutes);
      },
      showCheckmark: false,
      selectedColor: colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? Colors.transparent
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
