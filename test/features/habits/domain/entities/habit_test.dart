import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/core/models/habit_type.dart';
import 'package:habit_app/features/habits/domain/entities/habit_log.dart';

import '../../../../helpers/fixtures.dart';

/// Tarefa 2.1c: uma só regra de "meta cumprida" (bug M8).
void main() {
  HabitLog log([double? value]) =>
      HabitLog(habitId: 'h1', date: '2026-06-15', value: value);

  group('Habit.isGoalMet', () {
    test('sem registo, nunca cumpre', () {
      expect(makeHabit().isGoalMet(null), isFalse);
      expect(
        makeHabit(type: HabitType.quantitative, goalValue: 2).isGoalMet(null),
        isFalse,
      );
    });

    test('sim/não: qualquer registo cumpre (incluindo o valor nulo antigo)', () {
      final habit = makeHabit();
      expect(habit.isGoalMet(log(1)), isTrue);
      expect(habit.isGoalMet(log()), isTrue);
    });

    test('quantitativo: cumpre a partir da meta, inclusive', () {
      final habit = makeHabit(type: HabitType.quantitative, goalValue: 2);
      expect(habit.isGoalMet(log(1.5)), isFalse);
      expect(habit.isGoalMet(log(2)), isTrue);
      expect(habit.isGoalMet(log(3.25)), isTrue);
      expect(habit.isGoalMet(log()), isFalse, reason: 'valor nulo conta como 0');
    });
  });

  test('a regra só existe na entidade (guarda contra novas cópias)', () {
    // Comparações "meta cumprida" com goalValue fora de habit.dart indicam uma
    // nova cópia da regra. O progressRatio (barra de progresso) é uma divisão,
    // não uma comparação, e não é apanhado.
    final copy = RegExp(r'>=\s*[\w.!?]*goalValue|goalValue\s*<=');
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final path = file.path.replaceAll(r'\', '/');
      if (path.endsWith('domain/entities/habit.dart') ||
          path.endsWith('.freezed.dart') ||
          path.endsWith('.g.dart')) {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (copy.hasMatch(lines[i])) offenders.add('$path:${i + 1}');
      }
    }
    expect(offenders, isEmpty, reason: 'usar Habit.isGoalMet');
  });
}
