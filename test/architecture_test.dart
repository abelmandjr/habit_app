import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regras de dependência entre camadas (pedido de 2026-10-07, tarefa 2.1b).
///
/// Falha se algum ficheiro importar o que a sua camada não deve conhecer.
void main() {
  /// Imports de [dir] (recursivo) que casam com [forbidden], como
  /// "ficheiro: import".
  List<String> violations(String dir, RegExp forbidden) {
    final found = <String>[];
    final root = Directory(dir);
    if (!root.existsSync()) return found;
    for (final file in root.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      for (final line in file.readAsLinesSync()) {
        final trimmed = line.trim();
        if ((trimmed.startsWith('import ') || trimmed.startsWith('export ')) &&
            forbidden.hasMatch(trimmed)) {
          found.add('${file.path.replaceAll(r'\', '/')}: $trimmed');
        }
      }
    }
    return found;
  }

  List<String> inFeatures(String layer, RegExp forbidden) => [
        for (final feature in Directory('lib/features')
            .listSync()
            .whereType<Directory>())
          ...violations('${feature.path}/$layer', forbidden),
      ];

  test('a apresentação não importa o Drift nem a BD', () {
    final forbidden = RegExp(
      r'''package:drift/|app_database\.dart|database_provider\.dart''',
    );
    expect(inFeatures('presentation', forbidden), isEmpty);
  });

  test('o domínio não importa o Drift, a BD, a camada de dados nem o Flutter',
      () {
    final forbidden = RegExp(
      r'''package:drift/|app_database\.dart|database_provider\.dart|/data/|package:flutter/|package:flutter_riverpod/''',
    );
    expect(inFeatures('domain', forbidden), isEmpty);
  });

  test('a regra deteta violações (controlo)', () {
    final dir = Directory.systemTemp.createTempSync('arch_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/widget.dart')
        .writeAsStringSync("import 'package:drift/drift.dart';\n");

    expect(violations(dir.path, RegExp('package:drift/')), hasLength(1));
  });
}
