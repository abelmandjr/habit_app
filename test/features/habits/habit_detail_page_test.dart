import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/core/database/app_database.dart';
import 'package:habit_app/core/notifications/notification_service.dart';
import 'package:habit_app/core/providers/database_provider.dart';
import 'package:habit_app/features/habits/presentation/pages/habit_detail_page.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';
import '../../helpers/fixtures.dart';

const _months = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', //
  'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

/// Tarefa 1.7: editar um dia de um mês anterior não faz o calendário voltar
/// ao mês atual.
void main() {
  testWidgets('o calendário mantém o mês depois de registar um dia', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1);
    await db.insertHabit(
      HabitsCompanion.insert(
        id: 'h1',
        title: 'Meditar',
        category: 'Geral',
        createdAt: Value(DateTime(now.year, now.month - 2)),
      ),
    );

    // Ecrã alto, para o calendário caber sem scroll.
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(FakeNotifications()),
        ],
        child: testApp(const HabitDetailPage(habitId: 'h1')),
      ),
    );
    await tester.pumpAndSettle();

    final previousLabel =
        '${_months[previousMonth.month - 1]} ${previousMonth.year}';
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.text(previousLabel), findsOneWidget);

    // Regista o dia 15 do mês anterior.
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sim'));
    await tester.pumpAndSettle();

    final day = DateTime(previousMonth.year, previousMonth.month, 15);
    expect(await queriesFor(db).isCompletedOn('h1', day), isTrue);
    expect(find.text(previousLabel), findsOneWidget,
        reason: 'O calendário voltou ao mês atual');
  });
}
