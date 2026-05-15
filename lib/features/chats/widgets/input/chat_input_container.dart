// ================================================================
// FILE: lib/features/chat/widgets/input/chat_input_container.dart
// PURPOSE: Main chat input container with text field, attachments, voice
// STYLE: WhatsApp + Snapchat hybrid
// DEPENDENCIES: All input components
// ================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/features/chats/model/chat_attachment_model.dart';
import 'package:the_time_chart/features/chats/widgets/input/poll_creation_sheet.dart';

import '../../providers/chat_message_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/chat_attachment_provider.dart';
import '../../utils/chat_text_utils.dart';
import 'bottom_sheet_widget.dart';
import 'chat_text_input_field.dart';
import 'chat_send_button.dart';
import 'chat_attachment_button.dart';
import 'chat_emoji_button.dart';
import 'chat_reply_bar.dart';
import 'chat_voice_recorder.dart';
import 'chat_mention_popup.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;

import '../../../../media_utility/camera_capture_screen.dart';
import '../../../../media_utility/gallery_picker_screen.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'task_creation_sheet.dart';
import '../../../../widgets/app_snackbar.dart';

class ChatInputContainer extends StatefulWidget {
  final String chatId;
  final TextEditingController textController;
  final FocusNode focusNode;
  final VoidCallback onTyping;

  const ChatInputContainer({
    super.key,
    required this.chatId,
    required this.textController,
    required this.focusNode,
    required this.onTyping,
  });

  @override
  State<ChatInputContainer> createState() => _ChatInputContainerState();
}

class _ChatInputContainerState extends State<ChatInputContainer>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _isRecording = false;
  bool _recordingInitiallyLocked = false;
  bool _isComposing = false;
  bool _showEmojiPicker = false;
  bool _showMentionPopup = false;
  OverlayEntry? _mentionOverlay;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _inputFieldKey = GlobalKey();
  final GlobalKey<ChatVoiceRecorderState> _recorderKey = GlobalKey();

  late AnimationController _inputAnimationController;
  late Animation<double> _inputAnimation;

  Timer? _typingDebounceTimer;

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
    WidgetsBinding.instance.addObserver(this);

    _inputAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _inputAnimation = CurvedAnimation(
      parent: _inputAnimationController,
      curve: Curves.easeOutCubic,
    );
    _inputAnimationController.forward();
    
    // Load draft
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChatMessageProvider>();
      final draft = provider.getDraft(widget.chatId);
      if (draft != null && draft.isNotEmpty) {
        widget.textController.text = draft;
        widget.textController.selection = TextSelection.collapsed(offset: draft.length);
        if (mounted) setState(() => _isComposing = true);
      }
    });
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    WidgetsBinding.instance.addObserver(this);
    _typingDebounceTimer?.cancel();
    _removeMentionOverlay();
    _inputAnimationController.dispose();
    super.dispose();
  }

  Timer? _draftTimer;

  void _onTextChanged() {
    final hasText = widget.textController.text.isNotEmpty;
    if (hasText != _isComposing) {
      setState(() => _isComposing = hasText);
    }

    // 1. Immediate Typing indicator (throttled inside repository)
    widget.onTyping();

    // 2. Mentions check (immediate for UI overlay)
    _checkForMentions();

    // 3. Debounced Draft Saving (avoids excessive disk writes)
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final text = widget.textController.text;
      context.read<ChatMessageProvider>().saveDraft(widget.chatId, text);
      try {
        context.read<ChatProvider>().updateDraft(widget.chatId, text);
      } catch (_) {}
    });
  }

  void _onFocusChanged() {
    if (widget.focusNode.hasFocus) {
      _inputAnimationController.forward();
      if (_showEmojiPicker) {
        setState(() => _showEmojiPicker = false);
      }
    }
  }

  void _checkForMentions() {
    final query = ChatTextUtils.getMentionQuery(
      widget.textController.text,
      widget.textController.selection.baseOffset,
    );

    if (query != null) {
      if (!_showMentionPopup) {
        setState(() => _showMentionPopup = true);
        _showMentionOverlay(query);
      } else {
        _updateMentionOverlay(query);
      }
    } else {
      if (_showMentionPopup) {
        setState(() => _showMentionPopup = false);
        _removeMentionOverlay();
      }
    }
  }

  void _showMentionOverlay(String query) {
    _removeMentionOverlay();

    final overlay = Overlay.of(context);
    final renderBox =
        _inputFieldKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _mentionOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy - 200, // Show above input
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, -200),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ChatMentionPopup(
              chatId: widget.chatId,
              query: query,
              onMentionSelected: _insertMention,
            ),
          ),
        ),
      ),
    );

    overlay.insert(_mentionOverlay!);
  }

  void _updateMentionOverlay(String query) {
    if (_mentionOverlay != null) {
      _showMentionOverlay(query);
    }
  }

  void _removeMentionOverlay() {
    _mentionOverlay?.remove();
    _mentionOverlay = null;
  }

  void _insertMention(String userId, String displayName) {
    final newText = ChatTextUtils.insertMention(
      text: widget.textController.text,
      cursorPosition: widget.textController.selection.baseOffset,
      userId: userId,
      displayName: displayName,
    );

    widget.textController.text = newText;
    widget.textController.selection = TextSelection.collapsed(
      offset: newText.length,
    );

    _removeMentionOverlay();
    setState(() => _showMentionPopup = false);
  }

  Future<void> _handleSend() async {
    final text = widget.textController.text.trim();
    if (text.isEmpty && !_isRecording) return;

    HapticFeedback.lightImpact();

    if (_isRecording) {
      final attachmentProvider = context.read<ChatAttachmentProvider>();

      // Stop recording via GlobalKey
      await _recorderKey.currentState?.stopRecording();

      final voiceResult = await attachmentProvider.sendVoiceNote();
      if (voiceResult.success) {
        setState(() => _isRecording = false);
      }
    } else {
      final provider = context.read<ChatMessageProvider>();
      await provider.sendMessage(text);
      try {
        context.read<ChatProvider>().updateDraft(widget.chatId, '');
      } catch (_) {}
      widget.textController.clear();
      if (_showEmojiPicker) {
        setState(() => _showEmojiPicker = false);
      }
    }
  }

  void _handleAttachmentPressed() {
    HapticFeedback.lightImpact();
    widget.focusNode.unfocus();

    showModalBottomSheet<ChatAttachmentType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const AttachmentPickerSheet(),
    ).then((result) {
      if (result != null) {
        _handleAttachmentResult(result);
      }
    });
  }

  void _handleAttachmentResult(ChatAttachmentType type) async {
    switch (type) {
      case ChatAttachmentType.camera:
      case ChatAttachmentType.cameraVideo:
        _openCamera();
        break;
      case ChatAttachmentType.gallery:
        _openGallery();
        break;
      case ChatAttachmentType.document:
        _pickDocument();
        break;
      case ChatAttachmentType.audio:
        setState(() {
          _isRecording = true;
          _recordingInitiallyLocked = true;
        });
        break;
      case ChatAttachmentType.task:
        _openTaskCreation();
        break;
      case ChatAttachmentType.poll:
        _openPollCreation();
        break;
    }
  }

  Future<void> _openCamera() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (context) => const CameraCaptureScreen()),
    );

    if (result == null) return;

    final attachmentProvider = context.read<ChatAttachmentProvider>();
    attachmentProvider.setActiveChatId(widget.chatId);

    if (result is List<XFile>) {
      for (var xFile in result) {
        await attachmentProvider.sendFile(
          file: File(xFile.path),
          type:
              xFile.path.toLowerCase().endsWith('.mp4') ||
                  xFile.path.toLowerCase().endsWith('.mov')
              ? AttachmentType.video
              : AttachmentType.image,
        );
      }
    } else if (result is CameraCaptureResult) {
      for (var xFile in result.files) {
        await attachmentProvider.sendFile(
          file: File(xFile.path),
          type:
              xFile.path.toLowerCase().endsWith('.mp4') ||
                  xFile.path.toLowerCase().endsWith('.mov')
              ? AttachmentType.video
              : AttachmentType.image,
        );
      }
    }
  }

  Future<void> _openGallery() async {
    final result = await Navigator.push<List<File>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const GalleryPickerScreen(allowMultiple: true, maxSelection: 10),
      ),
    );

    if (result != null && result.isNotEmpty) {
      final attachmentProvider = context.read<ChatAttachmentProvider>();
      attachmentProvider.setActiveChatId(widget.chatId);
      for (var file in result) {
        await attachmentProvider.sendFile(
          file: file,
          type:
              file.path.toLowerCase().endsWith('.mp4') ||
                  file.path.toLowerCase().endsWith('.mov')
              ? AttachmentType.video
              : AttachmentType.image,
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final attachmentProvider = context.read<ChatAttachmentProvider>();
        attachmentProvider.setActiveChatId(widget.chatId);
        for (var file in result.files) {
          if (file.path != null) {
            await attachmentProvider.sendFile(
              file: File(file.path!),
              type: AttachmentType.document,
            );
          }
        }
      }
    } catch (e) {
      AppSnackbar.error('Error picking document', description: e.toString());
    }
  }

  void _openTaskCreation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskCreationSheet(chatId: widget.chatId),
    );
  }

  void _openPollCreation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PollCreationSheet(chatId: widget.chatId),
    );
  }

  void _handleEmojiPressed() {
    HapticFeedback.lightImpact();
    if (_showEmojiPicker) {
      widget.focusNode.requestFocus();
    } else {
      widget.focusNode.unfocus();
    }
    setState(() => _showEmojiPicker = !_showEmojiPicker);
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    widget.textController
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: widget.textController.text.length),
      );
    _onTextChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatMessageProvider>(
      builder: (context, provider, _) {
        return SizeTransition(
          sizeFactor: _inputAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: CompositedTransformTarget(
              link: _layerLink,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reply/Edit bar
                  if ((provider.isReplyMode || provider.isEditing) &&
                      provider.actionMessage != null)
                    ChatReplyBar(
                      actionMessage: provider.actionMessage!,
                      isEditing: provider.isEditing,
                      onCancel: provider.clearAction,
                    ),

                  // Main input row
                  Padding(
                    padding: EdgeInsets.only(
                      left: 8,
                      right: 8,
                      bottom: MediaQuery.of(context).viewInsets.bottom > 0
                          ? 8
                          : MediaQuery.of(context).padding.bottom + 8,
                      top: 4,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Attachment button
                          if (!_isRecording)
                            ChatAttachmentButton(
                              onPressed: _handleAttachmentPressed,
                              size: 40,
                            ),

                          if (!_isRecording)
                            ChatEmojiButton(
                              onPressed: _handleEmojiPressed,
                              size: 40,
                            ),

                          // Text input or voice recorder
                          Expanded(
                            child: _isRecording
                                ? ChatVoiceRecorder(
                                    key: _recorderKey,
                                    onSend: _handleSend,
                                    onCancel: () => setState(() {
                                      _isRecording = false;
                                      _recordingInitiallyLocked = false;
                                    }),
                                    startLocked: _recordingInitiallyLocked,
                                  )
                                : ChatTextInputField(
                                    key: _inputFieldKey,
                                    controller: widget.textController,
                                    focusNode: widget.focusNode,
                                    onSend: _handleSend,
                                    onChanged: (_) => widget.onTyping(),
                                    hintText: 'Type a message',
                                  ),
                          ),

                          // Send/Voice button
                          ChatSendButton(
                            onPressed: _handleSend,
                            isRecording: _isRecording,
                            canSend: _isComposing,
                            showMic: !_isComposing,
                            onLongPress: () => setState(() {
                              _isRecording = true;
                              _recordingInitiallyLocked = false;
                            }),
                            onLongPressMoveUpdate: (details) {
                              _recorderKey.currentState?.updateDragPosition(
                                details.offsetFromOrigin.dx,
                                details.offsetFromOrigin.dy,
                              );
                            },
                            onLongPressEnd: (details) {
                              _recorderKey.currentState?.endDrag(0, 0);
                            },
                            size: 40,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Emoji picker
                  if (_showEmojiPicker)
                    SizedBox(
                      height: 250,
                      child: EmojiPicker(
                        onEmojiSelected: _onEmojiSelected,
                        config: Config(
                          height: 256,
                          checkPlatformCompatibility: true,
                          emojiViewConfig: EmojiViewConfig(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                            columns: 7,
                            emojiSizeMax:
                                32 *
                                (foundation.defaultTargetPlatform ==
                                        TargetPlatform.iOS
                                    ? 1.30
                                    : 1.0),
                          ),
                          categoryViewConfig: const CategoryViewConfig(
                            backgroundColor: Colors.transparent,
                          ),
                          bottomActionBarConfig: const BottomActionBarConfig(
                            enabled: false,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
