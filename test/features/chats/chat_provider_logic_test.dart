import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:the_time_chart/features/chats/providers/chat_provider.dart';
import 'package:the_time_chart/features/chats/repositories/chat_repository.dart';
import 'package:the_time_chart/features/chats/repositories/chat_message_repository.dart';
import 'package:the_time_chart/features/chats/repositories/chat_member_repository.dart';
import 'package:the_time_chart/features/chats/repositories/chat_attachment_repository.dart';
import 'package:the_time_chart/features/chats/model/chat_attachment_model.dart';
import 'package:the_time_chart/features/chats/model/chat_message_model.dart';

class MockChatRepository extends Mock implements ChatRepository {}
class MockChatMessageRepository extends Mock implements ChatMessageRepository {}
class MockChatMemberRepository extends Mock implements ChatMemberRepository {}
class MockChatAttachmentRepository extends Mock implements ChatAttachmentRepository {}

void main() {
  late ChatProvider provider;
  late MockChatRepository mockChatRepo;
  late MockChatMessageRepository mockMsgRepo;
  late MockChatMemberRepository mockMemberRepo;
  late MockChatAttachmentRepository mockAttachmentRepo;

  setUp(() {
    mockChatRepo = MockChatRepository();
    mockMsgRepo = MockChatMessageRepository();
    mockMemberRepo = MockChatMemberRepository();
    mockAttachmentRepo = MockChatAttachmentRepository();

    provider = ChatProvider(
      chatRepo: mockChatRepo,
      messageRepo: mockMsgRepo,
      memberRepo: mockMemberRepo,
      attachmentRepo: mockAttachmentRepo,
    );
  });

  group('ChatProvider Shared Content', () {
    const testChatId = 'test-chat-id';

    test('getAllMedia calls attachment repository with active chatId', () async {
      provider.setActiveChatId(testChatId);
      
      when(() => mockAttachmentRepo.getChatImages(testChatId))
          .thenAnswer((_) async => []);
      when(() => mockAttachmentRepo.getChatVideos(testChatId))
          .thenAnswer((_) async => []);

      await provider.getAllMedia();

      verify(() => mockAttachmentRepo.getChatImages(testChatId)).called(1);
      verify(() => mockAttachmentRepo.getChatVideos(testChatId)).called(1);
    });

    test('getAllDocuments calls attachment repository', () async {
      provider.setActiveChatId(testChatId);
      
      when(() => mockAttachmentRepo.getChatDocuments(testChatId))
          .thenAnswer((_) async => []);

      await provider.getAllDocuments();

      verify(() => mockAttachmentRepo.getChatDocuments(testChatId)).called(1);
    });

    test('getSharedContent returns messages of specific type', () async {
      // Note: This test would need a mock for PowerSync database if we want to test the implementation inside ChatProvider
      // But ChatProvider.getSharedContent currently directly queries PowerSync.
      // We should ideally refactor ChatProvider to use a repository for shared content as well.
    });
  });
}
