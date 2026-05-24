import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/habit_type.dart';
import '../utils/date_utils.dart';
import '../utils/streak_calculator.dart';

part 'app_database.g.dart';

@DataClassName('HabitData')
class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get category => text()();
  TextColumn get habitType =>
      text().withDefault(const Constant('yesNo'))();
  TextColumn get unit => text().nullable()();
  IntColumn get goalValue => integer().withDefault(const Constant(1))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get reminderHour => integer().nullable()();
  IntColumn get reminderMinute => integer().nullable()();
  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class HabitCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get habitId => text().references(Habits, #id, onDelete: KeyAction.cascade)();
  TextColumn get date => text()();
  RealColumn get loggedValue => real().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {habitId, date},
      ];
}

/// Configurações da app (nome do utilizador, categorias personalizadas, etc.)
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Habits, HabitCompletions, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'habits'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(habitCompletions);
            await m.addColumn(habits, habits.description);
            await m.addColumn(habits, habits.reminderHour);
            await m.addColumn(habits, habits.reminderMinute);
            await m.addColumn(habits, habits.reminderEnabled);
            await m.addColumn(habits, habits.createdAt);

            final legacy = await select(habits).get();
            final today = HabitDateUtils.todayKey();
            for (final habit in legacy) {
              if (habit.isCompleted) {
                await into(habitCompletions).insert(
                  HabitCompletionsCompanion.insert(
                    habitId: habit.id,
                    date: today,
                  ),
                  mode: InsertMode.insertOrIgnore,
                );
              }
            }
          }
          if (from < 3) {
            await m.addColumn(habits, habits.habitType);
            await m.addColumn(habits, habits.unit);
            await m.addColumn(habitCompletions, habitCompletions.loggedValue);
          }
          if (from < 4) {
            await m.createTable(appSettings);
          }
        },
      );

  static const _userNameKey = 'user_name';
  static const _customCategoriesKey = 'custom_categories';

  Future<String?> _getSetting(String key) async {
    final row = await (select(appSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> _setSetting(String key, String value) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(key: key, value: value),
    );
  }

  Future<String> getUserName() async => await _getSetting(_userNameKey) ?? '';

  Future<void> setUserName(String name) =>
      _setSetting(_userNameKey, name);

  Future<List<String>> getCustomCategories() async {
    final raw = await _getSetting(_customCategoriesKey);
    if (raw == null || raw.isEmpty) return [];
    return raw.split('\n').where((c) => c.isNotEmpty).toList();
  }

  Future<void> setCustomCategories(List<String> categories) async {
    await _setSetting(_customCategoriesKey, categories.join('\n'));
  }

  Future<List<HabitData>> getAllHabits() => select(habits).get();

  Future<HabitData?> getHabitById(String id) =>
      (select(habits)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertHabit(HabitsCompanion habit) =>
      into(habits).insert(habit);

  Future<void> updateHabit(HabitData habit) =>
      update(habits).replace(habit);

  Future<void> deleteHabit(String id) async {
    await (delete(habitCompletions)..where((t) => t.habitId.equals(id))).go();
    await (delete(habits)..where((t) => t.id.equals(id))).go();
  }

  Future<HabitCompletion?> _completionRow(String habitId, String date) =>
      (select(habitCompletions)
            ..where((t) => t.habitId.equals(habitId) & t.date.equals(date)))
          .getSingleOrNull();

  Future<bool> isGoalMet(HabitData habit, HabitCompletion? row) async {
    if (row == null) return false;
    final type = HabitType.fromKey(habit.habitType);
    if (type == HabitType.yesNo) return true;
    return (row.loggedValue ?? 0) >= habit.goalValue;
  }

  Future<bool> isCompletedOn(String habitId, String date) async {
    final habit = await getHabitById(habitId);
    if (habit == null) return false;
    final row = await _completionRow(habitId, date);
    return isGoalMet(habit, row);
  }

  Future<double?> getLoggedValue(String habitId, String date) async {
    final row = await _completionRow(habitId, date);
    return row?.loggedValue;
  }

  Future<void> setYesNoCompletion(
    String habitId,
    String date,
    bool completed,
  ) async {
    if (completed) {
      await into(habitCompletions).insertOnConflictUpdate(
        HabitCompletionsCompanion.insert(
          habitId: habitId,
          date: date,
          loggedValue: const Value(1),
        ),
      );
    } else {
      await (delete(habitCompletions)
            ..where((t) => t.habitId.equals(habitId) & t.date.equals(date)))
          .go();
    }
  }

  Future<void> setQuantitativeCompletion(
    String habitId,
    String date,
    double value,
  ) async {
    if (value <= 0) {
      await (delete(habitCompletions)
            ..where((t) => t.habitId.equals(habitId) & t.date.equals(date)))
          .go();
      return;
    }

    await into(habitCompletions).insertOnConflictUpdate(
      HabitCompletionsCompanion.insert(
        habitId: habitId,
        date: date,
        loggedValue: Value(value),
      ),
    );
  }

  Future<void> toggleToday(String habitId) async {
    final today = HabitDateUtils.todayKey();
    final done = await isCompletedOn(habitId, today);
    await setYesNoCompletion(habitId, today, !done);
  }

  Future<Set<String>> getCompletionDates(String habitId) async {
    final habit = await getHabitById(habitId);
    if (habit == null) return {};

    final rows = await (select(habitCompletions)
          ..where((t) => t.habitId.equals(habitId)))
        .get();

    final dates = <String>{};
    for (final row in rows) {
      if (await isGoalMet(habit, row)) {
        dates.add(row.date);
      }
    }
    return dates;
  }

  Future<StreakStats> getStreakStats(String habitId) async {
    final dates = await getCompletionDates(habitId);
    return StreakCalculator.compute(dates);
  }
}
