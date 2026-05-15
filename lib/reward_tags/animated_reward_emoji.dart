// lib/reward_tags/animated_reward_emoji.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'reward_enums.dart';

class _TierVisual {
  final String emoji;
  final List<Color> glowColors;
  final List<Color> ringColors;
  final List<Color> innerRingColors;
  final List<String> particles;
  final double pulseAmplitude;
  final double rotateSpeed;
  final bool showSparkles;
  final bool showAura;
  final bool showLightning;
  final AnimationType animationType;
  final double animationSpeed;
  final List<Color> particleColors;
  final bool showParticles;
  final ParticleType particleType;

  const _TierVisual({
    required this.emoji,
    required this.glowColors,
    required this.ringColors,
    required this.innerRingColors,
    required this.particles,
    this.pulseAmplitude = 0.06,
    this.rotateSpeed = 1.0,
    this.showSparkles = false,
    this.showAura = false,
    this.showLightning = false,
    this.animationType = AnimationType.pulse,
    this.animationSpeed = 1.0,
    this.particleColors = const [Color(0xFF3B82F6)],
    this.showParticles = false,
    this.particleType = ParticleType.orbit,
  });
}

enum AnimationType {
  pulse,
  rotate,
  orbit,
  wave,
  bounce,
  ripple,
  energy,
  float,
  shimmer,
  spiral,
  glitch,
  breathe,
  magnetism,
}

enum ParticleType { orbit, float, scatter, spiral, none }

const Map<RewardTier, _TierVisual> _visuals = {
  // ── CORE REWARDS ──
  RewardTier.spark: _TierVisual(
    emoji: '✨',
    glowColors: [Color(0x77FACC15), Color(0x33FDE047), Color(0x00000000)],
    ringColors: [Color(0xFFEAB308), Color(0xFFFEF08A), Color(0xFFCA8A04)],
    innerRingColors: [Color(0x44FACC15), Color(0x15FDE047), Color(0x00000000)],
    particles: ['◇', '◆', '◇'],
    particleColors: [Color(0xFFFEF08A), Color(0xFFEAB308)],
    pulseAmplitude: 0.08,
    animationType: AnimationType.breathe,
    showParticles: true,
    particleType: ParticleType.float,
  ),

  RewardTier.flame: _TierVisual(
    emoji: '🔥',
    glowColors: [Color(0x77F97316), Color(0x44FDBA74), Color(0x00000000)],
    ringColors: [Color(0xFFF97316), Color(0xFFFDBA74), Color(0xFFEA580C)],
    innerRingColors: [Color(0x44F97316), Color(0x22FDBA74), Color(0x00000000)],
    particles: ['🔥', '💥', '🔥'],
    particleColors: [Color(0xFFFDBA74), Color(0xFFEA580C)],
    animationType: AnimationType.glitch,
    rotateSpeed: 1.3,
    showParticles: true,
    particleType: ParticleType.scatter,
  ),

  RewardTier.ember: _TierVisual(
    emoji: '🌿',
    glowColors: [Color(0x6610B981), Color(0x3234D399), Color(0x00000000)],
    ringColors: [Color(0xFF059669), Color(0xFF6EE7B7), Color(0xFF064E3B)],
    innerRingColors: [Color(0x3310B981), Color(0x1534D399), Color(0x00000000)],
    particles: ['🍃', '🍃', '🍃'],
    particleColors: [Color(0xFF6EE7B7), Color(0xFF059669)],
    showSparkles: false,
    animationType: AnimationType.pulse,
    showParticles: true,
    particleType: ParticleType.orbit,
  ),

  RewardTier.blaze: _TierVisual(
    emoji: '⚡',
    glowColors: [Color(0xCC06B6D4), Color(0x7722D3EE), Color(0x00000000)],
    ringColors: [Color(0xFF06B6D4), Color(0xFF67E8F9), Color(0xFF0891B2)],
    innerRingColors: [Color(0x7706B6D4), Color(0x4422D3EE), Color(0x00000000)],
    particles: ['⚡', '🔥', '⚡'],
    particleColors: [Color(0xFF67E8F9), Color(0xFF06B6D4)],
    animationSpeed: 1.5,
    showSparkles: true,
    showAura: true,
    animationType: AnimationType.rotate,
    showParticles: true,
    particleType: ParticleType.scatter,
  ),

  RewardTier.crystal: _TierVisual(
    emoji: '💎',
    glowColors: [Color(0xAA3B82F6), Color(0x6660A5FA), Color(0x00000000)],
    ringColors: [Color(0xFF3B82F6), Color(0xFF93C5FD), Color(0xFF1D4ED8)],
    innerRingColors: [Color(0x553B82F6), Color(0x3360A5FA), Color(0x00000000)],
    particles: ['✦', '✧', '✦'],
    particleColors: [Color(0xFF93C5FD), Color(0xFF3B82F6)],
    showSparkles: true,
    showAura: true,
    animationType: AnimationType.shimmer,
    showParticles: true,
    particleType: ParticleType.float,
  ),

  RewardTier.prism: _TierVisual(
    emoji: '🏆',
    glowColors: [Color(0xBBF8FAFC), Color(0x66CBD5E1), Color(0x00000000)],
    ringColors: [Color(0xFFEC4899), Color(0xFF3B82F6), Color(0xFFEAB308)],
    innerRingColors: [Color(0x66F8FAFC), Color(0x33E2E8F0), Color(0x00000000)],
    particles: ['✨', '💎', '✨'],
    particleColors: [Color(0xFFF472B6), Color(0xFF60A5FA)],
    showSparkles: true,
    showAura: true,
    animationType: AnimationType.magnetism,
    showParticles: true,
    particleType: ParticleType.scatter,
  ),

  RewardTier.radiant: _TierVisual(
    emoji: '👑',
    glowColors: [Color(0x99F59E0B), Color(0x55FEF3C7), Color(0x00000000)],
    ringColors: [Color(0xFFF59E0B), Color(0xFFFEF3C7), Color(0xFFB45309)],
    innerRingColors: [Color(0x44F59E0B), Color(0x22FEF3C7), Color(0x00000000)],
    particles: ['.', '.', '.'],
    particleColors: [Color(0xFFFEF3C7), Color(0xFFB45309)],
    rotateSpeed: 1.8,
    showLightning: true,
    animationType: AnimationType.energy,
    showParticles: true,
    particleType: ParticleType.orbit,
  ),

  RewardTier.nova: _TierVisual(
    emoji: '🌟',
    glowColors: [Color(0xDDBE123C), Color(0xAAFB7185), Color(0x00000000)],
    ringColors: [Color(0xFFBE123C), Color(0xFFFDA4AF), Color(0xFFE11D48)],
    innerRingColors: [Color(0x99BE123C), Color(0x66FB7185), Color(0x00000000)],
    particles: ['💥', '💥', '💥'],
    particleColors: [Color(0xFFFDA4AF), Color(0xFFBE123C)],
    animationSpeed: 2.0,
    showSparkles: true,
    showAura: true,
    showLightning: true,
    animationType: AnimationType.glitch,
    showParticles: true,
    particleType: ParticleType.spiral,
  ),

  // ── DASHBOARD REWARDS ──
  RewardTier.dashboardBronze: _TierVisual(
    emoji: '🍀',
    glowColors: [Color(0x6610B981), Color(0x4434D399), Color(0x00000000)],
    ringColors: [Color(0xFF10B981), Color(0xFFD1FAE5), Color(0xFF065F46)],
    innerRingColors: [Color(0x3310B981), Color(0x1134D399), Color(0x00000000)],
    particles: ['🍀', '🍀', '🍀'],
    particleColors: [Color(0xFFD1FAE5), Color(0xFF10B981)],
    animationType: AnimationType.magnetism,
    showParticles: true,
    particleType: ParticleType.float,
  ),

  RewardTier.dashboardSilver: _TierVisual(
    emoji: '☄️',
    glowColors: [Color(0x660EA5E9), Color(0x337DD3FC), Color(0x00000000)],
    ringColors: [Color(0xFF0EA5E9), Color(0xFFE0F2FE), Color(0xFF0369A1)],
    innerRingColors: [Color(0x330EA5E9), Color(0x117DD3FC), Color(0x00000000)],
    particles: ['☄️', '☄️', '☄️'],
    particleColors: [Color(0xFFBAE6FD), Color(0xFF0EA5E9)],
    showSparkles: true,
    animationType: AnimationType.wave,
    showParticles: true,
    particleType: ParticleType.scatter,
  ),

  RewardTier.dashboardGold: _TierVisual(
    emoji: '🔱',
    glowColors: [Color(0x99EAB308), Color(0x66FACC15), Color(0x00000000)],
    ringColors: [Color(0xFFEAB308), Color(0xFFFEF08A), Color(0xFFCA8A04)],
    innerRingColors: [Color(0x55EAB308), Color(0x22FACC15), Color(0x00000000)],
    particles: ['★', '✦', '★'],
    particleColors: [Color(0xFFFEF08A), Color(0xFFEAB308)],
    showAura: true,
    animationType: AnimationType.breathe,
    showParticles: true,
    particleType: ParticleType.orbit,
  ),

  RewardTier.dashboardPlatinum: _TierVisual(
    emoji: '🔮',
    glowColors: [Color(0xAA94A3B8), Color(0x66CBD5E1), Color(0x00000000)],
    ringColors: [Color(0xFF94A3B8), Color(0xFFE2E8F0), Color(0xFF64748B)],
    innerRingColors: [Color(0x5594A3B8), Color(0x22CBD5E1), Color(0x00000000)],
    particles: ['◆', '✧', '◆'],
    particleColors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
    animationType: AnimationType.ripple,
    showParticles: true,
    particleType: ParticleType.scatter,
  ),

  RewardTier.dashboardDiamond: _TierVisual(
    emoji: '💎',
    glowColors: [Color(0xAA2563EB), Color(0x6660A5FA), Color(0x00000000)],
    ringColors: [Color(0xFF2563EB), Color(0xFFBFDBFE), Color(0xFF1D4ED8)],
    innerRingColors: [Color(0x552563EB), Color(0x3360A5FA), Color(0x00000000)],
    particles: ['✦', '✧', '✦'],
    particleColors: [Color(0xFFBFDBFE), Color(0xFF60A5FA)],
    showSparkles: true,
    showAura: true,
    animationType: AnimationType.rotate,
    showParticles: true,
    particleType: ParticleType.orbit,
  ),

  RewardTier.dashboardOmega: _TierVisual(
    emoji: 'Ω',
    glowColors: [Color(0xCC7C3AED), Color(0x77A78BFA), Color(0x00000000)],
    ringColors: [Color(0xFF7C3AED), Color(0xFFDDD6FE), Color(0xFF5B21B6)],
    innerRingColors: [Color(0x777C3AED), Color(0x44A78BFA), Color(0x00000000)],
    particles: ['Ω', '✦', 'Ω'],
    particleColors: [Color(0xFFDDD6FE), Color(0xFF7C3AED)],
    showSparkles: true,
    showAura: true,
    showLightning: true,
    animationType: AnimationType.spiral,
    showParticles: true,
    particleType: ParticleType.spiral,
  ),

  RewardTier.dashboardApex: _TierVisual(
    emoji: '⚜️',
    glowColors: [Color(0xDDF59E0B), Color(0xAAFB7185), Color(0x00000000)],
    ringColors: [Color(0xFFF59E0B), Color(0xFFFEF3C7), Color(0xFFD97706)],
    innerRingColors: [Color(0x99F59E0B), Color(0x66FB7185), Color(0x00000000)],
    particles: ['⚜️', '⚜️', '⚜️'],
    particleColors: [Color(0xFFFEF3C7), Color(0xFFF59E0B)],
    animationSpeed: 2.2,
    showSparkles: true,
    showAura: true,
    animationType: AnimationType.glitch,
    showParticles: true,
    particleType: ParticleType.scatter,
  ),

  // ── GLOBAL RANK REWARDS ──
  RewardTier.rankElite: _TierVisual(
    emoji: '🐲',
    glowColors: [Color(0x6616A34A), Color(0x334ADE80), Color(0x00000000)],
    ringColors: [Color(0xFF16A34A), Color(0xFFDCFCE7), Color(0xFF14532D)],
    innerRingColors: [Color(0x3316A34A), Color(0x164ADE80), Color(0x00000000)],
    particles: ['🐲', '🐲', '🐲'],
    particleColors: [Color(0xFFDCFCE7), Color(0xFF16A34A)],
    animationType: AnimationType.magnetism,
    showParticles: true,
    particleType: ParticleType.float,
  ),

  RewardTier.rankMaster: _TierVisual(
    emoji: '🏹',
    glowColors: [Color(0x77F59E0B), Color(0x44FEF3C7), Color(0x00000000)],
    ringColors: [Color(0xFFF59E0B), Color(0xFFFEF3C7), Color(0xFFD97706)],
    innerRingColors: [Color(0x44F59E0B), Color(0x22FEF3C7), Color(0x00000000)],
    particles: ['✦', '✦', '✦'],
    particleColors: [Color(0xFFFEF3C7), Color(0xFFF59E0B)],
    showAura: true,
    animationType: AnimationType.energy,
    showParticles: true,
    particleType: ParticleType.orbit,
  ),

  RewardTier.rankLegend: _TierVisual(
    emoji: '🐉',
    glowColors: [Color(0x9915803D), Color(0x664ADE80), Color(0x00000000)],
    ringColors: [Color(0xFF15803D), Color(0xFFBBF7D0), Color(0xFF166534)],
    innerRingColors: [Color(0x5515803D), Color(0x224ADE80), Color(0x00000000)],
    particles: ['🐉', '✧', '🐉'],
    particleColors: [Color(0xFFBBF7D0), Color(0xFF15803D)],
    showSparkles: true,
    showAura: true,
    animationType: AnimationType.shimmer,
    showParticles: true,
    particleType: ParticleType.scatter,
  ),

  RewardTier.rankIcon: _TierVisual(
    emoji: '💠',
    glowColors: [Color(0x9906B6D4), Color(0x55A5F3FC), Color(0x00000000)],
    ringColors: [Color(0xFF06B6D4), Color(0xFFCFFAFE), Color(0xFF0891B2)],
    innerRingColors: [Color(0x4406B6D4), Color(0x22A5F3FC), Color(0x00000000)],
    particles: ['◆', '✦', '◆'],
    particleColors: [Color(0xFFCFFAFE), Color(0xFF06B6D4)],
    showLightning: true,
    animationType: AnimationType.glitch,
    showParticles: true,
    particleType: ParticleType.spiral,
  ),

  RewardTier.rankGodsend: _TierVisual(
    emoji: '💫',
    glowColors: [Color(0xCCF59E0B), Color(0x77FEF3C7), Color(0x00000000)],
    ringColors: [Color(0xFFF59E0B), Color(0xFFFEF3C7), Color(0xFFB45309)],
    innerRingColors: [Color(0x77F59E0B), Color(0x44FEF3C7), Color(0x00000000)],
    particles: ['✨', '✧', '✨'],
    particleColors: [Color(0xFFFEF3C7), Color(0xFFF59E0B)],
    showSparkles: true,
    showAura: true,
    animationType: AnimationType.breathe,
    showParticles: true,
    particleType: ParticleType.float,
  ),

  RewardTier.rankVanguard: _TierVisual(
    emoji: '🔱',
    glowColors: [Color(0xCC6366F1), Color(0x77A5B4FC), Color(0x00000000)],
    ringColors: [Color(0xFF6366F1), Color(0xFFE0E7FF), Color(0xFF4338CA)],
    innerRingColors: [Color(0x776366F1), Color(0x44A5B4FC), Color(0x00000000)],
    particles: ['🔱', '▲', '🔱'],
    particleColors: [Color(0xFFE0E7FF), Color(0xFF6366F1)],
    showSparkles: true,
    showAura: true,
    showLightning: true,
    animationType: AnimationType.rotate,
    showParticles: true,
    particleType: ParticleType.scatter,
  ),

  RewardTier.rankSentinel: _TierVisual(
    emoji: '🦄',
    glowColors: [Color(0xDDD946EF), Color(0xAAFFC7FF), Color(0x00000000)],
    ringColors: [Color(0xFFD946EF), Color(0xFFFAE8FF), Color(0xFF701A75)],
    innerRingColors: [Color(0x99D946EF), Color(0x66FFC7FF), Color(0x00000000)],
    particles: ['🦄', '🦄', '🦄'],
    particleColors: [Color(0xFFFAE8FF), Color(0xFFD946EF)],
    animationSpeed: 2.5,
    showSparkles: true,
    showAura: true,
    showLightning: true,
    animationType: AnimationType.wave,
    showParticles: true,
    particleType: ParticleType.orbit,
  ),
};

// ─────────────────────────────────────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class AnimatedRewardEmoji extends StatefulWidget {
  final RewardTier tier;
  final double size;

  const AnimatedRewardEmoji({super.key, required this.tier, this.size = 120});

  @override
  State<AnimatedRewardEmoji> createState() => _AnimatedRewardEmojiState();
}

class _AnimatedRewardEmojiState extends State<AnimatedRewardEmoji>
    with TickerProviderStateMixin {
  late final AnimationController _master;
  late final AnimationController _shimmer;
  late final AnimationController _glitch;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    final v = _visuals[widget.tier];
    final speed = (v?.animationSpeed ?? 1.0) * (v?.rotateSpeed ?? 1.0);

    _master = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (5000 / speed).round()),
    )..repeat();

    _pulse = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2000 / speed).round()),
    )..repeat(reverse: true);

    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _glitch = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _master.dispose();
    _pulse.dispose();
    _shimmer.dispose();
    _glitch.dispose();
    super.dispose();
  }

  double get pulseValue => _pulse.value;
  double get rotateValue => _master.value;
  double get counterRotateValue => (1.0 - _master.value);
  double get orbitValue => (_master.value * 1.5) % 1.0;
  double get auraValue => _pulse.value;
  double get sparkleValue => _pulse.value;
  double get lightningValue => _glitch.value;
  double get waveValue => _master.value;
  double get bounceValue => _pulse.value;
  double get rippleValue => _master.value;
  double get energyValue => _master.value;
  double get floatValue => _pulse.value;
  double get shimmerValue => _shimmer.value;
  double get spiralValue => _master.value;
  double get glitchValue => _glitch.value;
  double get breatheValue => _pulse.value;
  double get magnetismValue => _pulse.value;

  @override
  Widget build(BuildContext context) {
    final v = _visuals[widget.tier];
    if (v == null) return const SizedBox.shrink();

    final s = widget.size;

    return SizedBox(
      width: s,
      height: s,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: Listenable.merge([_master, _pulse, _shimmer, _glitch]),
          builder: (context, _) => _buildContent(v, s),
        ),
      ),
    );
  }

  Widget _buildContent(_TierVisual v, double s) {
    final curPulseScale =
        1.0 + math.sin(pulseValue * math.pi) * v.pulseAmplitude;

    final children = <Widget>[
      _GlowDisc(size: s, colors: v.glowColors),

      if (v.showAura)
        _AuraPulse(size: s, color: v.ringColors.first, value: auraValue),

      if (v.animationType == AnimationType.ripple) ..._buildRipples(v, s),
      if (v.animationType == AnimationType.energy) _buildEnergyField(v, s),
      if (v.animationType == AnimationType.spiral)
        _buildSpiralField(v, s, spiralValue),

      if (v.animationType == AnimationType.rotate ||
          v.animationType == AnimationType.glitch)
        Transform.rotate(
          angle: rotateValue * math.pi * 2 * v.rotateSpeed,
          child: _RingLayer(
            size: s * 0.92,
            colors: v.ringColors,
            isDiamond: widget.tier.isDiamond,
            strokeWidth: widget.tier.isDiamond ? 3.5 : 2.0,
          ),
        ),

      if (v.animationType == AnimationType.breathe)
        Transform.scale(
          scale: 0.9 + 0.15 * math.sin(breatheValue * math.pi),
          child: _RingLayer(
            size: s * 0.88,
            colors: v.ringColors,
            isDiamond: false,
            strokeWidth: 1.8,
          ),
        ),

      if (v.animationType == AnimationType.magnetism)
        Transform.rotate(
          angle: magnetismValue * math.pi,
          child: _RingLayer(
            size: s * 0.85,
            colors: v.ringColors,
            isDiamond: false,
            strokeWidth: 2.2,
          ),
        ),

      if (v.animationType == AnimationType.wave ||
          v.animationType == AnimationType.shimmer ||
          v.animationType == AnimationType.pulse)
        _RingLayer(
          size: s * 0.88,
          colors: v.ringColors,
          isDiamond: false,
          strokeWidth: 2.0,
        ),

      if (v.animationType != AnimationType.energy &&
          v.animationType != AnimationType.spiral)
        Transform.rotate(
          angle: -counterRotateValue * math.pi * 2,
          child: _RingLayer(
            size: s * 0.72,
            colors: v.innerRingColors,
            isDiamond: false,
            strokeWidth: 1.5,
            dashed: true,
          ),
        ),

      if (v.showParticles)
        ...(switch (v.particleType) {
          ParticleType.orbit => _buildOrbitingParticles(v, s),
          ParticleType.float => _buildFloatingParticles(v, s),
          ParticleType.scatter => _buildScatterParticles(v, s),
          ParticleType.spiral => _buildSpiralParticles(v, s),
          ParticleType.none => <Widget>[],
        }),

      if (v.showSparkles) ..._sparkles(s, v.ringColors.first),
      if (v.showLightning) ..._lightningArcs(s, v.ringColors.first),

      _buildCentralEmoji(v, s, curPulseScale),

      if (v.animationType == AnimationType.shimmer) _buildShimmerSweep(v, s),
    ];

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: children,
    );
  }

  List<Widget> _buildRipples(_TierVisual v, double s) {
    return List.generate(3, (i) {
      final delay = i * 0.3;
      final progress = (rippleValue + delay) % 1.0;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      return Container(
        width: s * progress,
        height: s * progress,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: v.ringColors.first.withOpacity(opacity * 0.5),
            width: 2,
          ),
        ),
      );
    });
  }

  Widget _buildEnergyField(_TierVisual v, double s) {
    return CustomPaint(
      size: Size(s, s),
      painter: _EnergyPainter(color: v.ringColors.first, progress: energyValue),
    );
  }

  Widget _buildSpiralField(_TierVisual v, double s, double progress) {
    return CustomPaint(
      size: Size(s, s),
      painter: _SpiralPainter(
        color: v.ringColors.first,
        secondaryColor: v.innerRingColors.first,
        progress: progress,
      ),
    );
  }

  Widget _buildShimmerSweep(_TierVisual v, double s) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.transparent,
            v.ringColors.first.withOpacity(0.0),
            v.ringColors.first.withOpacity(0.4),
            v.ringColors.first.withOpacity(0.0),
            Colors.transparent,
          ],
          stops: [
            0.0,
            (shimmerValue - 0.2).clamp(0.0, 1.0),
            shimmerValue,
            (shimmerValue + 0.2).clamp(0.0, 1.0),
            1.0,
          ],
        ),
      ),
    );
  }

  Widget _buildCentralEmoji(_TierVisual v, double s, double pulseScale) {
    Widget emojiWidget = Transform.scale(
      scale: pulseScale,
      child: Container(
        width: s * 0.48,
        height: s * 0.48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [v.glowColors.first.withOpacity(0.6), Colors.transparent],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          v.emoji,
          style: TextStyle(
            fontSize: s * 0.38,
            shadows: [
              Shadow(
                color: v.glowColors.first.withOpacity(0.95),
                blurRadius: s * 0.18,
              ),
              Shadow(
                color: v.ringColors.first.withOpacity(0.5),
                blurRadius: s * 0.08,
              ),
            ],
          ),
        ),
      ),
    );

    switch (v.animationType) {
      case AnimationType.wave:
        final waveOff = math.sin(waveValue * math.pi * 2) * 12;
        return Transform.translate(
          offset: Offset(waveOff, 0),
          child: emojiWidget,
        );
      case AnimationType.bounce:
        final bounceOff = -math.sin(bounceValue * math.pi) * 15;
        return Transform.translate(
          offset: Offset(0, bounceOff),
          child: emojiWidget,
        );
      case AnimationType.float:
        final floatOff = -math.sin(floatValue * math.pi) * 18;
        return Transform.translate(
          offset: Offset(0, floatOff),
          child: emojiWidget,
        );
      case AnimationType.glitch:
        final gx = (math.sin(glitchValue * math.pi * 4) * 4).toInt();
        final gy = (math.cos(glitchValue * math.pi * 3) * 4).toInt();
        return Transform.translate(
          offset: Offset(gx.toDouble(), gy.toDouble()),
          child: emojiWidget,
        );
      case AnimationType.spiral:
        final ang = spiralValue * math.pi * 2;
        final rad = math.sin(spiralValue * math.pi) * 8;
        return Transform.translate(
          offset: Offset(math.cos(ang) * rad, math.sin(ang) * rad),
          child: emojiWidget,
        );
      case AnimationType.breathe:
        return Transform.scale(
          scale: 1.0 + 0.12 * math.sin(breatheValue * math.pi),
          child: emojiWidget,
        );
      case AnimationType.magnetism:
        final magX = math.cos(magnetismValue * math.pi * 2) * 5;
        final magY = math.sin(magnetismValue * math.pi * 2) * 5;
        return Transform.translate(
          offset: Offset(magX, magY),
          child: emojiWidget,
        );
      default:
        return emojiWidget;
    }
  }

  List<Widget> _buildOrbitingParticles(_TierVisual v, double s) {
    return List.generate(v.particles.length, (i) {
      final ang =
          (i / v.particles.length) * math.pi * 2 + orbitValue * math.pi * 2;
      final rad = s * 0.4;
      return Positioned(
        left: s / 2 + math.cos(ang) * rad - 8,
        top: s / 2 + math.sin(ang) * rad - 8,
        child: Text(
          v.particles[i],
          style: TextStyle(
            fontSize: 14,
            color: v.particleColors[i % v.particleColors.length],
          ),
        ),
      );
    });
  }

  List<Widget> _buildFloatingParticles(_TierVisual v, double s) {
    return List.generate(v.particles.length, (i) {
      final off = (i / v.particles.length) * math.pi * 2;
      final y = s * 0.35 * math.sin(floatValue * math.pi + off);
      final x = s * 0.35 * math.cos(off);
      return Positioned(
        left: s / 2 + x - 8,
        top: s / 2 + y - 8,
        child: Text(
          v.particles[i],
          style: TextStyle(
            fontSize: 12,
            color: v.particleColors[i % v.particleColors.length].withOpacity(
              0.8,
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildScatterParticles(_TierVisual v, double s) {
    return List.generate(v.particles.length, (i) {
      final seed = math.Random(i).nextDouble();
      final progress = (rotateValue + seed) % 1.0;
      final ang = seed * math.pi * 2;
      final rad = s * 0.1 + s * 0.35 * progress;
      return Positioned(
        left: s / 2 + math.cos(ang) * rad - 6,
        top: s / 2 + math.sin(ang) * rad - 6,
        child: Opacity(
          opacity: (1.0 - progress).clamp(0.0, 1.0),
          child: Text(
            v.particles[i],
            style: TextStyle(
              fontSize: 10 + 4 * seed,
              color: v.particleColors[i % v.particleColors.length],
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildSpiralParticles(_TierVisual v, double s) {
    return List.generate(v.particles.length, (i) {
      final seed = i / v.particles.length;
      final progress = (spiralValue + seed) % 1.0;
      final ang = progress * math.pi * 4 + seed * math.pi * 2;
      final rad = s * 0.4 * progress;
      return Positioned(
        left: s / 2 + math.cos(ang) * rad - 7,
        top: s / 2 + math.sin(ang) * rad - 7,
        child: Opacity(
          opacity: (1.0 - progress).clamp(0.0, 1.0),
          child: Text(
            v.particles[i],
            style: TextStyle(
              fontSize: 14,
              color: v.particleColors[i % v.particleColors.length],
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _sparkles(double s, Color color) {
    return List.generate(4, (i) {
      final ang = (i / 4) * math.pi * 2 + rotateValue * math.pi;
      final rad = s * 0.42;
      return Positioned(
        left: s / 2 + math.cos(ang) * rad - 5,
        top: s / 2 + math.sin(ang) * rad - 5,
        child: Opacity(
          opacity: sparkleValue,
          child: Icon(Icons.auto_awesome, color: color, size: 10),
        ),
      );
    });
  }

  List<Widget> _lightningArcs(double s, Color color) {
    if (glitchValue < 0.2) return [];
    return List.generate(2, (i) {
      final ang = (i / 2) * math.pi * 2 + rotateValue * math.pi;
      return Positioned(
        left: s / 2 + math.cos(ang) * (s * 0.35) - 10,
        top: s / 2 + math.sin(ang) * (s * 0.35) - 10,
        child: Transform.rotate(
          angle: ang,
          child: Icon(Icons.bolt, color: color, size: 20),
        ),
      );
    });
  }
}

class _EnergyPainter extends CustomPainter {
  final Color color;
  final double progress;

  _EnergyPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2 + progress * math.pi;
      final path = Path();
      final rStart = size.width * 0.2;
      final rEnd = size.width * 0.45;

      final p1 = Offset(
        center.dx + rStart * math.cos(angle),
        center.dy + rStart * math.sin(angle),
      );

      final p2 = Offset(
        center.dx +
            rEnd * math.cos(angle + 0.5 * math.sin(progress * math.pi * 2)),
        center.dy +
            rEnd * math.sin(angle + 0.5 * math.sin(progress * math.pi * 2)),
      );

      path.moveTo(p1.dx, p1.dy);
      path.quadraticBezierTo(
        center.dx + (rStart + rEnd) / 2 * math.cos(angle + 0.2),
        center.dy + (rStart + rEnd) / 2 * math.sin(angle + 0.2),
        p2.dx,
        p2.dy,
      );

      final opacity = (0.2 + 0.3 * math.sin(progress * math.pi + i)).clamp(
        0.0,
        1.0,
      );
      canvas.drawPath(path, paint..color = color.withOpacity(opacity));
    }
  }

  @override
  bool shouldRepaint(_EnergyPainter old) => progress != old.progress;
}

class _SpiralPainter extends CustomPainter {
  final Color color;
  final Color secondaryColor;
  final double progress;

  _SpiralPainter({
    required this.color,
    required this.secondaryColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    const spiralLoops = 3;
    const pointsPerLoop = 60;

    final path = Path();
    for (int i = 0; i < pointsPerLoop * spiralLoops; i++) {
      final t = i / pointsPerLoop;
      final angle = t * math.pi * 2 + progress * math.pi * 2;
      final radius = (size.width * 0.1) + (t * size.width * 0.3);

      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    paint.color = color.withOpacity(0.6);
    canvas.drawPath(path, paint);

    // Draw secondary spiral
    final path2 = Path();
    for (int i = 0; i < pointsPerLoop * spiralLoops; i++) {
      final t = i / pointsPerLoop;
      final angle = t * math.pi * 2 + progress * math.pi * 2 + math.pi;
      final radius = (size.width * 0.1) + (t * size.width * 0.3);

      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path2.moveTo(x, y);
      } else {
        path2.lineTo(x, y);
      }
    }

    paint.color = secondaryColor.withOpacity(0.4);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(_SpiralPainter old) => progress != old.progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// SUB-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _GlowDisc extends StatelessWidget {
  final double size;
  final List<Color> colors;
  const _GlowDisc({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors.length >= 3
        ? colors
        : [...colors, const Color(0x00000000)];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: c, stops: const [0.0, 0.5, 1.0]),
      ),
    );
  }
}

class _AuraPulse extends StatelessWidget {
  final double size;
  final Color color;
  final double value;
  const _AuraPulse({
    required this.size,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scale = 0.9 + 0.15 * math.sin(value * math.pi);
    final opacity = 0.15 + 0.20 * math.sin(value * math.pi);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size * 1.1,
        height: size * 1.1,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity), Colors.transparent],
            stops: const [0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

class _RingLayer extends StatelessWidget {
  final double size;
  final List<Color> colors;
  final bool isDiamond;
  final double strokeWidth;
  final bool dashed;

  const _RingLayer({
    required this.size,
    required this.colors,
    required this.isDiamond,
    this.strokeWidth = 2.0,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RingPainter(
        colors: colors,
        isDiamond: isDiamond,
        strokeWidth: strokeWidth,
        dashed: dashed,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final List<Color> colors;
  final bool isDiamond;
  final double strokeWidth;
  final bool dashed;

  _RingPainter({
    required this.colors,
    required this.isDiamond,
    required this.strokeWidth,
    required this.dashed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        colors: [...colors, colors.first],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    if (isDiamond && !dashed) {
      final path = Path();
      for (int i = 0; i < 8; i++) {
        final angle = (i / 8) * math.pi * 2 - math.pi / 8;
        final p = Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    } else if (dashed) {
      _drawDashed(canvas, center, radius, paint);
    } else {
      canvas.drawCircle(center, radius, paint);
    }
  }

  void _drawDashed(Canvas canvas, Offset center, double radius, Paint paint) {
    const dashCount = 20;
    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 0) continue;
      final startAngle = (i / dashCount) * math.pi * 2;
      final sweepAngle = math.pi * 2 / dashCount;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      isDiamond != old.isDiamond ||
      dashed != old.dashed ||
      strokeWidth != old.strokeWidth;
}
