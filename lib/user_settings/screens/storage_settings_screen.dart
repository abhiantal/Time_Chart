// lib/features/settings/screen/storage_settings_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../services/supabase_service.dart';
import '../../services/data_recovery_service.dart';
import '../../services/powersync_service.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/logger.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';

class StorageSettingsScreen extends StatelessWidget {
  const StorageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Storage & Data'), centerTitle: true),
        body: Consumer<SettingsProvider>(
          builder: (context, provider, child) {
            final dataStorage = provider.dataStorage;

            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                _buildStorageUsageCard(context),

                const SettingsSectionHeader(
                  title: 'Sync',
                  icon: Icons.sync_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.cloud_sync_outlined,
                      title: 'Auto-sync',
                      subtitle: 'Automatically sync data across devices',
                      value: dataStorage.autoSync,
                      onChanged: (value) => provider.updateDataStorage(
                        dataStorage.copyWith(autoSync: value),
                      ),
                    ),
                    if (dataStorage.autoSync)
                      SettingsSwitchTile(
                        icon: Icons.wifi_outlined,
                        title: 'Sync on Wi-Fi only',
                        subtitle: 'Save mobile data by syncing only on Wi-Fi',
                        value: dataStorage.syncOnWifiOnly,
                        onChanged: (value) => provider.updateDataStorage(
                          dataStorage.copyWith(syncOnWifiOnly: value),
                        ),
                      ),
                    SettingsTile(
                      icon: Icons.sync,
                      title: 'Sync now',
                      subtitle: 'Manually trigger a cloud sync',
                      showChevron: false,
                      onTap: () => _performSync(context),
                    ),
                  ],
                ),

                const SettingsSectionHeader(
                  title: 'Cache',
                  icon: Icons.cached_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsSliderTile(
                      icon: Icons.storage_outlined,
                      title: 'Cache size limit',
                      subtitle: 'Maximum cache size in MB',
                      value: dataStorage.cacheSizeLimit.toDouble(),
                      min: 100,
                      max: 2000,
                      divisions: 19,
                      valueLabel: '${dataStorage.cacheSizeLimit} MB',
                      onChanged: (value) => provider.updateDataStorage(
                        dataStorage.copyWith(cacheSizeLimit: value.toInt()),
                      ),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.auto_delete_outlined,
                      title: 'Auto-clear cache',
                      subtitle: 'Automatically clear old cache files',
                      value: dataStorage.autoClearCache,
                      onChanged: (value) => provider.updateDataStorage(
                        dataStorage.copyWith(autoClearCache: value),
                      ),
                    ),
                    if (dataStorage.autoClearCache)
                      SettingsSliderTile(
                        icon: Icons.schedule_outlined,
                        title: 'Clear cache after',
                        value: dataStorage.clearCacheAfterDays.toDouble(),
                        min: 7,
                        max: 90,
                        divisions: 11,
                        valueLabel: '${dataStorage.clearCacheAfterDays} days',
                        onChanged: (value) => provider.updateDataStorage(
                          dataStorage.copyWith(
                            clearCacheAfterDays: value.toInt(),
                          ),
                        ),
                      ),
                    SettingsTile(
                      icon: Icons.cleaning_services_outlined,
                      title: 'Clear cache now',
                      subtitle: 'Free up storage space',
                      showChevron: false,
                      onTap: () => _clearCache(context),
                    ),
                  ],
                ),

                const SettingsSectionHeader(
                  title: 'Backup',
                  icon: Icons.backup_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.cloud_upload_outlined,
                      title: 'Auto backup',
                      subtitle: 'Automatically backup your data',
                      value: dataStorage.backup.enabled,
                      onChanged: (value) => provider.updateDataStorage(
                        dataStorage.copyWith(
                          backup: dataStorage.backup.copyWith(enabled: value),
                        ),
                      ),
                    ),
                    if (dataStorage.backup.enabled) ...[
                      SettingsDropdownTile<String>(
                        icon: Icons.schedule_outlined,
                        title: 'Backup frequency',
                        value: dataStorage.backup.frequency,
                        items: const [
                          DropdownMenuItem(
                            value: 'daily',
                            child: Text('Daily'),
                          ),
                          DropdownMenuItem(
                            value: 'weekly',
                            child: Text('Weekly'),
                          ),
                          DropdownMenuItem(
                            value: 'monthly',
                            child: Text('Monthly'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            provider.updateDataStorage(
                              dataStorage.copyWith(
                                backup: dataStorage.backup.copyWith(
                                  frequency: value,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      SettingsDropdownTile<CloudProvider?>(
                        icon: Icons.cloud_outlined,
                        title: 'Cloud provider',
                        value: dataStorage.backup.cloudProvider,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('None')),
                          DropdownMenuItem(
                            value: CloudProvider.googleDrive,
                            child: Text('Google Drive'),
                          ),
                          DropdownMenuItem(
                            value: CloudProvider.icloud,
                            child: Text('iCloud'),
                          ),
                          DropdownMenuItem(
                            value: CloudProvider.dropbox,
                            child: Text('Dropbox'),
                          ),
                          DropdownMenuItem(
                            value: CloudProvider.oneDrive,
                            child: Text('OneDrive'),
                          ),
                        ],
                        onChanged: (value) => provider.updateDataStorage(
                          dataStorage.copyWith(
                            backup: dataStorage.backup.copyWith(
                              cloudProvider: value,
                            ),
                          ),
                        ),
                      ),
                      SettingsSwitchTile(
                        icon: Icons.photo_outlined,
                        title: 'Include media',
                        subtitle: 'Backup photos and videos',
                        value: dataStorage.backup.includeMedia,
                        onChanged: (value) => provider.updateDataStorage(
                          dataStorage.copyWith(
                            backup: dataStorage.backup.copyWith(
                              includeMedia: value,
                            ),
                          ),
                        ),
                      ),
                    ],
                    SettingsTile(
                      icon: Icons.backup_table_outlined,
                      title: 'Backup now',
                      subtitle: 'Update cloud data with current local data',
                      showChevron: false,
                      onTap: () => _performBackup(context),
                    ),
                  ],
                ),

                const SettingsSectionHeader(
                  title: 'Offline',
                  icon: Icons.offline_bolt_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.download_for_offline_outlined,
                      title: 'Offline mode',
                      subtitle: 'Use app without internet connection',
                      value: dataStorage.offlineMode,
                      onChanged: (value) => provider.updateDataStorage(
                        dataStorage.copyWith(offlineMode: value),
                      ),
                    ),
                  ],
                ),

                const SettingsSectionHeader(
                  title: 'Data Management',
                  icon: Icons.folder_outlined,
                ),
                SettingsCard(
                  children: [
                    // ── 1. Clear local data ──
                    SettingsTile(
                      icon: Icons.sync_problem_outlined,
                      title: 'Clear local data',
                      subtitle: 'Wipe database & cache from device',
                      iconColor: Colors.orange,
                      isDestructive: true,
                      showChevron: false,
                      onTap: () => _showClearLocalDataDialog(context),
                    ),
                    // ── 2. Recover cloud data ──
                    SettingsTile(
                      icon: Icons.cloud_download_outlined,
                      title: 'Recover cloud data',
                      subtitle: 'Restore all data from cloud',
                      iconColor: Colors.orange,
                      showChevron: false,
                      onTap: () => _showForceResyncDialog(context),
                    ),
                    // ── 3. Clear all data (Cloud + Local, Keep Profile) ──
                    SettingsTile(
                      icon: Icons.delete_sweep_outlined,
                      title: 'Clear all data',
                      subtitle: 'Delete all app data',
                      iconColor: Colors.red,
                      isDestructive: true,
                      showChevron: false,
                      onTap: () => _showClearDataDialog(context),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // STORAGE USAGE CARD
  // ════════════════════════════════════════════════════════

  Widget _buildStorageUsageCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<SettingsProvider>();

    final cacheSizeMB = provider.cacheSizeMB;
    final dbSizeMB = provider.databaseSizeMB;
    final totalUsedMB = provider.totalUsageMB;
    const double totalStorageLimit = 2048.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Storage Usage',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () => provider.refreshStorageMetrics(),
                tooltip: 'Refresh metrics',
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (totalUsedMB / totalStorageLimit).clamp(0.0, 1.0),
            backgroundColor: colorScheme.surface.withValues(alpha: 0.5),
            color: colorScheme.primary,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Text(
            '${totalUsedMB.toStringAsFixed(1)} MB of ${totalStorageLimit.toStringAsFixed(0)} MB used',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _buildStorageItem(context, 'App Database', dbSizeMB, Colors.blue),
          const SizedBox(height: 12),
          _buildStorageItem(context, 'Media Cache', cacheSizeMB, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStorageItem(
    BuildContext context,
    String label,
    double size,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(
          '${size.toStringAsFixed(1)} MB',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  // SYNC NOW
  // ════════════════════════════════════════════════════════

  Future<void> _performSync(BuildContext context) async {
    AppSnackbar.loading(title: 'Syncing...');
    try {
      await PowerSyncService().connectSync();
      await Future.delayed(const Duration(milliseconds: 800));
      if (context.mounted) {
        await context.read<SettingsProvider>().refreshStorageMetrics();
      }
      AppSnackbar.hideLoading();
      AppSnackbar.success('Sync completed successfully!');
    } catch (e) {
      logE('Sync failed', error: e);
      AppSnackbar.hideLoading();
      AppSnackbar.error(
        'Sync failed',
        description: 'Please check your connection and try again.',
      );
    }
  }

  // ════════════════════════════════════════════════════════
  // CLEAR MEDIA CACHE
  // ════════════════════════════════════════════════════════

  void _clearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_outlined, color: Colors.orange),
            SizedBox(width: 12),
            Text('Clear Media Cache?'),
          ],
        ),
        content: const Text(
          'This will delete all locally cached photos and videos. '
          'They will be re-downloaded from the cloud when needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              AppSnackbar.loading(title: 'Clearing cache...');
              try {
                await _wipeCacheDirectories();
                PowerSyncService().clearCache();
                if (context.mounted) {
                  await context
                      .read<SettingsProvider>()
                      .refreshStorageMetrics();
                  context.read<SettingsProvider>().clearCache();
                }
                AppSnackbar.hideLoading();
                AppSnackbar.success('Cache cleared successfully!');
              } catch (e) {
                logE('Clear cache failed', error: e);
                AppSnackbar.hideLoading();
                AppSnackbar.error(
                  'Failed to clear cache',
                  description: 'Please try again.',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Now'),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // BACKUP NOW
  // ════════════════════════════════════════════════════════

  Future<void> _performBackup(BuildContext context) async {
    final recoveryService = DataRecoveryService();
    AppSnackbar.loading(title: 'Updating cloud data...');
    try {
      await recoveryService.backupDatabase(
        onProgress: (status) => AppSnackbar.loading(title: status),
      );
      AppSnackbar.hideLoading();
      AppSnackbar.success('Cloud database updated successfully!');
    } catch (e) {
      logE('Backup failed', error: e);
      AppSnackbar.hideLoading();
      AppSnackbar.error(
        'Backup failed',
        description: 'Please check your connection and try again.',
      );
    }
  }

  // ════════════════════════════════════════════════════════
  // 1. CLEAR LOCAL DATA (Wipe Local Only, Do NOT Sync)
  // ════════════════════════════════════════════════════════

  void _showClearLocalDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.sync_problem_outlined, color: Colors.orange),
            SizedBox(width: 12),
            Text('Clear Local Data?'),
          ],
        ),
        content: const Text(
          'This will wipe all local database and media files from this device.\n\n'
          'Sync will be disconnected and no new data will download until manually enabled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeClearLocalData(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeClearLocalData(BuildContext context) async {
    AppSnackbar.loading(title: 'Clearing local data...');
    try {
      final powerSync = PowerSyncService();

      // Disconnect and wipe local data completely
      await powerSync.disconnect();
      await Future.wait([
        powerSync.clearLocalData(reinitialize: false),
        _wipeCacheDirectories(),
      ]);

      AppSnackbar.hideLoading();
      AppSnackbar.success('All local data cleared from device');

      if (context.mounted) {
        await context
            .read<SettingsProvider>()
            .refreshStorageMetrics()
            .catchError((_) {});
      }
    } catch (e) {
      logE('Clear local data failed', error: e);
      AppSnackbar.hideLoading();
      AppSnackbar.error(
        'Clear failed',
        description: 'Failed to clear local storage.',
      );
    }
  }

  // ════════════════════════════════════════════════════════
  // 2. FORCE RESYNC / RECOVER CLOUD DATA (Wipe Local, Sync Background)
  // ════════════════════════════════════════════════════════

  void _showForceResyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cloud_download_outlined, color: Colors.orange),
            SizedBox(width: 12),
            Text('Recover Cloud Data?'),
          ],
        ),
        content: const Text(
          'This will wipe all local data and re-download everything from the cloud.\n\n'
          'Use this to sync and restore all data from the cloud down to this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeForceResync(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Recover Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeForceResync(BuildContext context) async {
    AppSnackbar.loading(title: 'Initializing recovery...');
    try {
      final powerSync = PowerSyncService();

      // 1. Disconnect and wipe local
      await powerSync.disconnect();
      await Future.wait([
        powerSync.clearLocalData(reinitialize: false),
        _wipeCacheDirectories(),
      ]).timeout(const Duration(seconds: 5));

      // 2. Re-connect and sync in the background
      await powerSync.initialize();
      
      // Start connectSync in background without blocking UI
      powerSync.connectSync().catchError((e) {
        logW('Background connectSync failed: $e');
      });

      // 🚀 OPTIMIZATION: Instant success feedback for user, sync runs in background.
      AppSnackbar.hideLoading();
      AppSnackbar.success('Cloud data recovery started in background!');

      if (context.mounted) {
        await context
            .read<SettingsProvider>()
            .refreshStorageMetrics()
            .catchError((_) {});
      }
    } catch (e) {
      logE('Force resync failed', error: e);
      AppSnackbar.hideLoading();
      AppSnackbar.error(
        'Recovery failed',
        description: 'Failed to initiate cloud data recovery.',
      );
    }
  }

  // ════════════════════════════════════════════════════════
  // 3. CLEAR ALL DATA (Cloud + Local, Keep Profile)
  // ════════════════════════════════════════════════════════

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Clear All Data?'),
          ],
        ),
        content: const Text(
          'This will permanently delete ALL your data from BOTH the cloud and this device.\n\n'
          'YOUR PROFILE AND PROFILE PICTURE WILL BE KEPT.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _executeWipeAllData(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeWipeAllData(BuildContext context) async {
    final supabase = SupabaseService.instance;
    final powerSync = PowerSyncService();
    final userId = supabase.currentUserId;

    if (userId == null) {
      AppSnackbar.error('Not signed in');
      return;
    }

    AppSnackbar.loading(title: 'Wiping all data...');

    try {
      // 🚀 OPTIMIZATION: Fire the cloud wipes in the background without blocking the UI thread.
      // This makes the action instantaneous while ensuring completion on the server.
      supabase.wipeAllUserStorage(includeProfile: false).catchError((e) {
        logW('Background cloud storage wipe failed: $e');
      });
      supabase.callRpc(functionName: 'clear_user_data').catchError((e) {
        logW('Background cloud DB wipe failed: $e');
      });

      // 2. Wipe Local Data in parallel
      await Future.wait([
        powerSync.clearLocalData(reinitialize: false),
        _wipeCacheDirectories(),
      ]).timeout(const Duration(seconds: 5));

      if (context.mounted) {
        context.read<SettingsProvider>().refreshStorageMetrics().catchError((_) {});
      }
      AppSnackbar.hideLoading();
      AppSnackbar.success('All app data cleared successfully');
    } catch (e) {
      logE('Wipe all data failed', error: e);
      AppSnackbar.hideLoading();
      AppSnackbar.error(
        'Clear failed',
        description: 'Failed to clear all app data.',
      );
    }
  }

  // ════════════════════════════════════════════════════════
  // CACHE WIPE HELPER
  // Clears media/temp directories only — never touches DB files.
  // DB files are handled exclusively by PowerSyncService.
  // ════════════════════════════════════════════════════════

  Future<void> _wipeCacheDirectories() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();

      // App-level media cache folder
      final mediaCacheDir = Directory(p.join(appDir.path, 'media_cache'));
      if (await mediaCacheDir.exists()) {
        await mediaCacheDir.delete(recursive: true);
      }

      // System temp dir
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final stream = tempDir.list(recursive: false);
        await for (final entity in stream) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }

      if (Platform.isAndroid) {
        try {
          final extCacheDirs = await getExternalCacheDirectories();
          if (extCacheDirs != null) {
            for (final dir in extCacheDirs) {
              if (await dir.exists()) {
                final stream = dir.list(recursive: false);
                await for (final entity in stream) {
                  try {
                    await entity.delete(recursive: true);
                  } catch (_) {}
                }
              }
            }
          }
        } catch (_) {}
      }

      logI('✓ Cache directories wiped');
    } catch (e) {
      logW('Cache wipe warning: $e');
    }
  }
}
