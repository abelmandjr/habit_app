import 'package:clock/clock.dart';

import '../../../../core/utils/date_utils.dart';
import '../entities/habit.dart';
import '../entities/habit_log.dart';
import 'streak_calculator.dart';

class GlobalStreakStats {
  const GlobalStreakStats({
    required this.currentStreak,
    required this.bestStreak,
  });

  final int currentStreak;
  final int bestStreak;
}

class YesNoHabitReport {
  const YesNoHabitReport({
    required this.daysDone,
    required this.daysFailed,
    required this.successRate,
    required this.streak,
    required this.completionDates,
    required this.trackedDays,
  });

  final int daysDone;
  final int daysFailed;
  final double successRate;
  final StreakStats streak;
  final Set<String> completionDates;
  final int trackedDays;
}

class QuantitativeDayValue {
  const QuantitativeDayValue({required this.date, required this.value});

  final String date;
  final double value;
}

class QuantitativeHabitReport {
  const QuantitativeHabitReport({
    required this.todayValue,
    required this.dailyAverage,
    required this.totalAccumulated,
    required this.bestDayValue,
    required this.bestDayDate,
    required this.goalProgress,
    required this.goalMetToday,
    required this.history,
    required this.streak,
    required this.goalMetDates,
    required this.loggedDates,
  });

  final double todayValue;
  final double dailyAverage;
  final double totalAccumulated;
  final double bestDayValue;
  final String? bestDayDate;
  final double goalProgress;
  final bool goalMetToday;
  final List<QuantitativeDayValue> history;
  final StreakStats streak;
  final Set<String> goalMetDates;
  final Set<String> loggedDates;
}

class HabitReportCalculator {
  HabitReportCalculator._();

  /// Chave do dia de início do hábito. Até à v5 (coluna `startDate`, tarefa
  /// 3.4), a data de início é o dia de criação.
  static String startKeyOf(Habit habit) =>
      HabitDateUtils.dateKey(habit.createdAt);

  /// Dias de calendário desde o início até hoje, inclusive.
  static int trackedDaysSince(DateTime createdAt) =>
      HabitDateUtils.daysBetween(createdAt, clock.now()) + 1;

  static Set<String> _fromStart(Set<String> dates, String startKey) =>
      dates.where((d) => d.compareTo(startKey) >= 0).toSet();

  static YesNoHabitReport buildYesNoReport({
    required Habit habit,
    required Set<String> completionDates,
  }) {
    final dates = _fromStart(completionDates, startKeyOf(habit));
    final tracked = trackedDaysSince(habit.createdAt);
    final doneToday = dates.contains(HabitDateUtils.todayKey());

    // Hoje só conta (como feito) se já estiver feito; por fazer ainda não é
    // uma falha.
    final pastDays = (tracked - 1).clamp(0, tracked);
    final donePast = dates.length - (doneToday ? 1 : 0);
    final failed = (pastDays - donePast).clamp(0, pastDays);
    final evaluated = pastDays + (doneToday ? 1 : 0);
    final rate = evaluated == 0 ? 0.0 : (dates.length / evaluated) * 100;

    return YesNoHabitReport(
      daysDone: dates.length,
      daysFailed: failed,
      successRate: rate,
      streak: StreakCalculator.compute(dates),
      completionDates: dates,
      trackedDays: tracked,
    );
  }

  static QuantitativeHabitReport buildQuantitativeReport({
    required Habit habit,
    required List<HabitLog> logs,
    required Set<String> goalMetDates,
  }) {
    final todayKey = HabitDateUtils.todayKey();
    final startKey = startKeyOf(habit);
    goalMetDates = _fromStart(goalMetDates, startKey);
    final rowsWithValue = logs
        .where((c) => (c.value ?? 0) > 0)
        .where((c) => c.date.compareTo(startKey) >= 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    double todayValue = 0;
    for (final row in rowsWithValue) {
      if (row.date == todayKey) {
        todayValue = row.value ?? 0;
        break;
      }
    }

    var total = 0.0;
    HabitLog? bestRow;
    for (final row in rowsWithValue) {
      final v = row.value ?? 0;
      total += v;
      if (bestRow == null || v > (bestRow.value ?? 0)) {
        bestRow = row;
      }
    }

    final daysLogged = rowsWithValue.length;
    final average = daysLogged == 0 ? 0.0 : total / daysLogged;
    final goal = habit.goalValue.toDouble();
    final progress = goal <= 0 ? 0.0 : (todayValue / goal).clamp(0.0, 1.0);

    final last30 = HabitDateUtils.lastDays(30);
    final valueByDate = {
      for (final r in rowsWithValue) r.date: r.value ?? 0.0,
    };
    final history = last30
        .map(
          (d) => QuantitativeDayValue(
            date: HabitDateUtils.dateKey(d),
            value: valueByDate[HabitDateUtils.dateKey(d)] ?? 0,
          ),
        )
        .toList();

    final loggedDates = rowsWithValue.map((r) => r.date).toSet();

    return QuantitativeHabitReport(
      todayValue: todayValue,
      dailyAverage: average,
      totalAccumulated: total,
      bestDayValue: bestRow?.value ?? 0,
      bestDayDate: bestRow?.date,
      goalProgress: progress,
      goalMetToday: goalMetDates.contains(todayKey),
      history: history,
      streak: StreakCalculator.compute(goalMetDates),
      goalMetDates: goalMetDates,
      loggedDates: loggedDates,
    );
  }

  /// Dia conta se todos os hábitos ativos nesse dia atingiram a meta.
  static GlobalStreakStats computeGlobalStreak({
    required List<Habit> habits,
    required List<HabitLog> allLogs,
  }) {
    if (habits.isEmpty) {
      return const GlobalStreakStats(currentStreak: 0, bestStreak: 0);
    }

    final completionsByHabit = <String, Map<String, HabitLog>>{};
    for (final row in allLogs) {
      completionsByHabit
          .putIfAbsent(row.habitId, () => {})
          [row.date] = row;
    }

    // Percorre os dias por chave (YYYY-MM-DD): cada passo é exatamente um dia
    // de calendário, mesmo com mudanças de hora (bug M10).
    final successDays = <String>{};
    final starts = {for (final h in habits) h.id: startKeyOf(h)};
    final earliest = starts.values.reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
    final today = HabitDateUtils.todayKey();

    for (var key = earliest;
        key.compareTo(today) <= 0;
        key = HabitDateUtils.addDays(key, 1)) {
      final activeHabits =
          habits.where((h) => starts[h.id]!.compareTo(key) <= 0);
      if (activeHabits.isEmpty) continue;

      final allMet = activeHabits.every(
        (habit) => habit.isGoalMet(completionsByHabit[habit.id]?[key]),
      );
      if (allMet) successDays.add(key);
    }

    final streak = StreakCalculator.compute(successDays);
    return GlobalStreakStats(
      currentStreak: streak.currentStreak,
      bestStreak: streak.bestStreak,
    );
  }

}
