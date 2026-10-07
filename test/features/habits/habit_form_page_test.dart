import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/core/database/app_database.dart';
import 'package:habit_app/core/notifications/notification_service.dart';
import 'package:habit_app/core/providers/database_provider.dart';
import 'package:habit_app/features/habits/presentation/pages/habit_form_page.dart';

import '../../helpers/fakes.dart';

/// Tarefa 1.10: a permissão de notificações só é pedida ao ligar um lembrete.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> openReminderSwitch(
    WidgetTester tester,
    FakeNotifications notifications,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(notifications),
        ],
        child: const MaterialApp(home: HabitFormPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sim ou não'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Lembrete diário'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }

  SwitchListTile reminderSwitch(WidgetTester tester) => tester.widget(
        find.widgetWithText(SwitchListTile, 'Lembrete diário'),
      );

  testWidgets('não pede permissão só por abrir o formulário', (tester) async {
    final notifications = FakeNotifications();
    await openReminderSwitch(tester, notifications);

    expect(notifications.permissionRequests, 0);
  });

  testWidgets('ligar o lembrete pede permissão e, se concedida, liga-o', (
    tester,
  ) async {
    final notifications = FakeNotifications();
    await openReminderSwitch(tester, notifications);

    await tester.tap(find.text('Lembrete diário'));
    await tester.pumpAndSettle();

    expect(notifications.permissionRequests, 1);
    expect(reminderSwitch(tester).value, isTrue);
    expect(find.text('09:00'), findsOneWidget);
  });

  group('alarmes exatos ("Alarmes e lembretes")', () {
    const warning = 'Os lembretes podem chegar atrasados';

    testWidgets('já permitidos: não mostra diálogo nem aviso', (tester) async {
      final notifications = FakeNotifications();
      await openReminderSwitch(tester, notifications);

      await tester.tap(find.text('Lembrete diário'));
      await tester.pumpAndSettle();

      expect(find.text('Lembretes à hora certa'), findsNothing);
      expect(find.textContaining(warning), findsNothing);
    });

    testWidgets('explica e abre as definições; se concedidos, sem aviso', (
      tester,
    ) async {
      final notifications = FakeNotifications(
        exactAlarmsAllowed: false,
        exactAlarmsAllowedAfterSettings: true,
      );
      await openReminderSwitch(tester, notifications);

      await tester.tap(find.text('Lembrete diário'));
      await tester.pumpAndSettle();
      expect(find.text('Lembretes à hora certa'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Abrir definições'));
      await tester.pumpAndSettle();

      expect(notifications.exactAlarmSettingsOpened, 1);
      expect(reminderSwitch(tester).value, isTrue);
      expect(find.textContaining(warning), findsNothing);
    });

    testWidgets('se recusados: lembrete inexato com aviso e botão', (
      tester,
    ) async {
      final notifications = FakeNotifications(exactAlarmsAllowed: false);
      await openReminderSwitch(tester, notifications);

      await tester.tap(find.text('Lembrete diário'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agora não'));
      await tester.pumpAndSettle();

      expect(notifications.exactAlarmSettingsOpened, 0);
      expect(reminderSwitch(tester).value, isTrue);
      expect(find.textContaining(warning), findsOneWidget);

      // O botão do aviso abre as definições; quando a permissão é dada, o
      // aviso desaparece.
      notifications.exactAlarmsAllowed = true;
      final openSettings = find.widgetWithText(TextButton, 'Abrir definições');
      await tester.ensureVisible(openSettings);
      await tester.pumpAndSettle();
      await tester.tap(openSettings);
      await tester.pumpAndSettle();

      expect(notifications.exactAlarmSettingsOpened, 1);
      expect(find.textContaining(warning), findsNothing);
    });
  });

  testWidgets('se a permissão for recusada, o lembrete fica desligado', (
    tester,
  ) async {
    final notifications = FakeNotifications(permissionGranted: false);
    await openReminderSwitch(tester, notifications);

    await tester.tap(find.text('Lembrete diário'));
    await tester.pumpAndSettle();

    expect(notifications.permissionRequests, 1);
    expect(reminderSwitch(tester).value, isFalse);
    expect(find.textContaining('Sem permissão para notificações'), findsOneWidget);
  });
}
