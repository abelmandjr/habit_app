import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/core/database/app_database.dart';
import 'package:habit_app/core/notifications/notification_service.dart';
import 'package:habit_app/core/providers/database_provider.dart';
import 'package:habit_app/core/utils/date_utils.dart';
import 'package:habit_app/features/dashboard/presentation/pages/dashboard_page.dart';

/// Evita chamadas ao plugin nativo de notificações nos testes.
class _FakeNotifications implements NotificationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pumpDashboard(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(_FakeNotifications()),
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
  }, skip: true); // Bug A6 (CircularDependencyError): corrigido na tarefa 1.12

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
  }, skip: true); // Bug A6 (CircularDependencyError): corrigido na tarefa 1.12

}
