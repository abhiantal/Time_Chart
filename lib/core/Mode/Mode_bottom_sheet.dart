// lib/core/ThemeMode/Mode_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:the_time_chart/user_settings/providers/settings_provider.dart';
import 'navigation_bar_type.dart';

class ModeBottomSheet extends StatefulWidget {
  const ModeBottomSheet({super.key});

  @override
  State<ModeBottomSheet> createState() => _ModeBottomSheetState();

  // Static method to easily show the bottom sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(
        0.6,
      ), // Slightly darker barrier for more focus
      builder: (context) => const ModeBottomSheet(),
    );
  }
}

class _ModeBottomSheetState extends State<ModeBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Closes the bottom sheet after a short delay for a smoother UX
  // Closes the bottom sheet after a short delay and navigates
  void _selectAndPop(NavigationBarType type) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        if (type == NavigationBarType.personal) {
          context.goNamed('personalNav');
        } else {
          context.goNamed('socialNav');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = context.watch<SettingsProvider>();

    return SafeArea(
      top: false,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          // The content is now shorter, so we can use a dynamic height
          child: Wrap(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ), // More rounded
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 30,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag Handle
                    Container(
                      margin: const EdgeInsets.only(top: 16, bottom: 12),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.4,
                        ),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),

                    // Header [MODIFIED FOR FOCUS]
                    _buildHeader(context, theme),

                    Divider(
                      height: 1,
                      thickness: 1,
                      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    ),

                    // Content [MODIFIED - ONLY NAVIGATION SELECTOR]
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      child: Column(
                        children: [
                          _buildNavigationSelector(context, settingsProvider),
                          const SizedBox(height: 24),
                          _buildInfoCard(context),
                        ],
                      ),
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

  // [MODIFIED HEADER] - New icon and text to reflect the sole purpose of mode selection
  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.explore_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select App Mode',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Choose your primary experience',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // [KEPT AND ENHANCED] - This is now the main content of the sheet
  Widget _buildNavigationSelector(
    BuildContext context,
    SettingsProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      // The map function is perfect for this. No need to change the logic.
      children: NavigationBarType.values.map((type) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildOptionCard(
            context: context,
            isSelected: provider.navigationBarType == type,
            icon: type.icon,
            title: type.displayName,
            description: type.description,
            gradient: LinearGradient(
              colors: [
                type.getPrimaryColor(isDark).withOpacity(0.8),
                type.getPrimaryColor(isDark),
              ],
            ),
            onTap: () {
              provider.setNavigationBarType(type);
              _selectAndPop(type);
            },
          ),
        );
      }).toList(),
    );
  }

  // [KEPT] - This is the core, highly-styled option card widget. It's excellent.
  Widget _buildOptionCard({
    required BuildContext context,
    required bool isSelected,
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: theme.colorScheme.primary.withOpacity(0.1),
        highlightColor: theme.colorScheme.primary.withOpacity(0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withOpacity(0.4)
                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: isSelected ? gradient : null,
                  color: isSelected ? null : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AnimatedScale(
                scale: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.elasticOut,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [MODIFIED INFO CARD] - Text is more relevant to mode selection
  Widget _buildInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: theme.colorScheme.onTertiaryContainer,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your selected mode is saved automatically for future sessions.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onTertiaryContainer.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
