import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:the_time_chart/features/social/follow/models/follows_model.dart';
import 'package:the_time_chart/features/social/follow/providers/follow_provider.dart';
import 'package:the_time_chart/media_utility/universal_media_service.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:the_time_chart/widgets/error_handler.dart';

class FollowRequestsScreen extends StatefulWidget {
  final String currentUserId;

  const FollowRequestsScreen({super.key, required this.currentUserId});

  @override
  State<FollowRequestsScreen> createState() => _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends State<FollowRequestsScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final Map<String, String?> _avatarCache = {};
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    await context.read<FollowProvider>().loadPendingRequests();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadAvatar(String userId, String? url) async {
    if (url == null || _avatarCache.containsKey(userId)) return;

    final validUrl = await mediaService.getValidSignedUrl(url);
    if (mounted) {
      setState(() {
        _avatarCache[userId] = validUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final provider = context.watch<FollowProvider>();
    final requests = provider.pendingRequests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow Requests'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: theme.dividerColor.withOpacity(0.5),
            height: 1,
          ),
        ),
      ),
      body: _isLoading && requests.isEmpty
          ? _buildLoadingState(theme)
          : requests.isEmpty
          ? _buildEmptyState(theme)
          : _buildRequestsList(theme, requests),
    );
  }

  Widget _buildRequestsList(ThemeData theme, List<FollowRequest> requests) {
    return RefreshIndicator(
      onRefresh: _loadRequests,
      color: theme.colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          _loadAvatar(request.userId, request.profileUrl);

          return _buildRequestCard(theme, request);
        },
      ),
    );
  }

  Widget _buildRequestCard(ThemeData theme, FollowRequest request) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            GestureDetector(
              onTap: () => _navigateToProfile(request.userId),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: _avatarCache[request.userId] != null
                    ? (_avatarCache[request.userId]!.startsWith('http') ||
                                  _avatarCache[request.userId]!.startsWith(
                                    'https',
                                  )
                              ? NetworkImage(_avatarCache[request.userId]!)
                              : FileImage(File(_avatarCache[request.userId]!)))
                          as ImageProvider
                    : null,
                child: _avatarCache[request.userId] == null
                    ? Text(
                        request.displayName.isNotEmpty ? request.displayName.substring(0, 1).toUpperCase() : '?',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          request.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (request.isVerified)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.verified,
                            size: 18,
                            color: Colors.blue,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${request.username}',
                    style: theme.textScheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (request.bio != null && request.bio!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      request.bio!,
                      style: theme.textScheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Requested ${request.timeAgo}',
                        style: theme.textScheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (request.isMutual) ...[
                        const SizedBox(width: 12),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurfaceVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.people,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Follows you',
                          style: theme.textScheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () =>
                        _handleRequest(request.userId, accept: true),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    onPressed: () =>
                        _handleRequest(request.userId, accept: false),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading requests...',
            style: theme.textScheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add_disabled,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No pending requests',
              style: theme.textScheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'When someone requests to follow you,\nthey will appear here',
              style: theme.textScheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRequest(String followerId, {required bool accept}) async {
    HapticFeedback.mediumImpact();

    try {
      final provider = context.read<FollowProvider>();
      if (accept) {
        await provider.acceptFollowRequest(followerId);
        AppSnackbar.success('Follow request accepted');
      } else {
        await provider.rejectFollowRequest(followerId);
        AppSnackbar.info(title: 'Follow request declined');
      }
    } catch (e) {
      ErrorHandler.showErrorSnackbar(
        'Failed to ${accept ? 'accept' : 'decline'} request',
      );
    }
  }

  void _navigateToProfile(String userId) {
    if (userId == widget.currentUserId) {
      context.goNamed('personalNav');
    } else {
      context.pushNamed(
        'otherUserProfileScreen',
        pathParameters: {'userId': userId},
      );
    }
  }
}

extension _ThemeTextScheme on ThemeData {
  TextTheme get textScheme => textTheme;
}

final mediaService = UniversalMediaService();
