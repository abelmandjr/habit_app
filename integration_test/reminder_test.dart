import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/core/notifications/notification_service.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/timezone.dart' as tz;

/// Tarefa 1.1 no dispositivo: um lembrete agendado para HH:MM locais chega à
/// hora local certa. Imprime marcadores `IT_REMINDER` para cruzar com
/// `adb shell dumpsys alarm` e `adb shell dumpsys notification`.
///
/// Usa o NotificationService real; o lembrete é cancelado no fim.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'lembrete chega à hora local certa',
    (tester) async {
      final service = NotificationService.instance;
      await service.initialize();

      final now = DateTime.now();
      final target = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
      ).add(const Duration(minutes: 2));

      final reminder = HabitReminder(
        habitId: 'integration-test-reminder',
        title: 'Teste de lembrete',
        enabled: true,
        hour: target.hour,
        minute: target.minute,
      );
      final id = service.notificationIdForHabit(reminder.habitId);
      final android = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()!;

      try {
        final exact = await service.canScheduleExactAlarms();
        await service.syncHabitReminder(reminder);

        // ignore: avoid_print
        print('IT_REMINDER scheduled id=$id tz=${tz.local.name} '
            'exact=$exact now=$now target=$target');

        final pending = await FlutterLocalNotificationsPlugin()
            .pendingNotificationRequests();
        expect(pending.map((p) => p.id), contains(id));

        // Exato: chega à hora. Inexato: o Android pode atrasar até 75 % do
        // tempo que faltava quando foi agendado (ver ANALISE_PROJETO.md §9).
        final maxDelay = exact
            ? const Duration(seconds: 15)
            : target.difference(now) * 0.75 + const Duration(seconds: 20);
        final deadline = target.add(maxDelay);
        DateTime? arrivedAt;
        while (DateTime.now().isBefore(deadline)) {
          final active = await android.getActiveNotifications();
          if (active.any((n) => n.id == id)) {
            arrivedAt = DateTime.now();
            break;
          }
          await Future<void>.delayed(const Duration(seconds: 5));
        }

        // ignore: avoid_print
        print('IT_REMINDER arrived=$arrivedAt target=$target '
            'delay=${arrivedAt?.difference(target).inSeconds}s');
        expect(arrivedAt, isNotNull, reason: 'A notificação não apareceu');
        expect(arrivedAt!.isBefore(target), isFalse);
        expect(arrivedAt.difference(target), lessThan(maxDelay));

        // Deixa a notificação visível 20 s para o dumpsys notification.
        await Future<void>.delayed(const Duration(seconds: 20));
      } finally {
        await service.cancelHabitReminder(reminder.habitId);
      }
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
