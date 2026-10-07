import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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
  /// [executor] permite usar uma BD em memória nos testes.
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'habits'));

  @override
  int get schemaVersion => 4;

  /// A v4 é a base do schema: a app nunca foi distribuída (decisão 11).
  /// As migrações seguintes (v5, …) são incrementais e testadas (tarefa 3.1).
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 4) {
            // Versões anteriores à base só existem em dispositivos de
            // desenvolvimento: recria tudo em vez de migrar os dados.
            for (final table in allTables.toList().reversed) {
              await m.deleteTable(table.actualTableName);
            }
            await m.createAll();
          }
        },
        beforeOpen: (details) async {
          // Sem isto, o SQLite ignora as chaves estrangeiras (e o
          // ON DELETE CASCADE de habit_completions).
          await customStatement('PRAGMA foreign_keys = ON');
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

  Future<List<HabitCompletion>> getCompletionsForHabit(String habitId) =>
      (select(habitCompletions)..where((t) => t.habitId.equals(habitId))).get();

  Future<List<HabitCompletion>> getAllCompletions() =>
      select(habitCompletions).get();

  /// Registo de [habitId] no dia [date]. Se houver duplicados (de versões
  /// antigas), fica o mais recente e os restantes são apagados.
  Future<HabitCompletion?> getCompletion(String habitId, String date) async {
    final rows = await (select(habitCompletions)
          ..where((t) => t.habitId.equals(habitId) & t.date.equals(date)))
        .get();

    if (rows.isEmpty) return null;
    if (rows.length == 1) return rows.first;

    rows.sort((a, b) => b.id.compareTo(a.id));
    final keep = rows.first;
    for (var i = 1; i < rows.length; i++) {
      await (delete(habitCompletions)..where((t) => t.id.equals(rows[i].id))).go();
    }
    return keep;
  }

  Future<void> _upsertCompletion({
    required String habitId,
    required String date,
    required Value<double?> loggedValue,
  }) async {
    final existing = await getCompletion(habitId, date);
    if (existing != null) {
      await (update(habitCompletions)
            ..where(
              (t) => t.habitId.equals(habitId) & t.date.equals(date),
            ))
          .write(HabitCompletionsCompanion(loggedValue: loggedValue));
    } else {
      await into(habitCompletions).insert(
        HabitCompletionsCompanion.insert(
          habitId: habitId,
          date: date,
          loggedValue: loggedValue,
        ),
      );
    }
  }

  Future<void> setYesNoCompletion(
    String habitId,
    String date,
    bool completed,
  ) async {
    if (completed) {
      await _upsertCompletion(
        habitId: habitId,
        date: date,
        loggedValue: const Value(1),
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

    await _upsertCompletion(
      habitId: habitId,
      date: date,
      loggedValue: Value(value),
    );
  }
}
