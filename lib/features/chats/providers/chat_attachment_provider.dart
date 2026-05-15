import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:the_time_chart/features/chats/model/chat_model.dart';
import 'package:the_time_chart/features/chats/model/chat_attachment_model.dart';
import 'package:uuid/uuid.dart';
import '../repositories/chat_attachment_repository.dart';
import '../repositories/chat_repository.dart';

enum MediaProviderState {
  idle,
  loading,
  loaded,
  error;

  bool get isLoading => this == loading;
  bool get isLoaded => this == loaded;
  bool get isError => this == error;
}

enum MediaGalleryTab { all, images, videos, documents, audio }

class MediaSelection {
  final File file;
  final AttachmentType type;
  final String? caption;

  const MediaSelection({required this.file, required this.type, this.caption});

  String get fileName => p.basename(file.path);

  ChatMediaUploadTask toUploadTask() =>
      ChatMediaUploadTask(id: const Uuid().v4(), file: file, type: type);
}

class ChatAttachmentProvider extends ChangeNotifier {
  late final ChatAttachmentRepository _attachmentRepo;
  late final ChatRepository _chatRepo;

  bool _initialized = false;
  bool _disposed = false;

  MediaProviderState _state = MediaProviderState.idle;
  String? _errorMessage;

  String? _activeChatId;

  MediaGalleryTab _activeTab = MediaGalleryTab.all;
  List<ChatMessageAttachmentModel> _galleryItems = [];
  Map<String, ChatMediaUploadTask> _uploadProgress = {};

  final List<MediaSelection> _selectedMedia = [];
  String? _mediaCaption;

  // Recording state
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  List<double> _waveform = [];
  String? _recordedFilePath;

  final List<StreamSubscription> _subscriptions = [];

  ChatAttachmentProvider({
    ChatAttachmentRepository? attachmentRepo,
    ChatRepository? chatRepo,
  }) : _attachmentRepo = attachmentRepo ?? ChatAttachmentRepository(),
       _chatRepo = chatRepo ?? ChatRepository();

  bool get initialized => _initialized;
  MediaProviderState get state => _state;
  String? get activeChatId => _activeChatId;

  List<ChatMessageAttachmentModel> get galleryItems =>
      UnmodifiableListView(_galleryItems);
  Map<String, ChatMediaUploadTask> get uploadProgress =>
      UnmodifiableMapView(_uploadProgress);
  List<MediaSelection> get selectedMedia =>
      UnmodifiableListView(_selectedMedia);

  // Recording getters
  bool get isRecording => _isRecording;
  Duration get recordDuration => _recordDuration;
  List<double> get waveform => _waveform;
  String? get recordedFilePath => _recordedFilePath;

  Future<void> initialize() async {
    if (_initialized) return;
    _subscriptions.add(
      _attachmentRepo.uploadProgressStream.listen((progress) {
        _uploadProgress = progress;
        _safeNotify();
      }),
    );
    _initialized = true;
  }

  void setActiveChatId(String? chatId) {
    if (_activeChatId == chatId) return;
    _activeChatId = chatId;
    _galleryItems = [];
    if (chatId != null) {
      _startGalleryStream(chatId);
    }
    _safeNotify();
  }

  void _startGalleryStream(String chatId) {
    _subscriptions.add(
      _attachmentRepo.watchMediaGallery(chatId).listen((items) {
        _galleryItems = items;
        _safeNotify();
      }),
    );
  }

  void addMediaToSelection(MediaSelection media) {
    _selectedMedia.add(media);
    _safeNotify();
  }

  void clearSelectedMedia() {
    _selectedMedia.clear();
    _mediaCaption = null;
    _safeNotify();
  }

  Future<ChatResult<String>> sendSelectedMedia({String? replyToId}) async {
    if (_activeChatId == null) return ChatResult.fail('No active chat');
    if (_selectedMedia.isEmpty) return ChatResult.fail('No media selected');

    final tasks = _selectedMedia.map((s) => s.toUploadTask()).toList();

    final result = await _attachmentRepo.uploadAndSendMedia(
      chatId: _activeChatId!,
      tasks: tasks,
      chatRepo: _chatRepo,
      caption: _mediaCaption,
      replyToId: replyToId,
    );

    if (result.success) {
      clearSelectedMedia();
    }

    return result;
  }

  // Recording methods
  void startRecording() {
    _isRecording = true;
    _recordDuration = Duration.zero;
    _waveform = [];
    _recordedFilePath = null;
    _safeNotify();
  }

  void updateRecordingDuration(Duration duration) {
    _recordDuration = duration;
    _safeNotify();
  }

  void updateWaveform(List<double> values) {
    _waveform = values;
    _safeNotify();
  }

  void stopRecording(String? path) {
    _isRecording = false;
    _recordedFilePath = path;
    _safeNotify();
  }

  void cancelRecording() {
    _isRecording = false;
    _recordDuration = Duration.zero;
    _waveform = [];
    _recordedFilePath = null;
    _safeNotify();
  }

  // Sending helpers
  Future<ChatResult<String>> sendVoiceNote() async {
    if (_activeChatId == null || _recordedFilePath == null) {
      return ChatResult.fail('Nothing to send');
    }

    final result = await _attachmentRepo.uploadAndSendVoiceNote(
      chatId: _activeChatId!,
      audioFile: File(_recordedFilePath!),
      durationSeconds: _recordDuration.inSeconds,
      chatRepo: _chatRepo,
    );

    if (result.success) {
      cancelRecording();
    }
    return result;
  }

  Future<ChatResult<String>> sendFile({
    required File file,
    required AttachmentType type,
  }) async {
    if (_activeChatId == null) return ChatResult.fail('No active chat');

    final task = ChatMediaUploadTask(
      id: const Uuid().v4(),
      file: file,
      type: type,
    );

    return await _attachmentRepo.uploadAndSendMedia(
      chatId: _activeChatId!,
      tasks: [task],
      chatRepo: _chatRepo,
    );
  }

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}
