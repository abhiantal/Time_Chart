import 'dart:async';
import 'package:flutter/material.dart';
import 'package:the_time_chart/features/social/post/providers/post_provider.dart';
import '../screens/feed_screen.dart';

class FeedController {
  final PostProvider _postProvider;
  final String _currentUserId;
  final ScrollController scrollController = ScrollController();

  FeedController({
    required PostProvider postProvider,
    required String currentUserId,
  }) : _postProvider = postProvider,
       _currentUserId = currentUserId;

  FeedType _currentFeedType = FeedType.home;
  Timer? _debounceTimer;
  bool _isLoadingMore = false;

  Future<void> loadInitialPosts() async {
    await _postProvider.loadHomeFeed(refresh: true);
  }

  Future<void> refreshFeed() async {
    switch (_currentFeedType) {
      case FeedType.trending:
        await _postProvider.loadExploreFeed(refresh: true);
        break;
      default:
        await _postProvider.loadHomeFeed(refresh: true);
        break;
    }
  }

  Future<void> loadMorePosts() async {
    if (_isLoadingMore) return;
    if (_debounceTimer?.isActive ?? false) return;

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      _isLoadingMore = true;
      try {
        switch (_currentFeedType) {
          case FeedType.trending:
            if (_postProvider.hasMoreExplore &&
                !_postProvider.isLoadingExplore) {
              await _postProvider.loadExploreFeed();
            }
            break;
          default:
            if (_postProvider.hasMoreFeed && !_postProvider.isLoadingFeed) {
              await _postProvider.loadHomeFeed();
            }
            break;
        }
      } finally {
        _isLoadingMore = false;
      }
    });
  }

  void changeFeedType(FeedType type) {
    if (_currentFeedType == type) return;
    _currentFeedType = type;
    refreshFeed();
  }

  void dispose() {
    _debounceTimer?.cancel();
    scrollController.dispose();
  }
}
