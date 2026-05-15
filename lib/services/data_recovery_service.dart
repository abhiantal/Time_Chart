// lib/services/data_recovery_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/database_schema.dart';
import '../services/powersync_service.dart';
import '../widgets/logger.dart';

class DataRecoveryService {
  final _supabase = Supabase.instance.client;
  final _powerSync = PowerSyncService();

  Future<void> restoreFromCloud({
    Function(String status)? onProgress,
  }) async {
    try {
      onProgress?.call('Preparing to restore from cloud...');
      // clearAndResync wipes local and pulls fresh from cloud
      await _powerSync.clearAndResync();
      onProgress?.call('Restore completed successfully!');
    } catch (e) {
      logE('Restore from cloud failed', error: e);
      rethrow;
    }
  }

  Future<void> clearLocalData({
    Function(String status)? onProgress,
  }) async {
    try {
      onProgress?.call('Wiping local data...');
      await _powerSync.clearLocalData();
      onProgress?.call('Local data wiped successfully.');
    } catch (e) {
      logE('Clear local data failed', error: e);
      rethrow;
    }
  }

  Future<void> backupDatabase({
    Function(String status)? onProgress,
  }) async {
    final tables = schema.tables;
    
    for (final table in tables) {
      // Skip local-only tables as they don't exist in Supabase
      if (table.localOnly) {
        logD('Skipping local-only table: ${table.name}');
        continue;
      }

      try {
        onProgress?.call('Recovering table: ${table.name}...');
        
        // Fetch all local records
        final rows = await _powerSync.executeQuery('SELECT * FROM ${table.name}');
        
        if (rows.isEmpty) {
          logD('Table ${table.name} is empty locally, skipping.');
          continue;
        }

        logI('Recovering ${rows.length} records for table: ${table.name}');
        
        // Prepare data for Supabase (clean up PowerSync internal columns if any)
        final List<Map<String, dynamic>> cleanRows = rows.map((row) {
          final map = Map<String, dynamic>.from(row);
          // PowerSync might add internal columns starting with 'ps_', though usually not in getAll
          map.removeWhere((key, value) => key.startsWith('ps_'));
          
          // Special handling for tables that might not have user_id in Supabase
          // based on _SupabaseConnector implementation in powersync_service.dart
          if (const ['chats', 'chat_messages', 'chat_message_attachments', 'chat_invites'].contains(table.name)) {
            map.remove('user_id');
          }
          
          return map;
        }).toList();

        // Push to Supabase
        await _supabase.from(table.name).upsert(cleanRows);
        logI('✓ Table ${table.name} recovered successfully');
      } catch (e) {
        logE('Failed to recover table: ${table.name}', error: e);
        // Continue with other tables even if one fails
      }
    }
  }

  Future<void> recoverStorage({
    Function(String status)? onProgress,
  }) async {
    try {
      // PowerSync stores media index in media_cache_index
      final mediaRows = await _powerSync.executeQuery('SELECT * FROM media_cache_index');
      
      if (mediaRows.isEmpty) {
        logI('No local media found to recover.');
        return;
      }

      int recoveredCount = 0;
      for (final row in mediaRows) {
        final localPath = row['local_path'] as String?;
        final storagePath = row['storage_path'] as String?;
        final bucketName = row['bucket_name'] as String?;

        if (localPath == null || storagePath == null || bucketName == null) continue;

        final file = File(localPath);
        if (await file.exists()) {
          onProgress?.call('Recovering file: ${storagePath.split('/').last}...');
          try {
            await _supabase.storage.from(bucketName).upload(
              storagePath,
              file,
              fileOptions: const FileOptions(upsert: true),
            );
            recoveredCount++;
            logD('✓ Recovered file: $storagePath to $bucketName');
          } catch (e) {
            logW('Failed to upload file $storagePath: $e');
          }
        }
      }
      logI('✓ Storage recovery finished. Files recovered: $recoveredCount/${mediaRows.length}');
    } catch (e) {
      logE('Storage recovery failed', error: e);
    }
  }
}
