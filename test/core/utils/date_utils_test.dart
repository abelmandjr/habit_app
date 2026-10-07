import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/core/utils/date_utils.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('HabitDateUtils', () {
    test('dateKey preenche mês e dia com zeros', () {
      expect(HabitDateUtils.dateKey(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
    });

    test('parseKey é o inverso de dateKey e devolve o dia em UTC', () {
      final date = HabitDateUtils.parseKey('2026-12-31');
      expect(date, DateTime.utc(2026, 12, 31));
      expect(HabitDateUtils.dateKey(date), '2026-12-31');
    });

    test('todayKey usa o relógio injetado', () {
      expect(atTestNow(HabitDateUtils.todayKey), '2026-06-15');
    });

    test('lastDays devolve os últimos N dias por ordem, terminando hoje', () {
      final days = atTestNow(() => HabitDateUtils.lastDays(3));
      expect(
        days.map(HabitDateUtils.dateKey),
        ['2026-06-13', '2026-06-14', '2026-06-15'],
      );
    });
  });
}
