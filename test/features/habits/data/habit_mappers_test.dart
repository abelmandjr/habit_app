import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/core/database/app_database.dart';
import 'package:habit_app/core/models/habit_type.dart';
import 'package:habit_app/features/habits/data/mappers/habit_mappers.dart';
import 'package:habit_app/features/habits/domain/entities/habit.dart';
import 'package:habit_app/features/habits/domain/entities/habit_log.dart';

/// Tarefa 2.1a: conversões entre as classes do Drift e as entidades.
void main() {
  final quantitative = Habit(
    id: 'agua',
    title: 'Beber água',
    description: 'Ao longo do dia',
    category: 'Saúde',
    type: HabitType.quantitative,
    unit: 'L',
    goalValue: 2,
    reminderEnabled: true,
    reminderHour: 9,
    reminderMinute: 30,
    createdAt: DateTime(2026, 6, 1, 8, 15),
  );

  group('Habit', () {
    test('Habit → HabitData → Habit não perde nada', () {
      expect(quantitative.toData().toEntity(), quantitative);
    });

    test('HabitData → Habit converte o tipo e ignora o isCompleted legado', () {
      final data = HabitData(
        id: 'h1',
        title: 'Meditar',
        description: '',
        category: 'Geral',
        habitType: 'yesNo',
        goalValue: 1,
        isCompleted: true,
        reminderEnabled: false,
        createdAt: DateTime(2026, 6, 1),
      );

      final habit = data.toEntity();
      expect(habit.type, HabitType.yesNo);
      expect(habit.unit, isNull);
      expect(habit.toData().isCompleted, isFalse);
    });

    test('tipo desconhecido na BD passa a sim/não', () {
      final data = quantitative.toData().copyWith(habitType: 'outro');
      expect(data.toEntity().type, HabitType.yesNo);
    });

    test('igualdade por valor e copyWith (freezed)', () {
      final copy = quantitative.copyWith(title: 'Água');
      expect(copy, isNot(quantitative));
      expect(copy.copyWith(title: 'Beber água'), quantitative);
    });

    test('toCompanion insere na BD e volta igual', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await db.insertHabit(quantitative.toCompanion());

      final stored = await db.getHabitById('agua');
      expect(stored!.toEntity(), quantitative);
    });
  });

  group('HabitLog', () {
    test('toCompanion e toEntity fazem o caminho de ida e volta pela BD', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.insertHabit(quantitative.toCompanion());

      const log = HabitLog(habitId: 'agua', date: '2026-06-15', value: 1.5);
      await db.into(db.habitCompletions).insert(log.toCompanion());

      final rows = await db.getCompletionsForHabit('agua');
      expect(rows.single.toEntity(), log);
    });

    test('valor nulo mantém-se nulo', () {
      final row = HabitCompletion(
        id: 7,
        habitId: 'h1',
        date: '2026-06-15',
      );
      expect(row.toEntity(), const HabitLog(habitId: 'h1', date: '2026-06-15'));
    });
  });
}
