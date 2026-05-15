// ================================================================
// FILE: lib/features/chat/widgets/common/connection_banner.dart
// PURPOSE: Banner showing connection status (connecting/offline)
// STYLE: WhatsApp-style colored banner with animation
// DEPENDENCIES: None - Pure widget
// ================================================================

import 'package:flutter/material.dart';

enum ConnectionState {
  connected,
  connecting,
  disconnected,
  reconnecting,
  error,
}

class ConnectionBanner extends StatefulWidget {
  final ConnectionState state;
  final VoidCallback? onRetry;
  final Duration displayDuration;
  final bool autoDismiss;

  const ConnectionBanner({
    super.key,
    this.state = ConnectionState.disconnected,
    this.onRetry,
    this.displayDuration = const Duration(seconds: 10),
    this.autoDismiss = true,
  });

  // Factory constructors
  const ConnectionBanner.connecting({super.key})
    : state = ConnectionState.connecting,
      onRetry = null,
      displayDuration = const Duration(seconds: 10),
      autoDismiss = false;

  const ConnectionBanner.disconnected({super.key, this.onRetry})
    : state = ConnectionState.disconnected,
      displayDuration = const Duration(seconds: 10),
      autoDismiss = true;

  const ConnectionBanner.reconnecting({super.key})
    : state = ConnectionState.reconnecting,
      onRetry = null,
      displayDuration = const Duration(seconds: 10),
      autoDismiss = false;

  @override
  State<ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends State<ConnectionBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    if (widget.autoDismiss && widget.state == ConnectionState.disconnected) {
      Future.delayed(widget.displayDuration, _dismiss);
    }
  }

  void _dismiss() {
    if (mounted && !_isDismissed) {
      setState(() => _isDismissed = true);
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBanner(context),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (widget.state) {
      case ConnectionState.connected:
        return _buildConnectedBanner(theme, colorScheme);
      case ConnectionState.connecting:
        return _buildConnectingBanner(theme, colorScheme);
      case ConnectionState.disconnected:
        return _buildDisconnectedBanner(theme, colorScheme);
      case ConnectionState.reconnecting:
        return _buildReconnectingBanner(theme, colorScheme);
      case ConnectionState.error:
        return _buildErrorBanner(theme, colorScheme);
    }
  }

  Widget _buildConnectedBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.green,
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Connected',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: _dismiss,
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 20,
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectingBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colorScheme.primary,
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Connecting...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colorScheme.error,
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: colorScheme.onError, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No internet connection',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onError,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (widget.onRetry != null) ...[
            TextButton(
              onPressed: () {
                widget.onRetry!();
                _dismiss();
              },
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onError,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
              child: const Text('Retry'),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            onPressed: _dismiss,
            icon: Icon(
              Icons.close_rounded,
              color: colorScheme.onError,
              size: 20,
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildReconnectingBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.orange,
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.onError,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Reconnecting...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onError,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colorScheme.error,
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colorScheme.onError,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Connection error',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onError,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: _dismiss,
            icon: Icon(
              Icons.close_rounded,
              color: colorScheme.onError,
              size: 20,
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}
