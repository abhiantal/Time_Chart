import 'package:flutter/material.dart';

class FeedRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final bool isRefreshing;

  const FeedRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: theme.colorScheme.primary,
      backgroundColor: theme.cardColor,
      child: Stack(
        children: [
          child,
          if (isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                      theme.colorScheme.primary,
                    ],
                  ),
                ),
                child: const LinearProgressIndicator(
                  value: null,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
