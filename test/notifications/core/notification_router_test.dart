import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:the_time_chart/notifications/core/notification_handler_interface.dart';
import 'package:the_time_chart/notifications/core/notification_types.dart';

class MockNotificationHandler extends Mock implements NotificationHandler {}
class MockBuildContext extends Mock implements BuildContext {}

void main() {
  late NotificationRouter router;
  late MockNotificationHandler mockHandler;

  setUp(() {
    router = NotificationRouter();
    router.clearHandlers();
    mockHandler = MockNotificationHandler();
    
    when(() => mockHandler.handlerId).thenReturn('test_handler');
    when(() => mockHandler.supportedTypes).thenReturn([NotificationType.chatMessage]);
    when(() => mockHandler.supports(any())).thenAnswer((invocation) {
      return invocation.positionalArguments[0] == NotificationType.chatMessage;
    });
  });

  group('NotificationRouter', () {
    test('registerHandler should add handler to list', () {
      router.registerHandler(mockHandler);
      expect(router.handlers.length, 1);
      expect(router.handlers.first.handlerId, 'test_handler');
    });

    test('getHandler should return correct handler for type', () {
      router.registerHandler(mockHandler);
      final found = router.getHandler(NotificationType.chatMessage);
      expect(found, mockHandler);
    });

    test('routeTap should delegate to handler', () async {
      final context = MockBuildContext();
      final data = NotificationData(type: 'chat_message', title: 'T', body: 'B');
      
      router.registerHandler(mockHandler);
      when(() => mockHandler.handleNotificationTap(any(), any())).thenAnswer((_) async => true);

      final result = await router.routeTap(context, data);
      
      expect(result, true);
      verify(() => mockHandler.handleNotificationTap(context, data)).called(1);
    });
  });
}
