import 'dart:convert';

// ============================================================
// 🎨 ENUMS
// ============================================================

enum ThemeMode { light, dark, system }

enum FontSize { small, medium, large, extraLarge }

enum ColorScheme { defaultScheme, ocean, forest, sunset, lavender, custom }

enum ProfileVisibility { public, private, friendsOnly }

enum AllowFrom { everyone, friends, nobody }

enum TaskView { list, grid, kanban, calendar }

enum Priority { low, medium, high, urgent }

enum WeekDay { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

enum GoalView { list, grid, timeline }

enum ProgressCalculation { automatic, manual }

enum BucketView { list, grid, map }

enum MediaAutoDownload { always, wifi, never }

enum SwipeAction { reply, archive, delete, pin, mute }

enum BubbleStyle { defaultStyle, minimal, classic, modern }

enum FeedShowFrom { all, following, friends }

enum FeedSortBy { recent, popular, relevant }

enum SuggestionFrequency { minimal, moderate, frequent }

enum ResponseStyle { concise, balanced, detailed }

enum ExportFormat { json, csv, pdf }

enum CloudProvider { googleDrive, icloud, dropbox, oneDrive }

enum CalendarProvider { google, apple, outlook, other }

enum HealthProvider { googleFit, appleHealth, fitbit, other }

enum TimeFormat { h12, h24 }

enum MeasurementUnit { metric, imperial }

enum WidgetSize { small, medium, large }

enum QuickAction { addTask, addDiary, startTimer, voiceNote, addGoal, scan }

enum DashboardLayout { defaultLayout, compact, detailed }

// ============================================================
// ⚙️ USER SETTINGS (Main Model)
// ============================================================

class UserSettings {
  final String id;
  final String userId;
  final AppearanceSettings appearance;
  final NotificationSettings notifications;
  final PrivacySettings privacy;
  final TaskSettings tasks;
  final GoalSettings goals;
  final BucketListSettings bucketList;
  final DiarySettings diary;
  final ChatSettings chat;
  final SocialSettings social;
  final AiSettings ai;
  final CompetitionSettings competition;
  final SecuritySettings security;
  final DataStorageSettings dataStorage;
  final LocalizationSettings localization;
  final AccessibilitySettings accessibility;
  final ExperimentalSettings experimental;
  final WidgetSettings widgets;
  final AnalyticsSettings analytics;
  final MentoringSettings mentoring;
  final IntegrationSettings integrations;
  final int settingsVersion;
  final DateTime? lastSyncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettings({
    required this.id,
    required this.userId,
    AppearanceSettings? appearance,
    NotificationSettings? notifications,
    PrivacySettings? privacy,
    TaskSettings? tasks,
    GoalSettings? goals,
    BucketListSettings? bucketList,
    DiarySettings? diary,
    ChatSettings? chat,
    SocialSettings? social,
    AiSettings? ai,
    CompetitionSettings? competition,
    SecuritySettings? security,
    DataStorageSettings? dataStorage,
    LocalizationSettings? localization,
    AccessibilitySettings? accessibility,
    ExperimentalSettings? experimental,
    WidgetSettings? widgets,
    AnalyticsSettings? analytics,
    MentoringSettings? mentoring,
    IntegrationSettings? integrations,
    this.settingsVersion = 1,
    this.lastSyncedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : appearance = appearance ?? AppearanceSettings(),
        notifications = notifications ?? NotificationSettings(),
        privacy = privacy ?? PrivacySettings(),
        tasks = tasks ?? TaskSettings(),
        goals = goals ?? GoalSettings(),
        bucketList = bucketList ?? BucketListSettings(),
        diary = diary ?? DiarySettings(),
        chat = chat ?? ChatSettings(),
        social = social ?? SocialSettings(),
        ai = ai ?? AiSettings(),
        competition = competition ?? CompetitionSettings(),
        security = security ?? SecuritySettings(),
        dataStorage = dataStorage ?? DataStorageSettings(),
        localization = localization ?? LocalizationSettings(),
        accessibility = accessibility ?? AccessibilitySettings(),
        experimental = experimental ?? ExperimentalSettings(),
        widgets = widgets ?? WidgetSettings(),
        analytics = analytics ?? AnalyticsSettings(),
        mentoring = mentoring ?? MentoringSettings(),
        integrations = integrations ?? IntegrationSettings(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create default settings for new user
  factory UserSettings.defaultSettings(String userId) =>
      UserSettings(id: '', userId: userId);

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      appearance: AppearanceSettings.fromJson(
        _parseJsonField(json['appearance']),
      ),
      notifications: NotificationSettings.fromJson(
        _parseJsonField(json['notifications']),
      ),
      privacy: PrivacySettings.fromJson(_parseJsonField(json['privacy'])),
      tasks: TaskSettings.fromJson(_parseJsonField(json['tasks'])),
      goals: GoalSettings.fromJson(_parseJsonField(json['goals'])),
      bucketList: BucketListSettings.fromJson(
        _parseJsonField(json['bucket_list']),
      ),
      diary: DiarySettings.fromJson(_parseJsonField(json['diary'])),
      chat: ChatSettings.fromJson(_parseJsonField(json['chat'])),
      social: SocialSettings.fromJson(_parseJsonField(json['social'])),
      ai: AiSettings.fromJson(_parseJsonField(json['ai'])),
      competition: CompetitionSettings.fromJson(
        _parseJsonField(json['competition']),
      ),
      security: SecuritySettings.fromJson(_parseJsonField(json['security'])),
      dataStorage: DataStorageSettings.fromJson(
        _parseJsonField(json['data_storage']),
      ),
      localization: LocalizationSettings.fromJson(
        _parseJsonField(json['localization']),
      ),
      accessibility: AccessibilitySettings.fromJson(
        _parseJsonField(json['accessibility']),
      ),
      experimental: ExperimentalSettings.fromJson(
        _parseJsonField(json['experimental']),
      ),
      widgets: WidgetSettings.fromJson(_parseJsonField(json['widgets'])),
      analytics: AnalyticsSettings.fromJson(_parseJsonField(json['analytics'])),
      mentoring: MentoringSettings.fromJson(_parseJsonField(json['mentoring'])),
      integrations: IntegrationSettings.fromJson(
        _parseJsonField(json['integrations']),
      ),
      settingsVersion: json['settings_version'] as int? ?? 1,
      lastSyncedAt: _parseDate(json['last_synced_at']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'appearance': appearance.toJson(),
      'notifications': notifications.toJson(),
      'privacy': privacy.toJson(),
      'tasks': tasks.toJson(),
      'goals': goals.toJson(),
      'bucket_list': bucketList.toJson(),
      'diary': diary.toJson(),
      'chat': chat.toJson(),
      'social': social.toJson(),
      'ai': ai.toJson(),
      'competition': competition.toJson(),
      'security': security.toJson(),
      'data_storage': dataStorage.toJson(),
      'localization': localization.toJson(),
      'accessibility': accessibility.toJson(),
      'experimental': experimental.toJson(),
      'widgets': widgets.toJson(),
      'analytics': analytics.toJson(),
      'mentoring': mentoring.toJson(),
      'integrations': integrations.toJson(),
      'settings_version': settingsVersion,
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserSettings copyWith({
    String? id,
    String? userId,
    AppearanceSettings? appearance,
    NotificationSettings? notifications,
    PrivacySettings? privacy,
    TaskSettings? tasks,
    GoalSettings? goals,
    BucketListSettings? bucketList,
    DiarySettings? diary,
    ChatSettings? chat,
    SocialSettings? social,
    AiSettings? ai,
    CompetitionSettings? competition,
    SecuritySettings? security,
    DataStorageSettings? dataStorage,
    LocalizationSettings? localization,
    AccessibilitySettings? accessibility,
    ExperimentalSettings? experimental,
    WidgetSettings? widgets,
    AnalyticsSettings? analytics,
    MentoringSettings? mentoring,
    IntegrationSettings? integrations,
    int? settingsVersion,
    DateTime? lastSyncedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      appearance: appearance ?? this.appearance,
      notifications: notifications ?? this.notifications,
      privacy: privacy ?? this.privacy,
      tasks: tasks ?? this.tasks,
      goals: goals ?? this.goals,
      bucketList: bucketList ?? this.bucketList,
      diary: diary ?? this.diary,
      chat: chat ?? this.chat,
      social: social ?? this.social,
      ai: ai ?? this.ai,
      competition: competition ?? this.competition,
      security: security ?? this.security,
      dataStorage: dataStorage ?? this.dataStorage,
      localization: localization ?? this.localization,
      accessibility: accessibility ?? this.accessibility,
      experimental: experimental ?? this.experimental,
      widgets: widgets ?? this.widgets,
      analytics: analytics ?? this.analytics,
      mentoring: mentoring ?? this.mentoring,
      integrations: integrations ?? this.integrations,
      settingsVersion: settingsVersion ?? this.settingsVersion,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================================
// 🎨 APPEARANCE SETTINGS
// ============================================================

class AppearanceSettings {
  final ThemeMode theme;
  final ColorScheme colorScheme;
  final String accentColor;
  final FontSize fontSize;
  final String fontFamily;
  final bool reduceMotion;
  final bool highContrast;
  final bool compactMode;

  AppearanceSettings({
    this.theme = ThemeMode.system,
    this.colorScheme = ColorScheme.defaultScheme,
    this.accentColor = '#6366f1',
    this.fontSize = FontSize.medium,
    this.fontFamily = 'system',
    this.reduceMotion = false,
    this.highContrast = false,
    this.compactMode = false,
  });

  factory AppearanceSettings.fromJson(Map<String, dynamic> json) {
    return AppearanceSettings(
      theme: _parseEnum(json['theme'], ThemeMode.values, ThemeMode.system),
      colorScheme: _parseEnum(
        json['color_scheme'],
        ColorScheme.values,
        ColorScheme.defaultScheme,
      ),
      accentColor: json['accent_color'] as String? ?? '#6366f1',
      fontSize: _parseEnum(json['font_size'], FontSize.values, FontSize.medium),
      fontFamily: json['font_family'] as String? ?? 'system',
      reduceMotion: _parseBool(json['reduce_motion']),
      highContrast: _parseBool(json['high_contrast']),
      compactMode: _parseBool(json['compact_mode']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme.name,
      'color_scheme': colorScheme.name,
      'accent_color': accentColor,
      'font_size': fontSize.name,
      'font_family': fontFamily,
      'reduce_motion': reduceMotion,
      'high_contrast': highContrast,
      'compact_mode': compactMode,
    };
  }

  AppearanceSettings copyWith({
    ThemeMode? theme,
    ColorScheme? colorScheme,
    String? accentColor,
    FontSize? fontSize,
    String? fontFamily,
    bool? reduceMotion,
    bool? highContrast,
    bool? compactMode,
  }) {
    return AppearanceSettings(
      theme: theme ?? this.theme,
      colorScheme: colorScheme ?? this.colorScheme,
      accentColor: accentColor ?? this.accentColor,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      highContrast: highContrast ?? this.highContrast,
      compactMode: compactMode ?? this.compactMode,
    );
  }
}

// ============================================================
// 🔔 NOTIFICATION SETTINGS
// ============================================================

class NotificationSettings {
  final bool enabled;
  final bool sound;
  final bool vibration;
  final bool badgeCount;
  final bool previewContent;
  final QuietHoursSettings quietHours;
  final NotificationChannels channels;

  NotificationSettings({
    this.enabled = true,
    this.sound = true,
    this.vibration = true,
    this.badgeCount = true,
    this.previewContent = true,
    QuietHoursSettings? quietHours,
    NotificationChannels? channels,
  }) : quietHours = quietHours ?? QuietHoursSettings(),
        channels = channels ?? NotificationChannels();

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: _parseBool(json['enabled'], defaultValue: true),
      sound: _parseBool(json['sound'], defaultValue: true),
      vibration: _parseBool(json['vibration'], defaultValue: true),
      badgeCount: _parseBool(json['badge_count'], defaultValue: true),
      previewContent: _parseBool(json['preview_content'], defaultValue: true),
      quietHours: QuietHoursSettings.fromJson(
        _parseJsonField(json['quiet_hours']),
      ),
      channels: NotificationChannels.fromJson(
        _parseJsonField(json['channels']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'sound': sound,
      'vibration': vibration,
      'badge_count': badgeCount,
      'preview_content': previewContent,
      'quiet_hours': quietHours.toJson(),
      'channels': channels.toJson(),
    };
  }

  NotificationSettings copyWith({
    bool? enabled,
    bool? sound,
    bool? vibration,
    bool? badgeCount,
    bool? previewContent,
    QuietHoursSettings? quietHours,
    NotificationChannels? channels,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      badgeCount: badgeCount ?? this.badgeCount,
      previewContent: previewContent ?? this.previewContent,
      quietHours: quietHours ?? this.quietHours,
      channels: channels ?? this.channels,
    );
  }
}

class QuietHoursSettings {
  final bool enabled;
  final String start;
  final String end;
  final List<String> days;

  QuietHoursSettings({
    this.enabled = false,
    this.start = '22:00',
    this.end = '07:00',
    this.days = const [
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
    ],
  });

  factory QuietHoursSettings.fromJson(Map<String, dynamic> json) {
    return QuietHoursSettings(
      enabled: _parseBool(json['enabled']),
      start: json['start'] as String? ?? '22:00',
      end: json['end'] as String? ?? '07:00',
      days: List<String>.from(
        _parseJsonbListRaw(json['days']).isNotEmpty
            ? _parseJsonbListRaw(json['days'])
            : [
          'sunday',
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
        ],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'start': start,
      'end': end,
      'days': {'items': days},
    };
  }

  QuietHoursSettings copyWith({
    bool? enabled,
    String? start,
    String? end,
    List<String>? days,
  }) {
    return QuietHoursSettings(
      enabled: enabled ?? this.enabled,
      start: start ?? this.start,
      end: end ?? this.end,
      days: days ?? this.days,
    );
  }
}

class NotificationChannels {
  final TaskNotificationChannel tasks;
  final GoalNotificationChannel goals;
  final SocialNotificationChannel social;
  final ChatNotificationChannel chat;
  final DiaryNotificationChannel diary;
  final AiNotificationChannel ai;
  final AnalyticsNotificationChannel analytics;
  final CompetitionNotificationChannel competition;
  final MentoringNotificationChannel mentoring;
  final SystemNotificationChannel system;

  NotificationChannels({
    TaskNotificationChannel? tasks,
    GoalNotificationChannel? goals,
    SocialNotificationChannel? social,
    ChatNotificationChannel? chat,
    DiaryNotificationChannel? diary,
    AiNotificationChannel? ai,
    AnalyticsNotificationChannel? analytics,
    CompetitionNotificationChannel? competition,
    MentoringNotificationChannel? mentoring,
    SystemNotificationChannel? system,
  }) : tasks = tasks ?? TaskNotificationChannel(),
        goals = goals ?? GoalNotificationChannel(),
        social = social ?? SocialNotificationChannel(),
        chat = chat ?? ChatNotificationChannel(),
        diary = diary ?? DiaryNotificationChannel(),
        ai = ai ?? AiNotificationChannel(),
        analytics = analytics ?? AnalyticsNotificationChannel(),
        competition = competition ?? CompetitionNotificationChannel(),
        mentoring = mentoring ?? MentoringNotificationChannel(),
        system = system ?? SystemNotificationChannel();

  factory NotificationChannels.fromJson(Map<String, dynamic> json) {
    return NotificationChannels(
      tasks: TaskNotificationChannel.fromJson(_parseJsonField(json['tasks'])),
      goals: GoalNotificationChannel.fromJson(_parseJsonField(json['goals'])),
      social: SocialNotificationChannel.fromJson(
        _parseJsonField(json['social']),
      ),
      chat: ChatNotificationChannel.fromJson(_parseJsonField(json['chat'])),
      diary: DiaryNotificationChannel.fromJson(_parseJsonField(json['diary'])),
      ai: AiNotificationChannel.fromJson(_parseJsonField(json['ai'])),
      analytics: AnalyticsNotificationChannel.fromJson(
        _parseJsonField(json['analytics']),
      ),
      competition: CompetitionNotificationChannel.fromJson(
        _parseJsonField(json['competition']),
      ),
      mentoring: MentoringNotificationChannel.fromJson(
        _parseJsonField(json['mentoring']),
      ),
      system: SystemNotificationChannel.fromJson(
        _parseJsonField(json['system']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tasks': tasks.toJson(),
      'goals': goals.toJson(),
      'social': social.toJson(),
      'chat': chat.toJson(),
      'diary': diary.toJson(),
      'ai': ai.toJson(),
      'analytics': analytics.toJson(),
      'competition': competition.toJson(),
      'mentoring': mentoring.toJson(),
      'system': system.toJson(),
    };
  }

  NotificationChannels copyWith({
    TaskNotificationChannel? tasks,
    GoalNotificationChannel? goals,
    SocialNotificationChannel? social,
    ChatNotificationChannel? chat,
    DiaryNotificationChannel? diary,
    AiNotificationChannel? ai,
    AnalyticsNotificationChannel? analytics,
    CompetitionNotificationChannel? competition,
    MentoringNotificationChannel? mentoring,
    SystemNotificationChannel? system,
  }) {
    return NotificationChannels(
      tasks: tasks ?? this.tasks,
      goals: goals ?? this.goals,
      social: social ?? this.social,
      chat: chat ?? this.chat,
      diary: diary ?? this.diary,
      ai: ai ?? this.ai,
      analytics: analytics ?? this.analytics,
      competition: competition ?? this.competition,
      mentoring: mentoring ?? this.mentoring,
      system: system ?? this.system,
    );
  }
}

class TaskNotificationChannel {
  final bool enabled;
  final bool reminders;
  final bool dueSoon;
  final bool overdue;
  final bool completed;

  TaskNotificationChannel({
    this.enabled = true,
    this.reminders = true,
    this.dueSoon = true,
    this.overdue = true,
    this.completed = false,
  });

  factory TaskNotificationChannel.fromJson(Map<String, dynamic> json) {
    return TaskNotificationChannel(
      enabled: _parseBool(json['enabled'], defaultValue: true),
      reminders: _parseBool(json['reminders'], defaultValue: true),
      dueSoon: _parseBool(json['due_soon'], defaultValue: true),
      overdue: _parseBool(json['overdue'], defaultValue: true),
      completed: _parseBool(json['completed']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'reminders': reminders,
      'due_soon': dueSoon,
      'overdue': overdue,
      'completed': completed,
    };
  }

  TaskNotificationChannel copyWith({
    bool? enabled,
    bool? reminders,
    bool? dueSoon,
    bool? overdue,
    bool? completed,
  }) {
    return TaskNotificationChannel(
      enabled: enabled ?? this.enabled,
      reminders: reminders ?? this.reminders,
      dueSoon: dueSoon ?? this.dueSoon,
      overdue: overdue ?? this.overdue,
      completed: completed ?? this.completed,
    );
  }
}

class GoalNotificationChannel {
  final bool enabled;
  final bool milestones;
  final bool progressUpdates;
  final bool weeklySummary;

  GoalNotificationChannel({
    this.enabled = true,
    this.milestones = true,
    this.progressUpdates = true,
    this.weeklySummary = true,
  });

  factory GoalNotificationChannel.fromJson(Map<String, dynamic> json) {
    return GoalNotificationChannel(
      enabled: _parseBool(json['enabled'], defaultValue: true),
      milestones: _parseBool(json['milestones'], defaultValue: true),
      progressUpdates: _parseBool(json['progress_updates'], defaultValue: true),
      weeklySummary: _parseBool(json['weekly_summary'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'milestones': milestones,
      'progress_updates': progressUpdates,
      'weekly_summary': weeklySummary,
    };
  }

  GoalNotificationChannel copyWith({
    bool? enabled,
    bool? milestones,
    bool? progressUpdates,
    bool? weeklySummary,
  }) {
    return GoalNotificationChannel(
      enabled: enabled ?? this.enabled,
      milestones: milestones ?? this.milestones,
      progressUpdates: progressUpdates ?? this.progressUpdates,
      weeklySummary: weeklySummary ?? this.weeklySummary,
    );
  }
}

class SocialNotificationChannel {
  final bool enabled;
  final bool likes;
  final bool comments;
  final bool follows;
  final bool mentions;
  final bool shares;

  SocialNotificationChannel({
    this.enabled = true,
    this.likes = true,
    this.comments = true,
    this.follows = true,
    this.mentions = true,
    this.shares = true,
  });

  factory SocialNotificationChannel.fromJson(Map<String, dynamic> json) {
    return SocialNotificationChannel(
      enabled: _parseBool(json['enabled'], defaultValue: true),
      likes: _parseBool(json['likes'], defaultValue: true),
      comments: _parseBool(json['comments'], defaultValue: true),
      follows: _parseBool(json['follows'], defaultValue: true),
      mentions: _parseBool(json['mentions'], defaultValue: true),
      shares: _parseBool(json['shares'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'likes': likes,
      'comments': comments,
      'follows': follows,
      'mentions': mentions,
      'shares': shares,
    };
  }

  SocialNotificationChannel copyWith({
    bool? enabled,
    bool? likes,
    bool? comments,
    bool? follows,
    bool? mentions,
    bool? shares,
  }) {
    return SocialNotificationChannel(
      enabled: enabled ?? this.enabled,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      follows: follows ?? this.follows,
      mentions: mentions ?? this.mentions,
      shares: shares ?? this.shares,
    );
  }
}

class ChatNotificationChannel {
  final bool enabled;
  final bool messages;
  final bool groupMessages;
  final bool mentions;
  final bool reactions;

  ChatNotificationChannel({
    this.enabled = true,
    this.messages = true,
    this.groupMessages = true,
    this.mentions = true,
    this.reactions = false,
  });

  factory ChatNotificationChannel.fromJson(Map<String, dynamic> json) {
    return ChatNotificationChannel(
      enabled: _parseBool(json['enabled'], defaultValue: true),
      messages: _parseBool(json['messages'], defaultValue: true),
      groupMessages: _parseBool(json['group_messages'], defaultValue: true),
      mentions: _parseBool(json['mentions'], defaultValue: true),
      reactions: _parseBool(json['reactions']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'messages': messages,
      'group_messages': groupMessages,
      'mentions': mentions,
      'reactions': reactions,
    };
  }

  ChatNotificationChannel copyWith({
    bool? enabled,
    bool? messages,
    bool? groupMessages,
    bool? mentions,
    bool? reactions,
  }) {
    return ChatNotificationChannel(
      enabled: enabled ?? this.enabled,
      messages: messages ?? this.messages,
      groupMessages: groupMessages ?? this.groupMessages,
      mentions: mentions ?? this.mentions,
      reactions: reactions ?? this.reactions,
    );
  }
}

class DiaryNotificationChannel {
  final bool enabled;
  final bool dailyReminder;
  final String reminderTime;

  DiaryNotificationChannel({
    this.enabled = true,
    this.dailyReminder = true,
    this.reminderTime = '21:00',
  });

  factory DiaryNotificationChannel.fromJson(Map<String, dynamic> json) {
    return DiaryNotificationChannel(
      enabled: _parseBool(json['enabled'], defaultValue: true),
      dailyReminder: _parseBool(json['daily_reminder'], defaultValue: true),
      reminderTime: json['reminder_time'] as String? ?? '21:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'daily_reminder': dailyReminder,
      'reminder_time': reminderTime,
    };
  }

  DiaryNotificationChannel copyWith({
    bool? enabled,
    bool? dailyReminder,
    String? reminderTime,
  }) {
    return DiaryNotificationChannel(
      enabled: enabled ?? this.enabled,
      dailyReminder: dailyReminder ?? this.dailyReminder,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}

class AiNotificationChannel {
  final bool enabled;
  final bool suggestions;
  final bool insights;

  AiNotificationChannel({
    this.enabled = true,
    this.suggestions = true,
    this.insights = true,
  });

  factory AiNotificationChannel.fromJson(Map<String, dynamic> json) {
    return AiNotificationChannel(
      enabled: _parseBool(json['enabled'], defaultValue: true),
      suggestions: _parseBool(json['suggestions'], defaultValue: true),
      insights: _parseBool(json['insights'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'suggestions': suggestions,
      'insights': insights,
    };
  }

  AiNotificationChannel copyWith({
    bool? enabled,
    bool? suggestions,
    bool? insights,
  }) {
    return AiNotificationChannel(
      enabled: enabled ?? this.enabled,
      suggestions: suggestions ?? this.suggestions,
      insights: insights ?? this.insights,
    );
  }
}

class AnalyticsNotificationChannel {
  final bool enabled;
  final bool weeklyReports;
  final bool monthlyInsights;
  final bool trendAlerts;

  AnalyticsNotificationChannel({
    this.enabled = true,
    this.weeklyReports = true,
    this.monthlyInsights = true,
    this.trendAlerts = true,
  });

  factory AnalyticsNotificationChannel.fromJson(Map<String, dynamic> json) {
    return AnalyticsNotificationChannel(
      enabled: _parseBool(json['enabled'], defaultValue: true),
      weeklyReports: _parseBool(json['weekly_reports'], defaultValue: true),
      monthlyInsights: _parseBool(json['monthly_insights'], defaultValue: true),
      trendAlerts: _parseBool(json['trend_alerts'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'weekly_reports': weeklyReports,
      'monthly_insights': monthlyInsights,
      'trend_alerts': trendAlerts,
    };
  }

  AnalyticsNotificationChannel copyWith({
    bool? enabled,
    bool? weeklyReports,
    bool? monthlyInsights,
    bool? trendAlerts,
  }) {
    return AnalyticsNotificationChannel(
      enabled: enabled ?? this.enabled,
      weeklyReports: weeklyReports ?? this.weeklyReports,
      monthlyInsights: monthlyInsights ?? this.monthlyInsights,
      trendAlerts: trendAlerts ?? this.trendAlerts,
    );
  }
}

class CompetitionNotificationChannel {
  final bool enabled;
  final bool challengeReceived;
  final bool challengeUpdates;
  final bool leaderboardChanges;
  final bool tournamentInvites;
  final bool rankChanges;
  final bool milestoneReached;

  CompetitionNotificationChannel({
    this.enabled = true,
    this.challengeReceived = true,
    this.challengeUpdates = true,
    this.leaderboardChanges = true,
    this.tournamentInvites = true,
    this.rankChanges = true,
    this.milestoneReached = true,
  });

  factory CompetitionNotificationChannel.fromJson(Map<String, dynamic> json) {
    return CompetitionNotificationChannel(
      enabled: _parseBool(json['enabled'], defaultValue: true),
      challengeReceived: _parseBool(
        json['challenge_received'],
        defaultValue: true,
      ),
      challengeUpdates: _parseBool(json['challenge_updates'], defaultValue: true),
      leaderboardChanges: _parseBool(
        json['leaderboard_changes'],
        defaultValue: true,
      ),
      tournamentInvites: _parseBool(
        json['tournament_invites'],
        defaultValue: true,
      ),
      rankChanges: _parseBool(json['rank_changes'], defaultValue: true),
      milestoneReached: _parseBool(json['milestone_reached'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'challenge_received': challengeReceived,
      'challenge_updates': challengeUpdates,
      'leaderboard_changes': leaderboardChanges,
      'tournament_invites': tournamentInvites,
      'rank_changes': rankChanges,
      'milestone_reached': milestoneReached,
    };
  }

  CompetitionNotificationChannel copyWith({
    bool? enabled,
    bool? challengeReceived,
    bool? challengeUpdates,
    bool? leaderboardChanges,
    bool? tournamentInvites,
    bool? rankChanges,
    bool? milestoneReached,
  }) {
    return CompetitionNotificationChannel(
      enabled: enabled ?? this.enabled,
      challengeReceived: challengeReceived ?? this.challengeReceived,
      challengeUpdates: challengeUpdates ?? this.challengeUpdates,
      leaderboardChanges: leaderboardChanges ?? this.leaderboardChanges,
      tournamentInvites: tournamentInvites ?? this.tournamentInvites,
      rankChanges: rankChanges ?? this.rankChanges,
      milestoneReached: milestoneReached ?? this.milestoneReached,
    );
  }
}

class MentoringNotificationChannel {
  final bool enabled;
  final bool requests;
  final bool sessions;
  final bool feedback;
  final bool dataShared;

  MentoringNotificationChannel({
    this.enabled = true,
    this.requests = true,
    this.sessions = true,
    this.feedback = true,
    this.dataShared = true,
  });

  factory MentoringNotificationChannel.fromJson(Map<String, dynamic> json) {
    return MentoringNotificationChannel(
      enabled: _parseBool(json['enabled'], defaultValue: true),
      requests: _parseBool(json['requests'] ?? json['connection_requests'], defaultValue: true),
      sessions: _parseBool(json['sessions'] ?? json['session_reminders'], defaultValue: true),
      feedback: _parseBool(json['feedback'] ?? json['feedback_received'], defaultValue: true),
      dataShared: _parseBool(json['data_shared'] ?? json['data_shared_alerts'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'requests': requests,
      'sessions': sessions,
      'feedback': feedback,
      'data_shared': dataShared,
    };
  }

  MentoringNotificationChannel copyWith({
    bool? enabled,
    bool? requests,
    bool? sessions,
    bool? feedback,
    bool? dataShared,
  }) {
    return MentoringNotificationChannel(
      enabled: enabled ?? this.enabled,
      requests: requests ?? this.requests,
      sessions: sessions ?? this.sessions,
      feedback: feedback ?? this.feedback,
      dataShared: dataShared ?? this.dataShared,
    );
  }
}

class SystemNotificationChannel {
  final bool enabled;
  final bool updates;
  final bool security;
  final bool promotions;

  SystemNotificationChannel({
    this.enabled = true,
    this.updates = true,
    this.security = true,
    this.promotions = false,
  });

  factory SystemNotificationChannel.fromJson(Map<String, dynamic> json) {
    return SystemNotificationChannel(
      enabled: _parseBool(json['enabled'], defaultValue: true),
      updates: _parseBool(json['updates'], defaultValue: true),
      security: _parseBool(json['security'], defaultValue: true),
      promotions: _parseBool(json['promotions']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'updates': updates,
      'security': security,
      'promotions': promotions,
    };
  }

  SystemNotificationChannel copyWith({
    bool? enabled,
    bool? updates,
    bool? security,
    bool? promotions,
  }) {
    return SystemNotificationChannel(
      enabled: enabled ?? this.enabled,
      updates: updates ?? this.updates,
      security: security ?? this.security,
      promotions: promotions ?? this.promotions,
    );
  }
}

// ============================================================
// 🔒 PRIVACY SETTINGS
// ============================================================

class PrivacySettings {
  final ProfileVisibility profileVisibility;
  final bool showOnlineStatus;
  final bool showLastSeen;
  final bool showActivityStatus;
  final bool showReadReceipts;
  final bool showTypingIndicator;
  final AllowFrom allowMessagesFrom;
  final AllowFrom allowFollowsFrom;
  final AllowFrom allowCommentsFrom;
  final bool showInSearch;
  final bool showInSuggestions;
  final bool allowTagging;
  final bool allowMentions;
  final List<String> hideFromUsers;
  final List<String> blockedUsers;
  final List<String> restrictedUsers;
  final DataSharingSettings dataSharing;

  PrivacySettings({
    this.profileVisibility = ProfileVisibility.public,
    this.showOnlineStatus = true,
    this.showLastSeen = true,
    this.showActivityStatus = true,
    this.showReadReceipts = true,
    this.showTypingIndicator = true,
    this.allowMessagesFrom = AllowFrom.everyone,
    this.allowFollowsFrom = AllowFrom.everyone,
    this.allowCommentsFrom = AllowFrom.everyone,
    this.showInSearch = true,
    this.showInSuggestions = true,
    this.allowTagging = true,
    this.allowMentions = true,
    this.hideFromUsers = const [],
    this.blockedUsers = const [],
    this.restrictedUsers = const [],
    DataSharingSettings? dataSharing,
  }) : dataSharing = dataSharing ?? DataSharingSettings();

  bool isUserBlocked(String userId) => blockedUsers.contains(userId);
  bool isUserRestricted(String userId) => restrictedUsers.contains(userId);
  bool isHiddenFrom(String userId) => hideFromUsers.contains(userId);

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      profileVisibility: _parseEnum(
        json['profile_visibility'],
        ProfileVisibility.values,
        ProfileVisibility.public,
      ),
      showOnlineStatus: _parseBool(
        json['show_online_status'],
        defaultValue: true,
      ),
      showLastSeen: _parseBool(json['show_last_seen'], defaultValue: true),
      showActivityStatus: _parseBool(
        json['show_activity_status'],
        defaultValue: true,
      ),
      showReadReceipts: _parseBool(
        json['show_read_receipts'],
        defaultValue: true,
      ),
      showTypingIndicator: _parseBool(
        json['show_typing_indicator'],
        defaultValue: true,
      ),
      allowMessagesFrom: _parseEnum(
        json['allow_messages_from'],
        AllowFrom.values,
        AllowFrom.everyone,
      ),
      allowFollowsFrom: _parseEnum(
        json['allow_follows_from'],
        AllowFrom.values,
        AllowFrom.everyone,
      ),
      allowCommentsFrom: _parseEnum(
        json['allow_comments_from'],
        AllowFrom.values,
        AllowFrom.everyone,
      ),
      showInSearch: _parseBool(json['show_in_search'], defaultValue: true),
      showInSuggestions: _parseBool(
        json['show_in_suggestions'],
        defaultValue: true,
      ),
      allowTagging: _parseBool(json['allow_tagging'], defaultValue: true),
      allowMentions: _parseBool(json['allow_mentions'], defaultValue: true),
      hideFromUsers: List<String>.from(_parseJsonbListRaw(json['hide_from_users'])),
      blockedUsers: List<String>.from(_parseJsonbListRaw(json['blocked_users'])),
      restrictedUsers: List<String>.from(_parseJsonbListRaw(json['restricted_users'])),
      dataSharing: DataSharingSettings.fromJson(
        _parseJsonField(json['data_sharing']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_visibility': profileVisibility.name,
      'show_online_status': showOnlineStatus,
      'show_last_seen': showLastSeen,
      'show_activity_status': showActivityStatus,
      'show_read_receipts': showReadReceipts,
      'show_typing_indicator': showTypingIndicator,
      'allow_messages_from': allowMessagesFrom.name,
      'allow_follows_from': allowFollowsFrom.name,
      'allow_comments_from': allowCommentsFrom.name,
      'show_in_search': showInSearch,
      'show_in_suggestions': showInSuggestions,
      'allow_tagging': allowTagging,
      'allow_mentions': allowMentions,
      'hide_from_users': {'items': hideFromUsers},
      'blocked_users': {'items': blockedUsers},
      'restricted_users': {'items': restrictedUsers},
      'data_sharing': dataSharing.toJson(),
    };
  }

  PrivacySettings copyWith({
    ProfileVisibility? profileVisibility,
    bool? showOnlineStatus,
    bool? showLastSeen,
    bool? showActivityStatus,
    bool? showReadReceipts,
    bool? showTypingIndicator,
    AllowFrom? allowMessagesFrom,
    AllowFrom? allowFollowsFrom,
    AllowFrom? allowCommentsFrom,
    bool? showInSearch,
    bool? showInSuggestions,
    bool? allowTagging,
    bool? allowMentions,
    List<String>? hideFromUsers,
    List<String>? blockedUsers,
    List<String>? restrictedUsers,
    DataSharingSettings? dataSharing,
  }) {
    return PrivacySettings(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showLastSeen: showLastSeen ?? this.showLastSeen,
      showActivityStatus: showActivityStatus ?? this.showActivityStatus,
      showReadReceipts: showReadReceipts ?? this.showReadReceipts,
      showTypingIndicator: showTypingIndicator ?? this.showTypingIndicator,
      allowMessagesFrom: allowMessagesFrom ?? this.allowMessagesFrom,
      allowFollowsFrom: allowFollowsFrom ?? this.allowFollowsFrom,
      allowCommentsFrom: allowCommentsFrom ?? this.allowCommentsFrom,
      showInSearch: showInSearch ?? this.showInSearch,
      showInSuggestions: showInSuggestions ?? this.showInSuggestions,
      allowTagging: allowTagging ?? this.allowTagging,
      allowMentions: allowMentions ?? this.allowMentions,
      hideFromUsers: hideFromUsers ?? this.hideFromUsers,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      restrictedUsers: restrictedUsers ?? this.restrictedUsers,
      dataSharing: dataSharing ?? this.dataSharing,
    );
  }
}

class DataSharingSettings {
  final bool analytics;
  final bool personalization;
  final bool thirdParty;

  DataSharingSettings({
    this.analytics = true,
    this.personalization = true,
    this.thirdParty = false,
  });

  factory DataSharingSettings.fromJson(Map<String, dynamic> json) {
    return DataSharingSettings(
      analytics: _parseBool(json['analytics'], defaultValue: true),
      personalization: _parseBool(json['personalization'], defaultValue: true),
      thirdParty: _parseBool(json['third_party']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analytics': analytics,
      'personalization': personalization,
      'third_party': thirdParty,
    };
  }

  DataSharingSettings copyWith({
    bool? analytics,
    bool? personalization,
    bool? thirdParty,
  }) {
    return DataSharingSettings(
      analytics: analytics ?? this.analytics,
      personalization: personalization ?? this.personalization,
      thirdParty: thirdParty ?? this.thirdParty,
    );
  }
}

// ============================================================
// 📅 TASK SETTINGS
// ============================================================

class TaskSettings {
  final TaskView defaultView;
  final bool showCompleted;
  final bool autoArchiveCompleted;
  final int archiveAfterDays;
  final Priority defaultPriority;
  final int defaultReminder;
  final WeekDay weekStartsOn;
  final List<WeekDay> workingDays;
  final WorkingHours workingHours;
  final bool showSubtasks;
  final bool showTimeEstimates;
  final bool autoSchedule;
  final bool rolloverIncomplete;
  final int? dailyTaskLimit;
  final String? defaultCategory;
  final QuickAddDefaults quickAddDefaults;

  TaskSettings({
    this.defaultView = TaskView.list,
    this.showCompleted = true,
    this.autoArchiveCompleted = false,
    this.archiveAfterDays = 7,
    this.defaultPriority = Priority.medium,
    this.defaultReminder = 30,
    this.weekStartsOn = WeekDay.monday,
    this.workingDays = const [
      WeekDay.monday,
      WeekDay.tuesday,
      WeekDay.wednesday,
      WeekDay.thursday,
      WeekDay.friday,
    ],
    WorkingHours? workingHours,
    this.showSubtasks = true,
    this.showTimeEstimates = true,
    this.autoSchedule = false,
    this.rolloverIncomplete = true,
    this.dailyTaskLimit,
    this.defaultCategory,
    QuickAddDefaults? quickAddDefaults,
  }) : workingHours = workingHours ?? WorkingHours(),
        quickAddDefaults = quickAddDefaults ?? QuickAddDefaults();

  factory TaskSettings.fromJson(Map<String, dynamic> json) {
    return TaskSettings(
      defaultView: _parseEnum(
        json['default_view'],
        TaskView.values,
        TaskView.list,
      ),
      showCompleted: _parseBool(json['show_completed'], defaultValue: true),
      autoArchiveCompleted: _parseBool(json['auto_archive_completed']),
      archiveAfterDays: json['archive_after_days'] as int? ?? 7,
      defaultPriority: _parseEnum(
        json['default_priority'],
        Priority.values,
        Priority.medium,
      ),
      defaultReminder: json['default_reminder'] as int? ?? 30,
      weekStartsOn: _parseEnum(
        json['week_starts_on'],
        WeekDay.values,
        WeekDay.monday,
      ),
      workingDays:
      _parseJsonbListRaw(json['working_days']).isEmpty
          ? [
        WeekDay.monday,
        WeekDay.tuesday,
        WeekDay.wednesday,
        WeekDay.thursday,
        WeekDay.friday,
      ]
          : _parseJsonbListRaw(json['working_days'])
          .map((e) => _parseEnum(e, WeekDay.values, WeekDay.monday))
          .toList(),
      workingHours: WorkingHours.fromJson(
        _parseJsonField(json['working_hours']),
      ),
      showSubtasks: _parseBool(json['show_subtasks'], defaultValue: true),
      showTimeEstimates: _parseBool(
        json['show_time_estimates'],
        defaultValue: true,
      ),
      autoSchedule: _parseBool(json['auto_schedule']),
      rolloverIncomplete: _parseBool(
        json['rollover_incomplete'],
        defaultValue: true,
      ),
      dailyTaskLimit: json['daily_task_limit'] as int?,
      defaultCategory: json['default_category'] as String?,
      quickAddDefaults: QuickAddDefaults.fromJson(
        _parseJsonField(json['quick_add_defaults']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'default_view': defaultView.name,
      'show_completed': showCompleted,
      'auto_archive_completed': autoArchiveCompleted,
      'archive_after_days': archiveAfterDays,
      'default_priority': defaultPriority.name,
      'default_reminder': defaultReminder,
      'week_starts_on': weekStartsOn.name,
      'working_days': {'items': workingDays.map((e) => e.name).toList()},
      'working_hours': workingHours.toJson(),
      'show_subtasks': showSubtasks,
      'show_time_estimates': showTimeEstimates,
      'auto_schedule': autoSchedule,
      'rollover_incomplete': rolloverIncomplete,
      'daily_task_limit': dailyTaskLimit,
      'default_category': defaultCategory,
      'quick_add_defaults': quickAddDefaults.toJson(),
    };
  }

  TaskSettings copyWith({
    TaskView? defaultView,
    bool? showCompleted,
    bool? autoArchiveCompleted,
    int? archiveAfterDays,
    Priority? defaultPriority,
    int? defaultReminder,
    WeekDay? weekStartsOn,
    List<WeekDay>? workingDays,
    WorkingHours? workingHours,
    bool? showSubtasks,
    bool? showTimeEstimates,
    bool? autoSchedule,
    bool? rolloverIncomplete,
    int? dailyTaskLimit,
    String? defaultCategory,
    QuickAddDefaults? quickAddDefaults,
  }) {
    return TaskSettings(
      defaultView: defaultView ?? this.defaultView,
      showCompleted: showCompleted ?? this.showCompleted,
      autoArchiveCompleted: autoArchiveCompleted ?? this.autoArchiveCompleted,
      archiveAfterDays: archiveAfterDays ?? this.archiveAfterDays,
      defaultPriority: defaultPriority ?? this.defaultPriority,
      defaultReminder: defaultReminder ?? this.defaultReminder,
      weekStartsOn: weekStartsOn ?? this.weekStartsOn,
      workingDays: workingDays ?? this.workingDays,
      workingHours: workingHours ?? this.workingHours,
      showSubtasks: showSubtasks ?? this.showSubtasks,
      showTimeEstimates: showTimeEstimates ?? this.showTimeEstimates,
      autoSchedule: autoSchedule ?? this.autoSchedule,
      rolloverIncomplete: rolloverIncomplete ?? this.rolloverIncomplete,
      dailyTaskLimit: dailyTaskLimit ?? this.dailyTaskLimit,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      quickAddDefaults: quickAddDefaults ?? this.quickAddDefaults,
    );
  }
}

class WorkingHours {
  final String start;
  final String end;

  WorkingHours({this.start = '09:00', this.end = '17:00'});

  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    return WorkingHours(
      start: json['start'] as String? ?? '09:00',
      end: json['end'] as String? ?? '17:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {'start': start, 'end': end};
  }

  WorkingHours copyWith({String? start, String? end}) {
    return WorkingHours(start: start ?? this.start, end: end ?? this.end);
  }
}

class QuickAddDefaults {
  final Priority priority;
  final bool addToToday;

  QuickAddDefaults({this.priority = Priority.medium, this.addToToday = true});

  factory QuickAddDefaults.fromJson(Map<String, dynamic> json) {
    return QuickAddDefaults(
      priority: _parseEnum(json['priority'], Priority.values, Priority.medium),
      addToToday: _parseBool(json['add_to_today'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {'priority': priority.name, 'add_to_today': addToToday};
  }

  QuickAddDefaults copyWith({Priority? priority, bool? addToToday}) {
    return QuickAddDefaults(
      priority: priority ?? this.priority,
      addToToday: addToToday ?? this.addToToday,
    );
  }
}

// ============================================================
// 🎯 GOAL SETTINGS
// ============================================================

class GoalSettings {
  final GoalView defaultView;
  final bool showArchived;
  final ProgressCalculation progressCalculation;
  final bool milestoneNotifications;
  final WeekDay weeklyReviewDay;
  final String weeklyReviewTime;
  final bool showStreak;
  final bool goalTemplates;
  final bool aiSuggestions;

  GoalSettings({
    this.defaultView = GoalView.grid,
    this.showArchived = false,
    this.progressCalculation = ProgressCalculation.automatic,
    this.milestoneNotifications = true,
    this.weeklyReviewDay = WeekDay.sunday,
    this.weeklyReviewTime = '10:00',
    this.showStreak = true,
    this.goalTemplates = true,
    this.aiSuggestions = true,
  });

  factory GoalSettings.fromJson(Map<String, dynamic> json) {
    return GoalSettings(
      defaultView: _parseEnum(
        json['default_view'],
        GoalView.values,
        GoalView.grid,
      ),
      showArchived: _parseBool(json['show_archived']),
      progressCalculation: _parseEnum(
        json['progress_calculation'],
        ProgressCalculation.values,
        ProgressCalculation.automatic,
      ),
      milestoneNotifications: _parseBool(
        json['milestone_notifications'],
        defaultValue: true,
      ),
      weeklyReviewDay: _parseEnum(
        json['weekly_review_day'],
        WeekDay.values,
        WeekDay.sunday,
      ),
      weeklyReviewTime: json['weekly_review_time'] as String? ?? '10:00',
      showStreak: _parseBool(json['show_streak'], defaultValue: true),
      goalTemplates: _parseBool(json['goal_templates'], defaultValue: true),
      aiSuggestions: _parseBool(json['ai_suggestions'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'default_view': defaultView.name,
      'show_archived': showArchived,
      'progress_calculation': progressCalculation.name,
      'milestone_notifications': milestoneNotifications,
      'weekly_review_day': weeklyReviewDay.name,
      'weekly_review_time': weeklyReviewTime,
      'show_streak': showStreak,
      'goal_templates': goalTemplates,
      'ai_suggestions': aiSuggestions,
    };
  }

  GoalSettings copyWith({
    GoalView? defaultView,
    bool? showArchived,
    ProgressCalculation? progressCalculation,
    bool? milestoneNotifications,
    WeekDay? weeklyReviewDay,
    String? weeklyReviewTime,
    bool? showStreak,
    bool? goalTemplates,
    bool? aiSuggestions,
  }) {
    return GoalSettings(
      defaultView: defaultView ?? this.defaultView,
      showArchived: showArchived ?? this.showArchived,
      progressCalculation: progressCalculation ?? this.progressCalculation,
      milestoneNotifications:
      milestoneNotifications ?? this.milestoneNotifications,
      weeklyReviewDay: weeklyReviewDay ?? this.weeklyReviewDay,
      weeklyReviewTime: weeklyReviewTime ?? this.weeklyReviewTime,
      showStreak: showStreak ?? this.showStreak,
      goalTemplates: goalTemplates ?? this.goalTemplates,
      aiSuggestions: aiSuggestions ?? this.aiSuggestions,
    );
  }
}

// ============================================================
// 🪣 BUCKET LIST SETTINGS
// ============================================================

class BucketListSettings {
  final BucketView defaultView;
  final bool showCompleted;
  final bool showCostEstimates;
  final ProfileVisibility defaultVisibility;
  final bool inspirationFeed;
  final bool locationSuggestions;

  BucketListSettings({
    this.defaultView = BucketView.grid,
    this.showCompleted = true,
    this.showCostEstimates = true,
    this.defaultVisibility = ProfileVisibility.private,
    this.inspirationFeed = true,
    this.locationSuggestions = true,
  });

  factory BucketListSettings.fromJson(Map<String, dynamic> json) {
    return BucketListSettings(
      defaultView: _parseEnum(
        json['default_view'],
        BucketView.values,
        BucketView.grid,
      ),
      showCompleted: _parseBool(json['show_completed'], defaultValue: true),
      showCostEstimates: _parseBool(
        json['show_cost_estimates'],
        defaultValue: true,
      ),
      defaultVisibility: _parseEnum(
        json['default_visibility'],
        ProfileVisibility.values,
        ProfileVisibility.private,
      ),
      inspirationFeed: _parseBool(json['inspiration_feed'], defaultValue: true),
      locationSuggestions: _parseBool(
        json['location_suggestions'],
        defaultValue: true,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'default_view': defaultView.name,
      'show_completed': showCompleted,
      'show_cost_estimates': showCostEstimates,
      'default_visibility': defaultVisibility.name,
      'inspiration_feed': inspirationFeed,
      'location_suggestions': locationSuggestions,
    };
  }

  BucketListSettings copyWith({
    BucketView? defaultView,
    bool? showCompleted,
    bool? showCostEstimates,
    ProfileVisibility? defaultVisibility,
    bool? inspirationFeed,
    bool? locationSuggestions,
  }) {
    return BucketListSettings(
      defaultView: defaultView ?? this.defaultView,
      showCompleted: showCompleted ?? this.showCompleted,
      showCostEstimates: showCostEstimates ?? this.showCostEstimates,
      defaultVisibility: defaultVisibility ?? this.defaultVisibility,
      inspirationFeed: inspirationFeed ?? this.inspirationFeed,
      locationSuggestions: locationSuggestions ?? this.locationSuggestions,
    );
  }
}

// ============================================================
// 📔 DIARY SETTINGS
// ============================================================

class DiarySettings {
  final bool dailyPrompt;
  final String promptTime;
  final bool defaultMoodTracking;
  final bool showWordCount;
  final bool autoSave;
  final int autoSaveInterval;
  final bool showLinkedItems;
  final ProfileVisibility defaultVisibility;
  final bool enableRichText;
  final bool showWeather;
  final bool showLocation;
  final List<DiaryTemplate> templates;
  final List<String> favoritePrompts;

  DiarySettings({
    this.dailyPrompt = true,
    this.promptTime = '21:00',
    this.defaultMoodTracking = true,
    this.showWordCount = true,
    this.autoSave = true,
    this.autoSaveInterval = 30,
    this.showLinkedItems = true,
    this.defaultVisibility = ProfileVisibility.private,
    this.enableRichText = true,
    this.showWeather = true,
    this.showLocation = false,
    this.templates = const [],
    this.favoritePrompts = const [],
  });

  factory DiarySettings.fromJson(Map<String, dynamic> json) {
    return DiarySettings(
      dailyPrompt: _parseBool(json['daily_prompt'], defaultValue: true),
      promptTime: json['prompt_time'] as String? ?? '21:00',
      defaultMoodTracking: _parseBool(
        json['default_mood_tracking'],
        defaultValue: true,
      ),
      showWordCount: _parseBool(json['show_word_count'], defaultValue: true),
      autoSave: _parseBool(json['auto_save'], defaultValue: true),
      autoSaveInterval: json['auto_save_interval'] as int? ?? 30,
      showLinkedItems: _parseBool(
        json['show_linked_items'],
        defaultValue: true,
      ),
      defaultVisibility: _parseEnum(
        json['default_visibility'],
        ProfileVisibility.values,
        ProfileVisibility.private,
      ),
      enableRichText: _parseBool(json['enable_rich_text'], defaultValue: true),
      showWeather: _parseBool(json['show_weather'], defaultValue: true),
      showLocation: _parseBool(json['show_location']),
      templates:
      (json['templates'] as List<dynamic>?)
          ?.map((e) => DiaryTemplate.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      favoritePrompts: List<String>.from(json['favorite_prompts'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_prompt': dailyPrompt,
      'prompt_time': promptTime,
      'default_mood_tracking': defaultMoodTracking,
      'show_word_count': showWordCount,
      'auto_save': autoSave,
      'auto_save_interval': autoSaveInterval,
      'show_linked_items': showLinkedItems,
      'default_visibility': defaultVisibility.name,
      'enable_rich_text': enableRichText,
      'show_weather': showWeather,
      'show_location': showLocation,
      'templates': templates.map((e) => e.toJson()).toList(),
      'favorite_prompts': favoritePrompts,
    };
  }

  DiarySettings copyWith({
    bool? dailyPrompt,
    String? promptTime,
    bool? defaultMoodTracking,
    bool? showWordCount,
    bool? autoSave,
    int? autoSaveInterval,
    bool? showLinkedItems,
    ProfileVisibility? defaultVisibility,
    bool? enableRichText,
    bool? showWeather,
    bool? showLocation,
    List<DiaryTemplate>? templates,
    List<String>? favoritePrompts,
  }) {
    return DiarySettings(
      dailyPrompt: dailyPrompt ?? this.dailyPrompt,
      promptTime: promptTime ?? this.promptTime,
      defaultMoodTracking: defaultMoodTracking ?? this.defaultMoodTracking,
      showWordCount: showWordCount ?? this.showWordCount,
      autoSave: autoSave ?? this.autoSave,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      showLinkedItems: showLinkedItems ?? this.showLinkedItems,
      defaultVisibility: defaultVisibility ?? this.defaultVisibility,
      enableRichText: enableRichText ?? this.enableRichText,
      showWeather: showWeather ?? this.showWeather,
      showLocation: showLocation ?? this.showLocation,
      templates: templates ?? this.templates,
      favoritePrompts: favoritePrompts ?? this.favoritePrompts,
    );
  }
}

class DiaryTemplate {
  final String id;
  final String name;
  final String content;
  final bool isDefault;

  DiaryTemplate({
    required this.id,
    required this.name,
    required this.content,
    this.isDefault = false,
  });

  factory DiaryTemplate.fromJson(Map<String, dynamic> json) {
    return DiaryTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isDefault: _parseBool(json['is_default']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'is_default': isDefault,
    };
  }

  DiaryTemplate copyWith({
    String? id,
    String? name,
    String? content,
    bool? isDefault,
  }) {
    return DiaryTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

// ============================================================
// 💬 CHAT SETTINGS
// ============================================================

class ChatSettings {
  final bool enterToSend;
  final MediaAutoDownload mediaAutoDownload;
  final bool saveToGallery;
  final bool linkPreview;
  final bool emojiSuggestions;
  final bool stickerSuggestions;
  final ChatBackupSettings chatBackup;
  final int? defaultDisappearing;
  final BubbleStyle bubbleStyle;
  final String fontSize;
  final String? chatWallpaper;
  final ChatSwipeActions swipeActions;
  final bool openToChat;

  ChatSettings({
    this.enterToSend = true,
    this.mediaAutoDownload = MediaAutoDownload.wifi,
    this.saveToGallery = false,
    this.linkPreview = true,
    this.emojiSuggestions = true,
    this.stickerSuggestions = true,
    ChatBackupSettings? chatBackup,
    this.defaultDisappearing,
    this.bubbleStyle = BubbleStyle.defaultStyle,
    this.fontSize = 'medium',
    this.chatWallpaper,
    ChatSwipeActions? swipeActions,
    this.openToChat = true,
  }) : chatBackup = chatBackup ?? ChatBackupSettings(),
        swipeActions = swipeActions ?? ChatSwipeActions();

  factory ChatSettings.fromJson(Map<String, dynamic> json) {
    return ChatSettings(
      enterToSend: _parseBool(json['enter_to_send'], defaultValue: true),
      mediaAutoDownload: _parseEnum(
        json['media_auto_download'],
        MediaAutoDownload.values,
        MediaAutoDownload.wifi,
      ),
      saveToGallery: _parseBool(json['save_to_gallery']),
      linkPreview: _parseBool(json['link_preview'], defaultValue: true),
      emojiSuggestions: _parseBool(
        json['emoji_suggestions'],
        defaultValue: true,
      ),
      stickerSuggestions: _parseBool(
        json['sticker_suggestions'],
        defaultValue: true,
      ),
      chatBackup: ChatBackupSettings.fromJson(
        _parseJsonField(json['chat_backup']),
      ),
      defaultDisappearing: json['default_disappearing'] as int?,
      bubbleStyle: _parseEnum(
        json['bubble_style'],
        BubbleStyle.values,
        BubbleStyle.defaultStyle,
      ),
      fontSize: json['font_size'] as String? ?? 'medium',
      chatWallpaper: json['chat_wallpaper'] as String?,
      swipeActions: ChatSwipeActions.fromJson(
        _parseJsonField(json['swipe_actions']),
      ),
      openToChat: _parseBool(json['open_to_chat'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enter_to_send': enterToSend,
      'media_auto_download': mediaAutoDownload.name,
      'save_to_gallery': saveToGallery,
      'link_preview': linkPreview,
      'emoji_suggestions': emojiSuggestions,
      'sticker_suggestions': stickerSuggestions,
      'chat_backup': chatBackup.toJson(),
      'default_disappearing': defaultDisappearing,
      'bubble_style': bubbleStyle.name,
      'font_size': fontSize,
      'chat_wallpaper': chatWallpaper,
      'swipe_actions': swipeActions.toJson(),
      'open_to_chat': openToChat,
    };
  }

  ChatSettings copyWith({
    bool? enterToSend,
    MediaAutoDownload? mediaAutoDownload,
    bool? saveToGallery,
    bool? linkPreview,
    bool? emojiSuggestions,
    bool? stickerSuggestions,
    ChatBackupSettings? chatBackup,
    int? defaultDisappearing,
    BubbleStyle? bubbleStyle,
    String? fontSize,
    String? chatWallpaper,
    ChatSwipeActions? swipeActions,
    bool? openToChat,
  }) {
    return ChatSettings(
      enterToSend: enterToSend ?? this.enterToSend,
      mediaAutoDownload: mediaAutoDownload ?? this.mediaAutoDownload,
      saveToGallery: saveToGallery ?? this.saveToGallery,
      linkPreview: linkPreview ?? this.linkPreview,
      emojiSuggestions: emojiSuggestions ?? this.emojiSuggestions,
      stickerSuggestions: stickerSuggestions ?? this.stickerSuggestions,
      chatBackup: chatBackup ?? this.chatBackup,
      defaultDisappearing: defaultDisappearing ?? this.defaultDisappearing,
      bubbleStyle: bubbleStyle ?? this.bubbleStyle,
      fontSize: fontSize ?? this.fontSize,
      chatWallpaper: chatWallpaper ?? this.chatWallpaper,
      swipeActions: swipeActions ?? this.swipeActions,
      openToChat: openToChat ?? this.openToChat,
    );
  }
}

class ChatBackupSettings {
  final bool enabled;
  final String frequency;
  final bool includeMedia;

  ChatBackupSettings({
    this.enabled = false,
    this.frequency = 'weekly',
    this.includeMedia = false,
  });

  factory ChatBackupSettings.fromJson(Map<String, dynamic> json) {
    return ChatBackupSettings(
      enabled: _parseBool(json['enabled']),
      frequency: json['frequency'] as String? ?? 'weekly',
      includeMedia: _parseBool(json['include_media']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'frequency': frequency,
      'include_media': includeMedia,
    };
  }

  ChatBackupSettings copyWith({
    bool? enabled,
    String? frequency,
    bool? includeMedia,
  }) {
    return ChatBackupSettings(
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      includeMedia: includeMedia ?? this.includeMedia,
    );
  }
}

class ChatSwipeActions {
  final SwipeAction left;
  final SwipeAction right;

  ChatSwipeActions({
    this.left = SwipeAction.reply,
    this.right = SwipeAction.archive,
  });

  factory ChatSwipeActions.fromJson(Map<String, dynamic> json) {
    return ChatSwipeActions(
      left: _parseEnum(json['left'], SwipeAction.values, SwipeAction.reply),
      right: _parseEnum(json['right'], SwipeAction.values, SwipeAction.archive),
    );
  }

  Map<String, dynamic> toJson() {
    return {'left': left.name, 'right': right.name};
  }

  ChatSwipeActions copyWith({SwipeAction? left, SwipeAction? right}) {
    return ChatSwipeActions(
      left: left ?? this.left,
      right: right ?? this.right,
    );
  }
}

// ============================================================
// 📱 SOCIAL SETTINGS
// ============================================================

class SocialSettings {
  final ProfileVisibility defaultPostVisibility;
  final bool autoShareAchievements;
  final bool showActivityOnProfile;
  final FeedPreferences feedPreferences;
  final MediaAutoDownload autoPlayVideos;
  final bool reduceDataUsage;
  final bool hideSeenPosts;
  final List<String> mutedWords;
  final List<String> mutedAccounts;
  final String? createdCommunityId;
  final String? promotedCommunityId;

  SocialSettings({
    this.defaultPostVisibility = ProfileVisibility.public,
    this.autoShareAchievements = false,
    this.showActivityOnProfile = true,
    FeedPreferences? feedPreferences,
    this.autoPlayVideos = MediaAutoDownload.wifi,
    this.reduceDataUsage = false,
    this.hideSeenPosts = false,
    this.mutedWords = const [],
    this.mutedAccounts = const [],
    this.createdCommunityId,
    this.promotedCommunityId,
  }) : feedPreferences = feedPreferences ?? FeedPreferences();

  factory SocialSettings.fromJson(Map<String, dynamic> json) {
    return SocialSettings(
      defaultPostVisibility: _parseEnum(
        json['default_post_visibility'],
        ProfileVisibility.values,
        ProfileVisibility.public,
      ),
      autoShareAchievements: _parseBool(json['auto_share_achievements']),
      showActivityOnProfile: _parseBool(
        json['show_activity_on_profile'],
        defaultValue: true,
      ),
      feedPreferences: FeedPreferences.fromJson(
        _parseJsonField(json['feed_preferences']),
      ),
      autoPlayVideos: _parseEnum(
        json['auto_play_videos'],
        MediaAutoDownload.values,
        MediaAutoDownload.wifi,
      ),
      reduceDataUsage: _parseBool(json['reduce_data_usage']),
      hideSeenPosts: _parseBool(json['hide_seen_posts']),
      mutedWords: List<String>.from(json['muted_words'] ?? []),
      mutedAccounts: List<String>.from(json['muted_accounts'] ?? []),
      createdCommunityId: json['created_community_id'] as String?,
      promotedCommunityId: json['promoted_community_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'default_post_visibility': defaultPostVisibility.name,
      'auto_share_achievements': autoShareAchievements,
      'show_activity_on_profile': showActivityOnProfile,
      'feed_preferences': feedPreferences.toJson(),
      'auto_play_videos': autoPlayVideos.name,
      'reduce_data_usage': reduceDataUsage,
      'hide_seen_posts': hideSeenPosts,
      'muted_words': mutedWords,
      'muted_accounts': mutedAccounts,
      'created_community_id': createdCommunityId,
      'promoted_community_id': promotedCommunityId,
    };
  }

  SocialSettings copyWith({
    ProfileVisibility? defaultPostVisibility,
    bool? autoShareAchievements,
    bool? showActivityOnProfile,
    FeedPreferences? feedPreferences,
    MediaAutoDownload? autoPlayVideos,
    bool? reduceDataUsage,
    bool? hideSeenPosts,
    List<String>? mutedWords,
    List<String>? mutedAccounts,
    String? createdCommunityId,
    String? promotedCommunityId,
  }) {
    return SocialSettings(
      defaultPostVisibility:
      defaultPostVisibility ?? this.defaultPostVisibility,
      autoShareAchievements:
      autoShareAchievements ?? this.autoShareAchievements,
      showActivityOnProfile:
      showActivityOnProfile ?? this.showActivityOnProfile,
      feedPreferences: feedPreferences ?? this.feedPreferences,
      autoPlayVideos: autoPlayVideos ?? this.autoPlayVideos,
      reduceDataUsage: reduceDataUsage ?? this.reduceDataUsage,
      hideSeenPosts: hideSeenPosts ?? this.hideSeenPosts,
      mutedWords: mutedWords ?? this.mutedWords,
      mutedAccounts: mutedAccounts ?? this.mutedAccounts,
      createdCommunityId: createdCommunityId ?? this.createdCommunityId,
      promotedCommunityId: promotedCommunityId ?? this.promotedCommunityId,
    );
  }
}

class FeedPreferences {
  final FeedShowFrom showFrom;
  final List<String> contentTypes;
  final FeedSortBy sortBy;

  FeedPreferences({
    this.showFrom = FeedShowFrom.all,
    this.contentTypes = const ['posts', 'achievements', 'goals', 'buckets'],
    this.sortBy = FeedSortBy.recent,
  });

  factory FeedPreferences.fromJson(Map<String, dynamic> json) {
    return FeedPreferences(
      showFrom: _parseEnum(
        json['show_from'],
        FeedShowFrom.values,
        FeedShowFrom.all,
      ),
      contentTypes: List<String>.from(
        json['content_types'] ?? ['posts', 'achievements', 'goals', 'buckets'],
      ),
      sortBy: _parseEnum(json['sort_by'], FeedSortBy.values, FeedSortBy.recent),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'show_from': showFrom.name,
      'content_types': contentTypes,
      'sort_by': sortBy.name,
    };
  }

  FeedPreferences copyWith({
    FeedShowFrom? showFrom,
    List<String>? contentTypes,
    FeedSortBy? sortBy,
  }) {
    return FeedPreferences(
      showFrom: showFrom ?? this.showFrom,
      contentTypes: contentTypes ?? this.contentTypes,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

// ============================================================
// 🤖 AI SETTINGS
// ============================================================

class AiSettings {
  final bool enabled;
  final bool autoSuggestions;
  final SuggestionFrequency suggestionFrequency;
  final String preferredModel;
  final bool autoFallback;
  final int contextDepth;
  final ResponseStyle responseStyle;
  final AiUsageSettings useFor;
  final AiDataUsageSettings dataUsage;
  final int? dailyTokenLimit;
  final bool showUsageStats;

  AiSettings({
    this.enabled = true,
    this.autoSuggestions = true,
    this.suggestionFrequency = SuggestionFrequency.moderate,
    this.preferredModel = 'default',
    this.autoFallback = true,
    this.contextDepth = 5,
    this.responseStyle = ResponseStyle.balanced,
    AiUsageSettings? useFor,
    AiDataUsageSettings? dataUsage,
    this.dailyTokenLimit,
    this.showUsageStats = true,
  }) : useFor = useFor ?? AiUsageSettings(),
        dataUsage = dataUsage ?? AiDataUsageSettings();

  factory AiSettings.fromJson(Map<String, dynamic> json) {
    return AiSettings(
      enabled: _parseBool(json['enabled'], defaultValue: true),
      autoSuggestions: _parseBool(json['auto_suggestions'], defaultValue: true),
      suggestionFrequency: _parseEnum(
        json['suggestion_frequency'],
        SuggestionFrequency.values,
        SuggestionFrequency.moderate,
      ),
      preferredModel: json['preferred_model'] as String? ?? 'default',
      autoFallback: _parseBool(json['auto_fallback'], defaultValue: true),
      contextDepth: json['context_depth'] as int? ?? 5,
      responseStyle: _parseEnum(
        json['response_style'],
        ResponseStyle.values,
        ResponseStyle.balanced,
      ),
      useFor: AiUsageSettings.fromJson(_parseJsonField(json['use_for'])),
      dataUsage: AiDataUsageSettings.fromJson(
        _parseJsonField(json['data_usage']),
      ),
      dailyTokenLimit: json['daily_token_limit'] as int?,
      showUsageStats: _parseBool(json['show_usage_stats'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'auto_suggestions': autoSuggestions,
      'suggestion_frequency': suggestionFrequency.name,
      'preferred_model': preferredModel,
      'auto_fallback': autoFallback,
      'context_depth': contextDepth,
      'response_style': responseStyle.name,
      'use_for': useFor.toJson(),
      'data_usage': dataUsage.toJson(),
      'daily_token_limit': dailyTokenLimit,
      'show_usage_stats': showUsageStats,
    };
  }

  AiSettings copyWith({
    bool? enabled,
    bool? autoSuggestions,
    SuggestionFrequency? suggestionFrequency,
    String? preferredModel,
    bool? autoFallback,
    int? contextDepth,
    ResponseStyle? responseStyle,
    AiUsageSettings? useFor,
    AiDataUsageSettings? dataUsage,
    int? dailyTokenLimit,
    bool? showUsageStats,
  }) {
    return AiSettings(
      enabled: enabled ?? this.enabled,
      autoSuggestions: autoSuggestions ?? this.autoSuggestions,
      suggestionFrequency: suggestionFrequency ?? this.suggestionFrequency,
      preferredModel: preferredModel ?? this.preferredModel,
      autoFallback: autoFallback ?? this.autoFallback,
      contextDepth: contextDepth ?? this.contextDepth,
      responseStyle: responseStyle ?? this.responseStyle,
      useFor: useFor ?? this.useFor,
      dataUsage: dataUsage ?? this.dataUsage,
      dailyTokenLimit: dailyTokenLimit ?? this.dailyTokenLimit,
      showUsageStats: showUsageStats ?? this.showUsageStats,
    );
  }
}

class AiUsageSettings {
  final bool taskSuggestions;
  final bool goalPlanning;
  final bool diaryPrompts;
  final bool productivityInsights;
  final bool writingAssistance;
  final bool mediaVerification;

  AiUsageSettings({
    this.taskSuggestions = true,
    this.goalPlanning = true,
    this.diaryPrompts = true,
    this.productivityInsights = true,
    this.writingAssistance = true,
    this.mediaVerification = true,
  });

  factory AiUsageSettings.fromJson(Map<String, dynamic> json) {
    return AiUsageSettings(
      taskSuggestions: _parseBool(json['task_suggestions'], defaultValue: true),
      goalPlanning: _parseBool(json['goal_planning'], defaultValue: true),
      diaryPrompts: _parseBool(json['diary_prompts'], defaultValue: true),
      productivityInsights: _parseBool(
        json['productivity_insights'],
        defaultValue: true,
      ),
      writingAssistance: _parseBool(
        json['writing_assistance'],
        defaultValue: true,
      ),
      mediaVerification: _parseBool(
        json['media_verification'],
        defaultValue: true,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_suggestions': taskSuggestions,
      'goal_planning': goalPlanning,
      'diary_prompts': diaryPrompts,
      'productivity_insights': productivityInsights,
      'writing_assistance': writingAssistance,
      'media_verification': mediaVerification,
    };
  }

  AiUsageSettings copyWith({
    bool? taskSuggestions,
    bool? goalPlanning,
    bool? diaryPrompts,
    bool? productivityInsights,
    bool? writingAssistance,
    bool? mediaVerification,
  }) {
    return AiUsageSettings(
      taskSuggestions: taskSuggestions ?? this.taskSuggestions,
      goalPlanning: goalPlanning ?? this.goalPlanning,
      diaryPrompts: diaryPrompts ?? this.diaryPrompts,
      productivityInsights: productivityInsights ?? this.productivityInsights,
      writingAssistance: writingAssistance ?? this.writingAssistance,
      mediaVerification: mediaVerification ?? this.mediaVerification,
    );
  }
}

class AiDataUsageSettings {
  final bool learnFromHistory;
  final bool personalizedSuggestions;

  AiDataUsageSettings({
    this.learnFromHistory = true,
    this.personalizedSuggestions = true,
  });

  factory AiDataUsageSettings.fromJson(Map<String, dynamic> json) {
    return AiDataUsageSettings(
      learnFromHistory: _parseBool(
        json['learn_from_history'],
        defaultValue: true,
      ),
      personalizedSuggestions: _parseBool(
        json['personalized_suggestions'],
        defaultValue: true,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'learn_from_history': learnFromHistory,
      'personalized_suggestions': personalizedSuggestions,
    };
  }

  AiDataUsageSettings copyWith({
    bool? learnFromHistory,
    bool? personalizedSuggestions,
  }) {
    return AiDataUsageSettings(
      learnFromHistory: learnFromHistory ?? this.learnFromHistory,
      personalizedSuggestions:
      personalizedSuggestions ?? this.personalizedSuggestions,
    );
  }
}

// ============================================================
// 🏆 COMPETITION SETTINGS
// ============================================================

class CompetitionSettings {
  final bool allowChallenges;
  final bool autoAcceptFromFriends;
  final bool showOnLeaderboard;
  final bool shareStats;
  final CompetitionNotifications notifications;

  CompetitionSettings({
    this.allowChallenges = true,
    this.autoAcceptFromFriends = false,
    this.showOnLeaderboard = true,
    this.shareStats = true,
    CompetitionNotifications? notifications,
  }) : notifications = notifications ?? CompetitionNotifications();

  factory CompetitionSettings.fromJson(Map<String, dynamic> json) {
    return CompetitionSettings(
      allowChallenges: _parseBool(json['allow_challenges'], defaultValue: true),
      autoAcceptFromFriends: _parseBool(json['auto_accept_from_friends']),
      showOnLeaderboard: _parseBool(
        json['show_on_leaderboard'],
        defaultValue: true,
      ),
      shareStats: _parseBool(json['share_stats'], defaultValue: true),
      notifications: CompetitionNotifications.fromJson(
        _parseJsonField(json['notifications']),
      ),
    );
  }

  // ============================================================
  // 🏆 COMPETITION SETTINGS (Continued)
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'allow_challenges': allowChallenges,
      'auto_accept_from_friends': autoAcceptFromFriends,
      'show_on_leaderboard': showOnLeaderboard,
      'share_stats': shareStats,
      'notifications': notifications.toJson(),
    };
  }

  CompetitionSettings copyWith({
    bool? allowChallenges,
    bool? autoAcceptFromFriends,
    bool? showOnLeaderboard,
    bool? shareStats,
    CompetitionNotifications? notifications,
  }) {
    return CompetitionSettings(
      allowChallenges: allowChallenges ?? this.allowChallenges,
      autoAcceptFromFriends:
      autoAcceptFromFriends ?? this.autoAcceptFromFriends,
      showOnLeaderboard: showOnLeaderboard ?? this.showOnLeaderboard,
      shareStats: shareStats ?? this.shareStats,
      notifications: notifications ?? this.notifications,
    );
  }
}

class CompetitionNotifications {
  final bool challengeReceived;
  final bool challengeUpdates;
  final bool leaderboardChanges;

  CompetitionNotifications({
    this.challengeReceived = true,
    this.challengeUpdates = true,
    this.leaderboardChanges = true,
  });

  factory CompetitionNotifications.fromJson(Map<String, dynamic> json) {
    return CompetitionNotifications(
      challengeReceived: _parseBool(
        json['challenge_received'],
        defaultValue: true,
      ),
      challengeUpdates: _parseBool(
        json['challenge_updates'],
        defaultValue: true,
      ),
      leaderboardChanges: _parseBool(
        json['leaderboard_changes'],
        defaultValue: true,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'challenge_received': challengeReceived,
      'challenge_updates': challengeUpdates,
      'leaderboard_changes': leaderboardChanges,
    };
  }

  CompetitionNotifications copyWith({
    bool? challengeReceived,
    bool? challengeUpdates,
    bool? leaderboardChanges,
  }) {
    return CompetitionNotifications(
      challengeReceived: challengeReceived ?? this.challengeReceived,
      challengeUpdates: challengeUpdates ?? this.challengeUpdates,
      leaderboardChanges: leaderboardChanges ?? this.leaderboardChanges,
    );
  }
}

// ============================================================
// 🔐 SECURITY SETTINGS
// ============================================================

class SecuritySettings {
  final bool biometricLock;
  final bool appLockEnabled;
  final int appLockTimeout;
  final RequireAuthFor requireAuthFor;
  final bool twoFactorEnabled;
  final List<TrustedDevice> trustedDevices;
  final bool loginAlerts;
  final int? sessionTimeout;
  final bool autoLogout;

  SecuritySettings({
    this.biometricLock = false,
    this.appLockEnabled = false,
    this.appLockTimeout = 0,
    RequireAuthFor? requireAuthFor,
    this.twoFactorEnabled = false,
    this.trustedDevices = const [],
    this.loginAlerts = true,
    this.sessionTimeout,
    this.autoLogout = false,
  }) : requireAuthFor = requireAuthFor ?? RequireAuthFor();

  factory SecuritySettings.fromJson(Map<String, dynamic> json) {
    return SecuritySettings(
      biometricLock: _parseBool(json['biometric_lock']),
      appLockEnabled: _parseBool(json['app_lock_enabled']),
      appLockTimeout: json['app_lock_timeout'] as int? ?? 0,
      requireAuthFor: RequireAuthFor.fromJson(
        _parseJsonField(json['require_auth_for']),
      ),
      twoFactorEnabled: _parseBool(json['two_factor_enabled']),
      trustedDevices:
      (json['trusted_devices'] as List<dynamic>?)
          ?.map((e) => TrustedDevice.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      loginAlerts: _parseBool(json['login_alerts'], defaultValue: true),
      sessionTimeout: json['session_timeout'] as int?,
      autoLogout: _parseBool(json['auto_logout']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'biometric_lock': biometricLock,
      'app_lock_enabled': appLockEnabled,
      'app_lock_timeout': appLockTimeout,
      'require_auth_for': requireAuthFor.toJson(),
      'two_factor_enabled': twoFactorEnabled,
      'trusted_devices': trustedDevices.map((e) => e.toJson()).toList(),
      'login_alerts': loginAlerts,
      'session_timeout': sessionTimeout,
      'auto_logout': autoLogout,
    };
  }

  SecuritySettings copyWith({
    bool? biometricLock,
    bool? appLockEnabled,
    int? appLockTimeout,
    RequireAuthFor? requireAuthFor,
    bool? twoFactorEnabled,
    List<TrustedDevice>? trustedDevices,
    bool? loginAlerts,
    int? sessionTimeout,
    bool? autoLogout,
  }) {
    return SecuritySettings(
      biometricLock: biometricLock ?? this.biometricLock,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      appLockTimeout: appLockTimeout ?? this.appLockTimeout,
      requireAuthFor: requireAuthFor ?? this.requireAuthFor,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      trustedDevices: trustedDevices ?? this.trustedDevices,
      loginAlerts: loginAlerts ?? this.loginAlerts,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      autoLogout: autoLogout ?? this.autoLogout,
    );
  }
}

class RequireAuthFor {
  final bool diary;
  final bool chat;
  final bool settings;
  final bool export;

  RequireAuthFor({
    this.diary = false,
    this.chat = false,
    this.settings = false,
    this.export = true,
  });

  factory RequireAuthFor.fromJson(Map<String, dynamic> json) {
    return RequireAuthFor(
      diary: _parseBool(json['diary']),
      chat: _parseBool(json['chat']),
      settings: _parseBool(json['settings']),
      export: _parseBool(json['export'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diary': diary,
      'chat': chat,
      'settings': settings,
      'export': export,
    };
  }

  RequireAuthFor copyWith({
    bool? diary,
    bool? chat,
    bool? settings,
    bool? export,
  }) {
    return RequireAuthFor(
      diary: diary ?? this.diary,
      chat: chat ?? this.chat,
      settings: settings ?? this.settings,
      export: export ?? this.export,
    );
  }
}

class TrustedDevice {
  final String id;
  final String name;
  final String platform;
  final DateTime addedAt;
  final DateTime? lastUsedAt;

  TrustedDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.addedAt,
    this.lastUsedAt,
  });

  factory TrustedDevice.fromJson(Map<String, dynamic> json) {
    return TrustedDevice(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      addedAt: _parseDate(json['added_at']) ?? DateTime.now(),
      lastUsedAt: _parseDate(json['last_used_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'platform': platform,
      'added_at': addedAt.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
    };
  }

  TrustedDevice copyWith({
    String? id,
    String? name,
    String? platform,
    DateTime? addedAt,
    DateTime? lastUsedAt,
  }) {
    return TrustedDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      addedAt: addedAt ?? this.addedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}

// ============================================================
// 💾 DATA STORAGE SETTINGS
// ============================================================

class DataStorageSettings {
  final bool autoSync;
  final bool syncOnWifiOnly;
  final bool offlineMode;
  final int cacheSizeLimit;
  final bool autoClearCache;
  final int clearCacheAfterDays;
  final BackupSettings backup;
  final ExportFormat exportFormat;

  DataStorageSettings({
    this.autoSync = true,
    this.syncOnWifiOnly = false,
    this.offlineMode = true,
    this.cacheSizeLimit = 500,
    this.autoClearCache = true,
    this.clearCacheAfterDays = 30,
    BackupSettings? backup,
    this.exportFormat = ExportFormat.json,
  }) : backup = backup ?? BackupSettings();

  factory DataStorageSettings.fromJson(Map<String, dynamic> json) {
    return DataStorageSettings(
      autoSync: _parseBool(json['auto_sync'], defaultValue: true),
      syncOnWifiOnly: _parseBool(json['sync_on_wifi_only']),
      offlineMode: _parseBool(json['offline_mode'], defaultValue: true),
      cacheSizeLimit: json['cache_size_limit'] as int? ?? 500,
      autoClearCache: _parseBool(json['auto_clear_cache'], defaultValue: true),
      clearCacheAfterDays: json['clear_cache_after_days'] as int? ?? 30,
      backup: BackupSettings.fromJson(_parseJsonField(json['backup'])),
      exportFormat: _parseEnum(
        json['export_format'],
        ExportFormat.values,
        ExportFormat.json,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auto_sync': autoSync,
      'sync_on_wifi_only': syncOnWifiOnly,
      'offline_mode': offlineMode,
      'cache_size_limit': cacheSizeLimit,
      'auto_clear_cache': autoClearCache,
      'clear_cache_after_days': clearCacheAfterDays,
      'backup': backup.toJson(),
      'export_format': exportFormat.name,
    };
  }

  DataStorageSettings copyWith({
    bool? autoSync,
    bool? syncOnWifiOnly,
    bool? offlineMode,
    int? cacheSizeLimit,
    bool? autoClearCache,
    int? clearCacheAfterDays,
    BackupSettings? backup,
    ExportFormat? exportFormat,
  }) {
    return DataStorageSettings(
      autoSync: autoSync ?? this.autoSync,
      syncOnWifiOnly: syncOnWifiOnly ?? this.syncOnWifiOnly,
      offlineMode: offlineMode ?? this.offlineMode,
      cacheSizeLimit: cacheSizeLimit ?? this.cacheSizeLimit,
      autoClearCache: autoClearCache ?? this.autoClearCache,
      clearCacheAfterDays: clearCacheAfterDays ?? this.clearCacheAfterDays,
      backup: backup ?? this.backup,
      exportFormat: exportFormat ?? this.exportFormat,
    );
  }
}

class BackupSettings {
  final bool enabled;
  final String frequency;
  final bool includeMedia;
  final CloudProvider? cloudProvider;

  BackupSettings({
    this.enabled = false,
    this.frequency = 'weekly',
    this.includeMedia = true,
    this.cloudProvider,
  });

  factory BackupSettings.fromJson(Map<String, dynamic> json) {
    return BackupSettings(
      enabled: _parseBool(json['enabled']),
      frequency: json['frequency'] as String? ?? 'weekly',
      includeMedia: _parseBool(json['include_media'], defaultValue: true),
      cloudProvider: json['cloud_provider'] != null
          ? _parseEnum(
        json['cloud_provider'],
        CloudProvider.values,
        CloudProvider.googleDrive,
      )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'frequency': frequency,
      'include_media': includeMedia,
      'cloud_provider': cloudProvider?.name,
    };
  }

  BackupSettings copyWith({
    bool? enabled,
    String? frequency,
    bool? includeMedia,
    CloudProvider? cloudProvider,
  }) {
    return BackupSettings(
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      includeMedia: includeMedia ?? this.includeMedia,
      cloudProvider: cloudProvider ?? this.cloudProvider,
    );
  }
}

// ============================================================
// 🌍 LOCALIZATION SETTINGS
// ============================================================

class LocalizationSettings {
  final String language;
  final String? region;
  final String timezone;
  final String dateFormat;
  final TimeFormat timeFormat;
  final WeekDay firstDayOfWeek;
  final String currency;
  final MeasurementUnit measurementUnit;

  LocalizationSettings({
    this.language = 'en',
    this.region,
    this.timezone = 'auto',
    this.dateFormat = 'auto',
    this.timeFormat = TimeFormat.h12,
    this.firstDayOfWeek = WeekDay.monday,
    this.currency = 'USD',
    this.measurementUnit = MeasurementUnit.metric,
  });

  factory LocalizationSettings.fromJson(Map<String, dynamic> json) {
    return LocalizationSettings(
      language: json['language'] as String? ?? 'en',
      region: json['region'] as String?,
      timezone: json['timezone'] as String? ?? 'auto',
      dateFormat: json['date_format'] as String? ?? 'auto',
      timeFormat: _parseEnum(
        json['time_format'],
        TimeFormat.values,
        TimeFormat.h12,
      ),
      firstDayOfWeek: _parseEnum(
        json['first_day_of_week'],
        WeekDay.values,
        WeekDay.monday,
      ),
      currency: json['currency'] as String? ?? 'USD',
      measurementUnit: _parseEnum(
        json['measurement_unit'],
        MeasurementUnit.values,
        MeasurementUnit.metric,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'region': region,
      'timezone': timezone,
      'date_format': dateFormat,
      'time_format': timeFormat.name,
      'first_day_of_week': firstDayOfWeek.name,
      'currency': currency,
      'measurement_unit': measurementUnit.name,
    };
  }

  LocalizationSettings copyWith({
    String? language,
    String? region,
    String? timezone,
    String? dateFormat,
    TimeFormat? timeFormat,
    WeekDay? firstDayOfWeek,
    String? currency,
    MeasurementUnit? measurementUnit,
  }) {
    return LocalizationSettings(
      language: language ?? this.language,
      region: region ?? this.region,
      timezone: timezone ?? this.timezone,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      currency: currency ?? this.currency,
      measurementUnit: measurementUnit ?? this.measurementUnit,
    );
  }
}

// ============================================================
// ♿ ACCESSIBILITY SETTINGS
// ============================================================

class AccessibilitySettings {
  final bool screenReaderOptimized;
  final bool reduceMotion;
  final bool increaseContrast;
  final bool largerText;
  final bool boldText;
  final bool reduceTransparency;
  final bool hapticFeedback;
  final bool audioDescriptions;
  final bool closedCaptions;
  final bool monoAudio;
  final bool shakeToUndo;

  AccessibilitySettings({
    this.screenReaderOptimized = false,
    this.reduceMotion = false,
    this.increaseContrast = false,
    this.largerText = false,
    this.boldText = false,
    this.reduceTransparency = false,
    this.hapticFeedback = true,
    this.audioDescriptions = false,
    this.closedCaptions = true,
    this.monoAudio = false,
    this.shakeToUndo = true,
  });

  factory AccessibilitySettings.fromJson(Map<String, dynamic> json) {
    return AccessibilitySettings(
      screenReaderOptimized: _parseBool(json['screen_reader_optimized']),
      reduceMotion: _parseBool(json['reduce_motion']),
      increaseContrast: _parseBool(json['increase_contrast']),
      largerText: _parseBool(json['larger_text']),
      boldText: _parseBool(json['bold_text']),
      reduceTransparency: _parseBool(json['reduce_transparency']),
      hapticFeedback: _parseBool(json['haptic_feedback'], defaultValue: true),
      audioDescriptions: _parseBool(json['audio_descriptions']),
      closedCaptions: _parseBool(json['closed_captions'], defaultValue: true),
      monoAudio: _parseBool(json['mono_audio']),
      shakeToUndo: _parseBool(json['shake_to_undo'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'screen_reader_optimized': screenReaderOptimized,
      'reduce_motion': reduceMotion,
      'increase_contrast': increaseContrast,
      'larger_text': largerText,
      'bold_text': boldText,
      'reduce_transparency': reduceTransparency,
      'haptic_feedback': hapticFeedback,
      'audio_descriptions': audioDescriptions,
      'closed_captions': closedCaptions,
      'mono_audio': monoAudio,
      'shake_to_undo': shakeToUndo,
    };
  }

  AccessibilitySettings copyWith({
    bool? screenReaderOptimized,
    bool? reduceMotion,
    bool? increaseContrast,
    bool? largerText,
    bool? boldText,
    bool? reduceTransparency,
    bool? hapticFeedback,
    bool? audioDescriptions,
    bool? closedCaptions,
    bool? monoAudio,
    bool? shakeToUndo,
  }) {
    return AccessibilitySettings(
      screenReaderOptimized:
      screenReaderOptimized ?? this.screenReaderOptimized,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      increaseContrast: increaseContrast ?? this.increaseContrast,
      largerText: largerText ?? this.largerText,
      boldText: boldText ?? this.boldText,
      reduceTransparency: reduceTransparency ?? this.reduceTransparency,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      audioDescriptions: audioDescriptions ?? this.audioDescriptions,
      closedCaptions: closedCaptions ?? this.closedCaptions,
      monoAudio: monoAudio ?? this.monoAudio,
      shakeToUndo: shakeToUndo ?? this.shakeToUndo,
    );
  }
}

// ============================================================
// 🧪 EXPERIMENTAL SETTINGS
// ============================================================

class ExperimentalSettings {
  final bool betaFeatures;
  final bool earlyAccess;
  final bool developerMode;
  final bool debugLogging;
  final Map<String, bool> features;

  ExperimentalSettings({
    this.betaFeatures = false,
    this.earlyAccess = false,
    this.developerMode = false,
    this.debugLogging = false,
    this.features = const {},
  });

  bool isFeatureEnabled(String feature) => features[feature] ?? false;

  factory ExperimentalSettings.fromJson(Map<String, dynamic> json) {
    return ExperimentalSettings(
      betaFeatures: _parseBool(json['beta_features']),
      earlyAccess: _parseBool(json['early_access']),
      developerMode: _parseBool(json['developer_mode']),
      debugLogging: _parseBool(json['debug_logging']),
      features: Map<String, bool>.from(json['features'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'beta_features': betaFeatures,
      'early_access': earlyAccess,
      'developer_mode': developerMode,
      'debug_logging': debugLogging,
      'features': features,
    };
  }

  ExperimentalSettings copyWith({
    bool? betaFeatures,
    bool? earlyAccess,
    bool? developerMode,
    bool? debugLogging,
    Map<String, bool>? features,
  }) {
    return ExperimentalSettings(
      betaFeatures: betaFeatures ?? this.betaFeatures,
      earlyAccess: earlyAccess ?? this.earlyAccess,
      developerMode: developerMode ?? this.developerMode,
      debugLogging: debugLogging ?? this.debugLogging,
      features: features ?? this.features,
    );
  }
}

// ============================================================
// 📊 WIDGET SETTINGS
// ============================================================

class WidgetSettings {
  final List<HomeWidget> homeWidgets;
  final List<QuickAction> quickActions;
  final DashboardLayout dashboardLayout;

  WidgetSettings({
    List<HomeWidget>? homeWidgets,
    this.quickActions = const [
      QuickAction.addTask,
      QuickAction.addDiary,
      QuickAction.startTimer,
      QuickAction.voiceNote,
    ],
    this.dashboardLayout = DashboardLayout.defaultLayout,
  }) : homeWidgets = homeWidgets ?? _defaultHomeWidgets();

  static List<HomeWidget> _defaultHomeWidgets() {
    return [
      HomeWidget(type: 'today_tasks', size: WidgetSize.medium, position: 0),
      HomeWidget(type: 'active_goals', size: WidgetSize.small, position: 1),
      HomeWidget(type: 'streak', size: WidgetSize.small, position: 2),
    ];
  }

  factory WidgetSettings.fromJson(Map<String, dynamic> json) {
    return WidgetSettings(
      homeWidgets:
      (json['home_widgets'] as List<dynamic>?)
          ?.map((e) => HomeWidget.fromJson(e as Map<String, dynamic>))
          .toList() ??
          _defaultHomeWidgets(),
      quickActions:
      (json['quick_actions'] as List<dynamic>?)
          ?.map(
            (e) => _parseEnum(e, QuickAction.values, QuickAction.addTask),
      )
          .toList() ??
          [
            QuickAction.addTask,
            QuickAction.addDiary,
            QuickAction.startTimer,
            QuickAction.voiceNote,
          ],
      dashboardLayout: _parseEnum(
        json['dashboard_layout'],
        DashboardLayout.values,
        DashboardLayout.defaultLayout,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'home_widgets': homeWidgets.map((e) => e.toJson()).toList(),
      'quick_actions': quickActions.map((e) => e.name).toList(),
      'dashboard_layout': dashboardLayout.name,
    };
  }

  WidgetSettings copyWith({
    List<HomeWidget>? homeWidgets,
    List<QuickAction>? quickActions,
    DashboardLayout? dashboardLayout,
  }) {
    return WidgetSettings(
      homeWidgets: homeWidgets ?? this.homeWidgets,
      quickActions: quickActions ?? this.quickActions,
      dashboardLayout: dashboardLayout ?? this.dashboardLayout,
    );
  }
}

class HomeWidget {
  final String type;
  final WidgetSize size;
  final int position;
  final Map<String, dynamic> config;

  HomeWidget({
    required this.type,
    this.size = WidgetSize.medium,
    this.position = 0,
    this.config = const {},
  });

  factory HomeWidget.fromJson(Map<String, dynamic> json) {
    return HomeWidget(
      type: json['type'] as String? ?? '',
      size: _parseEnum(json['size'], WidgetSize.values, WidgetSize.medium),
      position: json['position'] as int? ?? 0,
      config: Map<String, dynamic>.from(json['config'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'size': size.name,
      'position': position,
      'config': config,
    };
  }

  HomeWidget copyWith({
    String? type,
    WidgetSize? size,
    int? position,
    Map<String, dynamic>? config,
  }) {
    return HomeWidget(
      type: type ?? this.type,
      size: size ?? this.size,
      position: position ?? this.position,
      config: config ?? this.config,
    );
  }
}

// ============================================================
// 📈 ANALYTICS SETTINGS
// ============================================================

class AnalyticsSettings {
  final bool weeklyReport;
  final WeekDay weeklyReportDay;
  final bool monthlyInsights;
  final bool productivityTracking;
  final bool moodAnalytics;
  final bool goalAnalytics;
  final bool shareAnonymousData;

  AnalyticsSettings({
    this.weeklyReport = true,
    this.weeklyReportDay = WeekDay.sunday,
    this.monthlyInsights = true,
    this.productivityTracking = true,
    this.moodAnalytics = true,
    this.goalAnalytics = true,
    this.shareAnonymousData = false,
  });

  factory AnalyticsSettings.fromJson(Map<String, dynamic> json) {
    return AnalyticsSettings(
      weeklyReport: _parseBool(json['weekly_report'], defaultValue: true),
      weeklyReportDay: _parseEnum(
        json['weekly_report_day'],
        WeekDay.values,
        WeekDay.sunday,
      ),
      monthlyInsights: _parseBool(json['monthly_insights'], defaultValue: true),
      productivityTracking: _parseBool(
        json['productivity_tracking'],
        defaultValue: true,
      ),
      moodAnalytics: _parseBool(json['mood_analytics'], defaultValue: true),
      goalAnalytics: _parseBool(json['goal_analytics'], defaultValue: true),
      shareAnonymousData: _parseBool(json['share_anonymous_data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekly_report': weeklyReport,
      'weekly_report_day': weeklyReportDay.name,
      'monthly_insights': monthlyInsights,
      'productivity_tracking': productivityTracking,
      'mood_analytics': moodAnalytics,
      'goal_analytics': goalAnalytics,
      'share_anonymous_data': shareAnonymousData,
    };
  }

  AnalyticsSettings copyWith({
    bool? weeklyReport,
    WeekDay? weeklyReportDay,
    bool? monthlyInsights,
    bool? productivityTracking,
    bool? moodAnalytics,
    bool? goalAnalytics,
    bool? shareAnonymousData,
  }) {
    return AnalyticsSettings(
      weeklyReport: weeklyReport ?? this.weeklyReport,
      weeklyReportDay: weeklyReportDay ?? this.weeklyReportDay,
      monthlyInsights: monthlyInsights ?? this.monthlyInsights,
      productivityTracking: productivityTracking ?? this.productivityTracking,
      moodAnalytics: moodAnalytics ?? this.moodAnalytics,
      goalAnalytics: goalAnalytics ?? this.goalAnalytics,
      shareAnonymousData: shareAnonymousData ?? this.shareAnonymousData,
    );
  }
}

// ============================================================
// 🔌 INTEGRATION SETTINGS
// ============================================================

class IntegrationSettings {
  final CalendarIntegration calendar;
  final HealthIntegration health;
  final CloudStorageIntegration cloudStorage;
  final Map<String, SocialAccountIntegration> socialAccounts;
  final List<WebhookIntegration> webhooks;

  IntegrationSettings({
    CalendarIntegration? calendar,
    HealthIntegration? health,
    CloudStorageIntegration? cloudStorage,
    this.socialAccounts = const {},
    this.webhooks = const [],
  }) : calendar = calendar ?? CalendarIntegration(),
        health = health ?? HealthIntegration(),
        cloudStorage = cloudStorage ?? CloudStorageIntegration();

  factory IntegrationSettings.fromJson(Map<String, dynamic> json) {
    return IntegrationSettings(
      calendar: CalendarIntegration.fromJson(_parseJsonField(json['calendar'])),
      health: HealthIntegration.fromJson(_parseJsonField(json['health'])),
      cloudStorage: CloudStorageIntegration.fromJson(
        _parseJsonField(json['cloud_storage']),
      ),
      socialAccounts:
      (json['social_accounts'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
          key,
          SocialAccountIntegration.fromJson(value as Map<String, dynamic>),
        ),
      ) ??
          {},
      webhooks:
      (json['webhooks'] as List<dynamic>?)
          ?.map(
            (e) => WebhookIntegration.fromJson(e as Map<String, dynamic>),
      )
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calendar': calendar.toJson(),
      'health': health.toJson(),
      'cloud_storage': cloudStorage.toJson(),
      'social_accounts': socialAccounts.map(
            (key, value) => MapEntry(key, value.toJson()),
      ),
      'webhooks': webhooks.map((e) => e.toJson()).toList(),
    };
  }

  IntegrationSettings copyWith({
    CalendarIntegration? calendar,
    HealthIntegration? health,
    CloudStorageIntegration? cloudStorage,
    Map<String, SocialAccountIntegration>? socialAccounts,
    List<WebhookIntegration>? webhooks,
  }) {
    return IntegrationSettings(
      calendar: calendar ?? this.calendar,
      health: health ?? this.health,
      cloudStorage: cloudStorage ?? this.cloudStorage,
      socialAccounts: socialAccounts ?? this.socialAccounts,
      webhooks: webhooks ?? this.webhooks,
    );
  }
}

class CalendarIntegration {
  final bool enabled;
  final CalendarProvider? provider;
  final bool syncTasks;
  final bool syncGoals;
  final bool syncEvents;
  final String? calendarId;

  CalendarIntegration({
    this.enabled = false,
    this.provider,
    this.syncTasks = false,
    this.syncGoals = false,
    this.syncEvents = false,
    this.calendarId,
  });

  factory CalendarIntegration.fromJson(Map<String, dynamic> json) {
    return CalendarIntegration(
      enabled: _parseBool(json['enabled']),
      provider: json['provider'] != null
          ? _parseEnum(
        json['provider'],
        CalendarProvider.values,
        CalendarProvider.google,
      )
          : null,
      syncTasks: _parseBool(json['sync_tasks']),
      syncGoals: _parseBool(json['sync_goals']),
      syncEvents: _parseBool(json['sync_events']),
      calendarId: json['calendar_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'provider': provider?.name,
      'sync_tasks': syncTasks,
      'sync_goals': syncGoals,
      'sync_events': syncEvents,
      'calendar_id': calendarId,
    };
  }

  CalendarIntegration copyWith({
    bool? enabled,
    CalendarProvider? provider,
    bool? syncTasks,
    bool? syncGoals,
    bool? syncEvents,
    String? calendarId,
  }) {
    return CalendarIntegration(
      enabled: enabled ?? this.enabled,
      provider: provider ?? this.provider,
      syncTasks: syncTasks ?? this.syncTasks,
      syncGoals: syncGoals ?? this.syncGoals,
      syncEvents: syncEvents ?? this.syncEvents,
      calendarId: calendarId ?? this.calendarId,
    );
  }
}

class HealthIntegration {
  final bool enabled;
  final HealthProvider? provider;
  final bool syncActivities;
  final bool syncSleep;
  final bool syncHeartRate;
  final bool syncSteps;

  HealthIntegration({
    this.enabled = false,
    this.provider,
    this.syncActivities = false,
    this.syncSleep = false,
    this.syncHeartRate = false,
    this.syncSteps = false,
  });

  factory HealthIntegration.fromJson(Map<String, dynamic> json) {
    return HealthIntegration(
      enabled: _parseBool(json['enabled']),
      provider: json['provider'] != null
          ? _parseEnum(
        json['provider'],
        HealthProvider.values,
        HealthProvider.googleFit,
      )
          : null,
      syncActivities: _parseBool(json['sync_activities']),
      syncSleep: _parseBool(json['sync_sleep']),
      syncHeartRate: _parseBool(json['sync_heart_rate']),
      syncSteps: _parseBool(json['sync_steps']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'provider': provider?.name,
      'sync_activities': syncActivities,
      'sync_sleep': syncSleep,
      'sync_heart_rate': syncHeartRate,
      'sync_steps': syncSteps,
    };
  }

  HealthIntegration copyWith({
    bool? enabled,
    HealthProvider? provider,
    bool? syncActivities,
    bool? syncSleep,
    bool? syncHeartRate,
    bool? syncSteps,
  }) {
    return HealthIntegration(
      enabled: enabled ?? this.enabled,
      provider: provider ?? this.provider,
      syncActivities: syncActivities ?? this.syncActivities,
      syncSleep: syncSleep ?? this.syncSleep,
      syncHeartRate: syncHeartRate ?? this.syncHeartRate,
      syncSteps: syncSteps ?? this.syncSteps,
    );
  }
}

class CloudStorageIntegration {
  final bool enabled;
  final CloudProvider? provider;
  final bool autoBackup;
  final String? folderPath;

  CloudStorageIntegration({
    this.enabled = false,
    this.provider,
    this.autoBackup = false,
    this.folderPath,
  });

  factory CloudStorageIntegration.fromJson(Map<String, dynamic> json) {
    return CloudStorageIntegration(
      enabled: _parseBool(json['enabled']),
      provider: json['provider'] != null
          ? _parseEnum(
        json['provider'],
        CloudProvider.values,
        CloudProvider.googleDrive,
      )
          : null,
      autoBackup: _parseBool(json['auto_backup']),
      folderPath: json['folder_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'provider': provider?.name,
      'auto_backup': autoBackup,
      'folder_path': folderPath,
    };
  }

  CloudStorageIntegration copyWith({
    bool? enabled,
    CloudProvider? provider,
    bool? autoBackup,
    String? folderPath,
  }) {
    return CloudStorageIntegration(
      enabled: enabled ?? this.enabled,
      provider: provider ?? this.provider,
      autoBackup: autoBackup ?? this.autoBackup,
      folderPath: folderPath ?? this.folderPath,
    );
  }
}

class SocialAccountIntegration {
  final String platform;
  final String accountId;
  final String accountName;
  final DateTime connectedAt;
  final bool isActive;
  final Map<String, dynamic> permissions;

  SocialAccountIntegration({
    required this.platform,
    required this.accountId,
    required this.accountName,
    required this.connectedAt,
    this.isActive = true,
    this.permissions = const {},
  });

  factory SocialAccountIntegration.fromJson(Map<String, dynamic> json) {
    return SocialAccountIntegration(
      platform: json['platform'] as String? ?? '',
      accountId: json['account_id'] as String? ?? '',
      accountName: json['account_name'] as String? ?? '',
      connectedAt: _parseDate(json['connected_at']) ?? DateTime.now(),
      isActive: _parseBool(json['is_active'], defaultValue: true),
      permissions: Map<String, dynamic>.from(json['permissions'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'account_id': accountId,
      'account_name': accountName,
      'connected_at': connectedAt.toIso8601String(),
      'is_active': isActive,
      'permissions': permissions,
    };
  }

  SocialAccountIntegration copyWith({
    String? platform,
    String? accountId,
    String? accountName,
    DateTime? connectedAt,
    bool? isActive,
    Map<String, dynamic>? permissions,
  }) {
    return SocialAccountIntegration(
      platform: platform ?? this.platform,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      connectedAt: connectedAt ?? this.connectedAt,
      isActive: isActive ?? this.isActive,
      permissions: permissions ?? this.permissions,
    );
  }
}

class WebhookIntegration {
  final String id;
  final String name;
  final String url;
  final List<String> events;
  final bool isActive;
  final String? secret;
  final DateTime? lastTriggeredAt;

  WebhookIntegration({
    required this.id,
    required this.name,
    required this.url,
    required this.events,
    this.isActive = true,
    this.secret,
    this.lastTriggeredAt,
  });

  factory WebhookIntegration.fromJson(Map<String, dynamic> json) {
    return WebhookIntegration(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      events: List<String>.from(json['events'] ?? []),
      isActive: _parseBool(json['is_active'], defaultValue: true),
      secret: json['secret'] as String?,
      lastTriggeredAt: _parseDate(json['last_triggered_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'events': events,
      'is_active': isActive,
      'secret': secret,
      'last_triggered_at': lastTriggeredAt?.toIso8601String(),
    };
  }

  WebhookIntegration copyWith({
    String? id,
    String? name,
    String? url,
    List<String>? events,
    bool? isActive,
    String? secret,
    DateTime? lastTriggeredAt,
  }) {
    return WebhookIntegration(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      events: events ?? this.events,
      isActive: isActive ?? this.isActive,
      secret: secret ?? this.secret,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
    );
  }
}

// ============================================================
// 🛠️ HELPER FUNCTIONS (Global)
// ============================================================

/// Parse JSON field that might come as String or Map
Map<String, dynamic> _parseJsonField(dynamic field) {
  if (field == null) return {};
  if (field is Map<String, dynamic>) return field;
  if (field is String) {
    try {
      return jsonDecode(field) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
  return {};
}

/// Parse boolean that might come as int (0/1), String, or bool
bool _parseBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }
  return defaultValue;
}

/// Parse DateTime safely
DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}

/// Parse enum from string
T _parseEnum<T extends Enum>(dynamic value, List<T> values, T defaultValue) {
  if (value == null) return defaultValue;
  if (value is T) return value;
  if (value is String) {
    try {
      return values.firstWhere(
            (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => defaultValue,
      );
    } catch (_) {
      return defaultValue;
    }
  }
  return defaultValue;
}

/// Parse list that might come as raw List or { "items": [...] }
List<dynamic> _parseJsonbListRaw(dynamic v) {
  if (v == null) return [];
  if (v is Map && v.containsKey('items')) return (v['items'] as List);
  if (v is List) return v;
  if (v is String && v.isNotEmpty) {
    try {
      final d = jsonDecode(v);
      if (d is Map && d.containsKey('items')) return (d['items'] as List);
      if (d is List) return d;
    } catch (_) {}
  }
  return [];
}

enum RelationshipType {
  teacherStudent,
  parentChild,
  bossEmployee,
  coachAthlete,
  accountabilityPartner,
  custom;

  String get value {
    switch (this) {
      case RelationshipType.teacherStudent:
        return 'teacher_student';
      case RelationshipType.parentChild:
        return 'parent_child';
      case RelationshipType.bossEmployee:
        return 'boss_employee';
      case RelationshipType.coachAthlete:
        return 'coach_athlete';
      case RelationshipType.accountabilityPartner:
        return 'accountability_partner';
      case RelationshipType.custom:
        return 'custom';
    }
  }

  static RelationshipType fromString(String? value) {
    switch (value) {
      case 'teacher_student':
        return RelationshipType.teacherStudent;
      case 'parent_child':
        return RelationshipType.parentChild;
      case 'boss_employee':
        return RelationshipType.bossEmployee;
      case 'coach_athlete':
        return RelationshipType.coachAthlete;
      case 'accountability_partner':
        return RelationshipType.accountabilityPartner;
      case 'custom':
        return RelationshipType.custom;
      default:
        return RelationshipType.custom;
    }
  }
}

class MentorshipPermissions {
  final bool showPoints;
  final bool showStreak;
  final bool showRank;
  final bool showTasks;
  final bool showTaskDetails;
  final bool showGoals;
  final bool showGoalDetails;
  final bool showMood;
  final bool showDiary;
  final bool showRewards;
  final bool showProgress;

  const MentorshipPermissions({
    this.showPoints = true,
    this.showStreak = true,
    this.showRank = true,
    this.showTasks = false,
    this.showTaskDetails = false,
    this.showGoals = false,
    this.showGoalDetails = false,
    this.showMood = false,
    this.showDiary = false,
    this.showRewards = true,
    this.showProgress = true,
  });

  factory MentorshipPermissions.fromJson(dynamic value) {
    if (value == null) return const MentorshipPermissions();

    Map<String, dynamic> json;
    if (value is String) {
      try {
        json = jsonDecode(value) as Map<String, dynamic>;
      } catch (_) {
        return const MentorshipPermissions();
      }
    } else if (value is Map<String, dynamic>) {
      json = value;
    } else {
      return const MentorshipPermissions();
    }

    return MentorshipPermissions(
      showPoints: json['show_points'] as bool? ?? true,
      showStreak: json['show_streak'] as bool? ?? true,
      showRank: json['show_rank'] as bool? ?? true,
      showTasks: json['show_tasks'] as bool? ?? false,
      showTaskDetails: json['show_task_details'] as bool? ?? false,
      showGoals: json['show_goals'] as bool? ?? false,
      showGoalDetails: json['show_goal_details'] as bool? ?? false,
      showMood: json['show_mood'] as bool? ?? false,
      showDiary: json['show_diary'] as bool? ?? false,
      showRewards: json['show_rewards'] as bool? ?? true,
      showProgress: json['show_progress'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'show_points': showPoints,
    'show_streak': showStreak,
    'show_rank': showRank,
    'show_tasks': showTasks,
    'show_task_details': showTaskDetails,
    'show_goals': showGoals,
    'show_goal_details': showGoalDetails,
    'show_mood': showMood,
    'show_diary': showDiary,
    'show_rewards': showRewards,
    'show_progress': showProgress,
  };

  MentorshipPermissions copyWith({
    bool? showPoints,
    bool? showStreak,
    bool? showRank,
    bool? showTasks,
    bool? showTaskDetails,
    bool? showGoals,
    bool? showGoalDetails,
    bool? showMood,
    bool? showDiary,
    bool? showRewards,
    bool? showProgress,
  }) {
    return MentorshipPermissions(
      showPoints: showPoints ?? this.showPoints,
      showStreak: showStreak ?? this.showStreak,
      showRank: showRank ?? this.showRank,
      showTasks: showTasks ?? this.showTasks,
      showTaskDetails: showTaskDetails ?? this.showTaskDetails,
      showGoals: showGoals ?? this.showGoals,
      showGoalDetails: showGoalDetails ?? this.showGoalDetails,
      showMood: showMood ?? this.showMood,
      showDiary: showDiary ?? this.showDiary,
      showRewards: showRewards ?? this.showRewards,
      showProgress: showProgress ?? this.showProgress,
    );
  }
}

class MentoringSettings {
  final bool mentoringEnabled;
  final bool isPublic;
  final bool allowMentoringRequests;
  final MentorshipPermissions defaultPermissions;

  MentoringSettings({
    this.mentoringEnabled = true,
    this.isPublic = true,
    this.allowMentoringRequests = true,
    this.defaultPermissions = const MentorshipPermissions(),
  });

  factory MentoringSettings.fromJson(Map<String, dynamic> json) {
    return MentoringSettings(
      mentoringEnabled: _parseBool(json['mentoring_enabled'], defaultValue: true),
      isPublic: _parseBool(json['is_public'], defaultValue: true),
      allowMentoringRequests: _parseBool(
        json['allow_mentoring_requests'],
        defaultValue: true,
      ),
      defaultPermissions: MentorshipPermissions.fromJson(json['default_permissions']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mentoring_enabled': mentoringEnabled,
      'is_public': isPublic,
      'allow_mentoring_requests': allowMentoringRequests,
      'default_permissions': defaultPermissions.toJson(),
    };
  }

  MentoringSettings copyWith({
    bool? mentoringEnabled,
    bool? isPublic,
    bool? allowMentoringRequests,
    MentorshipPermissions? defaultPermissions,
  }) {
    return MentoringSettings(
      mentoringEnabled: mentoringEnabled ?? this.mentoringEnabled,
      isPublic: isPublic ?? this.isPublic,
      allowMentoringRequests: allowMentoringRequests ?? this.allowMentoringRequests,
      defaultPermissions: defaultPermissions ?? this.defaultPermissions,
    );
  }
}
