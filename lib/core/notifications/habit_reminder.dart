/// O que o [NotificationService] precisa de saber para agendar o lembrete
/// diário de um hábito. Fica em `core/` para o serviço não depender das
/// entidades da funcionalidade de hábitos.
class HabitReminder {
  const HabitReminder({
    required this.habitId,
    required this.title,
    required this.enabled,
    this.hour,
    this.minute,
  });

  final String habitId;

  /// Texto da notificação (o título do hábito).
  final String title;
  final bool enabled;
  final int? hour;
  final int? minute;
}
