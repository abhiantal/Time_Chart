import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ================================================================
// SOLAR SYSTEM 3D HEADER - COMPLETE WORKING VERSION
// No errors, full realistic view with all features
// ================================================================

class SolarSystem3DHeader extends StatefulWidget {
  final bool isDark;
  final double width;
  final double height;

  const SolarSystem3DHeader({
    super.key,
    required this.isDark,
    this.width = 280,
    this.height = 240,
  });

  @override
  State<SolarSystem3DHeader> createState() => _SolarSystem3DHeaderState();
}

class _SolarSystem3DHeaderState extends State<SolarSystem3DHeader>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _pulseController]),
      builder: (context, child) {
        return RepaintBoundary(
          child: CustomPaint(
            size: Size(widget.width, widget.height),
            isComplex: true,
            willChange: true,
            painter: SolarSystemPainter(
              time: _controller.value * 120,
              pulse: _pulseController.value,
              isDark: widget.isDark,
            ),
          ),
        );
      },
    );
  }
}

// ================================================================
// MAIN PAINTER
// ================================================================

class SolarSystemPainter extends CustomPainter {
  final double time;
  final double pulse;
  final bool isDark;

  SolarSystemPainter({
    required this.time,
    required this.pulse,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;

    // Draw all layers
    _drawBackground(canvas, size);
    _drawStars(canvas, size);
    _drawShootingStars(canvas, size);
    _drawOrbits(canvas, cx, cy);
    _drawAsteroidBelt(canvas, cx, cy);
    _drawSun(canvas, cx, cy);
    _drawAllPlanets(canvas, cx, cy);
  }

  // ================================================================
  // BACKGROUND
  // ================================================================

  void _drawBackground(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (isDark) {
      // Deep space gradient
      final paint = Paint();
      paint.shader = ui.Gradient.radial(
        Offset(size.width * 0.3, size.height * 0.2),
        size.width * 1.2,
        [
          const Color(0xFF1a1a2e),
          const Color(0xFF16213e),
          const Color(0xFF0f0f1a),
          const Color(0xFF050508),
        ],
        [0.0, 0.35, 0.7, 1.0],
      );
      canvas.drawRect(rect, paint);

      // Purple nebula
      _drawNebula(
        canvas,
        size.width * 0.85,
        size.height * 0.15,
        size.width * 0.35,
        const Color(0xFF667eea),
        0.07,
      );

      // Pink nebula
      _drawNebula(
        canvas,
        size.width * 0.1,
        size.height * 0.85,
        size.width * 0.3,
        const Color(0xFF764ba2),
        0.05,
      );
    } else {
      final paint = Paint();
      paint.shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        [
          const Color(0xFFF0F4FF),
          const Color(0xFFE0ECFF),
          const Color(0xFFD0E4FF),
        ],
        [0.0, 0.5, 1.0],
      );
      canvas.drawRect(rect, paint);
    }
  }

  void _drawNebula(
    Canvas canvas,
    double x,
    double y,
    double radius,
    Color color,
    double opacity,
  ) {
    final paint = Paint();
    paint.shader = ui.Gradient.radial(
      Offset(x, y),
      radius,
      [
        color.withAlpha((255 * opacity).toInt()),
        color.withAlpha((255 * opacity * 0.4).toInt()),
        color.withAlpha((255 * 0).toInt()),
      ],
      [0.0, 0.5, 1.0],
    );
    canvas.drawCircle(Offset(x, y), radius, paint);
  }

  // ================================================================
  // STARS
  // ================================================================

  void _drawStars(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final count = isDark ? 180 : 60;

    for (int i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final baseSize = 0.4 + rng.nextDouble() * 1.8;

      // Twinkle effect
      final twinkleSpeed = 0.3 + rng.nextDouble() * 2.0;
      final twinklePhase = rng.nextDouble() * math.pi * 2;
      final twinkle =
          0.5 + 0.5 * math.sin(time * twinkleSpeed * 0.1 + twinklePhase);

      final brightness = (0.3 + rng.nextDouble() * 0.7) * twinkle;
      final starSize = baseSize * (0.8 + twinkle * 0.4);

      // Star color based on temperature
      final colorVal = rng.nextDouble();
      Color starColor;
      if (colorVal < 0.1) {
        starColor = const Color(0xFF9BB0FF); // Blue hot
      } else if (colorVal < 0.25) {
        starColor = const Color(0xFFCAD7FF); // Blue-white
      } else if (colorVal < 0.55) {
        starColor = const Color(0xFFFFFFF8); // White
      } else if (colorVal < 0.8) {
        starColor = const Color(0xFFFFEED8); // Yellow
      } else {
        starColor = const Color(0xFFFFD2A1); // Orange
      }

      final alpha = (brightness * (isDark ? 255 : 80)).round().clamp(0, 255);
      final paint = Paint()..color = starColor.withAlpha(alpha);

      canvas.drawCircle(Offset(x, y), starSize.clamp(0.3, 2.5), paint);

      // Glow for bright stars
      if (brightness > 0.7 && isDark && starSize > 1.0) {
        final glowPaint = Paint()
          ..color = starColor.withAlpha((alpha * 0.3).round().clamp(0, 255))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, starSize * 2);
        canvas.drawCircle(Offset(x, y), starSize * 2.5, glowPaint);
      }
    }
  }

  // ================================================================
  // SHOOTING STARS
  // ================================================================

  void _drawShootingStars(Canvas canvas, Size size) {
    if (!isDark) return;

    final rng = math.Random(789);

    for (int i = 0; i < 3; i++) {
      final interval = 8.0 + rng.nextDouble() * 12.0;
      final delay = rng.nextDouble() * interval;
      final duration = 0.4 + rng.nextDouble() * 0.5;

      final cycleTime = (time * 0.5) % interval;
      if (cycleTime < delay || cycleTime > delay + duration) continue;

      final progress = (cycleTime - delay) / duration;
      final eased = 1.0 - math.pow(1.0 - progress.clamp(0.0, 1.0), 3);

      // Start and end positions
      final startX = rng.nextDouble() * size.width * 0.5;
      final startY = rng.nextDouble() * size.height * 0.4;
      final endX =
          startX + size.width * 0.4 + rng.nextDouble() * size.width * 0.3;
      final endY =
          startY + size.height * 0.3 + rng.nextDouble() * size.height * 0.2;

      final currentX = startX + (endX - startX) * eased;
      final currentY = startY + (endY - startY) * eased;

      // Tail
      final tailLength = 30.0 + rng.nextDouble() * 20.0;
      final angle = math.atan2(endY - startY, endX - startX);
      final tailX =
          currentX - math.cos(angle) * tailLength * (1 - progress * 0.5);
      final tailY =
          currentY - math.sin(angle) * tailLength * (1 - progress * 0.5);

      final opacity = (1.0 - progress) * 0.9;

      // Draw tail
      final tailPaint = Paint()
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      tailPaint.shader = ui.Gradient.linear(
        Offset(tailX, tailY),
        Offset(currentX, currentY),
        [
          Colors.transparent,
          Colors.white.withAlpha((255 * opacity * 0.3).toInt()),
          Colors.white.withAlpha((255 * opacity * 0.8).toInt()),
          Colors.white.withAlpha((255 * opacity).toInt()),
        ],
        [0.0, 0.3, 0.7, 1.0],
      );

      canvas.drawLine(
        Offset(tailX, tailY),
        Offset(currentX, currentY),
        tailPaint,
      );

      // Draw head
      final headPaint = Paint()
        ..color = Colors.white.withAlpha((255 * opacity).toInt());
      canvas.drawCircle(Offset(currentX, currentY), 2.5, headPaint);

      // Glow
      final glowPaint = Paint()
        ..color = const Color(
          0xFFAADDFF,
        ).withAlpha((255 * opacity * 0.5).toInt())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(currentX, currentY), 5, glowPaint);
    }
  }

  // ================================================================
  // ORBITS
  // ================================================================

  void _drawOrbits(Canvas canvas, double cx, double cy) {
    final orbits = [28.0, 42.0, 58.0, 76.0, 100.0, 130.0];
    const tilt = 0.35;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    final orbitColor = isDark
        ? Colors.white.withAlpha((255 * 0.2).toInt())
        : const Color(0xFF6688AA).withAlpha((255 * 0.18).toInt());
    paint.color = orbitColor;

    for (final orbit in orbits) {
      final path = Path();
      for (int i = 0; i <= 72; i++) {
        final angle = (i / 72) * math.pi * 2;
        final x = cx + orbit * math.cos(angle);
        final y = cy + orbit * math.sin(angle) * tilt;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  // ================================================================
  // ASTEROID BELT
  // ================================================================

  void _drawAsteroidBelt(Canvas canvas, double cx, double cy) {
    final rng = math.Random(456);
    const tilt = 0.35;

    for (int i = 0; i < 80; i++) {
      final orbitRadius = 85.0 + rng.nextDouble() * 12.0;
      final angle = rng.nextDouble() * math.pi * 2 + time * 0.015;
      final x = cx + orbitRadius * math.cos(angle);
      final y = cy + orbitRadius * math.sin(angle) * tilt;
      final size = 0.4 + rng.nextDouble() * 1.2;
      final brightness = 0.3 + rng.nextDouble() * 0.5;

      final alpha = (brightness * (isDark ? 255 : 150)).round().clamp(0, 255);
      final paint = Paint()..color = const Color(0xFF8B7B6B).withAlpha(alpha);
      canvas.drawCircle(Offset(x, y), size, paint);
    }
  }

  // ================================================================
  // SUN
  // ================================================================

  void _drawSun(Canvas canvas, double cx, double cy) {
    final baseRadius = 20.0;
    final pulseRadius = baseRadius * (1.0 + pulse * 0.1);

    // Outer glow layers
    for (int i = 10; i >= 0; i--) {
      final glowRadius = pulseRadius * (2.5 + i * 0.25);
      final opacity = 0.018 * (11 - i) * (isDark ? 1.3 : 0.5);
      final alpha = (opacity * 255).round().clamp(0, 255);

      final glowPaint = Paint()
        ..color = const Color(0xFFFF8800).withAlpha(alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius * 0.35);
      canvas.drawCircle(Offset(cx, cy), glowRadius, glowPaint);
    }

    // Corona
    final coronaPaint1 = Paint();
    coronaPaint1.shader = ui.Gradient.radial(
      Offset(cx, cy),
      pulseRadius * 2.0,
      [
        Color.fromRGBO(255, 221, 102, isDark ? 0.45 : 0.25),
        Color.fromRGBO(255, 153, 34, isDark ? 0.2 : 0.1),
        const Color.fromRGBO(255, 153, 34, 0),
      ],
      [0.4, 0.7, 1.0],
    );
    canvas.drawCircle(Offset(cx, cy), pulseRadius * 2.0, coronaPaint1);

    // Sun body gradient
    final sunPaint = Paint();
    sunPaint.shader = ui.Gradient.radial(
      Offset(cx - baseRadius * 0.3, cy - baseRadius * 0.3),
      baseRadius * 1.6,
      [
        const Color(0xFFFFFFF0),
        const Color(0xFFFFFFAA),
        const Color(0xFFFFEE66),
        const Color(0xFFFFCC22),
        const Color(0xFFFF9900),
        const Color(0xFFFF6600),
      ],
      [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
    );
    canvas.drawCircle(Offset(cx, cy), pulseRadius, sunPaint);

    // Sunspots
    canvas.save();
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: pulseRadius));
    canvas.clipPath(clipPath);

    final spotRng = math.Random(42);
    for (int i = 0; i < 6; i++) {
      final angle = spotRng.nextDouble() * math.pi * 2 + time * 0.02;
      final dist = pulseRadius * (0.2 + spotRng.nextDouble() * 0.5);
      final spotX = cx + math.cos(angle) * dist;
      final spotY = cy + math.sin(angle) * dist;
      final spotR = pulseRadius * (0.04 + spotRng.nextDouble() * 0.06);

      final spotPaint = Paint()
        ..color = const Color(0xFF994400).withAlpha((255 * 0.45).toInt());
      canvas.drawCircle(Offset(spotX, spotY), spotR, spotPaint);
    }
    canvas.restore();
  }

  // ================================================================
  // ALL PLANETS
  // ================================================================

  void _drawAllPlanets(Canvas canvas, double cx, double cy) {
    const tilt = 0.35;

    // Planet data
    final planets = [
      _PlanetData(
        name: 'Mercury',
        orbit: 28,
        size: 4,
        speed: 4.0,
        phase: 0.0,
        colors: [
          const Color(0xFFD4C4B4),
          const Color(0xFFB0A090),
          const Color(0xFF807060),
        ],
      ),
      _PlanetData(
        name: 'Venus',
        orbit: 42,
        size: 6,
        speed: 3.0,
        phase: 0.25,
        colors: [
          const Color(0xFFFAE088),
          const Color(0xFFE8C76B),
          const Color(0xFFCCAA4D),
        ],
        atmosphereColor: const Color(0xFFFFE57F),
      ),
      _PlanetData(
        name: 'Earth',
        orbit: 58,
        size: 7,
        speed: 2.5,
        phase: 0.5,
        colors: [
          const Color(0xFF6BB5FF),
          const Color(0xFF4A90D9),
          const Color(0xFF2B5A8A),
        ],
        atmosphereColor: const Color(0xFF87CEEB),
        hasDetails: true,
        hasMoon: true,
      ),
      _PlanetData(
        name: 'Mars',
        orbit: 76,
        size: 5,
        speed: 2.0,
        phase: 0.75,
        colors: [
          const Color(0xFFE88A7A),
          const Color(0xFFCD5C5C),
          const Color(0xFF8B3A3A),
        ],
        hasPolarCaps: true,
      ),
      _PlanetData(
        name: 'Jupiter',
        orbit: 100,
        size: 14,
        speed: 1.0,
        phase: 0.15,
        colors: [
          const Color(0xFFEAC494),
          const Color(0xFFD4A574),
          const Color(0xFFA67C52),
        ],
        hasBands: true,
        hasSpot: true,
      ),
      _PlanetData(
        name: 'Saturn',
        orbit: 130,
        size: 12,
        speed: 0.7,
        phase: 0.4,
        colors: [
          const Color(0xFFFAE8AA),
          const Color(0xFFE8D088),
          const Color(0xFFCCAA55),
        ],
        hasBands: true,
        hasRings: true,
      ),
    ];

    // Sort by Z for proper depth rendering
    final sortedPlanets = <Map<String, dynamic>>[];

    for (final planet in planets) {
      final angle = time * planet.speed * 0.03 + planet.phase * math.pi * 2;
      final x = cx + planet.orbit * math.cos(angle);
      final y = cy + planet.orbit * math.sin(angle) * tilt;
      final z = math.sin(angle);

      sortedPlanets.add({
        'planet': planet,
        'x': x,
        'y': y,
        'z': z,
        'angle': angle,
      });
    }

    sortedPlanets.sort(
      (a, b) => (a['z'] as double).compareTo(b['z'] as double),
    );

    // Draw each planet
    for (final item in sortedPlanets) {
      final planet = item['planet'] as _PlanetData;
      final x = item['x'] as double;
      final y = item['y'] as double;
      final angle = item['angle'] as double;

      _drawPlanet(canvas, planet, x, y, angle, cx, cy, tilt);
    }
  }

  void _drawPlanet(
    Canvas canvas,
    _PlanetData planet,
    double x,
    double y,
    double angle,
    double cx,
    double cy,
    double tilt,
  ) {
    final size = planet.size.toDouble();

    // Light calculation
    final lightAngle = math.atan2(y - cy, x - cx);
    final lightIntensity = (0.5 + 0.5 * math.cos(lightAngle)).clamp(0.3, 1.0);

    // Atmosphere glow
    if (planet.atmosphereColor != null) {
      final atmosPaint = Paint();
      atmosPaint.shader = ui.Gradient.radial(
        Offset(x, y),
        size * 1.4,
        [
          const Color.fromRGBO(0, 0, 0, 0),
          planet.atmosphereColor!.withAlpha(
            (255 * (isDark ? 0.25 : 0.15)).toInt(),
          ),
          planet.atmosphereColor!.withAlpha(
            (255 * (isDark ? 0.4 : 0.25)).toInt(),
          ),
          const Color.fromRGBO(0, 0, 0, 0),
        ],
        [0.6, 0.8, 0.95, 1.0],
      );
      canvas.drawCircle(Offset(x, y), size * 1.4, atmosPaint);
    }

    // Rings behind (Saturn)
    if (planet.hasRings) {
      _drawRings(canvas, x, y, size, false);
    }

    // Planet body
    canvas.save();
    final planetClip = Path()
      ..addOval(Rect.fromCircle(center: Offset(x, y), radius: size));
    canvas.clipPath(planetClip);

    if (planet.hasBands) {
      // Banded planet (Jupiter, Saturn)
      _drawBandedPlanet(canvas, x, y, size, planet, lightIntensity);
    } else {
      // Solid planet
      final planetPaint = Paint();
      planetPaint.shader = ui.Gradient.radial(
        Offset(x - size * 0.4, y - size * 0.4),
        size * 2.0,
        [
          _adjustColor(planet.colors[0], lightIntensity * 1.2),
          _adjustColor(planet.colors[1], lightIntensity),
          _adjustColor(planet.colors[2], lightIntensity * 0.6),
        ],
        [0.0, 0.4, 1.0],
      );
      canvas.drawCircle(Offset(x, y), size, planetPaint);
    }

    // Earth details
    if (planet.hasDetails) {
      _drawEarthDetails(canvas, x, y, size, lightIntensity);
    }

    // Polar caps (Mars)
    if (planet.hasPolarCaps) {
      _drawPolarCaps(canvas, x, y, size, lightIntensity);
    }

    // Great Red Spot (Jupiter)
    if (planet.hasSpot) {
      _drawGreatSpot(canvas, x, y, size, lightIntensity);
    }

    canvas.restore();

    // Terminator shadow
    _drawTerminator(canvas, x, y, size, lightAngle);

    // Specular highlight
    if (lightIntensity > 0.4) {
      _drawSpecular(canvas, x, y, size, lightIntensity);
    }

    // Rings in front (Saturn)
    if (planet.hasRings) {
      _drawRings(canvas, x, y, size, true);
    }

    // Moon (Earth)
    if (planet.hasMoon) {
      _drawMoon(canvas, x, y, size, tilt);
    }
  }

  void _drawBandedPlanet(
    Canvas canvas,
    double x,
    double y,
    double size,
    _PlanetData planet,
    double lightIntensity,
  ) {
    final bandColors = [
      _adjustColor(planet.colors[0], lightIntensity * 1.1),
      _adjustColor(planet.colors[1], lightIntensity),
      _adjustColor(planet.colors[2], lightIntensity * 0.9),
      _adjustColor(planet.colors[1], lightIntensity * 0.95),
      _adjustColor(planet.colors[0], lightIntensity),
    ];

    final bandPaint = Paint();
    bandPaint.shader = ui.Gradient.linear(
      Offset(x, y - size),
      Offset(x, y + size),
      bandColors,
      [0.0, 0.25, 0.5, 0.75, 1.0],
    );
    canvas.drawRect(
      Rect.fromCircle(center: Offset(x, y), radius: size),
      bandPaint,
    );
  }

  void _drawEarthDetails(
    Canvas canvas,
    double x,
    double y,
    double size,
    double light,
  ) {
    final rng = math.Random(123);

    // Continents
    for (int i = 0; i < 4; i++) {
      final ca = rng.nextDouble() * math.pi * 2 + time * 0.03;
      final cd = size * (0.15 + rng.nextDouble() * 0.45);
      final ccx = x + math.cos(ca) * cd;
      final ccy = y + math.sin(ca) * cd;
      final cw = size * (0.2 + rng.nextDouble() * 0.15);
      final ch = cw * (0.5 + rng.nextDouble() * 0.3);

      final contPaint = Paint()
        ..color = Color.fromRGBO(62, 139, 78, (0.5 * light).clamp(0.0, 1.0));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ccx, ccy), width: cw, height: ch),
        contPaint,
      );
    }

    // Clouds
    for (int i = 0; i < 6; i++) {
      final ca = rng.nextDouble() * math.pi * 2 + time * 0.05;
      final cd = size * (0.1 + rng.nextDouble() * 0.6);
      final ccx = x + math.cos(ca) * cd;
      final ccy = y + (rng.nextDouble() - 0.5) * size * 1.5;
      final cw = size * (0.18 + rng.nextDouble() * 0.12);
      final ch = cw * (0.3 + rng.nextDouble() * 0.2);

      final cloudPaint = Paint()
        ..color = Color.fromRGBO(255, 255, 255, (0.35 * light).clamp(0.0, 1.0));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ccx, ccy), width: cw, height: ch),
        cloudPaint,
      );
    }
  }

  void _drawPolarCaps(
    Canvas canvas,
    double x,
    double y,
    double size,
    double light,
  ) {
    // North
    final northPaint = Paint();
    northPaint.shader = ui.Gradient.radial(
      Offset(x, y - size * 0.75),
      size * 0.35,
      [
        Color.fromRGBO(255, 255, 255, (0.85 * light).clamp(0.0, 1.0)),
        Color.fromRGBO(255, 255, 255, (0.4 * light).clamp(0.0, 1.0)),
        const Color.fromRGBO(255, 255, 255, 0),
      ],
      [0.0, 0.6, 1.0],
    );
    canvas.drawCircle(Offset(x, y - size * 0.75), size * 0.35, northPaint);

    // South
    final southPaint = Paint();
    southPaint.shader = ui.Gradient.radial(
      Offset(x, y + size * 0.75),
      size * 0.28,
      [
        Color.fromRGBO(255, 255, 255, (0.65 * light).clamp(0.0, 1.0)),
        Color.fromRGBO(255, 255, 255, (0.3 * light).clamp(0.0, 1.0)),
        const Color.fromRGBO(255, 255, 255, 0),
      ],
      [0.0, 0.6, 1.0],
    );
    canvas.drawCircle(Offset(x, y + size * 0.75), size * 0.28, southPaint);
  }

  void _drawGreatSpot(
    Canvas canvas,
    double x,
    double y,
    double size,
    double light,
  ) {
    final spotAngle = time * 0.25;
    final spotX = x + size * 0.4 * math.cos(spotAngle);
    final spotY = y + size * 0.2;

    final spotPaint = Paint();
    spotPaint.shader = ui.Gradient.radial(
      Offset(spotX, spotY),
      size * 0.2,
      [
        _adjustColor(const Color(0xFFE87A5A), light),
        _adjustColor(const Color(0xFFB84C3C), light * 0.8),
        const Color.fromRGBO(0, 0, 0, 0),
      ],
      [0.0, 0.7, 1.0],
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(spotX, spotY),
        width: size * 0.45,
        height: size * 0.28,
      ),
      spotPaint,
    );
  }

  void _drawTerminator(
    Canvas canvas,
    double x,
    double y,
    double size,
    double lightAngle,
  ) {
    canvas.save();
    final clip = Path()
      ..addOval(Rect.fromCircle(center: Offset(x, y), radius: size));
    canvas.clipPath(clip);

    final shadowPaint = Paint();
    shadowPaint.shader = ui.Gradient.linear(
      Offset(x - size * 0.3, y),
      Offset(x + size * 1.2, y),
      [
        const Color.fromRGBO(0, 0, 0, 0),
        const Color.fromRGBO(0, 0, 0, 0.12),
        const Color.fromRGBO(0, 0, 0, 0.4),
        const Color.fromRGBO(0, 0, 0, 0.65),
      ],
      [0.0, 0.3, 0.6, 1.0],
    );
    canvas.drawRect(
      Rect.fromCircle(center: Offset(x, y), radius: size),
      shadowPaint,
    );
    canvas.restore();
  }

  void _drawSpecular(
    Canvas canvas,
    double x,
    double y,
    double size,
    double light,
  ) {
    final specPaint = Paint();
    specPaint.shader = ui.Gradient.radial(
      Offset(x - size * 0.4, y - size * 0.4),
      size * 0.5,
      [
        Color.fromRGBO(255, 255, 255, (0.45 * light).clamp(0.0, 1.0)),
        Color.fromRGBO(255, 255, 255, (0.15 * light).clamp(0.0, 1.0)),
        const Color.fromRGBO(255, 255, 255, 0),
      ],
      [0.0, 0.5, 1.0],
    );
    canvas.drawCircle(Offset(x, y), size, specPaint);
  }

  void _drawRings(
    Canvas canvas,
    double x,
    double y,
    double size,
    bool isFront,
  ) {
    const ringTilt = 0.38;
    final startAngle = isFront ? -math.pi : 0.0;
    final baseOpacity = isFront ? 0.85 : 0.4;

    final rings = [
      {'inner': 1.35, 'outer': 1.55, 'op': 0.35},
      {'inner': 1.6, 'outer': 2.0, 'op': 0.9},
      {'inner': 2.02, 'outer': 2.08, 'op': 0.08}, // Cassini division
      {'inner': 2.12, 'outer': 2.45, 'op': 0.75},
    ];

    for (final ring in rings) {
      final inner = size * (ring['inner'] as double);
      final outer = size * (ring['outer'] as double);
      final opacity =
          (ring['op'] as double) * baseOpacity * (isDark ? 1.0 : 0.7);

      final path = Path()
        ..addArc(
          Rect.fromCenter(
            center: Offset(x, y),
            width: outer * 2,
            height: outer * 2 * ringTilt,
          ),
          startAngle,
          math.pi,
        )
        ..arcTo(
          Rect.fromCenter(
            center: Offset(x, y),
            width: inner * 2,
            height: inner * 2 * ringTilt,
          ),
          startAngle + math.pi,
          -math.pi,
          false,
        )
        ..close();

      final innerStop = (inner / outer).clamp(0.1, 0.95);

      final ringPaint = Paint();
      ringPaint.shader = ui.Gradient.radial(
        Offset(x, y),
        outer,
        [
          const Color.fromRGBO(0, 0, 0, 0),
          Color.fromRGBO(212, 184, 150, opacity * 0.5),
          Color.fromRGBO(212, 184, 150, opacity),
          Color.fromRGBO(212, 184, 150, opacity * 0.7),
          const Color.fromRGBO(0, 0, 0, 0),
        ],
        [
          (innerStop - 0.05).clamp(0.0, 1.0),
          innerStop,
          (innerStop + 0.5) / 1.5,
          0.92,
          1.0,
        ],
      );
      canvas.drawPath(path, ringPaint);
    }

    // Ring sparkles (front only)
    if (isFront && isDark) {
      final rng = math.Random(321);
      for (int i = 0; i < 15; i++) {
        final r = size * (1.7 + rng.nextDouble() * 0.6);
        final a = -math.pi + rng.nextDouble() * math.pi;
        final sx = x + r * math.cos(a);
        final sy = y + r * ringTilt * math.sin(a);
        final twinkle =
            0.3 + 0.7 * math.sin(time * 0.3 * (1 + rng.nextDouble()) + i);

        final sparklePaint = Paint()
          ..color = Color.fromRGBO(
            255,
            255,
            255,
            (twinkle * 0.6).clamp(0.0, 1.0),
          );
        canvas.drawCircle(
          Offset(sx, sy),
          0.6 + rng.nextDouble() * 0.5,
          sparklePaint,
        );
      }
    }
  }

  void _drawMoon(
    Canvas canvas,
    double px,
    double py,
    double planetSize,
    double tilt,
  ) {
    final moonAngle = time * 0.15;
    final moonDist = planetSize * 2.8;
    final moonX = px + moonDist * math.cos(moonAngle);
    final moonY = py + moonDist * math.sin(moonAngle) * 0.5;
    final moonSize = planetSize * 0.28;

    // Moon glow
    final glowPaint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, isDark ? 0.18 : 0.1)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, moonSize);
    canvas.drawCircle(Offset(moonX, moonY), moonSize * 1.6, glowPaint);

    // Moon body
    final moonPaint = Paint();
    moonPaint.shader = ui.Gradient.radial(
      Offset(moonX - moonSize * 0.35, moonY - moonSize * 0.35),
      moonSize * 1.8,
      [
        const Color(0xFFFFFFFF),
        const Color(0xFFE8E8E8),
        const Color(0xFFBBBBBB),
      ],
      [0.0, 0.5, 1.0],
    );
    canvas.drawCircle(Offset(moonX, moonY), moonSize, moonPaint);

    // Moon shadow
    final moonShadowPaint = Paint();
    moonShadowPaint.shader = ui.Gradient.linear(
      Offset(moonX - moonSize * 0.4, moonY),
      Offset(moonX + moonSize, moonY),
      [const Color.fromRGBO(0, 0, 0, 0), const Color.fromRGBO(0, 0, 0, 0.35)],
      [0.0, 1.0],
    );
    canvas.drawCircle(Offset(moonX, moonY), moonSize, moonShadowPaint);
  }

  // ================================================================
  // HELPER
  // ================================================================

  Color _adjustColor(Color color, double factor) {
    return Color.fromARGB(
      color.alpha,
      (color.red * factor).round().clamp(0, 255),
      (color.green * factor).round().clamp(0, 255),
      (color.blue * factor).round().clamp(0, 255),
    );
  }

  @override
  bool shouldRepaint(covariant SolarSystemPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.pulse != pulse ||
        oldDelegate.isDark != isDark;
  }
}

// ================================================================
// PLANET DATA CLASS
// ================================================================

class _PlanetData {
  final String name;
  final int orbit;
  final int size;
  final double speed;
  final double phase;
  final List<Color> colors;
  final Color? atmosphereColor;
  final bool hasDetails;
  final bool hasMoon;
  final bool hasPolarCaps;
  final bool hasBands;
  final bool hasSpot;
  final bool hasRings;

  const _PlanetData({
    required this.name,
    required this.orbit,
    required this.size,
    required this.speed,
    required this.phase,
    required this.colors,
    this.atmosphereColor,
    this.hasDetails = false,
    this.hasMoon = false,
    this.hasPolarCaps = false,
    this.hasBands = false,
    this.hasSpot = false,
    this.hasRings = false,
  });
}

// ================================================================
// HEADER WIDGET
// ================================================================

class SolarSystemHeaderWidget extends StatelessWidget {
  final bool isDark;

  const SolarSystemHeaderWidget({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha((255 * 0.7).toInt())
                : Colors.black.withAlpha((255 * 0.12).toInt()),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Solar System
          Positioned.fill(
            child: SolarSystem3DHeader(isDark: isDark, width: 280, height: 240),
          ),

          // Top gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? const Color(0xFF1A1A2E) : Colors.white).withAlpha(
                      (255 * 0.5).toInt(),
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    (isDark ? const Color(0xFF1A1A2E) : Colors.white).withAlpha(
                      (255 * 0.7).toInt(),
                    ),
                    (isDark ? const Color(0xFF1A1A2E) : Colors.white).withAlpha(
                      (255 * 0.95).toInt(),
                    ),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Content
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(
                                0xFF667eea,
                              ).withAlpha((255 * 0.3).toInt()),
                              const Color(
                                0xFF764ba2,
                              ).withAlpha((255 * 0.25).toInt()),
                            ]
                          : [
                              const Color(
                                0xFF4A7FD9,
                              ).withAlpha((255 * 0.25).toInt()),
                              const Color(
                                0xFF6B8AFF,
                              ).withAlpha((255 * 0.2).toInt()),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          (isDark
                                  ? const Color(0xFF667eea)
                                  : const Color(0xFF4A7FD9))
                              .withAlpha((255 * 0.35).toInt()),
                    ),
                  ),
                  child: Text(
                    _getGreeting(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF9BA8FF)
                          : const Color(0xFF4A7FD9),
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Corner icon
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? const Color(0xFF667eea) : const Color(0xFF4A7FD9))
                        .withAlpha((255 * 0.2).toInt()),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(
                  color:
                      (isDark
                              ? const Color(0xFF667eea)
                              : const Color(0xFF4A7FD9))
                          .withAlpha((255 * 0.3).toInt()),
                ),
              ),
              child: Icon(
                Icons.rocket_launch_rounded,
                size: 16,
                color: isDark
                    ? Colors.white.withAlpha((255 * 0.65).toInt())
                    : const Color(0xFF4A7FD9).withAlpha((255 * 0.75).toInt()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'NIGHT EXPLORER';
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    if (hour < 21) return 'GOOD EVENING';
    return 'NIGHT EXPLORER';
  }
}
