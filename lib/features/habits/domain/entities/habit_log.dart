import 'package:freezed_annotation/freezed_annotation.dart';

part 'habit_log.freezed.dart';

/// Registo de um hábito num dia. Há no máximo um por hábito e dia.
@freezed
abstract class HabitLog with _$HabitLog {
  const factory HabitLog({
    required String habitId,

    /// Dia de calendário, `YYYY-MM-DD`.
    required String date,

    /// 1 nos sim/não; o valor registado nos quantitativos.
    double? value,
  }) = _HabitLog;
}
