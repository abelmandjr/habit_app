import '../entities/habit.dart';
import '../entities/habit_log.dart';

/// Acesso aos hábitos e aos seus registos, independente da origem dos dados.
///
/// A implementação atual usa o Drift (BD local); na Fase 4 junta-se uma fonte
/// remota sem que o resto da app mude.
abstract interface class HabitRepository {
  Future<List<Habit>> getHabits();

  /// Emite a lista sempre que os hábitos mudam.
  Stream<List<Habit>> watchHabits();

  Stream<Habit?> watchHabit(String id);

  Future<Habit?> getHabit(String id);

  Future<void> createHabit(Habit habit);

  Future<void> updateHabit(Habit habit);

  /// Apaga o hábito e todos os seus registos.
  Future<void> deleteHabit(String id);

  Future<List<HabitLog>> getLogs(String habitId);

  Future<List<HabitLog>> getAllLogs();

  /// Emite os registos sempre que mudam.
  Stream<List<HabitLog>> watchAllLogs();

  Stream<List<HabitLog>> watchLogs(String habitId);

  /// Registo de [habitId] no dia [date] (`YYYY-MM-DD`), se existir.
  Future<HabitLog?> getLog(String habitId, String date);

  /// Hábito sim/não: marca ([done] = true) ou apaga o registo do dia.
  Future<void> setYesNo(String habitId, String date, bool done);

  /// Hábito quantitativo: grava [value] no dia; um valor ≤ 0 apaga o registo.
  Future<void> setQuantity(String habitId, String date, double value);
}
