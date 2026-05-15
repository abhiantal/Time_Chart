import 'package:flutter/material.dart';

class FeedSkeleton extends StatelessWidget {
  final bool isDark;

  const FeedSkeleton({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Row(
            children: [
              _buildShimmer(width: 44, height: 44, borderRadius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmer(width: 120, height: 16),
                    const SizedBox(height: 8),
                    _buildShimmer(width: 80, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content skeleton
          _buildShimmer(width: double.infinity, height: 16),
          const SizedBox(height: 8),
          _buildShimmer(width: double.infinity, height: 16),
          const SizedBox(height: 8),
          _buildShimmer(width: 200, height: 16),
          const SizedBox(height: 16),

          // Media skeleton
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),

          // Stats skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShimmer(width: 100, height: 14),
              Row(
                children: [
                  _buildShimmer(width: 40, height: 14),
                  const SizedBox(width: 16),
                  _buildShimmer(width: 40, height: 14),
                  const SizedBox(width: 16),
                  _buildShimmer(width: 40, height: 14),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Divider
          Container(height: 1, color: Colors.grey[300]),
          const SizedBox(height: 16),

          // Actions skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              4,
              (index) => _buildShimmer(width: 60, height: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer({
    required double width,
    required double height,
    double borderRadius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// Shimmer effect wrapper
class ShimmerEffect extends StatefulWidget {
  final Widget child;

  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_animation.value, 0),
              end: const Alignment(1, 0),
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}
