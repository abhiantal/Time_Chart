// =========================================================================
// WEEK TASK CALENDAR WIDGET — Premium UI with DailyFeedbackSummaryDialog
//
// -------------------------------------------------------------------------
//   Uses DailyFeedbackSummaryDialog (same as UnifiedCalendarWidget)
//   Builds DailyFeedbackSummaryData from WeekTaskModel.DailyProgress
//
//   Date Range Fix:
//   • startDate = min(createdAt, earliest feedback)
//   • endDate   = max(today/updatedAt, latest feedback)
//   • timeline.starting_time/ending_time are DAILY hours, NOT dates
// =========================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_time_chart/helpers/card_color_helper.dart';
import 'package:the_time_chart/widgets/daily_feedback_summary_viewer.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:the_time_chart/features/personal/task_model/week_task/models/week_task_model.dart';
import '../../../../../media_utility/media_asset_model.dart';

// =========================================================================
// ENUMS
// =========================================================================

enum WeekDayStatus {
  scheduled,   // Future scheduled day (Orange/Amber)
  completed,   // Done with feedback (Green)
  missed,      // Past scheduled, no feedback (Red)
  inProgress,  // Today (Blue pulse)
  partial,     // Some progress, not complete (Yellow)
  restDay,     // Non-working day within timeline (Grey)
  outOfRange,  // Outside task timeline (Transparent)
}

// =========================================================================
// DESIGN TOKENS
// =========================================================================

class _Tok {
  const _Tok._();

  static const double br = 24.0;
  static const double cr = 14.0;
  static const double calH = 380.0;
  static const double gap = 5.0;

  static const days = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday',
  ];
  static const dayShort = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  static const Map<WeekDayStatus, List<Color>> sg = {
    WeekDayStatus.scheduled: [
      Color(0xFFFF9500), Color(0xFFFFAB40), Color(0xFFFFCC02),
    ],
    WeekDayStatus.completed: [
      Color(0xFF00E676), Color(0xFF00C853), Color(0xFF69F0AE),
    ],
    WeekDayStatus.missed: [
      Color(0xFFFF5252), Color(0xFFE53935), Color(0xFFFF8A80),
    ],
    WeekDayStatus.inProgress: [
      Color(0xFF2979FF), Color(0xFF448AFF), Color(0xFF82B1FF),
    ],
    WeekDayStatus.partial: [
      Color(0xFFFFD600), Color(0xFFFFEA00), Color(0xFFFFF59D),
    ],
    WeekDayStatus.restDay: [
      Color(0xFF546E7A), Color(0xFF78909C), Color(0xFF90A4AE),
    ],
    WeekDayStatus.outOfRange: [
      Colors.transparent, Colors.transparent, Colors.transparent,
    ],
  };
}

extension _SC on WeekDayStatus {
  List<Color> get g =>
      _Tok.sg[this] ?? [Colors.grey, Colors.grey, Colors.grey];
  Color get primary => g.first;
}

// =========================================================================
// CELL DATA
// =========================================================================

class _Cell {
  final DateTime date;
  final WeekDayStatus status;
  final DailyProgress? progress;
  final bool isCurMonth, isToday, isScheduled, inTimeline;

  const _Cell({
    required this.date,
    required this.status,
    this.progress,
    required this.isCurMonth,
    required this.isToday,
    required this.isScheduled,
    required this.inTimeline,
  });

  bool get hasFeedback =>
      progress != null && progress!.feedbacks.isNotEmpty;
  int get feedbackCount => progress?.feedbacks.length ?? 0;
  bool get isComplete =>
      (progress?.isComplete ?? false) || (progress?.feedbacks.isNotEmpty ?? false);
  int get dayProgress => progress?.dailyMetrics.progress ?? 0;
  bool get canTap => isCurMonth && inTimeline;
}

// =========================================================================
// MAIN WIDGET
// =========================================================================

class WeekTaskCalendarWidget extends StatefulWidget {
  final WeekTaskModel task;
  final bool showAsDialog;
  final VoidCallback? onClose;
  final void Function(DateTime date, DailyProgress? progress)? onDayTap;
  final void Function(DateTime date)? onAddFeedback;

  const WeekTaskCalendarWidget({
    super.key,
    required this.task,
    this.showAsDialog = true,
    this.onClose,
    this.onDayTap,
    this.onAddFeedback,
  });

  static Future<void> show(
      BuildContext context, {
        required WeekTaskModel task,
        void Function(DateTime date, DailyProgress? progress)? onDayTap,
        void Function(DateTime date)? onAddFeedback,
      }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'WeekTaskCalendar',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, _, __) => WeekTaskCalendarWidget(
        task: task,
        showAsDialog: true,
        onClose: () => Navigator.of(ctx).pop(),
        onDayTap: onDayTap,
        onAddFeedback: onAddFeedback,
      ),
      transitionBuilder: (_, anim, __, child) {
        final c = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return Transform.scale(
          scale: 0.82 + (0.18 * c.value),
          child: Opacity(
            opacity: anim.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<WeekTaskCalendarWidget> createState() => _WTCalState();
}

class _WTCalState extends State<WeekTaskCalendarWidget>
    with TickerProviderStateMixin {
  late PageController _pc;
  late List<DateTime> _months;
  int _pg = 0;

  late AnimationController _shimC, _pulC, _floC, _glC;
  late Animation<double> _shimA, _pulA, _floA, _glA;

  late DateTime _startDate;
  late DateTime _endDate;
  late List<String> _scheduledDays;

  @override
  void initState() {
    super.initState();
    _computeDateRange();
    _buildScheduledDays();
    _months = _buildMonths();
    _pg = _todayPage();
    _pc = PageController(initialPage: _pg);
    _initAnims();
  }

  @override
  void didUpdateWidget(covariant WeekTaskCalendarWidget old) {
    super.didUpdateWidget(old);
    if (old.task.id != widget.task.id ||
        old.task.updatedAt != widget.task.updatedAt) {
      _computeDateRange();
      _buildScheduledDays();
      _months = _buildMonths();
      final p = _todayPage();
      if (p != _pg) {
        setState(() => _pg = p);
        _pc.jumpToPage(p);
      }
    }
  }

  @override
  void dispose() {
    _shimC.dispose();
    _pulC.dispose();
    _floC.dispose();
    _glC.dispose();
    _pc.dispose();
    super.dispose();
  }

  void _initAnims() {
    _shimC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _shimA = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimC, curve: Curves.easeInOut),
    );

    _pulC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulA = Tween<double>(begin: 0.94, end: 1.08).animate(
      CurvedAnimation(parent: _pulC, curve: Curves.easeInOut),
    );

    _floC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _floA = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _floC, curve: Curves.easeInOut),
    );

    _glC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glA = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glC, curve: Curves.easeInOut),
    );
  }

  // =========================================================================
  // DATE / SCHEDULE UTILITIES
  // =========================================================================

  static DateTime _d(DateTime d) {
    if (d.year < 1900) return DateTime.now();
    return DateTime(d.year, d.month, d.day);
  }

  static DateTime? _parseDate(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final t = s.trim();
    try {
      return DateFormat('dd-MM-yyyy').parse(t);
    } catch (_) {}
    try {
      return DateTime.parse(t);
    } catch (_) {}
    return null;
  }

  static String _normDay(String raw) {
    final l = raw.toLowerCase().trim();
    const m = {
      'mon': 'Monday',    'monday': 'Monday',
      'tue': 'Tuesday',   'tuesday': 'Tuesday',
      'wed': 'Wednesday', 'wednesday': 'Wednesday',
      'thu': 'Thursday',  'thursday': 'Thursday',
      'fri': 'Friday',    'friday': 'Friday',
      'sat': 'Saturday',  'saturday': 'Saturday',
      'sun': 'Sunday',    'sunday': 'Sunday',
    };
    return m[l] ?? raw;
  }

  void _buildScheduledDays() {
    _scheduledDays = widget.task.timeline.taskDays
        .split(',')
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty)
        .map(_normDay)
        .toSet()
        .toList();
  }

  bool _isScheduledDate(DateTime date) {
    final dayName = DateFormat('EEEE').format(date);
    return _scheduledDays.any(
          (d) => d.toLowerCase() == dayName.toLowerCase(),
    );
  }

  void _computeDateRange() {
    final now = DateTime.now();
    final today = _d(now);

    var start = _d(widget.task.timeline.startingDate);
    var end = _d(widget.task.timeline.expectedEndingDate);

    if (end.isAtSameMomentAs(start)) {
      end = start.add(const Duration(days: 6));
    }

    final created = _d(widget.task.createdAt);
    if (created.isBefore(start)) start = created;

    for (final dp in widget.task.dailyProgress) {
      final fd = _parseDate(dp.taskDate);
      if (fd == null) continue;
      final d = _d(fd);
      if (d.isBefore(start)) start = d;
      if (d.isAfter(end)) end = d;
    }

    final isActive = widget.task.indicators.status == 'inProgress' ||
        widget.task.indicators.status == 'pending';
    if (isActive) {
      final upcomingWindow = today.add(const Duration(days: 7));
      if (upcomingWindow.isAfter(end)) {
        end = upcomingWindow;
      }
    }

    if (end.difference(start).inDays < 6) {
      end = start.add(const Duration(days: 6));
    }

    _startDate = start;
    _endDate = end;
  }

  List<DateTime> _buildMonths() {
    final list = <DateTime>[];
    final now = DateTime.now();

    DateTime minMonth;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final signup = DateTime.tryParse(user.createdAt);
        if (signup != null) {
          minMonth = DateTime(signup.year, signup.month);
        } else {
          minMonth = DateTime(now.year, now.month);
        }
      } else {
        minMonth = DateTime(now.year, now.month);
      }
    } catch (_) {
      minMonth = DateTime(now.year, now.month);
    }

    final maxMonth = DateTime(now.year, now.month + 12);
    var current = minMonth;
    while (!current.isAfter(maxMonth)) {
      list.add(current);
      current = DateTime(current.year, current.month + 1);
    }

    return list;
  }

  int _todayPage() {
    final n = DateTime.now();
    for (int i = 0; i < _months.length; i++) {
      if (_months[i].year == n.year && _months[i].month == n.month) return i;
    }
    return _months.isEmpty ? 0 : _months.length - 1;
  }

  // =========================================================================
  // STATUS CALCULATION
  // =========================================================================

  WeekDayStatus _status(DateTime date) {
    final d = _d(date);
    final now = DateTime.now();
    final today = _d(now);

    if (d.isBefore(_startDate) || d.isAfter(_endDate)) {
      return WeekDayStatus.outOfRange;
    }

    final sched = _isScheduledDate(date);
    final progress = widget.task.getProgressForDate(date);

    if (d.isAtSameMomentAs(today)) {
      if (progress != null) {
        if (progress.isComplete || progress.dailyMetrics.progress >= 100) {
          return WeekDayStatus.completed;
        }
        if (progress.feedbacks.isNotEmpty ||
            progress.dailyMetrics.progress > 0) {
          return WeekDayStatus.inProgress;
        }
      }
      return sched ? WeekDayStatus.inProgress : WeekDayStatus.restDay;
    }

    if (d.isBefore(today)) {
      if (progress != null) {
        if (progress.dailyMetrics.isComplete || progress.dailyMetrics.progress >= 100) {
          return WeekDayStatus.completed;
        }
        if (progress.feedbacks.isNotEmpty) {
          return WeekDayStatus.completed;
        }
        if (progress.dailyMetrics.progress > 0) {
          return WeekDayStatus.partial;
        }
      }
      return sched ? WeekDayStatus.missed : WeekDayStatus.restDay;
    }

    return sched ? WeekDayStatus.scheduled : WeekDayStatus.restDay;
  }

  // =========================================================================
  // BUILD CELLS
  // =========================================================================

  List<_Cell> _cells(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);

    final dates = <DateTime>[];
    final lead = first.weekday % 7;
    for (int i = lead; i > 0; i--) {
      dates.add(first.subtract(Duration(days: i)));
    }
    for (int i = 0; i < last.day; i++) {
      dates.add(first.add(Duration(days: i)));
    }
    final trail = 42 - dates.length;
    for (int i = 1; i <= trail; i++) {
      dates.add(last.add(Duration(days: i)));
    }

    final now = DateTime.now();
    final today = _d(now);

    return dates.map((date) {
      final d = _d(date);
      final cur = date.month == month.month;

      if (!cur) {
        return _Cell(
          date: date,
          status: WeekDayStatus.outOfRange,
          isCurMonth: false,
          isToday: false,
          isScheduled: false,
          inTimeline: false,
        );
      }

      final inT = !d.isBefore(_startDate) && !d.isAfter(_endDate);

      return _Cell(
        date: date,
        status: _status(date),
        progress: widget.task.getProgressForDate(date),
        isCurMonth: true,
        isToday: d.isAtSameMomentAs(today),
        isScheduled: _isScheduledDate(date),
        inTimeline: inT,
      );
    }).toList();
  }

  // =========================================================================
  // STATISTICS
  // =========================================================================

  Map<String, int> _stats() {
    int comp = 0, active = 0, missed = 0, sched = 0;

    var cur = DateTime(_startDate.year, _startDate.month, _startDate.day);

    while (!cur.isAfter(_endDate)) {
      if (_isScheduledDate(cur)) {
        final s = _status(cur);
        switch (s) {
          case WeekDayStatus.completed:
            comp++;
            break;
          case WeekDayStatus.inProgress:
          case WeekDayStatus.partial:
            active++;
            break;
          case WeekDayStatus.missed:
            missed++;
            break;
          case WeekDayStatus.scheduled:
            sched++;
            break;
          default:
            break;
        }
      }
      cur = cur.add(const Duration(days: 1));
    }

    return {
      'completed': comp,
      'active': active,
      'missed': missed,
      'scheduled': sched,
    };
  }

  // =========================================================================
  // DAILY FEEDBACK SUMMARY DATA BUILDER
  // =========================================================================

  DailyFeedbackSummaryData _buildSummaryData({
    required DateTime date,
    required DailyProgress? progress,
    required WeekDayStatus status,
    required bool isToday,
  }) {
    final today = _d(DateTime.now());
    final key = _d(date);

    if (progress != null) {
      final feedbacks = progress.feedbacks;
      final metrics = progress.dailyMetrics;

      final mediaFiles = feedbacks
          .where((f) => f.mediaUrl != null && f.mediaUrl!.isNotEmpty)
          .map((f) => EnhancedMediaFile(
        id: 'wt_fb_${f.feedbackCount}_${progress.taskDate}',
        url: f.mediaUrl ?? '',
        type: EnhancedMediaFile.detectMediaType(f.mediaUrl ?? ''),
        thumbnailUrl: f.mediaUrl,
      ))
          .toList();

      final hourlyBreakdown = feedbacks.map((f) {
        return <String, dynamic>{
          'time': 'Feedback #${f.feedbackCount}',
          'points': 0,
          'hasMedia': f.hasMedia,
          'mediaUrl': f.mediaUrl,
          'timestamp': progress.taskDate,
        };
      }).toList();

      final isComplete = metrics.isComplete;
      final prog = metrics.progress;
      final hasFeedback = feedbacks.isNotEmpty;
      final isFuture = key.isAfter(today);
      final isMissed = !isComplete &&
          !isToday &&
          !isFuture &&
          !hasFeedback &&
          prog == 0;

      final dayName = progress.dayName.isNotEmpty
          ? progress.dayName
          : DateFormat('EEEE').format(key);

      final feedbackTexts = feedbacks
          .map((f) => f.finalText)
          .where((t) => t.isNotEmpty)
          .cast<String>()
          .toList();

      final statusLabel = isComplete
          ? 'Completed'
          : isToday
          ? (prog > 0 || hasFeedback
          ? 'In Progress ($prog%)'
          : 'In Progress')
          : isMissed
          ? 'Missed'
          : isFuture
          ? 'Scheduled'
          : prog > 0
          ? 'Partial ($prog%)'
          : hasFeedback
          ? 'Has Feedback'
          : 'No Feedback';

      return DailyFeedbackSummaryData(
        taskId: widget.task.id,
        taskType: 'Weekly Task',
        taskTitle: widget.task.aboutTask.taskName,
        date: key,
        progress: prog,
        pointsEarned: metrics.pointsEarned,
        rating: metrics.rating,
        isComplete: isComplete,
        isMissed: isMissed,
        isToday: isToday,
        statusLabel: statusLabel,
        statusData: {
          'status': widget.task.indicators.status,
          'priority': widget.task.indicators.priority,
        },
        feedbackTexts: feedbackTexts,
        mediaFiles: mediaFiles,
        feedbackCount: feedbacks.length,
        penaltyPoints: metrics.penalty?.penaltyPoints,
        penaltyReason: metrics.penalty?.reason,
        motivationalQuote: feedbackTexts.isNotEmpty ? feedbackTexts.last : null,
        rewardPackage: metrics.rewardPackage,
        onAddFeedback: widget.onAddFeedback != null
            ? () => widget.onAddFeedback!(key)
            : null,
        hourlyBreakdown: hourlyBreakdown,
        dayName: dayName,
      );
    }

    final isMissed = status == WeekDayStatus.missed;
    final dayName = DateFormat('EEEE').format(key);

    return DailyFeedbackSummaryData(
      taskId: widget.task.id,
      taskType: 'Weekly Task',
      taskTitle: widget.task.aboutTask.taskName,
      date: key,
      progress: 0,
      pointsEarned: 0,
      rating: 0,
      isComplete: false,
      isMissed: isMissed,
      isToday: isToday,
      statusLabel: _statusLabel(status),
      statusData: {
        'status': isMissed ? 'missed' : widget.task.indicators.status,
        'priority': widget.task.indicators.priority,
      },
      feedbackTexts: [],
      mediaFiles: [],
      feedbackCount: 0,
      penaltyPoints: null,
      penaltyReason: null,
      motivationalQuote: null,
      onAddFeedback: widget.onAddFeedback != null
          ? () => widget.onAddFeedback!(key)
          : null,
      hourlyBreakdown: null,
      dayName: dayName,
    );
  }

  String _statusLabel(WeekDayStatus s) {
    switch (s) {
      case WeekDayStatus.completed: return 'Completed';
      case WeekDayStatus.missed: return 'Missed';
      case WeekDayStatus.inProgress: return 'In Progress';
      case WeekDayStatus.partial: return 'Partial';
      case WeekDayStatus.scheduled: return 'Scheduled';
      case WeekDayStatus.restDay: return 'Rest Day';
      case WeekDayStatus.outOfRange: return 'Out of Range';
    }
  }

  // =========================================================================
  // INTERACTIONS
  // =========================================================================

  void _nav(int p) {
    if (p < 0 || p >= _months.length) return;
    HapticFeedback.selectionClick();
    _pc.animateToPage(
      p,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _tap(_Cell c) {
    if (!c.isCurMonth) return;
    HapticFeedback.mediumImpact();

    if (widget.onDayTap != null) {
      widget.onDayTap!(c.date, c.progress);
      return;
    }

    if (c.progress != null && c.progress!.feedbacks.isNotEmpty) {
      final summaryData = _buildSummaryData(
        date: c.date,
        progress: c.progress,
        status: c.status,
        isToday: c.isToday,
      );
      showDialog(
        context: context,
        builder: (_) => DailyFeedbackSummaryDialog(data: summaryData),
      );
      return;
    }

    if (c.inTimeline && widget.onAddFeedback != null) {
      final summaryData = _buildSummaryData(
        date: c.date,
        progress: c.progress,
        status: c.status,
        isToday: c.isToday,
      );
      showDialog(
        context: context,
        builder: (_) => DailyFeedbackSummaryDialog(data: summaryData),
      );
      return;
    }

    _showDayInfo(c);
  }

  void _showDayInfo(_Cell c) {
    final today = _d(DateTime.now());
    String msg;
    Color color;

    if (!c.inTimeline) {
      msg = 'Outside task timeline';
      color = Colors.grey;
    } else if (c.date.isAfter(today)) {
      msg = 'Scheduled for ${DateFormat('EEEE').format(c.date)} — Stay focused!';
      color = Colors.orange;
    } else if (c.isScheduled) {
      msg = 'No feedback recorded for this day';
      color = Colors.red;
    } else {
      msg = 'Rest day — No task scheduled';
      color = Colors.blueGrey;
    }

    if (!mounted) return;
    
    if (color == Colors.red) {
      AppSnackbar.error(msg);
    } else if (color == Colors.orange) {
      AppSnackbar.warning(msg);
    } else {
      AppSnackbar.info(title: msg);
    }
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final dk = th.brightness == Brightness.dark;
    final stats = _stats();

    final content = _buildContent(th, dk, stats);

    if (widget.showAsDialog) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_Tok.br),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: content,
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (widget.onClose != null) {
                  widget.onClose!();
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                margin: const EdgeInsets.all(16),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: dk
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: dk ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return content;
  }

  Widget _buildContent(ThemeData th, bool dk, Map<String, int> stats) {
    return AnimatedBuilder(
      animation: _glA,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dk
                ? [const Color(0xFF0F0F1E), const Color(0xFF1A1A2E)]
                : [const Color(0xFFF8F9FF), Colors.white],
          ),
          borderRadius: BorderRadius.circular(_Tok.br),
          border: Border.all(
            color: dk
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color:
              th.colorScheme.primary.withValues(alpha: _glA.value * 0.15),
              blurRadius: 30,
              spreadRadius: -5,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: dk ? 0.5 : 0.12),
              blurRadius: 40,
              offset: const Offset(0, 20),
              spreadRadius: -10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_Tok.br),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showAsDialog) _header(th, dk),
              _taskInfo(th, dk),
              _legend(th, dk),
              _monthNav(th, dk),
              const SizedBox(height: 8),
              SizedBox(
                height: _Tok.calH,
                child: PageView.builder(
                  controller: _pc,
                  onPageChanged: (p) {
                    setState(() => _pg = p);
                    HapticFeedback.selectionClick();
                  },
                  itemCount: _months.length,
                  itemBuilder: (_, i) =>
                      _grid(_cells(_months[i]), th, dk),
                ),
              ),
              if (_months.length > 1) ...[
                const SizedBox(height: 10),
                _dots(th),
              ],
              const SizedBox(height: 12),
              _statsRow(th, dk, stats),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // Header
  // =========================================================================

  Widget _header(ThemeData th, bool dk) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _floA,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _floA.value),
              child: child,
            ),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    th.colorScheme.primary,
                    th.colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: th.colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WEEKLY PROGRESS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: th.colorScheme.primary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Task Calendar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: dk ? Colors.white : Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Task Info Banner
  // =========================================================================

  Widget _taskInfo(ThemeData th, bool dk) {
    final t = widget.task;
    final range =
        '${DateFormat('MMM d').format(_startDate)} — '
        '${DateFormat('MMM d, yyyy').format(_endDate)}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: t.getCardGradient(isDarkMode: dk).take(2).toList(),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
            t.getCardGradient(isDarkMode: dk).first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.aboutTask.taskName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${_scheduledDays.length} days/wk · $range',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _miniProgress(t.summary.progress),
        ],
      ),
    );
  }

  Widget _miniProgress(int progress) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              value: progress / 100,
              strokeWidth: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '$progress%',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Legend
  // =========================================================================

  Widget _legend(ThemeData th, bool dk) {
    const items = [
      (WeekDayStatus.completed,  'Done',     Icons.check_circle_rounded),
      (WeekDayStatus.inProgress, 'Today',    Icons.play_circle_rounded),
      (WeekDayStatus.scheduled,  'Upcoming', Icons.schedule_rounded),
      (WeekDayStatus.missed,     'Missed',   Icons.cancel_rounded),
      (WeekDayStatus.restDay,    'Rest',     Icons.bedtime_rounded),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: dk
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dk
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((it) {
          final isT = it.$1 == WeekDayStatus.inProgress;
          return AnimatedBuilder(
            animation: _pulA,
            builder: (_, __) => Transform.scale(
              scale: isT ? _pulA.value : 1.0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: it.$1.g.take(2).toList(),
                      ),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: isT
                          ? [
                        BoxShadow(
                          color: it.$1.primary.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ]
                          : null,
                    ),
                    child: Icon(it.$3, size: 10, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    it.$2,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: dk ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // =========================================================================
  // Month Navigation
  // =========================================================================

  Widget _monthNav(ThemeData th, bool dk) {
    return AnimatedBuilder(
      animation: _floA,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _floA.value * 0.3),
        child: child,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            th.colorScheme.primary.withValues(alpha: 0.1),
            th.colorScheme.secondary.withValues(alpha: 0.05),
          ]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: th.colorScheme.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            _navBtn(
              Icons.chevron_left_rounded,
              _pg > 0,
                  () => _nav(_pg - 1),
              th,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: a, curve: Curves.easeOut),
                    ),
                    child: c,
                  ),
                ),
                child: Text(
                  DateFormat('MMMM yyyy').format(_months[_pg]),
                  key: ValueKey(_months[_pg]),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    foreground: Paint()
                      ..shader = LinearGradient(colors: [
                        th.colorScheme.primary,
                        th.colorScheme.secondary,
                      ]).createShader(
                        const Rect.fromLTWH(0, 0, 200, 30),
                      ),
                  ),
                ),
              ),
            ),
            _navBtn(
              Icons.chevron_right_rounded,
              _pg < _months.length - 1,
                  () => _nav(_pg + 1),
              th,
            ),
          ],
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon, bool en, VoidCallback cb, ThemeData th) {
    return GestureDetector(
      onTap: en
          ? () {
        HapticFeedback.lightImpact();
        cb();
      }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: en
              ? th.colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 24,
          color: en
              ? th.colorScheme.primary
              : th.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  // =========================================================================
  // Calendar Grid
  // =========================================================================

  Widget _grid(List<_Cell> cells, ThemeData th, bool dk) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _wdHdr(th, dk),
          const SizedBox(height: 6),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                crossAxisSpacing: _Tok.gap,
                mainAxisSpacing: _Tok.gap,
              ),
              itemCount: cells.length,
              itemBuilder: (_, i) => _cell(cells[i], i, th, dk),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wdHdr(ThemeData th, bool dk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: dk
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(7, (i) {
          final dayName = _Tok.days[i];
          final isSched = _scheduledDays.any(
                (d) => d.toLowerCase() == dayName.toLowerCase(),
          );
          final isWe = i == 0 || i == 6;

          return Expanded(
            child: Center(
              child: Text(
                _Tok.dayShort[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSched
                      ? th.colorScheme.primary
                      : isWe
                      ? (dk
                      ? Colors.red.shade300.withValues(alpha: 0.6)
                      : Colors.red.shade400.withValues(alpha: 0.7))
                      : (dk ? Colors.white38 : Colors.black38),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // =========================================================================
  // Cell
  // =========================================================================

  Widget _cell(_Cell c, int idx, ThemeData th, bool dk) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + (idx % 14) * 15),
      curve: Curves.easeOutBack,
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: GestureDetector(
        onTap: () => _tap(c),
        child: c.isToday
            ? AnimatedBuilder(
          animation: _pulA,
          builder: (_, child) =>
              Transform.scale(scale: _pulA.value, child: child),
          child: _cc(c, dk),
        )
            : _cc(c, dk),
      ),
    );
  }

  Widget _cc(_Cell c, bool dk) {
    if (!c.isCurMonth) {
      return Center(
        child: Text(
          '${c.date.day}',
          style: TextStyle(
            fontSize: 10,
            color: dk
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      );
    }

    final st = c.status;
    if (st == WeekDayStatus.outOfRange) {
      return Container(
        decoration: BoxDecoration(
          color: dk
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(_Tok.cr),
        ),
        child: Center(
          child: Text(
            '${c.date.day}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: dk
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.12),
            ),
          ),
        ),
      );
    }

    final isRest = st == WeekDayStatus.restDay;
    final colors = st.g;
    final op = isRest ? 0.15 : (c.isToday ? 1.0 : 0.85);
    final glow = c.isToday ? 0.6 : (isRest ? 0.0 : 0.18);

    return RepaintBoundary(
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            decoration: BoxDecoration(
              gradient: isRest
                  ? null
                  : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors[0].withValues(alpha: op),
                  colors[1].withValues(alpha: (op - 0.12).clamp(0, 1)),
                  colors[2].withValues(alpha: (op - 0.2).clamp(0, 1)),
                ],
              ),
              color: isRest
                  ? (dk
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04))
                  : null,
              borderRadius: BorderRadius.circular(_Tok.cr),
              border: Border.all(
                color: c.isToday
                    ? colors[0].withValues(alpha: 0.9)
                    : (c.hasFeedback && !isRest)
                    ? colors[0].withValues(alpha: 0.3)
                    : Colors.transparent,
                width: c.isToday ? 2.5 : 1.0,
              ),
              boxShadow: glow > 0
                  ? [
                BoxShadow(
                  color: colors[0].withValues(alpha: glow),
                  blurRadius: c.isToday ? 14 : 5,
                  spreadRadius: c.isToday ? 1 : -2,
                  offset: const Offset(0, 3),
                ),
              ]
                  : null,
            ),
            child: Center(child: _inner(c, isRest, dk)),
          ),

          // Shimmer
          if (c.isToday || st == WeekDayStatus.inProgress)
            Positioned.fill(child: _Shimmer(a: _shimA)),

          // Today ring
          if (c.isToday)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_Tok.cr),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
            ),

          // Feedback Indicator line & Count (Bottom Left)
          if (c.hasFeedback)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 2),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.forum_rounded, size: 7, color: Colors.white),
                    const SizedBox(width: 2),
                    Text(
                      '${c.feedbackCount}',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Completion Indicator line (Bottom Right)
          if (c.isComplete)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 14,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676),
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 2),
                  ],
                ),
              ),
            ),

          // Complete check mark (Top Right)
          if (c.isComplete)
            Positioned(
              top: 3,
              right: 3,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 11,
                  color: Color(0xFF00C853),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _inner(_Cell c, bool rest, bool dk) {
    final textC = rest
        ? (dk
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.3))
        : Colors.white;

    return Text(
      '${c.date.day}',
      style: TextStyle(
        fontSize: 14,
        fontWeight: rest ? FontWeight.w500 : FontWeight.w800,
        color: textC,
        height: 1,
        shadows: rest
            ? null
            : const [
          Shadow(
            color: Colors.black26,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Page Dots
  // -----------------------------------------------------------------------

  Widget _dots(ThemeData th) {
    if (_months.length <= 1) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_months.length, (i) {
            final a = i == _pg;
            return GestureDetector(
              onTap: () => _nav(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: a ? 24 : 6,
                height: 6,
                decoration: BoxDecoration(
                  gradient: a
                      ? LinearGradient(colors: [
                    th.colorScheme.primary,
                    th.colorScheme.secondary,
                  ])
                      : null,
                  color: a
                      ? null
                      : th.colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Stats Row
  // -----------------------------------------------------------------------

  Widget _statsRow(ThemeData th, bool dk, Map<String, int> stats) {
    final items = [
      (
      stats['completed']!,
      'Done',
      const Color(0xFF00E676),
      Icons.check_circle_rounded,
      ),
      (
      stats['active']!,
      'Active',
      const Color(0xFF2979FF),
      Icons.play_circle_rounded,
      ),
      (
      stats['missed']!,
      'Missed',
      const Color(0xFFFF5252),
      Icons.cancel_rounded,
      ),
      (
      widget.task.summary.progress,
      'Progress',
      CardColorHelper.getProgressColor(widget.task.summary.progress),
      Icons.trending_up_rounded,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: dk
                ? [
              Colors.white.withValues(alpha: 0.06),
              Colors.white.withValues(alpha: 0.02),
            ]
                : [
              Colors.black.withValues(alpha: 0.04),
              Colors.black.withValues(alpha: 0.01),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: dk
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((it) {
            final isProg = it.$2 == 'Progress';
            return AnimatedBuilder(
              animation: _glA,
              builder: (_, __) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: it.$3.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: it.$3.withOpacity(
                          0.5 + _glA.value * 0.2,
                        ),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: it.$3.withValues(alpha: _glA.value * 0.3),
                          blurRadius: 8,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: isProg
                          ? Text(
                        '${it.$1}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: it.$3,
                        ),
                      )
                          : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(it.$4, size: 14, color: it.$3),
                          const SizedBox(width: 2),
                          Text(
                            '${it.$1}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: it.$3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    it.$2,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: dk ? Colors.white38 : Colors.black45,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SHIMMER OVERLAY
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _Shimmer extends StatelessWidget {
  final Animation<double> a;
  const _Shimmer({required this.a});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: a,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(_Tok.cr - 1),
        child: ShaderMask(
          shaderCallback: (b) => LinearGradient(
            begin: Alignment(a.value - 1, 0),
            end: Alignment(a.value, 0),
            colors: const [
              Colors.transparent,
              Colors.white,
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(b),
          blendMode: BlendMode.overlay,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(_Tok.cr - 1),
            ),
          ),
        ),
      ),
    );
  }
}
