// ================================================================
// FILE: lib/features/competition/widgets/screen_specific/detail_widgets.dart
// Widgets for Competition Detail Screen (1v1 Comparison)
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../widgets/bar_progress_indicator.dart';
import '../../../../../widgets/circular_progress_indicator.dart';
import '../common/competition_helpers.dart';
import '../common/competition_models.dart';
import '../common/competition_shared_widgets.dart';

// ================================================================
// EPIC BATTLE HEADER
// ================================================================
class EpicBattleHeader extends StatefulWidget {
  final CompetitorData user;
  final CompetitorData competitor;
  final VoidCallback? onUserTap;
  final VoidCallback? onCompetitorTap;

  const EpicBattleHeader({
    super.key,
    required this.user,
    required this.competitor,
    this.onUserTap,
    this.onCompetitorTap,
  });

  @override
  State<EpicBattleHeader> createState() => _EpicBattleHeaderState();
}

class _EpicBattleHeaderState extends State<EpicBattleHeader>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _vsController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _vsScaleAnimation;
  late Animation<double> _vsRotateAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _vsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _vsScaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _vsController, curve: Curves.easeInOut));

    _vsRotateAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(parent: _vsController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _vsController.dispose();
    super.dispose();
  }

  bool get _isUserWinning =>
      widget.user.totalScore > widget.competitor.totalScore;
  bool get _isTied => widget.user.totalScore == widget.competitor.totalScore;
  int get _pointDifference =>
      (widget.user.totalScore - widget.competitor.totalScore).abs();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1A24),
                  const Color(0xFF2A2A3A),
                  const Color(0xFF1A1A24),
                ]
              : [Colors.white, const Color(0xFFF8F9FF), Colors.white],
        ),
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseController,
          _floatController,
          _vsController,
        ]),
        builder: (context, child) {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // User Avatar
                  _buildBattleAvatar(
                    competitor: widget.user,
                    isWinning: _isUserWinning && !_isTied,
                    isUser: true,
                    colors: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    isDark: isDark,
                    onTap: widget.onUserTap,
                  ),

                  // VS Badge
                  Transform.scale(
                    scale: _vsScaleAnimation.value,
                    child: Transform.rotate(
                      angle: _vsRotateAnimation.value,
                      child: _buildVsBadge(isDark),
                    ),
                  ),

                  // Competitor Avatar
                  _buildBattleAvatar(
                    competitor: widget.competitor,
                    isWinning: !_isUserWinning && !_isTied,
                    isUser: false,
                    colors: const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                    isDark: isDark,
                    onTap: widget.onCompetitorTap,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildStatusBanner(isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBattleAvatar({
    required CompetitorData competitor,
    required bool isWinning,
    required bool isUser,
    required List<Color> colors,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.translate(
        offset: Offset(
          0,
          isUser ? _floatAnimation.value : -_floatAnimation.value,
        ),
        child: Column(
          children: [
            // Crown for winner
            if (isWinning)
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBBF24).withOpacity(0.6),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              )
            else
              const SizedBox(height: 44),

            // Avatar
            Transform.scale(
              scale: isWinning ? _pulseAnimation.value : 1.0,
              child: GlowContainer(
                glowColor: colors.first,
                secondaryGlowColor: colors.last,
                blurRadius: 25,
                animate: isWinning,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF1A1A24) : Colors.white,
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withOpacity(0.05),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: competitor.avatarUrl != null
                          ? Image.network(
                              competitor.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildAvatarFallback(competitor.name, colors),
                            )
                          : _buildAvatarFallback(competitor.name, colors),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Name
            Text(
              isUser ? 'YOU' : competitor.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Score
            ShaderMask(
              shaderCallback: (bounds) =>
                  LinearGradient(colors: colors).createShader(bounds),
              child: Text(
                ScoreHelper.format(competitor.totalScore),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),

            Text(
              'pts',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String name, List<Color> colors) {
    return Container(
      color: colors.first.withOpacity(0.1),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: colors.first,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildVsBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2A2A3A), const Color(0xFF3A3A4A)]
              : [Colors.white, const Color(0xFFF0F0F5)],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(-5, 5),
          ),
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚔️', style: TextStyle(fontSize: 24)),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF3B82F6)],
            ).createShader(bounds),
            child: const Text(
              'VS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(bool isDark) {
    Color bgColor;
    List<Color> gradientColors;
    String text;
    IconData icon;

    if (_isTied) {
      bgColor = const Color(0xFFFBBF24).withOpacity(0.15);
      gradientColors = const [Color(0xFFFBBF24), Color(0xFFF59E0B)];
      text = "It's a Tie! 🤝";
      icon = Icons.handshake_rounded;
    } else if (_isUserWinning) {
      bgColor = const Color(0xFF10B981).withOpacity(0.15);
      gradientColors = const [Color(0xFF10B981), Color(0xFF34D399)];
      text = "You're Leading by $_pointDifference pts! 🏆";
      icon = Icons.arrow_upward_rounded;
    } else {
      bgColor = const Color(0xFFF97316).withOpacity(0.15);
      gradientColors = const [Color(0xFFF97316), Color(0xFFFBBF24)];
      text = "Behind by $_pointDifference pts 💪";
      icon = Icons.arrow_downward_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: gradientColors.first.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          ShaderMask(
            shaderCallback: (bounds) =>
                LinearGradient(colors: gradientColors).createShader(bounds),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// LIVE SCORE PROGRESS
// ================================================================
class LiveScoreProgress extends StatefulWidget {
  final int userScore;
  final int competitorScore;
  final String userName;
  final String competitorName;
  final bool showLiveIndicator;

  const LiveScoreProgress({
    super.key,
    required this.userScore,
    required this.competitorScore,
    required this.userName,
    required this.competitorName,
    this.showLiveIndicator = true,
  });

  @override
  State<LiveScoreProgress> createState() => _LiveScoreProgressState();
}

class _LiveScoreProgressState extends State<LiveScoreProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  double get _userShare {
    final total = widget.userScore + widget.competitorScore;
    if (total == 0) return 0.5;
    return widget.userScore / total;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.5,
      end: _userShare,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void didUpdateWidget(LiveScoreProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userScore != widget.userScore ||
        oldWidget.competitorScore != widget.competitorScore) {
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: _userShare,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          if (widget.showLiveIndicator)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LiveIndicator(),
                  const SizedBox(width: 12),
                  Text(
                    'Score Tracker',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              final userPercent = (_progressAnimation.value * 100).toInt();
              final compPercent = 100 - userPercent;

              return Column(
                children: [
                  // Percentage labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPercentageLabel('$userPercent%', const [
                        Color(0xFF8B5CF6),
                        Color(0xFFEC4899),
                      ]),
                      _buildPercentageLabel('$compPercent%', const [
                        Color(0xFF3B82F6),
                        Color(0xFF06B6D4),
                      ]),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Bar
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        // User progress
                        FractionallySizedBox(
                          widthFactor: _progressAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                              ),
                              borderRadius: BorderRadius.horizontal(
                                left: const Radius.circular(10),
                                right: Radius.circular(
                                  _progressAnimation.value > 0.95 ? 10 : 4,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF8B5CF6,
                                  ).withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Center divider
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment(
                              (_progressAnimation.value * 2) - 1,
                              0,
                            ),
                            child: Container(
                              width: 4,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white : Colors.black87,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Name labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.userName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            widget.competitorName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageLabel(String text, List<Color> colors) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          LinearGradient(colors: colors).createShader(bounds),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ================================================================
// CATEGORY TAB BAR
// ================================================================
class CategoryTabBar extends StatelessWidget {
  final ComparisonCategory selectedCategory;
  final Function(ComparisonCategory) onCategorySelected;

  const CategoryTabBar({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final List<MapEntry<ComparisonCategory, String>> _categories = const [
    MapEntry(ComparisonCategory.overall, '🏆 Overall'),
    MapEntry(ComparisonCategory.tasks, '✅ Tasks'),
    MapEntry(ComparisonCategory.goals, '🎯 Goals'),
    MapEntry(ComparisonCategory.buckets, '🪣 Buckets'),
    MapEntry(ComparisonCategory.diary, '📔 Diary'),
    MapEntry(ComparisonCategory.streaks, '🔥 Streaks'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final entry = _categories[index];
          final isSelected = selectedCategory == entry.key;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onCategorySelected(entry.key);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? ColorHelper.getGradientForCategory(entry.key.name)
                      : null,
                  color: isSelected
                      ? null
                      : (isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03)),
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: isDark
                              ? Colors.white12
                              : Colors.black.withOpacity(0.05),
                        ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ================================================================
// METRIC COMPARISON CARD
// ================================================================
class MetricComparisonCard extends StatefulWidget {
  final MetricComparison metric;
  final bool initiallyExpanded;

  const MetricComparisonCard({
    super.key,
    required this.metric,
    this.initiallyExpanded = false,
  });

  @override
  State<MetricComparisonCard> createState() => _MetricComparisonCardState();
}

class _MetricComparisonCardState extends State<MetricComparisonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    HapticFeedback.selectionClick();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metric = widget.metric;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: _toggleExpand,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: metric.isUserWinning
                                ? const [Color(0xFF10B981), Color(0xFF34D399)]
                                : const [Color(0xFFF97316), Color(0xFFFBBF24)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          metric.isUserWinning
                              ? Icons.check_rounded
                              : Icons.trending_up_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Title
                      Expanded(
                        child: Text(
                          metric.category,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),

                      // Win indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: metric.isUserWinning
                                ? const [Color(0xFF10B981), Color(0xFF34D399)]
                                : const [Color(0xFFF97316), Color(0xFFFBBF24)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          metric.isUserWinning ? 'Winning' : 'Behind',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Expand icon
                      RotationTransition(
                        turns: Tween<double>(
                          begin: 0,
                          end: 0.5,
                        ).animate(_expandAnimation),
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),

                // Quick comparison
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuickStat(
                          value: metric.userValue,
                          label: 'You',
                          color: metric.userColor,
                          isDark: isDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Text(
                          'vs',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black26,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildQuickStat(
                          value: metric.competitorValue,
                          label: 'Opponent',
                          color: metric.competitorColor,
                          isDark: isDark,
                          alignRight: true,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Expandable content
                ClipRect(
                  child: AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: _buildExpandedContent(isDark, metric),
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStat({
    required String value,
    required String label,
    required Color color,
    required bool isDark,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: alignRight
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!alignRight) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            if (alignRight) ...[
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [color, color.withOpacity(0.8)],
          ).createShader(bounds),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(bool isDark, MetricComparison metric) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 12),

          // Progress bars
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Your Progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomProgressIndicator(
                      progress: metric.userProgress / 100,
                      width: double.infinity,
                      baseHeight: 10,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      progressColor: metric.userColor,
                      borderRadius: 5,
                      progressBarName: '',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${metric.userProgress.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: metric.userColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Opponent Progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomProgressIndicator(
                      progress: metric.competitorProgress / 100,
                      width: double.infinity,
                      baseHeight: 10,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      progressColor: metric.competitorColor,
                      borderRadius: 5,
                      progressBarName: '',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${metric.competitorProgress.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: metric.competitorColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Battle progress bar
          _buildBattleProgressBar(metric, isDark),
        ],
      ),
    );
  }

  Widget _buildBattleProgressBar(MetricComparison metric, bool isDark) {
    final total = metric.userProgress + metric.competitorProgress;
    final userShare = total > 0 ? metric.userProgress / total : 0.5;

    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          // User progress
          FractionallySizedBox(
            widthFactor: userShare,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [metric.userColor, metric.userColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.horizontal(
                  left: const Radius.circular(10),
                  right: Radius.circular(userShare > 0.95 ? 10 : 4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// DUAL PROGRESS RING
// ================================================================
class DualProgressRing extends StatelessWidget {
  final double userProgress;
  final double competitorProgress;
  final String userLabel;
  final String competitorLabel;
  final List<Color> userColors;
  final List<Color> competitorColors;
  final double size;

  const DualProgressRing({
    super.key,
    required this.userProgress,
    required this.competitorProgress,
    required this.userLabel,
    required this.competitorLabel,
    this.userColors = const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    this.competitorColors = const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // User ring
        Column(
          children: [
            AdvancedProgressIndicator(
              progress: userProgress / 100,
              size: size,
              strokeWidth: 8,
              gradientColors: userColors,
              labelStyle: ProgressLabelStyle.percentage,
              labelTextStyle: TextStyle(
                fontSize: size * 0.15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              name: userLabel,
              namePosition: ProgressLabelPosition.bottom,
              nameTextStyle: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              animated: true,
              showGlow: true,
            ),
          ],
        ),

        // VS divider
        Column(
          children: [
            Container(
              width: 2,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    isDark ? Colors.white12 : Colors.black12,
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Text(
                'VS',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              width: 2,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark ? Colors.white12 : Colors.black12,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),

        // Competitor ring
        Column(
          children: [
            AdvancedProgressIndicator(
              progress: competitorProgress / 100,
              size: size,
              strokeWidth: 8,
              gradientColors: competitorColors,
              labelStyle: ProgressLabelStyle.percentage,
              labelTextStyle: TextStyle(
                fontSize: size * 0.15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              name: competitorLabel,
              namePosition: ProgressLabelPosition.bottom,
              nameTextStyle: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              animated: true,
              showGlow: true,
            ),
          ],
        ),
      ],
    );
  }
}

// ================================================================
// WINNER STATUS BADGE
// ================================================================
class WinnerStatusBadge extends StatelessWidget {
  final bool isUserWinning;
  final bool isTied;
  final int pointDifference;
  final double size;

  const WinnerStatusBadge({
    super.key,
    required this.isUserWinning,
    required this.isTied,
    required this.pointDifference,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    List<Color> colors;
    String emoji;
    String statusText;
    String subtitleText;

    if (isTied) {
      colors = const [Color(0xFFFBBF24), Color(0xFFF59E0B)];
      emoji = '🤝';
      statusText = "It's a Tie!";
      subtitleText = 'Keep pushing!';
    } else if (isUserWinning) {
      colors = const [Color(0xFF10B981), Color(0xFF34D399)];
      emoji = '🏆';
      statusText = "You're Winning!";
      subtitleText = '+$pointDifference pts ahead';
    } else {
      colors = const [Color(0xFFF97316), Color(0xFFFBBF24)];
      emoji = '💪';
      statusText = 'Keep Going!';
      subtitleText = '$pointDifference pts behind';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors.map((c) => c.withOpacity(0.15)).toList(),
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.first.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: Center(
              child: Text(emoji, style: TextStyle(fontSize: size * 0.45)),
            ),
          ),

          const SizedBox(height: 20),

          // Status text
          ShaderMask(
            shaderCallback: (bounds) =>
                LinearGradient(colors: colors).createShader(bounds),
            child: Text(
              statusText,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: colors.first.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subtitleText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.first,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// STREAK COMPARE ROW
// ================================================================
class StreakCompareRow extends StatelessWidget {
  final int userStreak;
  final int competitorStreak;
  final int userLongest;
  final int competitorLongest;

  const StreakCompareRow({
    super.key,
    required this.userStreak,
    required this.competitorStreak,
    required this.userLongest,
    required this.competitorLongest,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // User streak
        Expanded(
          child: _buildStreakCard(
            label: 'Your Streak',
            current: userStreak,
            longest: userLongest,
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 16),

        // VS divider
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'VS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),

        // Competitor streak
        Expanded(
          child: _buildStreakCard(
            label: 'Opponent',
            current: competitorStreak,
            longest: competitorLongest,
            color: const Color(0xFF3B82F6),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard({
    required String label,
    required int current,
    required int longest,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                StreakHelper.getStreakEmoji(current),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                current.toString(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Text(
                'd',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Longest: $longest days',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
