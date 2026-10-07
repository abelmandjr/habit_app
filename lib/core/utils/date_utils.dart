import 'package:clock/clock.dart';

/// Datas de hábitos como **dias de calendário** (sem hora).
///
/// As contas com dias (somar, subtrair, contar) são feitas sobre
/// `DateTime.utc(ano, mês, dia)`: em UTC todos os dias têm 24 h, por isso a
/// hora de verão do fuso do dispositivo não tem efeito (bug M10). O único
/// valor que depende do fuso é "que dia é hoje", lido do relógio local.
class HabitDateUtils {
  HabitDateUtils._();

  static String dateKey(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String todayKey() => dateKey(clock.now());

  /// Dia de calendário de [key] (`YYYY-MM-DD`), em UTC.
  static DateTime parseKey(String key) {
    final parts = key.split('-');
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Dia de calendário de [date] (usa o ano, mês e dia de [date]), em UTC.
  static DateTime calendarDay(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  /// Hoje, como dia de calendário em UTC.
  static DateTime today() => calendarDay(clock.now());

  /// Chave do dia [days] dias depois (ou antes, se negativo) de [key].
  static String addDays(String key, int days) =>
      dateKey(parseKey(key).add(Duration(days: days)));

  /// Número de dias de calendário de [from] até [to] (pode ser negativo).
  static int daysBetween(DateTime from, DateTime to) =>
      calendarDay(to).difference(calendarDay(from)).inDays;

  /// Tempo de [now] até à próxima meia-noite local (início do dia seguinte).
  static Duration untilNextDay(DateTime now) =>
      DateTime(now.year, now.month, now.day + 1).difference(now);

  /// Meia-noite local de [date], para a UI (calendário, comparações de dias).
  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Os últimos [count] dias até hoje, por ordem, como dias de calendário.
  static List<DateTime> lastDays(int count) {
    final today = HabitDateUtils.today();
    return List.generate(
      count,
      (i) => today.subtract(Duration(days: count - 1 - i)),
    );
  }
}
