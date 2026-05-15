import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/chat_message_provider.dart';
import 'package:the_time_chart/features/chats/model/chat_message_model.dart';
import 'message_bubble_base.dart';
import '../components/message_reply_preview.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import '../../../utils/chat_text_utils.dart';

class ChatPollBubble extends StatefulWidget {
  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final String? senderName;
  final String? senderAvatar;
  final bool showName;
  final bool showAvatar;

  const ChatPollBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onLongPress,
    this.onDoubleTap,
    this.senderName,
    this.senderAvatar,
    this.showName = false,
    this.showAvatar = false,
  });

  @override
  State<ChatPollBubble> createState() => _ChatPollBubbleState();
}

class _ChatPollBubbleState extends State<ChatPollBubble> {
  // Local state to handle immediate feedback before server update
  String? _selectedOptionId;
  bool _isVoting = false;

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.message.sharedContentSnapshot ?? {};
    final question = snapshot['question'] ?? 'Poll';
    final List<Map<String, dynamic>> options = [];
    final rawOptions = snapshot['options'] as List?;
    if (rawOptions != null) {
      for (var i = 0; i < rawOptions.length; i++) {
        final opt = rawOptions[i];
        if (opt is Map) {
          options.add(Map<String, dynamic>.from(opt));
        } else if (opt is String) {
          // Fallback for legacy string-only options
          options.add({
            'id': 'legacy_$i',
            'text': opt,
            'votes': 0,
          });
        }
      }
    }
    final endsAtStr = snapshot['ends_at'] as String?;
    final allowMultiple = snapshot['allow_multiple'] ?? false;
    final totalVotes = snapshot['total_votes'] ?? 0;

    // Check if ended
    DateTime? endsAt;
    bool isEnded = false;
    if (endsAtStr != null) {
      endsAt = DateTime.tryParse(endsAtStr);
      if (endsAt != null && DateTime.now().isAfter(endsAt)) {
        isEnded = true;
      }
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return MessageBubbleBase(
      message: widget.message,
      isMe: widget.isMe,
      onLongPress: widget.onLongPress,
      onDoubleTap: widget.onDoubleTap,
      showName: widget.showName,
      showAvatar: widget.showAvatar,
      senderName: widget.senderName,
      senderAvatar: widget.senderAvatar,
      padding: EdgeInsets.zero,
      sentColor: Colors.transparent,
      receivedColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isMe
                ? [
                    const Color(0xFF00A884).withValues(alpha: 0.9),
                    const Color(0xFF008E6E).withValues(alpha: 0.7),
                  ]
                : [
                    isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                    isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reply preview
              if (widget.message.replyToId != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: MessageReplyPreview(
                    replyToId: widget.message.replyToId!,
                    isMe: widget.isMe,
                  ),
                ),

              // Header Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.poll_rounded,
                      size: 18,
                      color: widget.isMe ? Colors.white : colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ACTIVE POLL',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: widget.isMe ? Colors.white : colorScheme.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    if (isEnded)
                      _buildStatusBadge('Ended', Colors.redAccent)
                    else if (endsAt != null)
                      Text(
                        _timeLeft(endsAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: (widget.isMe ? Colors.white : colorScheme.onSurface).withValues(alpha: 0.7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),

              // Question
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  ChatTextUtils.cleanMentions(question),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    color: widget.isMe ? Colors.white : colorScheme.onSurface,
                    fontSize: 17,
                  ),
                ),
              ),


              // Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: options.map<Widget>((opt) {
                    final optId = opt['id'];
                    final text = opt['text'];

                    int votes = opt['votes'] ?? 0;
                    int displayTotalVotes = totalVotes;
                    if (_isVoting && _selectedOptionId == optId) {
                      votes += 1;
                      displayTotalVotes += 1;
                    }

                    final percentage = displayTotalVotes > 0 ? (votes / displayTotalVotes) : 0.0;
                    final isSelected = _selectedOptionId == optId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: isEnded ? null : () => _vote(optId),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 54,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? (widget.isMe ? Colors.white : colorScheme.primary)
                                  : Colors.white.withValues(alpha: 0.08),
                              width: 1.5,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Progress Bar
                              if (displayTotalVotes > 0)
                                AnimatedFractionallySizedBox(
                                  duration: const Duration(milliseconds: 500),
                                  widthFactor: percentage,
                                  curve: Curves.easeOutCubic,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: (widget.isMe ? Colors.white : colorScheme.primary)
                                          .withValues(alpha: isSelected ? 0.2 : 0.1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ChatTextUtils.cleanMentions(text),
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: widget.isMe ? Colors.white : colorScheme.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (displayTotalVotes > 0)
                                      Text(
                                        '${(percentage * 100).toInt()}%',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: (widget.isMe ? Colors.white : colorScheme.primary)
                                              .withValues(alpha: 0.9),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 14,
                      color: (widget.isMe ? Colors.white : colorScheme.onSurface).withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_isVoting ? totalVotes + 1 : totalVotes} votes total',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: (widget.isMe ? Colors.white : colorScheme.onSurface).withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (allowMultiple) ...[
                      const Spacer(),
                      _buildStatusBadge('Multiple Choice', colorScheme.secondary),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _timeLeft(DateTime endsAt) {
    final diff = endsAt.difference(DateTime.now());
    if (diff.isNegative) return 'Ended';
    if (diff.inHours > 24) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    return '${diff.inMinutes}m left';
  }

  void _vote(String optionId) async {
    if (_isVoting) return;

    setState(() {
      _selectedOptionId = optionId;
      _isVoting = true;
    });

    try {
      final provider = context.read<ChatMessageProvider>();
      await provider.voteInPoll(
        messageId: widget.message.id,
        optionId: optionId,
      );
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          'Failed to vote',
          description: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVoting = false;
        });
      }
    }
  }
}
