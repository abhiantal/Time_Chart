// ================================================================
// FILE: lib/user_profile/profile_widgets.dart
// Reusable UI components for profile system
// Includes: Avatar, Chips, Cards, Selectors, Progress, Forms
// ================================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../../widgets/bar_progress_indicator.dart';
import 'profile_models.dart';

// ================================================================
// PROFILE AVATAR
// ================================================================

/// Displays user avatar with fallback, loading, and edit capability
class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackText;
  final double size;
  final bool showEditButton;
  final bool isLoading;
  final double? uploadProgress;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;
  final Color? borderColor;
  final double borderWidth;
  final BoxFit fit;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.fallbackText,
    this.size = 100,
    this.showEditButton = false,
    this.isLoading = false,
    this.uploadProgress,
    this.onTap,
    this.onEditTap,
    this.borderColor,
    this.borderWidth = 3,
    this.fit = BoxFit.cover,
  });

  /// Small avatar for lists
  factory ProfileAvatar.small({
    String? imageUrl,
    String? fallbackText,
    VoidCallback? onTap,
  }) {
    return ProfileAvatar(
      imageUrl: imageUrl,
      fallbackText: fallbackText,
      size: 40,
      onTap: onTap,
    );
  }

  /// Medium avatar for cards
  factory ProfileAvatar.medium({
    String? imageUrl,
    String? fallbackText,
    VoidCallback? onTap,
  }) {
    return ProfileAvatar(
      imageUrl: imageUrl,
      fallbackText: fallbackText,
      size: 64,
      onTap: onTap,
    );
  }

  /// Large avatar for profile pages
  factory ProfileAvatar.large({
    String? imageUrl,
    String? fallbackText,
    bool showEditButton = false,
    VoidCallback? onTap,
    VoidCallback? onEditTap,
  }) {
    return ProfileAvatar(
      imageUrl: imageUrl,
      fallbackText: fallbackText,
      size: 120,
      showEditButton: showEditButton,
      onTap: onTap,
      onEditTap: onEditTap,
    );
  }

  /// Extra large avatar for onboarding
  factory ProfileAvatar.hero({
    String? imageUrl,
    XFile? localImage,
    String? fallbackText,
    bool isLoading = false,
    double? uploadProgress,
    VoidCallback? onTap,
  }) {
    return ProfileAvatar(
      imageUrl: localImage != null ? localImage.path : imageUrl,
      fallbackText: fallbackText,
      size: 180,
      showEditButton: true,
      isLoading: isLoading,
      uploadProgress: uploadProgress,
      onTap: onTap,
      onEditTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderColor = borderColor ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Main Avatar Container
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: effectiveBorderColor,
                width: borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: effectiveBorderColor.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(child: _buildAvatarContent(context)),
          ),

          // Loading Overlay
          if (isLoading || (uploadProgress != null && uploadProgress! < 1.0))
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.5),
                ),
                child: Center(
                  child: uploadProgress != null
                      ? CircularProgressIndicator(
                          value: uploadProgress,
                          strokeWidth: 3,
                          color: Colors.white,
                        )
                      : const CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                ),
              ),
            ),

          // Edit Button
          if (showEditButton && !isLoading)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: onEditTap ?? onTap,
                child: Container(
                  padding: EdgeInsets.all(size * 0.08),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: size * 0.15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent(BuildContext context) {
    // Network image
    if (imageUrl != null &&
        (imageUrl!.startsWith('http') || imageUrl!.startsWith('https'))) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: fit,
        placeholder: (_, __) => _buildPlaceholder(context),
        errorWidget: (_, __, ___) => _buildFallback(context),
      );
    }

    // Local file (fallback for non-network strings)
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      File file;
      try {
        if (imageUrl!.startsWith('file:')) {
          file = File(Uri.parse(imageUrl!).toFilePath());
        } else {
          file = File(imageUrl!);
        }

        if (file.existsSync()) {
          return Image.file(
            file,
            fit: fit,
            errorBuilder: (_, __, ___) => _buildFallback(context),
          );
        }
      } catch (_) {
        // Fallback
      }
    }

    // Fallback
    return _buildFallback(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.3),
            theme.colorScheme.secondary.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _getInitials();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    if (fallbackText == null || fallbackText!.isEmpty) return '?';
    final parts = fallbackText!.split(RegExp(r'[_\s]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fallbackText!
        .substring(0, fallbackText!.length >= 2 ? 2 : 1)
        .toUpperCase();
  }
}

// ================================================================
// PROFILE COMPLETION CARD
// ================================================================

/// Shows profile completion progress with suggestions
class ProfileCompletionCard extends StatelessWidget {
  final double completionPercentage;
  final VoidCallback? onTap;
  final bool showSuggestions;
  final UserProfile? profile;

  const ProfileCompletionCard({
    super.key,
    required this.completionPercentage,
    this.onTap,
    this.showSuggestions = true,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (completionPercentage * 100).toInt();
    final isComplete = percentage >= 100;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isComplete
                ? [theme.colorScheme.primary, theme.colorScheme.secondary]
                : [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.secondaryContainer,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        (isComplete ? Colors.white : theme.colorScheme.primary)
                            .withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isComplete
                        ? Icons.check_circle_rounded
                        : Icons.person_outline_rounded,
                    color: isComplete
                        ? Colors.white
                        : theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isComplete
                            ? 'Profile Complete!'
                            : 'Complete Your Profile',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isComplete
                              ? Colors.white
                              : theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isComplete
                            ? 'Great job! Your profile is fully set up.'
                            : 'Add more details to stand out',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              (isComplete
                                      ? Colors.white
                                      : theme.colorScheme.onPrimaryContainer)
                                  .withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isComplete)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Progress Bar
            CustomProgressIndicator(
              progress: completionPercentage,
              orientation: ProgressOrientation.horizontal,
              width: double.infinity,
              baseHeight: 12,
              maxHeightIncrease: 6,
              gradientColors: isComplete
                  ? [Colors.white, Colors.white70]
                  : [theme.colorScheme.primary, theme.colorScheme.secondary],
              borderRadius: 8,
              backgroundColor:
                  (isComplete
                          ? Colors.white
                          : theme.colorScheme.onPrimaryContainer)
                      .withOpacity(0.2),
              progressBarName: '',
              progressLabelDisplay: ProgressLabelDisplay.box,
              customProgressLabel: '$percentage%',
              progressLabelBackgroundColor: isComplete
                  ? Colors.white
                  : theme.colorScheme.primary,
              progressLabelStyle: TextStyle(
                color: isComplete ? theme.colorScheme.primary : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              animateProgressLabel: true,
              animated: true,
            ),

            // Suggestions
            if (showSuggestions && !isComplete && profile != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _buildSuggestions(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSuggestions(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = <String>[];

    if (profile == null) return [];

    if (profile!.profileUrl == null || profile!.profileUrl!.isEmpty) {
      suggestions.add('Add photo');
    }
    if (profile!.address == null || profile!.address!.isEmpty) {
      suggestions.add('Add location');
    }
    if (!profile!.hasOrganization) {
      suggestions.add('Add organization');
    }
    if (!profile!.hasGoals) {
      suggestions.add('Set goals');
    }

    return suggestions.take(3).map((suggestion) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              suggestion,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

// ================================================================
// CHIP SELECTOR (Multi-Select)
// ================================================================

/// Multi-select chip component with custom input support
class ChipSelector extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final String? customInputHint;
  final TextEditingController? customInputController;
  final int maxSelection;
  final bool allowCustom;
  final bool showSelectedFirst;

  const ChipSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.customInputHint,
    this.customInputController,
    this.maxSelection = 10,
    this.allowCustom = true,
    this.showSelectedFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sort options if showSelectedFirst
    final sortedOptions = showSelectedFirst
        ? [
            ...options.where((o) => selected.contains(o)),
            ...options.where((o) => !selected.contains(o)),
          ]
        : options;

    // Get custom selections (not in options)
    final customSelections = selected
        .where((s) => !options.contains(s))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chips Wrap
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            // Standard options
            ...sortedOptions.map((option) {
              final isSelected = selected.contains(option);
              return _buildChip(
                context,
                label: option,
                isSelected: isSelected,
                onTap: () => _toggleSelection(option),
              );
            }),

            // Custom selections
            ...customSelections.map((custom) {
              return _buildChip(
                context,
                label: custom,
                isSelected: true,
                isCustom: true,
                onTap: () => _toggleSelection(custom),
              );
            }),
          ],
        ),

        // Custom Input
        if (allowCustom) ...[
          const SizedBox(height: 16),
          _buildCustomInput(context),
        ],

        // Selection count
        if (maxSelection < 100) ...[
          const SizedBox(height: 8),
          Text(
            '${selected.length}/$maxSelection selected',
            style: theme.textTheme.bodySmall?.copyWith(
              color: selected.length >= maxSelection
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    bool isCustom = false,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(
                    isCustom ? Icons.star_rounded : Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomInput(BuildContext context) {
    final theme = Theme.of(context);
    final controller = customInputController ?? TextEditingController();

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: customInputHint ?? 'Add custom...',
              prefixIcon: const Icon(Icons.add_rounded),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            onSubmitted: (value) => _addCustom(controller),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filled(
          onPressed: () => _addCustom(controller),
          icon: const Icon(Icons.add_rounded),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
          ),
        ),
      ],
    );
  }

  void _toggleSelection(String option) {
    final newSelection = List<String>.from(selected);
    if (newSelection.contains(option)) {
      newSelection.remove(option);
    } else if (newSelection.length < maxSelection) {
      newSelection.add(option);
    }
    onChanged(newSelection);
  }

  void _addCustom(TextEditingController controller) {
    final value = controller.text.trim();
    if (value.isNotEmpty && !selected.contains(value)) {
      if (selected.length < maxSelection) {
        onChanged([...selected, value]);
        controller.clear();
      }
    }
  }
}

// ================================================================
// GOAL SELECTOR (Single Select)
// ================================================================

/// Single-select goal component with visual emphasis
class GoalSelector extends StatelessWidget {
  final List<String> goals;
  final String? selectedGoal;
  final ValueChanged<String> onSelected;
  final bool allowCustom;
  final TextEditingController? customController;

  const GoalSelector({
    super.key,
    required this.goals,
    required this.selectedGoal,
    required this.onSelected,
    this.allowCustom = true,
    this.customController,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final isCustomSelected =
        selectedGoal != null && !goals.contains(selectedGoal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Goals Grid
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...goals.map((goal) {
              final isSelected = selectedGoal == goal;
              return _buildGoalChip(context, goal, isSelected);
            }),
            if (isCustomSelected)
              _buildGoalChip(context, selectedGoal!, true, isCustom: true),
          ],
        ),

        // Custom Input
        if (allowCustom) ...[
          const SizedBox(height: 20),
          _buildCustomGoalInput(context),
        ],
      ],
    );
  }

  Widget _buildGoalChip(
    BuildContext context,
    String goal,
    bool isSelected, {
    bool isCustom = false,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => onSelected(goal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : theme.colorScheme.outline.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                isCustom ? Icons.star_rounded : Icons.check_circle_rounded,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              goal,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomGoalInput(BuildContext context) {
    final theme = Theme.of(context);
    final controller = customController ?? TextEditingController();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Or set your own goal',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Enter your goal...',
                    prefixIcon: const Icon(Icons.flag_rounded),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      onSelected(value.trim());
                      controller.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    onSelected(controller.text.trim());
                    controller.clear();
                  }
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(52, 52),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================================================================
// TOGGLE CARD
// ================================================================

/// Card with toggle switch for boolean settings
class ToggleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final bool enabled;

  const ToggleCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveActiveColor = activeColor ?? theme.colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: value
            ? effectiveActiveColor.withOpacity(0.1)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value
              ? effectiveActiveColor.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: value
                  ? effectiveActiveColor.withOpacity(0.2)
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: value
                  ? effectiveActiveColor
                  : theme.colorScheme.onSurfaceVariant,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: enabled
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Switch
          Switch.adaptive(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: effectiveActiveColor,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// SUBSCRIPTION TIER CARD
// ================================================================

/// Card for subscription tier selection
class SubscriptionTierCard extends StatelessWidget {
  final String tier;
  final String title;
  final String price;
  final List<String> features;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badge;
  final IconData icon;

  const SubscriptionTierCard({
    super.key,
    required this.tier,
    required this.title,
    required this.price,
    required this.features,
    required this.isSelected,
    required this.onTap,
    this.badge,
    this.icon = Icons.star_outline_rounded,
  });

  /// Free tier
  factory SubscriptionTierCard.free({
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SubscriptionTierCard(
      tier: 'free',
      title: 'Free',
      price: '\$0/month',
      features: const [
        'Basic task management',
        '5 user comparisons',
        'Basic analytics',
        'Community access',
      ],
      isSelected: isSelected,
      onTap: onTap,
      icon: Icons.person_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),

                // Title & Price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badge!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Checkmark
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Features
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// PROFILE INFO CARD
// ================================================================

/// Card displaying profile information section
class ProfileInfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<ProfileInfoItem> items;
  final VoidCallback? onEditTap;

  const ProfileInfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onEditTap != null)
                IconButton(
                  onPressed: onEditTap,
                  icon: const Icon(Icons.edit_rounded),
                  iconSize: 20,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),

          if (items.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Items
            ...items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                child: entry.value,
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// Single info item for ProfileInfoCard
class ProfileInfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  const ProfileInfoItem({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ================================================================
// FEATURE ITEM
// ================================================================

/// Feature highlight item for welcome/info screen
class FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color? iconColor;

  const FeatureItem({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: effectiveIconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: effectiveIconColor, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// SECTION HEADER
// ================================================================

/// Section header with optional action button
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final IconData? actionIcon;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null || actionIcon != null)
            TextButton.icon(
              onPressed: onActionTap,
              icon: Icon(actionIcon ?? Icons.arrow_forward_rounded, size: 18),
              label: Text(actionLabel ?? ''),
            ),
        ],
      ),
    );
  }
}

// ================================================================
// EMPTY STATE
// ================================================================

/// Empty state placeholder
class ProfileEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const ProfileEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onActionTap != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onActionTap,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ================================================================
// PROFILE BADGE
// ================================================================

/// Badge for subscription tier or special status
class ProfileBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double fontSize;

  const ProfileBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.fontSize = 10,
  });

  factory ProfileBadge.free() {
    return const ProfileBadge(
      label: 'FREE',
      backgroundColor: Colors.grey,
      textColor: Colors.white,
    );
  }

  factory ProfileBadge.pro() {
    return const ProfileBadge(
      label: 'PRO',
      backgroundColor: Color(0xFF6366F1),
      textColor: Colors.white,
      icon: Icons.star_rounded,
    );
  }

  factory ProfileBadge.elite() {
    return const ProfileBadge(
      label: 'ELITE',
      backgroundColor: Color(0xFFF59E0B),
      textColor: Colors.white,
      icon: Icons.diamond_rounded,
    );
  }

  factory ProfileBadge.influencer() {
    return const ProfileBadge(
      label: 'INFLUENCER',
      backgroundColor: Color(0xFFEC4899),
      textColor: Colors.white,
      icon: Icons.verified_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primary;
    final fgColor = textColor ?? Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fgColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// LOADING SKELETON
// ================================================================

/// Shimmer loading skeleton for profile
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar skeleton
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 24),

          // Name skeleton
          Container(
            width: 160,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),

          // Email skeleton
          Container(
            width: 200,
            height: 16,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 32),

          // Card skeletons
          for (int i = 0; i < 3; i++) ...[
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
