import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/core/database/app_database.dart';
import 'package:habit_app/core/notifications/notification_service.dart';
import 'package:habit_app/core/providers/database_provider.dart';
import 'package:habit_app/core/utils/date_utils.dart';
import 'package:habit_app/main.dart';

import 'helpers/fakes.dart';

/// Tarefa 1.8: quando muda o dia (com a app aberta ou ao voltar a ela), a
/// lista "Hoje" passa para o novo dia.
///
/// Nos testes de widget, `clock.now()` avança com `tester.pump(duração)`.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Hábito feito "hoje" e a app aberta no dashboard.
  Future<void> openWithHabitDoneToday(WidgetTester tester) async {
    await db.insertHabit(
      HabitsCompanion.insert(
        id: 'h1',
        title: 'Meditar',
        category: 'Geral',
        createdAt: Value(clock.now().subtract(const Duration(days: 30))),
      ),
    );
    await db.setYesNoCompletion('h1', HabitDateUtils.todayKey(), true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(FakeNotifications()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  }

  Future<void> setLifecycle(
    WidgetTester tester,
    List<AppLifecycleState> states,
  ) async {
    for (final state in states) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
  }

  Duration pastMidnight() =>
      HabitDateUtils.untilNextDay(clock.now()) + const Duration(seconds: 5);

  testWidgets('à meia-noite, com a app aberta, passa para o novo dia', (
    tester,
  ) async {
    await openWithHabitDoneToday(tester);

    await tester.pump(pastMidnight());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('ao voltar à app noutro dia, passa para o novo dia', (
    tester,
  ) async {
    await openWithHabitDoneToday(tester);

    // A app vai para segundo plano: o temporizador da meia-noite é cancelado.
    await setLifecycle(tester, [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]);
    await tester.pump(pastMidnight());
    expect(find.byIcon(Icons.check_rounded), findsOneWidget,
        reason: 'em segundo plano não recarrega');

    // Volta à app.
    await setLifecycle(tester, [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]);

    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  test('untilNextDay conta até à meia-noite local seguinte', () {
    expect(
      HabitDateUtils.untilNextDay(DateTime(2026, 6, 15, 23, 59, 30)),
      const Duration(seconds: 30),
    );
    expect(
      HabitDateUtils.untilNextDay(DateTime(2026, 12, 31, 18)),
      const Duration(hours: 6),
    );
  });
}
