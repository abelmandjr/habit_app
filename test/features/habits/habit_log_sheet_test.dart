import 'package:drift/drift.dart' show Value;
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

/// Tarefa 1.9: o registo quantitativo aceita vírgula e ponto decimal.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> logValue(WidgetTester tester, String typed) async {
    await db.insertHabit(
      HabitsCompanion.insert(
        id: 'agua',
        title: 'Beber água',
        category: 'Saúde',
        habitType: const Value('quantitative'),
        goalValue: const Value(2),
        unit: const Value('L'),
      ),
    );
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

    await tester.tap(find.text('Beber água'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), typed);
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
  }

  Future<double?> todayValue() =>
      db.getLoggedValue('agua', HabitDateUtils.todayKey());

  testWidgets('aceita vírgula decimal ("1,5")', (tester) async {
    await logValue(tester, '1,5');
    expect(await todayValue(), 1.5);
  });

  testWidgets('aceita ponto decimal ("2.25")', (tester) async {
    await logValue(tester, '2.25');
    expect(await todayValue(), 2.25);
  });

  testWidgets('ignora um segundo separador ("1,5,3" fica "1,5")', (
    tester,
  ) async {
    await logValue(tester, '1,5,3');
    expect(await todayValue(), 1.5);
  });
}
