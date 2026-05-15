import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:the_time_chart/features/chats/model/chat_member_model.dart';
import 'package:the_time_chart/features/chats/repositories/chat_member_repository.dart';
import 'package:the_time_chart/features/chats/model/chat_model.dart'; // For ChatResult

class ChatMemberProvider extends ChangeNotifier {
  final ChatMemberRepository _repository;
  
  List<ChatMemberModel> _members = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _memberSub;

  ChatMemberProvider({ChatMemberRepository? repository})
    : _repository = repository ?? ChatMemberRepository();

  List<ChatMemberModel> get members => _members;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void watchMembers(String chatId) {
    _memberSub?.cancel();
    _isLoading = true;
    notifyListeners();

    _memberSub = _repository.watchChatMembers(chatId).listen((list) {
      _members = list;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<ChatResult<void>> addMembers(String chatId, List<String> userIds) async {
    return await _repository.addMembers(chatId, userIds);
  }

  Future<void> updateRole(String chatId, String userId, ChatMemberRole role) async {
    try {
      await _repository.updateRole(chatId, userId, role.toJson());
      // Local state is updated by the stream
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeMember(String chatId, String userId) async {
    try {
      await _repository.removeMember(chatId, userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _memberSub?.cancel();
    super.dispose();
  }
}
