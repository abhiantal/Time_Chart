import 'package:flutter/foundation.dart';
import 'package:the_time_chart/features/chats/model/chat_invite_model.dart';
import 'package:the_time_chart/features/chats/model/chat_model.dart';
import 'package:the_time_chart/features/chats/repositories/chat_invite_repository.dart';

class ChatInviteProvider extends ChangeNotifier {
  final ChatInviteRepository _repository;

  List<ChatInviteModel> _activeInvites = [];
  bool _isLoading = false;
  String? _error;

  ChatInviteProvider({ChatInviteRepository? repository})
    : _repository = repository ?? ChatInviteRepository();

  List<ChatInviteModel> get activeInvites => _activeInvites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadInvites(String chatId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _activeInvites = await _repository.getChatInvites(chatId, activeOnly: true);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ChatResult<ChatInviteModel>> createInvite({
    required String chatId,
    int? maxUses,
    Duration? expiresIn,
  }) async {
    final result = await _repository.createInvite(
      chatId: chatId,
      maxUses: maxUses,
      expiresAt: expiresIn != null ? DateTime.now().add(expiresIn) : null,
    );

    if (result.success && result.data != null) {
      _activeInvites.insert(0, result.data!);
      notifyListeners();
    }

    return result;
  }

  Future<ChatResult<void>> revokeInvite(String inviteId) async {
    final result = await _repository.revokeInvite(inviteId);
    if (result.success) {
      _activeInvites.removeWhere((i) => i.id == inviteId);
      notifyListeners();
    }
    return result;
  }

  Future<JoinResult> joinViaCode(String code) async {
    return await _repository.joinViaCode(code);
  }
}
