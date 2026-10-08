import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/app_localizations.dart';
import '../database/app_database.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

/// Estado da permissão de alarmes exatos, para a UI. É invalidado quando a
/// app volta ao primeiro plano e depois de abrir as definições.
final exactAlarmsAllowedProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.watch(notificationServiceProvider).canScheduleExactAlarms();
});

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    // As permissões não são pedidas no arranque: só quando o utilizador liga
    // o primeiro lembrete (ver requestPermission).
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (_) {},
    );

    _lastExactAllowed = await canScheduleExactAlarms();
    _initialized = true;
  }

  /// Pede permissão para mostrar notificações (Android 13+ / iOS).
  /// Devolve `true` se as notificações estiverem autorizadas.
  Future<bool> requestPermission() async {
    final android = _android;
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? await android.areNotificationsEnabled() ?? true;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Sem isto, `tz.local` fica em UTC e os lembretes disparam à hora errada.
  Future<void> _configureLocalTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('Fuso horário local indisponível, a usar UTC: $e');
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Se a app pode agendar alarmes exatos (SCHEDULE_EXACT_ALARM, que no
  /// Android 14+ vem desligada por omissão). Fora do Android devolve `true`.
  Future<bool> canScheduleExactAlarms() async {
    final android = _android;
    if (android == null) return true;
    return await android.canScheduleExactNotifications() ?? false;
  }

  /// Abre as definições "Alarmes e lembretes" da app e devolve o estado da
  /// permissão depois de o utilizador voltar.
  Future<bool> openExactAlarmSettings() async {
    await _android?.requestExactAlarmsPermission();
    return canScheduleExactAlarms();
  }

  bool? _lastExactAllowed;

  /// Último estado conhecido de "Alarmes e lembretes" (atualizado ao iniciar
  /// e em [syncExactAlarmPermission]).
  bool? get lastKnownExactAlarmsAllowed => _lastExactAllowed;

  /// Verifica se a permissão de alarmes exatos mudou desde a última vez e,
  /// se mudou, reagenda todos os lembretes no modo certo. Devolve o estado.
  Future<bool> syncExactAlarmPermission(AppDatabase db) async {
    final allowed = await canScheduleExactAlarms();
    final previous = _lastExactAllowed;
    _lastExactAllowed = allowed;
    if (previous != null && previous != allowed) {
      await rescheduleAll(db);
    }
    return allowed;
  }

  Future<void> rescheduleAll(AppDatabase db) async {
    if (!_initialized) return;
    final habits = await db.getAllHabits();
    for (final habit in habits) {
      await syncHabitReminder(habit);
    }
  }

  /// Próxima ocorrência de [hour]:[minute] no fuso de [now] (hoje, ou amanhã
  /// se já passou). Avança por campos de calendário e não somando 24 h: num
  /// dia com mudança de hora, somar 24 h daria uma hora a mais ou a menos.
  static tz.TZDateTime nextInstanceOf(
    tz.TZDateTime now,
    int hour,
    int minute,
  ) {
    final today = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!today.isBefore(now)) return today;
    return tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + 1,
      hour,
      minute,
    );
  }

  int notificationIdForHabit(String habitId) =>
      habitId.hashCode.abs() % 2147483647;

  Future<void> scheduleHabitReminder(HabitData habit) async {
    if (!_initialized || !habit.reminderEnabled) return;
    if (habit.reminderHour == null || habit.reminderMinute == null) return;

    final id = notificationIdForHabit(habit.id);
    await cancelHabitReminder(habit.id);

    final scheduled = nextInstanceOf(
      tz.TZDateTime.now(tz.local),
      habit.reminderHour!,
      habit.reminderMinute!,
    );

    // Sem BuildContext: os textos vêm diretamente do ARB da língua da app.
    final l10n = lookupAppLocalizations(const Locale('pt'));
    final androidDetails = AndroidNotificationDetails(
      'habit_reminders',
      l10n.notificationChannelName,
      channelDescription: l10n.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: id,
      title: l10n.notificationTitle,
      body: habit.title,
      scheduledDate: scheduled,
      notificationDetails: details,
      // Exato só com SCHEDULE_EXACT_ALARM concedida pelo utilizador. Sem ela,
      // o Android pode atrasar o alarme até 75 % do tempo que falta para ele.
      androidScheduleMode: await canScheduleExactAlarms()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelHabitReminder(String habitId) async {
    await _plugin.cancel(id: notificationIdForHabit(habitId));
  }

  Future<void> syncHabitReminder(HabitData habit) async {
    if (habit.reminderEnabled) {
      await scheduleHabitReminder(habit);
    } else {
      await cancelHabitReminder(habit.id);
    }
  }
}
