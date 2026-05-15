import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:timeago/timeago.dart' as timeago;
import 'package:the_time_chart/features/social/post/models/post_model.dart';
import 'package:the_time_chart/media_utility/universal_media_service.dart';

class PostHeader extends StatefulWidget {
  final String userId;
  final String username;
  final String? displayName;
  final String? profileUrl;
  final DateTime createdAt;
  final bool isEdited;
  final bool isOwnPost;
  final PostVisibility visibility;
  final bool isSponsored;
  final String contentType;
  final VoidCallback onAvatarTap;
  final VoidCallback onUsernameTap;
  final VoidCallback onMenuTap;

  const PostHeader({
    super.key,
    required this.userId,
    required this.username,
    this.displayName,
    this.profileUrl,
    required this.createdAt,
    required this.isEdited,
    required this.isOwnPost,
    required this.visibility,
    required this.isSponsored,
    required this.contentType,
    required this.onAvatarTap,
    required this.onUsernameTap,
    required this.onMenuTap,
  });

  @override
  State<PostHeader> createState() => _PostHeaderState();
}

class _PostHeaderState extends State<PostHeader> {
  String? _resolvedAvatarUrl;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _resolveAvatar();
    // Refresh time ago every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(PostHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileUrl != widget.profileUrl) {
      _resolveAvatar();
    }
  }

  Future<void> _resolveAvatar() async {
    if (widget.profileUrl == null || widget.profileUrl!.isEmpty) {
      if (mounted) setState(() => _resolvedAvatarUrl = null);
      return;
    }
    try {
      final url = await UniversalMediaService().getValidAvatarUrl(
        widget.profileUrl,
      );
      if (mounted) setState(() => _resolvedAvatarUrl = url);
    } catch (_) {
      if (mounted) setState(() => _resolvedAvatarUrl = widget.profileUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: widget.onAvatarTap,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isSponsored
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: _resolvedAvatarUrl != null
                      ? (_resolvedAvatarUrl!.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: _resolvedAvatarUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    _buildAvatarPlaceholder(theme),
                                errorWidget: (_, __, ___) =>
                                    _buildAvatarPlaceholder(theme),
                              )
                            : Image.file(
                                File(_resolvedAvatarUrl!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildAvatarPlaceholder(theme),
                              ))
                      : _buildAvatarPlaceholder(theme),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Username and metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username row
                GestureDetector(
                  onTap: widget.onUsernameTap,
                  child: Row(
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.displayName?.isNotEmpty == true
                                  ? widget.displayName!
                                  : widget.username,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                _buildVisibilityIcon(context),
                                const SizedBox(width: 6),
                                Text(
                                  _formatContentType(widget.contentType),
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (widget.isSponsored) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Sponsored',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Metadata (Timestamp and Content Type)
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTimeAgo(widget.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  if (widget.isEdited) ...[
                    const SizedBox(width: 4),
                    Text(
                      '• edited',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // Menu button
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            onPressed: widget.onMenuTap,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        widget.username.isNotEmpty
            ? widget.username.substring(0, 1).toUpperCase()
            : '?',
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return '';
    final localDate = date.isUtc ? date.toLocal() : date;
    final now = DateTime.now();

    // Handle clock skew: if the post seems to be in the future, show "Just now"
    if (localDate.isAfter(now)) {
      return 'Just now';
    }

    return timeago.format(localDate);
  }

  String _formatContentType(String type) {
    if (widget.isSponsored) return 'Advertisement';
    if (type.isEmpty) return '';
    final formatted = type.replaceAll('_', ' ');
    return formatted
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? word.substring(0, 1).toUpperCase() + word.substring(1)
              : '',
        )
        .join(' ');
  }

  Widget _buildVisibilityIcon(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    switch (widget.visibility) {
      case PostVisibility.public:
        return Icon(
          Icons.public,
          size: 14,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        );
      case PostVisibility.followers:
        return Icon(
          Icons.people_outline,
          size: 14,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        );
      case PostVisibility.following:
        return Icon(
          Icons.person_add_alt_1_outlined,
          size: 14,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        );
      case PostVisibility.private:
        return Icon(
          Icons.lock_outline,
          size: 14,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        );
    }
  }
}

extension _ThemeTextScheme on ThemeData {
  TextTheme get textScheme => textTheme;
}
