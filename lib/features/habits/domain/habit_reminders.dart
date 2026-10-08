import '../../../core/notifications/habit_reminder.dart';
import 'entities/habit.dart';

/// Lembrete diário de um hábito, no formato do NotificationService.
extension HabitToReminder on Habit {
  HabitReminder get reminder => HabitReminder(
        habitId: id,
        title: title,
        enabled: reminderEnabled,
        hour: reminderHour,
        minute: reminderMinute,
      );
}
