// ================================================================
// FILE: lib/services/powersync_service.dart
// ================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:sqlite_async/sqlite_async.dart';

import '../config/database_schema.dart';
import '../config/env_config.dart';
import '../widgets/logger.dart';

// ================================================================
// POWERSYNC SERVICE
// ================================================================

class PowerSyncService {
  static final PowerSyncService _instance = PowerSyncService._internal();
  late PowerSyncDatabase _db;
  late _SupabaseConnector _connector;

  bool _isInitialized = false;
  bool _isSyncConnected = false;
  bool _syncEnabled = false;
  bool _isOnline = true;

  final Map<String, List<Map<String, dynamic>>> _queryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Future<void>? _initializing;
  Future<void>? _connecting;
  StreamSubscription<SyncStatus>? _syncStatusSubscription;

  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  factory PowerSyncService() => _instance;
  PowerSyncService._internal() {
    _initConnectivityListener();
  }

  bool get isInitialized => _isInitialized;
  bool get isSyncConnected => _isSyncConnected;
  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;
  bool get isOnline => _isOnline;
  bool get isReady => _isInitialized;

  PowerSyncDatabase get db {
    if (!_isInitialized) {
      throw PowerSyncException(
        'PowerSync not initialized. Call initialize() first.',
      );
    }
    return _db;
  }

  Future<void> waitForReady() async {
    if (_isInitialized) return;
    if (_initializing != null) {
      await _initializing;
      return;
    }
    await Future.doWhile(() async {
      if (_isInitialized) return false;
      await Future.delayed(const Duration(milliseconds: 100));
      return true;
    });
  }

  // ================================================================
  // NETWORK & CONNECTIVITY
  // ================================================================

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((_) {
      checkConnectivity();
    });
    checkConnectivity();
  }

  Future<bool> checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _updateOnlineStatus(false);
      return false;
    }

    // ⭐ OPTIMIZATION: If we have ANY connectivity result (Wifi/Mobile), 
    // we should be optimistic. DNS lookup (lookup) can be blocked on some 
    // public/corporate Wi-Fi networks even if HTTP traffic works.
    
    final supabaseReachable = await PowerSyncService.checkSupabaseReachable();
    if (supabaseReachable) {
      _updateOnlineStatus(true);
      return true;
    }

    // Fallback: If DNS lookup for Supabase failed, try Google or just trust connectivity status
    if (await PowerSyncService.checkDNS()) {
      logW('⚠️ Supabase DNS failed but internet is available. Marking ONLINE.');
      _updateOnlineStatus(true);
      return true;
    }

    // FINAL FALLBACK: If Connectivity says we are on Wifi/Mobile, trust it 
    // but log a warning that lookup failed.
    logI('🌐 Connectivity exists (${connectivityResult.join(", ")}) but lookup failed. Proceeding as ONLINE.');
    _updateOnlineStatus(true);
    return true;
  }

  void _updateOnlineStatus(bool status) {
    final oldOnline = _isOnline;
    _isOnline = status;
    
    if (oldOnline != status) {
      logI(status ? '🌐 Network ONLINE' : '🔌 Network OFFLINE');
    }

    // ⭐ CRITICAL: If we are online, ensure sync is connected
    if (status && _syncEnabled && !_isSyncConnected) {
      logI('🔄 Re-connecting PowerSync (Network Available)...');
      _db.connect(connector: _connector).then((_) {
        _isSyncConnected = true;
      }).catchError((e) {
        logW('Re-connect attempt failed: $e');
        _isSyncConnected = false;
      });
    }
  }

  static Future<bool> checkDNS() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static Future<bool> checkSupabaseReachable() async {
    try {
      final uri = Uri.parse(EnvConfig.supabaseUrl);
      final result = await InternetAddress.lookup(uri.host);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> checkPowerSyncReachable() async {
    try {
      final uri = Uri.parse(EnvConfig.powerSyncUrl);
      if (uri.host.isEmpty) return false;
      final result = await InternetAddress.lookup(uri.host);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ================================================================
  // INITIALIZATION
  // ================================================================

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initializing != null) {
      await _initializing;
      return;
    }
    _initializing = _doInitialize();
    try {
      await _initializing;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _doInitialize() async {
    try {
      final dbPath = await _getDatabasePath();
      _db = PowerSyncDatabase(schema: schema, path: dbPath);
      _connector = _SupabaseConnector(this);

      await _db.initialize();
      
      // ⭐ CRITICAL: Run schema migrations before marking as initialized
      try {
        await _ensureColumnsExist();
      } catch (e) {
        logW('Post-initialization column check failed: $e');
      }

      _isInitialized = true;
      logI('✓ PowerSync initialized at: $dbPath');

      Future.microtask(() async {
        try {
          await _cleanupOrphanChatData();
          logD('✓ PowerSync background cleanup completed');
        } catch (e) {
          logW('PowerSync background cleanup failed (non-critical): $e');
        }
      });
    } catch (error, stackTrace) {
      logE('PowerSync Initialization Error', error: error, stackTrace: stackTrace);

      if (error.toString().contains('SqliteException') ||
          error.toString().contains('powersync_replace_schema')) {
        logW('Attempting to recover by clearing local database...');
        try {
          try { await _db.close(); } catch (_) {}
          await _deleteAllDatabaseFiles();

          _db = PowerSyncDatabase(schema: schema, path: await _getDatabasePath());
          _connector = _SupabaseConnector(this);
          await _db.initialize();
          await _cleanupOrphanChatData();
          _isInitialized = true;
          logI('✓ PowerSync re-initialized successfully');
          return;
        } catch (cleanupError) {
          logE('Failed to recover database', error: cleanupError);
        }
      }

      throw PowerSyncException('Failed to initialize PowerSync: $error');
    }
  }

  // ================================================================
  // SYNC CONNECTION
  // ================================================================

  Future<void> connectSync() async {
    if (!_isInitialized) throw PowerSyncException('PowerSync not initialized');
    if (_isSyncConnected) return;
    if (_connecting != null) {
      await _connecting;
      return;
    }
    _connecting = _doConnectSync();
    try {
      await _connecting;
    } finally {
      _connecting = null;
    }
  }

  Future<void> _doConnectSync() async {
    try {
      _syncEnabled = true;

      if (!await checkConnectivity()) {
        logW('⚠️ Network unavailable. Sync will automatically start when online.');
        return;
      }

      logI('🔗 Attempting PowerSync connection to: ${EnvConfig.powerSyncUrl}');

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        logI('⚠️ Cannot connect sync - user not authenticated');
        return;
      }

      await _db.connect(connector: _connector);
      _isSyncConnected = true;

      _syncStatusSubscription = _db.statusStream.listen(
            (status) => _syncStatusController.add(status),
        onError: (error) {
          final e = error.toString();
          if (e.contains('ClientException') ||
              e.contains('SocketException') ||
              e.contains('Connection closed') ||
              e.contains('Failed host lookup')) {
            logW('Sync connection interruption (will retry): $e');
          } else {
            logE('Sync status error', error: error);
          }
        },
      );

      logI('✓ PowerSync sync connected');
    } catch (error, stackTrace) {
      final e = error.toString();
      if (e.contains('Failed host lookup') ||
          e.contains('SocketException') ||
          e.contains('ClientException')) {
        logW('⚠️ PowerSync connect failed (network). Will retry when online: $e');
        _isSyncConnected = false;
        return;
      }
      logE('PowerSync Sync Connection Error', error: error, stackTrace: stackTrace);
      throw PowerSyncException('Failed to connect PowerSync sync: $error');
    }
  }

  // ================================================================
  // DISCONNECTION & CLEANUP
  // ================================================================

  Future<void> disconnectSync() async {
    try {
      _syncEnabled = false;
      if (_isSyncConnected) {
        await _syncStatusSubscription?.cancel();
        _syncStatusSubscription = null;
        await _db.disconnect();
        _isSyncConnected = false;
        logI('✓ PowerSync sync disconnected');
      }
    } catch (error) {
      logE('Disconnect sync error', error: error);
    }
  }

  Future<void> disconnect() async {
    try {
      if (_isInitialized) {
        await disconnectSync();
        try { await _db.close(); } catch (_) {}
        _isInitialized = false;
        _connectivitySubscription?.cancel();
        _queryCache.clear();
        _cacheTimestamps.clear();
        logI('✓ PowerSync fully disconnected');
      }
    } catch (error) {
      logE('Disconnect error', error: error);
    }
  }

  // ================================================================
  // CLEAR LOCAL DATA — FULLY WIPES ALL DB FILES ON DEVICE
  // ================================================================

  Future<void> clearLocalData({bool reinitialize = true}) async {
    try {
      logI('🧹 Starting deep local data wipe...');

      // 1. Disconnect and close DB handle first
      await disconnectSync();
      try { await _db.close(); } catch (_) {}
      _isInitialized = false;
      _queryCache.clear();
      _cacheTimestamps.clear();

      // 2. Delete every database file we can find
      await _deleteAllDatabaseFiles();

      // 3. Re-initialize so the app stays functional offline (if requested)
      if (reinitialize) {
        await initialize();
      }

      logI('✓ Clear local data completed.');
    } catch (e) {
      logE('Clear local data failed', error: e);
      throw PowerSyncException('Clear local data failed: $e');
    }
  }

  /// Deletes ALL SQLite / PowerSync database files across every location
  /// Android might write them to. This is the core fix for the "User data
  /// still showing 122 MB after clear" issue.
  Future<void> _deleteAllDatabaseFiles() async {
    final pathsToDelete = <String>{};

    // ── Primary path (getApplicationSupportDirectory) ──
    try {
      final supportDir = await getApplicationSupportDirectory();
      final primaryPath = p.join(supportDir.path, 'powersync_database.db');
      pathsToDelete.addAll([
        primaryPath,
        '$primaryPath-wal',
        '$primaryPath-shm',
      ]);

      // Scan the entire support dir for any .db files
      if (await supportDir.exists()) {
        await for (final entity in supportDir.list(recursive: true)) {
          if (entity is File) {
            final name = p.basename(entity.path).toLowerCase();
            if (name.endsWith('.db') ||
                name.endsWith('.db-wal') ||
                name.endsWith('.db-shm') ||
                name.endsWith('.sqlite') ||
                name.endsWith('.sqlite-wal') ||
                name.endsWith('.sqlite-shm') ||
                name.contains('powersync')) {
              pathsToDelete.add(entity.path);
            }
          }
        }
      }
    } catch (e) {
      logW('Support dir scan error (non-critical): $e');
    }

    // ── Android: databases/ directory (the real culprit for "User data") ──
    // Android stores SQLite files in  /data/data/<pkg>/databases/
    // path_provider does NOT expose this directly, but it is always
    // exactly one level up from getApplicationSupportDirectory() on Android.
    if (Platform.isAndroid) {
      try {
        final supportDir = await getApplicationSupportDirectory();
        final appDataRoot = supportDir.parent; // /data/data/<pkg>/

        // /data/data/<pkg>/databases/
        final databasesDir = Directory(p.join(appDataRoot.path, 'databases'));
        if (await databasesDir.exists()) {
          await for (final entity in databasesDir.list(recursive: true)) {
            if (entity is File) {
              pathsToDelete.add(entity.path);
            }
          }
          logI('Found Android databases/ dir: ${databasesDir.path}');
        }

        // /data/data/<pkg>/files/ (some PowerSync versions write here)
        final filesDir = Directory(p.join(appDataRoot.path, 'files'));
        if (await filesDir.exists()) {
          await for (final entity in filesDir.list(recursive: true)) {
            if (entity is File) {
              final name = p.basename(entity.path).toLowerCase();
              if (name.endsWith('.db') ||
                  name.endsWith('.db-wal') ||
                  name.endsWith('.db-shm') ||
                  name.endsWith('.sqlite') ||
                  name.contains('powersync')) {
                pathsToDelete.add(entity.path);
              }
            }
          }
        }

        // /data/data/<pkg>/app_flutter/ (Flutter's preferred files dir on old APIs)
        final flutterDir = Directory(p.join(appDataRoot.path, 'app_flutter'));
        if (await flutterDir.exists()) {
          await for (final entity in flutterDir.list(recursive: true)) {
            if (entity is File) {
              final name = p.basename(entity.path).toLowerCase();
              if (name.endsWith('.db') ||
                  name.endsWith('.sqlite') ||
                  name.contains('powersync')) {
                pathsToDelete.add(entity.path);
              }
            }
          }
        }
      } catch (e) {
        logW('Android databases/ scan error (non-critical): $e');
      }

      // Also check getApplicationDocumentsDirectory (maps to app_flutter on some devices)
      try {
        final docDir = await getApplicationDocumentsDirectory();
        if (await docDir.exists()) {
          await for (final entity in docDir.list(recursive: true)) {
            if (entity is File) {
              final name = p.basename(entity.path).toLowerCase();
              if (name.endsWith('.db') ||
                  name.endsWith('.db-wal') ||
                  name.endsWith('.db-shm') ||
                  name.endsWith('.sqlite') ||
                  name.contains('powersync')) {
                pathsToDelete.add(entity.path);
              }
            }
          }
        }
      } catch (e) {
        logW('Documents dir scan error (non-critical): $e');
      }
    }

    // ── Delete every file we collected ──
    int deleted = 0;
    int failed = 0;
    for (final path in pathsToDelete) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          logD('🗑️ Deleted: $path');
          deleted++;
        }
      } catch (e) {
        logW('Could not delete $path: $e');
        failed++;
      }
    }
    logI('✓ Database file wipe complete — deleted: $deleted, skipped/failed: $failed');
  }

  Future<void> clearAndResync() async {
    try {
      await clearLocalData();
      await connectSync();
      logI('Resync triggered.');
    } catch (e) {
      logE('Clear and resync failed', error: e);
      throw PowerSyncException('Clear and resync failed: $e');
    }
  }

  void dispose() {
    _syncStatusController.close();
    _syncStatusSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _queryCache.clear();
    _cacheTimestamps.clear();
  }

  // ── Primary DB path (used at init time) ──
  Future<String> _getDatabasePath() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, 'powersync_database.db');
  }

  Future<double> getDatabaseSize() async {
    try {
      final dbPath = await _getDatabasePath();
      final files = [
        File(dbPath),
        File('$dbPath-wal'),
        File('$dbPath-shm'),
      ];
      int totalBytes = 0;
      for (var file in files) {
        if (await file.exists()) {
          totalBytes += await file.length();
        }
      }
      return totalBytes / (1024 * 1024);
    } catch (e) {
      logW('Failed to get database size: $e');
      return 0.0;
    }
  }

  // ================================================================
  // QUERY METHODS WITH CACHING
  // ================================================================

  Stream<List<Map<String, dynamic>>> watchQuery(
      String sql, {
        List<dynamic>? parameters,
      }) {
    if (!_isInitialized) {
      return Stream.fromFuture(waitForReady()).asyncExpand(
            (_) => watchQuery(sql, parameters: parameters),
      );
    }

    final cacheKey = '$sql|${parameters?.join(',')}';

    final liveStream = _db
        .watch(sql, parameters: parameters ?? [])
        .map((results) {
      final mapped = results.map((row) => Map<String, dynamic>.from(row)).toList();
      _queryCache[cacheKey] = mapped;
      _cacheTimestamps[cacheKey] = DateTime.now();
      return mapped;
    })
        .handleError((error, stackTrace) {
      logW('Watch query error (using cache if available)', error: error, stackTrace: stackTrace);
      if (_queryCache.containsKey(cacheKey)) {
        logI('Returning cached data due to watch query error');
        return _queryCache[cacheKey]!;
      }
      return <Map<String, dynamic>>[];
    });

    if (_queryCache.containsKey(cacheKey)) {
      final cacheAge = DateTime.now().difference(_cacheTimestamps[cacheKey]!);
      if (cacheAge < _cacheExpiry) {
        return Stream.value(_queryCache[cacheKey]!).asyncExpand((_) => liveStream);
      }
    }

    return liveStream;
  }

  Future<List<Map<String, dynamic>>> executeQuery(
      String sql, {
        List<dynamic>? parameters,
      }) async {
    await waitForReady();
    _ensureInitialized();

    final cacheKey = '$sql|${parameters?.join(',')}';

    try {
      final results = await _db.getAll(sql, parameters ?? []);
      final mapped = results.map((row) => Map<String, dynamic>.from(row)).toList();
      _queryCache[cacheKey] = mapped;
      _cacheTimestamps[cacheKey] = DateTime.now();
      return mapped;
    } catch (error) {
      if (!error.toString().contains('no such table')) {
        logE('Query error', error: error);
      }
      if (_queryCache.containsKey(cacheKey)) {
        final cacheAge = DateTime.now().difference(_cacheTimestamps[cacheKey]!);
        if (cacheAge < _cacheExpiry) {
          logI('Returning cached data (${cacheAge.inSeconds}s old)');
          return _queryCache[cacheKey]!;
        }
      }
      if (error.toString().contains('no such table')) {
        logD('Table not synced yet, returning empty result');
        return <Map<String, dynamic>>[];
      }
      throw PowerSyncException('Query failed: $error');
    }
  }

  Future<Map<String, dynamic>?> querySingle(
      String sql, {
        List<dynamic>? parameters,
      }) async {
    await waitForReady();
    _ensureInitialized();
    try {
      final result = await _db.getOptional(sql, parameters ?? []);
      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } catch (error) {
      logE('Query single error', error: error);
      throw PowerSyncException('Query single failed: $error');
    }
  }

  Future<Map<String, dynamic>?> getById(String table, String id) async {
    final cacheKey = 'getById|$table|$id';
    if (_queryCache.containsKey(cacheKey) && _queryCache[cacheKey]!.isNotEmpty) {
      final cacheAge = DateTime.now().difference(_cacheTimestamps[cacheKey]!);
      if (cacheAge < _cacheExpiry) return _queryCache[cacheKey]!.first;
    }
    final result = await querySingle('SELECT * FROM $table WHERE id = ?', parameters: [id]);
    if (result != null) {
      _queryCache[cacheKey] = [result];
      _cacheTimestamps[cacheKey] = DateTime.now();
    }
    return result;
  }

  Future<bool> exists(String table, String id) async {
    await waitForReady();
    _ensureInitialized();
    try {
      final result = await _db.getOptional('SELECT 1 FROM $table WHERE id = ?', [id]);
      return result != null;
    } catch (error) {
      logE('Exists check error', error: error);
      return false;
    }
  }

  bool _tableHasColumn(String tableName, String columnName) {
    try {
      final table = schema.tables.firstWhere((t) => t.name == tableName);
      return table.columns.any((c) => c.name == columnName);
    } catch (_) {
      return false;
    }
  }

  // ================================================================
  // CRUD OPERATIONS
  // ================================================================

  Future<String> insert(String table, Map<String, dynamic> data) async {
    await waitForReady();
    _ensureInitialized();
    try {
      if (!data.containsKey('id') || data['id'] == null) {
        data['id'] = const Uuid().v4();
      }
      final processedData = _processJsonbFields(data);
      final now = DateTime.now().toIso8601String();
      if (_tableHasColumn(table, 'created_at') && !processedData.containsKey('created_at')) {
        processedData['created_at'] = now;
      }
      if (_tableHasColumn(table, 'updated_at') && !processedData.containsKey('updated_at')) {
        processedData['updated_at'] = now;
      }

      final columns = processedData.keys.join(', ');
      final placeholders = List.generate(processedData.length, (_) => '?').join(', ');
      final values = processedData.values.toList();

      await _db.writeTransaction((tx) async {
        await tx.execute('INSERT INTO $table ($columns) VALUES ($placeholders)', values);
      });

      _invalidateCacheForTable(table);
      logI('✓ Inserted into $table: ${data['id']}');
      return data['id'] as String;
    } catch (error, stackTrace) {
      logE('Insert error in $table', error: error, stackTrace: stackTrace);
      throw PowerSyncException('Insert failed: $error');
    }
  }

  Future<void> update(String table, Map<String, dynamic> data, String id) async {
    await waitForReady();
    _ensureInitialized();
    try {
      final processedData = _processJsonbFields(data);
      processedData.remove('id');
      if (_tableHasColumn(table, 'updated_at')) {
        processedData['updated_at'] = DateTime.now().toIso8601String();
      }
      if (processedData.isEmpty) return;

      final updateParts = processedData.keys.map((key) => '$key = ?').join(', ');
      final values = [...processedData.values, id];

      await _db.writeTransaction((tx) async {
        await tx.execute('UPDATE $table SET $updateParts WHERE id = ?', values);
      });

      _invalidateCacheForTable(table);
      _queryCache.remove('getById|$table|$id');
      logI('✓ Updated $table: $id');
    } catch (error, stackTrace) {
      logE('Update error in $table', error: error, stackTrace: stackTrace);
      throw PowerSyncException('Update failed: $error');
    }
  }

  /// Upsert (Insert or Replace) a record
  Future<void> put(String table, Map<String, dynamic> data) async {
    await waitForReady();
    _ensureInitialized();
    
    int retryCount = 0;
    while (retryCount < 2) {
      try {
        final processedData = _processJsonbFields(data);
        final now = DateTime.now().toIso8601String();
        if (_tableHasColumn(table, 'created_at') && !processedData.containsKey('created_at')) {
          processedData['created_at'] = now;
        }
        if (_tableHasColumn(table, 'updated_at')) {
          processedData['updated_at'] = now;
        }

        final columns = processedData.keys.join(', ');
        final placeholders = List.generate(processedData.length, (_) => '?').join(', ');
        final values = processedData.values.toList();

        await _db.writeTransaction((tx) async {
          await tx.execute(
            'INSERT OR REPLACE INTO $table ($columns) VALUES ($placeholders)',
            values,
          );
        });

        _invalidateCacheForTable(table);
        final id = data['id'];
        if (id != null) _queryCache.remove('getById|$table|$id');
        logI('✓ Put (upsert) $table: $id');
        return; // Success
      } catch (error, stackTrace) {
        final errorStr = error.toString();
        if (retryCount == 0 && (errorStr.contains('no column named') || errorStr.contains('has no column'))) {
          logW('🛠️ Detected missing column in $table. Attempting on-the-fly migration...');
          try {
            await _ensureColumnsExist();
            retryCount++;
            continue; // Retry the loop
          } catch (migrationError) {
            logE('Migration failed during retry', error: migrationError);
          }
        }
        
        logE('Put error in $table', error: error, stackTrace: stackTrace);
        throw PowerSyncException('Put failed: $error');
      }
    }
  }

  Future<void> delete(String table, String id) async {
    await waitForReady();
    _ensureInitialized();
    try {
      await _db.writeTransaction((tx) async {
        await tx.execute('DELETE FROM $table WHERE id = ?', [id]);
      });
      _invalidateCacheForTable(table);
      _queryCache.remove('getById|$table|$id');
      logI('✓ Deleted from $table: $id');
    } catch (error, stackTrace) {
      logE('Delete error in $table', error: error, stackTrace: stackTrace);
      throw PowerSyncException('Delete failed: $error');
    }
  }

  Future<void> execute(String sql, [List<dynamic>? parameters]) async {
    await waitForReady();
    _ensureInitialized();
    try {
      await _db.writeTransaction((tx) async {
        await tx.execute(sql, parameters ?? []);
      });
      logI('✓ Executed SQL: $sql');
    } catch (error, stackTrace) {
      logE('Execute error', error: error, stackTrace: stackTrace);
      throw PowerSyncException('Execute failed: $error');
    }
  }

  Future<void> updateWhere(
      String table,
      Map<String, dynamic> data,
      String whereClause, [
        List<dynamic>? parameters,
      ]) async {
    await waitForReady();
    _ensureInitialized();
    try {
      final processedData = _processJsonbFields(data);
      processedData.remove('id');
      processedData['updated_at'] = DateTime.now().toIso8601String();
      if (processedData.isEmpty) return;

      final updateParts = processedData.keys.map((key) => '$key = ?').join(', ');
      final values = [...processedData.values, ...(parameters ?? [])];

      await _db.writeTransaction((tx) async {
        await tx.execute('UPDATE $table SET $updateParts WHERE $whereClause', values);
      });

      _invalidateCacheForTable(table);
      logI('✓ Updated $table where $whereClause');
    } catch (error, stackTrace) {
      logE('UpdateWhere error in $table', error: error, stackTrace: stackTrace);
      throw PowerSyncException('UpdateWhere failed: $error');
    }
  }

  Future<void> deleteWhere(
      String table,
      String whereClause, [
        List<dynamic>? parameters,
      ]) async {
    await waitForReady();
    _ensureInitialized();
    try {
      await _db.writeTransaction((tx) async {
        await tx.execute('DELETE FROM $table WHERE $whereClause', parameters ?? []);
      });
      _invalidateCacheForTable(table);
      logI('✓ Deleted from $table where $whereClause');
    } catch (error, stackTrace) {
      logE('DeleteWhere error in $table', error: error, stackTrace: stackTrace);
      throw PowerSyncException('DeleteWhere failed: $error');
    }
  }

  Future<void> waitForSync({
    Duration timeout = const Duration(seconds: 15),
    bool quiet = false,
  }) async {
    _ensureInitialized();
    if (_isSyncConnected && _db.currentStatus.hasSynced == true) {
      logI('Already synced');
      return;
    }
    try {
      await _db.statusStream
          .firstWhere((status) => status.hasSynced == true)
          .timeout(timeout);
      logI('Sync completed');
    } on TimeoutException catch (_) {
      if (quiet) {
        logI('Sync timeout after ${timeout.inSeconds}s (continued in background)');
      } else {
        logW('Sync timeout after ${timeout.inSeconds}s (may still be syncing)');
      }
    } catch (e) {
      logW('Sync wait failed: $e');
    }
  }

  Future<bool> hasSyncedData() async {
    _ensureInitialized();
    try {
      final result = await _db.getOptional('SELECT 1 FROM user_profiles LIMIT 1');
      return result != null;
    } catch (e) {
      return false;
    }
  }

  Future<T> transaction<T>(Future<T> Function(SqliteWriteContext) action) async {
    await waitForReady();
    _ensureInitialized();
    return await _db.writeTransaction(action);
  }

  // ================================================================
  // CACHE MANAGEMENT
  // ================================================================

  void _invalidateCacheForTable(String table) {
    final keysToRemove = _queryCache.keys.where((key) => key.contains(table)).toList();
    for (final key in keysToRemove) {
      _queryCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  void clearCache() {
    _queryCache.clear();
    _cacheTimestamps.clear();
    logI('✓ Cache cleared');
  }

  Future<void> _ensureColumnsExist() async {
    try {
      final tableInfo = await _db.getAll('PRAGMA table_info(mentorship_connections)');
      final columns = tableInfo.map((row) => row['name'].toString()).toSet();

      final missingColumns = {
        'last_encouragement_at': 'TEXT',
        'last_encouragement_type': 'TEXT',
        'last_encouragement_message': 'TEXT',
        'encouragement_count': 'INTEGER',
      };

      for (final entry in missingColumns.entries) {
        if (!columns.contains(entry.key)) {
          logI('🛠️ Adding missing column ${entry.key} to mentorship_connections');
          await _db.execute(
            'ALTER TABLE mentorship_connections ADD COLUMN ${entry.key} ${entry.value}',
          );
        }
      }

      final userProfileInfo = await _db.getAll('PRAGMA table_info(user_profiles)');
      final userProfileColumns = userProfileInfo.map((row) => row['name'].toString()).toSet();
      
      if (!userProfileColumns.contains('promoted_community_id')) {
        logI('🛠️ Adding missing column promoted_community_id to user_profiles');
        await _db.execute('ALTER TABLE user_profiles ADD COLUMN promoted_community_id TEXT');
      }
      
      if (!userProfileColumns.contains('score')) {
        logI('🛠️ Adding missing column score to user_profiles');
        await _db.execute('ALTER TABLE user_profiles ADD COLUMN score INTEGER DEFAULT 0');
      }

      if (!userProfileColumns.contains('global_rank')) {
        logI('🛠️ Adding missing column global_rank to user_profiles');
        await _db.execute('ALTER TABLE user_profiles ADD COLUMN global_rank INTEGER DEFAULT 0');
      }

      final userSettingsInfo = await _db.getAll('PRAGMA table_info(user_settings)');
      final userSettingsColumns = userSettingsInfo.map((row) => row['name'].toString()).toSet();
      
      if (!userSettingsColumns.contains('mentoring')) {
        logI('🛠️ Adding missing column mentoring to user_settings');
        await _db.execute('ALTER TABLE user_settings ADD COLUMN mentoring TEXT');
      }
    } catch (e) {
      logW('Column check failed (usually fine if table does not exist yet): $e');
    }
  }

  Future<void> _cleanupOrphanChatData() async {
    try {
      await _db.writeTransaction((tx) async {
        await tx.execute('DELETE FROM chat_messages WHERE chat_id NOT IN (SELECT id FROM chats)');
        await tx.execute('DELETE FROM chat_members WHERE chat_id NOT IN (SELECT id FROM chats)');
        await tx.execute('DELETE FROM chat_invites WHERE chat_id NOT IN (SELECT id FROM chats)');
      });
      logI('✓ Cleaned orphan chat records');
    } catch (error) {
      logE('Orphan chat cleanup failed', error: error);
    }
  }

  // ================================================================
  // HELPERS
  // ================================================================

  void _ensureInitialized() {
    if (!_isInitialized) throw PowerSyncException('PowerSync not initialized');
  }

  dynamic _normalizeNumericValues(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _normalizeNumericValues(v)));
    } else if (value is List) {
      return value.map((v) => _normalizeNumericValues(v)).toList();
    } else if (value is double) {
      final rounded = value.round();
      if ((value - rounded).abs() < 1e-9 && !value.isInfinite && !value.isNaN) {
        return rounded;
      }
      return value;
    } else if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return value;
      if (trimmed.contains('.')) {
        try {
          final doubleVal = double.parse(trimmed);
          final rounded = doubleVal.round();
          if ((doubleVal - rounded).abs() < 1e-9 && !doubleVal.isInfinite && !doubleVal.isNaN) {
            return rounded;
          }
        } catch (_) {}
      }
    }
    return value;
  }

  dynamic _deepNormalize(dynamic value) => _normalizeNumericValues(value);

  Map<String, dynamic> _processJsonbFields(Map<String, dynamic> data) {
    final processed = <String, dynamic>{};
    data.forEach((key, value) {
      final normalizedValue = _normalizeNumericValues(value);
      if (normalizedValue is Map || normalizedValue is List) {
        try {
          processed[key] = jsonEncode(normalizedValue, toEncodable: (nonEncodable) {
            if (nonEncodable is DateTime) return nonEncodable.toIso8601String();
            return nonEncodable.toString();
          });
        } catch (e) {
          logE('JSON Encode error for key $key', error: e);
          processed[key] = '{}';
        }
      } else if (normalizedValue is DateTime) {
        processed[key] = normalizedValue.toIso8601String();
      } else if (normalizedValue == null) {
        processed[key] = null;
      } else {
        processed[key] = normalizedValue;
      }
    });
    return processed;
  }

  Map<String, dynamic> parseJsonbFields(
      Map<String, dynamic> data,
      List<String> jsonbColumns,
      ) {
    final parsed = Map<String, dynamic>.from(data);
    for (final column in jsonbColumns) {
      if (parsed[column] != null && parsed[column] is String) {
        try {
          parsed[column] = jsonDecode(parsed[column]);
        } catch (e) {
          // Keep as string if parsing fails
        }
      }
    }
    return parsed;
  }
}

// ================================================================
// SUPABASE CONNECTOR
// ================================================================

class _SupabaseConnector extends PowerSyncBackendConnector {
  final PowerSyncService service;
  int _retryAttempt = 0;

  _SupabaseConnector(this.service);

  int _compareCrudEntriesForUpload(CrudEntry a, CrudEntry b) {
    int tablePriority(String table) {
      switch (table) {
        case 'chats': return 0;
        case 'chat_members':
        case 'chat_invites': return 1;
        case 'chat_messages':
        case 'chat_message_attachments': return 2;
        default: return 10;
      }
    }
    int opPriority(UpdateType op) {
      switch (op) {
        case UpdateType.put: return 0;
        case UpdateType.patch: return 1;
        case UpdateType.delete: return 2;
      }
    }
    final ta = tablePriority(a.table);
    final tb = tablePriority(b.table);
    if (ta != tb) return ta.compareTo(tb);
    final oa = opPriority(a.op);
    final ob = opPriority(b.op);
    if (oa != ob) return oa.compareTo(ob);
    return 0;
  }

  static const _tablesWithoutUserIdColumn = <String>{
    'chats',
    'chat_messages',
    'chat_message_attachments',
    'chat_invites',
  };

  static const _excludedColumnsPerTable = <String, Set<String>>{
    'chats': {'user_id'},
    'chat_messages': {'user_id'},
    'chat_invites': {'user_id'},
    'chat_message_attachments': {'user_id'},
    'user_profiles': {
      'created_at',
      'updated_at',
      'id',
      'push_token',
      'last_login',
      'score',
      'global_rank',
    },
  };

  static const _boolFieldsPerTable = <String, Set<String>>{
    'user_profiles': {'is_profile_public', 'onboarding_completed', 'open_to_chat'},
    'chats': {'disappearing_messages', 'is_community', 'is_public', 'is_discoverable'},
    'chat_messages': {'is_edited', 'is_deleted', 'is_pinned'},
    'chat_members': {'is_pinned', 'is_muted', 'is_archived', 'is_blocked', 'is_active'},
    'chat_invites': {'is_active', 'is_revoked'},
    'chat_polls': {'is_multi_select', 'is_anonymous'},
    'post_views': {'completed', 'clicked_cta'},
    'posts': {'is_sponsored', 'allow_comments', 'allow_reactions', 'allow_reposts', 'allow_saves', 'is_pinned'},
    'comments': {'is_edited', 'is_deleted', 'is_hidden', 'is_pinned', 'is_by_author'},
    'follows': {'show_in_feed'},
    'notifications': {'is_read'},
    'categories': {'is_global', 'is_active'},
    'mentorship_connections': {
      'is_live_enabled',
      'notify_owner_on_view',
      'notify_mentor_on_update',
      'notify_mentor_on_inactive',
    },
  };

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    try {
      var session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        logD('fetchCredentials: No active session, returning null');
        return null;
      }

      if (session.isExpired ||
          (session.expiresAt != null &&
              DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
                  .difference(DateTime.now())
                  .inSeconds < 60)) {
        logI('Session expired/expiring — refreshing...');
        try {
          final refreshed = await Supabase.instance.client.auth.refreshSession();
          session = refreshed.session;
        } catch (refreshError) {
          logW('Session refresh failed: $refreshError');
        }
      }

      if (session == null) return null;

      final url = EnvConfig.powerSyncUrl;
      final effectiveUrl = url.isEmpty
          ? 'https://69036e0396a2ff4fd9892ba2.powersync.journeyapps.com'
          : url;

      logI('🔑 fetchCredentials: endpoint=$effectiveUrl user=${session.user.id}');

      return PowerSyncCredentials(
        endpoint: effectiveUrl,
        token: session.accessToken,
        userId: session.user.id,
        expiresAt: session.expiresAt != null
            ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
            : null,
      );
    } catch (error) {
      logE('Credential fetch error', error: error);
      return null;
    }
  }

  @override
  void invalidateCredentials() {
    if (service.isOnline) {
      logI('Credentials invalidated - refreshing...');
      Supabase.instance.client.auth.refreshSession();
    }
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final batch = await database.getCrudBatch();
    if (batch == null) return;

    if (!service.isOnline) {
      logD('Offline: Pausing upload batch...');
      await _waitForOnline();
    }

    final sortedCrud = List<CrudEntry>.from(batch.crud)
      ..sort(_compareCrudEntriesForUpload);

    try {
      int successfulUploads = 0;
      final failedOps = <CrudEntry>[];

      for (var op in sortedCrud) {
        if (!service.isOnline) await _waitForOnline();
        final success = await _safeUploadOperation(op, sortedCrud);
        if (success) {
          successfulUploads++;
        } else {
          failedOps.add(op);
        }
      }

      if (failedOps.isEmpty) {
        await batch.complete();
        _retryAttempt = 0;
        logI('✓ Upload batch completed ($successfulUploads items)');
      } else {
        if (successfulUploads > 0) {
          logW('⚠️ Batch partially completed ($successfulUploads/${batch.crud.length}). Retrying failed items immediately.');
        } else {
          await _applyBackoff();
        }
        throw PowerSyncException('Batch upload incomplete (${failedOps.length} failed) - retrying');
      }
    } catch (e) {
      if (e is PowerSyncException) rethrow;
      logE('Upload batch error', error: e);
      await _applyBackoff();
      rethrow;
    }
  }

  Future<bool> _safeUploadOperation(CrudEntry op, List<CrudEntry> allOpEntries) async {
    try {
      // ⭐ OPTIMIZATION: Removed aggressive pre-checks (checkSupabaseReachable).
      // We are better off just trying the operation and catching the SocketException.
      // This allows the app to work on networks that block ICMP/DNS lookups.
      
      final data = _sanitizeDataForSupabase(op.table, op.opData ?? {});
      final opId = op.id;
      final table = Supabase.instance.client.from(op.table);


      logI('SYNC: ${op.op.name.toUpperCase()} ${op.table}/$opId → ${data.keys.toList()}');
      if (op.table == 'bucket_models') {
        logD('📦 DEBUG bucket_models payload: ${jsonEncode(data)}');
      }


      switch (op.op) {
        case UpdateType.put:
          await _executePut(table, op.table, opId, data);
          logI('✓ Synced PUT ${op.table}/$opId');
          break;
        case UpdateType.patch:
          await table.update(data).eq('id', opId);
          logI('✓ Synced PATCH ${op.table}/$opId');
          break;
        case UpdateType.delete:
          const preservedTables = [
            'day_tasks', 'weekly_tasks', 'long_goals', 'bucket_models',
            'user_profiles', 'user_settings', 'fcm_tokens',
          ];
          if (preservedTables.contains(op.table)) {
            logI('🛡️ Preserving ${op.table}/$opId on Supabase (local-only delete)');
          } else {
            await table.delete().eq('id', opId);
            logI('✓ Synced DELETE ${op.table}/$opId');
          }
          break;
      }

      return true;
    } on PostgrestException catch (e) {
      return await _handlePostgrestError(e, op, allOpEntries);
    } catch (error) {
      return _handleGenericError(error, op);
    }
  }

  Map<String, dynamic> _sanitizeDataForSupabase(String tableName, Map<String, dynamic> rawData) {
    final sanitized = <String, dynamic>{};
    final excluded = _excludedColumnsPerTable[tableName] ?? <String>{};
    final boolFields = _boolFieldsPerTable[tableName] ?? <String>{};
    final shouldRemoveUserId = _tablesWithoutUserIdColumn.contains(tableName);

    if (shouldRemoveUserId && rawData.containsKey('user_id')) {
      logD('⚠️ FOUND user_id in $tableName - WILL REMOVE');
    }

    rawData.forEach((key, value) {
      var effectiveKey = key;
      if (tableName == 'chat_messages') {
        if (key == 'shared_id') {
          effectiveKey = 'shared_content_id';
          logW('🔄 Mapping legacy shared_id -> shared_content_id');
        } else if (key == 'shared_mode') {
          effectiveKey = 'shared_content_mode';
          logW('🔄 Mapping legacy shared_mode -> shared_content_mode');
        } else if (key == 'shared_snapshot') {
          effectiveKey = 'shared_content_snapshot';
          logW('🔄 Mapping legacy shared_snapshot -> shared_content_snapshot');
        }
      }

      if (effectiveKey == 'user_id' && shouldRemoveUserId) {
        logD('✅ Removed PowerSync user_id from $tableName');
        return;
      }
      if (excluded.contains(effectiveKey)) {
        logD('ℹ️ Excluded "$effectiveKey" from $tableName');
        return;
      }
      if (value == null) {
        sanitized[effectiveKey] = null;
        return;
      }
      if (boolFields.contains(effectiveKey)) {
        if (value is int) { sanitized[effectiveKey] = value == 1; return; }
        if (value is bool) { sanitized[effectiveKey] = value; return; }
      }

      dynamic finalValue = value;
      if (value is String) {
        try { finalValue = jsonDecode(value); } catch (_) {}
      }

      if (finalValue is DateTime) {
        sanitized[effectiveKey] = finalValue.toIso8601String();
      } else {
        sanitized[effectiveKey] = _normalizeNumericValues(finalValue);
      }
    });

    if (shouldRemoveUserId && sanitized.containsKey('user_id')) {
      sanitized.remove('user_id');
      logW('🚨 SAFETY NET: Removed stray user_id from $tableName');
    }

    return sanitized;
  }

  dynamic _normalizeNumericValues(dynamic value) => service._normalizeNumericValues(value);
  dynamic _deepNormalize(dynamic value) => service._deepNormalize(value);

  Future<void> _executePut(
      SupabaseQueryBuilder table,
      String tableName,
      String opId,
      Map<String, dynamic> data,
      ) async {
    if (tableName == 'user_profiles' || tableName == 'user_settings') {
      data.remove('id');
      if (tableName == 'user_profiles') _injectEmailIfMissing(data);
    } else if (tableName == 'fcm_tokens') {
      data.remove('id');
    } else {
      if (!data.containsKey('id')) data['id'] = opId;
    }

    if (_tablesWithoutUserIdColumn.contains(tableName) && data.containsKey('user_id')) {
      logW('🚨 Removing user_id from $tableName in _executePut');
      data.remove('user_id');
    }

    logI('SYNC: Upserting $tableName → ${data.keys.join(', ')}');

    try {
      if (tableName == 'user_profiles' || tableName == 'user_settings') {
        await table.upsert(data, onConflict: 'user_id');
      } else if (tableName == 'fcm_tokens') {
        await table.upsert(data, onConflict: 'user_id, token');
      } else {
        await table.upsert(data);
      }
    } catch (e) {
      if (e is PostgrestException) {
        final code = (e.code ?? '').toLowerCase();
        final message = e.message.toLowerCase();

        if (code == '42501' || code == '23505' || message.contains('duplicate key')) {
          logI('⚠️ Upsert conflict for $tableName/$opId → UPDATE fallback');
          data.remove('id');
          try {
            await table.update(data).eq('id', opId);
            return;
          } catch (updateError) {
            logE('❌ UPDATE fallback failed', error: updateError);
          }
        }

        final isColumnMismatch = code == '42703' ||
            (message.contains('column') && (message.contains('does not exist') || message.contains('schema cache')));
        if (isColumnMismatch) {
          await _retryWithoutBadColumn(table, tableName, opId, data, e);
          return;
        }
      }
      rethrow;
    }
  }

  Future<void> _retryWithoutBadColumn(
      SupabaseQueryBuilder table,
      String tableName,
      String opId,
      Map<String, dynamic> data,
      PostgrestException originalError,
      ) async {
    final match = RegExp(
      r'(?:column "(\w+)" does not exist|Could not find the [''"]?(\w+)[''"]? column)',
      caseSensitive: false,
    ).firstMatch(originalError.message);

    if (match != null) {
      final badColumn = match.group(1) ?? match.group(2)!;
      logW('⚠️ Auto-removing "$badColumn" from $tableName and retrying...');
      data.remove(badColumn);
      try {
        await table.upsert(data);
        logI('✓ Retry without "$badColumn" succeeded for $tableName/$opId');
      } catch (retryError) {
        logE('❌ Retry without "$badColumn" also failed', error: retryError);
        if (badColumn == 'user_id' || retryError.toString().contains('user_id')) {
          logW('⚠️ CRITICAL: user_id error persists. Deleting local $tableName/$opId to prevent queue block.');
          await _deleteLocalRecord(tableName, opId);
          return;
        }
        rethrow;
      }
    } else {
      logE('⛔ Column error but could not parse column name: ${originalError.message}');
      if (originalError.message.contains('user_id')) {
        logW('⚠️ Skipping likely user_id error for $tableName/$opId and deleting local record.');
        await _deleteLocalRecord(tableName, opId);
        return;
      }
      throw originalError;
    }
  }

  Future<bool> _handlePostgrestError(
      PostgrestException e,
      CrudEntry op,
      List<CrudEntry> allOpEntries,
      ) async {
    final code = (e.code ?? '').toLowerCase();
    final message = e.message.toLowerCase();

    // ── Handle "cannot extract elements from an object" ─────────────────
    if (message.contains('cannot extract elements from an object')) {
      logE('⛔ ⛔ SCHEMA MISMATCH for ${op.table}/${op.id}: ${e.message}');
      logE('🔍 FAIL PAYLOAD: ${jsonEncode(op.opData)}');
      logW('⚠️ This error usually means a DB trigger expected an array but got an object.');
      
      if (op.table == 'bucket_models') {
        logW('💡 Suggestion: Check if bucket_models.metadata should be an array or if a trigger is broken.');
      }
      
      // We return false to allow retry/exponential backoff, 
      // but in some cases we might want to skip to prevent blocking the queue.
      return false; 
    }


    final isColumnMismatch = code == '42703' ||
        (message.contains('column') && (message.contains('does not exist') || message.contains('schema cache')));
    if (isColumnMismatch) {
      logE('⛔ COLUMN MISMATCH ${op.table}/${op.id}: ${e.message}');
      final match = RegExp(
        r'(?:column "(\w+)" does not exist|Could not find the [''"]?(\w+)[''"]? column)',
        caseSensitive: false,
      ).firstMatch(e.message);

      if (match != null) {
        final badColumn = match.group(1) ?? match.group(2)!;
        logW('⚠️ Retrying ${op.table} without "$badColumn"...');
        try {
          final data = _sanitizeDataForSupabase(op.table, op.opData ?? {});
          data.remove(badColumn);
          final table = Supabase.instance.client.from(op.table);
          if (op.op == UpdateType.put) {
            if (!data.containsKey('id') &&
                op.table != 'user_profiles' &&
                op.table != 'user_settings' &&
                op.table != 'fcm_tokens') {
              data['id'] = op.id;
            }
            await table.upsert(data);
          } else if (op.op == UpdateType.patch) {
            await table.update(data).eq('id', op.id);
          }
          logI('✓ Retry succeeded for ${op.table}/${op.id}');
          return true;
        } catch (retryError) {
          logE('❌ Retry also failed for ${op.table}/${op.id}', error: retryError);
          if (badColumn == 'user_id' || retryError.toString().contains('user_id')) {
            logW('⚠️ SKIPPING unrecoverable user_id error for ${op.table}/${op.id}');
            await _deleteLocalRecord(op.table, op.id);
            return true;
          }
          return false;
        }
      }
      if (message.contains('user_id')) {
        await _deleteLocalRecord(op.table, op.id);
        return true;
      }
      return false;
    }

    if (code == '23502') {
      logE('⛔ NULL required field in ${op.table}/${op.id}: ${e.message}');
      await _deleteLocalRecord(op.table, op.id);
      return true;
    }

    if (code == '23503') {
      logE('⛔ Foreign Key Violation for ${op.table}/${op.id}: ${e.message}');
      Future<bool> parentExistsLocally(String parentTable, String parentId) async {
        try {
          final res = await service.db.getOptional('SELECT id FROM $parentTable WHERE id = ?', [parentId]);
          return res != null;
        } catch (e) {
          return false;
        }
      }
      final opData = op.opData ?? {};
      if ((op.table == 'chat_messages' || op.table == 'chat_members' || op.table == 'chat_invites') &&
          message.contains('chat_id')) {
        final chatId = opData['chat_id'];
        if (chatId != null) {
          final pid = chatId.toString();
          final existsLocally = await parentExistsLocally('chats', pid);
          if (!existsLocally || true) {
            await _deleteLocalRecord(op.table, op.id);
            return true;
          }
        }
      }
      return false;
    }

    if (code == '42501' || code == '23505' || message.contains('duplicate key')) {
      if (op.op == UpdateType.delete) {
        logW('⚠️ DELETE failed with permission error for ${op.table}/${op.id}. Treating as local-only delete.');
        return true;
      }
      logI('⚠️ Permission/conflict for ${op.table}/${op.id} → UPDATE fallback');
      try {
        final data = _sanitizeDataForSupabase(op.table, op.opData ?? {});
        data.remove('id');
        await Supabase.instance.client.from(op.table).update(data).eq('id', op.id);
        return true;
      } catch (updateError) {
        logE('❌ Fallback UPDATE failed', error: updateError);
        return false;
      }
    }

    if (code == '22p02' || message.contains('invalid input syntax')) {
      logW('⚠️ Invalid input syntax for ${op.table}/${op.id}: ${e.message}');
      try {
        final aggressiveData = _deepNormalize(_sanitizeDataForSupabase(op.table, op.opData ?? {}));
        final table = Supabase.instance.client.from(op.table);
        if (op.op == UpdateType.put) {
          if (!aggressiveData.containsKey('id') &&
              op.table != 'user_profiles' &&
              op.table != 'user_settings' &&
              op.table != 'fcm_tokens') {
            aggressiveData['id'] = op.id;
          }
          await table.upsert(aggressiveData);
        } else if (op.op == UpdateType.patch) {
          await table.update(aggressiveData).eq('id', op.id);
        }
        logI('✓ Retry with aggressive normalization succeeded for ${op.table}/${op.id}');
        return true;
      } catch (retryError) {
        logE('❌ Retry with normalized data also failed for ${op.table}/${op.id}', error: retryError);
        return false;
      }
    }

    if (message.contains('cannot extract elements from an object')) {
      logE('⛔ SCHEMA MISMATCH for ${op.table}/${op.id}: ${e.message}');
      logE('🔍 FAIL PAYLOAD: ${jsonEncode(op.opData)}');
      logW('⚠️ This record is blocking the sync queue. Deleting local record to rescue sync flow.');
      await _deleteLocalRecord(op.table, op.id);
      return true; // Return true to indicate we "handled" it by skipping
    }

    logE('⛔ Unhandled Postgrest error for ${op.table}/${op.id}: ${e.message}');
    return false;
  }

  bool _handleGenericError(dynamic error, CrudEntry op) {
    final errStr = error.toString();
    if (errStr.contains('SocketException') ||
        errStr.contains('ClientException') ||
        errStr.contains('Connection aborted') ||
        errStr.contains('Connection closed') ||
        errStr.contains('Failed host lookup') ||
        errStr.contains('Network is unreachable') ||
        errStr.contains('Software caused connection abort')) {
      logW('🌐 Network error uploading ${op.table}: $error');
      return false;
    }
    if (errStr.contains('42703') ||
        errStr.contains('record "new" has no field') ||
        errStr.contains('user_id')) {
      logE('⛔ SCHEMA ERROR in ${op.table}: $error');
      if (errStr.contains('user_id')) {
        _deleteLocalRecord(op.table, op.id);
        return true;
      }
      return false;
    }
    logE('❌ Upload failed for ${op.table}/${op.id}: $error');
    return false;
  }

  void _injectEmailIfMissing(Map<String, dynamic> data) {
    if (!data.containsKey('email') || data['email'] == null) {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser?.email != null) {
        data['email'] = currentUser!.email;
        logI('SYNC: Injected email into user_profiles');
      }
    }
  }

  Future<void> _deleteLocalRecord(String tableName, String id) async {
    try {
      await service.db.writeTransaction((tx) async {
        await tx.execute('DELETE FROM $tableName WHERE id = ?', [id]);
      });
      logW('🗑️ Deleted invalid local record: $tableName/$id');
    } catch (delError) {
      logE('❌ Failed to delete local record: $tableName/$id', error: delError);
    }
  }

  Future<void> _waitForOnline() async {
    int attempts = 0;
    const maxAttempts = 15;
    while (!service.isOnline && attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 2));
      if (await service.checkConnectivity()) break;
      attempts++;
    }
    if (attempts >= maxAttempts) {
      logW('⚠️ _waitForOnline timed out after ${maxAttempts * 2}s — proceeding anyway');
    }
  }

  Future<void> _applyBackoff() async {
    _retryAttempt++;
    final delaySeconds = (_retryAttempt == 0 ? 0 : (10 * (1 << (_retryAttempt - 1)))).clamp(10, 60);
    logW('Upload failed. Backing off for $delaySeconds seconds...');
    await Future.delayed(Duration(seconds: delaySeconds));
  }
}

// ================================================================
// POWERSYNC EXCEPTION
// ================================================================

class PowerSyncException implements Exception {
  final String message;
  PowerSyncException(this.message);

  @override
  String toString() => 'PowerSyncException: $message';
}