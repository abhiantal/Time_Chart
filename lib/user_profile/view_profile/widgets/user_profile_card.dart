// ================================================================
// FILE: lib/message_bubbles/profile/user_profile_card.dart
// Comprehensive User Profile Card - All Data Display
// ================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import '../../create_edit_profile/profile_models.dart';

/// A comprehensive card widget for displaying user profile information.
class UserProfileCard extends StatelessWidget {
  final UserProfile profile;
  final String? validAvatarUrl;
  final bool isOwnProfile;
  final VoidCallback? onEdit;
  final VoidCallback? onAvatarTap;

  const UserProfileCard({
    super.key,
    required this.profile,
    this.validAvatarUrl,
    this.isOwnProfile = false,
    this.onEdit,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Avatar and Edit Button
              _buildHeader(theme, context),
              const SizedBox(height: 24),

              // About Section
              _buildAboutSection(theme),
              const SizedBox(height: 24),

              // Organization Section
              _buildOrganizationSection(theme),
              const SizedBox(height: 24),

              // Goals Section
              _buildGoalsSection(theme),
              const SizedBox(height: 24),

              // Influencer Section
              _buildInfluencerSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the header section with avatar and user details.
  Widget _buildHeader(ThemeData theme, BuildContext context) {
    return Row(
      children: [
        // Avatar
        GestureDetector(
          onTap: onAvatarTap,
          child: CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: validAvatarUrl != null
                ? ClipOval(
                    child: Builder(
                      builder: (context) {
                        final url = validAvatarUrl!;
                        final isNetwork =
                            url.startsWith('http') || url.startsWith('https');

                        if (isNetwork) {
                          return Image.network(
                            url,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 40,
                                color: theme.colorScheme.onSurfaceVariant,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          );
                        } else {
                          // Assume it is a local file path
                          final f = File(url);
                          return Image.file(
                            f,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // If file doesn't exist or fails to load, show placeholder
                              return Icon(
                                Icons.person,
                                size: 40,
                                color: theme.colorScheme.onSurfaceVariant,
                              );
                            },
                          );
                        }
                      },
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 40,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
        const SizedBox(width: 16),

        // Name and Email
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.displayName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '@${profile.username}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                profile.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the "About" section with basic user info.
  Widget _buildAboutSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, Icons.info_outline, 'About'),
        const SizedBox(height: 16),
        _buildInfoRow(theme, 'Username', profile.username),
        _buildInfoRow(theme, 'Email', profile.email),
        if (profile.address != null && profile.address!.isNotEmpty)
          _buildInfoRow(theme, 'Address', profile.address!),
        _buildInfoRow(
          theme,
          'Profile Visibility',
          profile.isProfilePublic ? 'Public' : 'Private',
        ),
        _buildInfoRow(
          theme,
          'Subscription',
          profile.subscriptionTier.toUpperCase(),
        ),
      ],
    );
  }

  /// Builds the "Organization" section.
  Widget _buildOrganizationSection(ThemeData theme) {
    final hasOrganization =
        profile.organizationName != null &&
        profile.organizationName!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, Icons.business_outlined, 'Organization'),
        const SizedBox(height: 16),
        if (hasOrganization) ...[
          if (profile.organizationName != null)
            _buildInfoRow(theme, 'Organization', profile.organizationName!),
          if (profile.organizationLocation != null)
            _buildInfoRow(theme, 'Location', profile.organizationLocation!),
          if (profile.organizationRole != null)
            _buildInfoRow(theme, 'Role', profile.organizationRole!),
        ] else
          _buildEmptyState(theme, 'No organization information added'),
      ],
    );
  }

  /// Builds the "Goals & Development" section.
  Widget _buildGoalsSection(ThemeData theme) {
    final hasGoals =
        profile.primaryGoal != null ||
        profile.weaknesses.isNotEmpty ||
        profile.strengths.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          theme,
          Icons.emoji_events_outlined,
          'Goals & Development',
        ),
        const SizedBox(height: 16),
        if (hasGoals) ...[
          // Primary Goal
          if (profile.primaryGoal != null) ...[
            Text(
              'Primary Goal',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Text(
                profile.primaryGoal!,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Strengths
          if (profile.strengths.isNotEmpty) ...[
            Text(
              'Strengths',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.strengths
                  .map(
                    (strength) => Chip(
                      label: Text(strength),
                      backgroundColor: theme.colorScheme.secondaryContainer
                          .withOpacity(0.5),
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontSize: 13,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Weaknesses/Areas to Improve
          if (profile.weaknesses.isNotEmpty) ...[
            Text(
              'Areas to Improve',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.weaknesses
                  .map(
                    (weakness) => Chip(
                      label: Text(weakness),
                      backgroundColor: theme.colorScheme.tertiaryContainer
                          .withOpacity(0.5),
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontSize: 13,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ] else
          _buildEmptyState(theme, 'No goals or development areas set'),
      ],
    );
  }

  /// Builds the "Influencer Status" section.
  Widget _buildInfluencerSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          theme,
          Icons.verified_outlined,
          'Influencer Status',
        ),
        const SizedBox(height: 16),
        if (profile.isInfluencer) ...[
          // Verified Badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.1),
                  theme.colorScheme.secondary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.verified,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Verified Influencer',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (profile.influencerCategory != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      profile.influencerCategory!,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (profile.messageForFollower != null &&
                    profile.messageForFollower!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Message to Followers',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile.messageForFollower!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ] else
          _buildEmptyState(theme, 'Not an influencer'),
      ],
    );
  }

  /// Helper widget to build section headers.
  Widget _buildSectionHeader(ThemeData theme, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 12),
            height: 1,
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ],
    );
  }

  /// Helper widget to build information rows.
  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  /// Helper widget to build empty state indicators.
  Widget _buildEmptyState(ThemeData theme, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
