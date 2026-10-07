import 'package:habit_app/core/database/app_database.dart';
import 'package:habit_app/core/models/habit_type.dart';
import 'package:habit_app/core/notifications/notification_service.dart';
import 'package:habit_app/features/habits/data/repositories/habit_repository_impl.dart';

/// Evita chamadas ao plugin nativo de notificações nos testes.
class FakeNotifications implements NotificationService {
  FakeNotifications({
    this.permissionGranted = true,
    this.exactAlarmsAllowed = true,
    this.exactAlarmsAllowedAfterSettings,
  });

  /// Resposta simulada ao pedido de permissão de notificações.
  final bool permissionGranted;
  int permissionRequests = 0;

  /// Estado simulado de "Alarmes e lembretes" (SCHEDULE_EXACT_ALARM).
  bool exactAlarmsAllowed;

  /// Estado depois de "abrir as definições" (por omissão, não muda).
  final bool? exactAlarmsAllowedAfterSettings;
  int exactAlarmSettingsOpened = 0;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<bool> canScheduleExactAlarms() async => exactAlarmsAllowed;

  @override
  Future<bool> syncExactAlarmPermission(AppDatabase db) async =>
      exactAlarmsAllowed;

  @override
  Future<bool> openExactAlarmSettings() async {
    exactAlarmSettingsOpened++;
    exactAlarmsAllowed = exactAlarmsAllowedAfterSettings ?? exactAlarmsAllowed;
    return exactAlarmsAllowed;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

/// Repositório real (BD em memória) em que as escritas falham sempre e a
/// leitura da lista falha as primeiras [failedLoads] vezes.
class FailingRepository extends HabitRepositoryImpl {
  FailingRepository(super.db, {this.failedLoads = 0});

  int failedLoads;

  static Future<void> _fail() => Future.error(Exception('falha simulada'));

  @override
  Future<List<HabitWithToday>> getHabitsWithTodayStatus() {
    if (failedLoads > 0) {
      failedLoads--;
      return Future.error(Exception('falha simulada'));
    }
    return super.getHabitsWithTodayStatus();
  }

  @override
  Future<void> setYesNoForDate(String habitId, String date, bool completed) =>
      _fail();

  @override
  Future<void> setQuantitativeForDate(
    String habitId,
    String date,
    double value,
  ) =>
      _fail();

  @override
  Future<void> deleteHabit(String id) => _fail();

  @override
  Future<void> createHabit({
    required String id,
    required String title,
    required String description,
    required String category,
    required HabitType habitType,
    required int goalValue,
    String? unit,
    bool reminderEnabled = false,
    int? reminderHour,
    int? reminderMinute,
  }) =>
      _fail();
}
