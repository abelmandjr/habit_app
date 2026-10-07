import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/core/database/app_database.dart';
import 'package:habit_app/core/notifications/notification_service.dart';
import 'package:habit_app/core/providers/database_provider.dart';
import 'package:habit_app/main.dart';
import 'package:integration_test/integration_test.dart';

/// Tarefa 1.10 no dispositivo: com "Alarmes e lembretes" recusado, o lembrete
/// fica inexato; quando a permissão é dada e a app volta ao primeiro plano,
/// os lembretes são reagendados em modo exato.
///
/// É orquestrado por fora, com adb (ver ANALISE_PROJETO.md §9):
///   1. antes: `appops set com.example.habit_app.debug SCHEDULE_EXACT_ALARM deny`
///   2. com `IT_RESUME ready`: `dumpsys alarm` (inexato), `appops ... allow`,
///      tecla HOME e `am start` (volta à app), `dumpsys alarm` (exato)
/// O teste espera até a permissão estar concedida e a app ter voltado.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'reagenda em modo exato quando a permissão é dada',
    (tester) async {
      final service = NotificationService.instance;
      await service.initialize();
      expect(
        await service.canScheduleExactAlarms(),
        isFalse,
        reason: 'Correr antes: appops set … SCHEDULE_EXACT_ALARM deny',
      );

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final target = DateTime.now().add(const Duration(minutes: 30));
      await db.insertHabit(
        HabitsCompanion.insert(
          id: 'integration-test-resume',
          title: 'Teste de alarme exato',
          category: 'Geral',
          reminderEnabled: const Value(true),
          reminderHour: Value(target.hour),
          reminderMinute: Value(target.minute),
        ),
      );

      // A app agenda os lembretes ao carregar a lista (modo inexato).
      await tester.pumpWidget(
        ProviderScope(
          overrides: [dbProvider.overrideWithValue(db)],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Regista os estados de ciclo de vida recebidos, para diagnóstico.
      final states = <AppLifecycleState>[];
      final lifecycle = AppLifecycleListener(onStateChange: states.add);
      addTearDown(lifecycle.dispose);

      try {
        // ignore: avoid_print
        print('IT_RESUME ready target=${target.hour}:${target.minute}');

        // Espera (até 4 min) que a permissão seja dada por fora.
        final deadline = DateTime.now().add(const Duration(minutes: 4));
        while (!await service.canScheduleExactAlarms()) {
          expect(DateTime.now().isBefore(deadline), isTrue,
              reason: 'A permissão não foi concedida a tempo');
          await Future<void>.delayed(const Duration(seconds: 2));
        }
        // ignore: avoid_print
        print('IT_RESUME permission granted');

        // Ao voltar à app, o MyApp deteta a mudança e reagenda em modo exato.
        final returnDeadline = DateTime.now().add(const Duration(seconds: 90));
        while (service.lastKnownExactAlarmsAllowed != true &&
            DateTime.now().isBefore(returnDeadline)) {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
        // ignore: avoid_print
        print('IT_RESUME done rescheduled='
            '${service.lastKnownExactAlarmsAllowed} '
            'lifecycle=${states.map((s) => s.name).join(',')}');
        expect(service.lastKnownExactAlarmsAllowed, isTrue,
            reason: 'A app não reagendou ao voltar ao primeiro plano');

        // Tempo para o dumpsys alarm confirmar o modo exato.
        await Future<void>.delayed(const Duration(seconds: 15));
      } finally {
        await service.cancelHabitReminder('integration-test-resume');
      }
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
