import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:the_time_chart/widgets/logger.dart';
import 'package:the_time_chart/features/chats/model/chat_model.dart';
import 'package:the_time_chart/features/chats/model/chat_message_model.dart';
import 'package:the_time_chart/features/chats/model/chat_member_model.dart';
import 'package:the_time_chart/features/chats/repositories/chat_repository.dart';
import 'package:the_time_chart/features/chats/repositories/chat_message_repository.dart';
import 'package:the_time_chart/features/chats/repositories/chat_member_repository.dart';
import 'package:the_time_chart/features/chats/utils/chat_text_utils.dart';

enum ConversationState { initial, loading, loaded, error }

class ChatMessageProvider extends ChangeNotifier {
  final ChatMessageRepository _messageRepo;
  final ChatRepository _chatRepo;
  final ChatMemberRepository _memberRepo;
  SharedPreferences? _prefs;

  // -- State --
  ConversationState _state = ConversationState.initial;
  ChatModel? _activeChat;
  ChatMemberModel? _myMembership;
  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  // Pagination
  int _messageLimit = 50;
  bool _hasMore = true;

  List<ChatMemberModel> _members = [];

  // Realtime
  List<String> _typingUserIds = [];

  // Inputs
  String? _replyToId;
  ChatMessageModel? _replyToMessage;
  ChatMessageModel? _editMessage;
  bool _isEditing = false;

  // Subscriptions
  StreamSubscription? _chatWatchSub;
  StreamSubscription? _msgSub;
  StreamSubscription? _pinnedSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _memberSub;

  bool _initialized = false;

  ChatMessageProvider({
    ChatMessageRepository? messageRepo,
    ChatRepository? chatRepo,
    ChatMemberRepository? memberRepo,
  }) : _messageRepo = messageRepo ?? ChatMessageRepository(),
       _chatRepo = chatRepo ?? ChatRepository(),
       _memberRepo = memberRepo ?? ChatMemberRepository();

  // -- Getters --
  bool get initialized => _initialized;
  ConversationState get state => _state;
  ChatModel? get activeChat => _activeChat;
  String? get activeChatId => _activeChat?.id;
  ChatMemberModel? get myMembership => _myMembership;
  List<ChatMessageModel> get messages => _messages;
  List<ChatMemberModel> get members => _members;
  List<ChatMessageModel> _pinned = [];
  List<ChatMessageModel> get pinnedMessages => _pinned;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUserId => _currentUserId;

  List<String> get typingUserIds => _typingUserIds;
  bool get isReplyMode => _replyToId != null;
  ChatMessageModel? get replyToMessage => _replyToMessage;
  bool get isEditing => _isEditing;
  ChatMessageModel? get editMessage => _editMessage;
  
  // Unified getter for whichever is active
  ChatMessageModel? get actionMessage => _editMessage ?? _replyToMessage;

  bool get canSendMessage {
    if (_activeChat == null || _myMembership == null) return false;
    // Group permissions
    if (_activeChat!.type == ChatType.group || _activeChat!.type == ChatType.community) {
      if (_activeChat!.whoCanSend == ChatPermission.admins && !_myMembership!.role.isAdmin) {
        return false;
      }
    }
    return _myMembership!.isActive;
  }

  bool get isConnected => true;

  String? getDraft(String chatId) {
    return _prefs?.getString('chat_draft_$chatId');
  }

  void saveDraft(String chatId, String text) {
    if (text.isEmpty) {
      _prefs?.remove('chat_draft_$chatId');
    } else {
      _prefs?.setString('chat_draft_$chatId', text);
    }
  }

  String getPresenceText(String userId) {
    if (isUserOnline(userId)) return 'Online';
    return 'Offline';
  }

  // -- Lifecycle --
  Future<void> initialize({required String userId}) async {
    _currentUserId = userId;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    notifyListeners();
  }

  Future<void> openChat(String chatId) async {
    if (_activeChat?.id == chatId) return;

    _isLoading = true;
    _state = ConversationState.loading;
    _error = null;
    notifyListeners();

    try {
      ChatModel? chat;
      ChatMemberModel? membership;

      int retries = 5;
      final effectiveUserId = _currentUserId ?? _messageRepo.currentUserId;
      
      while (retries > 0) {
        chat = await _chatRepo.getChatById(chatId);
        membership = await _memberRepo.getMember(chatId, effectiveUserId ?? '');

        if (chat != null && membership != null) break;

        await Future.delayed(const Duration(milliseconds: 800));
        retries--;
      }

      _activeChat = chat;
      _myMembership = membership;

      if (_activeChat == null) {
        _state = ConversationState.error;
        _error = 'Chat not available.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _watchChatData(chatId);
      _subscribeToMessages(chatId);
      _subscribeToPinned(chatId);
      _subscribeToMembers(chatId);

      _typingSub?.cancel();
      _typingSub = _messageRepo.typingStream.listen((data) {
        _typingUserIds = data[chatId] ?? [];
        notifyListeners();
      });

      try {
        await _messageRepo.markAsRead(chatId);
      } catch (_) {}

      _state = ConversationState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = ConversationState.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _watchChatData(String chatId) {
    _chatWatchSub?.cancel();
    _chatWatchSub = _chatRepo.watchChat(chatId).listen((chat) {
      if (chat != null) {
        _activeChat = chat;
        notifyListeners();
      }
    });
  }

  void _subscribeToMessages(String chatId) {
    _msgSub?.cancel();
    _msgSub = _messageRepo.watchMessages(chatId, limit: _messageLimit).listen((msgs) {
      final sorted = List<ChatMessageModel>.from(msgs);
      sorted.sort((a, b) {
        final cmp = b.sentAt.compareTo(a.sentAt);
        if (cmp != 0) return cmp;
        return b.id.compareTo(a.id);
      });
      _messages = sorted;
      if (msgs.length < _messageLimit) {
        _hasMore = false;
      }
      notifyListeners();
    });
  }

  void _subscribeToPinned(String chatId) {
    _pinnedSub?.cancel();
    _pinnedSub = _messageRepo.watchPinnedMessages(chatId).listen((pins) {
      _pinned = pins;
      notifyListeners();
    });
  }

  void _subscribeToMembers(String chatId) {
    _memberSub?.cancel();
    _memberSub = _memberRepo.watchChatMembers(chatId).listen((members) {
      _members = members;
      _myMembership = members.where((m) => m.userId == _currentUserId).firstOrNull ?? _myMembership;
      notifyListeners();
    });
  }

  Future<void> loadMore() async {
    if (_activeChat == null || !_hasMore || _isLoading) return;
    _messageLimit += 30;
    _subscribeToMessages(_activeChat!.id);
  }

  void closeChat() {
    _activeChat = null;
    _myMembership = null;
    _messages = [];
    _chatWatchSub?.cancel();
    _msgSub?.cancel();
    _pinnedSub?.cancel();
    _memberSub?.cancel();
    _typingSub?.cancel();
    _replyToId = null;
    _replyToMessage = null;
    _state = ConversationState.initial;
    notifyListeners();
  }

  // -- Actions --

  void setReply(ChatMessageModel message) {
    _replyToId = message.id;
    _replyToMessage = message;
    notifyListeners();
  }

  void clearReply() {
    _replyToId = null;
    _replyToMessage = null;
    notifyListeners();
  }

  void setEdit(ChatMessageModel message) {
    _editMessage = message;
    _isEditing = true;
    _replyToId = null;
    _replyToMessage = null;
    notifyListeners();
  }

  void clearEdit() {
    _editMessage = null;
    _isEditing = false;
    notifyListeners();
  }

  void clearAction() {
    clearReply();
    clearEdit();
  }

  void onTyping() {
    if (_activeChat != null) {
      _messageRepo.sendTyping(_activeChat!.id, true);
    }
  }

  void onStopTyping() {
    if (_activeChat != null) {
      _messageRepo.sendTyping(_activeChat!.id, false);
    }
  }

  Future<void> sendMessage(String text) async {
    if (_activeChat == null || text.trim().isEmpty) return;
    
    final chatId = _activeChat!.id;
    final replyId = _replyToId;
    
    // Extract mentioned user IDs from the markdown-like syntax @[Name](userId)
    final mentionedUserIds = ChatTextUtils.extractMentions(text);
    
    clearReply();
    try {
      await _messageRepo.sendMessage(
        chatId: chatId,
        text: text,
        replyToId: replyId,
        mentionedUserIds: mentionedUserIds.isNotEmpty ? mentionedUserIds : null,
      );
      // Clear draft after sending
      saveDraft(chatId, '');
    } catch (e) {
      logE('Failed to send text message', error: e);
    }
  }

  Future<void> sendSharedContent({
    required SharedContentType contentType,
    String? contentId,
    String? text,
    Map<String, dynamic>? snapshot,
  }) async {
    if (_activeChat == null) return;
    try {
      await _messageRepo.sendSharedContent(
        chatId: _activeChat!.id,
        type: contentType.toJson()!,
        contentId: contentId,
        textContent: text,
        snapshot: snapshot,
        replyToId: _replyToId,
      );
      clearReply();
    } catch (e) {
      logE('Failed to send shared content', error: e);
    }
  }

  Future<void> sendSharedPollMessage({
    required String question,
    required List<String> options,
    required int durationMinutes,
    bool allowMultiple = false,
  }) async {
    await sendSharedContent(
      contentType: SharedContentType.chatPoll,
      text: question,
      snapshot: {
        'question': question,
        'options': options.map((text) => {
          'id': const Uuid().v4(),
          'text': text,
          'votes': 0,
        }).toList(),
        'duration_minutes': durationMinutes,
        'allow_multiple': allowMultiple,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'total_votes': 0,
      },
    );
  }

  Future<void> voteInPoll({
    required String messageId,
    required String optionId,
  }) async {
    try {
      await _messageRepo.voteInPoll(
        messageId: messageId,
        optionId: optionId,
      );
    } catch (e) {
      logE('Failed to vote in poll', error: e);
      rethrow;
    }
  }

  Future<void> sendSharedTaskMessage({
    required String title,
    String? description,
    required DateTime dueDate,
  }) async {
    await sendSharedContent(
      contentType: SharedContentType.chatTask,
      text: title,
      snapshot: {
        'title': title,
        'description': description,
        'due_date': dueDate.toUtc().toIso8601String(),
        'status': 'pending',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<void> deleteMessageForEveryone(String messageId) async {
    await _messageRepo.deleteMessageForEveryone(messageId);
  }

  Future<void> deleteMessageForMe(String messageId) async {
    await _messageRepo.deleteMessageForMe(messageId);
  }

  Future<void> deleteChat() async {
    if (_activeChat == null) return;
    await _chatRepo.deleteChat(_activeChat!.id);
  }

  Future<void> leaveGroup() async {
    if (_activeChat == null || _currentUserId == null) return;
    await _memberRepo.removeMember(_activeChat!.id, _currentUserId!);
  }

  bool isUserOnline(String userId) {
    return _typingUserIds.contains(userId);
  }

  Future<void> togglePinMessage(String messageId, bool pinned) async {
    await _messageRepo.pinMessage(messageId, pinned);
  }

  Future<ChatResult<String>> toggleReaction(String messageId, String emoji) async {
    return await _messageRepo.toggleReaction(messageId, emoji);
  }

  // -- Member Management --
  bool get canPromote => _myMembership?.role.isAdmin ?? false;
  bool get canDemote => _myMembership?.role.isOwner ?? false;
  bool get canRemove => _myMembership?.role.isAdmin ?? false;

  Future<void> promoteMember(String userId) async {
    if (_activeChat == null) return;
    await _memberRepo.updateRole(_activeChat!.id, userId, 'admin');
  }

  Future<void> demoteMember(String userId) async {
    if (_activeChat == null) return;
    await _memberRepo.updateRole(_activeChat!.id, userId, 'member');
  }

  Future<void> removeMember(String userId) async {
    if (_activeChat == null) return;
    await _memberRepo.removeMember(_activeChat!.id, userId);
  }

  Future<void> toggleBlock(bool blocked) async {
    if (_activeChat == null) return;
    await _memberRepo.toggleBlock(_activeChat!.id, blocked);
    _myMembership = _myMembership?.copyWith(isBlocked: blocked);
    notifyListeners();
  }

  Future<void> toggleMute(bool muted, {Duration? muteDuration}) async {
    if (_activeChat == null) return;
    await _memberRepo.toggleMute(_activeChat!.id, muted,
        muteDuration: muteDuration);
    _myMembership = _myMembership?.copyWith(isMuted: muted);
    notifyListeners();
  }

  Future<void> togglePin(bool pinned) async {
    if (_activeChat == null) return;
    await _memberRepo.togglePin(_activeChat!.id, pinned);
    _myMembership = _myMembership?.copyWith(isPinned: pinned);
    notifyListeners();
  }

  Future<void> toggleArchive(bool archived) async {
    if (_activeChat == null) return;
    await _memberRepo.toggleArchive(_activeChat!.id, archived);
    _myMembership = _myMembership?.copyWith(isArchived: archived);
    notifyListeners();
  }

  Future<void> blockUser(String userId) async {
    if (_activeChat == null) return;
    await _memberRepo.toggleBlock(_activeChat!.id, true);
  }

  Future<ChatResult<String>> forwardMessage({
    required String messageId,
    required String toChatId,
  }) async {
    return await _messageRepo.forwardMessage(
      messageId: messageId,
      toChatId: toChatId,
    );
  }

  Future<void> clearChatHistory() async {
    if (_activeChat == null) return;
    try {
      await _messageRepo.clearChatHistory(_activeChat!.id);
    } catch (e) {
      logE('Error clearing chat history', error: e);
      rethrow;
    }
  }

  @override
  void dispose() {
    _chatWatchSub?.cancel();
    _msgSub?.cancel();
    _pinnedSub?.cancel();
    _memberSub?.cancel();
    _typingSub?.cancel();
    super.dispose();
  }
}
