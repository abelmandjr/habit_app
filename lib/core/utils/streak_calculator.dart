import 'date_utils.dart';

class StreakStats {
  const StreakStats({
    required this.currentStreak,
    required this.bestStreak,
    required this.completedToday,
    required this.totalCompletions,
  });

  final int currentStreak;
  final int bestStreak;
  final bool completedToday;
  final int totalCompletions;
}

class StreakCalculator {
  StreakCalculator._();

  static StreakStats compute(Set<String> completionDates) {
    if (completionDates.isEmpty) {
      return const StreakStats(
        currentStreak: 0,
        bestStreak: 0,
        completedToday: false,
        totalCompletions: 0,
      );
    }

    final today = HabitDateUtils.todayKey();
    final completedToday = completionDates.contains(today);

    return StreakStats(
      currentStreak: _currentStreak(completionDates),
      bestStreak: _bestStreak(completionDates),
      completedToday: completedToday,
      totalCompletions: completionDates.length,
    );
  }

  static int _currentStreak(Set<String> dates) {
    var cursor = HabitDateUtils.startOfDay(DateTime.now());
    final todayKey = HabitDateUtils.dateKey(cursor);

    if (!dates.contains(todayKey)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!dates.contains(HabitDateUtils.dateKey(cursor))) {
        return 0;
      }
    }

    var streak = 0;
    while (dates.contains(HabitDateUtils.dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int _bestStreak(Set<String> dates) {
    final sorted = dates.map(HabitDateUtils.parseKey).toList()
      ..sort((a, b) => a.compareTo(b));

    var best = 1;
    var current = 1;

    for (var i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > best) best = current;
      } else if (diff > 1) {
        current = 1;
      }
    }

    return dates.length == 1 ? 1 : best;
  }
}
