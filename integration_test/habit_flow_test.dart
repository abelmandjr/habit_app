import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/core/database/app_database.dart';
import 'package:habit_app/core/notifications/notification_service.dart';
import 'package:habit_app/core/providers/database_provider.dart';
import 'package:habit_app/main.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/fakes.dart';
import '../test/helpers/test_app.dart';

/// Fluxo completo no dispositivo (tarefas 1.2 e 1.12): criar um hábito pela UI,
/// marcá-lo, ver o streak global atualizar e eliminá-lo com swipe.
///
/// Usa uma BD em memória: os dados reais da app no telemóvel não são tocados.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // O banner do streak global é um RichText: "N dia(s)  ·  melhor: M dia(s)".
  Finder banner(String text) => find.textContaining(text, findRichText: true);

  testWidgets('criar, marcar e eliminar um hábito', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

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
    expect(find.text(testL10n.emptyTitle), findsOneWidget);

    // Criar pela UI.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sim ou não'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Título'),
      'Teste de integração',
    );
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

    expect(find.text('Teste de integração'), findsOneWidget);
    expect(banner('0 dias  ·  melhor: 0 dias'), findsOneWidget);
    expect(await db.getAllHabits(), hasLength(1));

    // Marcar como feito: a lista e o streak global atualizam.
    await tester.tap(find.text('Teste de integração'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(banner('1 dia  ·  melhor: 1 dia'), findsOneWidget);

    // Eliminar com swipe, sem erros. (O SnackBar "Hábito criado" também é um
    // Dismissible, por isso procura-se o que contém o hábito.)
    await tester.drag(
      find.ancestor(
        of: find.text('Teste de integração'),
        matching: find.byType(Dismissible),
      ),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, testL10n.actionDelete));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Teste de integração'), findsNothing);
    expect(find.text(testL10n.emptyTitle), findsOneWidget);
    expect(banner('0 dias  ·  melhor: 0 dias'), findsOneWidget);
    expect(await db.getAllHabits(), isEmpty);
  });
}
