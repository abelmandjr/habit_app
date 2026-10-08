import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/models/habit_type.dart';

part 'habit.freezed.dart';

/// Hábito, tal como o resto da app o conhece (sem detalhes da BD).
@freezed
abstract class Habit with _$Habit {
  const factory Habit({
    required String id,
    required String title,
    @Default('') String description,
    required String category,
    required HabitType type,

    /// Unidade dos hábitos quantitativos (ex.: "L"); `null` nos sim/não.
    String? unit,

    /// Meta diária dos quantitativos; 1 nos sim/não.
    @Default(1) int goalValue,
    @Default(false) bool reminderEnabled,
    int? reminderHour,
    int? reminderMinute,

    /// Até à v5 (coluna `startDate`, tarefa 3.4), é também a data de início.
    required DateTime createdAt,
  }) = _Habit;
}
