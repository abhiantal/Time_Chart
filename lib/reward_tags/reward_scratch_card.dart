// lib/reward_tags/reward_scratch_card.dart
//
// PremiumRewardBox  — compact tappable reward box (thumbnail)
// PremiumScratchCardPopup — full-screen scratch & reveal experience
//
// Key improvements:
//  • Scratch completes at ~35% coverage (feels fast, not frustrating)
//  • "Reveal instantly" button after 10% scratch
//  • Richer reveal: confetti, floating particles, shine sweep, tier burst
//  • rewardColor is always driven by the hex code from RewardPackage
//  • Full legacy JSON support (old tier / color names)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'reward_manager.dart';
import 'animated_reward_emoji.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM REWARD BOX  (compact thumbnail)
// ─────────────────────────────────────────────────────────────────────────────

class PremiumRewardBox extends StatefulWidget {
  final String taskId;
  final String taskType;
  final String taskTitle;
  final RewardPackage rewardPackage;
  final VoidCallback? onRewardClaimed;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;

  const PremiumRewardBox({
    super.key,
    required this.taskId,
    required this.taskType,
    required this.taskTitle,
    required this.rewardPackage,
    this.onRewardClaimed,
    this.width = 90,
    this.height = 90,
    this.borderRadius,
    this.margin,
  });

  @override
  State<PremiumRewardBox> createState() => _PremiumRewardBoxState();
}

class _PremiumRewardBoxState extends State<PremiumRewardBox>
    with TickerProviderStateMixin {
  bool _isScratched = false;

  late final AnimationController _float;
  late final AnimationController _shimmer;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _checkScratchState();

    _float = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    )..repeat(reverse: true);

    _shimmer = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();

    _pulse = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> _checkScratchState() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'scratched_${widget.taskId}_${widget.taskType}';
    if (mounted) setState(() => _isScratched = prefs.getBool(key) ?? false);
  }

  Color get _primary => widget.rewardPackage.primaryColor;

  void _open() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (ctx, anim, _) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(
              begin: 0.85,
              end: 1.0,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
            child: PremiumScratchCardPopup(
              taskId: widget.taskId,
              taskType: widget.taskType,
              taskTitle: widget.taskTitle,
              rewardPackage: widget.rewardPackage,
              wasAlreadyScratched: _isScratched,
              onRewardClaimed: () {
                widget.onRewardClaimed?.call();
                _checkScratchState();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(22);

    return AnimatedBuilder(
      animation: Listenable.merge([_float, _shimmer, _pulse]),
      builder: (ctx, _) {
        final floatY = math.sin(_float.value * math.pi) * 4;
        final pulseScale = _isScratched
            ? 1.0
            : 1.0 + math.sin(_pulse.value * math.pi) * 0.028;

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Transform.scale(
            scale: pulseScale,
            child: GestureDetector(
              onTap: widget.rewardPackage.earned ? _open : null,
              child: Container(
                width: widget.width,
                height: widget.height,
                margin: widget.margin,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(_isScratched ? 0.35 : 0.55),
                      blurRadius: _isScratched ? 18 : 28,
                      spreadRadius: _isScratched ? 2 : 4,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Stack(
                    children: [
                      _bg(),
                      if (!_isScratched && widget.rewardPackage.earned)
                        _shimmerLayer(),
                      _content(),
                      _border(radius),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bg() {
    if (_isScratched) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primary.withOpacity(0.22),
              Colors.black.withOpacity(0.82),
            ],
          ),
        ),
      );
    }
    if (!widget.rewardPackage.earned) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF374151), Color(0xFF111827)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary.withOpacity(0.9), _primary.withOpacity(0.5)],
        ),
      ),
    );
  }

  Widget _shimmerLayer() => Positioned.fill(
    child: CustomPaint(
      painter: _ShimmerPainter(progress: _shimmer.value, color: Colors.white),
    ),
  );

  Widget _content() {
    final w = widget.width;
    final h = widget.height;

    if (!widget.rewardPackage.earned) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: Colors.white.withOpacity(0.4),
              size: w * 0.34,
            ),
            const SizedBox(height: 4),
            Text(
              'Locked',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_isScratched) {
      return Center(
        child: SizedBox(
          width: w * 0.68,
          height: h * 0.68,
          child: FittedBox(
            fit: BoxFit.contain,
            child: AnimatedRewardEmoji(
              tier: widget.rewardPackage.tier,
              size: w * 0.62,
            ),
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.card_giftcard_rounded,
            color: Colors.white,
            size: w * 0.38,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'TAP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _border(BorderRadius radius) => Positioned.fill(
    child: Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: _isScratched
              ? _primary.withOpacity(0.55)
              : Colors.white.withOpacity(0.28),
          width: 1.8,
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _float.dispose();
    _shimmer.dispose();
    _pulse.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM SCRATCH CARD POPUP
// ─────────────────────────────────────────────────────────────────────────────

class PremiumScratchCardPopup extends StatefulWidget {
  final String taskId;
  final String taskType;
  final String taskTitle;
  final RewardPackage rewardPackage;
  final bool wasAlreadyScratched;
  final VoidCallback? onRewardClaimed;

  const PremiumScratchCardPopup({
    super.key,
    required this.taskId,
    required this.taskType,
    required this.taskTitle,
    required this.rewardPackage,
    this.wasAlreadyScratched = false,
    this.onRewardClaimed,
  });

  @override
  State<PremiumScratchCardPopup> createState() =>
      _PremiumScratchCardPopupState();
}

class _PremiumScratchCardPopupState extends State<PremiumScratchCardPopup>
    with TickerProviderStateMixin {
  bool _isRevealed = false;
  bool _showRevealHint = false;
  double _scratchProgress = 0.0;
  final List<Offset> _scratchPoints = [];

  // Animation controllers
  late final AnimationController _reveal;
  late final AnimationController _particle;
  late final AnimationController _pulse;
  late final AnimationController _rotate;
  late final AnimationController _celebration;
  late final AnimationController _border;
  late final AnimationController _shine;
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _isRevealed = widget.wasAlreadyScratched;
    _initAnimations();
    if (_isRevealed) _reveal.value = 1.0;
  }

  void _initAnimations() {
    _reveal = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _particle = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );
    _pulse = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);
    _rotate = AnimationController(
      duration: const Duration(milliseconds: 7000),
      vsync: this,
    )..repeat();
    _celebration = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );
    _border = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..repeat();
    _shine = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );
    _float = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);
  }

  // ── Scratch logic ────────────────────────────────────────────────────────

  void _handleScratch(DragUpdateDetails d, Size cardSize) {
    if (widget.wasAlreadyScratched || _isRevealed) return;

    setState(() {
      _scratchPoints.add(d.localPosition);

      // Grid-based coverage — 28x28 cells
      const gridSize = 28.0;
      final uniqueCells = <String>{};
      for (final p in _scratchPoints) {
        uniqueCells.add(
          '${(p.dx / gridSize).floor()},${(p.dy / gridSize).floor()}',
        );
      }

      final totalCells =
          (cardSize.width / gridSize) * (cardSize.height / gridSize);
      // Only need 32% coverage to trigger reveal — feels satisfying, not slow
      _scratchProgress = (uniqueCells.length / (totalCells * 0.32)).clamp(
        0.0,
        1.0,
      );

      if (_scratchProgress >= 0.10 && !_showRevealHint) {
        _showRevealHint = true;
      }
      if (_scratchProgress >= 1.0) _revealReward();
    });
  }

  void _revealReward() async {
    if (_isRevealed) return;
    setState(() => _isRevealed = true);

    HapticFeedback.heavyImpact();
    _reveal.forward();
    _particle.forward();
    _celebration.forward();
    _shine.forward();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('scratched_${widget.taskId}_${widget.taskType}', true);
    widget.onRewardClaimed?.call();

    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 640), () {
      if (mounted) HapticFeedback.lightImpact();
    });
  }

  // ── Colours ──────────────────────────────────────────────────────────────

  Color get _primary => widget.rewardPackage.primaryColor;

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final cardWidth = math.min(screen.width * 0.88, 380.0);
    final cardHeight = math.min(screen.height * 0.76, 600.0);
    final tierInfo = RewardManager.getTierInfo(widget.rewardPackage.tier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dismiss on tap outside
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),

          // Celebration confetti (behind card)
          if (_isRevealed)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _celebration,
                builder: (_, __) => CustomPaint(
                  painter: _CelebrationPainter(
                    progress: _celebration.value,
                    color: _primary,
                  ),
                ),
              ),
            ),

          // The card
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_rotate, _border, _float]),
              builder: (_, __) {
                final floatY = math.sin(_float.value * math.pi) * 6;
                return Transform.translate(
                  offset: Offset(0, floatY),
                  child: Container(
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(
                            0.38 + math.sin(_rotate.value * math.pi * 2) * 0.18,
                          ),
                          blurRadius: 55,
                          spreadRadius: 12,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.55),
                          blurRadius: 28,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Stack(
                        children: [
                          _cardBackground(cardWidth, cardHeight),
                          if (_isRevealed)
                            _revealedContent(cardWidth, cardHeight, tierInfo),
                          if (_isRevealed && !widget.wasAlreadyScratched)
                            _particleLayer(cardWidth, cardHeight),
                          if (_isRevealed) _shineLayer(cardWidth, cardHeight),
                          if (!_isRevealed)
                            _scratchSurface(cardWidth, cardHeight),
                          _animatedBorder(),
                          _closeButton(),
                          _tierBadge(tierInfo),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Card layers ──────────────────────────────────────────────────────────

  Widget _cardBackground(double w, double h) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF08080F), Color(0xFF0E0E1A), Color(0xFF08080F)],
        ),
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: Size(w, h),
            painter: _HexPatternPainter(color: _primary.withOpacity(0.045)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.75,
                colors: [_primary.withOpacity(0.12), Colors.transparent],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _revealedContent(double w, double h, Map<String, dynamic> tierInfo) {
    return AnimatedBuilder(
      animation: _reveal,
      builder: (_, __) {
        final scale = Curves.elasticOut.transform(
          _reveal.value.clamp(0.0, 1.0),
        );
        final fade = Curves.easeOut.transform(_reveal.value.clamp(0.0, 1.0));
        return Opacity(
          opacity: fade,
          child: Transform.scale(
            scale: scale,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _header(tierInfo),
                            const SizedBox(height: 18),
                            _rewardDisplay(h, tierInfo),
                            const SizedBox(height: 18),
                            _tagRow(tierInfo),
                            const SizedBox(height: 14),
                            _pointsChip(),
                            const SizedBox(height: 14),
                            _taskInfoRow(),
                            const Spacer(),
                            const SizedBox(height: 14),
                            _suggestionTile(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(Map<String, dynamic> tierInfo) {
    final isDiamond = tierInfo['isDiamond'] as bool? ?? false;
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (b) => LinearGradient(
            colors: [Colors.white, _primary, Colors.white],
          ).createShader(b),
          child: Text(
            isDiamond ? '✨  LEGENDARY  ✨' : '🎉  CONGRATULATIONS  🎉',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'You earned a reward!',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.65),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _rewardDisplay(double h, Map<String, dynamic> tierInfo) {
    final size = h * 0.28;
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _rotate]),
      builder: (_, __) {
        final pScale = 1.0 + math.sin(_pulse.value * math.pi) * 0.045;
        return Transform.scale(
          scale: pScale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: size * 1.15,
                height: size * 1.15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_primary.withOpacity(0.25), Colors.transparent],
                    stops: const [0.55, 1.0],
                  ),
                ),
              ),
              // Rotating dotted circle
              Transform.rotate(
                angle: _rotate.value * math.pi * 2,
                child: SizedBox(
                  width: size * 1.0,
                  height: size * 1.0,
                  child: CustomPaint(
                    painter: _DottedCirclePainter(
                      color: _primary,
                      dotCount: 28,
                    ),
                  ),
                ),
              ),
              // Inner solid glow
              Container(
                width: size * 0.78,
                height: size * 0.78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _primary.withOpacity(0.30),
                      _primary.withOpacity(0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // The emoji
              SizedBox(
                width: size * 0.68,
                height: size * 0.68,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: AnimatedRewardEmoji(
                    tier: widget.rewardPackage.tier,
                    size: size * 0.65,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tagRow(Map<String, dynamic> tierInfo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary.withOpacity(0.22), _primary.withOpacity(0.10)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withOpacity(0.42), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tierInfo['emoji'] as String? ?? '🎯',
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.rewardPackage.tagName.isNotEmpty
                      ? widget.rewardPackage.tagName
                      : (tierInfo['tagName'] as String? ?? ''),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.rewardPackage.rewardDisplayName,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.65),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'T${widget.rewardPackage.tierLevel}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pointsChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x33FFD700), Color(0x1AFFA500)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x80FFD700), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.22),
            blurRadius: 22,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 28),
          const SizedBox(width: 10),
          Text(
            '+${widget.rewardPackage.points}',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'POINTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                  letterSpacing: 2,
                ),
              ),
              Text(
                'earned',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _taskInfoRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_taskIcon(), color: Colors.white.withOpacity(0.55), size: 15),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.taskTitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.68),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.rewardPackage.source.label,
              style: TextStyle(
                fontSize: 9,
                color: _primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestionTile() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: Colors.amber.withOpacity(0.82),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.rewardPackage.suggestion.isNotEmpty
                  ? widget.rewardPackage.suggestion
                  : widget.rewardPackage.tagReason,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.72),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Scratch surface ──────────────────────────────────────────────────────

  Widget _scratchSurface(double w, double h) {
    return GestureDetector(
      onPanUpdate: (d) => _handleScratch(d, Size(w, h)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primary,
              _primary.withOpacity(0.82),
              _primary.withOpacity(0.65),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DiagonalLinesPainter(
                  color: Colors.white.withOpacity(0.09),
                ),
              ),
            ),
            CustomPaint(
              size: Size(w, h),
              painter: _ScratchPainter(points: _scratchPoints),
            ),
            _scratchHint(),
          ],
        ),
      ),
    );
  }

  Widget _scratchHint() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Transform.scale(
              scale: 1.0 + math.sin(_pulse.value * math.pi) * 0.1,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.22),
                      blurRadius: 22,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Colors.white, Colors.white60, Colors.white],
            ).createShader(b),
            child: const Text(
              'SCRATCH TO REVEAL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your ${widget.rewardPackage.rewardDisplayName} awaits!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 13,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Opacity(
              opacity: 0.5 + _pulse.value * 0.5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swipe_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Swipe to scratch',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  // ── Reveal decorations ───────────────────────────────────────────────────

  Widget _particleLayer(double w, double h) => Positioned.fill(
    child: AnimatedBuilder(
      animation: _particle,
      builder: (_, __) => CustomPaint(
        painter: _ParticlePainter(
          progress: _particle.value,
          color: _primary,
          count: 65,
        ),
      ),
    ),
  );

  Widget _shineLayer(double w, double h) {
    return AnimatedBuilder(
      animation: _shine,
      builder: (_, __) {
        final progress = Curves.easeIn.transform(_shine.value.clamp(0.0, 1.0));
        return CustomPaint(
          size: Size(w, h),
          painter: _ShinePainter(progress: progress),
        );
      },
    );
  }

  Widget _animatedBorder() => Positioned.fill(
    child: IgnorePointer(
      child: AnimatedBuilder(
        animation: _border,
        builder: (_, __) => CustomPaint(
          painter: _AnimatedBorderPainter(
            progress: _border.value,
            color: _primary,
          ),
        ),
      ),
    ),
  );

  Widget _closeButton() => Positioned(
    top: 14,
    right: 14,
    child: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
      ),
    ),
  );

  Widget _tierBadge(Map<String, dynamic> tierInfo) => Positioned(
    top: 14,
    left: 14,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary.withOpacity(0.85), _primary.withOpacity(0.6)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(color: _primary.withOpacity(0.38), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tierInfo['emoji'] as String? ?? '🎯',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 5),
          Text(
            '${tierInfo['powerWord'] ?? tierInfo['name'] ?? 'Reward'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ),
  );

  IconData _taskIcon() {
    switch (widget.taskType) {
      case 'dayTask':
        return Icons.today_rounded;
      case 'weekTask':
        return Icons.view_week_rounded;
      case 'longGoal':
        return Icons.flag_rounded;
      case 'bucket':
        return Icons.all_inclusive_rounded;
      case 'diary':
        return Icons.book_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    _particle.dispose();
    _pulse.dispose();
    _rotate.dispose();
    _celebration.dispose();
    _border.dispose();
    _shine.dispose();
    _float.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _ShimmerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final sw = size.width * 0.45;
    final startX = -sw + (size.width + sw * 2) * progress;
    final gradient = ui.Gradient.linear(
      Offset(startX, 0),
      Offset(startX + sw, size.height),
      [color.withOpacity(0), color.withOpacity(0.28), color.withOpacity(0)],
      [0.0, 0.5, 1.0],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = gradient,
    );
  }

  @override
  bool shouldRepaint(_ShimmerPainter o) => progress != o.progress;
}

class _ScratchPainter extends CustomPainter {
  final List<Offset> points;
  const _ScratchPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = Colors.transparent
      ..strokeWidth = 72
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = BlendMode.clear;

    for (final p in points) canvas.drawCircle(p, 36, paint);

    if (points.length > 1) {
      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(_ScratchPainter o) => points.length != o.points.length;
}

class _DiagonalLinesPainter extends CustomPainter {
  final Color color;
  const _DiagonalLinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const spacing = 22.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalLinesPainter o) => false;
}

class _HexPatternPainter extends CustomPainter {
  final Color color;
  const _HexPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const r = 18.0;
    const w = r * 1.73;
    const h = r * 1.5;
    for (double y = 0; y < size.height + h; y += h) {
      for (double x = 0; x < size.width + w; x += w) {
        final dx = ((y / h).floor() % 2 == 0) ? 0.0 : w * 0.5;
        _hex(canvas, Offset(x + dx, y), r, paint);
      }
    }
  }

  void _hex(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = (i * 60 - 30) * math.pi / 180;
      final pt = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _HexPatternPainter o) => false;
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  final int count;
  const _ParticlePainter({
    required this.progress,
    required this.color,
    this.count = 50,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rng = math.Random(42);

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + rng.nextDouble() * 0.6;
      final speed = 0.45 + rng.nextDouble() * 0.55;
      final maxD = size.width * 0.85 * speed;
      final dist = maxD * Curves.easeOut.transform(progress);
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final pSize = (3.5 + rng.nextDouble() * 4) * (1 - progress * 0.5);

      final x = cx + math.cos(angle) * dist;
      final y = cy + math.sin(angle) * dist;

      final paint = Paint()..color = _pColor(i, rng).withOpacity(opacity);

      switch (i % 3) {
        case 0:
          _star(canvas, Offset(x, y), pSize, paint);
          break;
        case 1:
          _diamond(canvas, Offset(x, y), pSize, paint);
          break;
        default:
          canvas.drawCircle(Offset(x, y), pSize, paint);
      }
    }
  }

  Color _pColor(int i, math.Random r) {
    final list = [
      color,
      const Color(0xFFFFD700),
      Colors.white,
      color.withOpacity(0.75),
    ];
    return list[i % list.length];
  }

  void _star(Canvas c, Offset o, double s, Paint p) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final a = (i * 72 - 90) * math.pi / 180;
      final pt = Offset(o.dx + s * math.cos(a), o.dy + s * math.sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    c.drawPath(path, p);
  }

  void _diamond(Canvas c, Offset o, double s, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(o.dx, o.dy - s)
        ..lineTo(o.dx + s, o.dy)
        ..lineTo(o.dx, o.dy + s)
        ..lineTo(o.dx - s, o.dy)
        ..close(),
      p,
    );
  }

  @override
  bool shouldRepaint(_ParticlePainter o) => progress != o.progress;
}

class _CelebrationPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _CelebrationPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(123);
    for (int i = 0; i < 55; i++) {
      final startX = rng.nextDouble() * size.width;
      final startY = -50.0 - rng.nextDouble() * 100;
      final endY = size.height + 50;

      final fall = ((progress * 2 - i / 55) % 1).clamp(0.0, 1.0);
      final y = startY + (endY - startY) * fall;
      final x = startX + math.sin(fall * math.pi * 4) * 28;

      final opacity = (1 - fall).clamp(0.25, 1.0);
      final cSize = 4 + rng.nextDouble() * 6;
      final paint = Paint()..color = _cColor(i, rng).withOpacity(opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(fall * math.pi * 4);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: cSize,
          height: cSize * 0.55,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  Color _cColor(int i, math.Random r) {
    final list = [
      color,
      const Color(0xFFFFD700),
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFAB47BC),
      Colors.white,
    ];
    return list[i % list.length];
  }

  @override
  bool shouldRepaint(_CelebrationPainter o) => progress != o.progress;
}

class _ShinePainter extends CustomPainter {
  final double progress;
  const _ShinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;
    final x = -size.width * 0.4 + (size.width * 1.8) * progress;
    final gradient = ui.Gradient.linear(
      Offset(x, 0),
      Offset(x + size.width * 0.4, size.height),
      [
        Colors.white.withOpacity(0),
        Colors.white.withOpacity(0.18),
        Colors.white.withOpacity(0),
      ],
      [0.0, 0.5, 1.0],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = gradient,
    );
  }

  @override
  bool shouldRepaint(_ShinePainter o) => progress != o.progress;
}

class _DottedCirclePainter extends CustomPainter {
  final Color color;
  final int dotCount;
  const _DottedCirclePainter({required this.color, this.dotCount = 24});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.55);
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 4;
    for (int i = 0; i < dotCount; i++) {
      final a = (i / dotCount) * math.pi * 2;
      canvas.drawCircle(
        Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a)),
        3.2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DottedCirclePainter o) => false;
}

class _AnimatedBorderPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _AnimatedBorderPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(32));

    final gradient = SweepGradient(
      startAngle: progress * math.pi * 2,
      colors: [
        color.withOpacity(0.0),
        color.withOpacity(0.65),
        color.withOpacity(0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(6), const Radius.circular(26)),
      Paint()
        ..color = color.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_AnimatedBorderPainter o) => progress != o.progress;
}
