import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/models/habit_type.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';

/// Conversões entre as classes geradas pelo Drift e as entidades do domínio.
/// Só a camada de dados as usa: o resto da app conhece apenas as entidades.
extension HabitDataToEntity on HabitData {
  Habit toEntity() => Habit(
        id: id,
        title: title,
        description: description,
        category: category,
        type: HabitType.fromKey(habitType),
        unit: unit,
        goalValue: goalValue,
        reminderEnabled: reminderEnabled,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
        createdAt: createdAt,
      );
}

extension HabitToData on Habit {
  /// Linha completa, para `update(...).replace`. A coluna legada
  /// `isCompleted` (removida na v5) fica sempre a `false`.
  HabitData toData() => HabitData(
        id: id,
        title: title,
        description: description,
        category: category,
        habitType: type.storageKey,
        unit: unit,
        goalValue: goalValue,
        isCompleted: false,
        reminderEnabled: reminderEnabled,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
        createdAt: createdAt,
      );

  /// Para inserir um hábito novo.
  HabitsCompanion toCompanion() => HabitsCompanion.insert(
        id: id,
        title: title,
        description: Value(description),
        category: category,
        habitType: Value(type.storageKey),
        unit: Value(unit),
        goalValue: Value(goalValue),
        reminderEnabled: Value(reminderEnabled),
        reminderHour: Value(reminderHour),
        reminderMinute: Value(reminderMinute),
        createdAt: Value(createdAt),
      );
}

extension HabitCompletionToEntity on HabitCompletion {
  HabitLog toEntity() =>
      HabitLog(habitId: habitId, date: date, value: loggedValue);
}

extension HabitLogToCompanion on HabitLog {
  HabitCompletionsCompanion toCompanion() => HabitCompletionsCompanion.insert(
        habitId: habitId,
        date: date,
        loggedValue: Value(value),
      );
}
