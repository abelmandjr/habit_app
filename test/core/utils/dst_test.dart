import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/core/notifications/notification_service.dart';
import 'package:habit_app/core/utils/date_utils.dart';
import 'package:habit_app/core/utils/habit_report_calculator.dart';
import 'package:habit_app/core/utils/streak_calculator.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/fixtures.dart';

/// Bug M10: as contas com dias não podem depender da hora de verão.
///
/// Não muda o fuso do sistema: usa o pacote `timezone` para simular um
/// dispositivo em Lisboa ou em Nova Iorque. O relógio injetado devolve um
/// `TZDateTime` nesse fuso, que é o que `clock.now()` daria no dispositivo.
///
/// Mudanças de hora em 2026:
/// - Europe/Lisbon: 29/03 (dia de 23 h) e 25/10 (dia de 25 h)
/// - America/New_York: 08/03 (dia de 23 h) e 01/11 (dia de 25 h)
void main() {
  late tz.Location lisbon;
  late tz.Location newYork;

  setUpAll(() {
    tzdata.initializeTimeZones();
    lisbon = tz.getLocation('Europe/Lisbon');
    newYork = tz.getLocation('America/New_York');
  });

  /// Corre [body] como se o dispositivo estivesse em [location] a [now].
  T at<T>(tz.Location location, DateTime now, T Function() body) {
    final local = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );
    return withClock(Clock.fixed(local), body);
  }

  /// Chaves de [count] dias seguidos a terminar em [lastKey].
  Set<String> daysEndingAt(String lastKey, int count) => {
        for (var i = 0; i < count; i++) HabitDateUtils.addDays(lastKey, -i),
      };

  group('controlo: a aritmética antiga falha nestes fusos', () {
    test('Lisboa: meia-noite de 30/03 menos 24 h salta o dia 29', () {
      final midnight = tz.TZDateTime(lisbon, 2026, 3, 30);
      final previous = midnight.subtract(const Duration(days: 1));
      expect(HabitDateUtils.dateKey(previous), '2026-03-28');
    });

    test('Nova Iorque: de 08/03 a 15/03 às meias-noites dá 6 dias', () {
      // A semana tem 7 dias de calendário mas só 167 h (perde-se 1 h a 08/03).
      final a = tz.TZDateTime(newYork, 2026, 3, 8);
      final b = tz.TZDateTime(newYork, 2026, 3, 15);
      expect(b.difference(a).inDays, 6);
    });
  });

  group('HabitDateUtils', () {
    test('addDays atravessa as mudanças de hora sem saltar dias', () {
      expect(HabitDateUtils.addDays('2026-03-30', -1), '2026-03-29');
      expect(HabitDateUtils.addDays('2026-03-28', 1), '2026-03-29');
      expect(HabitDateUtils.addDays('2026-03-09', -1), '2026-03-08');
      expect(HabitDateUtils.addDays('2026-10-25', 1), '2026-10-26');
      expect(HabitDateUtils.addDays('2026-11-01', 7), '2026-11-08');
    });

    test('daysBetween conta dias de calendário', () {
      expect(
        HabitDateUtils.daysBetween(
          tz.TZDateTime(newYork, 2026, 3, 8),
          tz.TZDateTime(newYork, 2026, 3, 15),
        ),
        7,
      );
      expect(
        HabitDateUtils.daysBetween(
          tz.TZDateTime(lisbon, 2026, 3, 28, 23, 30),
          tz.TZDateTime(lisbon, 2026, 3, 30, 0, 30),
        ),
        2,
      );
    });

    test('lastDays inclui o dia da mudança de hora (Lisboa)', () {
      final days = at(lisbon, DateTime(2026, 3, 31, 10), () {
        return HabitDateUtils.lastDays(4).map(HabitDateUtils.dateKey).toList();
      });
      expect(days, ['2026-03-28', '2026-03-29', '2026-03-30', '2026-03-31']);
    });
  });

  group('StreakCalculator', () {
    for (final (name, location, lastDay) in [
      ('Lisboa, primavera', 'Europe/Lisbon', '2026-03-31'),
      ('Lisboa, outono', 'Europe/Lisbon', '2026-10-27'),
      ('Nova Iorque, primavera', 'America/New_York', '2026-03-10'),
      ('Nova Iorque, outono', 'America/New_York', '2026-11-03'),
    ]) {
      test('sequência atravessa a mudança de hora ($name)', () {
        final today = HabitDateUtils.parseKey(lastDay);
        final dates = daysEndingAt(lastDay, 10);
        final stats = at(
          tz.getLocation(location),
          DateTime(today.year, today.month, today.day, 10),
          () => StreakCalculator.compute(dates),
        );
        expect(stats.currentStreak, 10);
        expect(stats.bestStreak, 10);
      });
    }
  });

  group('HabitReportCalculator', () {
    test('dias acompanhados ao longo de março (Nova Iorque e Lisboa)', () {
      for (final location in [newYork, lisbon]) {
        final tracked = at(
          location,
          DateTime(2026, 3, 31, 10),
          () => HabitReportCalculator.trackedDaysSince(
            tz.TZDateTime(location, 2026, 3, 1, 9),
          ),
        );
        expect(tracked, 31, reason: location.name);
      }
    });

    test('streak global avalia o dia de hoje no dia da mudança de hora', () {
      final habit = makeHabit(createdAt: DateTime(2026, 3, 1));
      final completions = [
        for (final d in daysEndingAt('2026-03-08', 8)) makeCompletion('h1', d),
      ];
      final stats = at(
        newYork,
        DateTime(2026, 3, 8, 12),
        () => HabitReportCalculator.computeGlobalStreak(
          habits: [habit],
          allCompletions: completions,
        ),
      );
      expect(stats.currentStreak, 8);
    });
  });

  group('lembretes: próxima ocorrência', () {
    test('Lisboa: 09:00 do dia em que a hora muda continua a ser às 09:00', () {
      final now = tz.TZDateTime(lisbon, 2026, 3, 28, 22);
      final next = NotificationService.nextInstanceOf(now, 9, 0);
      expect([next.year, next.month, next.day, next.hour], [2026, 3, 29, 9]);

      // Controlo: somar 24 h às 09:00 de hoje dava 10:00.
      final oldWay =
          tz.TZDateTime(lisbon, 2026, 3, 28, 9).add(const Duration(days: 1));
      expect(oldWay.hour, 10);
    });

    test('Nova Iorque: 08:00 no fim da hora de verão continua a ser às 08:00',
        () {
      final now = tz.TZDateTime(newYork, 2026, 10, 31, 20);
      final next = NotificationService.nextInstanceOf(now, 8, 0);
      expect([next.year, next.month, next.day, next.hour], [2026, 11, 1, 8]);

      final oldWay =
          tz.TZDateTime(newYork, 2026, 10, 31, 8).add(const Duration(days: 1));
      expect(oldWay.hour, 7);
    });

    test('ainda hoje, se a hora não passou', () {
      final now = tz.TZDateTime(newYork, 2026, 6, 15, 7, 30);
      final next = NotificationService.nextInstanceOf(now, 8, 0);
      expect([next.day, next.hour, next.minute], [15, 8, 0]);
    });
  });
}
