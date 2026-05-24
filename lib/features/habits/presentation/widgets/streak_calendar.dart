import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';

/// Heatmap mensal: amarelo = concluído, vermelho = não concluído, azul = hoje.
class StreakCalendar extends StatefulWidget {
  const StreakCalendar({
    super.key,
    required this.completionDates,
    required this.habitCreatedAt,
    this.loggedDates,
    this.onDayTap,
    this.initialMonth,
  });

  /// Dias em que a meta foi atingida (amarelo).
  final Set<String> completionDates;

  /// Dias com qualquer registo, mesmo abaixo da meta (vermelho se não concluído).
  final Set<String>? loggedDates;

  final DateTime habitCreatedAt;
  final void Function(DateTime day)? onDayTap;
  final DateTime? initialMonth;

  static const completedYellow = Color(0xFFFFD54F);
  static const loggedIncompleteRed = Color(0xFFEF5350);
  static const todayBlue = Color(0xFF42A5F5);
  static const neutralFill = Color(0x00000000);

  @override
  State<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<StreakCalendar> {
  static const _weekdays = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(
      (widget.initialMonth ?? now).year,
      (widget.initialMonth ?? now).month,
    );
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
          'Calendário de progresso',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _LegendDot(color: StreakCalendar.completedYellow, label: 'Concluído'),
            _LegendDot(
              color: StreakCalendar.loggedIncompleteRed,
              label: 'Registado',
            ),
            _LegendDot(color: StreakCalendar.todayBlue, label: 'Hoje'),
          ],
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
                    onPressed: () => setState(() {
                      _displayedMonth = DateTime(
                        _displayedMonth.year,
                        _displayedMonth.month - 1,
                      );
                    }),
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
                    onPressed: () => setState(() {
                      _displayedMonth = DateTime(
                        _displayedMonth.year,
                        _displayedMonth.month + 1,
                      );
                    }),
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              ...weeks.map(
                (week) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: week.map((day) {
                      if (day == null) {
                        return const Expanded(child: SizedBox(height: 36));
                      }
                      return Expanded(
                        child: _HeatmapDay(
                          key: ValueKey(
                            '${HabitDateUtils.dateKey(day)}_${widget.completionDates.contains(HabitDateUtils.dateKey(day))}_${widget.loggedDates?.contains(HabitDateUtils.dateKey(day))}',
                          ),
                          day: day,
                          today: today,
                          completionDates: widget.completionDates,
                          loggedDates: widget.loggedDates,
                          onTap: widget.onDayTap,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<List<DateTime?>> _buildWeeks(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = first.weekday % 7;

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

class _HeatmapDay extends StatelessWidget {
  const _HeatmapDay({
    super.key,
    required this.day,
    required this.today,
    required this.completionDates,
    this.loggedDates,
    this.onTap,
  });

  final DateTime day;
  final DateTime today;
  final Set<String> completionDates;
  final Set<String>? loggedDates;
  final void Function(DateTime day)? onTap;

  @override
  Widget build(BuildContext context) {
    final key = HabitDateUtils.dateKey(day);
    final isToday = _sameDay(day, today);
    final isFuture = day.isAfter(today);
    final dayNorm = HabitDateUtils.startOfDay(day);
    final completed = completionDates.contains(key);
    final logged = loggedDates?.contains(key) ?? completed;

    final theme = Theme.of(context);
    Color fill = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);
    Color textColor = theme.colorScheme.onSurfaceVariant;
    Border? border;

    if (isFuture) {
      fill = theme.colorScheme.surfaceContainerHighest;
      textColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
    } else if (isToday) {
      border = Border.all(color: StreakCalendar.todayBlue, width: 2.5);
      if (completed) {
        fill = StreakCalendar.completedYellow;
        textColor = Colors.black87;
      } else if (logged) {
        fill = StreakCalendar.loggedIncompleteRed;
        textColor = Colors.white;
      }
    } else if (completed) {
      fill = StreakCalendar.completedYellow;
      textColor = Colors.black87;
    } else if (logged) {
      fill = StreakCalendar.loggedIncompleteRed;
      textColor = Colors.white;
    }
    // Sem registo: mantém fill neutro (passado ou antes da criação).

    // Permite editar qualquer dia passado (incl. antes da criação) para migração de histórico.
    final canTap = onTap != null && !isFuture;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: GestureDetector(
        onTap: canTap ? () => onTap!(dayNorm) : null,
        behavior: HitTestBehavior.opaque,
        child: Material(
          color: fill,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: border,
            ),
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
