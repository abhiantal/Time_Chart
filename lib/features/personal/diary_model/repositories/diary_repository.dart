// lib/features/personal/diary_model/repositories/diary_repository.dart

import 'dart:convert';
import 'dart:io';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:uuid/uuid.dart';

import 'package:the_time_chart/widgets/error_handler.dart';
import '../../../../../widgets/logger.dart';
import '../../../../media_utility/universal_media_service.dart';

import 'package:the_time_chart/reward_tags/reward_manager.dart';

import '../models/diary_entry_model.dart';
import 'package:the_time_chart/services/powersync_service.dart';

class DiaryRepository {
  final PowerSyncService _powerSync;
  final UniversalMediaService _mediaService;
  static const String _tableName = 'diary_entries';

  static final DiaryRepository _instance = DiaryRepository._internal();
  factory DiaryRepository({PowerSyncService? powerSync, UniversalMediaService? mediaService}) {
    return _instance;
  }
  
  DiaryRepository._internal({PowerSyncService? powerSync, UniversalMediaService? mediaService})
      : _powerSync = powerSync ?? PowerSyncService(),
        _mediaService = mediaService ?? UniversalMediaService();

  final _jsonbColumns = [
    'mood',
    'shot_qna',
    'attachments',
    'linked_items',
    'settings',
    'metadata',
    'social_info',
    'share_info',
  ];

  // ================================================================
  // 🔍 VALIDATE ENTRY DATE
  // ================================================================
  Future<bool> _validateEntryDate(DateTime entryDate, String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(
      entryDate.year,
      entryDate.month,
      entryDate.day,
    );

    // 2. NO PAST OR FUTURE DATES
    if (dateToCheck.isBefore(today)) {
      AppSnackbar.error('Past entries are not allowed');
      return false;
    }
    if (dateToCheck.isAfter(today)) {
      AppSnackbar.error('Future entries are not allowed');
      return false;
    }

    // 1. ONLY ONE ENTRY PER DAY
    final existingEntry = await getEntryByDate(userId: userId, date: entryDate);
    if (existingEntry != null) {
      AppSnackbar.error('Only one entry per day is allowed');
      return false;
    }

    return true;
  }

  // ================================================================
  // 📝 CREATE DIARY ENTRY
  // ================================================================
  Future<DiaryEntryModel?> createEntry({
    required String userId,
    required DateTime entryDate,
    String? title,
    String? content,
    DiaryMood? mood,
    List<DiaryQnA>? shotQna,
    List<DiaryAttachment>? attachments,
    DiaryLinkedItems? linkedItems,
    DiarySettings? settings,
  }) async {
    try {
      if (userId.isEmpty) {
        logE(
          '❌ Action denied: Cannot create diary entry without active user session',
        );
        ErrorHandler.showErrorSnackbar(
          'You must be logged in to write a diary entry',
          title: 'Session Error',
        );
        return null;
      }

      if (!await _validateEntryDate(entryDate, userId)) {
        return null;
      }

      logI(
        '📝 Creating diary entry for date: ${entryDate.toIso8601String().split('T')[0]} locally...',
      );

      final wordCount =
          content?.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length ?? 0;

      final entryId = const Uuid().v4();
      final dateStr = entryDate.toIso8601String().split('T')[0];
      final now = DateTime.now();
      final nowStr = now.toIso8601String();

      final entryNumber = await _getNextEntryNumber(userId);
      final consistencyScore = await _calculateConsistencyScore(userId, entryNumber);

      final diaryProgress = DiaryEntryModel.calculateProgress(
        hasContent: content != null && content.trim().isNotEmpty,
        wordCount: wordCount,
        hasAttachments: attachments != null && attachments.isNotEmpty,
        attachmentCount: attachments?.length ?? 0,
        linkedItemsCount: linkedItems?.totalCount ?? 0,
        sentimentScore: mood?.score,
        consistencyScore: consistencyScore / 100.0,
        isOverdue: false, // Creating it now
      );

      // Points earned based on new rules
      final int pointsEarned = diaryProgress;

      // Calculate Rewards using universal formula
      final double progressRating = (1.0 + 4.0 * (pointsEarned / 500)).clamp(1.0, 5.0);
      final reward = RewardManager.calculate(
        progress: (pointsEarned / 5).clamp(0, 100).toDouble(),
        rating: progressRating,
        pointsEarned: pointsEarned,
        completedDays: (content != null && content.trim().isNotEmpty) ? 1 : 0,
        totalDays: 1,
        hoursPerDay: 0,
        taskStack: 0,
        source: RewardSource.diary,
        onTimeCompletion: content != null && content.trim().isNotEmpty,
      );

      // Determine task color based on mood rating
      String taskColor = 'medium';
      if (mood != null) {
        if (mood.rating >= 5) {
          taskColor = 'low'; // Positive mood
        } else if (mood.rating <= 2) {
          taskColor = 'high'; // Concern/Urgent attention
        }
      }

      final data = {
        'entry_id': entryId,
        'user_id': userId,
        'entry_date': dateStr,
        'title': title,
        'content': content,
        'mood':
            mood?.toJson() ??
            {'rating': 0, 'label': null, 'score': 0.0, 'emoji': null},
        'shot_qna': shotQna?.map((q) => q.toJson()).toList() ?? [],
        'attachments': attachments?.map((a) => a.toJson()).toList() ?? [],
        'linked_items':
            linkedItems?.toJson() ??
            {
              'long_goals': [],
              'day_tasks': [],
              'weekly_tasks': [],
              'bucket_items': [],
            },
        'settings':
            settings?.toJson() ??
            {'is_private': true, 'is_favorite': false, 'is_pinned': false},
        'entry_number': entryNumber,
        'metadata': {
          'task_color': taskColor,
          'reward_package': reward.toJson(),
          'word_count': wordCount,
          'has_attachments': attachments?.isNotEmpty ?? false,
          'sentiment_score': mood?.score,
          'consistency_score': consistencyScore,
          'ai_summary': null,
          'entry_number': entryNumber,
        },
        'social_info': {'is_posted': false, 'post_id': null, 'posted_at': null},
        'share_info': {
          'is_shared': false,
          'shared_with': [],
          'share_type': null,
          'shared_at': null,
        },
        'created_at': nowStr,
        'updated_at': nowStr,
      };

      // Prepare data for DB (use primary key 'id')
      final dataForDb = Map<String, dynamic>.from(data);
      dataForDb['id'] = entryId;
      dataForDb.remove('entry_id');
      dataForDb.remove('entry_number');

      await _powerSync.insert(_tableName, dataForDb);

      logI('✅ Diary entry created locally: $entryId');

      // Return the model
      return DiaryEntryModel.fromJson(data);
    } catch (e, stackTrace) {
      logE('❌ Error creating diary entry', error: e, stackTrace: stackTrace);
      ErrorHandler.handleError(e, stackTrace, 'Create diary entry');
      return null;
    }
  }

  // ================================================================
  // 📝 CREATE ENTRY WITH MEDIA
  // ================================================================
  Future<DiaryEntryModel?> createEntryWithMedia({
    required String userId,
    required DateTime entryDate,
    String? title,
    String? content,
    DiaryMood? mood,
    List<DiaryQnA>? shotQna,
    List<File>? mediaFiles,
    DiaryLinkedItems? linkedItems,
    DiarySettings? settings,
    Function(double)? onUploadProgress,
  }) async {
    try {
      logI(
        '📝 Creating diary entry with ${mediaFiles?.length ?? 0} media files',
      );

      List<DiaryAttachment> attachments = [];

      // Upload media files if provided (Offline First)
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        ErrorHandler.showLoading('Processing media...');

        logD('Starting media processing...');
        // uploadMultiple is offline-first: queues files and returns local paths/URLs
        final uploadedUrls = await _mediaService.uploadMultiple(
          files: mediaFiles,
          bucket: MediaBucket.diaryMedia,
          customPath: '$userId/diary/${entryDate.year}/${entryDate.month}',
          autoCompress: true,
          onProgress: onUploadProgress,
        );

        logI('✅ Processed ${uploadedUrls.length} media files');
        ErrorHandler.hideLoading();

        // Create DiaryAttachment objects from uploaded URLs (which might be local paths initially)
        for (int i = 0; i < uploadedUrls.length; i++) {
          final url = uploadedUrls[i];
          final file = mediaFiles[i];
          final mediaType = _detectMediaTypeFromFile(file);
          final fileName = file.path.split('/').last;
          final fileSize = await file.length();

          attachments.add(
            DiaryAttachment(
              id: 'att_${DateTime.now().millisecondsSinceEpoch}_$i',
              type: mediaType,
              url: url,
              fileName: fileName,
              fileSize: fileSize,
              mimeType: _getMimeType(fileName),
            ),
          );
        }
      }

      // Create the entry with structured attachments
      return await createEntry(
        userId: userId,
        entryDate: entryDate,
        title: title,
        content: content,
        mood: mood,
        shotQna: shotQna,
        attachments: attachments,
        linkedItems: linkedItems,
        settings: settings,
      );
    } catch (e, stackTrace) {
      ErrorHandler.hideLoading();
      logE(
        '❌ Error creating entry with media',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e, stackTrace, 'Create entry with media');
      return null;
    }
  }

  // ================================================================
  // 📎 ADD MEDIA TO EXISTING ENTRY
  // ================================================================
  Future<List<DiaryAttachment>?> addMediaToEntry({
    required String entryId,
    required List<File> mediaFiles,
    Function(double)? onProgress,
  }) async {
    try {
      logI('📎 Adding ${mediaFiles.length} media files to entry: $entryId');

      // Get current entry
      final entry = await getEntryById(entryId);
      if (entry == null) {
        logE('Entry not found: $entryId');
        ErrorHandler.showErrorSnackbar('Entry not found');
        return null;
      }

      ErrorHandler.showLoading('Uploading media...');

      // Upload new media
      final uploadedUrls = await _mediaService.uploadMultiple(
        files: mediaFiles,
        bucket: MediaBucket.diaryMedia,
        customPath:
            '${entry.userId}/diary/${entry.entryDate.year}/${entry.entryDate.month}',
        autoCompress: true,
        onProgress: onProgress,
      );

      ErrorHandler.hideLoading();

      if (uploadedUrls.isEmpty) {
        logW('No media uploaded');
        return null;
      }

      // Create new DiaryAttachment objects
      final newAttachments = <DiaryAttachment>[];
      for (int i = 0; i < uploadedUrls.length; i++) {
        final url = uploadedUrls[i];
        final file = mediaFiles[i];
        final mediaType = _detectMediaTypeFromFile(file);
        final fileName = file.path.split('/').last;
        final fileSize = await file.length();

        newAttachments.add(
          DiaryAttachment(
            id: 'att_${DateTime.now().millisecondsSinceEpoch}_$i',
            type: mediaType,
            url: url,
            fileName: fileName,
            fileSize: fileSize,
            mimeType: _getMimeType(fileName),
          ),
        );
      }

      // Merge with existing attachments
      final List<DiaryAttachment> allAttachments = [
        ...(entry.attachments ?? []),
        ...newAttachments,
      ];

      final attachmentsJson = allAttachments.map((a) => a.toJson()).toList();
      await _powerSync.update(_tableName, {
        'attachments': attachmentsJson,
      }, entryId);

      logI('✅ Added ${newAttachments.length} media files to entry');
      ErrorHandler.showSuccessSnackbar(
        'Media Added: ${newAttachments.length} files uploaded',
      );
      return allAttachments;
    } catch (e, stackTrace) {
      ErrorHandler.hideLoading();
      logE('❌ Error adding media to entry', error: e, stackTrace: stackTrace);
      ErrorHandler.handleError(e, stackTrace, 'Add media to entry');
      return null;
    }
  }

  // ================================================================
  // 🗑️ REMOVE MEDIA FROM ENTRY
  // ================================================================
  Future<bool> removeMediaFromEntry({
    required String entryId,
    required String attachmentId,
  }) async {
    try {
      logI('🗑️ Removing media from entry: $entryId');

      // Get current entry
      final entry = await getEntryById(entryId);
      if (entry == null) {
        logE('Entry not found: $entryId');
        return false;
      }

      // Find attachment to delete
      final attachmentToDelete = entry.attachments?.firstWhere(
        (a) => a.id == attachmentId,
        orElse: () => DiaryAttachment(id: '', type: '', url: ''),
      );

      if (attachmentToDelete == null || attachmentToDelete.id.isEmpty) {
        logW('Attachment not found: $attachmentId');
        return false;
      }

      // Delete from storage (try-catch as it might fail offline)
      try {
        final deleted = await _mediaService.deleteSingle(
          mediaUrl: attachmentToDelete.url,
          bucket: MediaBucket.diaryMedia,
        );

        if (!deleted) {
          logW('Failed to delete media from storage');
        }
      } catch (e) {
        logW('Offline or error deleting from storage: $e');
      }

      // Remove from entry
      final updatedAttachments =
          entry.attachments?.where((a) => a.id != attachmentId).toList() ?? [];

      final attachmentsJson = updatedAttachments
          .map((a) => a.toJson())
          .toList();
      await _powerSync.update(_tableName, {
        'attachments': attachmentsJson,
      }, entryId);
      final success = true;

      if (success) {
        logI('✅ Media removed from entry');
        ErrorHandler.showSuccessSnackbar('Media Removed Attachment deleted');
      }

      return success;
    } catch (e, stackTrace) {
      logE(
        '❌ Error removing media from entry',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e, stackTrace, 'Remove media from entry');
      return false;
    }
  }

  // ================================================================
  // 🤖 UPDATE AI SUMMARY
  // ================================================================
  Future<bool> updateAISummary({
    required String entryId,
    required String summary,
  }) async {
    try {
      logD('🤖 Updating AI summary for entry: $entryId');

      final entry = await getEntryById(entryId);
      final currentMeta = entry?.metadata?.toJson() ?? {};

      final updatedMeta = {...currentMeta, 'ai_summary': summary};

      await _powerSync.update(_tableName, {'metadata': updatedMeta}, entryId);

      logI('✅ AI summary updated locally for entry: $entryId');
      return true;
    } catch (e, stackTrace) {
      logE('❌ Error updating AI summary', error: e, stackTrace: stackTrace);
      ErrorHandler.handleError(e, stackTrace, 'Update AI summary');
      return false;
    }
  }

  // ================================================================
  // 👤 GET USER ENTRIES
  // ================================================================
  Future<List<DiaryEntryModel>> getUserEntries(
    String userId, {
    int limit = 100,
  }) async {
    try {
      logD('👤 Fetching entries for user: $userId');

      return await getAllEntries(
        userId: userId,
        limit: limit,
        orderBy: 'entry_date',
        ascending: false,
      );
    } catch (e, stackTrace) {
      logE('❌ Error fetching user entries', error: e, stackTrace: stackTrace);
      ErrorHandler.handleError(e, stackTrace, 'Get user entries');
      return [];
    }
  }

  // ================================================================
  // 👤 WATCH USER ENTRIES (REAL-TIME STREAM)
  // ================================================================
  Stream<List<DiaryEntryModel>> watchUserEntries(
    String userId, {
    int limit = 100,
  }) {
    logD('👤 Watching entries for user: $userId');
    return _powerSync
        .watchQuery(
          'SELECT * FROM $_tableName WHERE user_id = ? ORDER BY entry_date DESC LIMIT ?',
          parameters: [userId, limit],
        )
        .map((results) {
          return results
              .map(
                (row) => DiaryEntryModel.fromJson(
                  _powerSync.parseJsonbFields(row, _jsonbColumns),
                ),
              )
              .toList();
        });
  }

  // ================================================================
  // 📖 GET ENTRY BY DATE
  // ================================================================
  Future<DiaryEntryModel?> getEntryByDate({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      logD('📖 Fetching entry for date: $dateStr');

      final results = await _powerSync.executeQuery(
        'SELECT * FROM $_tableName WHERE user_id = ? AND entry_date = ?',
        parameters: [userId, dateStr],
      );

      if (results.isEmpty) {
        logD('ℹ️ No entry found for date: $dateStr');
        return null;
      }

      logD('✅ Entry found for date: $dateStr');
      return DiaryEntryModel.fromJson(
        _powerSync.parseJsonbFields(results.first, _jsonbColumns),
      );
    } catch (e, stackTrace) {
      logE('❌ Error fetching entry by date', error: e, stackTrace: stackTrace);
      ErrorHandler.handleError(e, stackTrace, 'Get entry by date');
      return null;
    }
  }

  // ================================================================
  // 📖 GET ENTRY BY ID
  // ================================================================
  Future<DiaryEntryModel?> getEntryById(String entryId) async {
    try {
      logD('📖 Fetching entry by ID: $entryId');

      final results = await _powerSync.getById(_tableName, entryId);

      if (results == null) return null;

      logD('✅ Entry fetched: $entryId');
      return DiaryEntryModel.fromJson(
        _powerSync.parseJsonbFields(results, _jsonbColumns),
      );
    } catch (e, stackTrace) {
      logE('❌ Error fetching entry by ID', error: e, stackTrace: stackTrace);
      ErrorHandler.handleError(e, stackTrace, 'Get entry by ID');
      return null;
    }
  }

  // ================================================================
  // 📚 GET ALL ENTRIES
  // ================================================================
  Future<List<DiaryEntryModel>> getAllEntries({
    required String userId,
    int limit = 50,
    int offset = 0,
    String orderBy = 'entry_date',
    bool ascending = false,
  }) async {
    try {
      logD('📚 Fetching all entries (limit: $limit, offset: $offset)');

      final results = await _powerSync.executeQuery(
        'SELECT * FROM $_tableName WHERE user_id = ? ORDER BY $orderBy ${ascending ? "ASC" : "DESC"} LIMIT ? OFFSET ?',
        parameters: [userId, limit, offset],
      );

      final entries = results
          .map(
            (row) => DiaryEntryModel.fromJson(
              _powerSync.parseJsonbFields(row, _jsonbColumns),
            ),
          )
          .toList();

      logI('✅ Fetched ${entries.length} entries');
      return entries;
    } catch (e, stackTrace) {
      logE('❌ Error fetching all entries', error: e, stackTrace: stackTrace);
      ErrorHandler.handleError(e, stackTrace, 'Get all entries');
      return [];
    }
  }

  // ================================================================
  // 📅 GET ENTRIES BY DATE RANGE
  // ================================================================
  Future<List<DiaryEntryModel>> getEntriesByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startStr = startDate.toIso8601String().split('T')[0];
      final endStr = endDate.toIso8601String().split('T')[0];

      logD('📅 Fetching entries from $startStr to $endStr');

      final results = await _powerSync.executeQuery(
        'SELECT * FROM $_tableName WHERE user_id = ? AND entry_date >= ? AND entry_date <= ? ORDER BY entry_date DESC',
        parameters: [userId, startStr, endStr],
      );

      final entries = results
          .map(
            (row) => DiaryEntryModel.fromJson(
              _powerSync.parseJsonbFields(row, _jsonbColumns),
            ),
          )
          .toList();

      logI('✅ Fetched ${entries.length} entries in date range');
      return entries;
    } catch (e, stackTrace) {
      logE(
        '❌ Error fetching entries by date range',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e, stackTrace, 'Get entries by date range');
      return [];
    }
  }

  // ================================================================
  // 🔍 SEARCH ENTRIES
  // ================================================================
  Future<List<DiaryEntryModel>> searchEntries({
    required String userId,
    required String query,
    int limit = 20,
  }) async {
    try {
      logD('🔍 Searching entries for: "$query"');

      final results = await _powerSync.executeQuery(
        'SELECT * FROM $_tableName WHERE user_id = ? AND (title LIKE ? OR content LIKE ?) ORDER BY entry_date DESC LIMIT ?',
        parameters: [userId, '%$query%', '%$query%', limit],
      );

      final entries = results
          .map(
            (row) => DiaryEntryModel.fromJson(
              _powerSync.parseJsonbFields(row, _jsonbColumns),
            ),
          )
          .toList();

      logI('✅ Found ${entries.length} entries for query: "$query"');
      return entries;
    } catch (e, stackTrace) {
      logE('❌ Error searching entries', error: e, stackTrace: stackTrace);
      ErrorHandler.handleError(e, stackTrace, 'Search entries');
      return [];
    }
  }

  // ================================================================
  // ⭐ TOGGLE FAVORITE
  // ================================================================
  Future<bool> toggleFavorite(String entryId, bool isFavorite) async {
    try {
      final entry = await getEntryById(entryId);
      if (entry == null) return false;

      final newSettings =
          entry.settings?.copyWith(isFavorite: isFavorite) ??
          DiarySettings(
            isFavorite: isFavorite,
            isPinned: false,
            isPrivate: true,
          );

      await _powerSync.update(_tableName, {
        'settings': newSettings.toJson(),
      }, entryId);
      return true;
    } catch (e, stackTrace) {
      logE('❌ Error toggling favorite', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // ================================================================
  // 📌 TOGGLE PINNED
  // ================================================================
  Future<bool> togglePinned(String entryId, bool isPinned) async {
    try {
      final entry = await getEntryById(entryId);
      if (entry == null) return false;

      final newSettings =
          entry.settings?.copyWith(isPinned: isPinned) ??
          DiarySettings(isFavorite: false, isPinned: isPinned, isPrivate: true);

      await _powerSync.update(_tableName, {
        'settings': newSettings.toJson(),
      }, entryId);
      return true;
    } catch (e, stackTrace) {
      logE('❌ Error toggling pinned', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // ================================================================
  // ⭐ GET FAVORITE ENTRIES
  // ================================================================
  Future<List<DiaryEntryModel>> getFavoriteEntries({
    required String userId,
    int limit = 20,
  }) async {
    try {
      logD('⭐ Fetching favorite entries');

      final results = await _powerSync.executeQuery(
        "SELECT * FROM $_tableName WHERE user_id = ? AND json_extract(settings, '\$.is_favorite') = 1 ORDER BY entry_date DESC LIMIT ?",
        parameters: [userId, limit],
      );

      final entries = results
          .map(
            (row) => DiaryEntryModel.fromJson(
              _powerSync.parseJsonbFields(row, _jsonbColumns),
            ),
          )
          .toList();

      logI('✅ Fetched ${entries.length} favorite entries');
      return entries;
    } catch (e, stackTrace) {
      logE(
        '❌ Error fetching favorite entries',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e, stackTrace, 'Get favorite entries');
      return [];
    }
  }

  // ================================================================
  // 📌 GET PINNED ENTRIES
  // ================================================================
  Future<List<DiaryEntryModel>> getPinnedEntries({
    required String userId,
  }) async {
    try {
      logD('📌 Fetching pinned entries');

      final results = await _powerSync.executeQuery(
        "SELECT * FROM $_tableName WHERE user_id = ? AND json_extract(settings, '\$.is_pinned') = 1 ORDER BY entry_date DESC",
        parameters: [userId],
      );

      final entries = results
          .map(
            (row) => DiaryEntryModel.fromJson(
              _powerSync.parseJsonbFields(row, _jsonbColumns),
            ),
          )
          .toList();

      logI('✅ Fetched ${entries.length} pinned entries');
      return entries;
    } catch (e, stackTrace) {
      logE('❌ Error fetching pinned entries', error: e, stackTrace: stackTrace);
      ErrorHandler.handleError(e, stackTrace, 'Get pinned entries');
      return [];
    }
  }

  // ================================================================
  // 📈 STATS HELPERS
  // ================================================================

  Future<int> _getNextEntryNumber(String userId) async {
    final result = await _powerSync.executeQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE user_id = ?',
      parameters: [userId],
    );
    final count = (result.first['count'] as num?)?.toInt() ?? 0;
    return count + 1;
  }

  Future<double> _calculateConsistencyScore(String userId, int currentEntriesCount) async {
    try {
      final firstEntryResult = await _powerSync.executeQuery(
        'SELECT entry_date FROM $_tableName WHERE user_id = ? ORDER BY entry_date ASC LIMIT 1',
        parameters: [userId],
      );

      final dateStr = firstEntryResult.first['entry_date']?.toString();
      if (dateStr == null) return 100.0;
      final firstDate = DateTime.tryParse(dateStr);
      if (firstDate == null) return 100.0;
      final now = DateTime.now();
      final totalDays = now.difference(firstDate).inDays + 1;

      if (totalDays <= 0) return 100.0;

      return (currentEntriesCount / totalDays * 100).clamp(0.0, 100.0);
    } catch (e) {
      logW('Error calculating consistency score: $e');
      return 100.0;
    }
  }

  // ================================================================
  // 😊 GET ENTRIES BY MOOD
  // ================================================================
  Future<List<DiaryEntryModel>> getEntriesByMood({
    required String userId,
    required String moodLabel,
    int limit = 20,
  }) async {
    try {
      logD('😊 Fetching entries with mood: $moodLabel');

      final results = await _powerSync.executeQuery(
        "SELECT * FROM $_tableName WHERE user_id = ? AND json_extract(mood, '\$.label') = ? ORDER BY entry_date DESC LIMIT ?",
        parameters: [userId, moodLabel, limit],
      );

      final entries = results
          .map(
            (row) => DiaryEntryModel.fromJson(
              _powerSync.parseJsonbFields(row, _jsonbColumns),
            ),
          )
          .toList();

      logI('✅ Fetched ${entries.length} entries with mood: $moodLabel');
      return entries;
    } catch (e, stackTrace) {
      logE(
        '❌ Error fetching entries by mood',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e, stackTrace, 'Get entries by mood');
      return [];
    }
  }

  // ================================================================
  // 📊 GET MOOD STATISTICS
  // ================================================================
  Future<Map<String, dynamic>> getMoodStatistics({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      logD('📊 Calculating mood statistics');

      String sql = 'SELECT mood, entry_date FROM $_tableName WHERE user_id = ?';
      final params = <dynamic>[userId];

      if (startDate != null) {
        sql += ' AND entry_date >= ?';
        params.add(startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        sql += ' AND entry_date <= ?';
        params.add(endDate.toIso8601String().split('T')[0]);
      }

      final results = await _powerSync.executeQuery(sql, parameters: params);

      final Map<String, int> moodCounts = {};
      int totalEntries = 0;
      double totalRating = 0;

      for (var row in results) {
        // Parse mood JSON
        Map<String, dynamic>? mood;
        if (row['mood'] is String) {
          try {
            mood = jsonDecode(row['mood'] as String);
          } catch (_) {}
        } else if (row['mood'] is Map) {
          mood = row['mood'] as Map<String, dynamic>;
        }

        if (mood != null) {
          final label = mood['label'] as String?;
          final rating = mood['rating'] as num?;

          if (label != null) {
            moodCounts[label] = (moodCounts[label] ?? 0) + 1;
          }

          if (rating != null) {
            totalRating += rating.toDouble();
            totalEntries++;
          }
        }
      }

      String? mostCommonMood;
      if (moodCounts.isNotEmpty) {
        mostCommonMood = moodCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      final averageRating = totalEntries > 0 ? totalRating / totalEntries : 0.0;

      return {
        'totalEntries': totalEntries,
        'averageRating': averageRating,
        'mostCommonMood': mostCommonMood,
        'moodCounts': moodCounts,
      };
    } catch (e, stackTrace) {
      logE(
        '❌ Error calculating mood statistics',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.handleError(e, stackTrace, 'Get mood statistics');
      return {};
    }
  }

  // ================================================================
  // 🗑️ DELETE ENTRY
  // ================================================================
  Future<bool> deleteEntry(String entryId) async {
    try {
      logW('🗑️ Deleting diary entry: $entryId');

      // 1. Get entry to check for media
      final entry = await getEntryById(entryId);
      if (entry != null && entry.attachments != null) {
        // 2. Delete media from storage
        for (final attachment in entry.attachments!) {
          try {
            await _mediaService.deleteSingle(
              mediaUrl: attachment.url,
              bucket: MediaBucket.diaryMedia,
            );
          } catch (e) {
            logW('Failed to delete media from storage during entry deletion: $e');
          }
        }
      }

      // 3. Delete from database
      await _powerSync.execute(
        'DELETE FROM $_tableName WHERE id = ?',
        [entryId],
      );

      logI('✅ Diary entry deleted: $entryId');
      ErrorHandler.showSuccessSnackbar('Diary entry deleted successfully');
      return true;
    } catch (e, stackTrace) {
      logE('❌ Error deleting diary entry', error: e, stackTrace: stackTrace);
      ErrorHandler.handleError(e, stackTrace, 'Delete diary entry');
      return false;
    }
  }

  // ================================================================
  // 🧹 CLEAR ALL ENTRIES (Debug/Dev)
  // ================================================================
  Future<void> clearAllEntries() async {
    try {
      logW('🧹 Clearing all diary entries...');
      await _powerSync.execute('DELETE FROM $_tableName');
      logI('✅ All diary entries cleared');
    } catch (e, stackTrace) {
      logE('❌ Error clearing all entries', error: e, stackTrace: stackTrace);
      ErrorHandler.handleError(e, stackTrace, 'Clear all entries');
    }
  }

  // ================================================================
  // 🛠️ HELPERS
  // ================================================================

  String _detectMediaTypeFromFile(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(ext)) {
      return 'image';
    }
    if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
      return 'video';
    }
    if (['mp3', 'wav', 'aac', 'm4a', 'flac'].contains(ext)) {
      return 'audio';
    }
    return 'file';
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }
}
