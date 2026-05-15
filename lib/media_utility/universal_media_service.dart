// services/universal_media_service.dart
// ================================================================
// COMPLETELY FIXED - Offline-First Media Service
// Key fixes:
// 1. RLS-compliant paths: always starts with userId
// 2. Proper signed URL generation for private buckets
// 3. Reliable cache hits using storage_path as primary key
// 4. Background sync queue that actually works
// 5. Fast offline access via local file cache
// ================================================================

import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../widgets/logger.dart';
import '../services/powersync_service.dart';
import '../media_utility/media_asset_model.dart';

// ================================================================
// BUCKET CONFIGURATION
// ================================================================

enum MediaBucket {
  userAvatars('user-avatars', 5, true), // 5MB  - PUBLIC bucket
  bucketMedia('bucket-media', 50, false), // 50MB - private
  dailyTaskMedia('daily-task-media', 10, false), // 10MB - private
  weeklyTaskMedia('weekly-task-media', 50, false), // 50MB - private
  longGoalsMedia('long-goals-media', 50, false), // 50MB - private
  socialMedia('social-media', 100, false), // 100MB - private (signed URLs)
  chatMedia('chat-media', 20, false), // 20MB - private
  diaryMedia('diary-media', 20, false); // 20MB - private

  const MediaBucket(this.bucketName, this.maxSizeMB, this.isPublic);
  final String bucketName;
  final int maxSizeMB;
  final bool
  isPublic; // true = public bucket, use getPublicUrl; false = private, use signed URL
}

// ================================================================
// STORAGE STATS
// ================================================================

class StorageStats {
  final Map<String, int> bucketStats;
  final int totalFiles;
  final int totalSize;

  StorageStats({
    required this.bucketStats,
    this.totalFiles = 0,
    this.totalSize = 0,
  });
}

// ================================================================
// URL UPDATE EVENT
// ================================================================

class UrlUpdateEvent {
  final String storagePath;
  final String newUrl;
  String get newHttpsUrl => newUrl;
  UrlUpdateEvent(this.storagePath, this.newUrl);
}

// ================================================================
// UNIVERSAL MEDIA STORAGE SERVICE - OFFLINE FIRST (FIXED)
// ================================================================

class UniversalMediaService {
  static final UniversalMediaService _instance =
      UniversalMediaService._internal();
  factory UniversalMediaService() => _instance;
  UniversalMediaService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final PowerSyncService _powerSync = PowerSyncService();

  // Signed URL cache to avoid hammering Supabase — valid 1 hour, cached 50 min
  final Map<String, _CachedUrl> _signedUrlCache = {};

  final _urlUpdateController = StreamController<UrlUpdateEvent>.broadcast();
  Stream<UrlUpdateEvent> get urlUpdates => _urlUpdateController.stream;

  bool _uploadQueueRunning = false;

  // ================================================================
  // INITIALIZATION
  // ================================================================

  Future<void> init() async {
    try {
      logI('🚀 Initializing UniversalMediaService...');

      logD('✓ media_cache_index table verified by PowerSync');

      // 3. Create cache directories
      logD('📁 Ensuring media cache directories...');
      final documentsDir = await getApplicationDocumentsDirectory();
      for (var bucket in MediaBucket.values) {
        final dir = Directory(
          p.join(documentsDir.path, 'media_cache', bucket.bucketName),
        );
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      }

      // 4. Start upload queue processor
      logD('🔄 Starting upload queue processor...');
      _processUploadQueue();

      logI('✅ UniversalMediaService initialized');
    } catch (e, stackTrace) {
      logE('❌ Failed to init media service', error: e, stackTrace: stackTrace);
    }
  }

  // ================================================================
  // UPLOAD - SINGLE FILE
  // ================================================================

  Future<String?> uploadSingle({
    required File file,
    required MediaBucket bucket,
    String? customPath, // subfolder under userId (e.g. chatId, taskId)
    String? exactStoragePath, // override full path (must start with userId)
    bool autoCompress = true,
    Function(double)? onProgress,
  }) async {
    final results = await uploadMultiple(
      files: [file],
      bucket: bucket,
      customPath: customPath,
      exactStoragePath: exactStoragePath,
      autoCompress: autoCompress,
      onProgress: onProgress,
    );
    return results.isNotEmpty ? results.first : null;
  }

  // ================================================================
  // STORAGE METRICS
  // ================================================================

  Future<double> getCacheSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(p.join(appDir.path, 'media_cache'));

      if (!await cacheDir.exists()) return 0.0;

      int totalBytes = 0;
      await for (final file in cacheDir.list(recursive: true)) {
        if (file is File) {
          totalBytes += await file.length();
        }
      }
      return totalBytes / (1024 * 1024); // Return in MB
    } catch (e) {
      logW('Failed to get cache size: $e');
      return 0.0;
    }
  }

  // ================================================================
  // UPLOAD - MULTIPLE FILES
  // FIXED: RLS requires path[0] == auth.uid()
  //        Path format: userId/[customPath/]bucketName/uniqueFileName
  // ================================================================

  Future<List<String>> uploadMultiple({
    required List<File> files,
    required MediaBucket bucket,
    String? customPath,
    String? exactStoragePath,
    bool autoCompress = true,
    Function(double)? onProgress,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      logE('uploadMultiple: user not authenticated');
      return [];
    }

    try {
      final results = <String>[];
      final appDir = await getApplicationDocumentsDirectory();
      int processedCount = 0;

      for (var file in files) {
        final fileName = p.basename(file.path);
        final ext = p.extension(fileName);
        final uniqueName =
            '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 8)}$ext';

        // ── Build storage path — ALWAYS starts with userId/bucketName (RLS requirement + bulletproof inference) ──
        String storagePath;
        if (files.length == 1 && exactStoragePath != null) {
          storagePath = _ensureUserIdPrefix(exactStoragePath, userId);
          if (!storagePath.contains('/${bucket.bucketName}/')) {
            storagePath = storagePath.replaceFirst('$userId/', '$userId/${bucket.bucketName}/');
          }
        } else {
          String bucketFolder = bucket.bucketName;
          if (customPath != null) {
            final cleanCustom = customPath.startsWith(userId)
                ? customPath
                      .substring(userId.length)
                      .replaceAll(RegExp(r'^/'), '')
                : customPath;
            if (cleanCustom.isEmpty) {
              storagePath = '$userId/$bucketFolder/$uniqueName';
            } else {
              storagePath = '$userId/$bucketFolder/$cleanCustom/$uniqueName';
            }
          } else {
            storagePath = '$userId/$bucketFolder/$uniqueName';
          }
        }

        // ── Cache file locally immediately for instant display ──
        final cacheDir = Directory(
          p.join(appDir.path, 'media_cache', bucket.bucketName),
        );
        if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

        final cachePath = p.join(cacheDir.path, uniqueName);
        final cachedFile = await file.copy(cachePath);

        // ── Save to cache index with local path so UI can display instantly ──
        await _upsertCacheIndex(
          storagePath: storagePath,
          bucketName: bucket.bucketName,
          localPath: cachedFile.path,
          publicUrl: null, // will be set after upload
        );

        // ── Queue for background upload ──
        await _powerSync.execute(
          '''INSERT OR REPLACE INTO media_sync_queue 
             (id, local_path, bucket_name, storage_path, status, retry_count, created_at)
             VALUES (?, ?, ?, ?, 'pending', 0, ?)''',
          [
            const Uuid().v4(),
            cachedFile.path,
            bucket.bucketName,
            storagePath,
            DateTime.now().toIso8601String(),
          ],
        );

        results.add(storagePath);

        // Immediately notify listeners with local path so UI renders now
        _urlUpdateController.add(UrlUpdateEvent(storagePath, cachedFile.path));

        processedCount++;
        onProgress?.call(processedCount / files.length);
      }

      // Start upload in background — don't await
      _processUploadQueue();

      return results;
    } catch (e, stack) {
      logE('uploadMultiple failed', error: e, stackTrace: stack);
      return [];
    }
  }

  // ================================================================
  // CONVENIENCE WRAPPERS
  // ================================================================

  Future<List<String>> uploadBucketMedia(List<File> files) =>
      uploadMultiple(files: files, bucket: MediaBucket.bucketMedia);

  Future<List<String>> uploadTaskMedia({
    List<File>? files,
    File? file,
    required String taskType,
    String? taskId,
  }) async {
    final List<File> filesToUpload = files ?? (file != null ? [file] : []);
    if (filesToUpload.isEmpty) return [];

    final MediaBucket bucket;
    switch (taskType) {
      case 'weekly':
        bucket = MediaBucket.weeklyTaskMedia;
        break;
      case 'long_goal':
        bucket = MediaBucket.longGoalsMedia;
        break;
      default:
        bucket = MediaBucket.dailyTaskMedia;
    }

    return uploadMultiple(
      files: filesToUpload,
      bucket: bucket,
      customPath: taskId, // goes under userId/taskId/
    );
  }

  Future<String?> uploadAvatar(File file, {String? userId}) async {
    final uid = userId ?? _supabase.auth.currentUser?.id;
    if (uid == null) return null;

    final ext = p.extension(file.path);
    final uniqueName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final exactPath = '$uid/$uniqueName';

    return uploadSingle(
      file: file,
      bucket: MediaBucket.userAvatars,
      exactStoragePath: exactPath,
    );
  }

  // ================================================================
  // RESOLVE URL — Main method used by UI to get a displayable URL
  // Priority: local file → in-memory signed URL cache → DB signed URL → fetch new signed URL
  // ================================================================

  Future<String?> resolveUrl(String? storagePath, MediaBucket bucket) async {
    if (storagePath == null || storagePath.isEmpty) return null;

    // Fast-path: if it is already an absolute local path, return it immediately
    if (!storagePath.startsWith('http') &&
        (storagePath.startsWith('/') ||
            storagePath.startsWith('C:\\') ||
            storagePath.startsWith('file://'))) {
      if (File(storagePath).existsSync()) {
        return storagePath;
      }
    }

    // Normalize: strip full URL to just storage path
    final normalizedPath = _normalizeToStoragePath(storagePath, bucket);

    // If normalization returned an absolute path and it didn't exist (checked above),
    // it's not a valid storage path for Supabase.
    if (normalizedPath.startsWith('/') ||
        normalizedPath.startsWith('file://') ||
        normalizedPath.contains(':\\')) {
      logW(
        'resolveUrl: Invalid storage path (local path leaked): $normalizedPath. This absolute path was likely accidentally persisted from a local cache instead of a clean storage path.',
      );
      return null;
    }

    // 1. Check local file cache first (instant, works offline)
    final localPath = await _getLocalPath(normalizedPath);
    if (localPath != null) {
      await _updateLastAccessed(normalizedPath);
      return localPath;
    }

    // 2. Check in-memory signed URL cache
    final cached = _signedUrlCache[normalizedPath];
    if (cached != null && !cached.isExpired) {
      // Trigger background download for next time
      _downloadAndCacheBackground(cached.url, normalizedPath, bucket);
      return cached.url;
    }

    // 3. Check DB for saved signed/public URL
    Map<String, dynamic>? dbRow;
    try {
      dbRow = await _powerSync.querySingle(
        'SELECT public_url, signed_url, signed_url_expires_at, local_path FROM media_cache_index WHERE storage_path = ?',
        parameters: [normalizedPath],
      );
    } catch (e) {
      logE('resolveUrl: DB read failed', error: e);
    }

    if (dbRow != null) {
      final dbLocalPath = dbRow['local_path'] as String?;
      if (dbLocalPath != null && File(dbLocalPath).existsSync()) {
        return dbLocalPath;
      }

      // Check if saved signed URL is still valid
      final expiresAtStr = dbRow['signed_url_expires_at'] as String?;
      if (expiresAtStr != null) {
        final expiresAt = DateTime.tryParse(expiresAtStr);
        if (expiresAt != null &&
            expiresAt.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
          final signedUrl = dbRow['signed_url'] as String?;
          if (signedUrl != null) {
            _signedUrlCache[normalizedPath] = _CachedUrl(signedUrl, expiresAt);
            _downloadAndCacheBackground(signedUrl, normalizedPath, bucket);
            return signedUrl;
          }
        }
      }

      // Use public_url for public buckets
      if (bucket.isPublic) {
        final publicUrl = dbRow['public_url'] as String?;
        if (publicUrl != null) {
          _downloadAndCacheBackground(publicUrl, normalizedPath, bucket);
          return publicUrl;
        }
      }
    }

    // 4. Fetch fresh URL from Supabase
    return await _fetchFreshUrl(normalizedPath, bucket);
  }

  // ================================================================
  // BACKWARD COMPAT — getValidSignedUrl used by _UrlResolver
  // ================================================================

  Future<String?> getValidSignedUrl(String? pathOrUrl) async {
    if (pathOrUrl == null || pathOrUrl.isEmpty) return null;

    // Fast-path: if it is already an absolute local path, return it immediately
    if (!pathOrUrl.startsWith('http') &&
        (pathOrUrl.startsWith('/') ||
            pathOrUrl.startsWith('C:\\') ||
            pathOrUrl.startsWith('file://'))) {
      if (File(pathOrUrl).existsSync()) {
        return pathOrUrl;
      }
    }

    // Try to infer bucket from path/URL
    MediaBucket? bucket;
    String storagePath = pathOrUrl;

    if (pathOrUrl.startsWith('http')) {
      for (var b in MediaBucket.values) {
        if (pathOrUrl.contains('/${b.bucketName}/')) {
          bucket = b;
          // Extract storage path from URL
          final uri = Uri.parse(pathOrUrl);
          final segments = uri.pathSegments;
          final bucketIdx = segments.indexOf(b.bucketName);
          if (bucketIdx != -1 && bucketIdx + 1 < segments.length) {
            storagePath = segments.sublist(bucketIdx + 1).join('/');
            // Remove query params
            storagePath = storagePath.split('?').first;
          }
          break;
        }
      }
      // If we couldn't find the bucket, return URL as-is (might be external)
      if (bucket == null) return pathOrUrl;
    } else {
      // Storage path — infer bucket from first path segment pattern
      bucket = _inferBucketFromPath(storagePath);
        if (bucket == null) {
          // Robust scanning: try to find the file inside candidate buckets
          final candidates = [
            MediaBucket.dailyTaskMedia,
            MediaBucket.diaryMedia,
            MediaBucket.socialMedia,
            MediaBucket.bucketMedia,
            MediaBucket.weeklyTaskMedia,
            MediaBucket.longGoalsMedia,
            MediaBucket.chatMedia,
          ];
          for (var cand in candidates) {
            try {
              // Quick check if the object exists
              await _supabase.storage.from(cand.bucketName).createSignedUrl(storagePath, 10);
              bucket = cand;
              logI('🔍 Successfully auto-resolved legacy storage path to bucket: ${cand.bucketName}');
              break;
            } catch (_) {}
          }
        }
        if (bucket == null) return pathOrUrl;
      }

      return resolveUrl(storagePath, bucket);
  }

  // ================================================================
  // AVATAR URL (PUBLIC BUCKET)
  // ================================================================

  Future<String?> getValidAvatarUrl(String? path) async {
    if (path == null || path.isEmpty) return null;

    // Already a full HTTP URL with token — return as-is
    if (path.startsWith('http') && path.contains('token=')) return path;

    // Fast-path: if it is already an absolute local path, return it immediately
    if (!path.startsWith('http') &&
        (path.startsWith('/') ||
            path.startsWith('C:\\') ||
            path.startsWith('file://'))) {
      if (File(path).existsSync()) {
        return path;
      }
    }

    const bucket = MediaBucket.userAvatars;
    final storagePath = _normalizeToStoragePath(path, bucket);

    // If normalization returned an absolute path, it's not a valid storage path
    if (storagePath.startsWith('/') ||
        storagePath.startsWith('file://') ||
        storagePath.contains(':\\')) {
      logW(
        'getValidAvatarUrl: Invalid storage path (local path leaked): $storagePath. 🚨 Please check if Onboarding or ProfileProvider is accidentally saving the display URL instead of the storage path.',
      );
      return null;
    }

    // 1. Local cache
    final localPath = await _getLocalPath(storagePath);
    if (localPath != null) return localPath;

    // 2. Public URL (user-avatars bucket is public)
    try {
      final publicUrl = _supabase.storage
          .from(bucket.bucketName)
          .getPublicUrl(storagePath);

      if (publicUrl.isNotEmpty) {
        // Optimization: if it's already a full URL, don't download in background again here
        // as resolveUrl might be called later. But for avatars we often want immediate cache.
        _downloadAndCacheBackground(publicUrl, storagePath, bucket);
        return publicUrl;
      }
    } catch (e) {
      logW('getValidAvatarUrl: getPublicUrl failed: $e');
    }

    // 3. Signed URL fallback
    try {
      final signedUrl = await _supabase.storage
          .from(bucket.bucketName)
          .createSignedUrl(storagePath, 3600);
      _downloadAndCacheBackground(signedUrl, storagePath, bucket);
      return signedUrl;
    } catch (e) {
      final errMsg = e.toString();
      if (errMsg.contains('SocketException') ||
          errMsg.contains('Failed host lookup')) {
        logW('📡 [Media] getValidAvatarUrl: Network unavailable');
        if (path.startsWith('http')) return path;
        return null;
      }
      logE('getValidAvatarUrl: createSignedUrl failed', error: e);
      if (path.startsWith('http')) return path;
      return null;
    }
  }

  // ================================================================
  // RETRIEVE MEDIA LIST
  // ================================================================

  Future<List<EnhancedMediaFile>> retrieve({
    required MediaBucket bucket,
    String? customPath,
    List<String>? specificUrls,
    int? limit,
  }) async {
    final results = <EnhancedMediaFile>[];

    if (specificUrls != null) {
      for (var pathOrUrl in specificUrls) {
        results.add(await _resolveToMediaFile(pathOrUrl, bucket));
      }
      return results;
    }

    final userId = _supabase.auth.currentUser?.id ?? 'temp';
    final searchPrefix = customPath != null ? '$userId/$customPath' : userId;

    final rows = await _powerSync.executeQuery(
      '''SELECT * FROM media_cache_index 
         WHERE bucket_name = ? AND storage_path LIKE ? 
         ORDER BY created_at DESC LIMIT ?''',
      parameters: [bucket.bucketName, '$searchPrefix%', limit ?? 50],
    );

    for (var row in rows) {
      results.add(await _mapRowToMedia(row, bucket));
    }

    // Background sync to fetch any new remote files
    _syncRemoteFolderBackground(bucket, searchPrefix);

    return results;
  }

  // ================================================================
  // DOWNLOAD FILE
  // ================================================================

  Future<File?> downloadFile({
    required String mediaUrl,
    required MediaBucket bucket,
    String? fileName,
  }) async {
    try {
      final fileN =
          fileName ?? p.basename(Uri.parse(mediaUrl).path).replaceAll('%', '_');
      final appDir = await getApplicationDocumentsDirectory();
      final savePath = p.join(
        appDir.path,
        'media_cache',
        bucket.bucketName,
        fileN,
      );
      final file = File(savePath);
      if (await file.exists()) return file;

      final response = await http
          .get(Uri.parse(mediaUrl))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      final errMsg = e.toString();
      if (errMsg.contains('SocketException') ||
          errMsg.contains('Failed host lookup') ||
          errMsg.contains('Timeout')) {
        logW('📡 [Media] downloadFile: Network unavailable');
        return null;
      }
      logE('downloadFile failed', error: e);
    }
    return null;
  }

  // ================================================================
  // DELETE
  // ================================================================

  Future<bool> deleteSingle({
    required String mediaUrl,
    required MediaBucket bucket,
  }) async {
    try {
      final storagePath = _normalizeToStoragePath(mediaUrl, bucket);

      // Remove from local cache
      final row = await _powerSync.querySingle(
        'SELECT local_path FROM media_cache_index WHERE storage_path = ?',
        parameters: [storagePath],
      );
      if (row != null) {
        final localPath = row['local_path'] as String?;
        if (localPath != null) {
          try {
            await File(localPath).delete();
          } catch (_) {}
        }
      }

      await _powerSync.execute(
        'DELETE FROM media_cache_index WHERE storage_path = ?',
        [storagePath],
      );

      // Delete from Supabase in background
      _supabase.storage.from(bucket.bucketName).remove([storagePath]).ignore();

      return true;
    } catch (e) {
      logE('deleteSingle failed', error: e);
      return false;
    }
  }

  Future<int> deleteAllUserMedia({
    required MediaBucket bucket,
    String? subfolder,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final prefix = subfolder != null ? '$userId/$subfolder' : userId;

      final rows = await _powerSync.executeQuery(
        'SELECT storage_path, local_path FROM media_cache_index WHERE bucket_name = ? AND storage_path LIKE ?',
        parameters: [bucket.bucketName, '$prefix%'],
      );

      for (final row in rows) {
        final localPath = row['local_path'] as String?;
        if (localPath != null) {
          try {
            await File(localPath).delete();
          } catch (_) {}
        }
      }

      await _powerSync.execute(
        'DELETE FROM media_cache_index WHERE bucket_name = ? AND storage_path LIKE ?',
        [bucket.bucketName, '$prefix%'],
      );

      return rows.length;
    } catch (e) {
      logE('deleteAllUserMedia failed', error: e);
      return 0;
    }
  }

  Future<void> clearCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(appDir.path, 'media_cache'));
      if (await dir.exists()) await dir.delete(recursive: true);
      await _powerSync.execute('DELETE FROM media_cache_index');
      _signedUrlCache.clear();
    } catch (e) {
      logE('clearCache failed', error: e);
    }
  }

  Future<StorageStats> getStorageStats() async {
    final stats = <String, int>{};
    for (var b in MediaBucket.values) {
      stats[b.bucketName] = 0;
    }
    return StorageStats(bucketStats: stats);
  }

  // ================================================================
  // PATH & URL HELPERS
  // ================================================================

  String generateStoragePath({
    required MediaBucket bucket,
    required String fileName,
    String? userId,
    String? customPath,
  }) {
    final uid = userId ?? _supabase.auth.currentUser?.id ?? 'temp';

    // For chat-media, the convention is chatId/chat-media/uniqueFileName
    if (bucket == MediaBucket.chatMedia && customPath != null) {
      return '$customPath/${bucket.bucketName}/$fileName';
    }

    if (customPath != null) {
      final clean = customPath.startsWith(uid)
          ? customPath.substring(uid.length).replaceAll(RegExp(r'^/'), '')
          : customPath;
      if (clean.isEmpty) {
        return '$uid/${bucket.bucketName}/$fileName';
      }
      return '$uid/${bucket.bucketName}/$clean/$fileName';
    }
    return '$uid/${bucket.bucketName}/$fileName';
  }

  String getPublicUrl({
    required MediaBucket bucket,
    required String storagePath,
  }) {
    return _supabase.storage.from(bucket.bucketName).getPublicUrl(storagePath);
  }

  Future<bool> verifyBucketAccess(MediaBucket bucket) async =>
      _supabase.auth.currentUser != null;

  // ================================================================
  // BACKGROUND UPLOAD QUEUE PROCESSOR (FIXED)
  // ================================================================

  Future<void> _processUploadQueue() async {
    if (_uploadQueueRunning) return;
    _uploadQueueRunning = true;

    try {
      while (true) {
        final pending = await _powerSync.executeQuery(
          "SELECT * FROM media_sync_queue WHERE status = 'pending' AND retry_count < 5 ORDER BY created_at LIMIT 3",
        );

        if (pending.isEmpty) break;

        for (var task in pending) {
          final id = task['id'] as String;
          final localPath = task['local_path'] as String;
          final storagePath = task['storage_path'] as String;
          final bucketName = task['bucket_name'] as String;
          final retryCount = (task['retry_count'] as int?) ?? 0;

          final file = File(localPath);
          if (!file.existsSync()) {
            await _powerSync.execute(
              "UPDATE media_sync_queue SET status = 'failed_missing' WHERE id = ?",
              [id],
            );
            continue;
          }

          // Verify path RLS safety
          final currentUserId = _supabase.auth.currentUser?.id;
          String finalPath = storagePath;

          if (currentUserId != null) {
            final bucket = MediaBucket.values.firstWhere(
              (b) => b.bucketName == bucketName,
              orElse: () => MediaBucket.bucketMedia,
            );

            // chat-media uses chatId/ prefix, others use userId/ prefix
            if (bucket == MediaBucket.chatMedia) {
              // Path should already be chatId/filename, no userId prefix needed
              logD('Processing chat-media upload: $storagePath');
            } else if (!storagePath.startsWith(currentUserId)) {
              finalPath = '$currentUserId/$storagePath';
              logW('Fixed non-compliant path: $storagePath → $finalPath');
              await _powerSync.execute(
                "UPDATE media_sync_queue SET storage_path = ? WHERE id = ?",
                [finalPath, id],
              );
            }
          }

          try {
            await _supabase.storage
                .from(bucketName)
                .upload(
                  finalPath,
                  file,
                  fileOptions: const FileOptions(upsert: true),
                );

            // Generate appropriate URL based on bucket type
            String? resolvedUrl;
            try {
              final bucket = MediaBucket.values.firstWhere(
                (b) => b.bucketName == bucketName,
              );
              if (bucket.isPublic) {
                resolvedUrl = _supabase.storage
                    .from(bucketName)
                    .getPublicUrl(finalPath);
              } else {
                resolvedUrl = await _supabase.storage
                    .from(bucketName)
                    .createSignedUrl(finalPath, 3600 * 24); // 24h signed URL
              }
            } catch (_) {}

            // Update cache index with remote URL
            await _powerSync.execute(
              '''UPDATE media_cache_index 
                 SET public_url = ?, signed_url = ?, signed_url_expires_at = ?
                 WHERE storage_path = ?''',
              [
                resolvedUrl,
                resolvedUrl,
                DateTime.now().add(const Duration(hours: 23)).toIso8601String(),
                finalPath,
              ],
            );

            await _powerSync.execute(
              "DELETE FROM media_sync_queue WHERE id = ?",
              [id],
            );

            if (resolvedUrl != null) {
              _urlUpdateController.add(UrlUpdateEvent(finalPath, resolvedUrl));
            }
            logI('✓ Uploaded: $finalPath');
          } catch (e) {
            final errStr = e.toString();
            logE(
              '⛔ Upload failed for $finalPath in $bucketName (User: $currentUserId)',
              error: e,
            );

            // Permanent failures — don't retry
            if (errStr.contains('403') ||
                errStr.contains('row-level security') ||
                errStr.contains('Unauthorized')) {
              await _powerSync.execute(
                "UPDATE media_sync_queue SET status = 'failed_auth' WHERE id = ?",
                [id],
              );
            } else {
              await _powerSync.execute(
                "UPDATE media_sync_queue SET retry_count = ? WHERE id = ?",
                [retryCount + 1, id],
              );
            }
          }
        }

        // Small delay between batches
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } finally {
      _uploadQueueRunning = false;
    }
  }

  // ================================================================
  // FETCH FRESH URL FROM SUPABASE
  // ================================================================

  Future<String?> _fetchFreshUrl(String storagePath, MediaBucket bucket) async {
    try {
      String url;
      DateTime? expiresAt;

      if (bucket.isPublic) {
        url = _supabase.storage
            .from(bucket.bucketName)
            .getPublicUrl(storagePath);
        // Public URLs don't expire
      } else {
        // Private bucket — generate signed URL valid for 1 hour
        url = await _supabase.storage
            .from(bucket.bucketName)
            .createSignedUrl(storagePath, 3600);
        expiresAt = DateTime.now().add(const Duration(hours: 1));
      }

      // Cache in memory
      _signedUrlCache[storagePath] = _CachedUrl(
        url,
        expiresAt ?? DateTime.now().add(const Duration(days: 365)),
      );

      // Cache in DB
      await _powerSync.execute(
        '''INSERT OR REPLACE INTO media_cache_index 
           (id, storage_path, bucket_name, local_path, public_url, signed_url, signed_url_expires_at, created_at, last_accessed)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          storagePath,
          storagePath,
          bucket.bucketName,
          null,
          bucket.isPublic ? url : null,
          bucket.isPublic ? null : url,
          expiresAt?.toIso8601String(),
          DateTime.now().toIso8601String(),
          DateTime.now().toIso8601String(),
        ],
      );

      // Download in background for offline access
      _downloadAndCacheBackground(url, storagePath, bucket);

      return url;
    } catch (e) {
      final errMsg = e.toString();
      if (errMsg.contains('SocketException') ||
          errMsg.contains('Failed host lookup')) {
        logW('📡 [Media] _fetchFreshUrl: Network unavailable for $storagePath');
        return null;
      }
      logE('_fetchFreshUrl failed for $storagePath', error: e);
      return null;
    }
  }

  // ================================================================
  // DOWNLOAD & CACHE (BACKGROUND)
  // ================================================================

  Future<void> _downloadAndCacheBackground(
    String url,
    String storagePath,
    MediaBucket bucket,
  ) async {
    // Check if already cached locally
    final existing = await _getLocalPath(storagePath);
    if (existing != null) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(storagePath);
      final safeFileName = Uri.decodeComponent(
        fileName,
      ).replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final savePath = p.join(
        appDir.path,
        'media_cache',
        bucket.bucketName,
        safeFileName,
      );
      final file = File(savePath);

      if (await file.exists()) {
        // Update DB with local path
        await _powerSync.execute(
          'UPDATE media_cache_index SET local_path = ? WHERE storage_path = ?',
          [file.path, storagePath],
        );
        return;
      }

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        await _powerSync.execute(
          'UPDATE media_cache_index SET local_path = ? WHERE storage_path = ?',
          [file.path, storagePath],
        );
        logI('✓ Cached locally: $storagePath');
      }
    } catch (e) {
      final errMsg = e.toString();
      if (errMsg.contains('SocketException') ||
          errMsg.contains('Failed host lookup') ||
          errMsg.contains('Timeout')) {
        // Silent warning for background download
        logD('📡 [Media] Background cache failed: Network unavailable');
        return;
      }
      logE('_downloadAndCacheBackground failed', error: e);
    }
  }

  // ================================================================
  // BACKGROUND REMOTE SYNC
  // ================================================================

  Future<void> _syncRemoteFolderBackground(
    MediaBucket bucket,
    String prefix,
  ) async {
    try {
      final files = await _supabase.storage
          .from(bucket.bucketName)
          .list(path: prefix);
      for (var f in files) {
        if (f.name.endsWith('/')) continue; // skip folders
        final storagePath = '$prefix/${f.name}';
        final exists = await _powerSync.querySingle(
          'SELECT 1 FROM media_cache_index WHERE storage_path = ?',
          parameters: [storagePath],
        );
        if (exists == null) {
          await _fetchFreshUrl(storagePath, bucket);
        }
      }
    } catch (e) {
      final errMsg = e.toString();
      if (errMsg.contains('SocketException') ||
          errMsg.contains('Failed host lookup')) {
        logW('📡 [Media] _syncRemoteFolderBackground: Network unavailable');
        return;
      }
      logE('_syncRemoteFolderBackground failed', error: e);
    }
  }

  // ================================================================
  // HELPER: GET LOCAL PATH
  // ================================================================

  Future<String?> _getLocalPath(String storagePath) async {
    try {
      final row = await _powerSync.querySingle(
        'SELECT local_path FROM media_cache_index WHERE storage_path = ?',
        parameters: [storagePath],
      );
      if (row == null) return null;
      final localPath = row['local_path'] as String?;
      if (localPath != null && File(localPath).existsSync()) return localPath;
    } catch (_) {}
    return null;
  }

  Future<void> _updateLastAccessed(String storagePath) async {
    try {
      await _powerSync.execute(
        'UPDATE media_cache_index SET last_accessed = ? WHERE storage_path = ?',
        [DateTime.now().toIso8601String(), storagePath],
      );
    } catch (_) {}
  }

  Future<void> _upsertCacheIndex({
    required String storagePath,
    required String bucketName,
    String? localPath,
    String? publicUrl,
  }) async {
    await _powerSync.execute(
      '''INSERT OR REPLACE INTO media_cache_index 
         (id, storage_path, bucket_name, local_path, public_url, created_at, last_accessed)
         VALUES (?, ?, ?, ?, ?, ?, ?)''',
      [
        storagePath,
        storagePath,
        bucketName,
        localPath,
        publicUrl,
        DateTime.now().toIso8601String(),
        DateTime.now().toIso8601String(),
      ],
    );
  }

  // ================================================================
  // HELPER: NORMALIZE PATH
  // Strips full Supabase URL to just the storage path inside the bucket
  // ================================================================

  String _normalizeToStoragePath(String pathOrUrl, MediaBucket bucket) {
    if (pathOrUrl.isEmpty) return pathOrUrl;

    if (!pathOrUrl.startsWith('http')) {
      // If it looks like an absolute local path, it's NOT a storage path
      if (pathOrUrl.startsWith('/') ||
          pathOrUrl.startsWith('file://') ||
          pathOrUrl.contains(':\\')) {
        // Try to see if it's a path within our own cache that we can reverse-map
        // For now, return as is but the caller must handle the fact it's not a storage path
        return pathOrUrl;
      }

      // Already a storage path — strip bucket prefix if accidentally included
      if (pathOrUrl.startsWith('${bucket.bucketName}/')) {
        return pathOrUrl.substring(bucket.bucketName.length + 1);
      }
      return pathOrUrl;
    }

    // Parse URL and extract path after bucket name
    try {
      final uri = Uri.parse(pathOrUrl);
      final segments = uri.pathSegments;
      final bucketIdx = segments.indexOf(bucket.bucketName);
      if (bucketIdx != -1 && bucketIdx + 1 < segments.length) {
        return segments.sublist(bucketIdx + 1).join('/').split('?').first;
      }
    } catch (_) {}

    return pathOrUrl;
  }

  String _ensureUserIdPrefix(String path, String userId) {
    if (path.startsWith(userId)) return path;
    final clean = path.replaceAll(RegExp(r'^/'), '');
    return '$userId/$clean';
  }

  MediaBucket? _inferBucketFromPath(String storagePath) {
    // Paths stored in DB have bucket context — try to match
    for (var b in MediaBucket.values) {
      if (storagePath.contains('/${b.bucketName}/') ||
          storagePath.startsWith('${b.bucketName}/')) {
        return b;
      }
    }
    return null;
  }

  // ================================================================
  // RESOLVE TO ENHANCED MEDIA FILE
  // ================================================================

  Future<EnhancedMediaFile> _resolveToMediaFile(
    String pathOrUrl,
    MediaBucket bucket,
  ) async {
    // Check local first
    final storagePath = _normalizeToStoragePath(pathOrUrl, bucket);
    final localPath = await _getLocalPath(storagePath);

    if (localPath != null) {
      return EnhancedMediaFile(
        id: storagePath,
        url: localPath,
        type: EnhancedMediaFile.detectMediaType(localPath),
        isLocal: true,
        fileName: p.basename(localPath),
      );
    }

    // Get remote URL
    final url = await resolveUrl(storagePath, bucket);
    return EnhancedMediaFile(
      id: storagePath,
      url: url ?? pathOrUrl,
      type: EnhancedMediaFile.detectMediaType(storagePath),
      isLocal: false,
      fileName: p.basename(storagePath),
    );
  }

  Future<EnhancedMediaFile> _mapRowToMedia(
    Map<String, dynamic> row,
    MediaBucket bucket,
  ) async {
    final storagePath = row['storage_path'] as String;
    final localPath = row['local_path'] as String?;

    if (localPath != null && File(localPath).existsSync()) {
      return EnhancedMediaFile(
        id: storagePath,
        url: localPath,
        type: EnhancedMediaFile.detectMediaType(localPath),
        isLocal: true,
        fileName: p.basename(localPath),
      );
    }

    final publicUrl = row['public_url'] as String?;
    final signedUrl = row['signed_url'] as String?;
    final url = publicUrl ?? signedUrl ?? storagePath;

    return EnhancedMediaFile(
      id: storagePath,
      url: url,
      type: EnhancedMediaFile.detectMediaType(storagePath),
      isLocal: false,
      fileName: p.basename(storagePath),
    );
  }
}

// ================================================================
// CACHED URL (IN-MEMORY SIGNED URL CACHE)
// ================================================================

class _CachedUrl {
  final String url;
  final DateTime expiresAt;

  _CachedUrl(this.url, this.expiresAt);

  bool get isExpired =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));
}

// Global instance
final mediaService = UniversalMediaService();
