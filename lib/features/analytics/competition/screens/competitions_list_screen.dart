// FILE: lib/features/analytics/competition/screens/competitions_list_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:the_time_chart/media_utility/universal_media_service.dart';
import 'package:the_time_chart/features/analytics/competition/repositories/competitions_repository.dart';
import 'package:the_time_chart/Authentication/auth_provider.dart';
import 'package:the_time_chart/widgets/circular_progress_indicator.dart';

class CompetitorListItem {
  final String userId;
  final String username;
  final String? profileUrl;
  final int averageProgress;

  CompetitorListItem({
    required this.userId,
    required this.username,
    this.profileUrl,
    required this.averageProgress,
  });
}

class CompetitionsListScreen extends StatefulWidget {
  final String userId;

  const CompetitionsListScreen({super.key, required this.userId});

  @override
  State<CompetitionsListScreen> createState() => _CompetitionsListScreenState();
}

class _CompetitionsListScreenState extends State<CompetitionsListScreen> {
  bool _isLoading = true;
  List<CompetitorListItem> _competitors = [];
  final Map<String, String?> _avatarCache = {};
  final UniversalMediaService mediaService = UniversalMediaService();

  @override
  void initState() {
    super.initState();
    _loadCompetitors();
  }

  Future<void> _loadCompetitors() async {
    setState(() => _isLoading = true);
    try {
      final repo = BattleChallengeRepository();
      final battles = await repo.getBattlesForUser(widget.userId);

      final List<CompetitorListItem> loadedItems = [];
      final Set<String> seenIds = {};

      for (final b in battles) {
        // If the current user (widget.userId) is a member,
        // the creator is a competitor we want to show.
        if (b.isActive &&
            b.userId != widget.userId &&
            b.isParticipant(widget.userId) &&
            !seenIds.contains(b.userId)) {
          if (b.userStats != null) {
            seenIds.add(b.userId);
            loadedItems.add(
              CompetitorListItem(
                userId: b.userId,
                username: b.userStats!.displayName,
                profileUrl: b.userStats!.profileUrl,
                averageProgress: b.userStats!.progressAverage,
              ),
            );

            _loadAvatar(b.userId, b.userStats!.profileUrl);
          }
        }
      }

      if (mounted) {
        setState(() {
          _competitors = loadedItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAvatar(String userId, String? url) async {
    if (url == null || _avatarCache.containsKey(userId)) return;

    // Using getValidAvatarUrl based on existing patterns
    final validUrl = await mediaService.getValidAvatarUrl(url);
    if (mounted && validUrl != null) {
      setState(() {
        _avatarCache[userId] = validUrl;
      });
    }
  }

  void _navigateToProfile(String targetUserId) {
    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    if (targetUserId == currentUserId) {
      context.goNamed('personalNav');
    } else {
      context.pushNamed(
        'otherUserProfileScreen',
        pathParameters: {'userId': targetUserId},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Competitors'), centerTitle: true),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _competitors.isEmpty
          ? _buildEmptyState(theme)
          : _buildCompetitorsList(theme),
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
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Competitors',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No users have added this person to their competition yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitorsList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: _competitors.length,
      itemBuilder: (context, index) {
        final competitor = _competitors[index];
        final profileUrl = _avatarCache[competitor.userId];

        ImageProvider? avatarImage;
        if (profileUrl != null) {
          if (profileUrl.startsWith('http') || profileUrl.startsWith('https')) {
            avatarImage = NetworkImage(profileUrl);
          } else {
            avatarImage = FileImage(File(profileUrl));
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: GestureDetector(
              onTap: () => _navigateToProfile(competitor.userId),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Progress Ring
                  AdvancedProgressIndicator(
                    progress: competitor.averageProgress / 100,
                    size: 52,
                    strokeWidth: 4,
                    labelStyle: ProgressLabelStyle.none,
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  // Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? Text(
                            competitor.username.isNotEmpty
                                ? competitor.username
                                      .substring(0, 1)
                                      .toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
            title: Text(
              competitor.username,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Row(
              children: [
                Text(
                  '${competitor.averageProgress}% Progress',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '@${competitor.username.toLowerCase().replaceAll(' ', '')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            onTap: () => _navigateToProfile(competitor.userId),
          ),
        );
      },
    );
  }
}
