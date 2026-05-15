// lib/features/personal/task_model/day_tasks/screens/day_task_calendar_dialog.dart
// ═══════════════════════════════════════════════════════════════════════════
// DAY TASK CALENDAR DIALOG — Premium UI (Image 2 Style)
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/day_task_model.dart';
import '../providers/day_task_provider.dart';
import '../screens/task_form_bottom_sheet.dart';
import '../screens/day_schedule_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════

enum DayStatus {
  completed,   // All tasks for the day are complete
  missed,      // At least one task was missed
  inProgress,  // Tasks are active today
  pending,     // Future tasks scheduled (Amber)
  noTasks,     // No tasks for this day (Subtle Grey)
  partial,     // Some tasks complete, some not
  rest,        // Explicit rest day or no tasks in past (Grey)
}

extension DayStatusExt on DayStatus {
  List<Color> getG(bool isDark) {
    switch (this) {
      case DayStatus.completed:
        return [const Color(0xFF10B981), const Color(0xFF059669)]; // Green (Done)
      case DayStatus.missed:
      case DayStatus.partial:
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)]; // Red (Missed)
      case DayStatus.inProgress:
        return [const Color(0xFF3B82F6), const Color(0xFF2563EB)]; // Blue (Today Task)
      case DayStatus.pending:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)]; // Yellow/Amber (Planned)
      case DayStatus.noTasks:
      case DayStatus.rest:
      default:
        return isDark
            ? [const Color(0xFF1F1F2E), const Color(0xFF1A1A26)] // Gray (Unscheduled/Future)
            : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)]; // Gray (Unscheduled/Future)
    }
  }

  List<Color> get g => getG(true);

  IconData get icon {
    switch (this) {
      case DayStatus.completed:
        return Icons.check_circle_rounded;
      case DayStatus.missed:
      case DayStatus.partial:
        return Icons.cancel_rounded;
      case DayStatus.pending:
        return Icons.schedule_rounded;
      case DayStatus.inProgress:
        return Icons.play_circle_fill_rounded;
      case DayStatus.noTasks:
      case DayStatus.rest:
      default:
        return Icons.circle;
    }
  }

  Color getColor(bool isDark) {
    switch (this) {
      case DayStatus.completed:
        return const Color(0xFF10B981);
      case DayStatus.missed:
      case DayStatus.partial:
        return const Color(0xFFEF4444);
      case DayStatus.pending:
        return const Color(0xFFF59E0B);
      case DayStatus.inProgress:
        return const Color(0xFF3B82F6);
      case DayStatus.noTasks:
      case DayStatus.rest:
      default:
        return isDark ? Colors.white30 : Colors.black26;
    }
  }

  Color get color => getColor(true);

  Color get primary => g.first;

  Color getTextColor(bool isDark, bool isSelected) {
    if (isSelected) return Colors.white;
    switch (this) {
      case DayStatus.completed:
      case DayStatus.missed:
      case DayStatus.inProgress:
      case DayStatus.pending:
        return Colors.white;
      case DayStatus.noTasks:
      case DayStatus.rest:
      default:
        return isDark ? Colors.white54 : Colors.black54;
    }
  }

  String get label {
    switch (this) {
      case DayStatus.completed:
        return 'Done';
      case DayStatus.missed:
      case DayStatus.partial:
        return 'Missed';
      case DayStatus.pending:
        return 'Planned';
      case DayStatus.inProgress:
        return 'Today';
      case DayStatus.noTasks:
      case DayStatus.rest:
      default:
        return 'Unscheduled';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════════════════

class _Tok {
  const _Tok._();

  static const double br = 32.0;
  static const double cr = 16.0;
  static const double gap = 8.0;

  static const dayShort = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
}

// ═══════════════════════════════════════════════════════════════════════════
// CELL DATA
// ═══════════════════════════════════════════════════════════════════════════

class _Cell {
  final DateTime date;
  final DayStatus status;
  final List<DayTaskModel> tasks;
  final bool isCurMonth, isToday;

  const _Cell({
    required this.date,
    required this.status,
    required this.tasks,
    required this.isCurMonth,
    required this.isToday,
  });

  bool get hasTasks => tasks.isNotEmpty;
  int get taskCount => tasks.length;
  int get completedCount => tasks.where((t) => t.metadata.isComplete).length;
  int get feedbackCount => tasks.fold(0, (sum, t) => sum + t.feedbackCount);
  bool get hasFeedback => feedbackCount > 0;
  bool get isComplete => hasTasks && tasks.every((t) => t.metadata.isComplete);
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class DayTaskCalendarDialog extends StatefulWidget {
  final bool showAsDialog;
  final VoidCallback? onClose;
  final void Function(DateTime date)? onDayTap;

  const DayTaskCalendarDialog({
    super.key,
    this.showAsDialog = true,
    this.onClose,
    this.onDayTap,
  });

  static Future<void> show(BuildContext context, {void Function(DateTime date)? onDayTap}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'DayTaskCalendar',
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (ctx, _, __) => DayTaskCalendarDialog(
        showAsDialog: true,
        onClose: () => Navigator.of(ctx).pop(),
        onDayTap: onDayTap,
      ),
      transitionBuilder: (_, anim, __, child) {
        final c = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return Transform.scale(
          scale: 0.8 + (0.2 * c.value),
          child: Opacity(opacity: anim.value.clamp(0.0, 1.0), child: child),
        );
      },
    );
  }

  @override
  State<DayTaskCalendarDialog> createState() => _DayTaskCalState();
}

class _DayTaskCalState extends State<DayTaskCalendarDialog> with TickerProviderStateMixin {
  late PageController _pc;
  late List<DateTime> _months;
  int _pg = 0;
  DateTime? _selectedDate;

  late AnimationController _shimC, _pulC, _floC, _glC;
  late Animation<double> _shimA, _pulA, _floA, _glA;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _months = _buildMonths();
    _pg = _todayPage();
    _pc = PageController(initialPage: _pg);
    _initAnims();
  }

  @override
  void dispose() {
    _shimC.dispose(); _pulC.dispose(); _floC.dispose(); _glC.dispose();
    _pc.dispose();
    super.dispose();
  }

  void _initAnims() {
    _shimC = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _shimA = Tween<double>(begin: -1.0, end: 2.0).animate(CurvedAnimation(parent: _shimC, curve: Curves.easeInOut));
    _pulC = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulA = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _pulC, curve: Curves.easeInOut));
    _floC = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _floA = Tween<double>(begin: 0, end: 8).animate(CurvedAnimation(parent: _floC, curve: Curves.easeInOut));
    _glC = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glA = Tween<double>(begin: 0.3, end: 0.7).animate(CurvedAnimation(parent: _glC, curve: Curves.easeInOut));
  }

  List<DateTime> _buildMonths() {
    final list = <DateTime>[];
    final now = DateTime.now();

    // Min limit: signup month of the user
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

    // Max limit: 12 months forward from current month
    final maxMonth = DateTime(now.year, now.month + 12);

    // Build consecutive months list from minMonth to maxMonth
    var current = minMonth;
    while (!current.isAfter(maxMonth)) {
      list.add(current);
      current = DateTime(current.year, current.month + 1);
    }

    return list;
  }

  int _todayPage() {
    final now = DateTime.now();
    for (int i = 0; i < _months.length; i++) {
      if (_months[i].year == now.year && _months[i].month == now.month) return i;
    }
    return _months.isEmpty ? 0 : _months.length - 1;
  }

  DayStatus _calculateDayStatus(List<DayTaskModel> tasks, DateTime date) {
    if (tasks.isEmpty) return DayStatus.noTasks;
    
    final now = DateTime.now();
    final today = _isSameDay(date, now);
    final isFuture = date.isAfter(now) && !today;

    final done = tasks.where((t) => t.indicators.status == 'completed').length;
    if (done == tasks.length) return DayStatus.completed;

    if (today) return DayStatus.inProgress;
    if (isFuture) return DayStatus.pending;

    // Past: if not all done, treat as missed/incomplete
    return DayStatus.missed;
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _parseDate(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now();
    try {
      // Improved date parsing
      if (dateStr.length >= 10) {
        if (dateStr.substring(0, 4).contains(RegExp(r'^\d{4}$'))) {
          // yyyy-MM-dd
          return DateTime.parse(dateStr);
        } else if (dateStr.contains('-')) {
          // dd-MM-yyyy
          return DateFormat('dd-MM-yyyy').parse(dateStr);
        }
      }
      return DateTime.parse(dateStr);
    } catch (_) { return DateTime.now(); }
  }

  void _tap(_Cell c) {
    HapticFeedback.heavyImpact();
    setState(() {
      _selectedDate = c.date;
    });

    if (widget.onDayTap != null) {
      widget.onDayTap!(c.date);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DayScheduleScreen(initialDate: c.date),
        ),
      );
    }

    if (widget.showAsDialog) {
      widget.onClose?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final dk = th.brightness == Brightness.dark;

    Widget content = Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: dk ? const Color(0xFF101018) : Colors.white,
        borderRadius: BorderRadius.circular(_Tok.br),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, offset: const Offset(0, 20)),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(th, dk),
            _legend(th, dk),
            _monthNav(th, dk),
            const SizedBox(height: 12),
            SizedBox(
              height: 360,
              child: _pager(th, dk),
            ),
            _dots(th, dk),
            _statsSummary(th, dk),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (widget.showAsDialog) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Material(color: Colors.transparent, child: content),
        ),
      );
    }

    return content;
  }

  Widget _header(ThemeData th, bool dk) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 20, 16),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _floA,
            builder: (_, child) => Transform.translate(offset: Offset(0, _floA.value), child: child),
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [th.colorScheme.primary, th.colorScheme.secondary]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: th.colorScheme.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SCHEDULE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: th.colorScheme.primary, letterSpacing: 2.0)),
                const SizedBox(height: 4),
                Text('Task Calendar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: dk ? Colors.white : Colors.black87, letterSpacing: -0.6)),
              ],
            ),
          ),
          if (widget.showAsDialog)
            IconButton(
              onPressed: widget.onClose,
              icon: Icon(Icons.close_rounded, color: dk ? Colors.white70 : Colors.black54),
              style: IconButton.styleFrom(backgroundColor: dk ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06), padding: const EdgeInsets.all(12)),
            ),
        ],
      ),
    );
  }

  Widget _legend(ThemeData th, bool dk) {
    final items = [
      (DayStatus.completed, 'Done', Icons.check_circle_rounded),
      (DayStatus.inProgress, 'Today', Icons.play_circle_rounded),
      (DayStatus.pending, 'Planned', Icons.schedule_rounded),
      (DayStatus.missed, 'Missed', Icons.cancel_rounded),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: dk ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dk ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((it) {
          final isT = it.$1 == DayStatus.inProgress;
          final colors = it.$1.getG(dk);
          return AnimatedBuilder(
            animation: _pulA,
            builder: (_, __) => Transform.scale(
              scale: isT ? _pulA.value : 1.0,
              child: Row(
                children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: isT ? [BoxShadow(color: it.$1.getColor(dk).withOpacity(0.5), blurRadius: 8)] : null,
                    ),
                    child: Icon(it.$3, size: 13, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(it.$2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: dk ? Colors.white60 : Colors.black54)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _monthNav(ThemeData th, bool dk) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [th.colorScheme.primary.withOpacity(0.15), th.colorScheme.secondary.withOpacity(0.08)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: th.colorScheme.primary.withOpacity(0.25), width: 1.8),
      ),
      child: Row(
        children: [
          _navBtn(Icons.chevron_left_rounded, _pg > 0, () => _pc.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic), th),
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy').format(_months[_pg]).toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: th.colorScheme.primary),
            ),
          ),
          _navBtn(Icons.chevron_right_rounded, _pg < _months.length - 1, () => _pc.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic), th),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, bool en, VoidCallback cb, ThemeData th) {
    return GestureDetector(
      onTap: en ? () { HapticFeedback.lightImpact(); cb(); } : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: en ? th.colorScheme.primary.withOpacity(0.12) : Colors.transparent, borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, size: 28, color: en ? th.colorScheme.primary : Colors.grey.withOpacity(0.3)),
      ),
    );
  }

  Widget _pager(ThemeData th, bool dk) {
    return PageView.builder(
      controller: _pc,
      onPageChanged: (v) {
        setState(() => _pg = v);
        final visibleMonth = _months[v];
        context.read<DayTaskProvider>().loadTasks(
          startDate: DateTime(visibleMonth.year, visibleMonth.month, 1),
          endDate: DateTime(visibleMonth.year, visibleMonth.month + 1, 0),
        );
      },
      itemCount: _months.length,
      itemBuilder: (ctx, idx) => _grid(_months[idx], th, dk),
    );
  }

  Widget _grid(DateTime month, ThemeData th, bool dk) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final cells = <_Cell>[];

    final startOffset = first.weekday % 7;
    for (int i = startOffset; i > 0; i--) {
      cells.add(_Cell(date: first.subtract(Duration(days: i)), status: DayStatus.noTasks, tasks: [], isCurMonth: false, isToday: false));
    }

    final provider = context.watch<DayTaskProvider>();
    final now = DateTime.now();

    for (int i = 1; i <= last.day; i++) {
      final d = DateTime(month.year, month.month, i);
      final dayTasks = provider.tasks.where((t) => _isSameDay(d, _parseDate(t.timeline.taskDate))).toList();
      cells.add(_Cell(date: d, status: _calculateDayStatus(dayTasks, d), tasks: dayTasks, isCurMonth: true, isToday: _isSameDay(d, now)));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _wdHdr(th, dk),
          const SizedBox(height: 10),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, 
              childAspectRatio: 1.02, 
              crossAxisSpacing: _Tok.gap, 
              mainAxisSpacing: _Tok.gap,
            ),
            itemCount: cells.length,
            itemBuilder: (_, i) => _cell(cells[i], i, th, dk),
          ),
        ],
      ),
    );
  }

  Widget _wdHdr(ThemeData th, bool dk) {
    return Row(
      children: List.generate(7, (i) => Expanded(
        child: Center(
          child: Text(_Tok.dayShort[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: (i == 0 || i == 6) ? Colors.red.withOpacity(0.7) : (dk ? Colors.white38 : Colors.black38))),
        ),
      )),
    );
  }

  Widget _cell(_Cell c, int idx, ThemeData th, bool dk) {
    if (!c.isCurMonth) return const SizedBox.shrink();

    final colors = c.status.getG(dk);
    final isT = c.isToday;
    final hasT = c.hasTasks;
    final now = DateTime.now();
    final isPast = c.date.isBefore(DateTime(now.year, now.month, now.day));
    
    final isSelected = _selectedDate != null && _isSameDay(c.date, _selectedDate!);

    final total = c.taskCount;
    final doneCount = c.tasks.where((t) => t.indicators.status == 'completed').length;
    final missedCount = c.tasks.where((t) => t.indicators.status != 'completed' && isPast).length;
    final pendingCount = total - doneCount - missedCount;

    // Determine primary icon or overlay icon
    IconData? mainIcon;
    Color? iconCol;
    if (doneCount == total && total > 0) {
      mainIcon = DayStatus.completed.icon;
      iconCol = DayStatus.completed.getColor(dk);
    } else if (isT) {
      mainIcon = DayStatus.inProgress.icon;
      iconCol = DayStatus.inProgress.getColor(dk);
    } else if (missedCount > 0) {
      mainIcon = DayStatus.missed.icon;
      iconCol = DayStatus.missed.getColor(dk);
    } else if (pendingCount > 0) {
      mainIcon = DayStatus.pending.icon;
      iconCol = DayStatus.pending.getColor(dk);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 250 + (idx % 14) * 20),
      curve: Curves.easeOutBack,
      builder: (_, s, child) => Transform.scale(scale: isSelected ? s * 1.05 : s, child: child),
      child: GestureDetector(
        onTap: () => _tap(c),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? [th.colorScheme.primary, th.colorScheme.secondary]
                      : [
                          colors[0].withOpacity(isT ? 1.0 : 0.85),
                          colors[1].withOpacity(isT ? 0.95 : 0.65),
                        ],
                ),
                borderRadius: BorderRadius.circular(_Tok.cr),
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : (isT ? DayStatus.inProgress.getColor(dk) : (hasT ? colors[0].withOpacity(0.5) : Colors.transparent)),
                  width: isSelected ? 3.0 : (isT ? 2.5 : 1.2),
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: th.colorScheme.primary.withOpacity(0.6), blurRadius: 14, offset: const Offset(0, 4))]
                    : (hasT ? [BoxShadow(color: colors[0].withOpacity(isT ? 0.5 : 0.2), blurRadius: isT ? 12 : 6, offset: const Offset(0, 3))] : null),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '${c.date.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: hasT || isSelected ? FontWeight.w900 : FontWeight.w600,
                          color: c.status.getTextColor(dk, isSelected),
                        ),
                      ),
                    ),
                  ),
                  if (hasT)
                    Positioned(
                      bottom: 6, left: 0, right: 0,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _cntIcn('T', total, Colors.white70),
                            if (doneCount > 0) _cntIcn('D', doneCount, DayStatus.completed.getColor(dk)),
                            if (missedCount > 0) _cntIcn('M', missedCount, DayStatus.missed.getColor(dk)),
                            if (pendingCount > 0) _cntIcn('P', pendingCount, DayStatus.pending.getColor(dk)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isT) Positioned.fill(child: _Shimmer(a: _shimA)),
            if (mainIcon != null)
              Positioned(
                top: 5, right: 5,
                child: Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(mainIcon, size: 10, color: iconCol),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cntIcn(String label, int val, Color col) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1),
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(3)),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(text: '$label:', style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w400, color: Colors.white60)),
              TextSpan(text: '$val', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: col)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dots(ThemeData th, bool dk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_months.length, (i) {
          final a = i == _pg;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: a ? 20 : 6, height: 6,
            decoration: BoxDecoration(gradient: a ? LinearGradient(colors: [th.colorScheme.primary, th.colorScheme.secondary]) : null, color: a ? null : (dk ? Colors.white12 : Colors.black12), borderRadius: BorderRadius.circular(4)),
          );
        }),
      ),
    );
  }

  Widget _statsSummary(ThemeData th, bool dk) {
    final now = DateTime.now();
    final provider = context.watch<DayTaskProvider>();
    final monthTasks = provider.tasks.where((t) {
      final d = _parseDate(t.timeline.taskDate);
      return d.year == _months[_pg].year && d.month == _months[_pg].month;
    }).toList();

    final total = monthTasks.length;
    final done = monthTasks.where((t) => t.indicators.status == 'completed').length;
    final missed = monthTasks.where((t) {
      final isCompleted = t.indicators.status == 'completed';
      final s = t.calculateStatus();
      return (s == 'failed' || s == 'missed') || (!isCompleted && _parseDate(t.timeline.taskDate).isBefore(DateTime(now.year, now.month, now.day)));
    }).length;

    final stats = [
      (total, 'Total Tasks', const Color(0xFF90A4AE), Icons.analytics_rounded),
      (done, 'Completed', const Color(0xFF1B5E20), Icons.task_alt_rounded),
      (missed, 'Missed/Left', const Color(0xFFB71C1C), Icons.error_outline_rounded),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: dk ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: dk ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: stats.map((it) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: it.$3.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(it.$4, color: it.$3, size: 22),
            ),
            const SizedBox(height: 10),
            Text('${it.$1}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: it.$3, letterSpacing: -0.5)),
            Text(it.$2, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: dk ? Colors.white54 : Colors.black54, letterSpacing: 0.5)),
          ],
        )).toList(),
      ),
    );
  }
}

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
          shaderCallback: (b) => LinearGradient(begin: Alignment(a.value - 1, 0), end: Alignment(a.value, 0), colors: const [Colors.transparent, Colors.white54, Colors.transparent], stops: const [0.0, 0.5, 1.0]).createShader(b),
          blendMode: BlendMode.overlay,
          child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(_Tok.cr - 1))),
        ),
      ),
    );
  }
}
