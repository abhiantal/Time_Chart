import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:the_time_chart/features/social/comments/models/comments_model.dart';
import 'package:the_time_chart/features/social/comments/providers/comment_provider.dart';
import 'dart:async';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:the_time_chart/widgets/logger.dart';
import '../../../../../media_utility/media_picker.dart';

class CommentInput extends StatefulWidget {
  final String postId;
  final String currentUserId;
  final bool isPostAuthor;

  const CommentInput({
    super.key,
    required this.postId,
    required this.currentUserId,
    required this.isPostAuthor,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _mentionSuggestions = [];
  bool _isSubmitting = false;
  bool _showEmojiPicker = false;
  CommentMedia? _selectedMedia;
  Timer? _typingTimer;
  String? _lastReplyId;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showEmojiPicker = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _detectMentions();
      }
    });

    // Update provider state
    context.read<CommentProvider>().updateInputText(
      widget.postId,
      _textController.text,
    );
  }

  void _detectMentions() {
    final text = _textController.text;
    final mentionRegex = RegExp(r'@(\w+)$');
    final matches = mentionRegex.allMatches(text);

    if (matches.isNotEmpty) {
      // final lastMatch = matches.last;
      // final query = lastMatch.group(1)?.toLowerCase() ?? '';
      // Fetch mention suggestions from your user service
      // _fetchMentionSuggestions(query);
      // Fetch mention suggestions
    }
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  Future<void> _pickMedia() async {
    try {
      final file = await EnhancedMediaPicker.pickMedia(
        context,
        config: const MediaPickerConfig(
          allowCamera: true,
          allowGallery: true,
          allowImage: true,
          allowVideo: false,
          allowAudio: false,
          allowDocument: false,
          autoCompress: true,
        ),
      );

      if (file != null && mounted) {
        setState(() {
          _selectedMedia = CommentMedia(type: 'image', url: file.path);
        });
      }
    } catch (e, stack) {
      logE('Error picking media', error: e, stackTrace: stack);
      AppSnackbar.error('Failed to pick image');
    }
  }

  Future<void> _submitComment() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedMedia == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Get current reply state from provider
      final replyState = context
          .read<CommentProvider>()
          .getInputState(widget.postId)
          .replyState;

      final comment = await context.read<CommentProvider>().addComment(
        postId: widget.postId,
        content: text,
        parentCommentId: replyState.replyToCommentId,
        media: _selectedMedia,
        mentions: context
            .read<CommentProvider>()
            .getInputState(widget.postId)
            .detectedMentions,
      );

      if (comment != null && mounted) {
        _textController.clear();
        setState(() {
          _selectedMedia = null;
          _showEmojiPicker = false;
        });
        _focusNode.unfocus();

        HapticFeedback.lightImpact();
      }
    } catch (e, stack) {
      logE('Error submitting comment', error: e, stackTrace: stack);
      AppSnackbar.error('Failed to post comment');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final replyState = context
        .watch<CommentProvider>()
        .getInputState(widget.postId)
        .replyState;
    final isReplying = replyState.isReplying;

    // Handle auto-focus when reply state changes
    if (replyState.replyToCommentId != _lastReplyId) {
      _lastReplyId = replyState.replyToCommentId;
      if (isReplying) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        });
      }
    }

    return PopScope(
      canPop: !_showEmojiPicker,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _showEmojiPicker) {
          setState(() {
            _showEmojiPicker = false;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply context bar
            if (isReplying) _buildReplyBar(context, theme, replyState),

            // Selected media preview
            if (_selectedMedia != null)
              Container(
                height: 80,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedMedia!.url),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Image attached',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to remove',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() => _selectedMedia = null);
                      },
                    ),
                  ],
                ),
              ),

            // Input row
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Media button - Matches image style
                  GestureDetector(
                    onTap: _selectedMedia == null ? _pickMedia : null,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 24,
                        color: _selectedMedia == null
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Text field container
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              focusNode: _focusNode,
                              maxLines: 4,
                              minLines: 1,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: isReplying
                                    ? replyState.placeholderText
                                    : 'Add a comment...',
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.6),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              style: theme.textTheme.bodyMedium,
                              onSubmitted: (_) => _submitComment(),
                            ),
                          ),

                          // Emoji icon - placed inside text field container
                          IconButton(
                            icon: Icon(
                              _showEmojiPicker
                                  ? Icons.keyboard_rounded
                                  : Icons.emoji_emotions_outlined,
                              size: 22,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.7),
                            ),
                            onPressed: _toggleEmojiPicker,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Send button - Circular gradient
                  GestureDetector(
                    onTap: _isSubmitting ? null : _submitComment,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF40C4FF),
                            theme.colorScheme.primary,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isSubmitting
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Emoji Picker
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _showEmojiPicker
                  ? SizedBox(
                      height: 250,
                      child: EmojiPicker(
                        onEmojiSelected: (category, emoji) {
                          _textController.text += emoji.emoji;
                        },
                        config: Config(
                          height: 250,
                          emojiViewConfig: EmojiViewConfig(
                            columns: 7,
                            emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                            backgroundColor: theme.scaffoldBackgroundColor,
                            loadingIndicator: const SizedBox.shrink(),
                          ),
                          categoryViewConfig: CategoryViewConfig(
                            backgroundColor: theme.scaffoldBackgroundColor,
                            indicatorColor: theme.colorScheme.primary,
                            iconColor: theme.colorScheme.onSurfaceVariant,
                            iconColorSelected: theme.colorScheme.primary,
                            backspaceColor: theme.colorScheme.primary,
                          ),
                          skinToneConfig: SkinToneConfig(
                            dialogBackgroundColor:
                                theme.scaffoldBackgroundColor,
                            indicatorColor: theme.colorScheme.onSurfaceVariant,
                          ),
                          checkPlatformCompatibility: true,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Mention suggestions
            if (_mentionSuggestions.isNotEmpty)
              _buildMentionSuggestions(context, theme),

            // Extra padding to avoid system navigation bar if not in keyboard mode
            if (!_showEmojiPicker &&
                MediaQuery.of(context).viewInsets.bottom == 0)
              SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyBar(
    BuildContext context,
    ThemeData theme,
    ({bool isReplying, String placeholderText, String? replyToCommentId}) state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.reply_rounded, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Replying to ",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.7,
                      ),
                    ),
                  ),
                  TextSpan(
                    text: state.placeholderText.replaceAll('Replying to ', ''),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              context.read<CommentProvider>().cancelReply(widget.postId);
              HapticFeedback.lightImpact();
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.close_rounded, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentionSuggestions(BuildContext context, ThemeData theme) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _mentionSuggestions.length,
        itemBuilder: (context, index) {
          final username = _mentionSuggestions[index];
          return GestureDetector(
            onTap: () {
              final currentText = _textController.text;
              final lastAtPos = currentText.lastIndexOf('@');
              if (lastAtPos != -1) {
                _textController.text =
                    '${currentText.substring(0, lastAtPos)}@$username ';
                _textController.selection = TextSelection.collapsed(
                  offset: _textController.text.length,
                );
              }
              setState(() => _mentionSuggestions.clear());
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '@$username',
                    style: theme.textScheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

extension _ThemeTextScheme on ThemeData {
  TextTheme get textScheme => textTheme;
}
