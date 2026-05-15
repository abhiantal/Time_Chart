import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_ui_provider.dart';
import '../../widgets/conversation/bubbles/message_bubble_base.dart';

import '../../../../widgets/error_handler.dart';

class ChatThemeScreen extends StatefulWidget {
  final String chatId;
  const ChatThemeScreen({super.key, required this.chatId});

  @override
  State<ChatThemeScreen> createState() => _ChatThemeScreenState();
}

class _ChatThemeScreenState extends State<ChatThemeScreen> {
  String _selectedTheme = 'default';
  String _selectedBubbleStyle = 'modern';
  String _selectedFontSize = 'medium';

  final List<Map<String, dynamic>> _themes = [
    {
      'id': 'default',
      'name': 'Default',
      'color': const Color(0xFF005C4B),
      'lightColor': const Color(0xFFD9FDD3),
    },
    {
      'id': 'ocean',
      'name': 'Ocean',
      'color': const Color(0xFF00615A),
      'lightColor': const Color(0xFFB2EBF2),
    },
    {
      'id': 'sunset',
      'name': 'Sunset',
      'color': const Color(0xFF8A3000),
      'lightColor': const Color(0xFFFFCC80),
    },
    {
      'id': 'forest',
      'name': 'Forest',
      'color': const Color(0xFF1B5E20),
      'lightColor': const Color(0xFFC8E6C9),
    },
    {
      'id': 'lavender',
      'name': 'Lavender',
      'color': const Color(0xFF4A148C),
      'lightColor': const Color(0xFFE1BEE7),
    },
    {
      'id': 'midnight',
      'name': 'Midnight',
      'color': const Color(0xFF1A237E),
      'lightColor': const Color(0xFFC5CAE9),
    },
  ];

  final List<Map<String, String>> _bubbleStyles = [
    {'id': 'whatsapp', 'name': 'WhatsApp'},
    {'id': 'modern', 'name': 'Modern'},
    {'id': 'ios', 'name': 'iOS Style'},
  ];

  final List<Map<String, String>> _fontSizes = [
    {'id': 'small', 'name': 'Small'},
    {'id': 'medium', 'name': 'Medium'},
    {'id': 'large', 'name': 'Large'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          'Chat Configuration',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilledButton.tonal(
              onPressed: _saveTheme,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          // Theme preview
          _buildThemePreview(theme, colorScheme, isDark),
          const SizedBox(height: 32),

          // Color themes
          const Text(
            'Color Theme',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: _themes.length,
            itemBuilder: (context, index) {
              final themeOption = _themes[index];
              final isSelected = _selectedTheme == themeOption['id'];
              final themeColor = isDark
                  ? themeOption['color']
                  : themeOption['lightColor'];

              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTheme = themeOption['id']);
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 
                      isSelected ? 0.5 : 0.2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? themeOption['color']
                          : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: themeOption['color'].withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: themeColor,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              themeOption['lightColor'],
                              themeOption['color'],
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: themeOption['color'].withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        themeOption['name'],
                        style: TextStyle(
                          color: isSelected
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Bubble style
          const Text(
            'Bubble Style',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _bubbleStyles.map((style) {
                final isSelected = _selectedBubbleStyle == style['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text(style['name']!),
                    selected: isSelected,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedBubbleStyle = style['id']!);
                      }
                    },
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),

          // Font size
          const Text(
            'Font Size',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: _fontSizes.map((size) {
                final isSelected = _selectedFontSize == size['id'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedFontSize = size['id']!);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        size['name']!,
                        style: TextStyle(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 48),

          // Reset button
          Center(
            child: TextButton.icon(
              onPressed: _resetToDefault,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reset to Defaults'),
              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemePreview(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final selectedTheme = _themes.firstWhere(
      (t) => t['id'] == _selectedTheme,
      orElse: () => _themes.first,
    );

    final activeSentColor = isDark
        ? selectedTheme['color']
        : selectedTheme['lightColor'];
    final activeTextColor = isDark ? Colors.white : const Color(0xFF111B21);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        image: const DecorationImage(
          image: AssetImage('assets/images/chat_wallpaper.jpg'),
          fit: BoxFit.cover,
          opacity: 0.05,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      selectedTheme['lightColor'],
                      selectedTheme['color'],
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.palette_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Preview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                    Text(
                      '${selectedTheme['name']} mode active',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildPreviewBubble(
                  isMe: false,
                  text:
                      'This is an example message showcasing the incoming bubble design.',
                  color: isDark ? const Color(0xFF202C33) : Colors.white,
                  textColor: activeTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildPreviewBubble(
                isMe: true,
                text: 'And here is how your sent messages will look! ✨',
                color: activeSentColor,
                textColor: activeTextColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBubble({
    required bool isMe,
    required String text,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
      ),
      child: Text(text, style: TextStyle(color: textColor)),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uiProvider = context.read<ChatUIProvider>();
      uiProvider.setActiveChatId(widget.chatId);
      setState(() {
        _selectedTheme = uiProvider.selectedTheme;
        _selectedBubbleStyle = uiProvider.bubbleStyle.name;
        _selectedFontSize = uiProvider.fontSize;
      });
    });
  }

  void _saveTheme() {
    HapticFeedback.mediumImpact();
    final uiProvider = context.read<ChatUIProvider>();

    uiProvider.setTheme(_selectedTheme);
    uiProvider.setFontSize(_selectedFontSize);

    // Map string back to enum
    final style = BubbleStyle.values.firstWhere(
      (e) => e.name == _selectedBubbleStyle,
      orElse: () => BubbleStyle.whatsapp,
    );
    uiProvider.setBubbleStyle(style);

    ErrorHandler.showSuccessSnackbar('Theme saved');
    Navigator.pop(context);
  }

  void _resetToDefault() {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedTheme = 'default';
      _selectedBubbleStyle = 'whatsapp';
      _selectedFontSize = 'medium';
    });

    final uiProvider = context.read<ChatUIProvider>();
    uiProvider.setTheme('default');
    uiProvider.setBubbleStyle(BubbleStyle.whatsapp);
    uiProvider.setFontSize('medium');

    ErrorHandler.showSuccessSnackbar('Reset to default');
  }
}
