import 'package:clock/clock.dart';
import 'package:habit_app/core/database/app_database.dart';

/// "Hoje" em todos os testes: segunda-feira, 15 de junho de 2026, 10:00.
/// Longe de mudanças de hora, para os resultados não dependerem do fuso.
final testNow = DateTime(2026, 6, 15, 10);

T atTestNow<T>(T Function() body) => withClock(Clock.fixed(testNow), body);

HabitData makeHabit({
  String id = 'h1',
  String title = 'Meditar',
  String habitType = 'yesNo',
  int goalValue = 1,
  String? unit,
  DateTime? createdAt,
}) {
  return HabitData(
    id: id,
    title: title,
    description: '',
    category: 'Geral',
    habitType: habitType,
    unit: unit,
    goalValue: goalValue,
    isCompleted: false,
    reminderEnabled: false,
    createdAt: createdAt ?? DateTime(2026, 6, 1),
  );
}

var _nextCompletionId = 1;

HabitCompletion makeCompletion(
  String habitId,
  String date, [
  double? value = 1,
]) {
  return HabitCompletion(
    id: _nextCompletionId++,
    habitId: habitId,
    date: date,
    loggedValue: value,
  );
}
