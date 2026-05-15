import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../../widgets/error_handler.dart';
import '../../model/chat_model.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/empty_state_illustration.dart';
import '../../widgets/common/loading_shimmer_list.dart';
import '../../widgets/common/user_avatar_cached.dart';

class NearbyCommunitiesScreen extends StatefulWidget {
  const NearbyCommunitiesScreen({super.key});

  @override
  State<NearbyCommunitiesScreen> createState() =>
      _NearbyCommunitiesScreenState();
}

class _NearbyCommunitiesScreenState extends State<NearbyCommunitiesScreen> {
  bool _isLoading = true;
  bool _locationEnabled = false;
  final List<ChatModel> _nearbyCommunities = [];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    try {
      final status = await Permission.location.status;
      if (mounted) {
        setState(() {
          _locationEnabled = status.isGranted;
        });
      }

      if (status.isGranted) {
        _loadNearbyCommunities();
      } else {
        if (mounted) {
           setState(() => _isLoading = false);
        }
      }
    } catch (e, st) {
      ErrorHandler.handleError(
        e,
        st,
        'NearbyCommunitiesScreen.checkLocationPermission',
      );
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      if (mounted) {
        setState(() {
          _locationEnabled = status.isGranted;
        });
      }

      if (status.isGranted) {
        _loadNearbyCommunities();
      } else if (status.isPermanentlyDenied) {
        _showSettingsDialog();
      }
    } catch (e, st) {
      ErrorHandler.handleError(
        e,
        st,
        'NearbyCommunitiesScreen.requestLocationPermission',
      );
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Location Required'),
        content: const Text(
          'Please enable location permissions in settings to see nearby communities.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadNearbyCommunities() async {
    try {
      setState(() => _isLoading = true);

      final chatProvider = context.read<ChatProvider>();
      // Using public communities as 'nearby' for now since backend doesn't support geo-query yet
      final results = await chatProvider.getPublicCommunities(limit: 10);

      if (mounted) {
        setState(() {
          _nearbyCommunities.clear();
          _nearbyCommunities.addAll(results);
          _isLoading = false;
        });
      }
    } catch (e, st) {
      ErrorHandler.handleError(
        e,
        st,
        'NearbyCommunitiesScreen.loadNearbyCommunities',
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _previewCommunity(ChatModel community) {
    context.pushNamed(
      'communityPreviewScreen',
      pathParameters: {'communityId': community.id},
      extra: community,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          'Nearby Communities',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _locationEnabled
                  ? Icons.location_on_rounded
                  : Icons.location_off_rounded,
              color: _locationEnabled
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            onPressed: _requestLocationPermission,
          ),
        ],
      ),
      body: !_locationEnabled && !_isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off_rounded,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Location Disabled',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Enable location to find communities near you',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _requestLocationPermission,
                    icon: const Icon(Icons.location_on_rounded),
                    label: const Text('Enable Location'),
                  ),
                ],
              ),
            )
          : _isLoading
          ? const LoadingShimmerList(itemCount: 8)
          : _nearbyCommunities.isEmpty
          ? EmptyStateIllustration(
              type: EmptyStateType.custom,
              icon: Icons.location_on_rounded,
              title: 'No Communities Nearby',
              description: 'Check back later or expand your search area',
              compact: true,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _nearbyCommunities.length,
              itemBuilder: (context, index) {
                final community = _nearbyCommunities[index];
                return _NearbyCard(
                  community: community,
                  onTap: () => _previewCommunity(community),
                );
              },
            ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  final ChatModel community;
  final VoidCallback onTap;

  const _NearbyCard({required this.community, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              UserAvatarCached(
                imageUrl: community.avatar,
                name: community.name ?? '',
                size: 56,
                isGroup: true,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            community.name ?? 'Unnamed Community',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (community.metadata['is_verified'] == true)
                          const Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: Colors.blue,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      community.metadata['category_name']?.toString() ?? 'General',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people_rounded,
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${community.totalMembers} members',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Local',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
