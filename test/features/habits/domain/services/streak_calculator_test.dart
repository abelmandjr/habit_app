import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/features/habits/domain/services/streak_calculator.dart';

import '../../../../helpers/fixtures.dart';

StreakStats compute(Set<String> dates) =>
    atTestNow(() => StreakCalculator.compute(dates));

void main() {
  group('StreakCalculator', () {
    test('sem registos devolve tudo a zero', () {
      final s = compute({});
      expect(s.currentStreak, 0);
      expect(s.bestStreak, 0);
      expect(s.completedToday, isFalse);
      expect(s.totalCompletions, 0);
    });

    test('só hoje feito: sequência 1', () {
      final s = compute({'2026-06-15'});
      expect(s.currentStreak, 1);
      expect(s.bestStreak, 1);
      expect(s.completedToday, isTrue);
      expect(s.totalCompletions, 1);
    });

    test('hoje ainda por fazer não quebra a sequência de ontem', () {
      final s = compute({'2026-06-13', '2026-06-14'});
      expect(s.currentStreak, 2);
      expect(s.completedToday, isFalse);
    });

    test('falhar ontem e hoje quebra a sequência atual', () {
      final s = compute({'2026-06-12', '2026-06-13'});
      expect(s.currentStreak, 0);
      expect(s.bestStreak, 2);
    });

    test('melhor sequência é a mais longa, mesmo que antiga', () {
      final s = compute({
        '2026-06-01', '2026-06-02', '2026-06-03', '2026-06-04', //
        '2026-06-14', '2026-06-15',
      });
      expect(s.currentStreak, 2);
      expect(s.bestStreak, 4);
      expect(s.totalCompletions, 6);
    });

    test('sequência atravessa a mudança de mês', () {
      final s = compute({'2026-05-30', '2026-05-31', '2026-06-01'});
      expect(s.bestStreak, 3);
    });
  });
}
