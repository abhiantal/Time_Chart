import 'package:provider/provider.dart';
import '../../../../user_profile/create_edit_profile/profile_provider.dart';
import '../../../../widgets/bar_progress_indicator.dart';
import '../../../../widgets/metric_indicators.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dashboard_model.dart';
import '../../../../widgets/error_handler.dart';
import 'shared_widgets.dart';

class _Pal {
  static const Color heat0Dark = Color(0xFF1E1E2E);
  static const Color heat0Light = Color(0xFFF3F4F6);
  static const Color heat1 = Color(0xFFEF4444);
  static const Color heat2 = Color(0xFFF59E0B);
  static const Color heat3 = Color(0xFF84CC16);
  static const Color heat4 = Color(0xFF22C55E);

  static const List<Color> moodLow = [Color(0xFFEF4444), Color(0xFFF97316)];
  static const List<Color> moodMid = [Color(0xFFFBBF24), Color(0xFF10B981)];
  static const List<Color> moodHigh = [Color(0xFF10B981), Color(0xFF06B6D4)];

  static Color heatColor(bool active, int intensity, bool isDark, Color primaryColor) {
    if (!active) {
      return isDark ? heat0Dark : heat0Light;
    }
    if (intensity <= 1) return primaryColor.withOpacity(0.18);
    if (intensity == 2) return primaryColor.withOpacity(0.40);
    if (intensity == 3) return primaryColor.withOpacity(0.68);
    return primaryColor;
  }

  static Color moodColor(double v) {
    if (v <= 3) return moodLow.first;
    if (v <= 5) return Color.lerp(moodLow.last, moodMid.first, (v - 3) / 2)!;
    if (v <= 7) return Color.lerp(moodMid.first, moodMid.last, (v - 5) / 2)!;
    return Color.lerp(moodMid.last, moodHigh.last, (v - 7) / 3)!;
  }

  static String moodEmoji(double v) {
    if (v >= 9) return '🤩';
    if (v >= 7.5) return '😄';
    if (v >= 6) return '😊';
    if (v >= 4.5) return '😐';
    if (v >= 3) return '😔';
    if (v >= 1.5) return '😢';
    return '😞';
  }
}

class StreakCalendarWidget extends StatefulWidget {
  final Streaks streaks;
  final VoidCallback? onTap;

  const StreakCalendarWidget({super.key, required this.streaks, this.onTap});

  @override
  State<StreakCalendarWidget> createState() => _StreakCalendarWidgetState();
}

class _StreakCalendarWidgetState extends State<StreakCalendarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  late List<DateTime> _months;
  late PageController _pageController;
  late int _currentPageIndex;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, .6, curve: Curves.easeOut),
    );
    _slideAnim = Tween<double>(
      begin: 24,
      end: 0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _initMonthsAndPages();
    _ctrl.forward();
  }

  void _initMonthsAndPages() {
    final today = DateTime.now();
    DateTime? signupDate;
    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      signupDate = profileProvider.currentProfile?.createdAt;
    } catch (_) {}

    if (signupDate == null) {
      try {
        final authUser = Supabase.instance.client.auth.currentUser;
        if (authUser != null && authUser.createdAt != null) {
          signupDate = DateTime.tryParse(authUser.createdAt!);
        }
      } catch (_) {}
    }

    signupDate ??= today;
    if (signupDate.isAfter(today)) {
      signupDate = today;
    }

    // Set the backward limit strictly to the user's signup/join month,
    // and the forward limit to exactly 1 year (12 months) in the future.
    final startMonth = DateTime(signupDate.year, signupDate.month, 1);
    final endMonth = DateTime(today.year, today.month + 12, 1);

    _months = [];
    var temp = startMonth;
    while (!temp.isAfter(endMonth)) {
      _months.add(temp);
      temp = DateTime(temp.year, temp.month + 1, 1);
    }

    if (_months.isEmpty) {
      _months.add(endMonth);
    }

    _currentPageIndex = _months.indexWhere((m) => m.year == today.year && m.month == today.month);
    if (_currentPageIndex == -1) {
      _currentPageIndex = _months.length - 1;
    }

    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  void didUpdateWidget(covariant StreakCalendarWidget old) {
    super.didUpdateWidget(old);
    if (old.streaks.history.calendar30Days.length != widget.streaks.history.calendar30Days.length) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isActive(DateTime d) =>
      widget.streaks.history.calendar30Days[_dateKey(d)] == true;

  int _intensity(DateTime d) {
    final streak = widget.streaks.currentDays;
    final daysAgo = DateTime.now().difference(d).inDays;
    if (!_isActive(d)) return 0;
    if (daysAgo == 0) return 4;
    if (streak >= 7 && daysAgo < 7) return 4;
    if (streak >= 3 && daysAgo < 14) return 3;
    return 2;
  }

  int _daysInMonth(int year, int month) {
    if (month == 2) {
      final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeap ? 29 : 28;
    }
    const days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month];
  }

  List<DateTime> _generateMonthDays(int year, int month) {
    final totalDays = _daysInMonth(year, month);
    return List.generate(totalDays, (index) => DateTime(year, month, index + 1));
  }

  static const _monthNames = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  String _monthLabel(DateTime d) => '${_monthNames[d.month]} ${d.year}';

  Gradient? _cellGradient(bool active, int intensity, bool isDark, Color primary) {
    if (!active) return null;
    switch (intensity) {
      case 1:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [primary.withOpacity(0.25), primary.withOpacity(0.45)]
              : [primary.withOpacity(0.15), primary.withOpacity(0.32)],
        );
      case 2:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF59E0B),
            Color(0xFFFBBF24),
          ],
        );
      case 3:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF97316),
            Color(0xFFEF4444),
          ],
        );
      case 4:
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEF4444),
            Color(0xFFFFB84D),
          ],
        );
    }
  }

  Color _cellSolidColor(bool active, int intensity, bool isDark, Color primary) {
    if (active) return Colors.transparent;
    return isDark ? const Color(0xFF1F1F30) : const Color(0xFFF3F4F6);
  }

  Map<String, dynamic> _calculateMonthlyStats(int year, int month) {
    final daysCount = _daysInMonth(year, month);
    int activeCount = 0;
    int maxConsecutive = 0;
    int currentConsecutive = 0;

    for (int day = 1; day <= daysCount; day++) {
      final date = DateTime(year, month, day);
      final active = _isActive(date);

      if (active) {
        activeCount++;
        currentConsecutive++;
        if (currentConsecutive > maxConsecutive) {
          maxConsecutive = currentConsecutive;
        }
      } else {
        currentConsecutive = 0;
      }
    }

    final activityRate = daysCount > 0 ? (activeCount / daysCount) * 100 : 0.0;

    String grade;
    Color gradeColor;
    if (activityRate >= 90) {
      grade = 'A+';
      gradeColor = const Color(0xFF10B981);
    } else if (activityRate >= 75) {
      grade = 'A';
      gradeColor = const Color(0xFF34D399);
    } else if (activityRate >= 60) {
      grade = 'B+';
      gradeColor = const Color(0xFF3B82F6);
    } else if (activityRate >= 45) {
      grade = 'B';
      gradeColor = const Color(0xFFFFB84D);
    } else if (activityRate >= 30) {
      grade = 'C';
      gradeColor = const Color(0xFFF97316);
    } else if (activityRate > 0) {
      grade = 'D';
      gradeColor = const Color(0xFFEF4444);
    } else {
      grade = 'F';
      gradeColor = Colors.grey;
    }

    return {
      'activeDays': activeCount,
      'activityRate': activityRate,
      'maxConsecutive': maxConsecutive,
      'grade': grade,
      'gradeColor': gradeColor,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = widget.streaks;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _fadeAnim.value,
        child: Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: widget.onTap != null
                  ? Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onTap,
                        child: Column(
                          children: [
                            _buildHeader(isDark, s),
                            if (s.isAtRisk) _buildRiskBanner(isDark),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildMonthPageView(isDark),
                            ),
                            _buildLegend(isDark),
                            _buildMonthlyStatsPanel(isDark),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        _buildHeader(isDark, s),
                        if (s.isAtRisk) _buildRiskBanner(isDark),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildMonthPageView(isDark),
                        ),
                        _buildLegend(isDark),
                        _buildMonthlyStatsPanel(isDark),
                        const SizedBox(height: 16),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Streaks s) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Streak Calendar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Keep your momentum going',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              if (s.isActive)
                const TaskMetricIndicator(
                  type: TaskMetricType.liveSnapshot,
                  value: true,
                  size: 24,
                  showLabel: true,
                  customLabel: 'ACTIVE',
                  customColor: Color(0xFF10B981),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                _buildStatPill(
                  emoji: s.streakEmoji,
                  label: 'Current',
                  value: '${s.currentDays} days',
                  color: theme.colorScheme.primary,
                  isDark: isDark,
                  highlight: true,
                ),
                _buildDivider(isDark),
                _buildStatPill(
                  emoji: '🏆',
                  label: 'Longest',
                  value: '${s.longestDays} days',
                  color: const Color(0xFFFBBF24),
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildStatPill(
                  emoji: '🎯',
                  label: 'Next Goal',
                  value: s.nextMilestone.target > 0
                      ? '${s.nextMilestone.target} d'
                      : '—',
                  color: theme.colorScheme.secondary,
                  isDark: isDark,
                  progress: s.nextMilestone.target > 0
                      ? s.nextMilestone.progressPercent / 100
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required String emoji,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    bool highlight = false,
    double? progress,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: highlight
                  ? color
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            CustomProgressIndicator(
              progress: progress.clamp(0.0, 1.0),
              progressBarName: '',
              baseHeight: 4,
              maxHeightIncrease: 0,
              backgroundColor: isDark
                  ? Colors.white12
                  : Colors.black.withValues(alpha: 0.08),
              progressColor: color,
              gradientColors: [color, color.withValues(alpha: 0.6)],
              borderRadius: 2,
              progressLabelDisplay: ProgressLabelDisplay.none,
              animated: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
    );
  }

  Widget _buildRiskBanner(bool isDark) {
    const crimsonRed = Color(0xFFEF4444);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: crimsonRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: crimsonRed.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: crimsonRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.streaks.risk.hoursUntilBreak != null
                  ? 'Streak at risk! ${widget.streaks.risk.hoursUntilBreak}h left — do it today!'
                  : 'Your streak is at risk today!',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: crimsonRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthPageView(bool isDark) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _buildNavHeader(isDark),
        const SizedBox(height: 12),
        _buildDayHeader(isDark),
        const SizedBox(height: 8),
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _months.length,
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() {
                _currentPageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final monthDate = _months[index];
              final days = _generateMonthDays(monthDate.year, monthDate.month);
              final startPad = (days.first.weekday - 1) % 7;
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.15)).clamp(0.0, 1.0);
                  }
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.95 + (0.05 * value),
                      child: child,
                    ),
                  );
                },
                child: _buildGrid(days, startPad, isDark),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNavHeader(bool isDark) {
    final theme = Theme.of(context);
    final currentMonthDate = _months[_currentPageIndex];
    final monthLabelStr = _monthLabel(currentMonthDate).toUpperCase();

    final canPrev = _currentPageIndex > 0;
    final canNext = _currentPageIndex < _months.length - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: canPrev ? () {
            _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          } : null,
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: canPrev
                ? theme.colorScheme.primary
                : (isDark ? Colors.white24 : Colors.black26),
          ),
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(8),
            minimumSize: const Size(36, 36),
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.03),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              monthLabelStr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            _buildPageDots(),
          ],
        ),
        IconButton(
          onPressed: canNext ? () {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          } : null,
          icon: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: canNext
                ? theme.colorScheme.primary
                : (isDark ? Colors.white24 : Colors.black26),
          ),
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(8),
            minimumSize: const Size(36, 36),
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.03),
          ),
        ),
      ],
    );
  }

  Widget _buildPageDots() {
    if (_months.length <= 1) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final count = _months.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == _currentPageIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 14 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withOpacity(0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildDayHeader(bool isDark) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: labels
          .map(
            (l) => SizedBox(
              width: 38,
              child: Center(
                child: Text(
                  l,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildGrid(List<DateTime> days, int startPad, bool isDark) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final totalCells = startPad + days.length;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayIndex = cellIndex - startPad;

              if (dayIndex < 0 || dayIndex >= days.length) {
                return SizedBox(
                  width: 38,
                  child: Container(
                    height: 38,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.025)
                            : Colors.black.withValues(alpha: 0.02),
                        width: 1,
                      ),
                    ),
                  ),
                );
              }

              final d = days[dayIndex];
              final isToday =
                  d.year == today.year &&
                  d.month == today.month &&
                  d.day == today.day;
              final active = _isActive(d);
              final intensity = _intensity(d);
              final grad = _cellGradient(active, intensity, isDark, theme.colorScheme.primary);
              final solid = _cellSolidColor(active, intensity, isDark, theme.colorScheme.primary);

              return SizedBox(
                width: 38,
                child: GestureDetector(
                  onTap: widget.onTap == null
                      ? () {
                          HapticFeedback.selectionClick();
                          _showDayTooltip(d, active);
                        }
                      : null,
                  child: Container(
                    height: 38,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: grad == null ? solid : null,
                      gradient: grad,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(
                              color: theme.colorScheme.secondary,
                              width: 2.0,
                            )
                          : Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 0.8,
                            ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: (intensity >= 3
                                    ? const Color(0xFFEF4444)
                                    : theme.colorScheme.primary).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: active && intensity == 4
                        ? const Center(
                            child: Text('🔥', style: TextStyle(fontSize: 10)),
                          )
                        : (isToday
                            ? Center(
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  void _showDayTooltip(DateTime d, bool active) {
    ErrorHandler.showInfoSnackbar(
      active
          ? '✅ ${d.day}/${d.month} — Active!'
          : '💤 ${d.day}/${d.month} — Resting',
      title: 'Activity',
    );
  }

  Widget _buildLegend(bool isDark) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Less',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(width: 8),
          _buildLegendBox(
            color: isDark ? const Color(0xFF1F1F30) : const Color(0xFFF3F4F6),
          ),
          _buildLegendBox(
            gradient: LinearGradient(
              colors: isDark
                  ? [theme.colorScheme.primary.withOpacity(0.25), theme.colorScheme.primary.withOpacity(0.45)]
                  : [theme.colorScheme.primary.withOpacity(0.15), theme.colorScheme.primary.withOpacity(0.32)],
            ),
          ),
          _buildLegendBox(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFF59E0B),
                Color(0xFFFBBF24),
              ],
            ),
          ),
          _buildLegendBox(
            gradient: const LinearGradient(
              colors: [Color(0xFFF97316), Color(0xFFEF4444)],
            ),
          ),
          _buildLegendBox(
            gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFFFB84D)],
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 6)),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'More',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBox({Color? color, Gradient? gradient, Widget? child}) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(3),
      ),
      child: child,
    );
  }

  Widget _buildMonthlyStatsPanel(bool isDark) {
    final theme = Theme.of(context);
    final currentMonthDate = _months[_currentPageIndex];
    final stats = _calculateMonthlyStats(currentMonthDate.year, currentMonthDate.month);

    final activeDays = stats['activeDays'] as int;
    final activityRate = stats['activityRate'] as double;
    final maxConsecutive = stats['maxConsecutive'] as int;
    final grade = stats['grade'] as String;
    final gradeColor = stats['gradeColor'] as Color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.02)
            : Colors.black.withOpacity(0.015),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📈', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Text(
                'MONTHLY PERFORMANCE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniStatBox(
                label: 'Active Days',
                value: '$activeDays',
                subtext: 'days logged',
                color: theme.colorScheme.primary,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildMiniStatBox(
                label: 'Activity Rate',
                value: '${activityRate.toStringAsFixed(0)}%',
                subtext: 'of month',
                color: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildMiniStatBox(
                label: 'Max Run',
                value: '$maxConsecutive d',
                subtext: 'consecutive',
                color: const Color(0xFFEF4444),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildMiniStatBox(
                label: 'Consistency',
                value: grade,
                subtext: 'grade index',
                color: gradeColor,
                isDark: isDark,
                isGrade: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatBox({
    required String label,
    required String value,
    required String subtext,
    required Color color,
    required bool isDark,
    bool isGrade = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: isGrade ? 14 : 13,
                fontWeight: FontWeight.w900,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtext,
              style: TextStyle(
                fontSize: 7,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class MoodTrendChart extends StatefulWidget {
  final Mood mood;
  final VoidCallback? onTap;
  final int maxPoints;
  final bool showBackground;
  final bool showShadow;
  final bool showFrequency;

  const MoodTrendChart({
    super.key,
    required this.mood,
    this.maxPoints = 14,
    this.showBackground = true,
    this.showShadow = true,
    this.showFrequency = true,
    this.onTap,
  });

  @override
  State<MoodTrendChart> createState() => _MoodTrendChartState();
}

class _MoodTrendChartState extends State<MoodTrendChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<MoodDataPoint> get _points {
    final all = widget.mood.moodHistory;
    if (all.isEmpty) return [];
    final sorted = [...all]..sort((a, b) => a.date.compareTo(b.date));
    return sorted.length > widget.maxPoints
        ? sorted.sublist(sorted.length - widget.maxPoints)
        : sorted;
  }

  static const List<double> _yLabels = [1, 3, 5, 7, 9];
  static const List<String> _yEmojis = ['😞', '😔', '😐', '😊', '🤩'];
  static String _shortDate(DateTime d) => '${d.day}/${d.month}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pts = _points;
    final m = widget.mood;

    final content = Column(
      children: [
        _buildHeader(isDark, m),
        if (pts.isEmpty)
          _buildEmpty(isDark)
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
            child: SizedBox(
              height: 180,
              child: AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => LineChart(
                  _buildChartData(pts, isDark),
                  duration: Duration.zero,
                ),
              ),
            ),
          ),
          _buildDateLabels(pts, isDark),
          const SizedBox(height: 12),
          if (widget.showFrequency && m.moodFrequency.isNotEmpty)
            _buildFrequencyRow(isDark, m),
          const SizedBox(height: 12),
        ],
      ],
    );

    return Container(
      margin: widget.showBackground
          ? null
          : const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        children: [
          if (widget.showBackground)
            GradientCard(
              colors: [theme.colorScheme.surface, theme.colorScheme.surface],
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              showShadow: widget.showShadow,
              child: content,
            )
          else
            content,
          if (widget.onTap != null)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, Mood m) {
    final avg7 = m.averageMoodLast7Days;
    final avg30 = m.averageMoodLast30Days;
    final trendUp = m.trend.toLowerCase() == 'improving';
    final trendDown = m.trend.toLowerCase() == 'declining';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _Pal.moodColor(avg7),
                  _Pal.moodColor(avg7).withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.mood_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mood Trends',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _Pal.moodColor(avg7),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      trendUp
                          ? Icons.trending_up_rounded
                          : trendDown
                          ? Icons.trending_down_rounded
                          : Icons.trending_flat_rounded,
                      size: 12,
                      color: trendUp
                          ? const Color(0xFF10B981)
                          : trendDown
                          ? const Color(0xFFEF4444)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      m.trend.isEmpty ? 'stable' : m.trend,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: trendUp
                            ? const Color(0xFF10B981)
                            : trendDown
                            ? const Color(0xFFEF4444)
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _avgChip('7d', avg7, isDark),
              const SizedBox(height: 4),
              _avgChip('30d', avg30, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avgChip(String label, double avg, bool isDark) {
    final c = _Pal.moodColor(avg);
    final emoji = _Pal.moodEmoji(avg);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            '$label ${avg.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(List<MoodDataPoint> pts, bool isDark) {
    final spots = pts.asMap().entries.map((e) {
      final y = e.value.value * _anim.value;
      return FlSpot(e.key.toDouble(), y.clamp(0, 10));
    }).toList();
    final avgColor = _Pal.moodColor(widget.mood.averageMoodLast7Days);

    return LineChartData(
      minY: 0,
      maxY: 10,
      clipData: const FlClipData.none(),
      minX: -0.2,
      maxX: (pts.length - 1).toDouble() + 0.2,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 2,
        getDrawingHorizontalLine: (v) => FlLine(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 2,
            getTitlesWidget: (value, meta) {
              final idx = _yLabels.indexOf(value);
              if (idx == -1) return const SizedBox.shrink();
              return Text(
                _yEmojis[idx],
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              );
            },
          ),
        ),
        bottomTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: widget.onTap == null,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) =>
              isDark ? const Color(0xFF2A2A3A) : Colors.white,
          getTooltipItems: (spots) => spots.map((s) {
            final pt = pts[s.spotIndex];
            final emoji = _Pal.moodEmoji(pt.value);
            final c = _Pal.moodColor(pt.value);
            return LineTooltipItem(
              '$emoji ${pt.value.toStringAsFixed(1)}\n',
              TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 12),
              children: [
                TextSpan(
                  text: _shortDate(pt.date),
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: avgColor,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, idx) {
              final isTouched = _touchedIndex == idx;
              return FlDotCirclePainter(
                radius: isTouched ? 6 : 3,
                color: _Pal.moodColor(pts[idx].value),
                strokeWidth: isTouched ? 2 : 1,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                avgColor.withValues(alpha: 0.2),
                avgColor.withValues(alpha: 0.05),
                Colors.transparent,
              ],
              stops: const [0, 0.6, 1],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateLabels(List<MoodDataPoint> pts, bool isDark) {
    if (pts.length < 2) return const SizedBox.shrink();
    final indices = {0, pts.length ~/ 2, pts.length - 1};
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 4, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(pts.length, (i) {
          if (!indices.contains(i)) return const Expanded(child: SizedBox());
          return Expanded(
            child: Text(
              _shortDate(pts[i].date),
              textAlign: i == 0
                  ? TextAlign.left
                  : i == pts.length - 1
                  ? TextAlign.right
                  : TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFrequencyRow(bool isDark, Mood m) {
    final sorted = m.moodFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final total = top.fold<int>(0, (s, e) => s + e.value);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MOOD FREQUENCY',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 8),
          ...top.map((entry) {
            final ratio = total > 0 ? entry.value / total : 0.0;
            final numVal = _labelToNum(entry.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      '${_Pal.moodEmoji(numVal)} ${entry.key}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomProgressIndicator(
                      progress: ratio,
                      progressBarName: '',
                      baseHeight: 8,
                      maxHeightIncrease: 0,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.05),
                      progressColor: _Pal.moodColor(numVal),
                      borderRadius: 3,
                      animateProgressLabel: false,
                      progressLabelDisplay: ProgressLabelDisplay.none,
                      animated: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _Pal.moodColor(numVal),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            '😐',
            style: TextStyle(
              fontSize: 40,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No mood data yet',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Write diary entries to see your mood trend',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
        ],
      ),
    );
  }

  double _labelToNum(String label) {
    final l = label.toLowerCase();
    if (l.contains('great') || l.contains('amazing')) return 9;
    if (l.contains('good') || l.contains('happy')) return 7.5;
    if (l.contains('okay') || l.contains('fine')) return 5.5;
    if (l.contains('bad') || l.contains('sad')) return 3;
    if (l.contains('terrible')) return 1.5;
    return 5;
  }
}
