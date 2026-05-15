// ================================================================
// FILE: lib/core/app_setup.dart
// Central setup file - Add new services/providers here
// ================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../Authentication/auth_provider.dart';
import '../../ai_services/services/token_manager_service.dart';
import '../../ai_services/services/universal_ai_service.dart';

import '../../features/chats/providers/chat_provider.dart';
import '../../features/chats/providers/chat_member_provider.dart';
import '../../features/chats/providers/chat_message_provider.dart';
import '../../features/chats/providers/chat_attachment_provider.dart';
import '../../features/chats/providers/chat_invite_provider.dart';
import '../../features/chats/providers/chat_ui_provider.dart';
import '../../features/chats/repositories/chat_repository.dart';
import '../../features/chats/repositories/chat_member_repository.dart';
import '../../features/chats/repositories/chat_message_repository.dart';
import '../../features/chats/repositories/chat_attachment_repository.dart';
import '../../features/chats/repositories/chat_invite_repository.dart';

import '../../features/analytics/competition/providers/competition_provider.dart';
import '../../features/analytics/dashboard/providers/user_dashboard_provider.dart';
import '../../features/analytics/leaderboard/providers/user_stats_provider.dart';
import '../../features/analytics/mentoring/providers/mentorship_provider.dart';

import '../../features/personal/diary_model/providers/diary_ai_provider.dart';
import '../../features/personal/category_model/providers/category_provider.dart';
import '../../features/personal/task_model/day_tasks/providers/day_task_provider.dart';
import '../../features/personal/task_model/long_goal/providers/long_goals_provider.dart';
import '../../features/personal/task_model/week_task/providers/week_task_provider.dart';
import '../../features/personal/bucket_model/providers/bucket_provider.dart';

import '../../features/social/saves/providers/save_provider.dart';
import '../../features/social/views/providers/post_view_provider.dart';
import '../../features/social/comments/providers/comment_provider.dart';
import '../../features/social/follow/providers/follow_provider.dart';
import '../../features/social/reactions/providers/reaction_provider.dart';
import '../../features/social/post/providers/post_provider.dart';
import '../../features/social/post/providers/post_ui_provider.dart';

import '../../notifications/notification_setup.dart';
import '../../notifications/presentation/providers/notification_provider.dart';
import '../../services/powersync_service.dart';
import '../../services/supabase_service.dart';
import '../../user_profile/create_edit_profile/profile_provider.dart';
import '../../user_settings/providers/settings_provider.dart';
import '../../widgets/logger.dart';

/// Central app setup - manages all services and providers
/// THIS IS YOUR MAIN CONTROL CENTER - ADD ALL NEW PROVIDERS HERE
class AppSetup {
  // Singleton pattern - ensures only one instance exists
  static final AppSetup _instance = AppSetup._internal();
  factory AppSetup() => _instance;
  AppSetup._internal();

  // ================================================================
  // SERVICE INSTANCES (Lazy Initialization)
  // ================================================================
  SupabaseService? _supabase;
  PowerSyncService? _powerSync;
  NotificationSetup? _notificationSetup;
  UniversalAIService? _aiService;
  TokenManagerService? _tokenManager;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ================================================================
  // SERVICE GETTERS WITH VALIDATION
  // ================================================================

  SupabaseService get supabase {
    final instance = SupabaseService.instance;
    if (!instance.isInitialized) {
      throw Exception(
        'Supabase not initialized. Call initializeServices() first.',
      );
    }
    return instance;
  }

  PowerSyncService get powerSync {
    final instance = PowerSyncService();
    if (!instance.isInitialized) {
      throw Exception(
        'PowerSync not initialized. Call initializeServices() first.',
      );
    }
    return instance;
  }

  NotificationSetup get notificationSetup {
    if (_notificationSetup == null || !_notificationSetup!.isInitialized) {
      throw Exception('Notification system not initialized.');
    }
    return _notificationSetup!;
  }

  UniversalAIService get aiService {
    _aiService ??= UniversalAIService();
    return _aiService!;
  }

  TokenManagerService get tokenManager {
    _tokenManager ??= TokenManagerService();
    return _tokenManager!;
  }

  // ================================================================
  // INITIALIZATION (Called by AppInitializer)
  // ================================================================

  /// Initialize core services only
  /// Other services are initialized by AppInitializer
  Future<void> initializeServices() async {
    if (_isInitialized) {
      logI('✓ AppSetup already initialized');
      return;
    }

    try {
      logI('🚀 Initializing AppSetup...');

      // Supabase should already be initialized in main.dart
      _supabase = SupabaseService.instance;
      if (!_supabase!.isInitialized) {
        throw Exception('Supabase must be initialized before AppSetup');
      }
      logI('✓ Supabase service linked');

      // Initialize PowerSync (but don't connect sync yet)
      _powerSync = PowerSyncService();
      await _powerSync!.initialize();
      logI('✓ PowerSync service initialized');

      // Initialize AI Services (no external dependencies)
      _aiService = UniversalAIService();
      _tokenManager = TokenManagerService();
      logI('✓ AI services prepared');

      _isInitialized = true;
      logI('✅ AppSetup initialization completed');
    } catch (e, stackTrace) {
      logE(
        '❌ AppSetup initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
      _isInitialized = false;
      rethrow;
    }
  }

  /// Initialize Notification System
  /// Called separately by AppInitializer
  Future<void> initializeNotificationSystem({BuildContext? context}) async {
    try {
      _notificationSetup = NotificationSetup();
      await _notificationSetup!.initialize(context: context);
      logI('✓ Notification system initialized');
    } catch (e, stackTrace) {
      logE(
        '⚠️ Notification system initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - app can work without notifications
      logI('⚠️ Continuing without notifications');
    }
  }

  /// Update notification context (call from main widget)
  void updateNotificationContext(BuildContext context) {
    if (_notificationSetup != null && _notificationSetup!.isInitialized) {
      _notificationSetup!.updateContext(context);
      logI('✓ Notification context updated');
    }
  }

  // ================================================================
  // PROVIDER SETUP
  // ================================================================

  /// Get all providers for the app
  /// ⭐ ADD NEW PROVIDERS HERE AS YOU CREATE THEM ⭐
  static List<SingleChildWidget> getProviders() {
    return [
      // Provide PowerSyncService instance WITHOUT triggering initialization here
      Provider<PowerSyncService>.value(value: PowerSyncService()),
      // ⭐ Auth Provider - MUST BE FIRST
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(),
        lazy: true, // Lazy load to ensure Supabase is ready
      ),

      // ⭐ User Profile Provider
      ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
        create: (_) => ProfileProvider(),
        update: (_, auth, provider) => provider!..updateAuth(auth),
        lazy: true, // Lazy load
      ),

      // ⭐ Day Task Provider
      ChangeNotifierProvider<DayTaskProvider>(
        create: (_) => DayTaskProvider(),
        lazy: true,
      ),
      // ⭐ Long Goals Provider
      ChangeNotifierProvider<LongGoalsProvider>(
        create: (_) => LongGoalsProvider(),
        lazy: true,
      ),
      // ⭐ Week Task Provider
      ChangeNotifierProxyProvider<AuthProvider, WeekTaskProvider>(
        create: (_) => WeekTaskProvider(),
        update: (_, auth, provider) => provider!..updateAuth(auth),
        lazy: true,
      ),
      // ⭐ Category Provider
      ChangeNotifierProxyProvider<AuthProvider, CategoryProvider>(
        create: (_) => CategoryProvider(),
        update: (_, auth, provider) => provider!..updateAuth(auth),
        lazy: true,
      ),
      // ⭐ Bucket Provider
      ChangeNotifierProvider<BucketProvider>(
        create: (_) => BucketProvider(),
        lazy: true,
      ),
      // ⭐ Chats Provider (Chat 1/5)
      ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
        create: (_) => ChatProvider(
          chatRepo: ChatRepository(),
          memberRepo: ChatMemberRepository(),
        ),
        update: (_, auth, chatProvider) {
          if (auth.currentUser?.id != null) {
            chatProvider!.initialize(userId: auth.currentUser!.id);
          }
          return chatProvider!;
        },
        lazy: true,
      ),

      // ⭐ Chat Member Provider (Chat 2/5)
      ChangeNotifierProvider<ChatMemberProvider>(
        create: (_) => ChatMemberProvider(
          repository: ChatMemberRepository(),
        ),
        lazy: true,
      ),

      // ⭐ Chat Message Provider (Chat 3/5)
      ChangeNotifierProxyProvider<AuthProvider, ChatMessageProvider>(
        create: (_) => ChatMessageProvider(
          messageRepo: ChatMessageRepository(),
          chatRepo: ChatRepository(),
          memberRepo: ChatMemberRepository(),
        ),
        update: (_, auth, provider) {
          if (auth.currentUser?.id != null) {
            provider!.initialize(userId: auth.currentUser!.id);
          }
          return provider!;
        },
        lazy: true,
      ),

      // ⭐ Chat Attachment Provider (Chat 4/5)
      ChangeNotifierProxyProvider<AuthProvider, ChatAttachmentProvider>(
        create: (_) => ChatAttachmentProvider(
          attachmentRepo: ChatAttachmentRepository(),
          chatRepo: ChatRepository(),
        ),
        update: (_, auth, provider) {
          if (auth.currentUser?.id != null && !provider!.initialized) {
            provider.initialize();
          }
          return provider!;
        },
        lazy: true,
      ),

      // ⭐ Chat Invite Provider (Chat 5/5)
      ChangeNotifierProvider<ChatInviteProvider>(
        create: (_) => ChatInviteProvider(
          repository: ChatInviteRepository(),
        ),
        lazy: true,
      ),
      
      // ⭐ Chat UI Provider
      ChangeNotifierProvider<ChatUIProvider>(
        create: (_) => ChatUIProvider()..initialize(),
        lazy: true,
      ),
      //--------------------------------------------------------------------------------------------------------------------------------------

      // ⭐ Comment Provider
      ChangeNotifierProvider<CommentProvider>(
        create: (_) => CommentProvider(),
        lazy: true,
      ),
      // ⭐ Follow Provider
      ChangeNotifierProvider<FollowProvider>(
        create: (_) => FollowProvider(),
        lazy: true,
      ),
      // ⭐ Like Provider
      ChangeNotifierProvider<ReactionProvider>(
        create: (_) => ReactionProvider(),
        lazy: true,
      ),
      // ⭐ Post Provider
      ChangeNotifierProvider<PostProvider>(
        create: (_) => PostProvider(),
        lazy: true,
      ),
      // ⭐ Post UI Provider
      ChangeNotifierProvider<PostUIProvider>(
        create: (_) => PostUIProvider(),
        lazy: true,
      ),
      // Save Provider
      ChangeNotifierProvider<SaveProvider>(
        create: (_) => SaveProvider(),
        lazy: true,
      ),
      // ⭐ View Provider
      ChangeNotifierProvider<PostViewProvider>(
        create: (_) => PostViewProvider(),
        lazy: true,
      ),
      // ⭐ Diary AI Provider
      ChangeNotifierProvider<DiaryAIProvider>(
        create: (_) => DiaryAIProvider(),
        lazy: true,
      ),

      //--------------------------------------------------------------------------------------------------------------------------
      // ⭐ Dashboard Providers
      ChangeNotifierProvider<UserDashboardProvider>(
        create: (_) => UserDashboardProvider(),
        lazy: true,
      ),
      ChangeNotifierProvider<LeaderboardProvider>(
        create: (_) => LeaderboardProvider(),
        lazy: true,
      ),
      ChangeNotifierProxyProvider<AuthProvider, BattleChallengeProvider>(
        create: (_) => BattleChallengeProvider(),
        update: (_, auth, provider) => provider!..updateAuth(auth),
        lazy: true,
      ),

      ChangeNotifierProvider<MentorshipProvider>(
        create: (_) => MentorshipProvider(),
        lazy: true,
      ),
      //------------------------------------------------------------------------------------------------------------------------------------------------

      // ⭐ Notification Provider
      ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
        create: (_) => NotificationProvider(),
        update: (_, auth, provider) => provider!..updateAuth(auth),
        lazy: true,
      ),
      // ⭐ Settings Provider
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(),
        lazy: true,
      ),
    ];
  }

  // ================================================================
  // SERVICE STATUS
  // ================================================================

  /// Get status of all services
  Map<String, bool> getServicesStatus() {
    return {
      'Supabase': _supabase?.isInitialized ?? false,
      'PowerSync': _powerSync?.isInitialized ?? false,
      'PowerSync Sync': _powerSync?.isSyncConnected ?? false,
      'Notification System': _notificationSetup?.isInitialized ?? false,
      'AI Service': _aiService != null,
      'Token Manager': _tokenManager != null,
    };
  }

  /// Print service status to console
  void printStatus() {
    logI('📊 Service Status:');
    final status = getServicesStatus();
    status.forEach((service, isActive) {
      final icon = isActive ? '✅' : '❌';
      logI('  $icon $service: ${isActive ? 'Active' : 'Inactive'}');
    });

    // Print notification handlers if available
    if (_notificationSetup != null && _notificationSetup!.isInitialized) {
      logI('\n📋 Notification Handlers:');
      for (final handler in _notificationSetup!.handlers) {
        logI('  • ${handler.handlerId}');
      }
    }
  }

  /// Get detailed service info
  Map<String, dynamic> getDetailedStatus() {
    return {
      'services': getServicesStatus(),
      'notification_handlers': _notificationSetup?.handlers.length ?? 0,
      'fcm_token': _notificationSetup?.fcmToken != null,
      'ai_provider': _aiService?.currentProvider.name,
    };
  }

  // ================================================================
  // CLEANUP & RESET
  // ================================================================

  /// Reset all services (useful for logout or testing)
  Future<void> reset() async {
    try {
      logI('🔄 Resetting AppSetup...');

      // Disconnect PowerSync
      final powerSync = PowerSyncService();
      if (powerSync.isSyncConnected) {
        await powerSync.disconnectSync();
      }

      // Delete FCM token
      if (_notificationSetup != null && _notificationSetup!.isInitialized) {
        await _notificationSetup!.deleteFCMToken();
      }

      // Clear AI caches
      if (_aiService != null) {
        _aiService!.clearCache();
      }

      // Don't dispose singleton services, just mark as not initialized
      _isInitialized = false;

      logI('✅ AppSetup reset completed');
    } catch (e, stackTrace) {
      logE('❌ AppSetup reset failed', error: e, stackTrace: stackTrace);
    }
  }

  /// Dispose all services (only call when app is closing)
  Future<void> dispose() async {
    try {
      logI('🗑️ Disposing AppSetup services...');

      await reset();

      // Dispose notification system
      if (_notificationSetup != null) {
        await _notificationSetup!.dispose();
      }

      // Dispose AI services
      if (_tokenManager != null) {
        _tokenManager!.dispose();
      }

      // Clear service references
      _supabase = null;
      _powerSync = null;
      _notificationSetup = null;
      _aiService = null;
      _tokenManager = null;

      _isInitialized = false;

      logI('✅ AppSetup disposed');
    } catch (e, stackTrace) {
      logE('❌ AppSetup disposal failed', error: e, stackTrace: stackTrace);
    }
  }

  // ================================================================
  // NOTIFICATION HELPERS
  // ================================================================

  /// Subscribe to notification topic
  Future<void> subscribeToNotificationTopic(String topic) async {
    if (_notificationSetup != null && _notificationSetup!.isInitialized) {
      await _notificationSetup!.subscribeToTopic(topic);
      logI('✓ Subscribed to topic: $topic');
    } else {
      logW('⚠️ Cannot subscribe - notification system not initialized');
    }
  }

  /// Unsubscribe from notification topic
  Future<void> unsubscribeFromNotificationTopic(String topic) async {
    if (_notificationSetup != null && _notificationSetup!.isInitialized) {
      await _notificationSetup!.unsubscribeFromTopic(topic);
      logI('✓ Unsubscribed from topic: $topic');
    } else {
      logW('⚠️ Cannot unsubscribe - notification system not initialized');
    }
  }

  /// Get FCM token
  String? get fcmToken {
    if (_notificationSetup != null && _notificationSetup!.isInitialized) {
      return _notificationSetup!.fcmToken;
    }
    return null;
  }

  // ================================================================
  // DEBUGGING
  // ================================================================

  /// Print complete debug info
  void printDebugInfo() {
    logI('\n═══════════════════════════════════════════');
    logI('🔍 AppSetup Debug Information');
    logI('═══════════════════════════════════════════');

    printStatus();

    logI('\n📦 Service Details:');
    final details = getDetailedStatus();
    details.forEach((key, value) {
      logI('  • $key: $value');
    });

    if (fcmToken != null) {
      logI('\n🔔 FCM Token: ${fcmToken!.substring(0, 20)}...');
    }

    logI('═══════════════════════════════════════════\n');
  }
}
