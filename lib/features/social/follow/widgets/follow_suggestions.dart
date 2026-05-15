import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../../media_utility/universal_media_service.dart';
import '../providers/follow_provider.dart';
import '../models/follows_model.dart';
import 'follow_button.dart';

class FollowSuggestions extends StatefulWidget {
  final String currentUserId;
  final Axis scrollDirection;
  final int itemCount;

  const FollowSuggestions({
    super.key,
    required this.currentUserId,
    this.scrollDirection = Axis.horizontal,
    this.itemCount = 5,
  });

  @override
  State<FollowSuggestions> createState() => _FollowSuggestionsState();
}

class _FollowSuggestionsState extends State<FollowSuggestions>
    with AutomaticKeepAliveClientMixin {
  final Map<String, String?> _avatarCache = {};
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);
    await context.read<FollowProvider>().loadSuggestions();
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
    final suggestions = provider.suggestions.take(widget.itemCount).toList();

    if (_isLoading && suggestions.isEmpty) {
      return _buildLoadingShimmer(theme);
    }

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.scrollDirection == Axis.horizontal) {
      return SizedBox(
        height: 240,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            _loadAvatar(suggestion.userId, suggestion.profileUrl);

            return _buildHorizontalCard(theme, suggestion);
          },
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        _loadAvatar(suggestion.userId, suggestion.profileUrl);

        return _buildVerticalTile(theme, suggestion);
      },
    );
  }

  Widget _buildHorizontalCard(ThemeData theme, FollowSuggestion suggestion) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 0,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              GestureDetector(
                onTap: () => _navigateToProfile(suggestion.userId),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: _avatarCache[suggestion.userId] != null
                        ? (_avatarCache[suggestion.userId]!.startsWith(
                                        'http',
                                      ) ||
                                      _avatarCache[suggestion.userId]!
                                          .startsWith('https')
                                  ? NetworkImage(
                                      _avatarCache[suggestion.userId]!,
                                    )
                                  : FileImage(
                                      File(_avatarCache[suggestion.userId]!),
                                    ))
                              as ImageProvider
                        : null,
                    child: _avatarCache[suggestion.userId] == null
                        ? Text(
                            suggestion.displayName.isNotEmpty ? suggestion.displayName.substring(0, 1).toUpperCase() : '?',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Username
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      suggestion.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${suggestion.username}',
                      style: theme.textScheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Mutual connections
              if (suggestion.hasMutualConnections) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people,
                      size: 12,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        suggestion.reasonText,
                        style: theme.textScheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Follow button
              FollowButton(
                targetUserId: suggestion.userId,
                size: FollowButtonSize.small,
                showIcon: true,
                showUsername: false,
                onFollowed: () {
                  context.read<FollowProvider>().dismissSuggestion(
                    suggestion.userId,
                  );
                },
              ),

              // Dismiss button
              TextButton(
                onPressed: () {
                  context.read<FollowProvider>().dismissSuggestion(
                    suggestion.userId,
                  );
                },
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Not now',
                  style: theme.textScheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalTile(ThemeData theme, FollowSuggestion suggestion) {
    return ListTile(
      leading: GestureDetector(
        onTap: () => _navigateToProfile(suggestion.userId),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: _avatarCache[suggestion.userId] != null
              ? (_avatarCache[suggestion.userId]!.startsWith('http') ||
                            _avatarCache[suggestion.userId]!.startsWith('https')
                        ? NetworkImage(_avatarCache[suggestion.userId]!)
                        : FileImage(File(_avatarCache[suggestion.userId]!)))
                    as ImageProvider
              : null,
          child: _avatarCache[suggestion.userId] == null
              ? Text(
                  suggestion.displayName.isNotEmpty ? suggestion.displayName.substring(0, 1).toUpperCase() : '?',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
      ),
      title: Text(
        suggestion.displayName,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '@${suggestion.username}',
            style: theme.textScheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (suggestion.hasMutualConnections) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 12, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  suggestion.reasonText,
                  style: theme.textScheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FollowButton(
            targetUserId: suggestion.userId,
            size: FollowButtonSize.small,
            showIcon: true,
            onFollowed: () {
              context.read<FollowProvider>().dismissSuggestion(
                suggestion.userId,
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              context.read<FollowProvider>().dismissSuggestion(
                suggestion.userId,
              );
            },
          ),
        ],
      ),
      onTap: () => _navigateToProfile(suggestion.userId),
    );
  }

  Widget _buildLoadingShimmer(ThemeData theme) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 12),
                Container(width: 100, height: 16, color: Colors.grey),
                const SizedBox(height: 8),
                Container(width: 80, height: 12, color: Colors.grey),
                const SizedBox(height: 16),
                Container(width: 100, height: 30, color: Colors.grey),
              ],
            ),
          );
        },
      ),
    );
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
