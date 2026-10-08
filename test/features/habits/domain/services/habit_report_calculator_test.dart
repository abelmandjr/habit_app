import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/core/models/habit_type.dart';
import 'package:habit_app/features/habits/domain/services/habit_report_calculator.dart';

import '../../../../helpers/fixtures.dart';

void main() {
  group('buildYesNoReport', () {
    test('conta dias feitos, falhados e taxa desde a criação (hoje por fazer não é falha)', () {
      final habit = makeHabit(createdAt: DateTime(2026, 6, 6, 18));
      final report = atTestNow(
        () => HabitReportCalculator.buildYesNoReport(
          habit: habit,
          completionDates: {
            '2026-06-06', '2026-06-08', '2026-06-10', //
            '2026-06-12', '2026-06-14',
          },
        ),
      );

      expect(report.trackedDays, 10); // 6 a 15 de junho, inclusive
      expect(report.daysDone, 5);
      // 9 dias já avaliados (6 a 14); hoje (15) ainda está por fazer.
      expect(report.daysFailed, 4);
      expect(report.successRate, closeTo(5 / 9 * 100, 0.01));
    });

    test(
      'registos anteriores à data de início são ignorados',
      () {
        final habit = makeHabit(createdAt: DateTime(2026, 6, 14));
        final report = atTestNow(
          () => HabitReportCalculator.buildYesNoReport(
            habit: habit,
            completionDates: {'2026-06-01', '2026-06-02', '2026-06-14'},
          ),
        );

        expect(report.daysDone, 1);
        expect(report.successRate, lessThanOrEqualTo(100));
      },
    );

    test(
      'hoje ainda por fazer não conta como falhado',
      () {
        final habit = makeHabit(createdAt: DateTime(2026, 6, 15));
        final report = atTestNow(
          () => HabitReportCalculator.buildYesNoReport(
            habit: habit,
            completionDates: {},
          ),
        );

        expect(report.daysFailed, 0);
      },
    );
  });

  group('buildQuantitativeReport', () {
    test('calcula hoje, média, total, melhor dia, progresso e histórico', () {
      final habit = makeHabit(
        type: HabitType.quantitative,
        goalValue: 2,
        unit: 'L',
      );
      final completions = [
        makeLog('h1', '2026-06-13', 1),
        makeLog('h1', '2026-06-14', 3),
        makeLog('h1', '2026-06-15', 2),
        makeLog('h1', '2026-06-10', 0), // valor 0 é ignorado
      ];

      final report = atTestNow(
        () => HabitReportCalculator.buildQuantitativeReport(
          habit: habit,
          logs: completions,
          goalMetDates: {'2026-06-14', '2026-06-15'},
        ),
      );

      expect(report.todayValue, 2);
      expect(report.totalAccumulated, 6);
      expect(report.dailyAverage, 2);
      expect(report.bestDayValue, 3);
      expect(report.bestDayDate, '2026-06-14');
      expect(report.goalProgress, 1.0);
      expect(report.goalMetToday, isTrue);
      expect(report.loggedDates, {'2026-06-13', '2026-06-14', '2026-06-15'});
      expect(report.streak.currentStreak, 2);

      expect(report.history, hasLength(30));
      expect(report.history.last.date, '2026-06-15');
      expect(report.history.last.value, 2);
      expect(report.history.first.date, '2026-05-17');
    });

    test('progresso é limitado a 100 %', () {
      final habit = makeHabit(type: HabitType.quantitative, goalValue: 2);
      final report = atTestNow(
        () => HabitReportCalculator.buildQuantitativeReport(
          habit: habit,
          logs: [makeLog('h1', '2026-06-15', 5)],
          goalMetDates: {'2026-06-15'},
        ),
      );
      expect(report.goalProgress, 1.0);
    });
  });

  group('computeGlobalStreak', () {
    test('sem hábitos devolve zero', () {
      final stats = atTestNow(
        () => HabitReportCalculator.computeGlobalStreak(
          habits: [],
          allLogs: [],
        ),
      );
      expect(stats.currentStreak, 0);
      expect(stats.bestStreak, 0);
    });

    test('um dia só conta se todos os hábitos ativos cumpriram a meta', () {
      final meditar = makeHabit(id: 'a', createdAt: DateTime(2026, 6, 12));
      final agua = makeHabit(
        id: 'b',
        type: HabitType.quantitative,
        goalValue: 2,
        createdAt: DateTime(2026, 6, 12),
      );
      // Criado mais tarde: não conta para os dias anteriores à sua criação.
      final ler = makeHabit(id: 'c', createdAt: DateTime(2026, 6, 14));

      final completions = [
        for (final d in ['2026-06-12', '2026-06-13', '2026-06-14', '2026-06-15'])
          makeLog('a', d),
        makeLog('b', '2026-06-12', 1), // abaixo da meta
        makeLog('b', '2026-06-13', 2),
        makeLog('b', '2026-06-14', 2),
        makeLog('b', '2026-06-15', 3),
        makeLog('c', '2026-06-14'),
        makeLog('c', '2026-06-15'),
      ];

      final stats = atTestNow(
        () => HabitReportCalculator.computeGlobalStreak(
          habits: [meditar, agua, ler],
          allLogs: completions,
        ),
      );

      expect(stats.currentStreak, 3); // 13, 14 e 15
      expect(stats.bestStreak, 3);
    });
  });
}
