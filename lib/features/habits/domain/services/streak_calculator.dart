import '../../../../core/utils/date_utils.dart';

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

  /// Calcula as sequências a partir das chaves `YYYY-MM-DD` dos dias feitos.
  /// Com [startKey], os dias anteriores à data de início são ignorados.
  static StreakStats compute(Set<String> completionDates, {String? startKey}) {
    final dates = startKey == null
        ? completionDates
        : completionDates.where((d) => d.compareTo(startKey) >= 0).toSet();

    if (dates.isEmpty) {
      return const StreakStats(
        currentStreak: 0,
        bestStreak: 0,
        completedToday: false,
        totalCompletions: 0,
      );
    }

    final today = HabitDateUtils.todayKey();

    return StreakStats(
      currentStreak: _currentStreak(dates, today),
      bestStreak: _bestStreak(dates),
      completedToday: dates.contains(today),
      totalCompletions: dates.length,
    );
  }

  /// Hoje ainda por fazer não quebra a sequência que termina ontem.
  static int _currentStreak(Set<String> dates, String today) {
    var cursor = dates.contains(today) ? today : HabitDateUtils.addDays(today, -1);

    var streak = 0;
    while (dates.contains(cursor)) {
      streak++;
      cursor = HabitDateUtils.addDays(cursor, -1);
    }
    return streak;
  }

  static int _bestStreak(Set<String> dates) {
    // parseKey devolve dias em UTC: a diferença entre dias seguidos é sempre
    // exatamente 1, mesmo quando há mudança de hora (bug M10).
    final sorted = dates.map(HabitDateUtils.parseKey).toList()..sort();

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

    return best;
  }
}
