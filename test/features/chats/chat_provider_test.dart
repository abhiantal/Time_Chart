import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_time_chart/features/chats/providers/chat_message_provider.dart';
import 'package:the_time_chart/features/chats/repositories/chat_repository.dart';
import 'package:the_time_chart/features/chats/repositories/chat_message_repository.dart';
import 'package:the_time_chart/features/chats/repositories/chat_member_repository.dart';
import 'package:the_time_chart/features/chats/model/chat_model.dart';
import 'package:the_time_chart/features/chats/model/chat_member_model.dart';
import 'package:the_time_chart/features/chats/model/chat_message_model.dart';

class MockChatRepository extends Mock implements ChatRepository {}
class MockChatMessageRepository extends Mock implements ChatMessageRepository {}
class MockChatMemberRepository extends Mock implements ChatMemberRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatMessageProvider provider;
  late MockChatRepository mockChatRepo;
  late MockChatMessageRepository mockMsgRepo;
  late MockChatMemberRepository mockMemberRepo;

  setUp(() {
    mockChatRepo = MockChatRepository();
    mockMsgRepo = MockChatMessageRepository();
    mockMemberRepo = MockChatMemberRepository();

    SharedPreferences.setMockInitialValues({});

    provider = ChatMessageProvider(
      chatRepo: mockChatRepo,
      messageRepo: mockMsgRepo,
      memberRepo: mockMemberRepo,
    );
  });

  group('ChatMessageProvider', () {
    test('initial state is correct', () {
      expect(provider.state, ConversationState.initial);
      expect(provider.isLoading, false);
      expect(provider.activeChat, null);
    });

    test('openChat transitions state and loads data', () async {
      const chatId = 'chat-1';
      final chat = ChatModel(
        id: chatId,
        type: ChatType.oneOnOne,
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final member = ChatMemberModel(
        id: 'mem-1',
        chatId: chatId,
        userId: 'test-user',
        role: ChatMemberRole.member,
        joinedAt: DateTime.now(),
      );

      when(() => mockChatRepo.getChatById(chatId)).thenAnswer((_) async => chat);
      when(() => mockMemberRepo.getMember(chatId, any())).thenAnswer((_) async => member);
      when(() => mockChatRepo.watchChat(chatId)).thenAnswer((_) => Stream.value(chat));
      when(() => mockMsgRepo.watchMessages(chatId, limit: any(named: 'limit')))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockMsgRepo.watchPinnedMessages(chatId)).thenAnswer((_) => Stream.value([]));
      when(() => mockMemberRepo.watchChatMembers(chatId)).thenAnswer((_) => Stream.value([member]));
      when(() => mockMsgRepo.typingStream).thenAnswer((_) => Stream.value({}));
      when(() => mockMsgRepo.markAsRead(chatId)).thenAnswer((_) async {});

      await provider.initialize(userId: 'test-user');
      await provider.openChat(chatId);

      expect(provider.state, ConversationState.loaded);
      expect(provider.activeChat?.id, chatId);
      expect(provider.myMembership?.id, 'mem-1');
    });

    test('sendMessage clears reply mode', () async {
      const chatId = 'chat-1';
      final chat = ChatModel(
        id: chatId,
        type: ChatType.oneOnOne,
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final member = ChatMemberModel(
        id: 'mem-1',
        chatId: chatId,
        userId: 'test-user',
        role: ChatMemberRole.member,
        joinedAt: DateTime.now(),
      );

      // Mock setup for openChat
      when(() => mockChatRepo.getChatById(chatId)).thenAnswer((_) async => chat);
      when(() => mockMemberRepo.getMember(chatId, any())).thenAnswer((_) async => member);
      when(() => mockChatRepo.watchChat(chatId)).thenAnswer((_) => Stream.value(chat));
      when(() => mockMsgRepo.watchMessages(chatId, limit: any(named: 'limit')))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockMsgRepo.watchPinnedMessages(chatId)).thenAnswer((_) => Stream.value([]));
      when(() => mockMemberRepo.watchChatMembers(chatId)).thenAnswer((_) => Stream.value([member]));
      when(() => mockMsgRepo.typingStream).thenAnswer((_) => Stream.value({}));
      when(() => mockMsgRepo.markAsRead(chatId)).thenAnswer((_) async {});
      when(() => mockMsgRepo.sendMessage(
        chatId: any(named: 'chatId'),
        text: any(named: 'text'),
        replyToId: any(named: 'replyToId'),
      )).thenAnswer((_) async => 'new-msg-id');

      await provider.initialize(userId: 'test-user');
      await provider.openChat(chatId);
      
      provider.setReply(ChatMessageModel.text(
        id: 'msg-reply',
        chatId: chatId,
        senderId: 'other',
        text: 'hello',
      ));
      expect(provider.isReplyMode, true);

      await provider.sendMessage('hi');
      
      expect(provider.isReplyMode, false);
      verify(() => mockMsgRepo.sendMessage(
        chatId: chatId,
        text: 'hi',
        replyToId: 'msg-reply',
      )).called(1);
    });
  });
}
