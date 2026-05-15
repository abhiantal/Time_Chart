import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/conversation/bubbles/message_bubble_base.dart';

class ChatUIProvider extends ChangeNotifier {
  String? _wallpaperId;
  String _selectedTheme = 'default';
  BubbleStyle _bubbleStyle = BubbleStyle.modern;
  String _fontSizeId = 'medium';

  SharedPreferences? _prefs;
  bool _initialized = false;

  bool get initialized => _initialized;
  String? get wallpaperId => _wallpaperId;
  String get selectedTheme => _selectedTheme;
  BubbleStyle get bubbleStyle => _bubbleStyle;
  String get fontSize => _fontSizeId;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _wallpaperId = _prefs?.getString('chat_wallpaper_id');
    _selectedTheme = _prefs?.getString('chat_theme') ?? 'default';
    _bubbleStyle = BubbleStyle.values.firstWhere(
      (e) => e.name == (_prefs?.getString('chat_bubble_style') ?? 'modern'),
      orElse: () => BubbleStyle.modern,
    );
    _fontSizeId = _prefs?.getString('chat_font_size_id') ?? 'medium';
    _initialized = true;
    notifyListeners();
  }

  void setActiveChatId(String chatId) {
    // Potential for chat-specific settings
  }

  void setWallpaper(String? id) {
    _wallpaperId = id;
    if (id == null) {
      _prefs?.remove('chat_wallpaper_id');
    } else {
      _prefs?.setString('chat_wallpaper_id', id);
    }
    notifyListeners();
  }

  void setTheme(String theme) {
    _selectedTheme = theme;
    _prefs?.setString('chat_theme', theme);
    notifyListeners();
  }

  void setBubbleStyle(BubbleStyle style) {
    _bubbleStyle = style;
    _prefs?.setString('chat_bubble_style', style.name);
    notifyListeners();
  }

  void setFontSize(String sizeId) {
    _fontSizeId = sizeId;
    _prefs?.setString('chat_font_size_id', sizeId);
    notifyListeners();
  }

  double get fontSizeValue {
    switch (_fontSizeId) {
      case 'small':
        return 13.0;
      case 'large':
        return 18.0;
      default:
        return 15.5;
    }
  }

  BoxDecoration getWallpaperDecoration(BuildContext context) {
    String? path = _wallpaperId;
    if (path == null || path == 'default' || path.isEmpty) {
      return const BoxDecoration();
    }

    if (path.startsWith('assets/')) {
      return BoxDecoration(
        image: DecorationImage(
          image: AssetImage(path),
          fit: BoxFit.cover,
        ),
      );
    } else {
      return BoxDecoration(
        image: DecorationImage(
          image: FileImage(File(path)),
          fit: BoxFit.cover,
        ),
      );
    }
  }
}
