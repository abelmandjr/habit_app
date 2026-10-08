import 'package:intl/intl.dart';

/// Formatos de datas e números da app, em português de Portugal.
///
/// Os dados de datas do `intl` para `pt_PT` são carregados pelos
/// `GlobalMaterialLocalizations`; fora da árvore de widgets (testes de
/// funções), chamar `initializeDateFormatting('pt_PT')` antes.
abstract final class AppFormats {
  static const locale = 'pt_PT';

  /// "quarta-feira, 7 de outubro"
  static String weekdayDayMonth(DateTime d) =>
      DateFormat("EEEE, d 'de' MMMM", locale).format(d);

  /// "7 de outubro de 2026"
  static String dayMonthYear(DateTime d) =>
      DateFormat("d 'de' MMMM 'de' y", locale).format(d);

  /// "Outubro 2026"
  static String monthYear(DateTime d) {
    final text = DateFormat('MMMM y', locale).format(d);
    return text[0].toUpperCase() + text.substring(1);
  }

  /// "7/10"
  static String dayMonth(DateTime d) => DateFormat('d/M', locale).format(d);

  /// Iniciais dos dias da semana, a começar ao domingo: D, S, T, Q, Q, S, S.
  static List<String> weekdayInitials() {
    final format = DateFormat('EEEEE', locale);
    // 2026-06-07 foi um domingo.
    return List.generate(7, (i) => format.format(DateTime(2026, 6, 7 + i)))
        .map((s) => s.toUpperCase())
        .toList();
  }

  /// Número com até 2 casas decimais e vírgula: 2 → "2", 1.5 → "1,5".
  /// Sem separador de milhares, para poder ser editado e lido de volta.
  static String number(num value) => NumberFormat('0.##', locale).format(value);

  /// Número com unidade opcional: "1,5 L", "3".
  static String quantity(num value, String unit) =>
      unit.isEmpty ? number(value) : '${number(value)} $unit';

  /// Percentagem arredondada: 0.556 → "56%".
  static String percent(double fraction) => '${(fraction * 100).round()}%';
}
