import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/core/database/app_database.dart';
import 'package:habit_app/core/models/habit_type.dart';
import 'package:habit_app/features/habits/data/repositories/drift_habit_repository.dart';
import 'package:habit_app/features/habits/domain/services/habit_queries.dart';

import '../../../../helpers/fixtures.dart';

/// Tarefa 2.1b: consultas derivadas sobre o HabitRepository (antes no
/// AppDatabase e no repositório).
void main() {
  late AppDatabase db;
  late DriftHabitRepository repo;
  late HabitQueries queries;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftHabitRepository(db);
    queries = HabitQueries(repo);
  });
  tearDown(() => db.close());

  test('registos anteriores à data de início não contam (tarefa 1.6)', () async {
    await repo.createHabit(makeHabit(createdAt: DateTime(2026, 6, 10)));
    await repo.setYesNo('h1', '2026-06-05', true);
    await repo.setYesNo('h1', '2026-06-12', true);

    expect(await queries.getCompletionDates('h1'), {'2026-06-12'});
    expect((await queries.getStreakStats('h1')).totalCompletions, 1);
  });

  test('estado de hoje: sim/não e quantitativo com e sem meta cumprida',
      () async {
    await repo.createHabit(makeHabit(id: 'ler'));
    await repo.createHabit(
      makeHabit(id: 'agua', type: HabitType.quantitative, goalValue: 2),
    );
    await repo.createHabit(makeHabit(id: 'correr'));

    await atTestNow(() async {
      await repo.setYesNo('ler', '2026-06-14', true);
      await repo.setYesNo('ler', '2026-06-15', true);
      await repo.setQuantity('agua', '2026-06-15', 1.5);

      final items = {
        for (final i in await queries.getHabitsWithTodayStatus()) i.habit.id: i,
      };

      expect(items['ler']!.completedToday, isTrue);
      expect(items['ler']!.currentStreak, 2);
      expect(items['agua']!.completedToday, isFalse, reason: '1,5 < meta 2');
      expect(items['agua']!.todayValue, 1.5);
      expect(items['agua']!.progressRatio, 0.75);
      expect(items['correr']!.completedToday, isFalse);
      expect(items['correr']!.todayValue, isNull);
    });
  });

  test('getHabitWithToday devolve só esse hábito, ou null', () async {
    await repo.createHabit(makeHabit());
    expect((await queries.getHabitWithToday('h1'))!.habit.id, 'h1');
    expect(await queries.getHabitWithToday('nao-existe'), isNull);
  });

  test('isCompletedOn e getValueOn por dia', () async {
    await repo.createHabit(
      makeHabit(id: 'agua', type: HabitType.quantitative, goalValue: 2),
    );
    await repo.setQuantity('agua', '2026-06-15', 2.5);

    final day = DateTime(2026, 6, 15);
    expect(await queries.isCompletedOn('agua', day), isTrue);
    expect(await queries.getValueOn('agua', day), 2.5);
    expect(await queries.getValueOn('agua', DateTime(2026, 6, 14)), isNull);
  });

  test('relatórios de um hábito que não existe vêm vazios', () async {
    expect((await queries.getYesNoReport('x')).trackedDays, 0);
    expect((await queries.getQuantitativeReport('x')).history, isEmpty);
  });
}
