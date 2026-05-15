import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:the_time_chart/features/chats/widgets/common/user_avatar_cached.dart';
import 'package:the_time_chart/widgets/circular_progress_indicator.dart';
import '../../../features/social/post/models/post_model.dart';

class ExpandableCustomPostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onTap;

  const ExpandableCustomPostCard({super.key, required this.post, this.onTap});

  @override
  State<ExpandableCustomPostCard> createState() =>
      _ExpandableCustomPostCardState();
}

class _ExpandableCustomPostCardState extends State<ExpandableCustomPostCard> {
  bool _isExpanded = false;
  bool _isPressed = false;

  void _toggleExpanded() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  // Get a premium gradient based on the content type
  List<Color> _getGradient(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final type = widget.post.contentType.toLowerCase();

    if (type == 'text') {
      return isDarkMode
          ? [const Color(0xFF0D47A1), const Color(0xFF1565C0)]
          : [const Color(0xFF1E88E5), const Color(0xFF64B5F6)];
    }
    if (type == 'poll') {
      return isDarkMode
          ? [const Color(0xFFE65100), const Color(0xFFEF6C00)]
          : [const Color(0xFFFB8C00), const Color(0xFFFFCC80)];
    }
    if (type == 'quote' || type == 'custom') {
      return isDarkMode
          ? [const Color(0xFF311B92), const Color(0xFF4527A0)]
          : [const Color(0xFF5E35B1), const Color(0xFF9575CD)];
    }

    return isDarkMode
        ? [const Color(0xFF263238), const Color(0xFF37474F)]
        : [const Color(0xFF607D8B), const Color(0xFFB0BEC5)];
  }

  String _getTitle() {
    final text = widget.post.content.text;
    if (text.isNotEmpty) {
      final lines = text.split('\n');
      final firstLine = lines.first.trim();
      if (firstLine.isNotEmpty) {
        return firstLine.length > 50
            ? '${firstLine.substring(0, 50)}...'
            : firstLine;
      }
    }
    return '${widget.post.contentType.toUpperCase()} Post';
  }

  String? _getDescription() {
    final text = widget.post.content.text;
    if (text.isEmpty) return null;

    final lines = text.split('\n');
    if (lines.length <= 1) return null;

    // Skip the first line as it's the title
    return lines.skip(1).join('\n').trim();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap?.call();

    context.pushNamed(
      'userPostFeed',
      extra: {
        'userId': widget.post.userId,
        'initialIndex': 0,
        'preloadedPosts': [widget.post],
        'title': _getTitle(),
        'isLive': widget.post.isLive,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradientColors = _getGradient(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _handleTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _isPressed ? 0.98 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Material(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopSection(context, theme, gradientColors),
                  if (_isExpanded) _buildExpandedSection(context, theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(
    BuildContext context,
    ThemeData theme,
    List<Color> gradientColors,
  ) {
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // New Header Row
          Row(
            children: [
              UserAvatarCached(
                imageUrl: widget.post.profileUrl,
                name: widget.post.displayName ?? widget.post.username ?? 'User',
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post.displayName ?? widget.post.username ?? 'User',
                      style: textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '@${widget.post.username ?? 'anonymous'}',
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.post.contentType.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _getTitle(),
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -0.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (_getDescription() != null) ...[
            const SizedBox(height: 12),
            Text(
              _getDescription()!,
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 15,
                height: 1.6,
              ),
              maxLines: _isExpanded ? 15 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              _buildInteractionSummary(),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_toggle_off_rounded,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(widget.post.createdAt),
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _toggleExpanded,
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 300),
                  turns: _isExpanded ? 0.5 : 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionSummary() {
    return Row(
      children: [
        _buildMiniStat(Icons.favorite_rounded, widget.post.likesCount),
        const SizedBox(width: 16),
        _buildMiniStat(Icons.insights_rounded, widget.post.metrics.views),
      ],
    );
  }

  Widget _buildMiniStat(IconData icon, int value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 6),
        Text(
          _formatNumber(value),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedSection(BuildContext context, ThemeData theme) {
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'PERFORMANCE METRICS',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _buildMetric(
                context,
                'Reach',
                widget.post.metrics.views,
                Colors.blue,
              ),
              _buildMetric(
                context,
                'Impact',
                widget.post.metrics.impressions,
                Colors.purple,
              ),
              _buildMetric(
                context,
                'Appreciation',
                widget.post.metrics.likesCount,
                Colors.red,
              ),
              _buildMetric(
                context,
                'Feedback',
                widget.post.metrics.commentsCount,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
    BuildContext context,
    String label,
    int value,
    Color color,
  ) {
    final formattedValue = _formatNumber(value);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AdvancedProgressIndicator(
          progress: value > 0 ? 1.0 : 0.0,
          size: 64,
          strokeWidth: 5,
          shape: ProgressShape.circular,
          gradientColors: [color.withValues(alpha: 0.4), color],
          backgroundColor: color.withValues(alpha: 0.05),
          labelStyle: ProgressLabelStyle.custom,
          customLabel: formattedValue,
          labelTextStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          animated: true,
        ),
        const SizedBox(height: 12),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 7) return DateFormat('MMM dd').format(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
