import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/features/social/post/models/post_model.dart';
import 'package:the_time_chart/features/social/post/providers/post_provider.dart';
import 'reels_player.dart';

class ReelsFeed extends StatefulWidget {
  final String currentUserId;
  final List<PostModel>? initialReels;
  final int initialIndex;

  const ReelsFeed({
    super.key,
    required this.currentUserId,
    this.initialReels,
    this.initialIndex = 0,
  });

  @override
  State<ReelsFeed> createState() => _ReelsFeedState();
}

class _ReelsFeedState extends State<ReelsFeed> {
  late PageController _pageController;
  late List<PostModel> _reels;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;

    if (widget.initialReels != null) {
      _reels = widget.initialReels!;
    } else {
      _loadReels();
    }
  }

  @override
  void didUpdateWidget(covariant ReelsFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialReels != null && widget.initialReels != oldWidget.initialReels) {
      setState(() {
        _reels = widget.initialReels!;
        // Ensure index is still valid
        if (_currentIndex >= _reels.length) {
          _currentIndex = _reels.isEmpty ? 0 : _reels.length - 1;
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadReels() async {
    final provider = context.read<PostProvider>();
    
    if (provider.feedPosts.isEmpty) {
      await provider.loadHomeFeed(refresh: true);
    }
    
    if (!mounted) return;
    
    setState(() {
      _reels = provider.feedPosts
          .map((f) => f.post)
          .where(
            (p) =>
                p.hasMedia ||
                p.postType == PostType.video ||
                p.postType == PostType.reel,
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_reels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No reels yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _reels.length,
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
      },
      itemBuilder: (context, index) {
        final reel = _reels[index];
        return ReelsPlayer(
          reel: reel,
          isActive: index == _currentIndex,
          autoPlay: true,
          onNext: index < _reels.length - 1
              ? () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              : null,
          onPrevious: index > 0
              ? () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              : null,
        );
      },
    );
  }
}
