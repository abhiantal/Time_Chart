// ================================================================
// FILE: lib/features/chat/widgets/common/loading_shimmer_list.dart
// PURPOSE: Shimmer loading effects for chat lists and messages
// STYLE: Facebook/WhatsApp shimmer effect
// DEPENDENCIES: None - Pure widget
// ================================================================

import 'package:flutter/material.dart';

class LoadingShimmerList extends StatefulWidget {
  final int itemCount;
  final bool showDividers;
  final ShimmerType type;

  const LoadingShimmerList({
    super.key,
    this.itemCount = 8,
    this.showDividers = false,
    this.type = ShimmerType.chatList,
  });

  @override
  State<LoadingShimmerList> createState() => _LoadingShimmerListState();
}

enum ShimmerType { chatList, messages, members, media, search }

class _LoadingShimmerListState extends State<LoadingShimmerList>
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

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
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
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(
                slidePercent: _animation.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (widget.type) {
      case ShimmerType.chatList:
        return _buildChatListShimmer();
      case ShimmerType.messages:
        return _buildMessagesShimmer();
      case ShimmerType.members:
        return _buildMembersShimmer();
      case ShimmerType.media:
        return _buildMediaShimmer();
      case ShimmerType.search:
        return _buildSearchShimmer();
    }
  }

  Widget _buildChatListShimmer() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.itemCount,
      separatorBuilder: (_, __) => widget.showDividers
          ? const Divider(height: 1, indent: 76)
          : const SizedBox.shrink(),
      itemBuilder: (context, index) => const _ChatTileShimmer(),
    );
  }

  Widget _buildMessagesShimmer() {
    return ListView.builder(
      reverse: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: 10,
      itemBuilder: (context, index) {
        final isMe = index % 3 == 0;
        final showAvatar =
            index == 0 || (index % 3 == 0) != ((index - 1) % 3 == 0);
        return _MessageShimmer(isMe: isMe, showAvatar: showAvatar);
      },
    );
  }

  Widget _buildMembersShimmer() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) => const _MemberTileShimmer(),
    );
  }

  Widget _buildMediaShimmer() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: 12,
      itemBuilder: (context, index) => Container(color: Colors.grey[300]),
    );
  }

  Widget _buildSearchShimmer() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) => const _SearchTileShimmer(),
    );
  }
}

// ================================================================
// SHIMMER TILES
// ================================================================

class _ChatTileShimmer extends StatelessWidget {
  const _ChatTileShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        width: 120,
                        height: 14,
                        color: Colors.grey[300],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 40, height: 12, color: Colors.grey[300]),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 12,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageShimmer extends StatelessWidget {
  final bool isMe;
  final bool showAvatar;

  const _MessageShimmer({required this.isMe, required this.showAvatar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 64 : 16,
        right: isMe ? 16 : 64,
        top: 4,
        bottom: 4,
      ),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 6),
                bottomRight: Radius.circular(isMe ? 6 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 180, height: 12, color: Colors.grey[400]),
                const SizedBox(height: 6),
                Container(width: 120, height: 12, color: Colors.grey[400]),
              ],
            ),
          ),
          if (isMe && showAvatar) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberTileShimmer extends StatelessWidget {
  const _MemberTileShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 100, height: 14, color: Colors.grey[300]),
                const SizedBox(height: 6),
                Container(width: 60, height: 10, color: Colors.grey[300]),
              ],
            ),
          ),
          Container(width: 50, height: 24, color: Colors.grey[300]),
        ],
      ),
    );
  }
}

class _SearchTileShimmer extends StatelessWidget {
  const _SearchTileShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 140, height: 14, color: Colors.grey[300]),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  height: 12,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// SLIDING GRADIENT TRANSFORM
// ================================================================

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

// ================================================================
// SIMPLE SHIMMER BOX - For inline use
// ================================================================

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  const ShimmerBox.circle({super.key, required double size})
    : width = size,
      height = size,
      borderRadius = 0,
      shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius)
            : null,
        shape: shape,
      ),
    );
  }
}
