import '../../../../core/database/app_database.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';
import '../../domain/repositories/habit_repository.dart';
import '../mappers/habit_mappers.dart';

/// [HabitRepository] sobre a BD local (Drift).
class DriftHabitRepository implements HabitRepository {
  DriftHabitRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Habit>> getHabits() async =>
      [for (final row in await _db.getAllHabits()) row.toEntity()];

  @override
  Stream<List<Habit>> watchHabits() => _db.watchAllHabits().map(
        (rows) => [for (final row in rows) row.toEntity()],
      );

  @override
  Stream<Habit?> watchHabit(String id) =>
      _db.watchHabitById(id).map((row) => row?.toEntity());

  @override
  Future<Habit?> getHabit(String id) async =>
      (await _db.getHabitById(id))?.toEntity();

  @override
  Future<void> createHabit(Habit habit) => _db.insertHabit(habit.toCompanion());

  @override
  Future<void> updateHabit(Habit habit) => _db.updateHabit(habit.toData());

  @override
  Future<void> deleteHabit(String id) => _db.deleteHabit(id);

  @override
  Future<List<HabitLog>> getLogs(String habitId) async => [
        for (final row in await _db.getCompletionsForHabit(habitId))
          row.toEntity(),
      ];

  @override
  Future<List<HabitLog>> getAllLogs() async =>
      [for (final row in await _db.getAllCompletions()) row.toEntity()];

  @override
  Stream<List<HabitLog>> watchAllLogs() => _db.watchAllCompletions().map(
        (rows) => [for (final row in rows) row.toEntity()],
      );

  @override
  Stream<List<HabitLog>> watchLogs(String habitId) =>
      _db.watchCompletionsForHabit(habitId).map(
            (rows) => [for (final row in rows) row.toEntity()],
          );

  @override
  Future<HabitLog?> getLog(String habitId, String date) async =>
      (await _db.getCompletion(habitId, date))?.toEntity();

  @override
  Future<void> setYesNo(String habitId, String date, bool done) =>
      _db.setYesNoCompletion(habitId, date, done);

  @override
  Future<void> setQuantity(String habitId, String date, double value) =>
      _db.setQuantitativeCompletion(habitId, date, value);
}
