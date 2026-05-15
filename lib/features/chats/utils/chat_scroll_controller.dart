// ================================================================
// CHAT SCROLL CONTROLLER - Production Ready
// ================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ChatScrollState {
  final bool isAtBottom;
  final bool isNearBottom;
  final bool isAtTop;
  final bool isScrollingUp;
  final int newMessageCount;
  final bool showScrollToBottom;

  const ChatScrollState({
    this.isAtBottom = true,
    this.isNearBottom = true,
    this.isAtTop = false,
    this.isScrollingUp = false,
    this.newMessageCount = 0,
    this.showScrollToBottom = false,
  });

  ChatScrollState copyWith({
    bool? isAtBottom,
    bool? isNearBottom,
    bool? isAtTop,
    bool? isScrollingUp,
    int? newMessageCount,
    bool? showScrollToBottom,
  }) {
    return ChatScrollState(
      isAtBottom: isAtBottom ?? this.isAtBottom,
      isNearBottom: isNearBottom ?? this.isNearBottom,
      isAtTop: isAtTop ?? this.isAtTop,
      isScrollingUp: isScrollingUp ?? this.isScrollingUp,
      newMessageCount: newMessageCount ?? this.newMessageCount,
      showScrollToBottom: showScrollToBottom ?? this.showScrollToBottom,
    );
  }
}

class ChatScrollController extends ChangeNotifier {
  late ScrollController scrollController;
  ChatScrollState _state = const ChatScrollState();
  final double _bottomThreshold;
  final double _topThreshold;
  final VoidCallback? onLoadMore;
  bool _loadMoreTriggered = false;
  final Map<String, GlobalKey> _messageKeys = {};
  String? _highlightedMessageId;
  Timer? _highlightTimer;
  bool _disposed = false;

  ChatScrollController({
    ScrollController? controller,
    this.onLoadMore,
    double bottomThreshold = 150,
    double topThreshold = 200,
  }) : _bottomThreshold = bottomThreshold,
       _topThreshold = topThreshold {
    scrollController = controller ?? ScrollController();
    scrollController.addListener(_onScroll);
  }

  ChatScrollState get state => _state;
  String? get highlightedMessageId => _highlightedMessageId;

  GlobalKey registerMessage(String messageId) {
    _messageKeys.putIfAbsent(messageId, () => GlobalKey());
    return _messageKeys[messageId]!;
  }

  void unregisterMessage(String messageId) {
    _messageKeys.remove(messageId);
  }

  Future<void> scrollToBottom({bool animated = true}) async {
    if (!scrollController.hasClients || _disposed) return;

    if (animated) {
      await scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      scrollController.jumpTo(0);
    }

    _updateState(
      _state.copyWith(
        newMessageCount: 0,
        showScrollToBottom: false,
        isAtBottom: true,
      ),
    );
  }

  Future<void> scrollToMessage(
    String messageId, {
    bool highlight = true,
    Duration highlightDuration = const Duration(seconds: 2),
  }) async {
    if (_disposed) return;

    final key = _messageKeys[messageId];
    if (key?.currentContext == null) return;

    await Scrollable.ensureVisible(
      key!.currentContext!,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      alignment: 0.3,
    );

    if (highlight) {
      _highlightedMessageId = messageId;
      notifyListeners();

      _highlightTimer?.cancel();
      _highlightTimer = Timer(highlightDuration, () {
        if (!_disposed) {
          _highlightedMessageId = null;
          notifyListeners();
        }
      });
    }
  }

  bool isMessageVisible(String messageId) {
    final key = _messageKeys[messageId];
    if (key?.currentContext == null) return false;

    final renderObject = key!.currentContext!.findRenderObject();
    if (renderObject == null) return false;

    final viewport = RenderAbstractViewport.of(renderObject);
    final offset = viewport.getOffsetToReveal(renderObject, 0.5);
    final currentOffset = scrollController.offset;
    final viewportHeight = scrollController.position.viewportDimension;

    return offset.offset >= currentOffset - 50 &&
        offset.offset <= currentOffset + viewportHeight + 50;
  }

  void onNewMessage({bool isFromMe = false}) {
    if (_disposed) return;

    if (isFromMe || _state.isNearBottom) {
      scrollToBottom();
      return;
    }

    _updateState(
      _state.copyWith(
        newMessageCount: _state.newMessageCount + 1,
        showScrollToBottom: true,
      ),
    );
  }

  void clearNewMessages() {
    if (_disposed) return;
    _updateState(
      _state.copyWith(newMessageCount: 0, showScrollToBottom: false),
    );
  }

  double? get currentOffset {
    if (!scrollController.hasClients) return null;
    return scrollController.offset;
  }

  void restorePosition(double offset) {
    if (!scrollController.hasClients || _disposed) return;
    scrollController.jumpTo(offset);
  }

  void _onScroll() {
    if (!scrollController.hasClients || _disposed) return;

    final offset = scrollController.offset;
    final maxExtent = scrollController.position.maxScrollExtent;
    final direction = scrollController.position.userScrollDirection;

    final isAtBottom = offset <= 0;
    final isNearBottom = offset <= _bottomThreshold;
    final isAtTop = offset >= maxExtent - _topThreshold;
    final isScrollingUp = direction == ScrollDirection.forward;
    final showFab =
        !isNearBottom && (!_state.isNearBottom || _state.newMessageCount > 0);

    _updateState(
      ChatScrollState(
        isAtBottom: isAtBottom,
        isNearBottom: isNearBottom,
        isAtTop: isAtTop,
        isScrollingUp: isScrollingUp,
        newMessageCount: isNearBottom ? 0 : _state.newMessageCount,
        showScrollToBottom: showFab,
      ),
    );

    if (isAtTop && !_loadMoreTriggered) {
      _loadMoreTriggered = true;
      onLoadMore?.call();
      Future.delayed(const Duration(seconds: 1), () {
        _loadMoreTriggered = false;
      });
    }
  }

  void _updateState(ChatScrollState newState) {
    if (_disposed || _state == newState) return;
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _highlightTimer?.cancel();
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    _messageKeys.clear();
    super.dispose();
  }
}
