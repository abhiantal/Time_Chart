import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_time_chart/notifications/core/notification_handler_interface.dart';
import 'package:the_time_chart/notifications/core/notification_types.dart';
import 'package:the_time_chart/notifications/handlers/notification_handlers.dart';

// =============================================================================
// MOCKS
// =============================================================================

class MockGoRouter extends Mock implements GoRouter {}

class MockConnectivity extends Mock implements Connectivity {}

// A helper widget to provide a mocked GoRouter to the context
class MockGoRouterProvider extends StatelessWidget {
  final GoRouter goRouter;
  final Widget child;

  const MockGoRouterProvider({
    super.key,
    required this.goRouter,
    required this.child,
  });

  @override
  Widget build(BuildContext context) =>
      InheritedGoRouter(goRouter: goRouter, child: child);
}

class MockLocalStorage extends LocalStorage {
  const MockLocalStorage();
  @override
  Future<void> initialize() async {}
  @override
  Future<String?> getItem(String key) async => null;
  @override
  Future<void> setItem(String key, String value) async {}
  @override
  Future<void> removeItem(String key) async {}
  @override
  Future<bool> hasItem(String key) async => false;
  @override
  Future<String?> accessToken() async => null;
  @override
  Future<bool> hasAccessToken() async => false;
  @override
  Future<void> persistSession(String persistSessionString) async {}
  @override
  Future<void> removePersistedSession() async {}
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});

    // Mock the Connectivity platform channel to avoid MissingPluginException
    const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'check') {
        return ['wifi'];
      }
      return null;
    });

    // Stub Connectivity
    final mockConnectivity = MockConnectivity();
    when(
      () => mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => Stream.value([ConnectivityResult.wifi]));
    when(
      () => mockConnectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);

    // Initialize Supabase with dummy values for testing
    await Supabase.initialize(
      url: 'https://placeholder.supabase.co',
      anonKey: 'placeholder',
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        localStorage: MockLocalStorage(),
      ),
    );
    registerFallbackValue(
      NotificationData(type: 'default', title: '', body: ''),
    );
  });

  group('Notification System Integration Tests', () {
    late NotificationRouter router;
    late MockGoRouter mockGoRouter;

    setUp(() {
      router = NotificationRouter();
      router.clearHandlers();
      mockGoRouter = MockGoRouter();

      // Register all real handlers manually to avoid side effects of NotificationSetup singleton
      final handlers = [
        DayTaskNotificationHandler(),
        WeekTaskNotificationHandler(),
        DiaryNotificationHandler(),
        ChatNotificationHandler(),
        SocialNotificationHandler(),
        SystemNotificationHandler(),
        LongGoalsNotificationHandler(),
        BucketNotificationHandler(),
        AiNotificationHandler(),
        CompetitionNotificationHandler(),
        LeaderboardNotificationHandler(),
        MentoringNotificationHandler(),
        DashboardNotificationHandler(),
      ];

      for (var handler in handlers) {
        router.registerHandler(handler);
      }

      // Stub GoRouter methods
      when(
        () => mockGoRouter.pushNamed(
          any(),
          pathParameters: any(named: 'pathParameters'),
          queryParameters: any(named: 'queryParameters'),
          extra: any(named: 'extra'),
        ),
      ).thenAnswer((_) async => null);

      when(
        () => mockGoRouter.goNamed(
          any(),
          pathParameters: any(named: 'pathParameters'),
          queryParameters: any(named: 'queryParameters'),
          extra: any(named: 'extra'),
        ),
      ).thenReturn(null);
    });

    test('All NotificationType enum values have a registered handler', () {
      final missingTypes = <NotificationType>[];
      for (final type in NotificationType.values) {
        if (type == NotificationType.defaultType) continue;
        if (router.getHandler(type) == null) missingTypes.add(type);
      }
      expect(
        missingTypes,
        isEmpty,
        reason:
            'Missing handlers for: ${missingTypes.map((e) => e.value).join(', ')}',
      );
    });

    testWidgets(
      'CompetitionNotificationHandler navigates to battle screen when battleId present',
      (WidgetTester tester) async {
        final handler = CompetitionNotificationHandler();
        final data = NotificationData(
          type: 'competition_added_as_member',
          title: 'Challenge',
          body: 'Body',
          targetId: 'battle_123',
          data: {'battle_id': 'battle_123'},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MockGoRouterProvider(
              goRouter: mockGoRouter,
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () =>
                        handler.handleNotificationTap(context, data),
                    child: const Text('Tap'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Tap'));

        verify(
          () => mockGoRouter.pushNamed(
            'competitionDetailScreen',
            pathParameters: {'competitorId': 'battle_123'},
          ),
        ).called(1);
      },
    );

    testWidgets('LongGoalsNotificationHandler navigates to detail screen', (
      WidgetTester tester,
    ) async {
      final handler = LongGoalsNotificationHandler();
      final data = NotificationData(
        type: 'long_goal_milestone',
        title: 'Milestone',
        body: 'Progress',
        targetId: 'goal_456',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MockGoRouterProvider(
            goRouter: mockGoRouter,
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => handler.handleNotificationTap(context, data),
                  child: const Text('Tap'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));

      verify(
        () => mockGoRouter.pushNamed(
          'longGoalDetailScreen',
          pathParameters: {'goalId': 'goal_456'},
        ),
      ).called(1);
    });

    testWidgets(
      'ChatNotificationHandler navigates to group chat when type is group',
      (WidgetTester tester) async {
        final handler = ChatNotificationHandler();
        final data = NotificationData(
          type: 'chat_message',
          title: 'Group',
          body: 'Msg',
          targetId: 'chat_789',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MockGoRouterProvider(
              goRouter: mockGoRouter,
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () =>
                        handler.handleNotificationTap(context, data),
                    child: const Text('Tap'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Tap'));

        verify(
          () => mockGoRouter.pushNamed(
            'chatDetailScreen',
            pathParameters: {'chatId': 'chat_789'},
          ),
        ).called(1);
      },
    );

    testWidgets('SocialNotificationHandler navigates to profile for follow', (
      WidgetTester tester,
    ) async {
      final handler = SocialNotificationHandler();
      final data = NotificationData(
        type: 'follow',
        title: 'Follow',
        body: 'User',
        targetId: 'user_001',
        data: {'userId': 'user_001'},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MockGoRouterProvider(
            goRouter: mockGoRouter,
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => handler.handleNotificationTap(context, data),
                  child: const Text('Tap'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));

      verify(
        () => mockGoRouter.pushNamed(
          'otherUserProfileScreen',
          pathParameters: {'userId': 'user_001'},
        ),
      ).called(1);
    });

    testWidgets('DashboardNotificationHandler navigates to dashboard', (
      WidgetTester tester,
    ) async {
      final handler = DashboardNotificationHandler();
      final data = NotificationData(
        type: 'dashboard_new_reward',
        title: 'T',
        body: 'B',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MockGoRouterProvider(
            goRouter: mockGoRouter,
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => handler.handleNotificationTap(context, data),
                  child: const Text('Tap'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));

      verify(() => mockGoRouter.goNamed('dashboardScreen')).called(1);
    });

    test('DashboardNotificationHandler provides custom display', () async {
      final handler = DashboardNotificationHandler();
      final data = NotificationData(
        type: 'dashboard_new_reward',
        title: 'T',
        body: 'B',
      );
      final display = await handler.customNotificationDisplay(data);
      expect(display, isNotNull);
      expect(display!['title'], contains('Reward'));
    });
  });
}
