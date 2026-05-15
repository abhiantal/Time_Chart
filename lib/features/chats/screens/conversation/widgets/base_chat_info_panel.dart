import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BaseChatInfoPanel extends StatefulWidget {
  final VoidCallback onClose;
  final Widget header;
  final Widget content;

  const BaseChatInfoPanel({
    super.key,
    required this.onClose,
    required this.header,
    required this.content,
  });

  @override
  State<BaseChatInfoPanel> createState() => BaseChatInfoPanelState();
}

class BaseChatInfoPanelState extends State<BaseChatInfoPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutQuint,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void closePanel() {
    HapticFeedback.lightImpact();
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop
        Positioned.fill(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: closePanel,
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
          ),
        ),
        // Panel
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 25,
                    offset: const Offset(-5, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  widget.header,
                  Expanded(child: widget.content),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
