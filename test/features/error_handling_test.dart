import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/core/database/app_database.dart';
import 'package:habit_app/core/notifications/notification_service.dart';
import 'package:habit_app/core/providers/database_provider.dart';
import 'package:habit_app/core/utils/date_utils.dart';
import 'package:habit_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:habit_app/features/habits/presentation/pages/habit_detail_page.dart';
import 'package:habit_app/features/habits/presentation/pages/habit_form_page.dart';
import 'package:habit_app/features/habits/presentation/providers/habit_provider.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';

/// Tarefa 1.3: falhas de escrita e de leitura mostram feedback ao utilizador
/// e repõem o estado, sem exceções por apanhar.
void main() {
  late AppDatabase db;
  late FailingRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = FailingRepository(db);
  });

  tearDown(() => db.close());

  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          habitRepositoryProvider.overrideWithValue(repo),
          notificationServiceProvider.overrideWithValue(FakeNotifications()),
        ],
        child: testApp(page),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> insertHabit() => db.insertHabit(
        HabitsCompanion.insert(id: 'h1', title: 'Meditar', category: 'Geral'),
      );

  group('dashboard', () {
    testWidgets('falha ao marcar mostra erro e repõe o estado', (tester) async {
      await insertHabit();
      await pumpPage(tester, const DashboardPage());

      await tester.tap(find.text('Meditar'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(testL10n.errorSaveLog), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(await db.isCompletedOn('h1', HabitDateUtils.todayKey()), isFalse);
    });

    testWidgets('falha ao eliminar mostra erro e o hábito volta à lista', (
      tester,
    ) async {
      await insertHabit();
      await pumpPage(tester, const DashboardPage());

      await tester.drag(find.byType(Dismissible), const Offset(-600, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, testL10n.actionDelete));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(testL10n.errorDeleteHabit), findsOneWidget);
      expect(find.text('Meditar'), findsOneWidget);
      expect(await db.getAllHabits(), hasLength(1));
    });

    testWidgets('falha ao carregar mostra "Tentar de novo", que recupera', (
      tester,
    ) async {
      await insertHabit();
      repo.failedLoads = 1;
      await pumpPage(tester, const DashboardPage());

      expect(find.text(testL10n.errorLoadHabits), findsOneWidget);

      await tester.tap(find.text(testL10n.actionRetry));
      await tester.pumpAndSettle();

      expect(find.text('Meditar'), findsOneWidget);
    });
  });

  testWidgets('detalhe: falha ao registar no sheet mostra erro e repõe o estado',
      (tester) async {
    await insertHabit();
    await pumpPage(tester, const HabitDetailPage(habitId: 'h1'));

    await tester.tap(find.text('Marcar como feito hoje'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sim'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(testL10n.errorSaveLog), findsOneWidget);
    expect(find.text('Marcar como feito hoje'), findsOneWidget);
  });

  testWidgets('formulário: falha ao guardar mostra erro e fica no ecrã', (
    tester,
  ) async {
    await pumpPage(tester, const HabitFormPage());

    await tester.tap(find.text('Sim ou não'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Ler');
    await tester.scrollUntilVisible(
      find.text('Criar hábito'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Criar hábito'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(testL10n.errorSaveHabit), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Título'), findsOneWidget);
    expect(await db.getAllHabits(), isEmpty);
  });
}
