import '../../../../core/models/habit_type.dart';
import '../entities/habit.dart';

/// Um hábito com o estado de hoje, para a lista "Hoje".
class HabitWithToday {
  const HabitWithToday({
    required this.habit,
    required this.completedToday,
    this.todayValue,
    this.currentStreak = 0,
  });

  final Habit habit;
  final bool completedToday;
  final double? todayValue;
  final int currentStreak;

  HabitType get type => habit.type;

  double get progressRatio {
    if (type == HabitType.quantitative && habit.goalValue > 0) {
      return ((todayValue ?? 0) / habit.goalValue).clamp(0.0, 1.0);
    }
    return completedToday ? 1.0 : 0.0;
  }
}
