// lib/providers/settings_provider.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart' hide ThemeMode, ColorScheme;
import 'package:flutter/material.dart' as material show ColorScheme, ThemeMode;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/Mode/navigation_bar_type.dart';
import '../../widgets/error_handler.dart';
import '../../widgets/logger.dart';
import '../../helpers/app_theme.dart';
import '../models/settings_model.dart';
import '../repositories/settings_repository.dart';
import '../../services/supabase_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../services/powersync_service.dart';
import '../../media_utility/universal_media_service.dart';

class SettingsProvider extends ChangeNotifier {
  // ============================================================
  // SINGLETON INSTANCE
  // ============================================================
  static SettingsProvider? _instance;
  factory SettingsProvider() => _instance ??= SettingsProvider._internal();
  SettingsProvider._internal();

  /// Reset singleton for testing
  @visibleForTesting
  static void reset() {
    _instance = null;
  }

  SettingsRepository? _repositoryOverride;
  SettingsRepository get _repository => _repositoryOverride ?? settingsRepository;

  @visibleForTesting
  set repository(SettingsRepository repo) => _repositoryOverride = repo;

  NavigationBarType _navigationBarType = NavigationBarType.personal;

  // ============================================================
  // STATE VARIABLES
  // ============================================================
  UserSettings? _settings;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  StreamSubscription<UserSettings?>? _settingsSubscription;

  // Theme cache for quick access
  ThemeMode _currentThemeMode = ThemeMode.system;
  bool _isDarkMode = false;
  String _accentColor = '#6366f1';

  final String _navigationMode = 'personal';

  // Notification cache
  bool _notificationsEnabled = true;
  bool _isInQuietHours = false;

  // Loading states for specific operations
  final Map<String, bool> _loadingStates = {};

  // Quiet hours check timer
  Timer? _quietHoursTimer;

  // Storage Metrics
  double _databaseSizeMB = 0.0;
  double _cacheSizeMB = 0.0;

  // ============================================================
  // GETTERS
  // ============================================================
  UserSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get hasError => _error != null;

  // Quick access getters
  ThemeMode get themeMode => _currentThemeMode;
  String get navigationMode => _navigationMode;

  // Primary getter returning enum
  NavigationBarType get navigationBarType => _navigationBarType;

  // // Backward compatibility getter returning string
  //   String get navigationMode => _navigationBarType.name;

  /// Helper to get Flutter's Material Mode
  material.ThemeMode get flutterThemeMode {
    switch (_currentThemeMode) {
      case ThemeMode.light:
        return material.ThemeMode.light;
      case ThemeMode.dark:
        return material.ThemeMode.dark;
      case ThemeMode.system:
        return material.ThemeMode.system;
    }
  }

  bool get isDarkMode => _isDarkMode;
  String get accentColor => _accentColor;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isInQuietHours => _isInQuietHours;

  // Storage Metrics Getters
  double get databaseSizeMB => _databaseSizeMB;
  double get cacheSizeMB => _cacheSizeMB;
  double get totalUsageMB => _databaseSizeMB + _cacheSizeMB;

  // Settings sections getters
  AppearanceSettings get appearance =>
      _settings?.appearance ?? AppearanceSettings();
  NotificationSettings get notifications =>
      _settings?.notifications ?? NotificationSettings();
  PrivacySettings get privacy => _settings?.privacy ?? PrivacySettings();
  TaskSettings get tasks => _settings?.tasks ?? TaskSettings();
  GoalSettings get goals => _settings?.goals ?? GoalSettings();
  BucketListSettings get bucketList =>
      _settings?.bucketList ?? BucketListSettings();
  DiarySettings get diary => _settings?.diary ?? DiarySettings();
  ChatSettings get chat => _settings?.chat ?? ChatSettings();
  SocialSettings get social => _settings?.social ?? SocialSettings();
  AiSettings get ai => _settings?.ai ?? AiSettings();
  CompetitionSettings get competition =>
      _settings?.competition ?? CompetitionSettings();
  SecuritySettings get security => _settings?.security ?? SecuritySettings();
  DataStorageSettings get dataStorage =>
      _settings?.dataStorage ?? DataStorageSettings();
  LocalizationSettings get localization =>
      _settings?.localization ?? LocalizationSettings();
  AccessibilitySettings get accessibility =>
      _settings?.accessibility ?? AccessibilitySettings();
  ExperimentalSettings get experimental =>
      _settings?.experimental ?? ExperimentalSettings();
  WidgetSettings get widgets => _settings?.widgets ?? WidgetSettings();
  AnalyticsSettings get analytics =>
      _settings?.analytics ?? AnalyticsSettings();
  MentoringSettings get mentoring =>
      _settings?.mentoring ?? MentoringSettings();
  IntegrationSettings get integrations =>
      _settings?.integrations ?? IntegrationSettings();

  /// Check loading state for specific operation
  bool isLoadingFor(String operation) => _loadingStates[operation] ?? false;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Load local preferences (Theme, Nav Mode) without DB access
  /// Call this in main.dart for fast startup
  Future<void> loadLocalPreferences() async {
    try {
      // Load Navigation Mode
      await _loadNavigationMode();

      // Load Theme Mode (if saved locally) - Future enhancement
      // For now using default or what was set in _loadNavigationMode if it saves theme too

      notifyListeners();
    } catch (e) {
      logW('Failed to load local preferences: $e');
    }
  }

  /// Initialize settings
  /// [force] - If true, re-initializes even if already initialized
  Future<bool> initialize({bool force = false}) async {
    if (_isInitialized && !force) {
      logD('Settings provider already initialized (use force=true to override)');
      return true;
    }

    if (_isLoading) {
      logD('Settings provider already loading, waiting...');
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _isInitialized;
    }

    logI('Initializing settings provider (force=$force)...');
    _setLoading(true);
    _clearError();

    try {
      // Always load local (non-DB) settings first
      await _loadNavigationMode();

      // Check if user is authenticated before attempting DB init
      final currentUserId = SupabaseService.instance.currentUserId;
      if (currentUserId == null) {
        logD('SettingsProvider: User not authenticated, skipped full DB initialization');
        _isInitialized = true; // Mark as initialized (at least local settings are ready)
        _setLoading(false);
        return true;
      }

      // 1. Initialize Repository (DB Access)
      final settings = await _repository.initialize();

      if (settings != null) {
        _updateSettings(settings);
        _startListening();
        _startQuietHoursTimer();
        _isInitialized = true;
        logI('✅ Settings provider initialized successfully from DB');
        
        // Initial storage metrics load
        refreshStorageMetrics();
        
        _setLoading(false);
        return true;
      } else {
        // If settings are null, create default settings
        logI('Settings not found in DB - creating defaults for user');

        final defaultSettings = UserSettings(
          id: currentUserId,
          userId: currentUserId,
        );
        _updateSettings(defaultSettings);
        _startListening();
        _startQuietHoursTimer();
        _isInitialized = true;
        _setLoading(false);
        return true;
      }
    } catch (e) {
      ErrorHandler.logError('SettingsProvider.initialize partial failure', e);
      _setError('Failed to initialize settings from DB');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reload settings from repository
  Future<bool> reload() async {
    logI('Reloading settings...');
    _setLoading(true);
    _clearError();

    try {
      final settings = await _repository.getCurrentUserSettings();
      if (settings != null) {
        _updateSettings(settings);
        logI('✅ Settings reloaded successfully');
        return true;
      }
      return false;
    } catch (e) {
      ErrorHandler.logError('SettingsProvider.reload failed', e);
      _setError('Failed to reload settings');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Start listening to settings changes
  void _startListening() {
    _settingsSubscription?.cancel();
    _settingsSubscription = _repository.watchCurrentUserSettings().listen(
      (settings) {
        if (settings != null) {
          _updateSettings(settings);
          logD('Settings updated from stream');
        }
      },
      onError: (error) {
        ErrorHandler.logError('Error in settings stream', error);
      },
    );
  }

  /// Start timer to check quiet hours periodically
  void _startQuietHoursTimer() {
    _quietHoursTimer?.cancel();
    _quietHoursTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkQuietHours(),
    );
  }

  Future<void> _loadNavigationMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('navigationMode');

      if (stored == 'social' || stored == NavigationBarType.social.name) {
        _navigationBarType = NavigationBarType.social;
      } else {
        _navigationBarType = NavigationBarType.personal;
      }

      notifyListeners();
      logD('Loaded navigation mode: ${_navigationBarType.name}');
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider._loadNavigationMode',
      );
      _navigationBarType = NavigationBarType.personal;
    }
  }

  // ============================================================
  // GENERIC UPDATE HELPER
  // ============================================================

  /// Execute an operation with optimistic update
  Future<bool> _executeWithOptimisticUpdate<T>({
    required String operationName,
    required T oldValue,
    required T newValue,
    required void Function(T value) updateCache,
    required Future<bool> Function() execute,
    bool showErrorSnackbar = true,
  }) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading(operationName, true);

    // Optimistic update
    updateCache(newValue);
    notifyListeners();

    try {
      final success = await execute();

      if (!success) {
        // Rollback on failure
        updateCache(oldValue);
        notifyListeners();
        if (showErrorSnackbar) {
          ErrorHandler.showErrorSnackbar('Failed to update $operationName');
        }
      }

      return success;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.$operationName',
      );
      // Rollback
      updateCache(oldValue);
      notifyListeners();
      if (showErrorSnackbar) {
        ErrorHandler.showErrorSnackbar('Failed to update $operationName');
      }
      return false;
    } finally {
      _setOperationLoading(operationName, false);
    }
  }

  // ============================================================
  // APPEARANCE SETTINGS
  // ============================================================

  /// Toggle dark mode
  Future<bool> toggleDarkMode() async {
    final oldTheme = _currentThemeMode;
    final oldIsDark = _isDarkMode;
    final newTheme = _isDarkMode ? ThemeMode.light : ThemeMode.dark;

    return _executeWithOptimisticUpdate(
      operationName: 'theme',
      oldValue: (oldTheme, oldIsDark),
      newValue: (newTheme, newTheme == ThemeMode.dark),
      updateCache: (value) {
        _currentThemeMode = value.$1;
        _isDarkMode = value.$2;
      },
      execute: () async {
        final updated = appearance.copyWith(theme: newTheme);
        return await _repository.updateAppearance(updated);
      },
    );
  }

  Future<bool> setNavigationBarType(NavigationBarType type) async {
    if (_navigationBarType == type) {
      return true;
    }

    _navigationBarType = type;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('navigationMode', type.name);
      logI('Navigation type set to: ${type.name}');
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.setNavigationBarType',
      );
      return false;
    }
  }

  /// Set navigation mode using string (backward compatibility)
  Future<bool> setNavigationMode(String mode) async {
    NavigationBarType? type;

    switch (mode.toLowerCase()) {
      case 'personal':
        type = NavigationBarType.personal;
        break;
      case 'social':
        type = NavigationBarType.social;
        break;
      default:
        logW('Invalid navigation mode: $mode');
        return false;
    }

    return await setNavigationBarType(type);
  }

  /// Set theme mode
  Future<bool> setThemeMode(ThemeMode mode) async {
    if (_currentThemeMode == mode) return true;

    final oldTheme = _currentThemeMode;
    final oldIsDark = _isDarkMode;

    return _executeWithOptimisticUpdate(
      operationName: 'theme',
      oldValue: (oldTheme, oldIsDark),
      newValue: (mode, mode == ThemeMode.dark),
      updateCache: (value) {
        _currentThemeMode = value.$1;
        _isDarkMode = value.$2;
      },
      execute: () async {
        final updated = appearance.copyWith(theme: mode);
        return await _repository.updateAppearance(updated);
      },
    );
  }

  /// Set accent color
  Future<bool> setAccentColor(String color) async {
    if (_accentColor == color) return true;

    final oldColor = _accentColor;

    return _executeWithOptimisticUpdate(
      operationName: 'accent',
      oldValue: oldColor,
      newValue: color,
      updateCache: (value) => _accentColor = value,
      execute: () async {
        final updated = appearance.copyWith(accentColor: color);
        return await _repository.updateAppearance(updated);
      },
    );
  }

  /// Set color scheme
  Future<bool> setColorScheme(ColorScheme scheme) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('colorScheme', true);

    try {
      final updated = appearance.copyWith(colorScheme: scheme);
      final success = await _repository.updateAppearance(updated);

      if (success) {
        logI('Color scheme updated to: ${scheme.name}');
      }

      return success;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.setColorScheme',
      );
      return false;
    } finally {
      _setOperationLoading('colorScheme', false);
    }
  }

  /// Set font size
  Future<bool> setFontSize(FontSize size) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('fontSize', true);

    try {
      final updated = appearance.copyWith(fontSize: size);
      return await _repository.updateAppearance(updated);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'SettingsProvider.setFontSize');
      return false;
    } finally {
      _setOperationLoading('fontSize', false);
    }
  }

  /// Update full appearance settings
  Future<bool> updateAppearance(AppearanceSettings newAppearance) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('appearance', true);

    try {
      return await _repository.updateAppearance(newAppearance);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.updateAppearance',
      );
      return false;
    } finally {
      _setOperationLoading('appearance', false);
    }
  }

  // ============================================================
  // NOTIFICATION SETTINGS
  // ============================================================

  /// Toggle notifications
  Future<bool> toggleNotifications() async {
    final oldValue = _notificationsEnabled;

    return _executeWithOptimisticUpdate(
      operationName: 'notifications',
      oldValue: oldValue,
      newValue: !oldValue,
      updateCache: (value) => _notificationsEnabled = value,
      execute: () async {
        final updated = notifications.copyWith(enabled: !oldValue);
        return await _repository.updateNotifications(updated);
      },
    );
  }

  /// Update notification channel
  Future<bool> setNotificationChannel({
    required String channel,
    required bool enabled,
  }) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('notificationChannel_$channel', true);

    try {
      final success = await _repository.updateNotificationChannel(
        channel,
        enabled,
      );
      if (success) {
        logI('Notification channel $channel set to: $enabled');
      }
      return success;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.setNotificationChannel',
      );
      return false;
    } finally {
      _setOperationLoading('notificationChannel_$channel', false);
    }
  }

  /// Set quiet hours
  Future<bool> setQuietHours({
    required bool enabled,
    String? startTime,
    String? endTime,
    List<String>? days,
  }) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('quietHours', true);

    try {
      final success = await _repository.setQuietHours(
        enabled: enabled,
        startTime: startTime,
        endTime: endTime,
        days: days,
      );

      if (success) {
        _checkQuietHours();
        logI('Quiet hours updated');
      }

      return success;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'SettingsProvider.setQuietHours');
      return false;
    } finally {
      _setOperationLoading('quietHours', false);
    }
  }

  /// Toggle sound
  Future<bool> toggleSound() async {
    if (!await _ensureInitialized()) return false;

    try {
      final updated = notifications.copyWith(sound: !notifications.sound);
      return await _repository.updateNotifications(updated);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'SettingsProvider.toggleSound');
      return false;
    }
  }

  /// Toggle vibration
  Future<bool> toggleVibration() async {
    if (!await _ensureInitialized()) return false;

    try {
      final updated = notifications.copyWith(
        vibration: !notifications.vibration,
      );
      return await _repository.updateNotifications(updated);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.toggleVibration',
      );
      return false;
    }
  }

  /// Update full notification settings
  Future<bool> updateNotifications(
    NotificationSettings newNotifications,
  ) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('notifications', true);

    try {
      return await _repository.updateNotifications(newNotifications);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.updateNotifications',
      );
      return false;
    } finally {
      _setOperationLoading('notifications', false);
    }
  }

  // ============================================================
  // PRIVACY SETTINGS
  // ============================================================

  /// Set profile visibility
  Future<bool> setProfileVisibility(ProfileVisibility visibility) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('profileVisibility', true);

    try {
      final success = await _repository.setProfileVisibility(visibility);
      if (success) {
        logI('Profile visibility set to: ${visibility.name}');
      }
      return success;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.setProfileVisibility',
      );
      return false;
    } finally {
      _setOperationLoading('profileVisibility', false);
    }
  }

  /// Block user
  Future<bool> blockUser(String userId) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('blockUser', true);

    try {
      return await _repository.blockUser(userId);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'SettingsProvider.blockUser');
      return false;
    } finally {
      _setOperationLoading('blockUser', false);
    }
  }

  /// Unblock user
  Future<bool> unblockUser(String userId) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('unblockUser', true);

    try {
      return await _repository.unblockUser(userId);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'SettingsProvider.unblockUser');
      return false;
    } finally {
      _setOperationLoading('unblockUser', false);
    }
  }

  /// Check if user is blocked
  bool isUserBlocked(String userId) => _repository.isUserBlocked(userId);

  /// Toggle online status
  Future<bool> toggleOnlineStatus() async {
    if (!await _ensureInitialized()) return false;

    try {
      final updated = privacy.copyWith(
        showOnlineStatus: !privacy.showOnlineStatus,
      );
      return await _repository.updatePrivacy(updated);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.toggleOnlineStatus',
      );
      return false;
    }
  }

  /// Toggle read receipts
  Future<bool> toggleReadReceipts() async {
    if (!await _ensureInitialized()) return false;

    try {
      final updated = privacy.copyWith(
        showReadReceipts: !privacy.showReadReceipts,
      );
      return await _repository.updatePrivacy(updated);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.toggleReadReceipts',
      );
      return false;
    }
  }

  /// Update full privacy settings
  Future<bool> updatePrivacy(PrivacySettings newPrivacy) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('privacy', true);

    try {
      return await _repository.updatePrivacy(newPrivacy);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'SettingsProvider.updatePrivacy');
      return false;
    } finally {
      _setOperationLoading('privacy', false);
    }
  }

  // ============================================================
  // TASK SETTINGS
  // ============================================================

  /// Set default task view
  Future<bool> setDefaultTaskView(TaskView view) async {
    if (!await _ensureInitialized()) return false;

    try {
      final updated = tasks.copyWith(defaultView: view);
      return await _repository.updateTaskSettings(updated);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.setDefaultTaskView',
      );
      return false;
    }
  }

  /// Set default priority
  Future<bool> setDefaultPriority(Priority priority) async {
    if (!await _ensureInitialized()) return false;

    try {
      final updated = tasks.copyWith(defaultPriority: priority);
      return await _repository.updateTaskSettings(updated);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.setDefaultPriority',
      );
      return false;
    }
  }

  /// Toggle rollover incomplete tasks
  Future<bool> toggleRolloverTasks() async {
    if (!await _ensureInitialized()) return false;

    try {
      final updated = tasks.copyWith(
        rolloverIncomplete: !tasks.rolloverIncomplete,
      );
      return await _repository.updateTaskSettings(updated);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.toggleRolloverTasks',
      );
      return false;
    }
  }

  /// Set week start day
  Future<bool> setWeekStartDay(WeekDay day) async {
    if (!await _ensureInitialized()) return false;

    try {
      final updated = tasks.copyWith(weekStartsOn: day);
      return await _repository.updateTaskSettings(updated);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.setWeekStartDay',
      );
      return false;
    }
  }

  /// Update full task settings
  Future<bool> updateTasks(TaskSettings newTasks) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('tasks', true);

    try {
      return await _repository.updateTaskSettings(newTasks);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'SettingsProvider.updateTasks');
      return false;
    } finally {
      _setOperationLoading('tasks', false);
    }
  }

  // ============================================================
  // GOAL SETTINGS
  // ============================================================

  /// Update goal settings
  Future<bool> updateGoals(GoalSettings newGoals) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('goals', true);

    try {
      return await _repository.updateGoalSettings(newGoals);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'SettingsProvider.updateGoals');
      return false;
    } finally {
      _setOperationLoading('goals', false);
    }
  }

  // ============================================================
  // BUCKET LIST SETTINGS
  // ============================================================

  /// Update bucket list settings
  Future<bool> updateBucketListSettings(BucketListSettings newBucketList) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('bucketList', true);

    try {
      return await _repository.updateBucketListSettings(newBucketList);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.updateBucketListSettings',
      );
      return false;
    } finally {
      _setOperationLoading('bucketList', false);
    }
  }

  // ============================================================
  // DIARY SETTINGS
  // ============================================================

  /// Update diary settings
  Future<bool> updateDiary(DiarySettings newDiary) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('diary', true);

    try {
      return await _repository.updateDiarySettings(newDiary);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'SettingsProvider.updateDiary');
      return false;
    } finally {
      _setOperationLoading('diary', false);
    }
  }

  // ============================================================
  // CHAT SETTINGS
  // ============================================================

  /// Toggle enter to send
  Future<bool> toggleEnterToSend() async {
    if (!await _ensureInitialized()) return false;

    try {
      final updated = chat.copyWith(enterToSend: !chat.enterToSend);
      return await _repository.updateChatSettings(updated);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.toggleEnterToSend',
      );
      return false;
    }
  }

  /// Set media auto download
  Future<bool> setMediaAutoDownload(MediaAutoDownload setting) async {
    if (!await _ensureInitialized()) return false;

    try {
      final updated = chat.copyWith(mediaAutoDownload: setting);
      return await _repository.updateChatSettings(updated);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.setMediaAutoDownload',
      );
      return false;
    }
  }

  /// Update full chat settings
  Future<bool> updateChat(ChatSettings newChat) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('chat', true);

    try {
      return await _repository.updateChatSettings(newChat);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'SettingsProvider.updateChat');
      return false;
    } finally {
      _setOperationLoading('chat', false);
    }
  }

  // ============================================================
  // SOCIAL SETTINGS
  // ============================================================

  /// Update full social settings
  Future<bool> updateSocialSettings(SocialSettings newSocial) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('social', true);

    try {
      return await _repository.updateSocialSettings(newSocial);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'SettingsProvider.updateSocialSettings');
      return false;
    } finally {
      _setOperationLoading('social', false);
    }
  }

  // ============================================================
  // AI SETTINGS
  // ============================================================

  /// Toggle AI
  Future<bool> toggleAI() async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('ai', true);

    try {
      final updated = ai.copyWith(enabled: !ai.enabled);
      final success = await _repository.updateAISettings(updated);

      if (success && !updated.enabled) {
        ErrorHandler.showInfoSnackbar(
          'AI features have been turned off',
          title: 'AI Disabled',
        );
      }

      return success;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'SettingsProvider.toggleAI');
      return false;
    } finally {
      _setOperationLoading('ai', false);
    }
  }

  /// Set AI response style
  Future<bool> setAIResponseStyle(ResponseStyle style) async {
    if (!await _ensureInitialized()) return false;

    try {
      final updated = ai.copyWith(responseStyle: style);
      return await _repository.updateAISettings(updated);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.setAIResponseStyle',
      );
      return false;
    }
  }

  /// Update full AI settings
  Future<bool> updateAI(AiSettings newAI) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('ai', true);

    try {
      return await _repository.updateAISettings(newAI);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'SettingsProvider.updateAI');
      return false;
    } finally {
      _setOperationLoading('ai', false);
    }
  }

  // ============================================================
  // COMPETITION SETTINGS
  // ============================================================

  /// Update competition settings
  Future<bool> updateCompetitionSettings(CompetitionSettings newCompetition) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('competition', true);

    try {
      return await _repository.updateCompetitionSettings(newCompetition);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.updateCompetitionSettings',
      );
      return false;
    } finally {
      _setOperationLoading('competition', false);
    }
  }

  // ============================================================
  // ANALYTICS SETTINGS
  // ============================================================

  /// Update analytics settings
  Future<bool> updateAnalyticsSettings(AnalyticsSettings newAnalytics) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('analytics', true);

    try {
      return await _repository.updateAnalyticsSettings(newAnalytics);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.updateAnalyticsSettings',
      );
      return false;
    } finally {
      _setOperationLoading('analytics', false);
    }
  }

  /// Update mentoring settings
  Future<bool> updateMentoringSettings(MentoringSettings newMentoring) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('mentoring', true);

    try {
      return await _repository.updateMentoringSettings(newMentoring);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.updateMentoringSettings',
      );
      return false;
    } finally {
      _setOperationLoading('mentoring', false);
    }
  }

  // ============================================================
  // SECURITY SETTINGS
  // ============================================================

  /// Toggle biometric lock
  Future<bool> toggleBiometricLock() async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('biometric', true);

    try {
      final updated = security.copyWith(biometricLock: !security.biometricLock);
      return await _repository.updateSecuritySettings(updated);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.toggleBiometricLock',
      );
      return false;
    } finally {
      _setOperationLoading('biometric', false);
    }
  }

  /// Set app lock timeout
  Future<bool> setAppLockTimeout(int seconds) async {
    if (!await _ensureInitialized()) return false;

    try {
      final updated = security.copyWith(appLockTimeout: seconds);
      return await _repository.updateSecuritySettings(updated);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.setAppLockTimeout',
      );
      return false;
    }
  }

  /// Update full security settings
  Future<bool> updateSecurity(SecuritySettings newSecurity) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('security', true);

    try {
      return await _repository.updateSecuritySettings(newSecurity);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.updateSecurity',
      );
      return false;
    } finally {
      _setOperationLoading('security', false);
    }
  }

  // ============================================================
  // LOCALIZATION SETTINGS
  // ============================================================

  /// Set language
  Future<bool> setLanguage(String language) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('language', true);

    try {
      final updated = localization.copyWith(language: language);
      final success = await _repository.updateLocalizationSettings(updated);

      if (success) {
        ErrorHandler.showInfoSnackbar(
          'App will restart to apply changes',
          title: 'Language Changed',
        );
      }

      return success;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'SettingsProvider.setLanguage');
      return false;
    } finally {
      _setOperationLoading('language', false);
    }
  }

  /// Set time format
  Future<bool> setTimeFormat(TimeFormat format) async {
    if (!await _ensureInitialized()) return false;

    try {
      final updated = localization.copyWith(timeFormat: format);
      return await _repository.updateLocalizationSettings(updated);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'SettingsProvider.setTimeFormat');
      return false;
    }
  }

  /// Update full localization settings
  Future<bool> updateLocalization(LocalizationSettings newLocalization) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('localization', true);

    try {
      return await _repository.updateLocalizationSettings(newLocalization);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.updateLocalization',
      );
      return false;
    } finally {
      _setOperationLoading('localization', false);
    }
  }

  // ============================================================
  // ACCESSIBILITY SETTINGS
  // ============================================================

  /// Update accessibility settings
  Future<bool> updateAccessibility(
    AccessibilitySettings newAccessibility,
  ) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('accessibility', true);

    try {
      return await _repository.updateAccessibilitySettings(newAccessibility);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.updateAccessibility',
      );
      return false;
    } finally {
      _setOperationLoading('accessibility', false);
    }
  }

  // ============================================================
  // EXPERIMENTAL SETTINGS
  // ============================================================

  /// Update experimental settings
  Future<bool> updateExperimental(ExperimentalSettings newExperimental) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('experimental', true);

    try {
      return await _repository.updateExperimentalSettings(newExperimental);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.updateExperimental',
      );
      return false;
    } finally {
      _setOperationLoading('experimental', false);
    }
  }

  /// Update data storage settings
  Future<bool> updateDataStorage(DataStorageSettings newDataStorage) async {
    if (!await _ensureInitialized()) return false;

    return _executeWithOptimisticUpdate(
      operationName: 'dataStorage',
      oldValue: dataStorage,
      newValue: newDataStorage,
      updateCache: (value) {
        if (_settings != null) {
          _settings = _settings!.copyWith(dataStorage: value);
          notifyListeners();
        }
      },
      execute: () => _repository.updateDataStorageSettings(newDataStorage),
    );
  }

  // ============================================================
  // RESET OPERATIONS
  // ============================================================

  /// Reset all settings
  Future<bool> resetAllSettings() async {
    if (!await _ensureInitialized()) return false;

    _setLoading(true);

    try {
      final success = await _repository.resetAllSettings();

      if (success) {
        // ⭐ Reset local preferences (Nav Mode) as well
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('navigationMode');
        _navigationBarType = NavigationBarType.personal;

        await reload();
        logI('All settings reset to defaults');
      }

      return success;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.resetAllSettings',
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset specific category_model
  Future<bool> resetCategory(String category) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('reset_$category', true);

    try {
      final success = await _repository.resetCategory(category);

      if (success) {
        await reload();
        logI('$category settings reset to defaults');
      }

      return success;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'SettingsProvider.resetCategory');
      return false;
    } finally {
      _setOperationLoading('reset_$category', false);
    }
  }

  // ============================================================
  // EXPORT/IMPORT
  // ============================================================

  /// Export settings to file
  Future<File?> exportSettingsToFile() async {
    if (!_canPerformOperation()) return null;

    _setOperationLoading('export', true);

    try {
      final data = await _repository.exportSettings();
      if (data == null) return null;

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/settings_backup_$timestamp.json');

      // Write to file
      await file.writeAsString(jsonEncode(data));

      logI('Settings exported to: ${file.path}');
      ErrorHandler.showSuccessSnackbar('Settings exported successfully');

      return file;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.exportSettingsToFile',
      );
      ErrorHandler.showErrorSnackbar('Failed to export settings');
      return null;
    } finally {
      _setOperationLoading('export', false);
    }
  }

  /// Import settings from file
  Future<bool> importSettingsFromFile(File file) async {
    if (!await _ensureInitialized()) return false;

    _setOperationLoading('import', true);

    try {
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final success = await _repository.importSettings(data);

      if (success) {
        await reload();
        logI('Settings imported successfully');
      }

      return success;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.importSettingsFromFile',
      );
      ErrorHandler.showErrorSnackbar('Failed to import settings');
      return false;
    } finally {
      _setOperationLoading('import', false);
    }
  }

  /// Export settings as shareable JSON string
  Future<String?> exportSettingsAsJson() async {
    if (!_canPerformOperation()) return null;

    try {
      final data = await _repository.exportSettings();
      return data != null ? jsonEncode(data) : null;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.exportSettingsAsJson',
      );
      return null;
    }
  }

  /// Import settings from JSON string
  Future<bool> importSettingsFromJson(String jsonString) async {
    if (!await _ensureInitialized()) return false;

    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final success = await _repository.importSettings(data);

      if (success) {
        await reload();
      }

      return success;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'SettingsProvider.importSettingsFromJson',
      );
      ErrorHandler.showErrorSnackbar('Invalid settings data');
      return false;
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Ensure settings are initialized before operation
  Future<bool> _ensureInitialized() async {
    if (_isInitialized) return true;
    
    // Attempt auto-initialization if user is logged in
    if (_repository.currentUserId != null) {
      logD('Settings not initialized, attempting auto-initialization...');
      return await initialize();
    }

    logW('Cannot perform operation: Settings not initialized');
    return false;
  }

  /// Check if operation can be performed (Sync version for UI)
  bool _canPerformOperation() {
    if (!_isInitialized) {
      // Attempt auto-initialization if user is logged in
      if (_repository.currentUserId != null) {
        logD('Settings not initialized, triggering auto-initialization...');
        initialize(); // Fire and forget for sync calls
      }
      return false;
    }

    if (_settings == null) {
      logW('No settings available');
      return false;
    }

    return true;
  }

  /// Update settings and cache values
  void _updateSettings(UserSettings newSettings) {
    _settings = newSettings;

    // Update cached values
    _currentThemeMode = newSettings.appearance.theme;
    _isDarkMode = newSettings.appearance.theme == ThemeMode.dark;
    _accentColor = newSettings.appearance.accentColor;
    _notificationsEnabled = newSettings.notifications.enabled;

    _checkQuietHours();
    notifyListeners();
  }

  /// Check if currently in quiet hours
  void _checkQuietHours() {
    if (_settings == null) return;

    final quietHours = _settings!.notifications.quietHours;
    if (!quietHours.enabled) {
      _isInQuietHours = false;
      return;
    }

    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final currentDay = _getDayName(now.weekday);

    if (!quietHours.days.contains(currentDay)) {
      _isInQuietHours = false;
      return;
    }

    final start = quietHours.start;
    final end = quietHours.end;

    if (start.compareTo(end) <= 0) {
      _isInQuietHours =
          currentTime.compareTo(start) >= 0 && currentTime.compareTo(end) <= 0;
    } else {
      _isInQuietHours =
          currentTime.compareTo(start) >= 0 || currentTime.compareTo(end) <= 0;
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

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set operation-specific loading state
  void _setOperationLoading(String operation, bool loading) {
    _loadingStates[operation] = loading;
    notifyListeners();
  }

  /// Set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Check if notification should be sent
  Future<bool> shouldSendNotification(String channel, {String? type}) async {
    if (!_notificationsEnabled) return false;
    if (_isInQuietHours) return false;

    return await _repository.shouldSendNotification(channel, type: type);
  }

  /// Check if feature is enabled
  bool isFeatureEnabled(String feature) =>
      _repository.isFeatureEnabled(feature);

  /// Get current locale
  Locale getLocale() {
    final languageCode = localization.language.split('_').first;
    final countryCode = localization.language.split('_').length > 1
        ? localization.language.split('_').last
        : null;
    return Locale(languageCode, countryCode);
  }

  /// Get supported locales
  List<Locale> get supportedLocales => const [
    Locale('en', 'US'),
    Locale('es', 'ES'),
    Locale('fr', 'FR'),
    Locale('de', 'DE'),
    Locale('it', 'IT'),
    Locale('pt', 'BR'),
    Locale('ru', 'RU'),
    Locale('zh', 'CN'),
    Locale('ja', 'JP'),
    Locale('ko', 'KR'),
  ];

  /// Get localization delegates
  List<LocalizationsDelegate> get localizationsDelegates => const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  ThemeData _buildThemeData(Brightness brightness) {
    ThemeData baseTheme = brightness == Brightness.dark
        ? AppTheme.getDarkTheme()
        : AppTheme.getLightTheme();

    if (appearance.colorScheme == ColorScheme.defaultScheme &&
        appearance.fontFamily == 'system' &&
        appearance.fontSize == FontSize.medium) {
      return baseTheme;
    }

    Color seedColor;
    if (appearance.colorScheme == ColorScheme.custom) {
      try {
        seedColor = Color(int.parse(_accentColor.replaceFirst('#', '0xFF')));
      } catch (e) {
        seedColor = const Color(0xFF6366F1);
      }
    } else {
      seedColor = baseTheme.colorScheme.primary;
    }

    final colorScheme = appearance.colorScheme == ColorScheme.custom
        ? material.ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: brightness,
          )
        : baseTheme.colorScheme;

    TextTheme textTheme = baseTheme.textTheme;
    double scaleFactor = 1.0;
    switch (appearance.fontSize) {
      case FontSize.small:
        scaleFactor = 0.85;
        break;
      case FontSize.large:
        scaleFactor = 1.15;
        break;
      case FontSize.extraLarge:
        scaleFactor = 1.30;
        break;
      case FontSize.medium:
        scaleFactor = 1.0;
    }

    if (scaleFactor != 1.0) {
      textTheme = textTheme.apply(fontSizeFactor: scaleFactor);
    }

    return baseTheme.copyWith(colorScheme: colorScheme, textTheme: textTheme);
  }

  ThemeData getThemeDataForBrightness(Brightness brightness) {
    return _buildThemeData(brightness);
  }

  ThemeData getThemeData(BuildContext context) {
    final effectiveBrightness = getEffectiveBrightness(context);
    return _buildThemeData(effectiveBrightness);
  }

  /// Get the system brightness for theme mode
  Brightness getEffectiveBrightness(BuildContext context) {
    switch (_currentThemeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return MediaQuery.platformBrightnessOf(context);
    }
  }

  /// Clear all cached data (for logout)
  void clearCache() {
    _repository.clearCache();
    _settings = null;
    _isInitialized = false;
    _currentThemeMode = ThemeMode.system;
    _isDarkMode = false;
    _accentColor = '#6366f1';
    _notificationsEnabled = true;
    _isInQuietHours = false;
    _loadingStates.clear();
    _navigationBarType = NavigationBarType.personal;
    _clearError();
    notifyListeners();
    logI('Settings provider cache cleared');
  }

  // ============================================================
  // STORAGE METRICS
  // ============================================================

  Future<void> refreshStorageMetrics() async {
    try {
      final dbSize = await PowerSyncService().getDatabaseSize();
      final cacheSize = await UniversalMediaService().getCacheSize();

      _databaseSizeMB = dbSize;
      _cacheSizeMB = cacheSize;
      
      notifyListeners();
      logD('Storage metrics refreshed: DB=${dbSize.toStringAsFixed(2)}MB, Cache=${cacheSize.toStringAsFixed(2)}MB');
    } catch (e) {
      logW('Failed to refresh storage metrics: $e');
    }
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    _quietHoursTimer?.cancel();
    _repository.dispose();
    logI('Settings provider disposed');
    super.dispose();
  }
}

// Global instance
final settingsProvider = SettingsProvider();
