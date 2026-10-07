import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/features/habits/presentation/widgets/streak_calendar.dart';

/// Tarefa 1.6: os dias anteriores à data de início não podem ser editados.
void main() {
  testWidgets('só os dias desde o início (e não futuros) são tocáveis', (
    tester,
  ) async {
    final tapped = <DateTime>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StreakCalendar(
              completionDates: const {},
              habitCreatedAt: DateTime(2026, 6, 10, 18),
              initialMonth: DateTime(2026, 6),
              onDayTap: tapped.add,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('5'));
    await tester.tap(find.text('9'));
    expect(tapped, isEmpty, reason: 'antes do início');

    await tester.tap(find.text('10'));
    await tester.tap(find.text('12'));
    expect(tapped, [DateTime(2026, 6, 10), DateTime(2026, 6, 12)]);
  });
}
