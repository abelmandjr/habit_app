import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/models/habit_type.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/habit_report_calculator.dart';
import '../../../../core/utils/streak_calculator.dart';

class HabitWithToday {
  const HabitWithToday({
    required this.habit,
    required this.completedToday,
    this.todayValue,
    this.currentStreak = 0,
  });

  final HabitData habit;
  final bool completedToday;
  final double? todayValue;
  final int currentStreak;

  HabitType get type => HabitType.fromKey(habit.habitType);

  double get progressRatio {
    if (type == HabitType.quantitative && habit.goalValue > 0) {
      return ((todayValue ?? 0) / habit.goalValue).clamp(0.0, 1.0);
    }
    return completedToday ? 1.0 : 0.0;
  }
}

class HabitRepositoryImpl {
  final AppDatabase db;

  HabitRepositoryImpl(this.db);

  Future<List<HabitWithToday>> getHabitsWithTodayStatus() async {
    final habits = await db.getAllHabits();
    final today = HabitDateUtils.todayKey();

    final results = <HabitWithToday>[];
    for (final habit in habits) {
      final completed = await db.isCompletedOn(habit.id, today);
      final value = await db.getLoggedValue(habit.id, today);
      final streak = await db.getStreakStats(habit.id);
      results.add(
        HabitWithToday(
          habit: habit,
          completedToday: completed,
          todayValue: value,
          currentStreak: streak.currentStreak,
        ),
      );
    }
    return results;
  }

  Future<HabitData?> getHabitById(String id) => db.getHabitById(id);

  Future<Set<String>> getCompletionDates(String habitId) =>
      db.getCompletionDates(habitId);

  Future<StreakStats> getStreakStats(String habitId) =>
      db.getStreakStats(habitId);

  Future<void> createHabit({
    required String id,
    required String title,
    required String description,
    required String category,
    required HabitType habitType,
    required int goalValue,
    String? unit,
    bool reminderEnabled = false,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return db.insertHabit(
      HabitsCompanion.insert(
        id: id,
        title: title,
        description: Value(description),
        category: category,
        habitType: Value(habitType.storageKey),
        unit: Value(unit),
        goalValue: Value(goalValue),
        reminderEnabled: Value(reminderEnabled),
        reminderHour: Value(reminderHour),
        reminderMinute: Value(reminderMinute),
      ),
    );
  }

  Future<void> updateHabit(HabitData habit) => db.updateHabit(habit);

  Future<void> setYesNoToday(String habitId, bool completed) =>
      setYesNoForDate(habitId, HabitDateUtils.todayKey(), completed);

  Future<void> setQuantitativeToday(String habitId, double value) =>
      setQuantitativeForDate(habitId, HabitDateUtils.todayKey(), value);

  Future<void> setYesNoForDate(
    String habitId,
    String date,
    bool completed,
  ) =>
      db.setYesNoCompletion(habitId, date, completed);

  Future<void> setQuantitativeForDate(
    String habitId,
    String date,
    double value,
  ) =>
      db.setQuantitativeCompletion(habitId, date, value);

  Future<bool> isCompletedOnDate(String habitId, DateTime date) =>
      db.isCompletedOn(habitId, HabitDateUtils.dateKey(date));

  Future<double?> getValueForDate(String habitId, DateTime date) =>
      db.getLoggedValue(habitId, HabitDateUtils.dateKey(date));

  Future<void> toggleToday(String habitId) => db.toggleToday(habitId);

  Future<void> setCompletion(String habitId, String date, bool completed) =>
      setYesNoForDate(habitId, date, completed);

  Future<void> deleteHabit(String id) => db.deleteHabit(id);

  Future<GlobalStreakStats> getGlobalStreakStats() =>
      db.getGlobalStreakStats();

  Future<YesNoHabitReport> getYesNoReport(String habitId) async {
    final habit = await db.getHabitById(habitId);
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
    final dates = await db.getCompletionDates(habitId);
    return HabitReportCalculator.buildYesNoReport(
      habit: habit,
      completionDates: dates,
    );
  }

  Future<QuantitativeHabitReport> getQuantitativeReport(String habitId) async {
    final habit = await db.getHabitById(habitId);
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
      );
    }
    final completions = await db.getCompletionsForHabit(habitId);
    final goalMetDates = await db.getCompletionDates(habitId);
    return HabitReportCalculator.buildQuantitativeReport(
      habit: habit,
      completions: completions,
      goalMetDates: goalMetDates,
    );
  }
}
