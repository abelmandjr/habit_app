import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/l10n/app_formats.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/test_app.dart';

/// Tarefa 2.3: datas, números e plurais em português de Portugal.
void main() {
  setUpAll(() => initializeDateFormatting(AppFormats.locale));

  test('datas', () {
    final day = DateTime(2026, 10, 7);
    expect(AppFormats.weekdayDayMonth(day), 'quarta-feira, 7 de outubro');
    expect(AppFormats.dayMonthYear(day), '7 de outubro de 2026');
    expect(AppFormats.monthYear(DateTime(2026, 9)), 'Setembro 2026');
    expect(AppFormats.dayMonth(day), '7/10');
    expect(AppFormats.weekdayInitials(), ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']);
  });

  test('números: vírgula decimal, sem ".0" e sem separador de milhares', () {
    expect(AppFormats.number(2.0), '2');
    expect(AppFormats.number(1.5), '1,5');
    expect(AppFormats.number(2.25), '2,25');
    expect(AppFormats.number(1234.5), '1234,5');
    expect(AppFormats.quantity(1.5, 'L'), '1,5 L');
    expect(AppFormats.quantity(3, ''), '3');
    expect(AppFormats.percent(5 / 9), '56%');
  });

  test('plural de "dia": 0 dias, 1 dia, 2 dias (PT-PT)', () {
    expect(testL10n.dayUnit(0), 'dias');
    expect(testL10n.dayUnit(1), 'dia');
    expect(testL10n.dayUnit(2), 'dias');
  });

  test('saudação com e sem nome', () {
    expect(testL10n.greetingWithName('Boa tarde', 'Ana'), 'Boa tarde, Ana 👋');
    expect(testL10n.greetingWithoutName('Bom dia'), 'Bom dia 👋');
  });
}
