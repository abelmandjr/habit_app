import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/core/database/app_database.dart';
import 'package:habit_app/core/notifications/notification_service.dart';
import 'package:habit_app/core/providers/database_provider.dart';
import 'package:habit_app/core/utils/date_utils.dart';
import 'package:habit_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:habit_app/features/habits/presentation/pages/habit_detail_page.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';
import '../../helpers/fixtures.dart';

/// Tarefa 2.2: os ecrãs reagem a alterações na BD feitas fora deles (como
/// fará a sincronização na Fase 4), sem recarregar à mão.
void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  Future<void> show(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(FakeNotifications()),
        ],
        child: testApp(page),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> insertHabit(String id, String title) => db.insertHabit(
    HabitsCompanion.insert(id: id, title: title, category: 'Geral'),
  );

  testWidgets('a lista mostra um hábito criado diretamente na BD', (
    tester,
  ) async {
    await show(tester, const DashboardPage());
    expect(find.text(testL10n.emptyTitle), findsOneWidget);

    await tester.runAsync(() => insertHabit('h1', 'Ler'));
    await tester.pumpAndSettle();

    expect(find.text('Ler'), findsOneWidget);
  });

  testWidgets('a lista reflete um registo gravado diretamente na BD', (
    tester,
  ) async {
    await insertHabit('h1', 'Ler');
    await show(tester, const DashboardPage());
    expect(find.byIcon(Icons.check_rounded), findsNothing);

    await tester.runAsync(
      () => db.setYesNoCompletion('h1', HabitDateUtils.todayKey(), true),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('o detalhe reflete um registo gravado diretamente na BD', (
    tester,
  ) async {
    await insertHabit('h1', 'Ler');
    await show(tester, const HabitDetailPage(habitId: 'h1'));
    expect(find.text(testL10n.markDoneToday), findsOneWidget);

    await tester.runAsync(
      () => db.setYesNoCompletion('h1', HabitDateUtils.todayKey(), true),
    );
    await tester.pumpAndSettle();

    expect(find.text(testL10n.doneToday), findsOneWidget);
  });
}
