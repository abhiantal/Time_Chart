// ================================================================
// FILE: lib/features/chat/widgets/search/search_bar_animated.dart
// PURPOSE: Animated search bar with expand/collapse
// STYLE: WhatsApp-style animated search
// ================================================================

import 'package:flutter/material.dart';

class SearchBarAnimated extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final bool autofocus;
  final double height;

  const SearchBarAnimated({
    super.key,
    required this.controller,
    this.focusNode,
    required this.hintText,
    required this.onChanged,
    this.onClear,
    this.autofocus = false,
    this.height = 48,
  });

  @override
  State<SearchBarAnimated> createState() => _SearchBarAnimatedState();
}

class _SearchBarAnimatedState extends State<SearchBarAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    _widthAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        widget.controller.clear();
                        widget.onChanged('');
                        widget.onClear?.call();
                      },
                      icon: const Icon(Icons.clear_rounded, size: 18),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
      },
    );
  }
}
