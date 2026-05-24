import '../database/app_database.dart';
import '../models/habit_type.dart';
import 'date_utils.dart';
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

  static int trackedDaysSince(DateTime createdAt) {
    final start = HabitDateUtils.startOfDay(createdAt);
    final today = HabitDateUtils.startOfDay(DateTime.now());
    return today.difference(start).inDays + 1;
  }

  static Iterable<DateTime> daysFromCreation(DateTime createdAt) {
    final start = HabitDateUtils.startOfDay(createdAt);
    final today = HabitDateUtils.startOfDay(DateTime.now());
    final count = today.difference(start).inDays + 1;
    return List.generate(
      count,
      (i) => start.add(Duration(days: i)),
    );
  }

  static YesNoHabitReport buildYesNoReport({
    required HabitData habit,
    required Set<String> completionDates,
  }) {
    final tracked = trackedDaysSince(habit.createdAt);
    final done = completionDates.length;
    final failed = (tracked - done).clamp(0, tracked);
    final rate = tracked == 0 ? 0.0 : (done / tracked) * 100;

    return YesNoHabitReport(
      daysDone: done,
      daysFailed: failed,
      successRate: rate,
      streak: StreakCalculator.compute(completionDates),
      completionDates: completionDates,
      trackedDays: tracked,
    );
  }

  static QuantitativeHabitReport buildQuantitativeReport({
    required HabitData habit,
    required List<HabitCompletion> completions,
    required Set<String> goalMetDates,
  }) {
    final todayKey = HabitDateUtils.todayKey();
    final rowsWithValue = completions
        .where((c) => (c.loggedValue ?? 0) > 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    double todayValue = 0;
    for (final row in rowsWithValue) {
      if (row.date == todayKey) {
        todayValue = row.loggedValue ?? 0;
        break;
      }
    }

    var total = 0.0;
    HabitCompletion? bestRow;
    for (final row in rowsWithValue) {
      final v = row.loggedValue ?? 0;
      total += v;
      if (bestRow == null || v > (bestRow.loggedValue ?? 0)) {
        bestRow = row;
      }
    }

    final daysLogged = rowsWithValue.length;
    final average = daysLogged == 0 ? 0.0 : total / daysLogged;
    final goal = habit.goalValue.toDouble();
    final progress = goal <= 0 ? 0.0 : (todayValue / goal).clamp(0.0, 1.0);

    final last30 = HabitDateUtils.lastDays(30);
    final valueByDate = {
      for (final r in rowsWithValue) r.date: r.loggedValue ?? 0.0,
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
      bestDayValue: bestRow?.loggedValue ?? 0,
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
    required List<HabitData> habits,
    required List<HabitCompletion> allCompletions,
  }) {
    if (habits.isEmpty) {
      return const GlobalStreakStats(currentStreak: 0, bestStreak: 0);
    }

    final completionsByHabit = <String, Map<String, HabitCompletion>>{};
    for (final row in allCompletions) {
      completionsByHabit
          .putIfAbsent(row.habitId, () => {})
          [row.date] = row;
    }

    final successDays = <String>{};
    final earliest = habits
        .map((h) => HabitDateUtils.startOfDay(h.createdAt))
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final today = HabitDateUtils.startOfDay(DateTime.now());
    var cursor = earliest;

    while (!cursor.isAfter(today)) {
      final key = HabitDateUtils.dateKey(cursor);
      final activeHabits = habits.where((h) {
        final created = HabitDateUtils.startOfDay(h.createdAt);
        return !created.isAfter(cursor);
      });

      if (activeHabits.isEmpty) {
        cursor = cursor.add(const Duration(days: 1));
        continue;
      }

      var allMet = true;
      for (final habit in activeHabits) {
        final row = completionsByHabit[habit.id]?[key];
        final met = _isGoalMetSync(habit, row);
        if (!met) {
          allMet = false;
          break;
        }
      }

      if (allMet) successDays.add(key);
      cursor = cursor.add(const Duration(days: 1));
    }

    final streak = StreakCalculator.compute(successDays);
    return GlobalStreakStats(
      currentStreak: streak.currentStreak,
      bestStreak: streak.bestStreak,
    );
  }

  static bool _isGoalMetSync(HabitData habit, HabitCompletion? row) {
    if (row == null) return false;
    if (HabitType.fromKey(habit.habitType) == HabitType.yesNo) return true;
    return (row.loggedValue ?? 0) >= habit.goalValue;
  }
}
