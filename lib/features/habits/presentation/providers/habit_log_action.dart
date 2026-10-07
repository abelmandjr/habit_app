// Ações do utilizador traduzidas em registos, para as atualizações otimistas.
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';

/// O registo que uma ação do utilizador deixa no dia [date]: marcar sim cria
/// um registo, marcar não apaga-o, e um valor ≤ 0 também o apaga.
HabitLog? logForAction(
  Habit habit,
  String date, {
  bool? yesNo,
  double? quantity,
}) {
  if (yesNo != null) {
    return yesNo ? HabitLog(habitId: habit.id, date: date, value: 1) : null;
  }
  if (quantity != null && quantity > 0) {
    return HabitLog(habitId: habit.id, date: date, value: quantity);
  }
  return null;
}
