import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:habit_app/core/database/app_database.dart';
import 'package:habit_app/core/models/habit_type.dart';
import 'package:habit_app/features/habits/data/repositories/drift_habit_repository.dart';
import 'package:habit_app/features/habits/domain/entities/habit.dart';
import 'package:habit_app/features/habits/domain/entities/habit_log.dart';
import 'package:habit_app/features/habits/domain/services/habit_queries.dart';

/// "Hoje" em todos os testes: segunda-feira, 15 de junho de 2026, 10:00.
/// Longe de mudanças de hora, para os resultados não dependerem do fuso.
/// BD em memória para testes. Fecha os streams de imediato quando deixam de
/// ser ouvidos: por omissão o Drift adia-o com um Timer, que fica pendente no
/// fim de um testWidgets (tarefa 2.2).
AppDatabase memoryDatabase() => AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );

final testNow = DateTime(2026, 6, 15, 10);

T atTestNow<T>(T Function() body) => withClock(Clock.fixed(testNow), body);

Habit makeHabit({
  String id = 'h1',
  String title = 'Meditar',
  HabitType type = HabitType.yesNo,
  int goalValue = 1,
  String? unit,
  DateTime? createdAt,
}) {
  return Habit(
    id: id,
    title: title,
    category: 'Geral',
    type: type,
    unit: unit,
    goalValue: goalValue,
    createdAt: createdAt ?? DateTime(2026, 6, 1),
  );
}

HabitLog makeLog(String habitId, String date, [double? value = 1]) =>
    HabitLog(habitId: habitId, date: date, value: value);

/// Consultas sobre uma BD de teste, para verificar o que ficou gravado.
HabitQueries queriesFor(AppDatabase db) =>
    HabitQueries(DriftHabitRepository(db));
