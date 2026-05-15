// ============================================================
// FEATURE INFO WIDGETS
// lib/widgets/feature_info_widgets.dart
//
// Elite Premium feature information card for The Time Chart.
// Includes sophisticated glassmorphism, depth, and staggered animations.
// ============================================================

import 'dart:ui';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────

/// Describes a button or icon action within a feature.
class ButtonDetail {
  final IconData icon;
  final String label;
  final String description;

  const ButtonDetail({
    required this.icon,
    required this.label,
    required this.description,
  });
}

/// Describes one app feature shown in the elite info card.
class FeatureInfo {
  final String id;
  final String title;
  final String tagline;
  final String whatItDoes;
  final String howItWorks;
  final String howItHelps;
  final IconData icon;
  final Color color;
  final Color colorLight;
  final List<String> steps;
  final List<ButtonDetail> buttons;
  final bool isNew;

  const FeatureInfo({
    required this.id,
    required this.title,
    required this.tagline,
    required this.whatItDoes,
    required this.howItWorks,
    required this.howItHelps,
    required this.icon,
    required this.color,
    required this.colorLight,
    required this.steps,
    this.buttons = const [],
    this.isNew = false,
  });
}

// ─────────────────────────────────────────────────────────────
// 1.  ELITE FEATURE INFO CARD
// ─────────────────────────────────────────────────────────────

class FeatureInfoCard extends StatefulWidget {
  final FeatureInfo feature;
  final double? width;
  final bool showCloseButton;

  const FeatureInfoCard({
    super.key,
    required this.feature,
    this.width,
    this.showCloseButton = false,
  });

  /// Shows the elite info card in a premium, blurred dialog.
  static Future<void> showEliteDialog(BuildContext context, FeatureInfo feature) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(200),
      builder: (context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          child: Material(
            color: Colors.transparent,
            child: FeatureInfoCard(
              feature: feature,
              showCloseButton: true,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<FeatureInfoCard> createState() => _FeatureInfoCardState();
}

class _FeatureInfoCardState extends State<FeatureInfoCard>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late AnimationController _flipCtrl;
  bool _isFlipped = false;

  // Staggered Animations
  late Animation<double> _fadeHeader;
  late Animation<double> _fadeBody;
  late Animation<Offset> _slideHeader;
  late Animation<Offset> _slideBody;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeHeader = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _slideHeader = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    _fadeBody = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    );
    _slideBody = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    ));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _flipCtrl.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_isFlipped) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final w = widget.width ?? double.infinity;
    final f = widget.feature;

    // Adaptive styling based on usage context
    final bool isDialog = widget.showCloseButton;
    final double baseOpacity = isDialog ? 0.85 : 0.98;
    final double blurAmount = isDialog ? 15.0 : 5.0;
    final double headerTopPadding = isDialog ? 44.0 : 32.0;

    return Center(
      child: GestureDetector(
        onTap: _toggleFlip,
        child: AnimatedBuilder(
          animation: _flipCtrl,
          builder: (context, child) {
            final angle = _flipCtrl.value * 3.14159;
            final isBack = angle > 3.14159 / 2;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: Container(
                width: w,
                constraints: const BoxConstraints(maxWidth: 400),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
            // 1. BASE GLASS CONTAINER
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isDark
                            ? colorScheme.surface.withOpacity(baseOpacity)
                            : Colors.white.withOpacity(baseOpacity),
                        isDark
                            ? colorScheme.surface.withOpacity(baseOpacity - 0.1)
                            : Colors.white.withOpacity(baseOpacity - 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: (isDark ? Colors.white : f.color).withOpacity(
                        isDialog ? 0.15 : 0.25,
                      ),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                        blurRadius: isDialog ? 40 : 25,
                        offset: Offset(0, isDialog ? 20 : 10),
                      ),
                      BoxShadow(
                        color: f.color.withOpacity(isDark ? 0.2 : 0.1),
                        blurRadius: isDialog ? 20 : 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: !isBack
                      ? Column(
                          key: const ValueKey('front'),
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // A. PREMIUM GRAPHICAL HEADER
                            _buildPremiumHeader(
                              theme,
                              colorScheme,
                              f,
                              isDark,
                              headerTopPadding,
                            ),

                            // B. MODULAR CONTENT BODY
                            FadeTransition(
                              opacity: _fadeBody,
                              child: SlideTransition(
                                position: _slideBody,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                  child: Column(
                                    children: [
                                      _EliteModule(
                                        icon: Icons.auto_awesome_rounded,
                                        title: 'The Core Power',
                                        text: f.whatItDoes,
                                        color: f.color,
                                        theme: theme,
                                      ),
                                      const SizedBox(height: 16),
                                      _EliteModule(
                                        icon: Icons.bolt_rounded,
                                        title: 'In Action',
                                        text: f.howItWorks,
                                        color: Colors.orange.shade800,
                                        theme: theme,
                                      ),
                                      if (f.steps.isNotEmpty) ...[
                                        const SizedBox(height: 24),
                                        _EliteSteps(
                                          steps: f.steps,
                                          color: f.color,
                                          theme: theme,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // C. BENEFIT BOX (Footer-like)
                            FadeTransition(
                              opacity: _fadeBody,
                              child: _EliteBenefitBox(feature: f, theme: theme),
                            ),
                          ],
                        )
                      : Transform(
                          key: const ValueKey('back'),
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(3.14159),
                          child: _buildBackSide(theme, colorScheme, f, isDark, headerTopPadding),
                        ),
              ),
            ),
          ),

                    // 2. NEW BADGE
                    if (f.isNew && !isBack)
                      Positioned(
                        top: -8,
                        left: 24,
                        child: _buildNewBadge(theme, f),
                      ),

                    // 3. CLOSE BUTTON (If dialog mode)
                    if (widget.showCloseButton)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: _buildCloseButton(context, isDark),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackSide(
    ThemeData theme,
    ColorScheme colorScheme,
    FeatureInfo f,
    bool isDark,
    double topPadding,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, topPadding, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'INTERFACE ACTIONS',
            style: theme.textTheme.labelLarge?.copyWith(
              color: f.color,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How to interact with ${f.title}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 32),
          ...f.buttons.map((btn) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _EliteModule(
                  icon: btn.icon,
                  title: btn.label,
                  text: btn.description,
                  color: f.color,
                  theme: theme,
                ),
              )),
          const SizedBox(height: 16),
          // Tap to flip back hit
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flip_camera_android_rounded,
                size: 14,
                color: f.color.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                'TAP TO FLIP BACK',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: f.color.withOpacity(0.6),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    FeatureInfo f,
    bool isDark,
    double topPadding,
  ) {
    return FadeTransition(
      opacity: _fadeHeader,
      child: SlideTransition(
        position: _slideHeader,
        child: Container(
          padding: EdgeInsets.fromLTRB(24, topPadding, 24, 24),
          child: Column(
            children: [
              // Icon with Glow
              Stack(
                alignment: Alignment.center,
                children: [
                  // Glow Effect
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: f.color.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  // Icon Container
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [f.color, f.color.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(f.icon, color: Colors.white, size: 34),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Typographic Text
              Text(
                f.title.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: f.color,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                f.tagline,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  height: 1.1,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewBadge(ThemeData theme, FeatureInfo f) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Text(
        'NEW FEATURE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            ),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}



class _EliteModule extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;
  final ThemeData theme;

  const _EliteModule({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.3 : 0.15),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.7,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _EliteSteps extends StatelessWidget {
  final List<String> steps;
  final Color color;
  final ThemeData theme;

  const _EliteSteps({
    required this.steps,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: steps.asMap().entries.map((e) {
        final isLast = e.key == steps.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color.withAlpha(40),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withAlpha(80), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withAlpha(40),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    e.value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(200),
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EliteBenefitBox extends StatelessWidget {
  final FeatureInfo feature;
  final ThemeData theme;
  const _EliteBenefitBox({required this.feature, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.tertiary.withOpacity(isDark ? 0.15 : 0.1),
            colorScheme.tertiary.withOpacity(isDark ? 0.05 : 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: colorScheme.tertiary.withOpacity(isDark ? 0.4 : 0.2),
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.tertiary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star_rounded, color: colorScheme.tertiary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WHY IT MATTERS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  feature.howItHelps,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.6,
                    fontSize: 15,
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

// ─────────────────────────────────────────────────────────────
// CENTRALIZED FEATURE REGISTRY
// ─────────────────────────────────────────────────────────────

class EliteFeatures {
  static const dayTasks = FeatureInfo(
    id: 'day_tasks_info',
    title: 'Day Tasks & Points',
    tagline: 'Master your daily rhythm with AI-powered tracking.',
    whatItDoes:
        'A comprehensive task management system that tracks daily productivity through points, bonuses, and penalties based on activity, duration, and on-time completion.',
    howItWorks:
        'Create tasks with categories and timelines. Log progress through text or media feedback throughout the day. Our AI verifies your efforts to calculate points automatically.',
    howItHelps:
        'Motivates consistency with real-time feedback, reduces mental load through clear visualization, and uses AI to ensure your progress is authentic and rewarding.',
    icon: Icons.auto_awesome_mosaic_rounded,
    color: Color(0xFF2196F3),
    colorLight: Color(0xFFE3F2FD),
    steps: [
      'Add tasks with categories & priorities',
      'Log progress with text or media feedback',
      'Earn points based on duration & on-time activity',
      'AI verifies and awards your daily consistency',
    ],
    buttons: [
      ButtonDetail(icon: Icons.add_circle_outline_rounded, label: 'Add Task', description: 'Create a new daily task with priority.'),
      ButtonDetail(icon: Icons.history_edu_rounded, label: 'Log Progress', description: 'Add notes or photos to verify completion.'),
      ButtonDetail(icon: Icons.analytics_outlined, label: 'View Stats', description: 'Check your daily points breakdown.'),
    ],
    isNew: true,
  );

  static const weekTasks = FeatureInfo(
    id: 'week_tasks_info',
    title: 'Weekly Master Plan',
    tagline: 'Visualize your entire week with crystal clarity.',
    whatItDoes:
        'A high-level weekly schedule that coordinates your time slots with specific tasks, helping you maintain a consistent rhythm across seven days.',
    howItWorks:
        'Define recurring time slots for your routine. Map your tasks into this grid to see overlaps and gaps. Sync your progress across all days automatically.',
    howItHelps:
        'Reduces decision fatigue by pre-planning your week, ensures no important activities are forgotten, and provides a comprehensive view of your time distribution.',
    icon: Icons.calendar_view_week_rounded,
    color: Color(0xFF6366F1),
    colorLight: Color(0xFFEEF2FF),
    steps: [
      'Create custom time slots for your routine',
      'Drag and drop tasks into the weekly grid',
      'Track progress & completion status weekly',
      'Analyze your performance trends over time',
    ],
    buttons: [
      ButtonDetail(icon: Icons.grid_view_rounded, label: 'Grid Edit', description: 'Drag and drop tasks into your week.'),
      ButtonDetail(icon: Icons.copy_rounded, label: 'Clone Week', description: 'Copy this schedule to the next week.'),
      ButtonDetail(icon: Icons.auto_awesome_rounded, label: 'AI Planner', description: 'Optimize your slots for max efficiency.'),
    ],
    isNew: true,
  );

  static const longGoals = FeatureInfo(
    id: 'long_goals_info',
    title: 'Visionary Goals',
    tagline: 'Transform your long-term dreams into documented reality.',
    whatItDoes:
        'A comprehensive goal-setting system that tracks complex milestones over months or years, utilizing AI to verify authentic progress and consistency.',
    howItWorks:
        'Set visionary outcomes and track them with multi-media feedback. Our AI verifies your efforts, while our variance-aware scoring rewards true consistency over sporadic bursts.',
    howItHelps:
        'Keeps your "North Star" goals visible, gamifies steady progress with tier-based rewards, and provides deep analytical insights into your long-term success patterns.',
    icon: Icons.auto_graph_rounded,
    color: Color(0xFF8B5CF6),
    colorLight: Color(0xFFF5F3FF),
    steps: [
      'Define your vision, motivation, and outcome',
      'Log multi-media feedback for AI verification',
      'Maintain consistency for top tier rewards',
      'Achieve milestones & earn elite goal badges',
    ],
    buttons: [
      ButtonDetail(icon: Icons.auto_graph_rounded, label: 'Trends', description: 'Visualize your progress over months.'),
      ButtonDetail(icon: Icons.add_a_photo_rounded, label: 'Snapshot', description: 'Capture a moment of your goal journey.'),
      ButtonDetail(icon: Icons.workspace_premium_rounded, label: 'Rewards', description: 'Claim exclusive visionary badges.'),
    ],
    isNew: true,
  );

  static const buckets = FeatureInfo(
    id: 'bucket_tasks_info',
    title: 'Life Bucket List',
    tagline: 'Turn your life dreams into achievable checklists.',
    whatItDoes:
        'A dedicated module for non-time-bound goals. Whether it\'s a hobby, a professional project, or a travel list, buckets help you organize and track them without the pressure of a daily schedule.',
    howItWorks:
        'Create a bucket, then use the AI engine to generate an actionable checklist. Document your progress with feedback and media to earn professional quality ratings and tiers.',
    howItHelps:
        'Eliminates the overwhelm of massive goals. By breaking dreams into interactive sub-tasks, you create a sustainable path to achievement while earning points for consistency.',
    icon: Icons.inventory_2_outlined,
    color: Color(0xFF0D9488), // Teal primary
    colorLight: Color(0xFFF0FDFA),
    steps: [
      'Define your vision and give it a title',
      'Generate an AI-powered checklist plan',
      'Track progress with media & feedback',
      'Unlock Radiant & Nova status tiers',
    ],
    buttons: [
      ButtonDetail(icon: Icons.checklist_rtl_rounded, label: 'Auto-Check', description: 'AI breaks down your dream into steps.'),
      ButtonDetail(icon: Icons.style_rounded, label: 'Themes', description: 'Apply premium visual styles to your bucket.'),
      ButtonDetail(icon: Icons.share_rounded, label: 'Public Link', description: 'Share your bucket progress with the world.'),
    ],
    isNew: true,
  );

  static const competition = FeatureInfo(
    id: 'competition_info',
    title: 'Battle Arena',
    tagline: 'Turn your productivity into a legendary battle.',
    whatItDoes:
        'A social gamification system that lets you compare your productivity scores with friends and rivals. It tracks your relative performance across all metrics.',
    howItWorks:
        'Add competitors to your arena. The system automatically syncs your daily points from tasks, goals, and habits. Use charts to analyze exactly where you lead or lag.',
    howItHelps:
        'Drives explosive consistency through healthy competition, reveals success patterns from your top rivals, and keeps you motivated during productivity plateaus.',
    icon: Icons.military_tech_rounded,
    color: Color(0xFFC026D3), // Deep Magenta/Purple
    colorLight: Color(0xFFFDF4FF),
    steps: [
      'Add rivals to your Battle Arena dashboard',
      'Earn Elite Points from daily activities',
      'Analyze variance charts to spot strengths',
      'Climb the leaderboard to claim total victory',
    ],
    buttons: [
      ButtonDetail(icon: Icons.person_add_alt_1_rounded, label: 'Invite', description: 'Add a competitor to your arena.'),
      ButtonDetail(icon: Icons.query_stats_rounded, label: 'Compare', description: 'Side-by-side performance analysis.'),
      ButtonDetail(icon: Icons.celebration_rounded, label: 'Taunt', description: 'Send a nudge to your rivals.'),
    ],
    isNew: true,
  );

  static const leaderboard = FeatureInfo(
    id: 'leaderboard_info',
    title: 'Champions League',
    tagline: 'Rise through the ranks of global high-achievers.',
    whatItDoes:
        'A global ranking system that celebrates productivity across the entire community. It tracks your progress against every builder using The Time Chart.',
    howItWorks:
        'Earn points through daily tasks, streak consistency, and goal completion. Your rank updates in real-time as you climb through mystical tiers from Contender to Mystic Sentinel.',
    howItHelps:
        'Provides a grand perspective on your growth, connects you with the community of high-performers, and celebrates your mastery with premium medals and trophies.',
    icon: Icons.emoji_events_rounded,
    color: Color(0xFFF1C40F), // Gold
    colorLight: Color(0xFFFFF9E6),
    steps: [
      'Complete tasks & goals to earn Elite Points',
      'Build long streaks to multiply your scores',
      'Earn medals that signify your rank tier',
      'Make your profile public to join the board',
    ],
    buttons: [
      ButtonDetail(icon: Icons.shield_rounded, label: 'Tiers', description: 'View all ranks from Contender to Sentinel.'),
      ButtonDetail(icon: Icons.military_tech_rounded, label: 'Medals', description: 'Browse your collection of achievements.'),
      ButtonDetail(icon: Icons.public_rounded, label: 'Go Public', description: 'Switch visibility to join global rankings.'),
    ],
    isNew: true,
  );

  static const mentoring = FeatureInfo(
    id: 'mentoring_info',
    title: 'Mentoring Hub',
    tagline: 'Accelerate growth through shared accountability.',
    whatItDoes:
        'A secure, permission-based system that allows you to share your productivity journey with mentors or guide others as a mentee.',
    howItWorks:
        'Request access or share your own with teammates. Define specific dashboard permissions (Tasks, Goals, Stats). Monitor live progress and provide feedback to stay on track together.',
    howItHelps:
        'Eliminates isolation by connecting you with experts, builds strong accountability loops, and ensures that your goals are being supported by those you trust.',
    icon: Icons.supervisor_account_rounded,
    color: Color(0xFF3B82F6), // Bright Blue
    colorLight: Color(0xFFEFF6FF),
    steps: [
      'Request or offer dashboard access to others',
      'Define exactly which modules are visible',
      'Monitor live progress in the Mentoring Hub',
      'Achieve legendary goals through team support',
    ],
    buttons: [
      ButtonDetail(icon: Icons.vpn_key_rounded, label: 'Access', description: 'Manage sharing permissions for your data.'),
      ButtonDetail(icon: Icons.connect_without_contact_rounded, label: 'Buddy UP', description: 'Connect with a productivity partner.'),
      ButtonDetail(icon: Icons.speed_rounded, label: 'Live View', description: 'Real-time observation of mentee progress.'),
    ],
    isNew: true,
  );

  static const dashboard = FeatureInfo(
    id: 'dashboard_info',
    title: 'Executive Dashboard',
    tagline: 'Your productivity, unified and visualized.',
    whatItDoes:
        'The central intelligence hub of your productivity journey. It aggregates goals, tasks, trends, and scores into a single high-fidelity overview.',
    howItWorks:
        'Real-time metrics from every module are synchronized here. Use the 10 specialized detail views to deep-dive into streaks, mood patterns, and historical performance.',
    howItHelps:
        'Provides the "Big Picture" needed for effective long-term planning. By seeing how your mood, streaks, and tasks correlate, you can optimize your life with data-driven precision.',
    icon: Icons.dashboard_customize_rounded,
    color: Color(0xFF6366F1), // Indigo
    colorLight: Color(0xFFEEF2FF),
    steps: [
      'Monitor live productivity via the Productivity Clock',
      'Analyze historical trends across 10 specialized views',
      'Track your Global Rank and Points in real-time',
      'Correlate mood patterns with task completion',
    ],
    buttons: [
      ButtonDetail(icon: Icons.timer_rounded, label: 'Clock', description: 'Toggle the high-fidelity productivity timer.'),
      ButtonDetail(icon: Icons.insights_rounded, label: 'Analysis', description: 'Open deep-dive cross-module statistics.'),
      ButtonDetail(icon: Icons.layers_rounded, label: 'Layout', description: 'Customize your dashboard overview modules.'),
    ],
    isNew: false,
  );

  static const diary = FeatureInfo(
    id: 'diary_info',
    title: 'Mindful Diary',
    tagline: 'Document your journey. Master your emotions.',
    whatItDoes:
        'A secure, premium space for digital journaling. It combines traditional reflection with advanced mood tracking and AI-driven growth analysis.',
    howItWorks:
        'Log your daily thoughts and select your current mood. Our AI analyzes your writing to provide summaries and correlations between your activities and your mental state.',
    howItHelps:
        'Journaling reduces stress and improves long-term memory. By tracking your mood over time, you can identify patterns and triggers that affect your overall well-being.',
    icon: Icons.auto_stories_rounded,
    color: Color(0xFF8B5CF6), // Violet
    colorLight: Color(0xFFF5F3FF),
    steps: [
      'Record your daily experiences and major milestones',
      'Track your emotional state with the Mood Matrix',
      'Generate AI-powered summaries of your reflections',
      'Deep-dive into historical entries with advanced filters',
    ],
    buttons: [
      ButtonDetail(icon: Icons.mood_rounded, label: 'Matrix', description: 'Precision emotional tracking interface.'),
      ButtonDetail(icon: Icons.psychology_rounded, label: 'AI Review', description: 'Generate insights from your journal entries.'),
      ButtonDetail(icon: Icons.lock_rounded, label: 'Privacy', description: 'Secure your diary with biometric locking.'),
    ],
    isNew: false,
  );

  static const community = FeatureInfo(
    id: 'community_info',
    title: 'Elite Communities',
    tagline: 'Collaborate. Connect. Conquer.',
    whatItDoes:
        'A premium networking hub designed for high-achievers. It combines secure direct messaging with a global community marketplace for group coordination and goal sharing.',
    howItWorks:
        'Discover public communities in the Global Market or build your own private ecosystem. Use community rules, categories, and roles to manage your network and stay aligned with your growth team.',
    howItHelps:
        'Reduces the friction of isolated growth by connecting you with a driven community. Peer accountability and shared knowledge accelerate your journey toward mastery.',
    icon: Icons.forum_rounded,
    color: Color(0xFFE91E63), // Pink/Rose
    colorLight: Color(0xFFFCE4EC),
    steps: [
      'Browse the Global Market for goal-aligned communities',
      'Create your own hub and define rule-based environments',
      'Use secure DM channels for personal coordination',
      'Promote your community to reach new milestones',
    ],
    buttons: [
      ButtonDetail(icon: Icons.storefront_rounded, label: 'Market', description: 'Discover new communities to join.'),
      ButtonDetail(icon: Icons.admin_panel_settings_rounded, label: 'Mod Tools', description: 'Advanced tools for hub administrators.'),
      ButtonDetail(icon: Icons.rocket_launch_rounded, label: 'Promote', description: 'Boost visibility of your community.'),
    ],
    isNew: true,
  );

  static const postFeed = FeatureInfo(
    id: 'post_feed_info',
    title: 'Chronicle Feed',
    tagline: 'Relive your journey through a premium vertical feed.',
    whatItDoes:
        'A high-fidelity vertical feed that aggregates your posts, snapshots, and live updates into a single immersive experience, similar to premium social platforms.',
    howItWorks:
        'Navigate through your entire history or specific categories (Posts, Live, Snapshots) using smooth vertical scrolling. All media is optimized for instant loading and high-quality display.',
    howItHelps:
        'Provides a cinematic perspective on your long-term growth, allows you to quickly verify your daily consistency, and makes sharing your achievements with others an elegant experience.',
    icon: Icons.dynamic_feed_rounded,
    color: Color(0xFFF1C40F), // Sun Yellow
    colorLight: Color(0xFFFFF9E6),
    steps: [
      'Tap any post in your profile grid to enter the feed',
      'Scroll vertically to browse your historical journey',
      'Use tab filters to focus on media, tasks, or live updates',
      'Interact with your posts and analyze your progress',
    ],
    buttons: [
      ButtonDetail(icon: Icons.filter_list_rounded, label: 'Tabs', description: 'Filter feed by media, tasks, or life events.'),
      ButtonDetail(icon: Icons.auto_awesome_motion_rounded, label: 'autoplay', description: 'Toggle auto-scroll through your journey.'),
      ButtonDetail(icon: Icons.download_done_rounded, label: 'Batch', description: 'Export multiple memories into a highlights reel.'),
    ],
    isNew: true,
  );
}
