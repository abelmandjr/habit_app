import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/core/database/app_database.dart';
import 'package:habit_app/core/notifications/notification_service.dart';
import 'package:habit_app/core/providers/database_provider.dart';
import 'package:habit_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:habit_app/features/habits/presentation/pages/habit_detail_page.dart';
import 'package:habit_app/features/habits/presentation/providers/habit_provider.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';
import '../../helpers/fixtures.dart';

/// Tarefa 2.1d (bug M7): o estado do ecrã de detalhe só existe enquanto o
/// ecrã está aberto.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = memoryDatabase();
    container = ProviderContainer(
      overrides: [
        dbProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(FakeNotifications()),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> show(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: testApp(page)),
    );
    await tester.pumpAndSettle();
  }

  bool detailExists() =>
      container.exists(habitDetailNotifierProvider('h1'));

  Future<void> insertHabit() => db.insertHabit(
        HabitsCompanion.insert(id: 'h1', title: 'Meditar', category: 'Geral'),
      );

  testWidgets('marcar no dashboard não cria o estado do detalhe', (
    tester,
  ) async {
    await insertHabit();
    await show(tester, const DashboardPage());

    await tester.tap(find.text('Meditar'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(detailExists(), isFalse);
  });

  testWidgets('sair do detalhe liberta o seu estado', (tester) async {
    await insertHabit();
    await show(tester, const HabitDetailPage(habitId: 'h1'));
    expect(detailExists(), isTrue);

    await show(tester, const SizedBox());

    expect(detailExists(), isFalse);
  });
}
