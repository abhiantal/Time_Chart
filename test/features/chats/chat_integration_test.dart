import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_time_chart/features/chats/providers/chat_message_provider.dart';
import 'package:the_time_chart/features/chats/repositories/chat_repository.dart';
import 'package:the_time_chart/features/chats/repositories/chat_message_repository.dart';
import 'package:the_time_chart/features/chats/repositories/chat_member_repository.dart';
import 'package:the_time_chart/features/chats/model/chat_model.dart';
import 'package:the_time_chart/features/chats/model/chat_member_model.dart';

class MockChatRepository extends Mock implements ChatRepository {}
class MockChatMessageRepository extends Mock implements ChatMessageRepository {}
class MockChatMemberRepository extends Mock implements ChatMemberRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockChatRepository mockChatRepo;
  late MockChatMessageRepository mockMsgRepo;
  late MockChatMemberRepository mockMemberRepo;

  setUp(() {
    mockChatRepo = MockChatRepository();
    mockMsgRepo = MockChatMessageRepository();
    mockMemberRepo = MockChatMemberRepository();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Chat Integration Flow: Open Chat and Send Message', (WidgetTester tester) async {
    final chatId = 'chat-123';
    final userId = 'user-456';

    final chat = ChatModel(
      id: chatId,
      type: ChatType.oneOnOne,
      createdBy: 'system',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final member = ChatMemberModel(
      id: 'mem-1',
      chatId: chatId,
      userId: userId,
      role: ChatMemberRole.member,
      joinedAt: DateTime.now(),
    );

    // Mock setup
    when(() => mockChatRepo.getChatById(chatId)).thenAnswer((_) async => chat);
    when(() => mockMemberRepo.getMember(chatId, userId)).thenAnswer((_) async => member);
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
    )).thenAnswer((_) async => 'new-msg-id');

    // Build the provider-wrapped widget
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ChatMessageProvider>(
            create: (_) {
              final p = ChatMessageProvider(
                chatRepo: mockChatRepo,
                messageRepo: mockMsgRepo,
                memberRepo: mockMemberRepo,
              );
              p.initialize(userId: userId);
              return p;
            },
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer<ChatMessageProvider>(
              builder: (context, provider, _) {
                if (provider.state == ConversationState.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.activeChat == null) {
                  return ElevatedButton(
                    onPressed: () => provider.openChat(chatId),
                    child: const Text('Open Chat'),
                  );
                }
                return Column(
                  children: [
                    Text('Chat: ${provider.activeChat!.id}'),
                    ElevatedButton(
                      onPressed: () => provider.sendMessage('Hello Integration'),
                      child: const Text('Send Message'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    // 1. Initial State
    expect(find.text('Open Chat'), findsOneWidget);

    // 2. Open Chat
    await tester.tap(find.text('Open Chat'));
    await tester.pumpAndSettle();

    expect(find.text('Chat: $chatId'), findsOneWidget);

    // 3. Send Message
    await tester.tap(find.text('Send Message'));
    await tester.pump();

    verify(() => mockMsgRepo.sendMessage(
      chatId: chatId,
      text: 'Hello Integration',
    )).called(1);
  });
}
