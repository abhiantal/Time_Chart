// ================================================================
// FILE: lib/user_profile/profile_models.dart
// Consolidated: UserProfile + ProfileUpdateDto + Constants
// Handles both PowerSync (SQLite) and Supabase (PostgreSQL) formats
// ================================================================

import 'dart:convert';
import 'package:the_time_chart/widgets/logger.dart';

// ================================================================
// PROFILE CONSTANTS
// ================================================================

/// Constants used throughout the profile system
class ProfileConstants {
  ProfileConstants._();

  // Common goals for user selection
  static const List<String> commonGoals = [
    'Weight Loss',
    'Muscle Building',
    'Career Growth',
    'Skill Development',
    'Better Health',
    'Financial Freedom',
    'Work-Life Balance',
    'Personal Growth',
    'Networking',
    'Leadership',
  ];

  // Common weaknesses for user selection
  static const List<String> commonWeaknesses = [
    'Procrastination',
    'Time Management',
    'Public Speaking',
    'Stress Management',
    'Focus & Concentration',
    'Self-Discipline',
    'Communication',
    'Organization',
    'Delegation',
    'Work-Life Balance',
  ];

  // Common strengths for user selection
  static const List<String> commonStrengths = [
    'Problem Solving',
    'Leadership',
    'Communication',
    'Creativity',
    'Teamwork',
    'Analytical Thinking',
    'Adaptability',
    'Time Management',
    'Technical Skills',
    'Emotional Intelligence',
  ];

  // Influencer categories
  static const List<String> influencerCategories = [
    'Tech',
    'Fitness',
    'Education',
    'Business',
    'Lifestyle',
    'Entertainment',
    'Health & Wellness',
    'Finance',
    'Travel',
    'Food',
    'Fashion',
    'Gaming',
    'Music',
    'Art & Design',
    'Sports',
  ];

  // Subscription tiers
  static const List<String> subscriptionTiers = ['free', 'pro', 'elite'];

  // Field length limits
  static const int maxUsernameLength = 30;
  static const int maxDisplayNameLength = 50;
  static const int maxAddressLength = 200;
  static const int maxOrgNameLength = 100;
  static const int maxOrgLocationLength = 100;
  static const int maxOrgRoleLength = 50;
  static const int maxInfluencerCategoryLength = 50;
  static const int maxMessageForFollowerLength = 300;
  static const int maxGoalLength = 50;
  static const int minUsernameLength = 3;

  // Validation patterns
  static final RegExp usernamePattern = RegExp(r'^[a-zA-Z0-9_]+$');
}

// ================================================================
// PROFILE STATUS ENUM
// ================================================================

enum ProfileStatus { initial, loading, loaded, updating, error }

// ================================================================
// SOCIAL STATS MODEL
// ================================================================

class SocialStats {
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int competitionsCount;

  const SocialStats({
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.competitionsCount = 0,
  });

  factory SocialStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SocialStats();
    return SocialStats(
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      postsCount: json['posts_count'] as int? ?? 0,
      competitionsCount: json['competitions_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followers_count': followersCount,
      'following_count': followingCount,
      'posts_count': postsCount,
      'competitions_count': competitionsCount,
    };
  }

  @override
  String toString() =>
      'SocialStats(followers: $followersCount, following: $followingCount, posts: $postsCount, competitions: $competitionsCount)';
}

// ================================================================
// USER PROFILE MODEL
// ================================================================

class UserProfile {
  final String id;
  final String userId;

  final String email;
  final String username;
  final String displayName;
  final String? profileUrl;
  final String? address;

  // Organization (from JSONB)
  final String? organizationName;
  final String? organizationLocation;
  final String? organizationRole;

  // Influencer (from JSONB)
  final bool isInfluencer;
  final String? influencerCategory;
  final String? messageForFollower;

  // User Info (from JSONB)
  final String? primaryGoal;
  final List<String> weaknesses;
  final List<String> strengths;

  // Settings
  final bool isProfilePublic;
  final bool openToChat;
  final String? createdCommunityId;
  final String? promotedCommunityId;
  final String subscriptionTier;
  final bool onboardingCompleted;

  // Social Stats (from JSONB)
  final SocialStats socialStats;

  // Analytics fields (computed from other tables in search)
  final int score;
  final int globalRank;

  // Timestamps
  final DateTime createdAt;
  final DateTime? lastLogin;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.userId,

    required this.email,
    required this.username,
    required this.displayName,
    this.profileUrl,
    this.address,
    this.organizationName,
    this.organizationLocation,
    this.organizationRole,
    this.isInfluencer = false,
    this.influencerCategory,
    this.messageForFollower,
    this.primaryGoal,
    this.weaknesses = const [],
    this.strengths = const [],
    this.isProfilePublic = true,
    this.openToChat = true,
    this.createdCommunityId,
    this.promotedCommunityId,
    this.subscriptionTier = 'free',
    this.onboardingCompleted = false,
    this.socialStats = const SocialStats(),
    this.score = 0,
    this.globalRank = 0,
    required this.createdAt,
    this.lastLogin,
    required this.updatedAt,
  });

  // ================================================================
  // FACTORY: FROM JSON (Handles both PowerSync & Supabase formats)
  // ================================================================

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Parse JSONB fields (may come as String or Map)
    final org = _parseJsonbField(json['organization']);
    final inf = _parseJsonbField(json['influencer']);
    final info = _parseJsonbField(json['user_info']);
    final stats = _parseJsonbField(json['social_stats']);

    // Get user_id (may be 'user_id' or 'id')
    final parsedUserId =
        json['user_id'] as String? ?? json['id'] as String? ?? '';

    return UserProfile(
      id: json['id'] as String? ?? parsedUserId,
      userId: parsedUserId,

      email: json['email'] as String? ?? '',
      username: _parseUsername(json['username'], json['email'], userId: parsedUserId),
      displayName: json['display_name'] as String? ?? 
                   json['full_name'] as String? ?? 
                   _parseUsername(json['username'], json['email'], userId: parsedUserId),
      profileUrl: _parseProfileUrl(json['profile_url']),
      address: json['address'] as String?,

      // Organization
      organizationName: org['name'] as String?,
      organizationLocation: org['location'] as String?,
      organizationRole: org['your_role'] as String?,

      // Influencer
      isInfluencer: _parseBool(inf['is_influencer']),
      influencerCategory: inf['influencer_category'] as String?,
      messageForFollower: inf['message_for_follower'] as String?,

      // User Info
      primaryGoal: info['primary_goal'] as String?,
      weaknesses: parseStringList(info['weaknesses']),
      strengths: parseStringList(info['strengths']),

      // Settings
      isProfilePublic: _parseBool(json['is_profile_public'] ?? true),
      openToChat: _parseBool(json['open_to_chat'] ?? true),
      createdCommunityId: json['created_community_id'] as String?,
      promotedCommunityId: json['promoted_community_id'] as String?,
      subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      onboardingCompleted: _parseBool(json['onboarding_completed']),
      socialStats: SocialStats.fromJson(stats),
      score: _parseInt(json['score']),
      globalRank: _parseInt(json['global_rank']),

      // Timestamps
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      lastLogin: _parseDateTime(json['last_login']),
      updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
    );
  }

  // ================================================================
  // TO JSON: For Supabase (Remote) - Native types
  // ================================================================

  Map<String, dynamic> toRemoteJson() {
    return {
      'id': id,
      'user_id': userId,

      'email': email,
      'username': username,
      'display_name': displayName,
      'profile_url': (profileUrl != null && !isLocalPath(profileUrl!)) ? profileUrl : null,
      'address': address,
      'organization': {
        'name': organizationName,
        'location': organizationLocation,
        'your_role': organizationRole,
      },
      'influencer': {
        'is_influencer': isInfluencer,
        'influencer_category': influencerCategory,
        'message_for_follower': messageForFollower,
      },
      'user_info': {
        'primary_goal': primaryGoal,
        'weaknesses': {'items': weaknesses},
        'strengths': {'items': strengths},
      },
      'is_profile_public': isProfilePublic,
      'open_to_chat': openToChat,
      'created_community_id': createdCommunityId,
      'promoted_community_id': promotedCommunityId,
      'subscription_tier': subscriptionTier,
      'onboarding_completed': onboardingCompleted,
      'social_stats': socialStats.toJson(),
      'score': score,
      'global_rank': globalRank,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ================================================================
  // TO JSON: For PowerSync (Local SQLite) - Encoded types
  // ================================================================

  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'user_id': userId,

      'email': email,
      'username': username,
      'display_name': displayName,
      'profile_url': (profileUrl != null && !isLocalPath(profileUrl!)) ? profileUrl : null,
      'address': address,
      // JSONB as encoded strings for SQLite
      'organization': jsonEncode({
        'name': organizationName,
        'location': organizationLocation,
        'your_role': organizationRole,
      }),
      'influencer': jsonEncode({
        'is_influencer': isInfluencer,
        'influencer_category': influencerCategory,
        'message_for_follower': messageForFollower,
      }),
      'user_info': jsonEncode({
        'primary_goal': primaryGoal,
        'weaknesses': {'items': weaknesses},
        'strengths': {'items': strengths},
      }),
      // Booleans as integers for SQLite
      'is_profile_public': isProfilePublic ? 1 : 0,
      'open_to_chat': openToChat ? 1 : 0,
      'created_community_id': createdCommunityId,
      'promoted_community_id': promotedCommunityId,
      'onboarding_completed': onboardingCompleted ? 1 : 0,
      'subscription_tier': subscriptionTier,
      'social_stats': jsonEncode(socialStats.toJson()),
      'score': score,
      'global_rank': globalRank,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ================================================================
  // COPY WITH
  // ================================================================

  UserProfile copyWith({
    String? id,
    String? userId,
    String? email,
    String? username,
    String? displayName,
    String? profileUrl,
    String? address,
    String? organizationName,
    String? organizationLocation,
    String? organizationRole,
    bool? isInfluencer,
    String? influencerCategory,
    String? messageForFollower,
    String? primaryGoal,
    List<String>? weaknesses,
    List<String>? strengths,
    bool? isProfilePublic,
    bool? openToChat,
    String? createdCommunityId,
    String? promotedCommunityId,
    String? subscriptionTier,
    bool? onboardingCompleted,
    SocialStats? socialStats,
    int? score,
    int? globalRank,
    DateTime? createdAt,
    DateTime? lastLogin,
    DateTime? updatedAt,
  }) {
    // 🛡️ SANITIZE profileUrl during copyWith to prevent local path leaks in state
    final sanitizedUrl = (profileUrl != null && UserProfile.isLocalPath(profileUrl))
        ? null
        : (profileUrl ?? this.profileUrl);

    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      profileUrl: sanitizedUrl,
      address: address ?? this.address,
      organizationName: organizationName ?? this.organizationName,
      organizationLocation: organizationLocation ?? this.organizationLocation,
      organizationRole: organizationRole ?? this.organizationRole,
      isInfluencer: isInfluencer ?? this.isInfluencer,
      influencerCategory: influencerCategory ?? this.influencerCategory,
      messageForFollower: messageForFollower ?? this.messageForFollower,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      weaknesses: weaknesses ?? this.weaknesses,
      strengths: strengths ?? this.strengths,
      isProfilePublic: isProfilePublic ?? this.isProfilePublic,
      openToChat: openToChat ?? this.openToChat,
      createdCommunityId: createdCommunityId ?? this.createdCommunityId,
      promotedCommunityId: promotedCommunityId ?? this.promotedCommunityId,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      socialStats: socialStats ?? this.socialStats,
      score: score ?? this.score,
      globalRank: globalRank ?? this.globalRank,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // ================================================================
  // COMPUTED PROPERTIES
  // ================================================================

  /// Profile completion percentage (0.0 - 1.0)
  double get completionPercentage {
    int completed = 0;
    const int total = 10;

    if (username.isNotEmpty && username.length >= 3) completed++;
    if (profileUrl != null && profileUrl!.isNotEmpty) completed++;
    if (address != null && address!.isNotEmpty) completed++;
    if (organizationName != null && organizationName!.isNotEmpty) completed++;
    if (organizationRole != null && organizationRole!.isNotEmpty) completed++;
    if (primaryGoal != null && primaryGoal!.isNotEmpty) completed++;
    if (weaknesses.isNotEmpty) completed++;
    if (strengths.isNotEmpty) completed++;
    if (subscriptionTier != 'free') completed++;
    if (onboardingCompleted) completed++;

    return completed / total;
  }

  /// Check if profile has minimum required data
  bool get isValid {
    return userId.isNotEmpty &&
        email.isNotEmpty &&
        username.isNotEmpty &&
        username.length >= ProfileConstants.minUsernameLength;
  }

  /// Identifies the first missing required field
  String? getFirstMissingField() {
    if (username.isEmpty || username.length < ProfileConstants.minUsernameLength) {
      return 'Username';
    }
    if (displayName.isEmpty) return 'Display Name';
    // profileUrl is optional in code, but user might want it
    if (primaryGoal == null || primaryGoal!.isEmpty) return 'Primary Goal';
    if (weaknesses.isEmpty) return 'Weaknesses';
    if (strengths.isEmpty) return 'Strengths';
    if (!onboardingCompleted) return 'Onboarding';
    return null;
  }

  /// Returns the corresponding onboarding step index (0-based) for the first missing field
  int getOnboardingStepIndex({bool isCreateMode = true}) {
    if (username.isEmpty || displayName.isEmpty) {
      return isCreateMode ? 1 : 0; // Step 1 in Create, Step 0 in Edit
    }
    if (primaryGoal == null || primaryGoal!.isEmpty || weaknesses.isEmpty || strengths.isEmpty) {
      return isCreateMode ? 3 : 2; // Step 3 in Create, Step 2 in Edit
    }
    if (!onboardingCompleted) {
      return isCreateMode ? 4 : 3; // Final step
    }
    return 0;
  }

  /// Check if organization is set
  bool get hasOrganization =>
      organizationName != null && organizationName!.isNotEmpty;

  /// Check if goals are set
  bool get hasGoals =>
      primaryGoal != null || weaknesses.isNotEmpty || strengths.isNotEmpty;

  /// Initials for avatar fallback
  String get initials {
    final name = displayName;
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'[_\s]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  // ================================================================
  // PARSING HELPERS (Static)
  // ================================================================

  static Map<String, dynamic> _parseJsonbField(dynamic field) {
    if (field == null) return {};

    // Already a Map
    if (field is Map) {
      try {
        return Map<String, dynamic>.from(field);
      } catch (_) {
        return {};
      }
    }

    // JSON String
    if (field is String) {
      if (field.isEmpty || field == '{}' || field == 'null') return {};
      try {
        final decoded = jsonDecode(field);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        // Try to handle malformed JSON gracefully
        return {};
      }
    }

    return {};
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static List<String> parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is Map) {
      if (value.containsKey('items')) {
        final items = value['items'];
        if (items is List) {
          return items.map((e) => e.toString()).toList();
        }
      }
    }
    if (value is String) {
      if (value.isEmpty || value == '[]') return [];
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
        if (decoded is Map && decoded.containsKey('items')) {
          final items = decoded['items'];
          if (items is List) {
            return items.map((e) => e.toString()).toList();
          }
        }
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  static String _parseUsername(dynamic username, dynamic email, {String? userId}) {
    if (username is String && username.isNotEmpty) {
      return username;
    }
    if (email is String && email.isNotEmpty) {
      return email.split('@').first;
    }
    if (userId != null && userId.isNotEmpty) {
      // Use short ID suffix for consistent "shadow" names (e.g. user_6c35)
      final suffix = userId.length >= 4 ? userId.substring(0, 4) : userId;
      return 'user_$suffix';
    }
    return 'user';
  }

  static String? _parseProfileUrl(dynamic url) {
    if (url == null) return null;
    if (url is String && url.isNotEmpty && url != 'null') {
      // 🛡️ SANITIZATION: If it is an absolute local path, it's a leak from another session.
      // We should NOT use it as the source of truth storage path.
      if (isLocalPath(url)) {
        return null;
      }
      return url;
    }
    return null;
  }

  /// Helper to detect absolute local file paths (non-portable)
  static bool isLocalPath(String path) {
    return path.startsWith('/') ||
           path.startsWith('file://') ||
           path.contains(':\\') ||
           path.contains('media_cache');
  }

  // ================================================================
  // EMPTY PROFILE FACTORY
  // ================================================================

  factory UserProfile.empty(String userId, String email) {
    final now = DateTime.now();
    return UserProfile(
      id: userId,
      userId: userId,
      email: email,
      username: email.split('@').first,
      displayName: email.split('@').first,
      createdAt: now,
      updatedAt: now,
      socialStats: const SocialStats(),
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, username: $username, email: $email, '
        'completion: ${(completionPercentage * 100).toInt()}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => id.hashCode ^ updatedAt.hashCode;
}

// ================================================================
// PROFILE UPDATE DTO
// ================================================================

class ProfileUpdateDto {
  final String? username;
  final String? displayName;
  final String? profileUrl;
  final String? address;

  // Organization
  final String? orgName;
  final String? orgLocation;
  final String? orgRole;

  // Influencer
  final bool? isInfluencer;
  final String? influencerCategory;
  final String? messageForFollower;

  // User Info
  final String? primaryGoal;
  final List<String>? weaknesses;
  final List<String>? strengths;

  // Settings
  final bool? isProfilePublic;
  final bool? openToChat;
  final String? promotedCommunityId;
  final String? subscriptionTier;
  final bool? onboardingCompleted;

  const ProfileUpdateDto({
    this.username,
    this.displayName,
    this.profileUrl,
    this.address,

    this.orgName,
    this.orgLocation,
    this.orgRole,
    this.isInfluencer,
    this.influencerCategory,
    this.messageForFollower,
    this.primaryGoal,
    this.weaknesses,
    this.strengths,
    this.isProfilePublic,
    this.openToChat,
    this.promotedCommunityId,
    this.subscriptionTier,
    this.onboardingCompleted,
  });

  // ================================================================
  // FACTORY CONSTRUCTORS
  // ================================================================

  /// Quick update for profile picture only
  factory ProfileUpdateDto.avatar(String url) {
    return ProfileUpdateDto(profileUrl: url);
  }

  /// Complete onboarding update
  factory ProfileUpdateDto.completeOnboarding() {
    return const ProfileUpdateDto(onboardingCompleted: true);
  }

  /// From existing profile (for editing)
  factory ProfileUpdateDto.fromProfile(UserProfile profile) {
    return ProfileUpdateDto(
      username: profile.username,
      displayName: profile.displayName,
      profileUrl: profile.profileUrl,
      address: profile.address,
      orgName: profile.organizationName,
      orgLocation: profile.organizationLocation,
      orgRole: profile.organizationRole,
      isInfluencer: profile.isInfluencer,
      influencerCategory: profile.influencerCategory,
      messageForFollower: profile.messageForFollower,
      primaryGoal: profile.primaryGoal,
      weaknesses: profile.weaknesses,
      strengths: profile.strengths,
      isProfilePublic: profile.isProfilePublic,
      openToChat: profile.openToChat,
      promotedCommunityId: profile.promotedCommunityId,
      subscriptionTier: profile.subscriptionTier,
      onboardingCompleted: profile.onboardingCompleted,
    );
  }

  // ================================================================
  // TO JSON: For Supabase (Remote)
  // ================================================================

  Map<String, dynamic> toRemoteJson({UserProfile? existingProfile}) {
    final json = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Simple fields
    if (username != null) json['username'] = username;
    if (displayName != null) json['display_name'] = displayName;

    // 🛡️ SANITIZATION: Never persist an absolute local path to the database.
    if (profileUrl != null && !UserProfile.isLocalPath(profileUrl!)) {
      json['profile_url'] = profileUrl;
    } else if (profileUrl != null && UserProfile.isLocalPath(profileUrl!)) {
      // If it's a local path, don't include it in update (don't overwrite with bad data)
      logW('ProfileUpdateDto: Skipping local path in toRemoteJson: $profileUrl');
    }

    if (address != null) json['address'] = address;

    if (subscriptionTier != null) json['subscription_tier'] = subscriptionTier;
    if (isProfilePublic != null) json['is_profile_public'] = isProfilePublic;
    if (openToChat != null) json['open_to_chat'] = openToChat;
    if (promotedCommunityId != null) {
      json['promoted_community_id'] = promotedCommunityId;
    }
    if (onboardingCompleted != null) {
      json['onboarding_completed'] = onboardingCompleted;
    }

    // Organization JSONB (merge with existing)
    if (orgName != null || orgLocation != null || orgRole != null) {
      json['organization'] = {
        'name': orgName ?? existingProfile?.organizationName,
        'location': orgLocation ?? existingProfile?.organizationLocation,
        'your_role': orgRole ?? existingProfile?.organizationRole,
      };
    }

    // Influencer JSONB (merge with existing)
    if (isInfluencer != null ||
        influencerCategory != null ||
        messageForFollower != null) {
      json['influencer'] = {
        'is_influencer': isInfluencer ?? existingProfile?.isInfluencer ?? false,
        'influencer_category':
            influencerCategory ?? existingProfile?.influencerCategory,
        'message_for_follower':
            messageForFollower ?? existingProfile?.messageForFollower,
      };
    }

    // User Info JSONB (merge with existing)
    if (primaryGoal != null || weaknesses != null || strengths != null) {
      json['user_info'] = {
        'primary_goal': primaryGoal ?? existingProfile?.primaryGoal,
        'weaknesses': {'items': weaknesses ?? existingProfile?.weaknesses ?? []},
        'strengths': {'items': strengths ?? existingProfile?.strengths ?? []},
      };
    }

    return json;
  }

  // ================================================================
  // TO JSON: For PowerSync (Local SQLite)
  // ================================================================

  Map<String, dynamic> toLocalJson({UserProfile? existingProfile}) {
    final json = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Simple fields
    if (username != null) json['username'] = username;
    if (displayName != null) json['display_name'] = displayName;

    // 🛡️ SANITIZATION: Never persist an absolute local path to the database.
    if (profileUrl != null && !UserProfile.isLocalPath(profileUrl!)) {
      json['profile_url'] = profileUrl;
    } else if (profileUrl != null && UserProfile.isLocalPath(profileUrl!)) {
      // If it's a local path, don't include it in update (don't overwrite with bad data)
      logW('ProfileUpdateDto: Skipping local path in toLocalJson: $profileUrl');
    }

    if (address != null) json['address'] = address;

    if (subscriptionTier != null) json['subscription_tier'] = subscriptionTier;

    // Booleans as integers for SQLite
    if (isProfilePublic != null) {
      json['is_profile_public'] = isProfilePublic! ? 1 : 0;
    }
    if (openToChat != null) {
      json['open_to_chat'] = openToChat! ? 1 : 0;
    }
    if (promotedCommunityId != null) {
      json['promoted_community_id'] = promotedCommunityId;
    }
    if (onboardingCompleted != null) {
      json['onboarding_completed'] = onboardingCompleted! ? 1 : 0;
    }

    // Organization JSONB as encoded string
    if (orgName != null || orgLocation != null || orgRole != null) {
      json['organization'] = jsonEncode({
        'name': orgName ?? existingProfile?.organizationName,
        'location': orgLocation ?? existingProfile?.organizationLocation,
        'your_role': orgRole ?? existingProfile?.organizationRole,
      });
    }

    // Influencer JSONB as encoded string
    if (isInfluencer != null ||
        influencerCategory != null ||
        messageForFollower != null) {
      json['influencer'] = jsonEncode({
        'is_influencer': isInfluencer ?? existingProfile?.isInfluencer ?? false,
        'influencer_category':
            influencerCategory ?? existingProfile?.influencerCategory,
        'message_for_follower':
            messageForFollower ?? existingProfile?.messageForFollower,
      });
    }

    // User Info JSONB as encoded string
    if (primaryGoal != null || weaknesses != null || strengths != null) {
      json['user_info'] = jsonEncode({
        'primary_goal': primaryGoal ?? existingProfile?.primaryGoal,
        'weaknesses': {'items': weaknesses ?? existingProfile?.weaknesses ?? []},
        'strengths': {'items': strengths ?? existingProfile?.strengths ?? []},
      });
    }

    return json;
  }

  /// Check if DTO has any changes
  bool get hasChanges {
    return username != null ||
        displayName != null ||
        profileUrl != null ||
        address != null ||
        orgName != null ||
        orgLocation != null ||
        orgRole != null ||
        isInfluencer != null ||
        influencerCategory != null ||
        messageForFollower != null ||
        primaryGoal != null ||
        weaknesses != null ||
        strengths != null ||
        isProfilePublic != null ||
        openToChat != null ||
        subscriptionTier != null ||
        onboardingCompleted != null;
  }

  @override
  String toString() {
    final fields = <String>[];
    if (username != null) fields.add('username');
    if (displayName != null) fields.add('displayName');
    if (profileUrl != null) fields.add('profileUrl');
    if (address != null) fields.add('address');
    if (orgName != null) fields.add('orgName');
    if (primaryGoal != null) fields.add('primaryGoal');
    if (onboardingCompleted != null) fields.add('onboardingCompleted');
    return 'ProfileUpdateDto(${fields.join(', ')})';
  }
}

// ================================================================
// PROFILE EXCEPTION
// ================================================================

class ProfileException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const ProfileException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'ProfileException: $message (code: $code)';

  // Common exceptions
  factory ProfileException.notFound() =>
      const ProfileException('Profile not found', code: 'NOT_FOUND');

  factory ProfileException.notAuthenticated() =>
      const ProfileException('User not authenticated', code: 'NOT_AUTH');

  factory ProfileException.invalidData(String field) =>
      ProfileException('Invalid data: $field', code: 'INVALID_DATA');

  factory ProfileException.networkError([dynamic error]) => ProfileException(
    'Network error. Please check your connection.',
    code: 'NETWORK_ERROR',
    originalError: error,
  );

  factory ProfileException.uploadFailed([dynamic error]) => ProfileException(
    'Failed to upload file',
    code: 'UPLOAD_FAILED',
    originalError: error,
  );

  factory ProfileException.syncFailed([dynamic error]) => ProfileException(
    'Failed to sync profile',
    code: 'SYNC_FAILED',
    originalError: error,
  );
}
