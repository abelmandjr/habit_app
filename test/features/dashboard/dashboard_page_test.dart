import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/core/database/app_database.dart';
import 'package:habit_app/core/notifications/notification_service.dart';
import 'package:habit_app/core/providers/database_provider.dart';
import 'package:habit_app/core/utils/date_utils.dart';
import 'package:habit_app/features/dashboard/presentation/pages/dashboard_page.dart';

import '../../helpers/fakes.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pumpDashboard(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(FakeNotifications()),
        ],
        child: const MaterialApp(home: DashboardPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> insertHabit(String id, String title) {
    return db.insertHabit(
      HabitsCompanion.insert(id: id, title: title, category: 'Geral'),
    );
  }

  testWidgets('sem hábitos mostra o estado vazio', (tester) async {
    await pumpDashboard(tester);

    expect(find.text('Nenhum hábito ainda'), findsOneWidget);
  });

  testWidgets('tocar num hábito sim/não marca-o como feito hoje', (
    tester,
  ) async {
    await insertHabit('h1', 'Meditar');
    await pumpDashboard(tester);

    await tester.tap(find.text('Meditar'));
    await tester.pumpAndSettle();

    final done = await db.isCompletedOn('h1', HabitDateUtils.todayKey());
    expect(done, isTrue);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('eliminar com swipe remove o hábito sem erros (tarefa 1.2)', (
    tester,
  ) async {
    await insertHabit('h1', 'Meditar');
    await pumpDashboard(tester);

    await tester.drag(find.byType(Dismissible), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Meditar'), findsNothing);
    expect(find.text('Nenhum hábito ainda'), findsOneWidget);
    expect(await db.getAllHabits(), isEmpty);
  });

  group('streak global (bug A6)', () {
    // O banner é um RichText: "N dia(s)  ·  melhor: M dia(s)".
    Finder banner(String text) => find.textContaining(text, findRichText: true);

    testWidgets('atualiza depois de marcar um hábito', (tester) async {
      await insertHabit('h1', 'Meditar');
      await pumpDashboard(tester);
      expect(banner('0 dias  ·  melhor: 0 dias'), findsOneWidget);

      await tester.tap(find.text('Meditar'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(banner('1 dia  ·  melhor: 1 dia'), findsOneWidget);
    });

    testWidgets('atualiza depois de eliminar um hábito', (tester) async {
      await insertHabit('h1', 'Meditar');
      await db.setYesNoCompletion('h1', HabitDateUtils.todayKey(), true);
      await pumpDashboard(tester);
      expect(banner('1 dia  ·  melhor: 1 dia'), findsOneWidget);

      await tester.drag(find.byType(Dismissible), const Offset(-600, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(banner('0 dias  ·  melhor: 0 dias'), findsOneWidget);
    });
  });
}
