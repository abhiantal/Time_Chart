// lib/core/routes/app_routes.dart

// lib/core/routes/app_routes.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// ─── Chat ───────────────────────────────────────────────────────
import 'package:the_time_chart/features/chats/model/chat_model.dart';
// Removed legacy rules import
import 'package:the_time_chart/features/personal/task_model/long_goal/models/long_goal_model.dart';
import '../../features/analytics/competition/screens/competition_overview_screen.dart';
import '../../features/analytics/competition/screens/competition_detail_screen.dart';
import '../../features/analytics/competition/screens/my_competition_data_screen.dart';
import '../../features/chats/screens/conversation/chat_conversation_screen.dart';
import '../../features/chats/screens/conversation/chat_dispatcher_screen.dart';
import '../../features/chats/screens/home/chat_hub_screen.dart';
// Removed legacy home screen imports
import '../../features/chats/screens/home/archived_chats_screen.dart';
import '../../features/chats/screens/create/add_members_screen.dart';
import '../../features/chats/screens/create/create_group_screen.dart';

import '../../features/chats/screens/create/create_community_screen.dart';
import '../../features/chats/screens/moderation/chat_rules_screen.dart';
import '../../features/chats/screens/moderation/blocked_users_screen.dart';
import '../../features/chats/screens/moderation/report_user_screen.dart';
import '../../features/chats/screens/moderation/reported_content_screen.dart';
import '../../features/chats/screens/profile/new_chat_screen.dart';
import '../../features/chats/screens/discover/discover_communities_screen.dart';
import '../../features/chats/screens/discover/community_preview_screen.dart';

import '../../features/chats/screens/info/chat_members_screen.dart';
import '../../features/chats/screens/create/group_permissions_screen.dart';
import '../../features/chats/screens/info/chat_theme_screen.dart';
import '../../features/chats/screens/info/chat_wallpaper_screen.dart';
import '../../features/chats/screens/info/chat_notification_settings_screen.dart';

import '../../features/chats/screens/create/group_banned_users_screen.dart';
import '../../features/chats/screens/search/in_chat_search_screen.dart';
import '../../features/chats/screens/search/chat_search_filters_screen.dart';
import '../../features/chats/screens/search/global_search_screen.dart';
import '../../features/chats/screens/invites/qr_code_screen.dart';
import '../../features/chats/screens/invites/qr_scanner_screen.dart';
import '../../features/chats/screens/discover/community_categories_screen.dart';
import '../../features/chats/screens/create/group_moderators_screen.dart';
import '../../features/chats/screens/moderation/moderation_queue_screen.dart';

// CHAT SHARED CONTENT SCREENS
import '../../features/chats/screens/media/chat_shared_content_screen.dart';
import '../../features/chats/screens/media/chat_shared_content_list_screen.dart';

// ─── Reward ─────────────────────────────────────────────────────
import 'package:the_time_chart/reward_tags/reward_scratch_card.dart';

// ─── Analytics ──────────────────────────────────────────────────
import '../../features/analytics/dashboard/screens/dashboard_home_screen.dart';
import '../../features/analytics/dashboard/screens/overview_detail_screen.dart';
import '../../features/analytics/dashboard/screens/today_detail_screen.dart';
import '../../features/analytics/dashboard/screens/active_items_detail_screen.dart';
import '../../features/analytics/dashboard/screens/progress_history_detail_screen.dart';
import '../../features/analytics/dashboard/screens/category_stats_detail_screen.dart';
import '../../features/analytics/dashboard/screens/streaks_detail_screen.dart';
import '../../features/analytics/dashboard/screens/mood_detail_screen.dart';
import '../../features/analytics/dashboard/screens/rewards_detail_screen.dart';
import '../../features/analytics/dashboard/screens/weekly_history_detail_screen.dart';
import '../../features/analytics/dashboard/screens/recent_activity_detail_screen.dart';
import '../../features/analytics/leaderboard/screens/stats_screen.dart';
import '../../features/analytics/mentoring/screens/mentoring_hub_screen.dart';
import '../../features/analytics/mentoring/models/mentorship_model.dart';
import '../../features/analytics/mentoring/screens/access_settings_screen.dart';
import '../../features/analytics/mentoring/screens/incoming_requests_screen.dart';
import '../../features/analytics/mentoring/screens/my_mentees_screen.dart';
import '../../features/analytics/mentoring/screens/my_mentors_screen.dart';
import '../../features/analytics/mentoring/screens/outgoing_requests_screen.dart';
import '../../features/analytics/mentoring/screens/view_mentee_screen.dart';
// ─── Personal Tasks ─────────────────────────────────────────────
import '../../features/personal/task_model/week_task/screens/week_task_detail_screen.dart';
import '../../features/personal/task_model/day_tasks/screens/day_schedule_screen.dart';
import '../../features/personal/task_model/week_task/screens/weekly_schedule_screen.dart';
import '../../features/personal/task_model/week_task/screens/add_weekly_task_screen.dart';
import '../../features/personal/task_model/week_task/models/week_task_model.dart';
import '../../features/personal/task_model/week_task/screens/weekly_analysis_screen.dart';
import '../../features/personal/task_model/long_goal/screens/long_goals_home_screen.dart';
import '../../features/personal/task_model/long_goal/screens/create_goal_screen.dart';
import '../../features/personal/task_model/long_goal/screens/long_goal_detail_screen.dart';
import '../../features/personal/task_model/long_goal/providers/long_goals_provider.dart';
import '../../features/personal/task_model/week_task/providers/week_task_provider.dart';

// ─── Bucket ─────────────────────────────────────────────────────
import '../../features/personal/bucket_model/screen/add_edit_bucket_page.dart';
import '../../features/personal/bucket_model/screen/bucket_detail_screen.dart';
import '../../features/personal/bucket_model/models/bucket_model.dart';
import '../../features/personal/bucket_model/providers/bucket_provider.dart';

// ─── Feedback ───────────────────────────────────────────────────
import '../../features/personal/task_model/week_task/screens/add_feedback_screen.dart';
import '../../features/personal/task_model/long_goal/screens/add_feedback_screen.dart';

// ─── Diary ──────────────────────────────────────────────────────
import '../../features/personal/diary_model/screens/diary_list_screen.dart';
import '../../features/personal/diary_model/screens/diary_entry_screen.dart';
import '../../features/personal/diary_model/screens/diary_entry_detail_screen.dart';
import '../../features/personal/diary_model/models/diary_entry_model.dart';

// ─── Profile ────────────────────────────────────────────────────
import '../../user_profile/create_edit_profile/profile_models.dart';
import '../../user_profile/create_edit_profile/profile_onboarding.dart';
import '../../user_profile/create_edit_profile/profile_provider.dart';
import '../../user_profile/view_profile/screens/search_page.dart';
import '../../user_profile/view_profile/screens/user_profile_screen.dart';
import '../../user_profile/view_profile/screens/user_post_feed.dart';
import '../../user_settings/screens/settings_screen.dart';

// ─── Social ─────────────────────────────────────────────────────
import '../../features/social/comments/screens/comments_screen.dart';
import '../../features/social/screens/create_post_screen.dart';
import '../../features/social/views/screens/view_analytics_screen.dart';
import '../../features/social/views/screens/recent_viewers_screen.dart';
import '../../features/social/follow/widgets/followers_screen.dart';
import '../../features/social/follow/widgets/following_screen.dart';
import '../../features/social/post/models/post_model.dart';

// ─── Core / Config ──────────────────────────────────────────────
import '../../core/Mode/Mode_bottom_sheet.dart';
import '../../Authentication/screens/signin_screen.dart';
import '../../Authentication/screens/signup_screen.dart';
import '../../Authentication/screens/forgot_password_screen.dart';
import '../../config/splash_screen.dart';
import '../navigation/personal_nav.dart';
import '../navigation/social_nav.dart';
import '../../media_utility/media_display.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRoutes {
  static const mainNavigation = 'personalNav';

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/splash'),

      // ════════════════════════════════════════
      // SPLASH
      // ════════════════════════════════════════
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) =>
            _fadePage(state, const SplashScreen(), duration: 800),
      ),

      // ════════════════════════════════════════
      // AUTH ROUTES
      // ════════════════════════════════════════
      GoRoute(
        path: '/signIn',
        name: 'signIn',
        pageBuilder: (context, state) => _fadePage(state, const SignInScreen()),
      ),
      GoRoute(
        path: '/signUp',
        name: 'signUp',
        pageBuilder: (context, state) => _fadePage(state, const SignUpScreen()),
      ),
      GoRoute(
        path: '/forgotPassword',
        name: 'forgotPassword',
        pageBuilder: (context, state) =>
            _fadePage(state, const ForgotPasswordScreen()),
      ),

      // ════════════════════════════════════════
      // PROFILE ONBOARDING
      // ════════════════════════════════════════
      GoRoute(
        path: '/profile/create',
        name: 'profileCreate',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final initialStep = extra?['initialStep'] as int? ?? 0;
          return ProfileOnboardingScreen.create(
            initialStep: initialStep,
            onComplete: () => context.goNamed('personalNav'),
          );
        },
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'profileEdit',
        builder: (context, state) {
          final profile = state.extra as UserProfile?;
          final profileProvider = context.read<ProfileProvider>();
          return ProfileOnboardingScreen.edit(
            profile: profile ?? profileProvider.currentProfile!,
            onComplete: () => context.pop(),
          );
        },
      ),

      // ════════════════════════════════════════
      // PERSONAL NAVIGATION (Main Entry)
      // ════════════════════════════════════════
      GoRoute(
        path: '/personalNav',
        name: 'personalNav',
        pageBuilder: (context, state) => _slidePage(state, const PersonalNav()),
        routes: [
          // ────────────────────────────────────
          // ANALYTICS / DASHBOARD
          // ────────────────────────────────────
          GoRoute(
            path: 'CompetitionOverviewScreen',
            name: 'competitionOverviewScreen',
            builder: (context, state) => const CompetitionOverviewScreen(),
          ),
          GoRoute(
            path: 'CompetitionDetailScreen/:competitorId',
            name: 'competitionDetailScreen',
            builder: (context, state) {
              final competitorId = state.pathParameters['competitorId']!;
              final extra = state.extra as Map<String, dynamic>?;
              final competitorName = extra?['competitorName'] as String?;
              return CompetitionDetailScreen(
                competitorId: competitorId,
                competitorName: competitorName,
              );
            },
          ),
          GoRoute(
            path: 'MyCompetitionDataScreen',
            name: 'myCompetitionDataScreen',
            builder: (context, state) => const MyCompetitionDataScreen(),
          ),
          GoRoute(
            path: 'userPostFeed',
            name: 'userPostFeed',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final userId = extra?['userId'] as String? ?? '';
              final initialIndex = extra?['initialIndex'] as int? ?? 0;
              final initialPostId = extra?['initialPostId'] as String?;
              final preloadedPosts = extra?['preloadedPosts'] as List<dynamic>?;
              final title = extra?['title'] as String?;
              final tabType = extra?['tabType'] as String?;
  
              return UserPostFeedScreen(
                userId: userId,
                initialIndex: initialIndex,
                initialPostId: initialPostId,
                preloadedPosts: preloadedPosts?.cast<PostModel>(),
                title: title,
                tabType: tabType,
              );
            },
          ),
          GoRoute(
            path: 'DashboardScreen',
            name: 'dashboardScreen',
            builder: (context, state) => const DashboardHomeScreen(),
          ),
          GoRoute(
            path: 'overviewDetail',
            name: 'overviewDetail',
            builder: (context, state) => const OverviewDetailScreen(),
          ),
          GoRoute(
            path: 'todayDetail',
            name: 'todayDetail',
            builder: (context, state) => const TodayDetailScreen(),
          ),
          GoRoute(
            path: 'activeItemsDetail',
            name: 'activeItemsDetail',
            builder: (context, state) => const ActiveItemsDetailScreen(),
          ),
          GoRoute(
            path: 'progressDetail',
            name: 'progressDetail',
            builder: (context, state) => const ProgressHistoryDetailScreen(),
          ),
          GoRoute(
            path: 'categoryStatsDetail',
            name: 'categoryStatsDetail',
            builder: (context, state) => const CategoryStatsDetailScreen(),
          ),
          GoRoute(
            path: 'streaksDetail',
            name: 'streaksDetail',
            builder: (context, state) => const StreaksDetailScreen(),
          ),
          GoRoute(
            path: 'moodDetail',
            name: 'moodDetail',
            builder: (context, state) => const MoodDetailScreen(),
          ),
          GoRoute(
            path: 'rewardsDetail',
            name: 'rewardsDetail',
            builder: (context, state) => const RewardsDetailScreen(),
          ),
          GoRoute(
            path: 'weeklyHistoryDetail',
            name: 'weeklyHistoryDetail',
            builder: (context, state) => const WeeklyHistoryDetailScreen(),
          ),
          GoRoute(
            path: 'recentActivityDetail',
            name: 'recentActivityDetail',
            builder: (context, state) => const RecentActivityDetailScreen(),
          ),
          GoRoute(
            path: 'MentoringHubScreen',
            name: 'mentoringHubScreen',
            builder: (context, state) => const MentoringHubScreen(),
          ),
          GoRoute(
            path: 'MenteeAccessSettingsScreen',
            name: 'menteeAccessSettingsScreen',
            builder: (context, state) {
              final connection = state.extra as MentorshipConnection;
              return AccessSettingsScreen(connection: connection);
            },
          ),
          GoRoute(
            path: 'IncomingMentorshipRequestsScreen',
            name: 'incomingMentorshipRequestsScreen',
            builder: (context, state) => const IncomingRequestsScreen(),
          ),
          GoRoute(
            path: 'MyMenteesScreen',
            name: 'myMenteesScreen',
            builder: (context, state) => const MyMenteesScreen(),
          ),
          GoRoute(
            path: 'MyMentorsScreen',
            name: 'myMentorsScreen',
            builder: (context, state) => const MyMentorsScreen(),
          ),
          GoRoute(
            path: 'OutgoingMentorshipRequestsScreen',
            name: 'outgoingMentorshipRequestsScreen',
            builder: (context, state) => const OutgoingRequestsScreen(),
          ),
          GoRoute(
            path: 'ViewMenteeScreen/:connectionId',
            name: 'viewMenteeScreen',
            builder: (context, state) {
              final connection = state.extra as MentorshipConnection;
              return ViewMenteeScreen(connection: connection);
            },
          ),
          GoRoute(
            path: 'StatsScreen',
            name: 'statsScreen',
            builder: (context, state) => const LeaderboardScreen(),
          ),

          // ────────────────────────────────────
          // DAY & WEEK TASKS
          // ────────────────────────────────────
          GoRoute(
            path: 'DayScheduleScreen',
            name: 'dayScheduleScreen',
            builder: (context, state) => const DayScheduleScreen(),
          ),
          GoRoute(
            path: 'WeeklyScheduleScreen',
            name: 'weeklyScheduleScreen',
            builder: (context, state) => const WeeklyScheduleScreen(),
          ),
          GoRoute(
            path: 'addWeeklyTask',
            name: 'addWeeklyTask',
            builder: (context, state) {
              final extra = state.extra;
              WeekTaskModel? existingTask;
              if (extra is Map<String, dynamic>) {
                existingTask = extra['existingTask'] as WeekTaskModel?;
              } else if (extra is WeekTaskModel) {
                existingTask = extra;
              }
              return AddWeeklyTaskScreen(existingTask: existingTask);
            },
          ),
          GoRoute(
            path: 'week-task/:taskId',
            name: 'weekTaskDetailScreen',
            builder: (context, state) {
              final taskId = state.pathParameters['taskId']!;
              final taskExtra = state.extra as WeekTaskModel?;

              return Consumer<WeekTaskProvider>(
                builder: (context, provider, child) {
                  final task =
                      provider.tasks.cast<WeekTaskModel?>().firstWhere(
                        (t) => t?.id == taskId,
                        orElse: () => null,
                      ) ??
                      taskExtra;

                  if (task != null) {
                    return WeekTaskDetailScreen(task: task);
                  }

                  return const Scaffold(
                    body: Center(child: Text('Task data unavailable')),
                  );
                },
              );
            },
          ),
          GoRoute(
            path: 'WeeklyTaskDailyAnalysisScreen/:taskId',
            name: 'weeklyTaskDailyAnalysisScreen',
            builder: (context, state) {
              final taskId = state.pathParameters['taskId']!;
              final params = state.extra as Map<String, dynamic>?;
              final selectedDate =
                  params?['selectedDate'] as DateTime? ?? DateTime.now();
              return WeeklyTaskDailyAnalysisScreen(
                taskId: taskId,
                selectedDate: selectedDate,
              );
            },
          ),

          // ────────────────────────────────────
          // LONG GOALS
          // ────────────────────────────────────
          GoRoute(
            path: 'LongGoalsHomeScreen',
            name: 'longGoalsHomeScreen',
            builder: (context, state) => const LongGoalsHomeScreen(),
          ),
          GoRoute(
            path: 'CreateLongGoalScreen',
            name: 'createLongGoalScreen',
            builder: (context, state) => const CreateLongGoalScreen(),
          ),
          GoRoute(
            path: 'LongGoalDetailScreen/:goalId',
            name: 'longGoalDetailScreen',
            builder: (context, state) {
              final goalId = state.pathParameters['goalId']!;
              final goalExtra = state.extra as LongGoalModel?;

              return Consumer<LongGoalsProvider>(
                builder: (context, provider, child) {
                  final goal =
                      provider.goals.cast<LongGoalModel?>().firstWhere(
                        (g) => g?.id == goalId || g?.goalId == goalId,
                        orElse: () => null,
                      ) ??
                      goalExtra;

                  if (goal != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      provider.getLongGoal(goalId);
                    });
                    return LongGoalDetailScreen(goal: goal);
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    provider.getLongGoal(goalId);
                  });
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                },
              );
            },
          ),

          // ────────────────────────────────────
          // BUCKETS
          // ────────────────────────────────────
          GoRoute(
            path: 'AddEditBucketPage',
            name: 'addEditBucketPage',
            builder: (context, state) => const AddEditBucketPage(),
          ),
          GoRoute(
            path: 'AddEditBucketPage/:bucketId',
            name: 'editBucketPage',
            builder: (context, state) {
              final bucketId = state.pathParameters['bucketId']!;
              return AddEditBucketPage(bucketId: bucketId);
            },
          ),
          GoRoute(
            path: 'BucketDetailScreen/:bucketId',
            name: 'bucketDetailScreen',
            builder: (context, state) {
              final bucketId = state.pathParameters['bucketId']!;
              final extraBucket = state.extra as BucketModel?;
              return Consumer<BucketProvider>(
                builder: (context, provider, child) {
                  final bucket = provider.buckets
                      .cast<BucketModel?>()
                      .firstWhere((b) => b?.id == bucketId, orElse: () => null);

                  if (bucket != null) {
                    return BucketDetailScreen(bucket: bucket);
                  }

                  if (extraBucket != null) {
                    // Start fetching the up-to-date version while showing this
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      provider.getBucket(bucketId);
                    });
                    return BucketDetailScreen(bucket: extraBucket);
                  }

                  // Fallback: trigger fetch and show loading
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    provider.getBucket(bucketId);
                  });
                  return BucketDetailScreen(
                    bucket: _createPlaceholderBucket(bucketId),
                  );
                },
              );
            },
          ),

          // ────────────────────────────────────
          // CHAT — HOME SCREENS
          // ────────────────────────────────────
          GoRoute(
            path: 'ChatHubScreen',
            name: 'chatHubScreen',
            builder: (context, state) => const ChatHubScreen(),
          ),
          GoRoute(
            path: 'GroupHomeScreen',
            name: 'groupHomeScreen',
            builder: (context, state) =>
                const ChatHubScreen(initialTab: ChatHubTab.groups),
          ),
          GoRoute(
            path: 'CommunityHomeScreen',
            name: 'communityHomeScreen',
            builder: (context, state) =>
                const ChatHubScreen(initialTab: ChatHubTab.communities),
          ),
          GoRoute(
            path: 'ArchivedChatsScreen',
            name: 'archivedChatsScreen',
            builder: (context, state) => const ArchivedChatsScreen(),
          ),

          // ────────────────────────────────────
          // CHAT — CONVERSATIONS
          // ────────────────────────────────────
          GoRoute(
            path: 'NewChatScreen',
            name: 'newChatScreen',
            builder: (context, state) => const NewChatScreen(),
          ),
          GoRoute(
            path: 'ChatConversationScreen/:chatId',
            name: 'chatConversationScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              return ChatConversationScreen(
                chatId: chatId,
                onTapSharedDayTasks: () => context.pushNamed(
                  'chatSharedDayTasksScreen',
                  pathParameters: {'chatId': chatId},
                ),
              );
            },
          ),
          GoRoute(
            path: 'PersonalChatScreen/:chatId',
            name: 'personalChatScreen',
            redirect: (context, state) =>
                '/personalNav/ChatConversationScreen/${state.pathParameters['chatId']}',
          ),
          GoRoute(
            path: 'CommunityChatScreen/:chatId',
            name: 'communityChatScreen',
            redirect: (context, state) =>
                '/personalNav/ChatConversationScreen/${state.pathParameters['chatId']}',
          ),
          GoRoute(
            path: 'GroupChatScreen/:chatId',
            name: 'groupChatScreen',
            redirect: (context, state) =>
                '/personalNav/ChatConversationScreen/${state.pathParameters['chatId']}',
          ),

          GoRoute(
            path: 'ChatRoomScreen/:chatId',
            name: 'chatRoomScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              return ChatDispatcherScreen(chatId: chatId);
            },
          ),

          // ────────────────────────────────────
          // CHAT — MEMBERS & USERS
          // ────────────────────────────────────
          GoRoute(
            path: 'AddMembersScreen/:chatId',
            name: 'addMembersScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              final extra = state.extra as Map<String, dynamic>?;
              return AddMembersScreen(
                chatId: chatId,
                excludeUserIds: extra?['excludeUserIds'] as List<String>?,
                isInviteMode: extra?['isInviteMode'] as bool? ?? false,
              );
            },
          ),
          GoRoute(
            path: 'ChatNotificationSettingsScreen/:chatId',
            name: 'notificationSettingsScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              return ChatNotificationSettingsScreen(chatId: chatId);
            },
          ),
          GoRoute(
            path: 'GroupBannedUsersScreen/:chatId',
            name: 'groupBannedUsersScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              return GroupBannedUsersScreen(groupId: chatId);
            },
          ),
          GoRoute(
            path: 'GroupModeratorsScreen/:chatId',
            name: 'groupModeratorsScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              return GroupModeratorsScreen(groupId: chatId);
            },
          ),
          GoRoute(
            path: 'CommunityCategoriesScreen',
            name: 'communityCategoriesScreen',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return CommunityCategoriesScreen(
                initialCategoryId: extra?['initialCategoryId'],
                initialCategoryName: extra?['initialCategoryName'],
              );
            },
          ),
          GoRoute(
            path: 'InChatSearchScreen/:chatId',
            name: 'inChatSearchScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              final chatName = state.uri.queryParameters['chatName'];
              return InChatSearchScreen(chatId: chatId, chatName: chatName);
            },
          ),
          GoRoute(
            path: 'ChatSearchFiltersScreen',
            name: 'chatSearchFiltersScreen',
            builder: (context, state) => const ChatSearchFiltersScreen(),
          ),
          GoRoute(
            path: 'SearchUsersScreen',
            name: 'searchUsersScreen',
            builder: (context, state) => const GlobalSearchScreen(),
          ),
          GoRoute(
            path: 'ReportedContentScreen',
            name: 'reportedContentScreen',
            builder: (context, state) => const ReportedContentScreen(),
          ),
          GoRoute(
            path: 'BlockedUsersScreen',
            name: 'blockedUsersScreen',
            builder: (context, state) => const BlockedUsersScreen(),
          ),
          GoRoute(
            path: 'ModerationQueueScreen',
            name: 'moderationQueueScreen',
            builder: (context, state) => const ModerationQueueScreen(),
          ),

          // ────────────────────────────────────
          // CHAT — INVITES
          // ────────────────────────────────────
          // Removed redundant invitesScreen
          GoRoute(
            path: 'QrCodeScreen/:chatId',
            name: 'qrCodeScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              return QrCodeScreen(chatId: chatId);
            },
          ),
          GoRoute(
            path: 'QrScannerScreen',
            name: 'qrScannerScreen',
            builder: (context, state) => const QrScannerScreen(),
          ),

          // ────────────────────────────────────
          // CHAT — CONTENT (Pinned, Shared, etc.)
          // ────────────────────────────────────

          // ────────────────────────────────────
          // CHAT — MEDIA & SHARED CONTENT
          // ────────────────────────────────────
          // Shared Content sub-routes consolidated here
          GoRoute(
            path: 'ChatSharedContentScreen/:chatId',
            name: 'chatSharedContentScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              final extra = state.extra as Map<String, dynamic>?;
              return ChatSharedContentScreen(
                chatId: chatId,
                chatName: extra?['chatName'],
              );
            },
          ),
          GoRoute(
            path: 'ChatMediaScreen/:chatId',
            name: 'chatMediaScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              final extra = state.extra as Map<String, dynamic>?;
              return ChatSharedContentListScreen(
                chatId: chatId,
                type: UnifiedSharedContentType.media,
                chatName: extra?['chatName'],
              );
            },
          ),
          GoRoute(
            path: 'ChatLinksScreen/:chatId',
            name: 'chatLinksScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              final extra = state.extra as Map<String, dynamic>?;
              return ChatSharedContentListScreen(
                chatId: chatId,
                type: UnifiedSharedContentType.links,
                chatName: extra?['chatName'],
              );
            },
          ),
          GoRoute(
            path: 'ChatDocumentsScreen/:chatId',
            name: 'chatDocumentsScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              final extra = state.extra as Map<String, dynamic>?;
              return ChatSharedContentListScreen(
                chatId: chatId,
                type: UnifiedSharedContentType.documents,
                chatName: extra?['chatName'],
              );
            },
          ),
          GoRoute(
            path: 'ChatSharedBucketsScreen/:chatId',
            name: 'chatSharedBucketsScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              final extra = state.extra as Map<String, dynamic>?;
              return ChatSharedContentListScreen(
                chatId: chatId,
                type: UnifiedSharedContentType.buckets,
                chatName: extra?['chatName'],
              );
            },
          ),
          GoRoute(
            path: 'ChatSharedDiariesScreen/:chatId',
            name: 'chatSharedDiariesScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              final extra = state.extra as Map<String, dynamic>?;
              return ChatSharedContentListScreen(
                chatId: chatId,
                type: UnifiedSharedContentType.diaries,
                chatName: extra?['chatName'],
              );
            },
          ),
          GoRoute(
            path: 'ChatSharedPostsScreen/:chatId',
            name: 'chatSharedPostsScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              final extra = state.extra as Map<String, dynamic>?;
              return ChatSharedContentListScreen(
                chatId: chatId,
                type: UnifiedSharedContentType.posts,
                chatName: extra?['chatName'],
              );
            },
          ),
          GoRoute(
            path: 'ChatSharedDayTasksScreen/:chatId',
            name: 'chatSharedDayTasksScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              final extra = state.extra as Map<String, dynamic>?;
              return ChatSharedContentListScreen(
                chatId: chatId,
                type: UnifiedSharedContentType.dayTasks,
                chatName: extra?['chatName'],
              );
            },
          ),
          GoRoute(
            path: 'ChatSharedWeekTasksScreen/:chatId',
            name: 'chatSharedWeekTasksScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              final extra = state.extra as Map<String, dynamic>?;
              return ChatSharedContentListScreen(
                chatId: chatId,
                type: UnifiedSharedContentType.weekTasks,
                chatName: extra?['chatName'],
              );
            },
          ),
          GoRoute(
            path: 'ChatSharedGoalsScreen/:chatId',
            name: 'chatSharedGoalsScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              final extra = state.extra as Map<String, dynamic>?;
              return ChatSharedContentListScreen(
                chatId: chatId,
                type: UnifiedSharedContentType.goals,
                chatName: extra?['chatName'],
              );
            },
          ),
          // This entire section was redundant and is now consolidated above or removed

          // ────────────────────────────────────
          // CHAT — DATA MANAGEMENT
          // ────────────────────────────────────

          // ────────────────────────────────────
          // CHAT — MODERATION
          // ────────────────────────────────────
          GoRoute(
            path: 'CommunityRulesPage/:communityId',
            name: 'communityRulesPage',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return ChatRulesScreen(
                chatId: state.pathParameters['communityId']!,
                chatName: extra?['communityName'] ?? 'Community',
                isCommunity: true,
              );
            },
          ),
          GoRoute(
            path: 'GroupRulesScreen/:groupId',
            name: 'groupRulesScreen',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return ChatRulesScreen(
                chatId: state.pathParameters['groupId']!,
                chatName: extra?['groupName'] ?? 'Group',
                isCommunity: false,
              );
            },
          ),
          GoRoute(
            path: 'ReportContentScreen',
            name: 'reportContentScreen',
            builder: (context, state) {
              return ReportedContentScreen(
                // type: extra?['type'] as ReportType? ?? ReportType.message, // Assuming type is not used or different
                // Fixed args based on what works likely
              );
            },
          ),

          // ────────────────────────────────────
          // CHAT — MODERATION
          // ────────────────────────────────────
          GoRoute(
            path: 'ReportUserScreen',
            name: 'reportUserScreen',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return ReportUserScreen(
                userId: extra?['targetId'] as String? ?? '',
                userName: extra?['targetName'] as String?,
              );
            },
          ),

          // ────────────────────────────────────
          // CHAT — CREATE GROUP / COMMUNITY
          // ────────────────────────────────────
          GoRoute(
            path: 'CreateGroupScreen',
            name: 'createGroupScreen',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return CreateGroupScreen(
                existingGroup: extra?['existingGroup'] as ChatModel?,
              );
            },
          ),
          GoRoute(
            path: 'CreateCommunityScreen',
            name: 'createCommunityScreen',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return CreateCommunityScreen(
                existingCommunity: extra?['existingCommunity'] as ChatModel?,
              );
            },
          ),

          GoRoute(
            path: 'ChatMembersScreen/:chatId',
            name: 'chatMembersScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              return ChatMembersScreen(chatId: chatId);
            },
          ),
          GoRoute(
            path: 'GroupPermissionsScreen',
            name: 'groupPermissionsScreen',
            builder: (context, state) => const GroupPermissionsScreen(),
          ),
          GoRoute(
            path: 'ChatThemeScreen/:chatId',
            name: 'chatThemeScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              return ChatThemeScreen(chatId: chatId);
            },
          ),
          GoRoute(
            path: 'ChatWallpaperScreen/:chatId',
            name: 'chatWallpaperScreen',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              return ChatWallpaperScreen(chatId: chatId);
            },
          ),

          // ────────────────────────────────────
          // CHAT — DISCOVER COMMUNITIES
          // ────────────────────────────────────
          GoRoute(
            path: 'DiscoverCommunitiesScreen',
            name: 'discoverCommunitiesScreen',
            builder: (context, state) => const DiscoverCommunitiesScreen(),
          ),
          GoRoute(
            path: 'CommunityPreviewScreen/:communityId',
            name: 'communityPreviewScreen',
            builder: (context, state) {
              final communityId = state.pathParameters['communityId']!;
              final community = state.extra as ChatModel?;
              return CommunityPreviewScreen(
                communityId: communityId,
                community: community,
              );
            },
          ),

          // ────────────────────────────────────
          // FEEDBACK
          // ────────────────────────────────────
          GoRoute(
            path: 'AddWeeklyFeedbackScreen',
            name: 'addWeeklyFeedbackScreen',
            builder: (context, state) {
              final params = state.extra as Map<String, dynamic>?;
              if (params == null) return _invalidParams();
              return AddWeeklyFeedbackScreen(
                task: params['task'],
                selectedDate: params['selectedDate'],
              );
            },
          ),
          GoRoute(
            path: 'AddDailyFeedbackScreen/:goalId',
            name: 'addDailyFeedbackScreen',
            builder: (context, state) {
              final goalId = state.pathParameters['goalId'];
              final params = state.extra as Map<String, dynamic>?;
              if (params == null || goalId == null) return _invalidParams();
              return AddLongGoalFeedbackScreen(
                goalId: goalId,
                weekId: params['weekId'],
                goalTitle: params['goalTitle'],
                weeklyGoal: params['weeklyGoal'],
                feedbackDate: params['selectedDate'] ?? DateTime.now(),
              );
            },
          ),

          // ────────────────────────────────────
          // DIARY
          // ────────────────────────────────────
          GoRoute(
            path: 'DiaryListScreen',
            name: 'diaryListScreen',
            builder: (context, state) => const DiaryListScreen(),
          ),
          GoRoute(
            path: 'DiaryEntryScreen',
            name: 'diaryEntryScreen',
            builder: (context, state) {
              final extra = state.extra;
              DateTime? selectedDate;

              if (extra is Map<String, dynamic>) {
                selectedDate = extra['selectedDate'];
              } else if (extra is DateTime) {
                selectedDate = extra;
              }

              return DiaryEntryScreen(selectedDate: selectedDate);
            },
          ),
          GoRoute(
            path: 'DiaryEntryDetailScreen/:entryId',
            name: 'diaryEntryDetailScreen',
            builder: (context, state) {
              final entryId = state.pathParameters['entryId']!;
              final entry = state.extra as DiaryEntryModel?;
              return DiaryEntryDetailScreen(entryId: entryId, entry: entry);
            },
          ),
        ],
      ),

      // ════════════════════════════════════════
      // SOCIAL NAVIGATION
      // ════════════════════════════════════════
      GoRoute(
        path: '/socialNav',
        name: 'socialNav',
        pageBuilder: (context, state) => _slidePage(state, const SocialNav()),
        routes: [
          GoRoute(
            path: 'comments',
            name: 'comments',
            builder: (context, state) {
              final params = state.extra as Map<String, dynamic>?;
              if (params == null) return _invalidParams();
              return CommentsScreen(
                targetType: params['targetType'],
                targetId: params['targetId'],
                currentUserId: params['currentUserId'],
              );
            },
          ),
          GoRoute(
            path: 'createPost',
            name: 'createPost',
            builder: (context, state) {
              final params = state.extra as Map<String, dynamic>?;
              if (params == null) return _invalidParams();
              return CreatePostScreen(
                currentUserId: params['currentUserId'],
                onPostSuccess: () {},
              );
            },
          ),
          GoRoute(
            path: 'viewAnalytics',
            name: 'viewAnalytics',
            builder: (context, state) {
              final params = state.extra as Map<String, dynamic>?;
              if (params == null) return _invalidParams();
              return ViewAnalyticsScreen(
                postId: params['targetId'] ?? '',
                postOwnerId: params['targetOwnerId'] ?? '',
                currentUserId: params['currentUserId'] ?? '',
              );
            },
          ),
          GoRoute(
            path: 'recentViewers',
            name: 'recentViewers',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              if (extra == null) return _invalidParams();
              return RecentViewersScreen(
                postId: extra['postId'] ?? '',
                postOwnerId: extra['postOwnerId'] ?? '',
                currentUserId: extra['currentUserId'] ?? '',
              );
            },
          ),
        ],
      ),

      // ════════════════════════════════════════
      // USER PROFILE (Top-level)
      // ════════════════════════════════════════
      GoRoute(
        path: '/otherUserProfileScreen/:userId',
        name: 'otherUserProfileScreen',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return _slidePage(state, UserProfileScreen(userId: userId));
        },
      ),
      GoRoute(
        path: '/settingsScreen',
        name: 'settingsScreen',
        pageBuilder: (context, state) =>
            _slidePage(state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/profileSearchPage',
        name: 'profileSearchPage',
        pageBuilder: (context, state) => _slidePage(state, const SearchPage()),
      ),

      // ════════════════════════════════════════
      // SOCIAL RELATIONS (Top-level)
      // ════════════════════════════════════════
      GoRoute(
        path: '/followers/:userId',
        name: 'followersScreen',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return _slidePage(
            state,
            FollowersScreen(
              userId: userId,
              currentUserId: extra['currentUserId'] ?? '',
            ),
          );
        },
      ),
      GoRoute(
        path: '/following/:userId',
        name: 'followingScreen',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return _slidePage(
            state,
            FollowingScreen(
              userId: userId,
              currentUserId: extra['currentUserId'] ?? '',
            ),
          );
        },
      ),

      // ════════════════════════════════════════
      // OVERLAY ROUTES (Outside Shell)
      // ════════════════════════════════════════
      GoRoute(
        path: '/themeMode',
        name: 'themeMode',
        pageBuilder: (context, state) =>
            _fadePage(state, const ModeBottomSheet()),
      ),
      GoRoute(
        path: '/scratchCard',
        name: 'scratchCard',
        pageBuilder: (context, state) {
          final params = state.extra as Map<String, dynamic>?;
          if (params == null) {
            return const MaterialPage(
              child: Scaffold(body: Center(child: Text('Invalid parameters'))),
            );
          }
          return CustomTransitionPage(
            key: state.pageKey,
            opaque: false,
            barrierColor: Colors.black87,
            barrierDismissible: true,
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            child: PremiumScratchCardPopup(
              taskId: params['taskId'],
              taskType: params['taskType'],
              taskTitle: params['taskTitle'],
              rewardPackage: params['rewardPackage'],
              wasAlreadyScratched: params['wasAlreadyScratched'] ?? false,
              onRewardClaimed: params['onRewardClaimed'],
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
          );
        },
      ),
      GoRoute(
        path: '/fullScreenMedia',
        name: 'fullScreenMedia',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>?;
          if (params == null) {
            return const Scaffold(
              body: Center(child: Text('Error: No params')),
            );
          }
          return FullScreenViewer(
            mediaFiles: params['mediaFiles'],
            initialIndex: params['initialIndex'] ?? 0,
            config: params['config'] ?? const MediaDisplayConfig(),
          );
        },
      ),
    ],
  );

  // ════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════

  static Widget _invalidParams() =>
      const Scaffold(body: Center(child: Text('Invalid parameters')));

  static CustomTransitionPage _fadePage(
    GoRouterState state,
    Widget page, {
    int duration = 600,
  }) => CustomTransitionPage(
    key: state.pageKey,
    child: page,
    transitionDuration: Duration(milliseconds: duration),
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );

  static CustomTransitionPage _slidePage(GoRouterState state, Widget page) =>
      CustomTransitionPage(
        key: state.pageKey,
        child: page,
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      );

  static BucketModel _createPlaceholderBucket(String bucketId) {
    return BucketModel(
      id: bucketId,
      userId: 'temp',
      title: 'Loading...',
      details: BucketDetails(
        description: 'Loading...',
        motivation: '',
        outCome: '',
        mediaUrl: [],
      ),
      checklist: [],
      timeline: BucketTimeline(
        isUnspecified: true,
        addedDate: DateTime.now(),
        startDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 30)),
      ),
      metadata: BucketMetadata(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ERROR SCREEN
// ══════════════════════════════════════════════════════════════
// ignore: unused_element
class _ErrorScreen extends StatelessWidget {
  final Exception? error;

  // ignore: unused_element_parameter
  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Route not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.goNamed(AppRoutes.mainNavigation),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
