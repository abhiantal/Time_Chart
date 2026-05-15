// ================================================================
// FILE: lib/features/competition/common/competition_shared_widgets.dart
// Base shared widgets for competition screens
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


// ================================================================
// GRADIENT CARD
// ================================================================
class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color>? gradientColors;
  final Color? backgroundColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final bool showBorder;
  final bool showGlow;
  final double elevation;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.child,
    this.gradientColors,
    this.backgroundColor,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.showBorder = true,
    this.showGlow = false,
    this.elevation = 4,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = gradientColors ?? [
      isDark ? const Color(0xFF2A2A3A) : Colors.white,
      isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF8F9FF),
    ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap != null ? () {
        HapticFeedback.lightImpact();
        onTap!();
      } : null,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: backgroundColor ?? (isDark ? const Color(0xFF1E1E2E) : Colors.white),
          gradient: gradientColors != null
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          )
              : null,
          borderRadius: BorderRadius.circular(borderRadius),
          border: showBorder
              ? Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          )
              : null,
          boxShadow: [
            if (showGlow)
              BoxShadow(
                color: colors.first.withOpacity(isDark ? 0.3 : 0.2),
                blurRadius: elevation * 4,
                spreadRadius: 2,
              ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: elevation * 2,
              offset: Offset(0, elevation),
            ),
          ],
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

// ================================================================
// GLOW CONTAINER
// ================================================================
class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final Color? secondaryGlowColor;
  final double blurRadius;
  final bool animate;
  final bool enabled;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlowContainer({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFF8B5CF6),
    this.secondaryGlowColor,
    this.blurRadius = 20,
    this.animate = false,
    this.enabled = true,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return Padding(padding: margin ?? EdgeInsets.zero, child: child);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.3),
            blurRadius: blurRadius,
            spreadRadius: 2,
          ),
          if (secondaryGlowColor != null)
            BoxShadow(
              color: secondaryGlowColor!.withOpacity(0.2),
              blurRadius: blurRadius * 1.5,
              spreadRadius: 4,
            ),
        ],
      ),
      child: child,
    );
  }
}

// ================================================================
// SHIMMER TEXT
// ================================================================
class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final List<Color> colors;
  final Duration duration;
  final bool enabled;

  const ShimmerText({
    super.key,
    required this.text,
    this.style,
    this.colors = const [
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF3B82F6),
    ],
    this.duration = const Duration(milliseconds: 2000),
    this.enabled = true,
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    if (widget.enabled) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Text(widget.text, style: widget.style);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: widget.colors,
              stops: List.generate(widget.colors.length, (i) {
                if (widget.colors.length == 1) return 0.5;
                final double interval = 0.4 / (widget.colors.length - 1);
                return (_controller.value - 0.2 + (i * interval)).clamp(0.0, 1.0);
              }),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: (widget.style ?? const TextStyle()).copyWith(
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

// ================================================================
// PULSE AVATAR
// ================================================================
class PulseAvatar extends StatefulWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final List<Color> borderGradient;
  final bool showPulse;
  final int? rank;
  final VoidCallback? onTap;
  final bool showRank;

  const PulseAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 60,
    this.borderGradient = const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    this.showPulse = true,
    this.rank,
    this.onTap,
    this.showRank = false,
  });

  @override
  State<PulseAvatar> createState() => _PulseAvatarState();
}

class _PulseAvatarState extends State<PulseAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.showPulse) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap != null ? () {
        HapticFeedback.lightImpact();
        widget.onTap!();
      } : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.showPulse ? _pulseAnimation.value : 1,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: widget.borderGradient),
                    boxShadow: [
                      BoxShadow(
                        color: widget.borderGradient.first.withOpacity(0.4),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                    ),
                    child: ClipOval(child: _buildAvatarContent()),
                  ),
                ),
              );
            },
          ),
          if (widget.showRank && widget.rank != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: _getRankGradient(widget.rank!),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  _getRankEmoji(widget.rank!),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return Image.network(
        widget.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    final initial = widget.name?.isNotEmpty == true
        ? widget.name![0].toUpperCase()
        : '?';

    return Container(
      color: widget.borderGradient.first.withOpacity(0.1),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: widget.borderGradient.first,
            fontSize: widget.size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  LinearGradient _getRankGradient(int rank) {
    switch (rank) {
      case 1:
        return const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]);
      case 2:
        return const LinearGradient(colors: [Color(0xFF94A3B8), Color(0xFFE2E8F0)]);
      case 3:
        return const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFFDDA15E)]);
      default:
        return const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)]);
    }
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }
}

// ================================================================
// LIVE INDICATOR
// ================================================================
class LiveIndicator extends StatefulWidget {
  final String text;
  final Color color;

  const LiveIndicator({
    super.key,
    this.text = 'LIVE',
    this.color = const Color(0xFFEF4444),
  });

  @override
  State<LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<LiveIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.1 + _controller.value * 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.8),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.text,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ================================================================
// RANK BADGE
// ================================================================
class RankBadge extends StatelessWidget {
  final int rank;
  final double size;

  const RankBadge({super.key, required this.rank, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final colors = _getRankColors();
    final emoji = _getRankEmoji();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: rank <= 3
            ? Text(emoji, style: TextStyle(fontSize: size * 0.5))
            : Text(
          '#$rank',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  List<Color> _getRankColors() {
    switch (rank) {
      case 1:
        return const [Color(0xFFFBBF24), Color(0xFFF59E0B)];
      case 2:
        return const [Color(0xFF94A3B8), Color(0xFFE2E8F0)];
      case 3:
        return const [Color(0xFFCD7F32), Color(0xFFDDA15E)];
      default:
        return const [Color(0xFF3B82F6), Color(0xFF06B6D4)];
    }
  }

  String _getRankEmoji() {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }
}

// ================================================================
// COMPETITION BADGE
// ================================================================
class CompetitionBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final List<Color> gradientColors;
  final double fontSize;
  final Color? textColor;
  final bool showIcon;

  const CompetitionBadge({
    super.key,
    required this.text,
    this.icon,
    this.gradientColors = const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    this.fontSize = 11,
    this.textColor,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon && icon != null) ...[
            Icon(icon, size: fontSize + 2, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ANIMATED COUNTER
// ================================================================
class AnimatedCounter extends StatefulWidget {
  final int value;
  final Duration duration;
  final Curve curve;
  final TextStyle? style;
  final String Function(int value)? format;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1500),
    this.curve = Curves.easeOutCubic,
    this.style,
    this.format,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _displayValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _controller.addListener(_updateValue);
    _controller.forward();
  }

  void _updateValue() {
    setState(() {
      _displayValue = (widget.value * _animation.value).round();
    });
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateValue);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatted = widget.format?.call(_displayValue) ?? _displayValue.toString();
    return Text(formatted, style: widget.style);
  }
}

// ================================================================
// SCORE FORMATTER HELPER
// ================================================================
class ScoreFormatter {
  static String format(int score) {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    }
    if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toString();
  }

  static String formatWithSuffix(int score) {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M pts';
    }
    if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K pts';
    }
    return '$score pts';
  }
}

// ================================================================
// DATE FORMATTER HELPER
// ================================================================
class DateFormatter {
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  static String formatShort(DateTime date) {
    return '${date.day}/${date.month}';
  }
}

// ================================================================
// EMPTY STATE WIDGET
// ================================================================
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ================================================================
// LOADING SHIMMER
// ================================================================
class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Shimmer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}

// Simple shimmer widget
class Shimmer extends StatefulWidget {
  final Widget child;

  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

// ================================================================
// SECTION HEADER
// ================================================================
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Color>? gradientColors;
  final Widget? trailing;
  final VoidCallback? onTrailingTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.gradientColors,
    this.trailing,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = gradientColors ?? const [Color(0xFF8B5CF6), Color(0xFFEC4899)];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: subtitle != null ? 32 : 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: colors.first),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            GestureDetector(
              onTap: onTrailingTap != null ? () {
                HapticFeedback.lightImpact();
                onTrailingTap!();
              } : null,
              child: trailing,
            ),
        ],
      ),
    );
  }
}