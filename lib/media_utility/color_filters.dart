// ================================================================
// FILE: lib/media_utility/color_filters.dart
// Each filter now exposes both 'filter' (ColorFilter for preview)
// and 'matrix' (List<double> for server-side image processing)
// ================================================================

import 'package:flutter/material.dart';

class ColorFilters {
  // ── Raw matrix constants (reused for both ColorFilter and processing) ──

  static const List<double> _clarendonMatrix = [
    1.2,
    0,
    0,
    0,
    0,
    0,
    1.2,
    0,
    0,
    0,
    0,
    0,
    1.2,
    0,
    10,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _ginghamMatrix = [
    0.95,
    0.05,
    0.05,
    0,
    10,
    0.05,
    0.95,
    0.05,
    0,
    10,
    0.05,
    0.05,
    0.90,
    0,
    20,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _moonMatrix = [
    0.25,
    0.65,
    0.15,
    0,
    -10,
    0.20,
    0.70,
    0.15,
    0,
    -10,
    0.20,
    0.60,
    0.30,
    0,
    10,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _larkMatrix = [
    1.1,
    0,
    0,
    0,
    20,
    0,
    1.0,
    0,
    0,
    15,
    0,
    0,
    0.9,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _reyesMatrix = [
    1.05,
    0.1,
    0.05,
    0,
    15,
    0.05,
    1.0,
    0.05,
    0,
    10,
    0.05,
    0.1,
    0.95,
    0,
    5,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _junoMatrix = [
    1.2,
    0.05,
    0,
    0,
    0,
    0,
    1.1,
    0.05,
    0,
    0,
    -0.05,
    0,
    1.0,
    0,
    10,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _slumberMatrix = [
    0.9,
    0.1,
    0.05,
    0,
    20,
    0.05,
    0.85,
    0.1,
    0,
    15,
    0.05,
    0.1,
    0.85,
    0,
    25,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _cremaMatrix = [
    1.0,
    0.1,
    0.1,
    0,
    25,
    0.1,
    0.95,
    0.05,
    0,
    20,
    0.05,
    0.05,
    0.9,
    0,
    15,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _ludwigMatrix = [
    1.05,
    0.05,
    0,
    0,
    5,
    0,
    1.0,
    0.05,
    0,
    0,
    0,
    0.05,
    0.95,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _adenMatrix = [
    0.9,
    0.1,
    0.1,
    0,
    30,
    0.1,
    0.9,
    0.1,
    0,
    25,
    0.1,
    0.1,
    0.85,
    0,
    35,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _valenciaMatrix = [
    1.15,
    0.1,
    0,
    0,
    15,
    0.05,
    1.05,
    0,
    0,
    10,
    0,
    0,
    0.95,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _nashvilleMatrix = [
    1.1,
    0.15,
    0.05,
    0,
    20,
    0,
    1.0,
    0.05,
    0,
    10,
    -0.05,
    0.1,
    0.95,
    0,
    30,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _sierraMatrix = [
    1.05,
    0.2,
    0.1,
    0,
    10,
    0.1,
    1.0,
    0.1,
    0,
    5,
    0.05,
    0.1,
    0.9,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _mayfairMatrix = [
    1.1,
    0.1,
    0.1,
    0,
    10,
    0.05,
    1.0,
    0.05,
    0,
    5,
    0.05,
    0.1,
    0.95,
    0,
    15,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _hudsonMatrix = [
    1.0,
    0,
    0,
    0,
    0,
    0,
    1.0,
    0.1,
    0,
    0,
    0.1,
    0.15,
    1.1,
    0,
    20,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _riseMatrix = [
    1.1,
    0.1,
    0,
    0,
    25,
    0.05,
    1.05,
    0.05,
    0,
    20,
    0,
    0.05,
    0.95,
    0,
    15,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _amaroMatrix = [
    1.1,
    0.1,
    0.1,
    0,
    30,
    0.1,
    1.1,
    0.1,
    0,
    25,
    0.1,
    0.1,
    1.0,
    0,
    20,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _brannanMatrix = [
    1.3,
    0.1,
    0,
    0,
    -20,
    0,
    1.1,
    0.1,
    0,
    -10,
    -0.1,
    0.1,
    1.1,
    0,
    10,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _vividMatrix = [
    1.3,
    0,
    0,
    0,
    0,
    0,
    1.3,
    0,
    0,
    0,
    0,
    0,
    1.3,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _sepiaMatrix = [
    0.393,
    0.769,
    0.189,
    0,
    0,
    0.349,
    0.686,
    0.168,
    0,
    0,
    0.272,
    0.534,
    0.131,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _blackAndWhiteMatrix = [
    0.299,
    0.587,
    0.114,
    0,
    0,
    0.299,
    0.587,
    0.114,
    0,
    0,
    0.299,
    0.587,
    0.114,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _coolMatrix = [
    0.9,
    0,
    0,
    0,
    0,
    0,
    1.0,
    0.05,
    0,
    0,
    0.1,
    0.1,
    1.15,
    0,
    10,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _warmMatrix = [
    1.15,
    0.05,
    0,
    0,
    10,
    0,
    1.0,
    0,
    0,
    5,
    0,
    0,
    0.9,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _vintageMatrix = [
    0.9,
    0.4,
    0.1,
    0,
    15,
    0.2,
    0.8,
    0.1,
    0,
    10,
    0.1,
    0.3,
    0.6,
    0,
    20,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _dramaticMatrix = [
    1.4,
    0,
    0,
    0,
    -30,
    0,
    1.4,
    0,
    0,
    -30,
    0,
    0,
    1.4,
    0,
    -30,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _fadedMatrix = [
    0.9,
    0,
    0,
    0,
    30,
    0,
    0.9,
    0,
    0,
    30,
    0,
    0,
    0.9,
    0,
    30,
    0,
    0,
    0,
    1,
    0,
  ];

  // ── Static ColorFilter getters (use the constants above) ──

  static ColorFilter clarendon() => const ColorFilter.matrix(_clarendonMatrix);
  static ColorFilter gingham() => const ColorFilter.matrix(_ginghamMatrix);
  static ColorFilter moon() => const ColorFilter.matrix(_moonMatrix);
  static ColorFilter lark() => const ColorFilter.matrix(_larkMatrix);
  static ColorFilter reyes() => const ColorFilter.matrix(_reyesMatrix);
  static ColorFilter juno() => const ColorFilter.matrix(_junoMatrix);
  static ColorFilter slumber() => const ColorFilter.matrix(_slumberMatrix);
  static ColorFilter crema() => const ColorFilter.matrix(_cremaMatrix);
  static ColorFilter ludwig() => const ColorFilter.matrix(_ludwigMatrix);
  static ColorFilter aden() => const ColorFilter.matrix(_adenMatrix);
  static ColorFilter valencia() => const ColorFilter.matrix(_valenciaMatrix);
  static ColorFilter nashville() => const ColorFilter.matrix(_nashvilleMatrix);
  static ColorFilter sierra() => const ColorFilter.matrix(_sierraMatrix);
  static ColorFilter mayfair() => const ColorFilter.matrix(_mayfairMatrix);
  static ColorFilter hudson() => const ColorFilter.matrix(_hudsonMatrix);
  static ColorFilter rise() => const ColorFilter.matrix(_riseMatrix);
  static ColorFilter amaro() => const ColorFilter.matrix(_amaroMatrix);
  static ColorFilter brannan() => const ColorFilter.matrix(_brannanMatrix);
  static ColorFilter vivid() => const ColorFilter.matrix(_vividMatrix);
  static ColorFilter sepia() => const ColorFilter.matrix(_sepiaMatrix);
  static ColorFilter blackAndWhite() =>
      const ColorFilter.matrix(_blackAndWhiteMatrix);
  static ColorFilter cool() => const ColorFilter.matrix(_coolMatrix);
  static ColorFilter warm() => const ColorFilter.matrix(_warmMatrix);
  static ColorFilter vintage() => const ColorFilter.matrix(_vintageMatrix);
  static ColorFilter dramatic() => const ColorFilter.matrix(_dramaticMatrix);
  static ColorFilter faded() => const ColorFilter.matrix(_fadedMatrix);

  // ── Master filter list ──
  // Each entry has:
  //   'name'   → display label
  //   'filter' → ColorFilter for live camera preview (nullable = no filter)
  //   'matrix' → List<double> for img-package processing (nullable = no filter)
  //   'icon'   → Icon for UI
  static List<Map<String, dynamic>> getAllFilters() {
    return [
      {
        'name': 'Original',
        'filter': null,
        'matrix': null,
        'icon': Icons.filter_none,
      },
      {
        'name': 'Clarendon',
        'filter': clarendon(),
        'matrix': _clarendonMatrix,
        'icon': Icons.wb_sunny_outlined,
      },
      {
        'name': 'Gingham',
        'filter': gingham(),
        'matrix': _ginghamMatrix,
        'icon': Icons.grid_on,
      },
      {
        'name': 'Moon',
        'filter': moon(),
        'matrix': _moonMatrix,
        'icon': Icons.nightlight_round,
      },
      {
        'name': 'Lark',
        'filter': lark(),
        'matrix': _larkMatrix,
        'icon': Icons.light_mode_outlined,
      },
      {
        'name': 'Reyes',
        'filter': reyes(),
        'matrix': _reyesMatrix,
        'icon': Icons.auto_awesome,
      },
      {
        'name': 'Juno',
        'filter': juno(),
        'matrix': _junoMatrix,
        'icon': Icons.flare,
      },
      {
        'name': 'Slumber',
        'filter': slumber(),
        'matrix': _slumberMatrix,
        'icon': Icons.bedtime_outlined,
      },
      {
        'name': 'Crema',
        'filter': crema(),
        'matrix': _cremaMatrix,
        'icon': Icons.coffee_outlined,
      },
      {
        'name': 'Ludwig',
        'filter': ludwig(),
        'matrix': _ludwigMatrix,
        'icon': Icons.music_note,
      },
      {
        'name': 'Aden',
        'filter': aden(),
        'matrix': _adenMatrix,
        'icon': Icons.park_outlined,
      },
      {
        'name': 'Valencia',
        'filter': valencia(),
        'matrix': _valenciaMatrix,
        'icon': Icons.local_fire_department_outlined,
      },
      {
        'name': 'Nashville',
        'filter': nashville(),
        'matrix': _nashvilleMatrix,
        'icon': Icons.piano,
      },
      {
        'name': 'Sierra',
        'filter': sierra(),
        'matrix': _sierraMatrix,
        'icon': Icons.terrain,
      },
      {
        'name': 'Mayfair',
        'filter': mayfair(),
        'matrix': _mayfairMatrix,
        'icon': Icons.location_city,
      },
      {
        'name': 'Hudson',
        'filter': hudson(),
        'matrix': _hudsonMatrix,
        'icon': Icons.water_outlined,
      },
      {
        'name': 'Rise',
        'filter': rise(),
        'matrix': _riseMatrix,
        'icon': Icons.trending_up,
      },
      {
        'name': 'Amaro',
        'filter': amaro(),
        'matrix': _amaroMatrix,
        'icon': Icons.brightness_5,
      },
      {
        'name': 'Vivid',
        'filter': vivid(),
        'matrix': _vividMatrix,
        'icon': Icons.colorize,
      },
      {
        'name': 'Warm',
        'filter': warm(),
        'matrix': _warmMatrix,
        'icon': Icons.whatshot,
      },
      {
        'name': 'Cool',
        'filter': cool(),
        'matrix': _coolMatrix,
        'icon': Icons.ac_unit,
      },
      {
        'name': 'B&W',
        'filter': blackAndWhite(),
        'matrix': _blackAndWhiteMatrix,
        'icon': Icons.contrast,
      },
      {
        'name': 'Sepia',
        'filter': sepia(),
        'matrix': _sepiaMatrix,
        'icon': Icons.photo_album,
      },
      {
        'name': 'Vintage',
        'filter': vintage(),
        'matrix': _vintageMatrix,
        'icon': Icons.camera_alt_outlined,
      },
      {
        'name': 'Dramatic',
        'filter': dramatic(),
        'matrix': _dramaticMatrix,
        'icon': Icons.theater_comedy,
      },
      {
        'name': 'Faded',
        'filter': faded(),
        'matrix': _fadedMatrix,
        'icon': Icons.blur_on,
      },
    ];
  }

  // ── Adjustment helpers (unchanged) ──

  static List<double> brightnessAdjust(double value) {
    if (value == 0) return _identityMatrix();
    final brightness = value * 100;
    return [
      1,
      0,
      0,
      0,
      brightness,
      0,
      1,
      0,
      0,
      brightness,
      0,
      0,
      1,
      0,
      brightness,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  static List<double> contrastAdjust(double value) {
    if (value == 0) return _identityMatrix();
    final factor = 1.0 + value;
    final offset = 128 * (1 - factor);
    return [
      factor,
      0,
      0,
      0,
      offset,
      0,
      factor,
      0,
      0,
      offset,
      0,
      0,
      factor,
      0,
      offset,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  static List<double> saturationAdjust(double value) {
    if (value == 0) return _identityMatrix();
    final s = value + 1.0;
    const lumR = 0.3086, lumG = 0.6094, lumB = 0.0820;
    return [
      lumR * (1 - s) + s,
      lumG * (1 - s),
      lumB * (1 - s),
      0,
      0,
      lumR * (1 - s),
      lumG * (1 - s) + s,
      lumB * (1 - s),
      0,
      0,
      lumR * (1 - s),
      lumG * (1 - s),
      lumB * (1 - s) + s,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  static List<double> _identityMatrix() => [
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}
