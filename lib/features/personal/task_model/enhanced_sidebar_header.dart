// lib/features/personal/task_model/enhanced_sidebar_header.dart

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ================================================================
// CINEMATIC OCEAN SCENE - MAIN WIDGET
// ================================================================

class CinematicOceanScene extends StatefulWidget {
  final double height;
  final double width;

  const CinematicOceanScene({super.key, this.height = 280, this.width = 280});

  @override
  State<CinematicOceanScene> createState() => _CinematicOceanSceneState();
}

class _CinematicOceanSceneState extends State<CinematicOceanScene>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _waveController;
  late AnimationController _cloudController;
  late AnimationController _boatController;
  late AnimationController _celestialController;
  late AnimationController _starTwinkleController;
  late AnimationController _birdController;
  late AnimationController _sparkleController;
  late AnimationController _reflectionController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 80),
    )..repeat();

    _boatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _celestialController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _starTwinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _birdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _reflectionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _cloudController.dispose();
    _boatController.dispose();
    _celestialController.dispose();
    _starTwinkleController.dispose();
    _birdController.dispose();
    _sparkleController.dispose();
    _reflectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF1a1a2e) : const Color(0xFF4a90c2))
                .withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _waveController,
            _cloudController,
            _boatController,
            _celestialController,
            _starTwinkleController,
            _birdController,
            _sparkleController,
            _reflectionController,
          ]),
          builder: (context, child) {
            return CustomPaint(
              painter: _UltraRealisticOceanPainter(
                wavePhase: _waveController.value * math.pi * 2,
                cloudPhase: _cloudController.value,
                boatPhase: _boatController.value,
                celestialPhase: _celestialController.value,
                starTwinkle: _starTwinkleController.value,
                birdPhase: _birdController.value,
                sparklePhase: _sparkleController.value,
                reflectionPhase: _reflectionController.value,
                isDark: isDark,
              ),
              size: Size(widget.width, widget.height),
            );
          },
        ),
      ),
    );
  }
}

// ================================================================
// ULTRA REALISTIC OCEAN PAINTER
// ================================================================

class _UltraRealisticOceanPainter extends CustomPainter {
  final double wavePhase;
  final double cloudPhase;
  final double boatPhase;
  final double celestialPhase;
  final double starTwinkle;
  final double birdPhase;
  final double sparklePhase;
  final double reflectionPhase;
  final bool isDark;

  // Pre-generated stars for night sky
  static final List<_Star> _stars = List.generate(
    120,
    (i) => _Star(
      x: math.Random(i).nextDouble(),
      y: math.Random(i + 100).nextDouble() * 0.45,
      size: math.Random(i + 200).nextDouble() * 2 + 0.5,
      twinkleOffset: math.Random(i + 300).nextDouble() * math.pi * 2,
      brightness: math.Random(i + 400).nextDouble() * 0.6 + 0.4,
      color: _getStarColor(math.Random(i + 500).nextDouble()),
    ),
  );

  // Pre-generated birds
  static final List<_Bird> _birds = List.generate(
    8,
    (i) => _Bird(
      startX: math.Random(i + 600).nextDouble() * 0.3,
      y: math.Random(i + 700).nextDouble() * 0.25 + 0.08,
      speed: math.Random(i + 800).nextDouble() * 0.3 + 0.5,
      size: math.Random(i + 900).nextDouble() * 0.4 + 0.6,
      wingOffset: math.Random(i + 1000).nextDouble() * math.pi * 2,
    ),
  );

  // Water sparkles
  static final List<_Sparkle> _sparkles = List.generate(
    25,
    (i) => _Sparkle(
      x: math.Random(i + 1100).nextDouble(),
      y: math.Random(i + 1200).nextDouble() * 0.4 + 0.55,
      size: math.Random(i + 1300).nextDouble() * 2 + 1,
      offset: math.Random(i + 1400).nextDouble() * math.pi * 2,
    ),
  );

  static Color _getStarColor(double random) {
    if (random < 0.6) return Colors.white;
    if (random < 0.75) return const Color(0xFFfff8e8);
    if (random < 0.85) return const Color(0xFFe8f0ff);
    if (random < 0.95) return const Color(0xFFffe8e8);
    return const Color(0xFFe8ffff);
  }

  _UltraRealisticOceanPainter({
    required this.wavePhase,
    required this.cloudPhase,
    required this.boatPhase,
    required this.celestialPhase,
    required this.starTwinkle,
    required this.birdPhase,
    required this.sparklePhase,
    required this.reflectionPhase,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Paint layers in order (back to front)
    _paintSky(canvas, size);

    if (isDark) {
      _paintStars(canvas, size);
      _paintMoon(canvas, size);
      _paintMoonGlow(canvas, size);
    } else {
      _paintSun(canvas, size);
      _paintSunRays(canvas, size);
      _paintClouds(canvas, size);
      _paintBirds(canvas, size);
    }

    _paintDistantMountains(canvas, size);
    _paintMidMountains(canvas, size);
    _paintNearMountains(canvas, size);
    _paintOcean(canvas, size);
    _paintWaves(canvas, size);
    _paintWaterReflections(canvas, size);

    if (!isDark) {
      _paintWaterSparkles(canvas, size);
    }

    _paintBoat(canvas, size);
    _paintBoatReflection(canvas, size);
    _paintAtmosphericEffects(canvas, size);
    _paintVignette(canvas, size);
  }

  // ================================================================
  // SKY
  // ================================================================

  void _paintSky(Canvas canvas, Size size) {
    final skyRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.58);

    List<Color> skyColors;

    if (isDark) {
      // Beautiful night sky gradient
      skyColors = [
        const Color(0xFF0a0a18),
        const Color(0xFF0f1028),
        const Color(0xFF151540),
        const Color(0xFF1a1a50),
        const Color(0xFF1e2060),
      ];
    } else {
      // Stunning day sky gradient
      skyColors = [
        const Color(0xFF1565C0),
        const Color(0xFF1E88E5),
        const Color(0xFF42A5F5),
        const Color(0xFF64B5F6),
        const Color(0xFF90CAF9),
      ];
    }

    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: skyColors,
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );

    canvas.drawRect(
      skyRect,
      Paint()..shader = skyGradient.createShader(skyRect),
    );

    // Add subtle color at horizon
    final horizonGlow = Rect.fromLTWH(
      0,
      size.height * 0.4,
      size.width,
      size.height * 0.2,
    );
    final horizonGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [Colors.transparent, const Color(0xFF2a2a5a).withOpacity(0.3)]
          : [Colors.transparent, const Color(0xFFffe4c4).withOpacity(0.2)],
    );
    canvas.drawRect(
      horizonGlow,
      Paint()..shader = horizonGradient.createShader(horizonGlow),
    );
  }

  // ================================================================
  // STARS (Night Mode)
  // ================================================================

  void _paintStars(Canvas canvas, Size size) {
    for (final star in _stars) {
      final twinkle = math.sin(starTwinkle * math.pi * 2 + star.twinkleOffset);
      final brightness = star.brightness * (0.6 + twinkle * 0.4);

      if (brightness <= 0.1) continue;

      final starX = star.x * size.width;
      final starY = star.y * size.height;

      // Star glow
      canvas.drawCircle(
        Offset(starX, starY),
        star.size * 3,
        Paint()
          ..color = star.color.withOpacity(brightness * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Star core with twinkle
      final coreSize = star.size * (0.8 + twinkle * 0.3);
      canvas.drawCircle(
        Offset(starX, starY),
        coreSize,
        Paint()..color = star.color.withOpacity(brightness),
      );

      // Cross sparkle for bright stars
      if (star.brightness > 0.8 && twinkle > 0.3) {
        final sparklePaint = Paint()
          ..color = star.color.withOpacity(brightness * 0.5)
          ..strokeWidth = 0.5
          ..strokeCap = StrokeCap.round;

        final sparkleLength = star.size * 2 * twinkle;
        canvas.drawLine(
          Offset(starX - sparkleLength, starY),
          Offset(starX + sparkleLength, starY),
          sparklePaint,
        );
        canvas.drawLine(
          Offset(starX, starY - sparkleLength),
          Offset(starX, starY + sparkleLength),
          sparklePaint,
        );
      }
    }

    // Milky way effect
    _paintMilkyWay(canvas, size);
  }

  void _paintMilkyWay(Canvas canvas, Size size) {
    final milkyWayPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    final path = Path();
    path.moveTo(0, size.height * 0.1);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.05,
      size.width * 0.5,
      size.height * 0.15,
    );
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.25,
      size.width,
      size.height * 0.2,
    );
    path.lineTo(size.width, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.35,
      size.width * 0.4,
      size.height * 0.25,
    );
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.15,
      0,
      size.height * 0.2,
    );
    path.close();

    canvas.drawPath(path, milkyWayPaint);
  }

  // ================================================================
  // MOON (Night Mode)
  // ================================================================

  void _paintMoon(Canvas canvas, Size size) {
    final moonX = size.width * 0.78;
    final moonY = size.height * 0.18;
    final moonRadius = size.width * 0.08;

    // Outer glow layers
    for (int i = 6; i >= 0; i--) {
      canvas.drawCircle(
        Offset(moonX, moonY),
        moonRadius * (1 + i * 0.35),
        Paint()
          ..color = const Color(0xFFe8eeff).withOpacity(0.04 - i * 0.005)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            moonRadius * 0.25 * i,
          ),
      );
    }

    // Moon body gradient
    final moonGradient = RadialGradient(
      center: const Alignment(-0.4, -0.4),
      radius: 1.0,
      colors: [
        const Color(0xFFffffff),
        const Color(0xFFf8f8ff),
        const Color(0xFFe8e8f0),
        const Color(0xFFd8d8e8),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    canvas.drawCircle(
      Offset(moonX, moonY),
      moonRadius,
      Paint()
        ..shader = moonGradient.createShader(
          Rect.fromCircle(center: Offset(moonX, moonY), radius: moonRadius),
        ),
    );

    // Moon craters
    _paintMoonDetails(canvas, Offset(moonX, moonY), moonRadius);
  }

  void _paintMoonDetails(Canvas canvas, Offset center, double radius) {
    final craterPaint = Paint()
      ..color = const Color(0xFFc8c8d8).withOpacity(0.4);

    final craters = [
      _Crater(-0.25, -0.3, 0.15),
      _Crater(0.3, 0.15, 0.12),
      _Crater(-0.1, 0.25, 0.1),
      _Crater(0.2, -0.25, 0.08),
      _Crater(-0.35, 0.1, 0.07),
      _Crater(0.15, 0.35, 0.06),
    ];

    for (final crater in craters) {
      canvas.drawCircle(
        Offset(center.dx + crater.x * radius, center.dy + crater.y * radius),
        radius * crater.size,
        craterPaint,
      );
    }

    // Mare (dark patches)
    final marePaint = Paint()
      ..color = const Color(0xFFb0b0c0).withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - radius * 0.15, center.dy - radius * 0.1),
        width: radius * 0.5,
        height: radius * 0.35,
      ),
      marePaint,
    );
  }

  void _paintMoonGlow(Canvas canvas, Size size) {
    final moonX = size.width * 0.78;
    final moonY = size.height * 0.18;

    // Atmospheric glow around moon
    final glowGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        const Color(0xFFc8d8ff).withOpacity(0.08),
        const Color(0xFFa0b8ff).withOpacity(0.03),
        Colors.transparent,
      ],
    );

    canvas.drawCircle(
      Offset(moonX, moonY),
      size.width * 0.25,
      Paint()
        ..shader = glowGradient.createShader(
          Rect.fromCircle(
            center: Offset(moonX, moonY),
            radius: size.width * 0.25,
          ),
        ),
    );
  }

  // ================================================================
  // SUN (Day Mode)
  // ================================================================

  void _paintSun(Canvas canvas, Size size) {
    final sunX = size.width * 0.75;
    final sunY = size.height * 0.2;
    final sunRadius = size.width * 0.07;

    // Outer glow layers - CHANGE THESE COLORS
    for (int i = 8; i >= 0; i--) {
      final glowRadius = sunRadius * (1 + i * 0.6);
      canvas.drawCircle(
        Offset(sunX, sunY),
        glowRadius,
        Paint()
          ..color = const Color(0xFFff6040)
              .withOpacity(0.08 - i * 0.008) // Changed to red-orange
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius * 0.4),
      );
    }

    // Sun body gradient - CHANGE THESE COLORS
    final sunGradient = RadialGradient(
      center: const Alignment(-0.2, -0.2),
      radius: 1.0,
      colors: [
        const Color(0xFFfffef0), // Center - keep white/cream
        const Color(0xFFffe0a0), // Inner - warm yellow
        const Color(0xFFff8c40), // Middle - orange
        const Color(0xFFff4020), // Edge - RED
      ],
      stops: const [0.0, 0.3, 0.6, 1.0],
    );

    canvas.drawCircle(
      Offset(sunX, sunY),
      sunRadius,
      Paint()
        ..shader = sunGradient.createShader(
          Rect.fromCircle(center: Offset(sunX, sunY), radius: sunRadius),
        ),
    );

    // Corona effect - CHANGE THIS COLOR
    canvas.drawCircle(
      Offset(sunX, sunY),
      sunRadius * 1.15,
      Paint()
        ..color = const Color(0xFFff6030)
            .withOpacity(0.4) // Changed to red-orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void _paintSunRays(Canvas canvas, Size size) {
    final sunX = size.width * 0.75;
    final sunY = size.height * 0.2;
    final sunRadius = size.width * 0.07;

    final rayPaint = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * math.pi * 2 + celestialPhase * math.pi * 0.5;
      final rayLength =
          sunRadius * (1.8 + math.sin(wavePhase * 2 + i * 0.5) * 0.4);
      final opacity = 0.15 + math.sin(wavePhase + i * 0.3) * 0.05;

      final startPoint = Offset(
        sunX + math.cos(angle) * sunRadius * 1.3,
        sunY + math.sin(angle) * sunRadius * 1.3,
      );
      final endPoint = Offset(
        sunX + math.cos(angle) * rayLength,
        sunY + math.sin(angle) * rayLength,
      );

      rayPaint.shader = ui.Gradient.linear(startPoint, endPoint, [
        const Color(0xFFff6040).withOpacity(opacity), // Changed to red-orange
        Colors.transparent,
      ]);

      canvas.drawLine(startPoint, endPoint, rayPaint);
    }
  }

  // ================================================================
  // CLOUDS (Day Mode)
  // ================================================================

  void _paintClouds(Canvas canvas, Size size) {
    final cloudConfigs = [
      _CloudConfig(0.15, 0.12, 0.35, 0.7),
      _CloudConfig(0.55, 0.08, 0.4, 0.8),
      _CloudConfig(0.85, 0.15, 0.3, 0.6),
      _CloudConfig(0.35, 0.22, 0.25, 0.5),
    ];

    for (final config in cloudConfigs) {
      final xOffset = ((cloudPhase * config.speed + config.baseX) % 1.4) - 0.2;
      _paintCloud(
        canvas,
        size,
        xOffset * size.width,
        size.height * config.y,
        size.width * config.scale,
      );
    }
  }

  void _paintCloud(Canvas canvas, Size size, double x, double y, double width) {
    final height = width * 0.4;

    // Cloud parts for fluffy appearance
    final cloudParts = [
      _CloudPart(0.0, 0.1, 0.45, 0.7),
      _CloudPart(0.2, -0.1, 0.5, 0.8),
      _CloudPart(0.45, 0.0, 0.55, 0.85),
      _CloudPart(0.7, -0.05, 0.4, 0.65),
      _CloudPart(0.35, -0.2, 0.35, 0.5),
      _CloudPart(0.55, -0.15, 0.3, 0.45),
    ];

    // Shadow layer
    for (final part in cloudParts) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            x + width * part.xOffset,
            y + height * (part.yOffset + 0.15),
          ),
          width: width * part.widthRatio,
          height: height * part.heightRatio,
        ),
        Paint()
          ..color = const Color(0xFF8090a0).withOpacity(0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
      );
    }

    // Main cloud body
    for (final part in cloudParts) {
      final cloudGradient = RadialGradient(
        center: const Alignment(-0.3, -0.5),
        radius: 1.0,
        colors: [
          Colors.white.withOpacity(0.95),
          Colors.white.withOpacity(0.85),
          const Color(0xFFf0f4f8).withOpacity(0.75),
        ],
      );

      final rect = Rect.fromCenter(
        center: Offset(x + width * part.xOffset, y + height * part.yOffset),
        width: width * part.widthRatio,
        height: height * part.heightRatio,
      );

      canvas.drawOval(
        rect,
        Paint()
          ..shader = cloudGradient.createShader(rect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  // ================================================================
  // BIRDS (Day Mode)
  // ================================================================

  void _paintBirds(Canvas canvas, Size size) {
    for (final bird in _birds) {
      final x = ((birdPhase * bird.speed + bird.startX) % 1.3) - 0.15;
      if (x < -0.1 || x > 1.1) continue;

      final birdX = x * size.width;
      final birdY =
          bird.y * size.height +
          math.sin(birdPhase * math.pi * 4 + bird.wingOffset) * 3;
      final wingAngle =
          math.sin(birdPhase * math.pi * 8 + bird.wingOffset) * 0.4;
      final birdSize = 4 * bird.size;

      _paintBird(canvas, birdX, birdY, birdSize, wingAngle);
    }
  }

  void _paintBird(
    Canvas canvas,
    double x,
    double y,
    double size,
    double wingAngle,
  ) {
    final birdColor = isDark
        ? const Color(0xFF2a2a3a)
        : const Color(0xFF3a4050);
    final paint = Paint()
      ..color = birdColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Left wing
    final leftWingPath = Path();
    leftWingPath.moveTo(x, y);
    leftWingPath.quadraticBezierTo(
      x - size * 0.7,
      y - size * (0.3 + wingAngle),
      x - size,
      y + size * 0.2 * wingAngle,
    );

    // Right wing
    final rightWingPath = Path();
    rightWingPath.moveTo(x, y);
    rightWingPath.quadraticBezierTo(
      x + size * 0.7,
      y - size * (0.3 + wingAngle),
      x + size,
      y + size * 0.2 * wingAngle,
    );

    canvas.drawPath(leftWingPath, paint);
    canvas.drawPath(rightWingPath, paint);
  }

  // ================================================================
  // MOUNTAINS
  // ================================================================

  void _paintDistantMountains(Canvas canvas, Size size) {
    final horizonY = size.height * 0.52;
    final color = isDark
        ? const Color(0xFF1a1a35).withOpacity(0.6)
        : const Color(0xFF7090b0).withOpacity(0.4);

    _paintMountainLayer(
      canvas,
      size,
      horizonY,
      color,
      [0.0, 0.15, 0.35, 0.5, 0.7, 0.85, 1.0],
      [0.04, 0.1, 0.07, 0.12, 0.08, 0.11, 0.05],
      blur: 15,
    );
  }

  void _paintMidMountains(Canvas canvas, Size size) {
    final horizonY = size.height * 0.52;
    final color = isDark
        ? const Color(0xFF252545).withOpacity(0.7)
        : const Color(0xFF5a7a9a).withOpacity(0.5);

    _paintMountainLayer(
      canvas,
      size,
      horizonY,
      color,
      [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
      [0.02, 0.07, 0.05, 0.09, 0.06, 0.03],
      blur: 8,
      addSnow: !isDark,
    );
  }

  void _paintNearMountains(Canvas canvas, Size size) {
    final horizonY = size.height * 0.52;
    final color = isDark
        ? const Color(0xFF1a1a30).withOpacity(0.85)
        : const Color(0xFF4a6a8a).withOpacity(0.6);

    _paintMountainLayer(
      canvas,
      size,
      horizonY,
      color,
      [0.0, 0.25, 0.5, 0.75, 1.0],
      [0.01, 0.04, 0.03, 0.05, 0.015],
      blur: 2,
      addTrees: true,
    );
  }

  void _paintMountainLayer(
    Canvas canvas,
    Size size,
    double horizonY,
    Color color,
    List<double> peakPositions,
    List<double> peakHeights, {
    double blur = 0,
    bool addSnow = false,
    bool addTrees = false,
  }) {
    final path = Path();
    path.moveTo(0, horizonY);

    List<Offset> peaks = [];

    for (int i = 0; i < peakPositions.length; i++) {
      final peakX = size.width * peakPositions[i];
      final peakY = horizonY - (size.height * peakHeights[i]);
      peaks.add(Offset(peakX, peakY));

      if (i == 0) {
        path.lineTo(peakX, peakY);
      } else {
        final prevPeak = peaks[i - 1];
        final controlX = (prevPeak.dx + peakX) / 2;
        final minY = math.min(prevPeak.dy, peakY);
        final controlY = minY + (horizonY - minY) * 0.4;
        path.quadraticBezierTo(controlX, controlY, peakX, peakY);
      }
    }

    path.lineTo(size.width, horizonY);
    path.lineTo(size.width, horizonY + 10);
    path.lineTo(0, horizonY + 10);
    path.close();

    final paint = Paint()..color = color;
    if (blur > 0) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    }

    canvas.drawPath(path, paint);

    // Snow caps
    if (addSnow) {
      for (int i = 1; i < peaks.length - 1; i++) {
        if (peakHeights[i] > 0.05) {
          _paintSnowCap(canvas, peaks[i], size.height * peakHeights[i] * 0.35);
        }
      }
    }

    // Tree line
    if (addTrees && !isDark) {
      _paintTreeLine(canvas, path, horizonY, size);
    }
  }

  void _paintSnowCap(Canvas canvas, Offset peak, double height) {
    final snowPath = Path();
    snowPath.moveTo(peak.dx, peak.dy);
    snowPath.lineTo(peak.dx - height * 0.5, peak.dy + height * 0.8);
    snowPath.quadraticBezierTo(
      peak.dx,
      peak.dy + height * 0.6,
      peak.dx + height * 0.5,
      peak.dy + height * 0.8,
    );
    snowPath.close();

    final snowGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.5)],
    );

    canvas.drawPath(
      snowPath,
      Paint()
        ..shader = snowGradient.createShader(
          Rect.fromLTWH(peak.dx - height * 0.5, peak.dy, height, height * 0.8),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );
  }

  void _paintTreeLine(
    Canvas canvas,
    Path mountainPath,
    double horizonY,
    Size size,
  ) {
    final treePaint = Paint()
      ..color = const Color(0xFF2a4a3a).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (double x = 0; x < size.width; x += 8) {
      final treeHeight = 3 + math.sin(x * 0.1) * 1.5;
      final treeY = horizonY - 2;

      canvas.drawLine(
        Offset(x, treeY),
        Offset(x, treeY - treeHeight),
        treePaint..strokeWidth = 1,
      );
    }
  }

  // ================================================================
  // OCEAN
  // ================================================================

  void _paintOcean(Canvas canvas, Size size) {
    final oceanTop = size.height * 0.52;
    final oceanRect = Rect.fromLTWH(
      0,
      oceanTop,
      size.width,
      size.height - oceanTop,
    );

    List<Color> oceanColors;

    if (isDark) {
      // Deep night ocean colors
      oceanColors = [
        const Color(0xFF0a1525),
        const Color(0xFF0c1a30),
        const Color(0xFF081420),
        const Color(0xFF061018),
        const Color(0xFF040a10),
      ];
    } else {
      // Beautiful day ocean colors
      oceanColors = [
        const Color(0xFF1976D2),
        const Color(0xFF1565C0),
        const Color(0xFF0D47A1),
        const Color(0xFF0a3d8f),
        const Color(0xFF082a70),
      ];
    }

    final oceanGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: oceanColors,
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );

    canvas.drawRect(
      oceanRect,
      Paint()..shader = oceanGradient.createShader(oceanRect),
    );
  }

  // ================================================================
  // WAVES
  // ================================================================

  void _paintWaves(Canvas canvas, Size size) {
    final oceanTop = size.height * 0.52;
    final oceanHeight = size.height - oceanTop;

    final waveConfigs = [
      _WaveConfig(0.0, 2, 4, 1.0, isDark ? 0.25 : 0.35),
      _WaveConfig(0.08, 2.5, 3.5, 0.85, isDark ? 0.22 : 0.32),
      _WaveConfig(0.16, 3, 3, 0.7, isDark ? 0.2 : 0.28),
      _WaveConfig(0.26, 3.5, 2.5, 0.6, isDark ? 0.18 : 0.25),
      _WaveConfig(0.38, 4, 2, 0.5, isDark ? 0.15 : 0.22),
      _WaveConfig(0.52, 4.5, 1.8, 0.4, isDark ? 0.12 : 0.18),
      _WaveConfig(0.68, 5, 1.5, 0.35, isDark ? 0.1 : 0.15),
      _WaveConfig(0.85, 5.5, 1.2, 0.3, isDark ? 0.08 : 0.12),
    ];

    for (final config in waveConfigs) {
      _paintWaveLayer(canvas, size, oceanTop, oceanHeight, config);
    }
  }

  void _paintWaveLayer(
    Canvas canvas,
    Size size,
    double oceanTop,
    double oceanHeight,
    _WaveConfig config,
  ) {
    final y = oceanTop + oceanHeight * config.yOffset;

    final waveColor = isDark
        ? const Color(0xFF4080c0)
        : const Color(0xFF90caf9);

    final path = Path();

    for (double x = 0; x <= size.width + 4; x += 3) {
      final phase = wavePhase * config.speed;
      final primaryWave = math.sin(
        (x / size.width * math.pi * config.frequency * 2) + phase,
      );
      final secondaryWave =
          math.sin(
            (x / size.width * math.pi * config.frequency) + phase * 0.7,
          ) *
          0.5;
      final tertiaryWave =
          math.sin(
            (x / size.width * math.pi * config.frequency * 3) + phase * 1.3,
          ) *
          0.25;

      final waveY =
          y + (primaryWave + secondaryWave + tertiaryWave) * config.amplitude;

      if (x == 0) {
        path.moveTo(x, waveY);
      } else {
        path.lineTo(x, waveY);
      }
    }

    // Wave line
    canvas.drawPath(
      path,
      Paint()
        ..color = waveColor.withOpacity(config.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // Foam on wave crests (for closer waves)
    if (config.yOffset < 0.3) {
      _paintWaveFoam(canvas, size, y, config);
    }
  }

  void _paintWaveFoam(Canvas canvas, Size size, double y, _WaveConfig config) {
    final foamPaint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.08 : 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (double x = 0; x < size.width; x += 35) {
      final phase = wavePhase * config.speed;
      final waveY =
          y +
          math.sin((x / size.width * math.pi * config.frequency * 2) + phase) *
              config.amplitude;

      if (math.sin((x / size.width * math.pi * config.frequency * 2) + phase) >
          0.5) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x + math.sin(wavePhase + x * 0.1) * 5, waveY - 1),
            width: 18 + math.sin(wavePhase + x) * 4,
            height: 3,
          ),
          foamPaint,
        );
      }
    }
  }

  // ================================================================
  // WATER REFLECTIONS
  // ================================================================

  void _paintWaterReflections(Canvas canvas, Size size) {
    final oceanTop = size.height * 0.52;

    if (isDark) {
      _paintMoonReflection(canvas, size, oceanTop);
    } else {
      _paintSunReflection(canvas, size, oceanTop);
    }
  }

  void _paintSunReflection(Canvas canvas, Size size, double oceanTop) {
    final sunX = size.width * 0.75;

    // Main sun reflection column
    for (int i = 0; i < 12; i++) {
      final y = oceanTop + 8 + i * 10;
      final width = 30.0 - i * 1.5;
      final offset =
          math.sin(reflectionPhase * math.pi * 2 + i * 0.4) * (6 + i * 0.5);
      final opacity = 0.25 - i * 0.018;

      if (opacity <= 0) continue;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(sunX + offset, y),
          width: width,
          height: 4,
        ),
        Paint()
          ..color = const Color(0xFFff8060)
              .withOpacity(opacity) // Changed to red-orange
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Shimmer highlights
    for (int i = 0; i < 6; i++) {
      final shimmerX =
          sunX + math.sin(reflectionPhase * math.pi * 4 + i * 1.2) * 25;
      final shimmerY = oceanTop + 15 + i * 18;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(shimmerX, shimmerY),
          width: 8,
          height: 2,
        ),
        Paint()
          ..color = const Color(
            0xFFffaa80,
          ).withOpacity(0.3 - i * 0.04), // Changed
      );
    }
  }

  void _paintMoonReflection(Canvas canvas, Size size, double oceanTop) {
    final moonX = size.width * 0.78;

    // Moon reflection column
    for (int i = 0; i < 10; i++) {
      final y = oceanTop + 10 + i * 12;
      final width = 25.0 - i * 1.5;
      final offset =
          math.sin(reflectionPhase * math.pi * 2 + i * 0.5) * (8 + i * 0.8);
      final opacity = 0.18 - i * 0.015;

      if (opacity <= 0) continue;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(moonX + offset, y),
          width: width,
          height: 3,
        ),
        Paint()
          ..color = const Color(0xFFc8d8ff).withOpacity(opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // Subtle shimmer
    for (int i = 0; i < 4; i++) {
      final shimmerX =
          moonX + math.sin(reflectionPhase * math.pi * 3 + i * 1.5) * 20;
      final shimmerY = oceanTop + 20 + i * 25;

      canvas.drawCircle(
        Offset(shimmerX, shimmerY),
        2,
        Paint()..color = Colors.white.withOpacity(0.15 - i * 0.03),
      );
    }
  }

  // ================================================================
  // WATER SPARKLES (Day Mode)
  // ================================================================

  void _paintWaterSparkles(Canvas canvas, Size size) {
    for (final sparkle in _sparkles) {
      final sparkleIntensity = math.sin(
        sparklePhase * math.pi * 2 + sparkle.offset,
      );

      if (sparkleIntensity < 0.3) continue;

      final sparkleX = sparkle.x * size.width;
      final sparkleY =
          sparkle.y * size.height + math.sin(wavePhase + sparkle.offset) * 2;
      final opacity = sparkleIntensity * 0.6;

      // Sparkle glow
      canvas.drawCircle(
        Offset(sparkleX, sparkleY),
        sparkle.size * 2,
        Paint()
          ..color = Colors.white.withOpacity(opacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );

      // Sparkle core
      canvas.drawCircle(
        Offset(sparkleX, sparkleY),
        sparkle.size * 0.8,
        Paint()..color = Colors.white.withOpacity(opacity),
      );

      // Cross sparkle
      if (sparkleIntensity > 0.7) {
        final crossSize = sparkle.size * 1.5;
        final crossPaint = Paint()
          ..color = Colors.white.withOpacity(opacity * 0.5)
          ..strokeWidth = 0.5
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(
          Offset(sparkleX - crossSize, sparkleY),
          Offset(sparkleX + crossSize, sparkleY),
          crossPaint,
        );
        canvas.drawLine(
          Offset(sparkleX, sparkleY - crossSize),
          Offset(sparkleX, sparkleY + crossSize),
          crossPaint,
        );
      }
    }
  }

  // ================================================================
  // BOAT
  // ================================================================

  void _paintBoat(Canvas canvas, Size size) {
    final oceanTop = size.height * 0.52;
    final boatX = size.width * 0.38 + math.sin(boatPhase * math.pi) * 4;
    final boatY = oceanTop + 28 + math.sin(wavePhase * 0.8) * 2.5;
    final boatRock =
        math.sin(boatPhase * math.pi * 2) * 0.05 +
        math.sin(wavePhase * 0.6) * 0.02;

    canvas.save();
    canvas.translate(boatX, boatY);
    canvas.rotate(boatRock);

    final boatScale = size.width / 280;

    // Shadow on water
    _paintBoatShadow(canvas, boatScale);

    // Hull
    _paintHull(canvas, boatScale);

    // Cabin
    _paintCabin(canvas, boatScale);

    // Mast and rigging
    _paintMast(canvas, boatScale);

    // Sails
    _paintSails(canvas, boatScale);

    // Flag
    _paintFlag(canvas, boatScale);

    // Details
    _paintBoatDetails(canvas, boatScale);

    canvas.restore();

    // Wake
    _paintWake(canvas, boatX, boatY, size);
  }

  void _paintBoatShadow(Canvas canvas, double scale) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(2 * scale, 14 * scale),
        width: 55 * scale,
        height: 10 * scale,
      ),
      Paint()
        ..color = Colors.black.withOpacity(isDark ? 0.3 : 0.15)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * scale),
    );
  }

  void _paintHull(Canvas canvas, double scale) {
    final hullPath = Path();
    final hullWidth = 55 * scale;
    final hullHeight = 14 * scale;

    hullPath.moveTo(-hullWidth / 2, 0);
    hullPath.quadraticBezierTo(
      -hullWidth / 2 - 5 * scale,
      hullHeight * 0.45,
      -hullWidth / 2 + 8 * scale,
      hullHeight,
    );
    hullPath.lineTo(hullWidth / 2 - 8 * scale, hullHeight);
    hullPath.quadraticBezierTo(
      hullWidth / 2 + 10 * scale,
      hullHeight * 0.5,
      hullWidth / 2 + 5 * scale,
      0,
    );
    hullPath.close();

    // Hull gradient
    final hullGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [
              const Color(0xFF3a3a4a),
              const Color(0xFF2a2a35),
              const Color(0xFF1a1a25),
            ]
          : [
              const Color(0xFF6a5040),
              const Color(0xFF5a4030),
              const Color(0xFF4a3020),
            ],
    );

    canvas.drawPath(
      hullPath,
      Paint()
        ..shader = hullGradient.createShader(
          Rect.fromLTWH(-hullWidth / 2, 0, hullWidth, hullHeight),
        ),
    );

    // Hull highlight
    canvas.drawPath(
      hullPath,
      Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * scale,
    );

    // Decorative stripe
    final stripePaint = Paint()
      ..color = isDark
          ? const Color(0xFF5a5a6a).withOpacity(0.6)
          : const Color(0xFFc4a882).withOpacity(0.7)
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(-hullWidth / 2 + 8 * scale, hullHeight * 0.5),
      Offset(hullWidth / 2 - 3 * scale, hullHeight * 0.5),
      stripePaint,
    );
  }

  void _paintCabin(Canvas canvas, double scale) {
    final cabinRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(-6 * scale, -5 * scale),
        width: 18 * scale,
        height: 10 * scale,
      ),
      Radius.circular(3 * scale),
    );

    final cabinGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [const Color(0xFF2a2a35), const Color(0xFF1a1a25)]
          : [const Color(0xFF5a4030), const Color(0xFF4a3020)],
    );

    canvas.drawRRect(
      cabinRect,
      Paint()..shader = cabinGradient.createShader(cabinRect.outerRect),
    );

    // Roof
    final roofPath = Path();
    roofPath.moveTo(-15 * scale, -5 * scale);
    roofPath.lineTo(-6 * scale, -12 * scale);
    roofPath.lineTo(3 * scale, -5 * scale);
    roofPath.close();

    canvas.drawPath(
      roofPath,
      Paint()
        ..color = isDark ? const Color(0xFF3a3a45) : const Color(0xFF6a5040),
    );

    // Windows with warm light at night
    final windowPositions = [-10 * scale, -6 * scale, -2 * scale];
    for (final wx in windowPositions) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(wx, -4 * scale),
            width: 3 * scale,
            height: 4 * scale,
          ),
          Radius.circular(0.5 * scale),
        ),
        Paint()
          ..color = isDark
              ? const Color(0xFFffaa40).withOpacity(0.7)
              : const Color(0xFF80d0ff).withOpacity(0.4),
      );
    }

    // Window glow at night
    if (isDark) {
      for (final wx in windowPositions) {
        canvas.drawCircle(
          Offset(wx, -4 * scale),
          4 * scale,
          Paint()
            ..color = const Color(0xFFffaa40).withOpacity(0.15)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale),
        );
      }
    }
  }

  void _paintMast(Canvas canvas, double scale) {
    // Main mast
    final mastPaint = Paint()
      ..color = isDark ? const Color(0xFF4a4a55) : const Color(0xFF6a5a4a)
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(8 * scale, 2 * scale),
      Offset(8 * scale, -50 * scale),
      mastPaint,
    );

    // Cross beam
    canvas.drawLine(
      Offset(-5 * scale, -40 * scale),
      Offset(22 * scale, -40 * scale),
      mastPaint..strokeWidth = 2 * scale,
    );

    // Crow's nest
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(8 * scale, -45 * scale),
        width: 8 * scale,
        height: 4 * scale,
      ),
      Paint()
        ..color = isDark ? const Color(0xFF3a3a45) : const Color(0xFF5a4a3a),
    );

    // Rigging
    final riggingPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.2)
      ..strokeWidth = 0.6 * scale;

    canvas.drawLine(
      Offset(8 * scale, -50 * scale),
      Offset(-25 * scale, 2 * scale),
      riggingPaint,
    );
    canvas.drawLine(
      Offset(8 * scale, -50 * scale),
      Offset(30 * scale, 2 * scale),
      riggingPaint,
    );
    canvas.drawLine(
      Offset(8 * scale, -40 * scale),
      Offset(-20 * scale, -5 * scale),
      riggingPaint,
    );
  }

  void _paintSails(Canvas canvas, double scale) {
    final windEffect = math.sin(wavePhase * 0.4) * 5 * scale;

    // Main sail
    final mainSailPath = Path();
    mainSailPath.moveTo(8 * scale, -48 * scale);
    mainSailPath.quadraticBezierTo(
      22 * scale + windEffect,
      -28 * scale,
      18 * scale + windEffect * 0.6,
      -5 * scale,
    );
    mainSailPath.lineTo(8 * scale, -5 * scale);
    mainSailPath.close();

    final sailGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: isDark
          ? [
              const Color(0xFF3a3a48),
              const Color(0xFF4a4a58),
              const Color(0xFF3a3a48),
            ]
          : [
              const Color(0xFFf5f0e8),
              const Color(0xFFfffaf2),
              const Color(0xFFebe6de),
            ],
    );

    canvas.drawPath(
      mainSailPath,
      Paint()
        ..shader = sailGradient.createShader(
          Rect.fromLTWH(8 * scale, -48 * scale, 18 * scale, 43 * scale),
        ),
    );

    // Sail seams
    canvas.drawPath(
      mainSailPath,
      Paint()
        ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5 * scale,
    );

    // Horizontal sail lines
    for (int i = 1; i < 4; i++) {
      final lineY = -48 * scale + i * 11 * scale;
      canvas.drawLine(
        Offset(8 * scale, lineY),
        Offset(14 * scale + windEffect * 0.3, lineY),
        Paint()
          ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.08)
          ..strokeWidth = 0.5 * scale,
      );
    }

    // Jib sail
    final jibPath = Path();
    jibPath.moveTo(8 * scale, -48 * scale);
    jibPath.quadraticBezierTo(
      -8 * scale - windEffect * 0.6,
      -28 * scale,
      -18 * scale - windEffect * 0.4,
      -8 * scale,
    );
    jibPath.lineTo(-22 * scale, 2 * scale);
    jibPath.close();

    canvas.drawPath(
      jibPath,
      Paint()
        ..shader = sailGradient.createShader(
          Rect.fromLTWH(-22 * scale, -48 * scale, 30 * scale, 50 * scale),
        ),
    );

    canvas.drawPath(
      jibPath,
      Paint()
        ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5 * scale,
    );
  }

  void _paintFlag(Canvas canvas, double scale) {
    final flagWave = math.sin(wavePhase * 2.5) * 3 * scale;

    final flagPath = Path();
    flagPath.moveTo(8 * scale, -50 * scale);
    flagPath.quadraticBezierTo(
      16 * scale + flagWave,
      -53 * scale + flagWave * 0.3,
      14 * scale + flagWave * 0.8,
      -46 * scale,
    );
    flagPath.lineTo(8 * scale, -44 * scale);
    flagPath.close();

    // Flag with gradient
    final flagGradient = LinearGradient(
      colors: [const Color(0xFFe04040), const Color(0xFFc03030)],
    );

    canvas.drawPath(
      flagPath,
      Paint()
        ..shader = flagGradient.createShader(
          Rect.fromLTWH(8 * scale, -53 * scale, 10 * scale, 9 * scale),
        ),
    );
  }

  void _paintBoatDetails(Canvas canvas, double scale) {
    // Anchor
    final anchorPaint = Paint()
      ..color = isDark ? const Color(0xFF6a6a7a) : const Color(0xFF7a6a5a)
      ..strokeWidth = 1.5 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(-22 * scale, 4 * scale), 2 * scale, anchorPaint);
    canvas.drawLine(
      Offset(-22 * scale, 6 * scale),
      Offset(-22 * scale, 10 * scale),
      anchorPaint,
    );

    // Portholes
    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset((-12 + i * 9) * scale, 5 * scale),
        1.8 * scale,
        Paint()
          ..color = isDark ? const Color(0xFF1a1a25) : const Color(0xFF3a3030),
      );
      canvas.drawCircle(
        Offset((-12 + i * 9) * scale, 5 * scale),
        1.8 * scale,
        Paint()
          ..color = isDark ? const Color(0xFF4a4a5a) : const Color(0xFF8a7a6a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5 * scale,
      );
    }

    // Helm
    canvas.drawCircle(
      Offset(18 * scale, -2 * scale),
      3 * scale,
      Paint()
        ..color = isDark ? const Color(0xFF5a5a6a) : const Color(0xFF8a6a4a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 * scale,
    );
  }

  void _paintWake(Canvas canvas, double boatX, double boatY, Size size) {
    final wakePaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (int i = 0; i < 6; i++) {
      final wakeX = boatX - 35 - i * 20;
      final wakeY = boatY + 10 + i * 2.5 + math.sin(wavePhase + i * 0.6) * 2;
      final wakeWidth = 28.0 + i * 8;
      final opacity = (isDark ? 0.08 : 0.12) - i * 0.015;

      if (opacity <= 0) continue;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(wakeX, wakeY),
          width: wakeWidth,
          height: 5 + i * 0.8,
        ),
        wakePaint..color = Colors.white.withOpacity(opacity.clamp(0, 1)),
      );
    }
  }

  void _paintBoatReflection(Canvas canvas, Size size) {
    final oceanTop = size.height * 0.52;
    final boatX = size.width * 0.38 + math.sin(boatPhase * math.pi) * 4;
    final reflectionY = oceanTop + 50;

    // Simple blurred reflection
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          boatX,
          reflectionY + math.sin(reflectionPhase * math.pi * 2) * 3,
        ),
        width: 45,
        height: 8,
      ),
      Paint()
        ..color = (isDark ? const Color(0xFF2a2a35) : const Color(0xFF4a3a2a))
            .withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  // ================================================================
  // ATMOSPHERIC EFFECTS
  // ================================================================

  void _paintAtmosphericEffects(Canvas canvas, Size size) {
    final oceanTop = size.height * 0.52;

    // Horizon mist/haze
    final hazeGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [
              Colors.transparent,
              const Color(0xFF1a2030).withOpacity(0.2),
              Colors.transparent,
            ]
          : [
              Colors.transparent,
              const Color(0xFFa0c0e0).withOpacity(0.15),
              Colors.transparent,
            ],
    );

    canvas.drawRect(
      Rect.fromLTWH(0, oceanTop - 20, size.width, 40),
      Paint()
        ..shader = hazeGradient.createShader(
          Rect.fromLTWH(0, oceanTop - 20, size.width, 40),
        ),
    );
  }

  void _paintVignette(Canvas canvas, Size size) {
    // Vignette effect
    final vignetteGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Colors.transparent,
        Colors.black.withOpacity(isDark ? 0.35 : 0.15),
      ],
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = vignetteGradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );

    // Subtle top gradient for integration
    final topGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        (isDark ? const Color(0xFF0a0a15) : const Color(0xFF1a4a7a))
            .withOpacity(0.4),
        Colors.transparent,
      ],
      stops: const [0.0, 0.35],
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.35),
      Paint()
        ..shader = topGradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height * 0.35),
        ),
    );

    // Bottom gradient
    final bottomGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        (isDark ? const Color(0xFF040a10) : const Color(0xFF082a50))
            .withOpacity(0.5),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3],
    );

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3),
      Paint()
        ..shader = bottomGradient.createShader(
          Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _UltraRealisticOceanPainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase ||
        oldDelegate.cloudPhase != cloudPhase ||
        oldDelegate.boatPhase != boatPhase ||
        oldDelegate.celestialPhase != celestialPhase ||
        oldDelegate.starTwinkle != starTwinkle ||
        oldDelegate.birdPhase != birdPhase ||
        oldDelegate.sparklePhase != sparklePhase ||
        oldDelegate.reflectionPhase != reflectionPhase ||
        oldDelegate.isDark != isDark;
  }
}

// ================================================================
// HELPER CLASSES
// ================================================================

class _Star {
  final double x;
  final double y;
  final double size;
  final double twinkleOffset;
  final double brightness;
  final Color color;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.twinkleOffset,
    required this.brightness,
    required this.color,
  });
}

class _Bird {
  final double startX;
  final double y;
  final double speed;
  final double size;
  final double wingOffset;

  _Bird({
    required this.startX,
    required this.y,
    required this.speed,
    required this.size,
    required this.wingOffset,
  });
}

class _Sparkle {
  final double x;
  final double y;
  final double size;
  final double offset;

  _Sparkle({
    required this.x,
    required this.y,
    required this.size,
    required this.offset,
  });
}

class _Crater {
  final double x;
  final double y;
  final double size;

  _Crater(this.x, this.y, this.size);
}

class _CloudConfig {
  final double baseX;
  final double y;
  final double scale;
  final double speed;

  _CloudConfig(this.baseX, this.y, this.scale, this.speed);
}

class _CloudPart {
  final double xOffset;
  final double yOffset;
  final double widthRatio;
  final double heightRatio;

  _CloudPart(this.xOffset, this.yOffset, this.widthRatio, this.heightRatio);
}

class _WaveConfig {
  final double yOffset;
  final double amplitude;
  final double frequency;
  final double speed;
  final double opacity;

  _WaveConfig(
    this.yOffset,
    this.amplitude,
    this.frequency,
    this.speed,
    this.opacity,
  );
}
