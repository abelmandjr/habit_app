import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';

/// Calendário mensal com cápsulas de streak contínuas (estilo da referência).
class StreakCalendar extends StatefulWidget {
  const StreakCalendar({
    super.key,
    required this.completionDates,
    this.onDayTap,
    this.initialMonth,
  });

  final Set<String> completionDates;
  final void Function(DateTime day)? onDayTap;
  final DateTime? initialMonth;

  @override
  State<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<StreakCalendar> {
  static const _weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  static const _monthsPt = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  late DateTime _displayedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(
      (widget.initialMonth ?? now).year,
      (widget.initialMonth ?? now).month,
    );
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  void didUpdateWidget(StreakCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.completionDates != widget.completionDates) {
      setState(() {});
    }
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = HabitDateUtils.startOfDay(DateTime.now());
    final weeks = _buildWeeks(_displayedMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Streak Calendar',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _previousMonth,
                    icon: const Icon(Icons.chevron_left_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: Text(
                      '${_monthsPt[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: _weekdays
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              ...weeks.map((week) => _WeekRow(
                    week: week,
                    completionDates: widget.completionDates,
                    today: today,
                    selectedDay: _selectedDay,
                    onDayTap: (day) {
                      setState(() => _selectedDay = day);
                      widget.onDayTap?.call(day);
                    },
                  )),
            ],
          ),
        ),
      ],
    );
  }

  List<List<DateTime?>> _buildWeeks(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = first.weekday % 7; // Sun=0

    final cells = <DateTime?>[];
    for (var i = 0; i < startWeekday; i++) {
      cells.add(null);
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(month.year, month.month, d));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return List.generate(
      cells.length ~/ 7,
      (i) => cells.sublist(i * 7, i * 7 + 7),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.week,
    required this.completionDates,
    required this.today,
    required this.selectedDay,
    required this.onDayTap,
  });

  final List<DateTime?> week;
  final Set<String> completionDates;
  final DateTime today;
  final DateTime? selectedDay;
  final void Function(DateTime day) onDayTap;

  static const _streakOrange = Color(0xFFFF8C42);

  @override
  Widget build(BuildContext context) {
    final segments = _streakSegments(week);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth / 7;
          const cellHeight = 40.0;

          return SizedBox(
            height: cellHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final seg in segments)
                  Positioned(
                    left: seg.start * cellWidth + 2,
                    width: (seg.end - seg.start + 1) * cellWidth - 4,
                    top: 6,
                    height: 28,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _streakOrange,
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(seg.roundLeft ? 14 : 0),
                          right: Radius.circular(seg.roundRight ? 14 : 0),
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: List.generate(7, (i) {
                    final day = week[i];
                    if (day == null) {
                      return SizedBox(width: cellWidth, height: cellHeight);
                    }
                    return SizedBox(
                      width: cellWidth,
                      height: cellHeight,
                      child: _DayCell(
                        day: day,
                        today: today,
                        selectedDay: selectedDay,
                        completionDates: completionDates,
                        inStreakSegment: segments.any(
                          (s) => i >= s.start && i <= s.end,
                        ),
                        streakDayIndex: _streakIndex(day, completionDates),
                        onTap: () => onDayTap(day),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<_StreakSegment> _streakSegments(List<DateTime?> week) {
    final segments = <_StreakSegment>[];
    var start = -1;

    for (var i = 0; i < 7; i++) {
      final day = week[i];
      final completed = day != null &&
          completionDates.contains(HabitDateUtils.dateKey(day));

      if (completed && start == -1) {
        start = i;
      } else if (!completed && start != -1) {
        segments.add(_StreakSegment(
          start: start,
          end: i - 1,
          roundLeft: true,
          roundRight: true,
        ));
        start = -1;
      }
    }
    if (start != -1) {
      var endIdx = start;
      for (var j = start; j < 7; j++) {
        final d = week[j];
        if (d != null &&
            completionDates.contains(HabitDateUtils.dateKey(d))) {
          endIdx = j;
        } else if (d != null) {
          break;
        }
      }
      segments.add(_StreakSegment(
        start: start,
        end: endIdx,
        roundLeft: true,
        roundRight: true,
      ));
    }
    return segments;
  }

  int _streakIndex(DateTime day, Set<String> dates) {
    if (!dates.contains(HabitDateUtils.dateKey(day))) return 0;
    var count = 1;
    var cursor = day.subtract(const Duration(days: 1));
    while (dates.contains(HabitDateUtils.dateKey(cursor))) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }
}

class _StreakSegment {
  const _StreakSegment({
    required this.start,
    required this.end,
    required this.roundLeft,
    required this.roundRight,
  });

  final int start;
  final int end;
  final bool roundLeft;
  final bool roundRight;
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.today,
    required this.selectedDay,
    required this.completionDates,
    required this.inStreakSegment,
    required this.streakDayIndex,
    required this.onTap,
  });

  final DateTime day;
  final DateTime today;
  final DateTime? selectedDay;
  final Set<String> completionDates;
  final bool inStreakSegment;
  final int streakDayIndex;
  final VoidCallback onTap;

  static const _streakOrange = Color(0xFFFF8C42);
  static const _streakPale = Color(0xFFFFE8D6);

  @override
  Widget build(BuildContext context) {
    final key = HabitDateUtils.dateKey(day);
    final completed = completionDates.contains(key);
    final isToday = _sameDay(day, today);
    final isFuture = day.isAfter(today);
    final isSelected =
        selectedDay != null && _sameDay(day, selectedDay!) && !isToday;

    final isStreakEnd = completed &&
        !inStreakSegment &&
        !isToday &&
        _isDayAfterMissedStreak(day, completionDates);

    if (isToday) {
      return GestureDetector(
        onTap: onTap,
        child: Center(
          child: _TodayBubble(
            day: day.day,
            completed: completed,
          ),
        ),
      );
    }

    if (isSelected) {
      return GestureDetector(
        onTap: onTap,
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    if (inStreakSegment && completed) {
      final showMilestone = streakDayIndex > 0 && streakDayIndex % 7 == 0;
      return GestureDetector(
        onTap: onTap,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Text(
                '${day.day}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (showMilestone)
                Positioned(
                  top: 0,
                  child: Transform.rotate(
                    angle: 0.785398,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (isStreakEnd) {
      return GestureDetector(
        onTap: onTap,
        child: Center(
          child: Container(
            width: 32,
            height: 28,
            decoration: BoxDecoration(
              color: _streakPale,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: const TextStyle(
                color: _streakOrange,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    if (completed && !isFuture) {
      return GestureDetector(
        onTap: onTap,
        child: Center(
          child: Container(
            width: 32,
            height: 28,
            decoration: BoxDecoration(
              color: _streakOrange.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: isFuture ? null : onTap,
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isFuture
                ? Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.45)
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isDayAfterMissedStreak(DateTime day, Set<String> dates) {
    final prev = day.subtract(const Duration(days: 1));
    final prev2 = day.subtract(const Duration(days: 2));
    return dates.contains(HabitDateUtils.dateKey(day)) &&
        dates.contains(HabitDateUtils.dateKey(prev2)) &&
        !dates.contains(HabitDateUtils.dateKey(prev));
  }
}

class _TodayBubble extends StatelessWidget {
  const _TodayBubble({required this.day, required this.completed});

  final int day;
  final bool completed;

  static const _todayBlue = Color(0xFF4A9EFF);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF7BB8FF), _todayBlue],
              center: Alignment(-0.3, -0.4),
              radius: 0.9,
            ),
            boxShadow: [
              BoxShadow(
                color: _todayBlue.withValues(alpha: 0.45),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(10, 6),
          painter: _BubblePointerPainter(
            color: completed ? _todayBlue : _todayBlue,
          ),
        ),
      ],
    );
  }
}

class _BubblePointerPainter extends CustomPainter {
  _BubblePointerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
