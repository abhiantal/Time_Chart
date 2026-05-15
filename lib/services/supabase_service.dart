// lib/services/supabase_service.dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/logger.dart';
import '../config/env_config.dart';

/// Singleton Supabase service wrapper for database, auth, storage, and realtime.
class SupabaseService {
  static SupabaseService? _instance;

  factory SupabaseService() {
    _instance ??= SupabaseService._internal();
    return _instance!;
  }

  SupabaseService._internal();

  static SupabaseService get instance {
    if (_instance == null) {
      throw Exception(
        'SupabaseService not initialized. Call SupabaseService().initialize() first.',
      );
    }
    return _instance!;
  }

  late final SupabaseClient _client;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  SupabaseClient get client {
    if (!_isInitialized) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client;
  }

  // Auth getters
  String? get currentUserId =>
      _isInitialized ? _client.auth.currentUser?.id : null;
  bool get isAuthenticated =>
      _isInitialized && _client.auth.currentUser != null;
  Session? get currentSession =>
      _isInitialized ? _client.auth.currentSession : null;
  User? get currentUser => _isInitialized ? _client.auth.currentUser : null;

  // Initialization
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      final supabaseUrl = EnvConfig.supabaseUrl;
      final supabaseAnonKey = EnvConfig.supabaseAnonKey;

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw Exception('Invalid Supabase environment configuration');
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
      );

      _client = Supabase.instance.client;
      _isInitialized = true;

      logD('✓ Supabase initialized successfully');
      logD('User ID: ${currentUserId ?? "Not logged in"}');
    } catch (error, stackTrace) {
      // Check if it's a network error during initialization (likely session recovery)
      if (error.toString().contains('Failed host lookup') ||
          error.toString().contains('SocketException') ||
          error.toString().contains('AuthRetryableFetchException')) {
        logW(
          '⚠️ Network error during Supabase initialization (offline mode likely)',
        );

        // Attempt to recover instance if possible
        try {
          _client = Supabase.instance.client;
          _isInitialized = true;
          logI('✓ Supabase instance recovered despite network error');
        } catch (e) {
          logE('❌ Critical: Supabase instance not available', error: e);
          rethrow;
        }
      } else {
        logE(
          'Supabase Initialization Error',
          error: error,
          stackTrace: stackTrace,
        );
        rethrow;
      }
    }
  }

  // Auth methods
  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) throw Exception('Supabase not initialized');

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      logD('✓ Sign up successful for $email');
      return response;
    } catch (error, stackTrace) {
      logE('Sign up error', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) throw Exception('Supabase not initialized');

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      logD('✓ Sign in successful for $email');
      return response;
    } catch (error, stackTrace) {
      logE('Sign in error', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!_isInitialized) throw Exception('Supabase not initialized');

    try {
      await _client.auth.signOut();
      logD('✓ Signed out successfully');
    } catch (error, stackTrace) {
      logE('Sign out error', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Stream<AuthState> get authStateChanges {
    if (!_isInitialized) throw Exception('Supabase not initialized');
    return _client.auth.onAuthStateChange;
  }

  // Storage methods
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List fileBytes,
    required String contentType,
  }) async {
    if (!_isInitialized) throw Exception('Supabase not initialized');

    try {
      await _client.storage
          .from(bucket)
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      // Always use signed URL for private buckets
      final url = await getFileUrl(bucket: bucket, path: path);
      logD('✓ File uploaded: $path');
      return url;
    } catch (error, stackTrace) {
      logE('Upload file error', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Renamed from getFilePublicUrl and made async
  Future<String> getFileUrl({
    required String bucket,
    required String path,
  }) async {
    if (!_isInitialized) throw Exception('Supabase not initialized');

    try {
      // Always use signed URL with 1 year expiry
      return await _client.storage
          .from(bucket)
          .createSignedUrl(path, 60 * 60 * 24 * 365);
    } catch (error, stackTrace) {
      logE('Get file URL error', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    if (!_isInitialized) throw Exception('Supabase not initialized');

    try {
      await _client.storage.from(bucket).remove([path]);
      logD('✓ File deleted: $path');
    } catch (error, stackTrace) {
      logE('Delete file error', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Wipes all user storage across all app buckets.
  /// If [includeProfile] is false, 'user-avatars' is skipped.
  Future<void> wipeAllUserStorage({bool includeProfile = false}) async {
    if (!_isInitialized) return;
    final userId = currentUserId;
    if (userId == null) return;

    final bucketsToWipe = [
      'bucket-media',
      'daily-task-media',
      'weekly-task-media',
      'long-goals-media',
      'social-media',
      'chat-media',
      'diary-media',
    ];
    if (includeProfile) {
      bucketsToWipe.add('user-avatars');
    }

    // Wipe all buckets in parallel. 
    // Optimization: Don't wait for individual file listing if we can help it, 
    // but Supabase requires specific paths for deletion.
    // We limit each bucket wipe to 10 seconds to ensure the whole process doesn't hang.
    await Future.wait(bucketsToWipe.map((bucket) async {
      try {
        // List files in the user's directory
        // In this version of supabase_flutter, recursive might be a top-level parameter 
        // or not supported in list(). We'll try top-level first.
        final files = await _client.storage
            .from(bucket)
            .list(path: userId) // Removed recursive if it's not in SearchOptions
            .timeout(const Duration(seconds: 5));
            
        if (files.isNotEmpty) {
          final paths = files.map((f) => '$userId/${f.name}').toList();
          // Delete up to 1000 files at once (Supabase limit)
          await _client.storage
              .from(bucket)
              .remove(paths)
              .timeout(const Duration(seconds: 5));
          logD('✓ Wiped ${files.length} items from $bucket');
        }
      } catch (e) {
        // Log but don't block the entire account deletion if storage wipe fails for one bucket
        logW('⚠️ Storage wipe skip for $bucket: $e');
      }
    })).timeout(const Duration(seconds: 15), onTimeout: () => []);
  }

  // Database methods
  Future<List<Map<String, dynamic>>> query({
    required String table,
    String select = '*',
    Map<String, dynamic>? filters,
  }) async {
    if (!_isInitialized) throw Exception('Supabase not initialized');

    try {
      var query = _client.from(table).select(select);
      filters?.forEach((key, value) {
        query = query.eq(key, value);
      });

      final data = await query;
      return List<Map<String, dynamic>>.from(data as List);
    } catch (error, stackTrace) {
      logE('Query error', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> insert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    if (!_isInitialized) throw Exception('Supabase not initialized');

    try {
      final response = await _client.from(table).insert(data).select().single();
      logD('✓ Data inserted into $table');
      return Map<String, dynamic>.from(response as Map);
    } catch (error, stackTrace) {
      logE('Insert error', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> update({
    required String table,
    required Map<String, dynamic> data,
    required String id,
  }) async {
    if (!_isInitialized) throw Exception('Supabase not initialized');

    try {
      final response = await _client
          .from(table)
          .update(data)
          .eq('id', id)
          .select()
          .single();
      logD('✓ Data updated in $table');
      return Map<String, dynamic>.from(response as Map);
    } catch (error, stackTrace) {
      logE('Update error', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> delete({required String table, required String id}) async {
    if (!_isInitialized) throw Exception('Supabase not initialized');

    try {
      await _client.from(table).delete().eq('id', id);
      logD('✓ Data deleted from $table');
    } catch (error, stackTrace) {
      logE('Delete error', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Realtime
  RealtimeChannel subscribeToTable(
    String table, {
    void Function(PostgresChangePayload)? onInsert,
    void Function(PostgresChangePayload)? onUpdate,
    void Function(PostgresChangePayload)? onDelete,
  }) {
    if (!_isInitialized) throw Exception('Supabase not initialized');

    try {
      final channel = _client.channel('public:$table');

      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            callback: (payload) {
              switch (payload.eventType) {
                case PostgresChangeEvent.insert:
                  onInsert?.call(payload);
                  break;
                case PostgresChangeEvent.update:
                  onUpdate?.call(payload);
                  break;
                case PostgresChangeEvent.delete:
                  onDelete?.call(payload);
                  break;
                case PostgresChangeEvent.all:
                  logD('Realtime event (ALL): ${payload.newRecord}');
                  break;
              }

              logD('Realtime update: $table - ${payload.eventType.name}');
            },
          )
          .subscribe();

      logD('✓ Subscribed to $table realtime');
      return channel;
    } catch (error, stackTrace) {
      logE('Subscribe error', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  void unsubscribeFromTable(String table) {
    if (!_isInitialized) throw Exception('Supabase not initialized');

    try {
      final channel = _client.channel('public:$table');
      _client.removeChannel(channel);
      logD('✓ Unsubscribed from $table');
    } catch (error, stackTrace) {
      logE('Unsubscribe error', error: error, stackTrace: stackTrace);
    }
  }

  // Edge Functions / RPC
  Future<dynamic> callFunction({
    required String functionName,
    Map<String, dynamic>? params,
  }) async {
    if (!_isInitialized) throw Exception('Supabase not initialized');

    try {
      final response = await _client.functions.invoke(
        functionName,
        body: params ?? {},
      );
      logD('✓ Function called: $functionName');
      return response.data;
    } catch (error, stackTrace) {
      logE(
        'Function call error: $functionName',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<dynamic> callRpc({
    required String functionName,
    Map<String, dynamic>? params,
  }) async {
    if (!_isInitialized) throw Exception('Supabase not initialized');

    try {
      final response = await _client.rpc(functionName, params: params ?? {});
      logD('✓ RPC called: $functionName');
      return response;
    } catch (error, stackTrace) {
      logE(
        'RPC call error: $functionName',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

// Singleton getter
SupabaseService get supabaseService => SupabaseService.instance;
