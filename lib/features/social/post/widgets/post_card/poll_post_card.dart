import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../providers/post_provider.dart';
import '../base_post_card.dart';
import '../helper/post_content.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:the_time_chart/widgets/logger.dart';

class PollPostCard extends StatefulWidget {
  final FeedPost post;
  final String currentUserId;
  final bool isInDetailView;
  final VoidCallback? onTap;
  final VoidCallback? onCommentPressed;
  final VoidCallback? onMenuPressed;

  const PollPostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    this.isInDetailView = false,
    this.onTap,
    this.onCommentPressed,
    this.onMenuPressed,
  });

  @override
  State<PollPostCard> createState() => _PollPostCardState();
}

class _PollPostCardState extends State<PollPostCard>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  String? _selectedOptionId;
  bool _isVoting = false;

  late AnimationController _entranceController;
  late AnimationController _resultController;
  late AnimationController _pulseController;
  late Animation<double> _entranceAnim;
  late Animation<double> _pulseAnim;

  // ── Vibrant gradient palette ──
  static const List<List<Color>> _optionGradients = [
    [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Indigo → Purple
    [Color(0xFFEF4444), Color(0xFFF97316)], // Red → Orange
    [Color(0xFF10B981), Color(0xFF06B6D4)], // Emerald → Cyan
    [Color(0xFFF59E0B), Color(0xFFEAB308)], // Amber → Yellow
    [Color(0xFFEC4899), Color(0xFFD946EF)], // Pink → Fuchsia
    [Color(0xFF3B82F6), Color(0xFF0EA5E9)], // Blue → Sky
    [Color(0xFF14B8A6), Color(0xFF10B981)], // Teal → Emerald
    [Color(0xFFF97316), Color(0xFFEF4444)], // Orange → Red
  ];

  // ── Convenience getters ──
  PollData? get _pollData => widget.post.post.pollData;

  bool get _hasVoted => _pollData?.hasUserVoted(widget.currentUserId) ?? false;

  bool get _isEnded => _pollData?.isEnded ?? false;

  bool get _showResults => _hasVoted || _isEnded;

  List<Color> _gradient(int i) => _optionGradients[i % _optionGradients.length];

  // ── Lifecycle ──
  @override
  void initState() {
    super.initState();
    _selectedOptionId = _pollData?.getUserVote(widget.currentUserId);

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _entranceAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    _resultController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (_showResults) {
      _resultController.value = 1.0;
    }

    _entranceController.forward();
    if (!_showResults) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PollPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasVoted =
        oldWidget.post.post.pollData?.hasUserVoted(widget.currentUserId) ??
        false;
    if (!wasVoted && _hasVoted) {
      _selectedOptionId = _pollData?.getUserVote(widget.currentUserId);
      _triggerResultReveal();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _resultController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Actions ──
  void _triggerResultReveal() {
    if (_resultController.status != AnimationStatus.forward &&
        _resultController.status != AnimationStatus.completed) {
      _resultController.forward();
      _pulseController.stop();
    }
  }

  Future<void> _vote() async {
    if (_selectedOptionId == null || _isVoting) return;
    setState(() => _isVoting = true);
    HapticFeedback.mediumImpact();

    try {
      final provider = context.read<PostProvider>();
      await provider.votePoll(
        postId: widget.post.post.id,
        optionId: _selectedOptionId!,
      );
      if (mounted) {
        setState(() => _isVoting = false);
        _triggerResultReveal();
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVoting = false);
        AppSnackbar.error('Failed to submit vote');
        logE('Poll vote error: $e');
      }
    }
  }

  // ── Helpers ──
  String _formatTimeRemaining(DateTime endTime) {
    final diff = endTime.difference(DateTime.now());
    if (diff.isNegative) return 'Ended';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m left';
    return 'Ending soon';
  }

  String? _findWinnerId() {
    if (_pollData == null || _pollData!.totalVotes == 0) return null;
    PollOption? winner;
    for (final o in _pollData!.options) {
      if (winner == null || o.votes > winner.votes) winner = o;
    }
    return winner?.id;
  }

  // ═══════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return BasePostCard(
      post: widget.post,
      currentUserId: widget.currentUserId,
      onTap: widget.onTap,
      onCommentPressed: widget.onCommentPressed,
      onMenuPressed: widget.onMenuPressed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.post.post.caption?.isNotEmpty == true &&
              widget.post.post.caption != _pollData?.question)
            PostContent(
              text: widget.post.post.caption!,
              hashtags: widget.post.post.hashtags,
              mentions: widget.post.post.mentionedUsernames,
              isExpanded: _isExpanded,
              onExpandToggle: () => setState(() => _isExpanded = !_isExpanded),
              maxLines: widget.isInDetailView ? null : 3,
            ),
          if (widget.post.post.postType == PostType.poll && _pollData != null)
            _buildPollSection(context),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // POLL SECTION
  // ═══════════════════════════════════════════
  Widget _buildPollSection(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FadeTransition(
      opacity: _entranceAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(_entranceAnim),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.surfaceContainerHighest.withOpacity(0.35),
                cs.surfaceContainerHighest.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.35),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, cs),
              _buildQuestion(theme, cs),
              const SizedBox(height: 4),
              _buildOptionsList(theme, cs),
              _buildFooter(theme, cs),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(ThemeData theme, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          if (_isEnded)
            _statusChip(
              theme,
              'Ended',
              Icons.timer_off_rounded,
              cs.error,
              cs.errorContainer,
            )
          else if (_hasVoted)
            _statusChip(
              theme,
              'Voted',
              Icons.check_circle_rounded,
              cs.primary,
              cs.primaryContainer,
            ),
        ],
      ),
    );
  }

  Widget _statusChip(
    ThemeData theme,
    String text,
    IconData icon,
    Color accent,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ── Question ──
  Widget _buildQuestion(ThemeData theme, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Text(
        _pollData!.question,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // OPTIONS LIST
  // ═══════════════════════════════════════════
  Widget _buildOptionsList(ThemeData theme, ColorScheme cs) {
    final options = _pollData!.options;
    final winnerId = _showResults ? _findWinnerId() : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Column(
        children: List.generate(options.length, (i) {
          final option = options[i];
          final grad = _gradient(i);
          final selected = option.id == _selectedOptionId;
          final winner = option.id == winnerId && _showResults;

          // Stagger entrance
          final delay = i * 0.1;
          final interval = Interval(
            delay.clamp(0.0, 0.6),
            (0.5 + delay).clamp(0.0, 1.0),
            curve: Curves.easeOutBack,
          );

          return AnimatedBuilder(
            animation: _entranceController,
            builder: (context, child) {
              final v = interval.transform(_entranceController.value);
              return Transform.translate(
                offset: Offset(0, 24 * (1 - v)),
                child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
              );
            },
            child: _showResults
                ? _resultOption(theme, cs, option, i, grad, selected, winner)
                : _selectableOption(theme, cs, option, i, grad, selected),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SELECTABLE OPTION (before voting)
  // ═══════════════════════════════════════════
  Widget _selectableOption(
    ThemeData theme,
    ColorScheme cs,
    PollOption option,
    int index,
    List<Color> grad,
    bool selected,
  ) {
    final accent = grad[0];
    final canTap = !_isEnded && !_hasVoted && !_isVoting;

    return GestureDetector(
      onTap: canTap
          ? () {
              HapticFeedback.selectionClick();
              setState(() => _selectedOptionId = option.id);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.08) : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? accent.withOpacity(0.6)
                : cs.outlineVariant.withOpacity(0.35),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // ── Gradient color strip ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: 4,
              height: 30,
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: grad,
                      )
                    : null,
                color: selected ? null : cs.outlineVariant.withOpacity(0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),

            // ── Radio indicator ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? accent : cs.outline.withOpacity(0.4),
                  width: selected ? 2 : 1.5,
                ),
                color: selected ? accent.withOpacity(0.08) : Colors.transparent,
              ),
              child: selected
                  ? Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.elasticOut,
                        builder: (_, v, __) => Transform.scale(
                          scale: v,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: grad),
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // ── Text ──
            Expanded(
              child: Text(
                option.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? cs.onSurface : cs.onSurfaceVariant,
                ),
              ),
            ),

            // ── Index badge ──
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selected ? LinearGradient(colors: grad) : null,
                color: selected ? null : cs.surfaceContainerHighest,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C…
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selected ? Colors.white : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // RESULT OPTION (after voting / ended)
  // ═══════════════════════════════════════════
  Widget _resultOption(
    ThemeData theme,
    ColorScheme cs,
    PollOption option,
    int index,
    List<Color> grad,
    bool selected,
    bool winner,
  ) {
    final pct = _pollData!.getOptionPercent(option.id);
    final votes = option.votes;
    final accent = grad[0];

    // Stagger result bars
    final delay = index * 0.08;
    final barInterval = Interval(
      delay.clamp(0.0, 0.4),
      (0.55 + delay).clamp(0.0, 1.0),
      curve: Curves.easeOutCubic,
    );

    return AnimatedBuilder(
      animation: _resultController,
      builder: (context, _) {
        final barValue = barInterval.transform(_resultController.value);
        final animPct = pct * barValue;
        final animVotes = (votes * barValue).round();

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? accent.withOpacity(0.5)
                  : cs.outlineVariant.withOpacity(0.25),
              width: selected ? 1.5 : 0.8,
            ),
            boxShadow: winner
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                // ── Transparent background ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  color: cs.surface,
                  child: const SizedBox(height: 26),
                ),

                // ── Animated gradient fill ──
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: (animPct / 100).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              grad[0].withOpacity(selected ? 0.22 : 0.1),
                              grad[1].withOpacity(selected ? 0.14 : 0.05),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Shimmer edge on progress bar ──
                if (barValue > 0 && barValue < 1)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (animPct / 100).clamp(0.0, 1.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  grad[0].withOpacity(0.5),
                                  grad[1].withOpacity(0.5),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Content overlay ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      // Color dot
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: grad),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Option text
                      Expanded(
                        child: Text(
                          option.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Winner crown
                      if (winner && _pollData!.totalVotes > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.elasticOut,
                            builder: (_, v, child) =>
                                Transform.scale(scale: v, child: child),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              size: 18,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ),

                      // User vote check
                      if (selected)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 17,
                            color: accent,
                          ),
                        ),

                      // Vote count pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$animVotes',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Percentage badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: (selected || winner)
                              ? LinearGradient(colors: grad)
                              : null,
                          color: (selected || winner)
                              ? null
                              : cs.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: (selected || winner)
                              ? [
                                  BoxShadow(
                                    color: accent.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          '${animPct.toStringAsFixed(0)}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: (selected || winner)
                                ? Colors.white
                                : cs.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════
  Widget _buildFooter(ThemeData theme, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Column(
        children: [
          // ── Participation bar ──
          if (_showResults && _pollData!.totalVotes > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildParticipationBar(theme, cs),
            ),

          Row(
            children: [
              // Total votes
              _footerStat(
                theme,
                cs,
                Icons.people_alt_rounded,
                '${_pollData!.totalVotes} votes',
              ),

              if (_pollData!.endsAt != null && !_isEnded) ...[
                const SizedBox(width: 14),
                _footerStat(
                  theme,
                  cs,
                  Icons.schedule_rounded,
                  _formatTimeRemaining(_pollData!.endsAt!),
                ),
              ],

              if (_pollData!.totalVotes == 0 && !_showResults) ...[
                const SizedBox(width: 14),
                Text(
                  'Be the first to vote!',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const Spacer(),

              if (!_showResults) _buildVoteButton(theme, cs),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerStat(
    ThemeData theme,
    ColorScheme cs,
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant.withOpacity(0.55)),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant.withOpacity(0.65),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Participation color bar ──
  Widget _buildParticipationBar(ThemeData theme, ColorScheme cs) {
    final options = _pollData!.options;
    final total = _pollData!.totalVotes;
    if (total == 0) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _resultController,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            width: double.infinity,
            child: Row(
              children: List.generate(options.length, (i) {
                final frac = options[i].votes / total;
                final grad = _gradient(i);
                final delay = i * 0.08;
                final interval = Interval(
                  delay.clamp(0.0, 0.4),
                  (0.6 + delay).clamp(0.0, 1.0),
                  curve: Curves.easeOut,
                );
                final v = interval.transform(_resultController.value);

                return Expanded(
                  flex: (frac * 1000 * v).round().clamp(1, 1000),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: grad),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  // ── Vote button ──
  Widget _buildVoteButton(ThemeData theme, ColorScheme cs) {
    final enabled = _selectedOptionId != null && !_isVoting;
    final selIdx = _selectedOptionId != null
        ? _pollData!.options.indexWhere((o) => o.id == _selectedOptionId)
        : -1;
    final grad = selIdx >= 0 ? _gradient(selIdx) : [cs.primary, cs.primary];

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: enabled ? _pulseAnim.value : 1.0,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: enabled ? _vote : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
          decoration: BoxDecoration(
            gradient: enabled ? LinearGradient(colors: grad) : null,
            color: enabled ? null : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: grad[0].withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: _isVoting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.how_to_vote_rounded,
                      size: 16,
                      color: enabled
                          ? Colors.white
                          : cs.onSurfaceVariant.withOpacity(0.4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Vote',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: enabled
                            ? Colors.white
                            : cs.onSurfaceVariant.withOpacity(0.4),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
