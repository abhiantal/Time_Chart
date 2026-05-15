import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_time_chart/widgets/logger.dart';
import 'package:the_time_chart/features/chats/model/chat_model.dart';
import 'package:the_time_chart/features/chats/model/chat_message_model.dart';
import 'package:the_time_chart/features/chats/model/chat_attachment_model.dart';
import 'package:the_time_chart/features/chats/repositories/chat_repository.dart';
import 'package:the_time_chart/features/chats/repositories/chat_member_repository.dart';
import 'package:the_time_chart/features/chats/repositories/chat_message_repository.dart';
import 'package:the_time_chart/features/chats/repositories/chat_attachment_repository.dart';

class ChatProvider extends ChangeNotifier {
  final ChatMessageRepository _messageRepo;
  final ChatRepository _chatRepo;
  final ChatMemberRepository _memberRepo;
  final ChatAttachmentRepository _attachmentRepo;

  List<ChatModel> _chats = [];
  List<ChatModel> _archivedChats = [];
  List<ChatSearchResult> _universalResults = [];
  int _totalUnreadCount = 0;
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  String? _currentUserId;
  bool _isConnected = true;
  List<SearchHistoryEntry> _searchHistory = [];
  Map<String, List<String>> _typingMap = {};
  int _currentResultIndex = 0;
  String? _activeSearchChatId;
  Map<String, String> _drafts = {};

  StreamSubscription? _chatListSub;
  StreamSubscription? _unreadSub;
  StreamSubscription? _typingSub;

  ChatProvider({
    ChatMessageRepository? messageRepo,
    ChatRepository? chatRepo,
    ChatMemberRepository? memberRepo,
    ChatAttachmentRepository? attachmentRepo,
  }) : _messageRepo = messageRepo ?? ChatMessageRepository(),
       _chatRepo = chatRepo ?? ChatRepository(),
       _memberRepo = memberRepo ?? ChatMemberRepository(),
       _attachmentRepo = attachmentRepo ?? ChatAttachmentRepository();

  List<ChatModel> get chats => UnmodifiableListView(_chats);
  List<ChatModel> get archivedChats => UnmodifiableListView(_archivedChats);
  List<ChatSearchResult> get universalResults => UnmodifiableListView(_universalResults);

  // Search Helpers for UI
  bool get hasResults => _universalResults.isNotEmpty;
  
  List<ChatSearchResult> get chatResults => 
    _universalResults.where((r) => r.type == SearchResultType.chat).toList();
    
  List<ChatSearchResult> get messageSearchResults => 
    _universalResults.where((r) => r.type == SearchResultType.message).toList();
    
  List<ChatSearchResult> get messageResults => messageSearchResults;
    
  List<ChatSearchResult> get contactResults => 
    _universalResults.where((r) => r.type == SearchResultType.contact).toList();

  List<ChatSearchResult> get mediaResults => 
    _universalResults.where((r) => r.type == SearchResultType.media || (r.type == SearchResultType.message && r.message?.isMediaMessage == true)).toList();

  List<ChatMessageAttachmentModel> get allMediaResults => 
    mediaResults.expand((r) => r.message?.attachments ?? <ChatMessageAttachmentModel>[]).toList();

  Map<SearchResultType, List<ChatSearchResult>> get groupedUniversalResults {
    final Map<SearchResultType, List<ChatSearchResult>> grouped = {};
    for (final res in _universalResults) {
      grouped.putIfAbsent(res.type, () => []).add(res);
    }
    return grouped;
  }
  List<SearchHistoryEntry> get searchHistory => UnmodifiableListView(_searchHistory);
  int get totalUnreadCount => _totalUnreadCount;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  int get currentResultIndex => _currentResultIndex;
  int get totalSearchResults => _universalResults.length;
  String? get error => _error;
  String? get currentUserId => _currentUserId;
  bool get isConnected => _isConnected;

  bool isUserOnline(String userId) {
    return _typingMap.values.any((list) => list.contains(userId));
  }

  bool isTypingInChat(String chatId) {
    return _typingMap[chatId]?.isNotEmpty ?? false;
  }

  List<String> getTypingUsers(String chatId) {
    return _typingMap[chatId] ?? [];
  }

  Future<void> initialize({required String userId}) async {
    _currentUserId = userId;
    _chatRepo.setCurrentUserId(userId);
    _messageRepo.setCurrentUserId(userId);
    _startSubscriptions();
    
    _typingSub?.cancel();
    _typingSub = _messageRepo.typingStream.listen((map) {
      _typingMap = map;
      notifyListeners();
    });

    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('chat_draft_'));
    final Map<String, String> drafts = {};
    for (final key in keys) {
      final chatId = key.replaceFirst('chat_draft_', '');
      final text = prefs.getString(key);
      if (text != null && text.isNotEmpty) {
        drafts[chatId] = text;
      }
    }
    _drafts = drafts;
    notifyListeners();
  }

  bool hasDraft(String chatId) => _drafts.containsKey(chatId);
  String? getDraft(String chatId) => _drafts[chatId];

  void updateDraft(String chatId, String? text) {
    if (text == null || text.isEmpty) {
      _drafts.remove(chatId);
    } else {
      _drafts[chatId] = text;
    }
    notifyListeners();
  }

  void _startSubscriptions() {
    _chatListSub?.cancel();
    _unreadSub?.cancel();

    _isLoading = true;
    notifyListeners();

    _chatListSub = _chatRepo.watchChatList().listen((list) {
      _chats = list.where((c) => !c.isArchived).toList();
      _archivedChats = list.where((c) => c.isArchived).toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });

    _unreadSub = _chatRepo.watchTotalUnreadCount().listen((count) {
      _totalUnreadCount = count;
      notifyListeners();
    });
  }

  Future<void> refresh() async {
    _startSubscriptions();
  }

  Future<void> archiveChat(String chatId, bool archived) async {
    await _memberRepo.toggleArchive(chatId, archived);
  }

  Future<void> toggleArchive(String chatId, bool archived) => archiveChat(chatId, archived);

  Future<void> deleteChat(String chatId) async {
    await _chatRepo.deleteChat(chatId);
  }

  Future<void> pinChat(String chatId, bool pinned) async {
    await _memberRepo.togglePin(chatId, pinned);
  }

  Future<void> togglePin(String chatId, bool pinned) => pinChat(chatId, pinned);

  Future<void> muteChat(String chatId, bool muted, {Duration? muteDuration}) async {
    await _memberRepo.toggleMute(chatId, muted, muteDuration: muteDuration);
  }

  Future<void> toggleMute(String chatId, bool muted, {Duration? muteDuration}) => 
    muteChat(chatId, muted, muteDuration: muteDuration);

  Future<void> markChatAsRead(String chatId) async {
    await _chatRepo.markAsRead(chatId);
  }

  Future<ChatResult<String>> createGroupChat({
    required String name,
    required List<String> memberUserIds,
    String? avatar,
    String? description,
  }) async {
    return await _chatRepo.createGroupChat(
      name: name,
      memberUserIds: memberUserIds,
      avatar: avatar,
      description: description,
    );
  }

  Future<ChatResult<String>> createCommunityChat({
    required String name,
    required String categoryId,
    String? avatar,
    String? banner,
    String? description,
    bool requireApproval = false,
    List<String>? rules,
    ChatVisibility visibility = ChatVisibility.public,
  }) async {
    return await _chatRepo.createCommunityChat(
      name: name,
      categoryId: categoryId,
      avatar: avatar,
      banner: banner,
      description: description,
      requireApproval: requireApproval,
      rules: rules,
      visibility: visibility,
    );
  }

  Future<void> updateChatMetadata(String chatId, Map<String, dynamic> metadata) async {
    await _chatRepo.updateChatMetadata(chatId, metadata);
  }

  Future<void> updateChatInfo({
    required String chatId,
    String? name,
    String? description,
    String? avatar,
    String? banner,
    ChatVisibility? visibility,
  }) async {
    await _chatRepo.updateChatInfo(
      chatId: chatId,
      name: name,
      description: description,
      avatar: avatar,
      banner: banner,
      visibility: visibility,
    );
  }

  Future<ChatModel?> getChatById(String chatId) async {
    return _chatRepo.getChatById(chatId);
  }

  // ----------------------------------------------------------------------
  // COMMUNITY DISCOVERY
  // ----------------------------------------------------------------------

  Future<List<ChatModel>> getFeaturedCommunities() async {
    return _chatRepo.getFeaturedCommunities();
  }

  Future<List<ChatModel>> getTrendingCommunities() async {
    return _chatRepo.getTrendingCommunities();
  }

  Future<List<ChatModel>> getNewCommunities() async {
    return _chatRepo.getNewCommunities();
  }

  Future<List<ChatModel>> getPublicCommunities({
    String? categoryId,
    String? query,
    int limit = 20,
    String? sortBy,
  }) async {
    return _chatRepo.getPublicCommunities(
      categoryId: categoryId,
      query: query,
      limit: limit,
      sortBy: sortBy,
    );
  }

  Future<ChatResult<void>> joinCommunity(String chatId) async {
    final result = await _chatRepo.joinCommunity(chatId);
    if (result.success) {
      // Potentially refresh chat list or handle UI state
      refresh();
    }
    return result;
  }

  Future<ChatResult<void>> addMembers(String chatId, List<String> userIds) async {
    return await _memberRepo.addMembers(chatId, userIds);
  }

  void setActiveChatId(String? chatId) {
    _activeSearchChatId = chatId;
    notifyListeners();
  }

  Future<ChatResult<String>> getOrCreateDirectChat(String otherUserId) async {
    return await _chatRepo.getOrCreateDirectChat(otherUserId);
  }

  Future<void> searchNow(String query) async {
    if (query.isEmpty) {
      _universalResults = [];
      _isSearching = false;
      _currentResultIndex = 0;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _currentResultIndex = 0;
    notifyListeners();

    try {
      final List<ChatSearchResult> results = [];
      
      // 1. Search local chats
      final localChats = _chats.where((c) => 
        (c.name?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
        (c.description?.toLowerCase().contains(query.toLowerCase()) ?? false)
      );

      if (_activeSearchChatId == null) {
        for (final chat in localChats) {
          results.add(ChatSearchResult(
            id: chat.id,
            type: SearchResultType.chat,
            title: chat.name ?? 'Group',
            subtitle: chat.description,
            imageUrl: chat.avatar,
            chat: chat,
          ));
        }
      }

      // 2. Search PowerSync for messages
      final syncService = _chatRepo.getCurrentPowerSync();
      if (syncService != null) {
        try {
          final db = syncService.db;
          String sql = 'SELECT * FROM chat_messages WHERE text_content LIKE ?';
          List<dynamic> params = ['%$query%'];
          
          if (_activeSearchChatId != null) {
            sql += ' AND chat_id = ?';
            params.add(_activeSearchChatId!);
          }
          
          sql += ' ORDER BY created_at DESC LIMIT 50';

          final messageRows = await db.getAll(sql, params);
          
          for (final row in messageRows) {
            try {
              final msg = ChatMessageModel.fromJson(row);
              results.add(ChatSearchResult(
                id: msg.id,
                type: msg.type == ChatMessageType.system ? SearchResultType.mention : (msg.isMediaMessage ? SearchResultType.media : SearchResultType.message),
                title: msg.senderName ?? 'User',
                subtitle: msg.textContent ?? '',
                imageUrl: msg.senderAvatar,
                timestamp: msg.sentAt,
                message: msg,
                metadata: {'chat_id': msg.chatId, 'sender_id': msg.senderId},
              ));
            } catch (e) {
              logE('Error parsing message in search: $row', error: e);
            }
          }
        } catch (e) {
          logE('Global message search error', error: e);
        }
      }

      _universalResults = results;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSearching = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchChats(String query) {
    searchNow(query); // Delegate to unified search
  }

  void searchInChat(String query) {
    searchNow(query);
  }

  Future<List<ChatSearchResult>> searchContacts(String query) async {
    if (query.isEmpty) return [];
    
    final results = <ChatSearchResult>[];
    final syncService = _chatRepo.getCurrentPowerSync();
    if (syncService != null) {
      try {
        final db = syncService.db;
        final rows = await db.getAll(
          'SELECT * FROM user_profiles WHERE display_name LIKE ? OR username LIKE ? LIMIT 20',
          ['%$query%', '%$query%']
        );
        
        for (final row in rows) {
          results.add(ChatSearchResult(
            id: row['user_id'] as String,
            type: SearchResultType.contact,
            title: row['display_name'] as String? ?? row['username'] as String? ?? 'User',
            subtitle: row['username'] as String?,
            imageUrl: row['profile_url'] as String?,
            metadata: {'bio': row['bio']},
          ));
        }
      } catch (e) {
        logE('Contact search error', error: e);
      }
    }
    return results;
  }

  Future<List<ChatMessageAttachmentModel>> getAllMedia() async {
    if (_activeSearchChatId == null) return [];
    final images = await _attachmentRepo.getChatImages(_activeSearchChatId!);
    final videos = await _attachmentRepo.getChatVideos(_activeSearchChatId!);
    return [...images, ...videos];
  }

  Future<List<ChatMessageAttachmentModel>> getAllDocuments() async {
    if (_activeSearchChatId == null) return [];
    return await _attachmentRepo.getChatDocuments(_activeSearchChatId!);
  }

  Future<List<ExtractedLink>> getAllLinks() async {
    if (_activeSearchChatId == null) return [];
    // Query messages with links
    final syncService = _chatRepo.getCurrentPowerSync();
    if (syncService == null) return [];
    
    final rows = await syncService.db.getAll(
      "SELECT id, chat_id, text_content, created_at FROM chat_messages WHERE chat_id = ? AND text_content LIKE '%http%'",
      [_activeSearchChatId!]
    );
    
    final links = <ExtractedLink>[];
    for (final row in rows) {
      final content = row['text_content'] as String;
      final urlRegExp = RegExp(r"(https?:\/\/[^\s]+)");
      final matches = urlRegExp.allMatches(content);
      for (final match in matches) {
        links.add(ExtractedLink(
          url: match.group(0)!,
          messageId: row['id'] as String,
          chatId: row['chat_id'] as String,
          timestamp: DateTime.parse(row['created_at'] as String),
        ));
      }
    }
    return links;
  }

  Future<List<ChatMessageModel>> getSharedContent({required SharedContentType type}) async {
    if (_activeSearchChatId == null) return [];
    final syncService = _chatRepo.getCurrentPowerSync();
    if (syncService == null) return [];
    
    final rows = await syncService.db.getAll(
      "SELECT * FROM chat_messages WHERE chat_id = ? AND shared_content_type = ? ORDER BY created_at DESC",
      [_activeSearchChatId!, type.toJson()]
    );
    
    return rows.map((r) => ChatMessageModel.fromJson(r)).toList();
  }

  void nextResult() {
    if (_currentResultIndex < totalSearchResults - 1) {
      _currentResultIndex++;
      notifyListeners();
    }
  }

  void previousResult() {
    if (_currentResultIndex > 0) {
      _currentResultIndex--;
      notifyListeners();
    }
  }

  // History Methods
  void clearHistory() {
    _searchHistory = [];
    notifyListeners();
  }

  void deleteHistoryEntry(String id) {
    _searchHistory.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void searchFromHistory(SearchHistoryEntry entry) {
    searchNow(entry.query);
  }

  void clearAll() {
    searchNow('');
  }

  Future<String> sendSharedContent({
    required String chatId,
    required String type,
    String? contentId,
    String? textContent,
    Map<String, dynamic>? snapshot,
  }) async {
    final messageId = await _messageRepo.sendSharedContent(
      chatId: chatId,
      type: type,
      contentId: contentId,
      textContent: textContent,
      snapshot: snapshot,
    );
    return messageId;
  }

  @override
  void dispose() {
    _chatListSub?.cancel();
    _unreadSub?.cancel();
    _typingSub?.cancel();
    super.dispose();
  }
}
