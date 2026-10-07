import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/core/database/app_database.dart';

/// Tarefa 1.4: a v4 é a base do schema e as chaves estrangeiras estão ativas.
void main() {
  Future<int> userVersion(AppDatabase db) async =>
      (await db.customSelect('PRAGMA user_version').getSingle())
          .read<int>('user_version');

  Future<void> insertHabit(AppDatabase db, String id) => db.insertHabit(
        HabitsCompanion.insert(id: id, title: 'Meditar', category: 'Geral'),
      );

  test('BD nova é criada na versão base (4)', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await insertHabit(db, 'h1');

    expect(await userVersion(db), 4);
    expect(await db.getAllHabits(), hasLength(1));
  });

  test('BD anterior à base (v1) é apagada e recriada com o schema atual', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          // Schema da v1: sem description, habit_type, created_at, etc.
          raw.execute(
            'CREATE TABLE habits (id TEXT NOT NULL PRIMARY KEY, '
            'title TEXT NOT NULL, category TEXT NOT NULL, '
            'is_completed INTEGER NOT NULL DEFAULT 0)',
          );
          raw.execute(
            "INSERT INTO habits VALUES ('antigo', 'Antigo', 'Geral', 1)",
          );
          raw.execute('PRAGMA user_version = 1');
        },
      ),
    );
    addTearDown(db.close);

    // Os dados de desenvolvimento antigos não são migrados (decisão 11)...
    expect(await db.getAllHabits(), isEmpty);
    expect(await userVersion(db), 4);

    // ...e todas as tabelas atuais funcionam.
    await insertHabit(db, 'h1');
    await db.setYesNoCompletion('h1', '2026-06-15', true);
    await db.setUserName('Ana');
    expect(await db.getHabitById('h1'), isNotNull);
    expect(await db.isCompletedOn('h1', '2026-06-15'), isTrue);
    expect(await db.getUserName(), 'Ana');
  });

  test('BD já na versão base mantém os dados ao reabrir', () async {
    final dir = await Directory.systemTemp.createTemp('habit_db_test');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/habits.sqlite');

    final first = AppDatabase(NativeDatabase(file));
    await insertHabit(first, 'h1');
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    addTearDown(second.close);
    expect(await second.getAllHabits(), hasLength(1));
  });

  group('chaves estrangeiras', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('estão ativas', () async {
      final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(row.read<int>('foreign_keys'), 1);
    });

    test('impedem registos de um hábito que não existe', () async {
      expect(
        db.into(db.habitCompletions).insert(
              HabitCompletionsCompanion.insert(
                habitId: 'inexistente',
                date: '2026-06-15',
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('apagar um hábito apaga os registos (ON DELETE CASCADE)', () async {
      await insertHabit(db, 'h1');
      await db.setYesNoCompletion('h1', '2026-06-15', true);

      await db.customStatement("DELETE FROM habits WHERE id = 'h1'");

      expect(await db.getAllCompletions(), isEmpty);
    });
  });
}
