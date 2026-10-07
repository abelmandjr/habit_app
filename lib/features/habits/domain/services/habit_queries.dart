import '../../../../core/utils/combine_latest.dart';
import '../../../../core/utils/date_utils.dart';
import '../entities/habit.dart';
import '../entities/habit_log.dart';
import '../models/habit_with_today.dart';
import '../repositories/habit_repository.dart';
import 'habit_report_calculator.dart';
import 'streak_calculator.dart';

/// Consultas derivadas (estado de hoje, sequências, relatórios) sobre o
/// [HabitRepository]. Antes viviam no `AppDatabase` e no repositório.
class HabitQueries {
  HabitQueries(this._repository);

  final HabitRepository _repository;

  Future<List<HabitWithToday>> getHabitsWithTodayStatus() async =>
      _listWithToday(
        await _repository.getHabits(),
        await _repository.getAllLogs(),
      );

  /// Como [getHabitsWithTodayStatus], mas emite de novo sempre que os hábitos
  /// ou os registos mudam na BD (tarefa 2.2).
  Stream<List<HabitWithToday>> watchHabitsWithTodayStatus() => combineLatest2(
        _repository.watchHabits(),
        _repository.watchAllLogs(),
        _listWithToday,
      );

  /// Emite sempre que o hábito [habitId] ou os seus registos mudam.
  Stream<void> watchHabitChanges(String habitId) => combineLatest2(
        _repository.watchHabit(habitId),
        _repository.watchLogs(habitId),
        (_, _) {},
      );

  List<HabitWithToday> _listWithToday(
    List<Habit> habits,
    List<HabitLog> allLogs,
  ) {
    final logsByHabit = _byHabit(allLogs);
    final today = HabitDateUtils.todayKey();
    return [
      for (final habit in habits)
        _withToday(habit, logsByHabit[habit.id] ?? const [], today),
    ];
  }

  Future<HabitWithToday?> getHabitWithToday(String habitId) async {
    final habit = await _repository.getHabit(habitId);
    if (habit == null) return null;
    final logs = await _repository.getLogs(habitId);
    return _withToday(habit, logs, HabitDateUtils.todayKey());
  }

  /// Dias (desde a data de início) em que a meta de [habitId] foi cumprida.
  Future<Set<String>> getCompletionDates(String habitId) async {
    final habit = await _repository.getHabit(habitId);
    if (habit == null) return {};
    return _completionDates(habit, await _repository.getLogs(habitId));
  }

  Future<StreakStats> getStreakStats(String habitId) async =>
      StreakCalculator.compute(await getCompletionDates(habitId));

  Future<GlobalStreakStats> getGlobalStreakStats() async =>
      HabitReportCalculator.computeGlobalStreak(
        habits: await _repository.getHabits(),
        allLogs: await _repository.getAllLogs(),
      );

  Future<bool> isCompletedOn(String habitId, DateTime day) async {
    final habit = await _repository.getHabit(habitId);
    if (habit == null) return false;
    final log =
        await _repository.getLog(habitId, HabitDateUtils.dateKey(day));
    return habit.isGoalMet(log);
  }

  Future<double?> getValueOn(String habitId, DateTime day) async =>
      (await _repository.getLog(habitId, HabitDateUtils.dateKey(day)))?.value;

  Future<YesNoHabitReport> getYesNoReport(String habitId) async {
    final habit = await _repository.getHabit(habitId);
    if (habit == null) {
      return YesNoHabitReport(
        daysDone: 0,
        daysFailed: 0,
        successRate: 0,
        streak: StreakCalculator.compute({}),
        completionDates: {},
        trackedDays: 0,
      );
    }
    return HabitReportCalculator.buildYesNoReport(
      habit: habit,
      completionDates:
          _completionDates(habit, await _repository.getLogs(habitId)),
    );
  }

  Future<QuantitativeHabitReport> getQuantitativeReport(String habitId) async {
    final habit = await _repository.getHabit(habitId);
    if (habit == null) {
      return QuantitativeHabitReport(
        todayValue: 0,
        dailyAverage: 0,
        totalAccumulated: 0,
        bestDayValue: 0,
        bestDayDate: null,
        goalProgress: 0,
        goalMetToday: false,
        history: [],
        streak: StreakCalculator.compute({}),
        goalMetDates: {},
        loggedDates: {},
      );
    }
    final logs = await _repository.getLogs(habitId);
    return HabitReportCalculator.buildQuantitativeReport(
      habit: habit,
      logs: logs,
      goalMetDates: _completionDates(habit, logs),
    );
  }

  HabitWithToday _withToday(Habit habit, List<HabitLog> logs, String today) {
    final todayLog = logs.where((l) => l.date == today).firstOrNull;
    return HabitWithToday(
      habit: habit,
      completedToday: habit.isGoalMet(todayLog),
      todayValue: todayLog?.value,
      currentStreak:
          StreakCalculator.compute(_completionDates(habit, logs)).currentStreak,
    );
  }

  /// Registos anteriores à data de início não contam (decisão 7).
  Set<String> _completionDates(Habit habit, List<HabitLog> logs) {
    final startKey = HabitReportCalculator.startKeyOf(habit);
    return {
      for (final log in logs)
        if (log.date.compareTo(startKey) >= 0 && habit.isGoalMet(log))
          log.date,
    };
  }

  static Map<String, List<HabitLog>> _byHabit(List<HabitLog> logs) {
    final map = <String, List<HabitLog>>{};
    for (final log in logs) {
      map.putIfAbsent(log.habitId, () => []).add(log);
    }
    return map;
  }
}
