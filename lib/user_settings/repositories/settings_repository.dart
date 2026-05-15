// lib/repositories/settings_repository.dart

import 'dart:async';
import 'dart:convert';
import '../../widgets/error_handler.dart';
import '../../widgets/logger.dart';
import '../../services/powersync_service.dart';
import '../models/settings_model.dart';

class SettingsRepository {
  // ============================================================
  // SINGLETON INSTANCE
  // ============================================================
  static final SettingsRepository _instance = SettingsRepository._internal();
  factory SettingsRepository() => _instance;
  SettingsRepository._internal();

  // ============================================================
  // DEPENDENCIES
  // ============================================================
  final PowerSyncService _powerSync = PowerSyncService();

  // ============================================================
  // STATE
  // ============================================================
  UserSettings? _cachedSettings;
  StreamController<UserSettings?>? _settingsController;
  StreamSubscription? _watchSubscription;
  bool _isInitialized = false;
  Completer<bool>? _initCompleter;

  // ============================================================
  // CONSTANTS
  // ============================================================
  static const String _tableName = 'user_settings';
  static const int _currentVersion = 1;

  static const List<String> _jsonbColumns = [
    'appearance',
    'notifications',
    'privacy',
    'tasks',
    'goals',
    'bucket_list',
    'diary',
    'chat',
    'social',
    'ai',
    'competition',
    'security',
    'data_storage',
    'localization',
    'accessibility',
    'experimental',
    'widgets',
    'analytics',
    'mentoring',
    'integrations',
  ];

  // ============================================================
  // GETTERS
  // ============================================================
  String? get currentUserId => _powerSync.currentUserId;
  UserSettings? get cachedSettings => _cachedSettings;
  bool get isInitialized => _isInitialized;

  Stream<UserSettings?> get settingsStream {
    _settingsController ??= StreamController<UserSettings?>.broadcast(
      onListen: _startWatching,
      onCancel: _stopWatching,
    );
    return _settingsController!.stream;
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialize settings repository
  Future<UserSettings?> initialize() async {
    if (_isInitialized && _cachedSettings != null) {
      logI('Settings repository already initialized');
      return _cachedSettings;
    }

    // Prevent multiple simultaneous initializations
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      logD('Waiting for ongoing initialization...');
      await _initCompleter!.future;
      return _cachedSettings;
    }

    _initCompleter = Completer<bool>();

    try {
      if (currentUserId == null) {
        logD('Settings repository: skip DB init (user not authenticated)');
        _initCompleter!.complete(false);
        return null;
      }

      logI('Initializing settings repository for user: $currentUserId');

      // Try to get existing settings
      UserSettings? settings = await _fetchSettings();

      // Create default settings if not exists
      if (settings == null) {
        logI('No settings found, creating defaults...');
        final created = await _createDefaultSettings();
        if (created) {
          settings = await _fetchSettings();
        }
      }

      if (settings != null) {
        _cachedSettings = settings;
        _isInitialized = true;
        _startWatching();
        _initCompleter!.complete(true);
        logI('✅ Settings repository initialized successfully');
        return settings;
      }

      _initCompleter!.complete(false);
      return null;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'SettingsRepository.initialize');
      _initCompleter!.complete(false);
      return null;
    }
  }

  /// Ensure repository is initialized before operations
  Future<bool> _ensureInitialized() async {
    if (_isInitialized && _cachedSettings != null) return true;

    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      return await _initCompleter!.future;
    }

    final settings = await initialize();
    return settings != null;
  }

  // ============================================================
  // PRIVATE CRUD OPERATIONS
  // ============================================================

  /// Fetch settings from database
  Future<UserSettings?> _fetchSettings() async {
    try {
      if (currentUserId == null) return null;

      final result = await _powerSync.getById(_tableName, currentUserId!);
      if (result == null) return null;

      final parsed = _parseJsonbFields(result);
      return UserSettings.fromJson(parsed);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsRepository._fetchSettings',
      );
      return null;
    }
  }

  /// Create default settings
  Future<bool> _createDefaultSettings() async {
    try {
      if (currentUserId == null) return false;

      logI('Creating default settings for user: $currentUserId');

      final defaultSettings = UserSettings.defaultSettings(currentUserId!);
      final now = DateTime.now().toIso8601String();

      final data = _settingsToDbMap(defaultSettings, isCreate: true);
      data['created_at'] = now;
      data['updated_at'] = now;

      await _powerSync.insert(_tableName, data);

      logI('✅ Default settings created');
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsRepository._createDefaultSettings',
      );
      return false;
    }
  }

  /// Convert settings to database map
  Map<String, dynamic> _settingsToDbMap(
    UserSettings settings, {
    bool isCreate = false,
  }) {
    final map = <String, dynamic>{
      'appearance': settings.appearance.toJson(),
      'notifications': settings.notifications.toJson(),
      'privacy': settings.privacy.toJson(),
      'tasks': settings.tasks.toJson(),
      'goals': settings.goals.toJson(),
      'bucket_list': settings.bucketList.toJson(),
      'diary': settings.diary.toJson(),
      'chat': settings.chat.toJson(),
      'social': settings.social.toJson(),
      'ai': settings.ai.toJson(),
      'competition': settings.competition.toJson(),
      'security': settings.security.toJson(),
      'data_storage': settings.dataStorage.toJson(),
      'localization': settings.localization.toJson(),
      'accessibility': settings.accessibility.toJson(),
      'experimental': settings.experimental.toJson(),
      'widgets': settings.widgets.toJson(),
      'analytics': settings.analytics.toJson(),
      'mentoring': settings.mentoring.toJson(),
      'integrations': settings.integrations.toJson(),
      'settings_version': _currentVersion,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (isCreate) {
      map['id'] = currentUserId;
      map['user_id'] = currentUserId;
    }

    return map;
  }

  // ============================================================
  // PUBLIC READ OPERATIONS
  // ============================================================

  /// Get current user's settings
  Future<UserSettings?> getCurrentUserSettings() async {
    try {
      if (!await _ensureInitialized()) return null;

      // Return cached if available
      if (_cachedSettings != null) {
        return _cachedSettings;
      }

      final settings = await _fetchSettings();
      if (settings != null) {
        _cachedSettings = settings;
      }
      return settings;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsRepository.getCurrentUserSettings',
      );
      return null;
    }
  }

  /// Get settings by user ID
  Future<UserSettings?> getSettingsByUserId(String userId) async {
    try {
      final result = await _powerSync.getById(_tableName, userId);
      if (result == null) return null;

      final parsed = _parseJsonbFields(result);
      return UserSettings.fromJson(parsed);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsRepository.getSettingsByUserId',
      );
      return null;
    }
  }

  // ============================================================
  // PUBLIC UPDATE OPERATIONS
  // ============================================================

  /// Update entire settings
  Future<bool> updateSettings(
    UserSettings settings, {
    bool showSnackbar = false,
  }) async {
    try {
      if (!await _ensureInitialized()) {
        ErrorHandler.showErrorSnackbar('Settings not initialized');
        return false;
      }

      logD('Updating all settings');

      final data = _settingsToDbMap(settings);
      data['last_synced_at'] = DateTime.now().toIso8601String();

      await _powerSync.update(_tableName, data, currentUserId!);

      _cachedSettings = settings;
      _notifySettingsChanged(settings);

      if (showSnackbar) {
        ErrorHandler.showSuccessSnackbar('Settings saved');
      }

      logI('✅ Settings updated successfully');
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsRepository.updateSettings',
      );
      ErrorHandler.showErrorSnackbar('Failed to save settings');
      return false;
    }
  }

  /// Generic section update helper
  Future<bool> _updateSection<T>({
    required String sectionName,
    required T section,
    required UserSettings Function(UserSettings current, T section) copyWith,
    bool showSnackbar = false,
  }) async {
    try {
      if (!await _ensureInitialized()) return false;

      final current = await getCurrentUserSettings();
      if (current == null) {
        ErrorHandler.showErrorSnackbar('Settings not found');
        return false;
      }

      final updated = copyWith(current, section);
      return await updateSettings(updated, showSnackbar: showSnackbar);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsRepository._updateSection($sectionName)',
      );
      ErrorHandler.showErrorSnackbar('Failed to update $sectionName settings');
      return false;
    }
  }

  /// Update appearance settings
  Future<bool> updateAppearance(
    AppearanceSettings appearance, {
    bool showSnackbar = false,
  }) {
    return _updateSection(
      sectionName: 'appearance',
      section: appearance,
      copyWith: (current, section) => current.copyWith(appearance: section),
      showSnackbar: showSnackbar,
    );
  }

  /// Update notification settings
  Future<bool> updateNotifications(
    NotificationSettings notifications, {
    bool showSnackbar = false,
  }) {
    return _updateSection(
      sectionName: 'notifications',
      section: notifications,
      copyWith: (current, section) => current.copyWith(notifications: section),
      showSnackbar: showSnackbar,
    );
  }

  /// Update privacy settings
  Future<bool> updatePrivacy(
    PrivacySettings privacy, {
    bool showSnackbar = false,
  }) {
    return _updateSection(
      sectionName: 'privacy',
      section: privacy,
      copyWith: (current, section) => current.copyWith(privacy: section),
      showSnackbar: showSnackbar,
    );
  }

  /// Update task settings
  Future<bool> updateTaskSettings(
    TaskSettings tasks, {
    bool showSnackbar = false,
  }) {
    return _updateSection(
      sectionName: 'tasks',
      section: tasks,
      copyWith: (current, section) => current.copyWith(tasks: section),
      showSnackbar: showSnackbar,
    );
  }

  /// Update goal settings
  Future<bool> updateGoalSettings(
    GoalSettings goals, {
    bool showSnackbar = false,
  }) {
    return _updateSection(
      sectionName: 'goals',
      section: goals,
      copyWith: (current, section) => current.copyWith(goals: section),
      showSnackbar: showSnackbar,
    );
  }

  /// Update bucket list settings
  Future<bool> updateBucketListSettings(
    BucketListSettings bucketList, {
    bool showSnackbar = false,
  }) {
    return _updateSection(
      sectionName: 'bucket list',
      section: bucketList,
      copyWith: (current, section) => current.copyWith(bucketList: section),
      showSnackbar: showSnackbar,
    );
  }

  /// Update diary settings
  Future<bool> updateDiarySettings(
    DiarySettings diary, {
    bool showSnackbar = false,
  }) {
    return _updateSection(
      sectionName: 'diary',
      section: diary,
      copyWith: (current, section) => current.copyWith(diary: section),
      showSnackbar: showSnackbar,
    );
  }

  /// Update chat settings
  Future<bool> updateChatSettings(
    ChatSettings chat, {
    bool showSnackbar = false,
  }) {
    return _updateSection(
      sectionName: 'chat',
      section: chat,
      copyWith: (current, section) => current.copyWith(chat: section),
      showSnackbar: showSnackbar,
    );
  }

  /// Update social settings
  Future<bool> updateSocialSettings(
    SocialSettings social, {
    bool showSnackbar = false,
  }) {
    return _updateSection(
      sectionName: 'social',
      section: social,
      copyWith: (current, section) => current.copyWith(social: section),
      showSnackbar: showSnackbar,
    );
  }

  /// Update AI settings
  Future<bool> updateAISettings(AiSettings ai, {bool showSnackbar = false}) {
    return _updateSection(
      sectionName: 'AI',
      section: ai,
      copyWith: (current, section) => current.copyWith(ai: section),
      showSnackbar: showSnackbar,
    );
  }

  /// Update competition settings
  Future<bool> updateCompetitionSettings(
    CompetitionSettings competition, {
    bool showSnackbar = false,
  }) {
    return _updateSection(
      sectionName: 'competition',
      section: competition,
      copyWith: (current, section) => current.copyWith(competition: section),
      showSnackbar: showSnackbar,
    );
  }

  /// Update security settings
  Future<bool> updateSecuritySettings(
    SecuritySettings security, {
    bool showSnackbar = true,
  }) {
    return _updateSection(
      sectionName: 'security',
      section: security,
      copyWith: (current, section) => current.copyWith(security: section),
      showSnackbar: showSnackbar,
    );
  }

  /// Update data storage settings
  Future<bool> updateDataStorageSettings(
    DataStorageSettings dataStorage, {
    bool showSnackbar = false,
  }) {
    return _updateSection(
      sectionName: 'data storage',
      section: dataStorage,
      copyWith: (current, section) => current.copyWith(dataStorage: section),
      showSnackbar: showSnackbar,
    );
  }

  /// Update localization settings
  Future<bool> updateLocalizationSettings(
    LocalizationSettings localization, {
    bool showSnackbar = false,
  }) {
    return _updateSection(
      sectionName: 'localization',
      section: localization,
      copyWith: (current, section) => current.copyWith(localization: section),
      showSnackbar: showSnackbar,
    );
  }

  /// Update accessibility settings
  Future<bool> updateAccessibilitySettings(
    AccessibilitySettings accessibility, {
    bool showSnackbar = false,
  }) {
    return _updateSection(
      sectionName: 'accessibility',
      section: accessibility,
      copyWith: (current, section) => current.copyWith(accessibility: section),
      showSnackbar: showSnackbar,
    );
  }

  /// Update experimental settings
  Future<bool> updateExperimentalSettings(
    ExperimentalSettings experimental, {
    bool showSnackbar = false,
  }) {
    return _updateSection(
      sectionName: 'experimental',
      section: experimental,
      copyWith: (current, section) => current.copyWith(experimental: section),
      showSnackbar: showSnackbar,
    );
  }

  /// Update widget settings
  Future<bool> updateWidgetSettings(
    WidgetSettings widgets, {
    bool showSnackbar = false,
  }) {
    return _updateSection(
      sectionName: 'widgets',
      section: widgets,
      copyWith: (current, section) => current.copyWith(widgets: section),
      showSnackbar: showSnackbar,
    );
  }

  /// Update analytics settings
  Future<bool> updateAnalyticsSettings(
    AnalyticsSettings analytics, {
    bool showSnackbar = false,
  }) {
    return _updateSection(
      sectionName: 'analytics',
      section: analytics,
      copyWith: (current, section) => current.copyWith(analytics: section),
      showSnackbar: showSnackbar,
    );
  }

  /// Update integration settings
  Future<bool> updateIntegrationSettings(
    IntegrationSettings integrations, {
    bool showSnackbar = false,
  }) {
    return _updateSection(
      sectionName: 'integrations',
      section: integrations,
      copyWith: (current, section) => current.copyWith(integrations: section),
      showSnackbar: showSnackbar,
    );
  }

  /// Update mentoring settings
  Future<bool> updateMentoringSettings(
    MentoringSettings mentoring, {
    bool showSnackbar = false,
  }) {
    return _updateSection(
      sectionName: 'mentoring',
      section: mentoring,
      copyWith: (current, section) => current.copyWith(mentoring: section),
      showSnackbar: showSnackbar,
    );
  }

  // ============================================================
  // THEME OPERATIONS
  // ============================================================

  /// Toggle dark mode
  Future<bool> toggleDarkMode() async {
    try {
      final current = await getCurrentUserSettings();
      if (current == null) return false;

      final newTheme = current.appearance.theme == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;

      final updated = current.appearance.copyWith(theme: newTheme);
      final success = await updateAppearance(updated);

      if (success) {
        logI('✅ Theme toggled to: ${newTheme.name}');
        ErrorHandler.showInfoSnackbar(
          'Switched to ${newTheme == ThemeMode.dark ? "dark" : "light"} mode',
          title: 'Theme Changed',
        );
      }

      return success;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsRepository.toggleDarkMode',
      );
      return false;
    }
  }

  /// Set theme mode
  Future<bool> setThemeMode(ThemeMode theme) async {
    try {
      final current = await getCurrentUserSettings();
      if (current == null) return false;

      if (current.appearance.theme == theme) return true;

      final updated = current.appearance.copyWith(theme: theme);
      return await updateAppearance(updated);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsRepository.setThemeMode',
      );
      return false;
    }
  }

  /// Set accent color
  Future<bool> setAccentColor(String color) async {
    try {
      final current = await getCurrentUserSettings();
      if (current == null) return false;

      final updated = current.appearance.copyWith(accentColor: color);
      return await updateAppearance(updated);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsRepository.setAccentColor',
      );
      return false;
    }
  }

  // ============================================================
  // NOTIFICATION OPERATIONS
  // ============================================================

  /// Toggle notifications
  Future<bool> toggleNotifications() async {
    try {
      final current = await getCurrentUserSettings();
      if (current == null) return false;

      final updated = current.notifications.copyWith(
        enabled: !current.notifications.enabled,
      );

      final success = await updateNotifications(updated);

      if (success) {
        ErrorHandler.showInfoSnackbar(
          updated.enabled ? 'Notifications enabled' : 'Notifications disabled',
          title: 'Notifications',
        );
      }

      return success;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsRepository.toggleNotifications',
      );
      return false;
    }
  }

  /// Update notification channel
  Future<bool> updateNotificationChannel(String channel, bool enabled) async {
    try {
      final current = await getCurrentUserSettings();
      if (current == null) return false;

      final channels = current.notifications.channels;
      final updatedChannels = _getUpdatedChannel(channels, channel, enabled);

      if (updatedChannels == null) {
        logW('Unknown notification channel: $channel');
        return false;
      }

      final updatedNotifications = current.notifications.copyWith(
        channels: updatedChannels,
      );

      return await updateNotifications(updatedNotifications);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsRepository.updateNotificationChannel',
      );
      return false;
    }
  }

  NotificationChannels? _getUpdatedChannel(
    NotificationChannels channels,
    String channel,
    bool enabled,
  ) {
    switch (channel) {
      case 'tasks':
        return channels.copyWith(
          tasks: channels.tasks.copyWith(enabled: enabled),
        );
      case 'goals':
        return channels.copyWith(
          goals: channels.goals.copyWith(enabled: enabled),
        );
      case 'social':
        return channels.copyWith(
          social: channels.social.copyWith(enabled: enabled),
        );
      case 'chat':
        return channels.copyWith(
          chat: channels.chat.copyWith(enabled: enabled),
        );
      case 'diary':
        return channels.copyWith(
          diary: channels.diary.copyWith(enabled: enabled),
        );
      case 'ai':
        return channels.copyWith(ai: channels.ai.copyWith(enabled: enabled));
      case 'system':
        return channels.copyWith(
          system: channels.system.copyWith(enabled: enabled),
        );
      default:
        return null;
    }
  }

  /// Set quiet hours
  Future<bool> setQuietHours({
    required bool enabled,
    String? startTime,
    String? endTime,
    List<String>? days,
  }) async {
    try {
      final current = await getCurrentUserSettings();
      if (current == null) return false;

      final quietHours = current.notifications.quietHours.copyWith(
        enabled: enabled,
        start: startTime,
        end: endTime,
        days: days,
      );

      final updated = current.notifications.copyWith(quietHours: quietHours);
      return await updateNotifications(updated);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsRepository.setQuietHours',
      );
      return false;
    }
  }

  // ============================================================
  // PRIVACY OPERATIONS
  // ============================================================

  /// Block user
  Future<bool> blockUser(String userId) async {
    try {
      final current = await getCurrentUserSettings();
      if (current == null) return false;

      if (current.privacy.blockedUsers.contains(userId)) {
        return true; // Already blocked
      }

      final blockedUsers = [...current.privacy.blockedUsers, userId];
      final updated = current.privacy.copyWith(blockedUsers: blockedUsers);

      final success = await updatePrivacy(updated);

      if (success) {
        logI('User blocked: $userId');
        ErrorHandler.showSuccessSnackbar('User blocked');
      }

      return success;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'SettingsRepository.blockUser');
      ErrorHandler.showErrorSnackbar('Failed to block user');
      return false;
    }
  }

  /// Unblock user
  Future<bool> unblockUser(String userId) async {
    try {
      final current = await getCurrentUserSettings();
      if (current == null) return false;

      final blockedUsers = current.privacy.blockedUsers
          .where((id) => id != userId)
          .toList();
      final updated = current.privacy.copyWith(blockedUsers: blockedUsers);

      final success = await updatePrivacy(updated);

      if (success) {
        logI('User unblocked: $userId');
        ErrorHandler.showSuccessSnackbar('User unblocked');
      }

      return success;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'SettingsRepository.unblockUser');
      ErrorHandler.showErrorSnackbar('Failed to unblock user');
      return false;
    }
  }

  /// Set profile visibility
  Future<bool> setProfileVisibility(ProfileVisibility visibility) async {
    try {
      final current = await getCurrentUserSettings();
      if (current == null) return false;

      final updated = current.privacy.copyWith(profileVisibility: visibility);
      return await updatePrivacy(updated);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsRepository.setProfileVisibility',
      );
      return false;
    }
  }

  // ============================================================
  // RESET OPERATIONS
  // ============================================================

  /// Reset all settings to defaults
  Future<bool> resetAllSettings() async {
    try {
      if (currentUserId == null) {
        ErrorHandler.showErrorSnackbar('User not authenticated');
        return false;
      }

      logW('Resetting all settings to defaults');
      ErrorHandler.showLoading('Resetting settings...');

      // Delete existing settings
      await _powerSync.delete(_tableName, currentUserId!);

      // Create new default settings
      final created = await _createDefaultSettings();

      if (!created) {
        ErrorHandler.hideLoading();
        ErrorHandler.showErrorSnackbar('Failed to reset settings');
        return false;
      }

      // Reload settings
      final settings = await _fetchSettings();
      _cachedSettings = settings;
      _notifySettingsChanged(settings);

      ErrorHandler.hideLoading();
      ErrorHandler.showSuccessSnackbar('Settings reset to defaults');
      logI('✅ Settings reset to defaults');

      return true;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsRepository.resetAllSettings',
      );
      ErrorHandler.hideLoading();
      ErrorHandler.showErrorSnackbar('Failed to reset settings');
      return false;
    }
  }

  /// Reset specific category_model to defaults
  Future<bool> resetCategory(String category) async {
    try {
      final current = await getCurrentUserSettings();
      if (current == null) return false;

      final defaults = UserSettings.defaultSettings(currentUserId!);
      final updated = _getResetCategorySettings(current, defaults, category);

      if (updated == null) {
        logW('Unknown settings category_model: $category');
        return false;
      }

      final success = await updateSettings(updated);

      if (success) {
        logI('$category settings reset to defaults');
        ErrorHandler.showSuccessSnackbar(
          '${_capitalize(category)} settings reset',
        );
      }

      return success;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsRepository.resetCategory',
      );
      ErrorHandler.showErrorSnackbar('Failed to reset settings');
      return false;
    }
  }

  UserSettings? _getResetCategorySettings(
    UserSettings current,
    UserSettings defaults,
    String category,
  ) {
    switch (category) {
      case 'appearance':
        return current.copyWith(appearance: defaults.appearance);
      case 'notifications':
        return current.copyWith(notifications: defaults.notifications);
      case 'privacy':
        return current.copyWith(privacy: defaults.privacy);
      case 'tasks':
        return current.copyWith(tasks: defaults.tasks);
      case 'goals':
        return current.copyWith(goals: defaults.goals);
      case 'bucketList':
        return current.copyWith(bucketList: defaults.bucketList);
      case 'diary':
        return current.copyWith(diary: defaults.diary);
      case 'chat':
        return current.copyWith(chat: defaults.chat);
      case 'social':
        return current.copyWith(social: defaults.social);
      case 'ai':
        return current.copyWith(ai: defaults.ai);
      case 'competition':
        return current.copyWith(competition: defaults.competition);
      case 'security':
        return current.copyWith(security: defaults.security);
      case 'dataStorage':
        return current.copyWith(dataStorage: defaults.dataStorage);
      case 'localization':
        return current.copyWith(localization: defaults.localization);
      case 'accessibility':
        return current.copyWith(accessibility: defaults.accessibility);
      case 'experimental':
        return current.copyWith(experimental: defaults.experimental);
      case 'widgets':
        return current.copyWith(widgets: defaults.widgets);
      case 'analytics':
        return current.copyWith(analytics: defaults.analytics);
      case 'integrations':
        return current.copyWith(integrations: defaults.integrations);
      default:
        return null;
    }
  }

  // ============================================================
  // EXPORT/IMPORT
  // ============================================================

  /// Export settings as JSON
  Future<Map<String, dynamic>?> exportSettings() async {
    try {
      logI('Exporting settings...');

      final settings = await getCurrentUserSettings();
      if (settings == null) {
        ErrorHandler.showErrorSnackbar('No settings to export');
        return null;
      }

      final exported = {
        'version': _currentVersion,
        'exported_at': DateTime.now().toIso8601String(),
        'settings': settings.toJson(),
      };

      logI('✅ Settings exported successfully');
      return exported;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsRepository.exportSettings',
      );
      ErrorHandler.showErrorSnackbar('Failed to export settings');
      return null;
    }
  }

  /// Import settings from JSON
  Future<bool> importSettings(Map<String, dynamic> data) async {
    try {
      logI('Importing settings...');
      ErrorHandler.showLoading('Importing settings...');

      // Validate version
      final version = data['version'] as int?;
      if (version == null || version > _currentVersion) {
        ErrorHandler.hideLoading();
        ErrorHandler.showErrorSnackbar('Unsupported settings version');
        return false;
      }

      // Parse settings
      final settingsData = data['settings'] as Map<String, dynamic>?;
      if (settingsData == null) {
        ErrorHandler.hideLoading();
        ErrorHandler.showErrorSnackbar('Invalid settings data');
        return false;
      }

      // Update with current user ID
      settingsData['user_id'] = currentUserId;
      settingsData['id'] = currentUserId;

      final settings = UserSettings.fromJson(settingsData);
      final success = await updateSettings(settings);

      ErrorHandler.hideLoading();

      if (success) {
        logI('✅ Settings imported successfully');
        ErrorHandler.showSuccessSnackbar('Settings imported successfully');
      }

      return success;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsRepository.importSettings',
      );
      ErrorHandler.hideLoading();
      ErrorHandler.showErrorSnackbar('Failed to import settings');
      return false;
    }
  }

  // ============================================================
  // WATCH STREAMS
  // ============================================================

  /// Watch current user's settings
  Stream<UserSettings?> watchCurrentUserSettings() => settingsStream;

  void _startWatching() {
    if (currentUserId == null) return;

    _stopWatching();

    _watchSubscription = _powerSync
        .watchQuery(
          'SELECT * FROM $_tableName WHERE id = ?',
          parameters: [currentUserId],
        )
        .listen(
          (results) {
            if (results.isNotEmpty) {
              try {
                final parsed = _parseJsonbFields(results.first);
                final settings = UserSettings.fromJson(parsed);
                _cachedSettings = settings;
                _settingsController?.add(settings);
                logD('Settings updated from watch stream');
              } catch (e) {
                ErrorHandler.logError(
                  'Failed to parse settings from stream',
                  e,
                );
              }
            } else {
              _cachedSettings = null;
              _settingsController?.add(null);
            }
          },
          onError: (error) {
            ErrorHandler.logError('Error in settings watch stream', error);
          },
        );
  }

  void _stopWatching() {
    _watchSubscription?.cancel();
    _watchSubscription = null;
  }

  void _notifySettingsChanged(UserSettings? settings) {
    _settingsController?.add(settings);
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Check if user should receive notifications
  Future<bool> shouldSendNotification(String channel, {String? type}) async {
    try {
      final settings = _cachedSettings ?? await getCurrentUserSettings();
      if (settings == null) return false;

      // Check global enabled
      if (!settings.notifications.enabled) return false;

      // Check quiet hours
      if (_isInQuietHours(settings.notifications.quietHours)) {
        return false;
      }

      // Check channel-specific settings
      return _isChannelEnabled(settings.notifications.channels, channel);
    } catch (e) {
      ErrorHandler.logError('Error checking notification permission', e);
      return true; // Default to allowed if error
    }
  }

  bool _isInQuietHours(QuietHoursSettings quietHours) {
    if (!quietHours.enabled) return false;

    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final currentDay = _getDayName(now.weekday);

    if (!quietHours.days.contains(currentDay)) {
      return false;
    }

    final start = quietHours.start;
    final end = quietHours.end;

    if (start.compareTo(end) <= 0) {
      return currentTime.compareTo(start) >= 0 &&
          currentTime.compareTo(end) <= 0;
    } else {
      return currentTime.compareTo(start) >= 0 ||
          currentTime.compareTo(end) <= 0;
    }
  }

  String _getDayName(int weekday) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return days[weekday - 1];
  }

  bool _isChannelEnabled(NotificationChannels channels, String channel) {
    switch (channel) {
      case 'tasks':
        return channels.tasks.enabled;
      case 'goals':
        return channels.goals.enabled;
      case 'social':
        return channels.social.enabled;
      case 'chat':
        return channels.chat.enabled;
      case 'diary':
        return channels.diary.enabled;
      case 'ai':
        return channels.ai.enabled;
      case 'system':
        return channels.system.enabled;
      default:
        return true;
    }
  }

  /// Check if user is blocked (sync method using cache)
  bool isUserBlocked(String userId) {
    return _cachedSettings?.privacy.isUserBlocked(userId) ?? false;
  }

  /// Check if feature is enabled
  bool isFeatureEnabled(String feature) {
    return _cachedSettings?.experimental.isFeatureEnabled(feature) ?? false;
  }

  /// Parse JSONB fields
  Map<String, dynamic> _parseJsonbFields(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);

    for (final column in _jsonbColumns) {
      if (result[column] is String) {
        try {
          result[column] = jsonDecode(result[column] as String);
        } catch (e) {
          result[column] = <String, dynamic>{};
        }
      }
    }

    return result;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  /// Clear cache (useful for logout)
  void clearCache() {
    _cachedSettings = null;
    _isInitialized = false;
    _initCompleter = null;
    logI('Settings cache cleared');
  }


  /// Dispose repository
  void dispose() {
    _stopWatching();
    _settingsController?.close();
    _settingsController = null;
    _cachedSettings = null;
    _isInitialized = false;
    _initCompleter = null;
    logI('Settings repository disposed');
  }
}

// Global instance
final settingsRepository = SettingsRepository();
