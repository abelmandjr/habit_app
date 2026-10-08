// Lista "Hoje" e streak global.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/habit_type.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../data/habit_repository_provider.dart';
import '../../domain/habit_reminders.dart';
import '../../domain/models/habit_with_today.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/services/habit_queries.dart';
import '../../domain/services/habit_report_calculator.dart';
import 'habit_detail_provider.dart';
import 'habit_log_action.dart';
import 'habit_queries_provider.dart';

final habitListProvider =
    StateNotifierProvider<HabitListNotifier, AsyncValue<List<HabitWithToday>>>(
  (ref) => HabitListNotifier(ref),
);

final globalStreakProvider = FutureProvider<GlobalStreakStats>((ref) async {
  ref.watch(habitListProvider);
  return ref.watch(habitQueriesProvider).getGlobalStreakStats();
});

class HabitListNotifier extends StateNotifier<AsyncValue<List<HabitWithToday>>> {
  HabitListNotifier(this._ref) : super(const AsyncLoading()) {
    unawaited(load());
  }

  final Ref _ref;
  static var _remindersSynced = false;

  HabitRepository get _repo => _ref.read(habitRepositoryProvider);
  HabitQueries get _queries => _ref.read(habitQueriesProvider);
  NotificationService get _notifications =>
      _ref.read(notificationServiceProvider);

  Future<void> load({bool silent = false}) async {
    if (!silent) state = const AsyncLoading();
    try {
      final data = await _queries.getHabitsWithTodayStatus();
      state = AsyncData(data);
    } catch (e, st) {
      state = AsyncError(e, st);
      return;
    }

    if (!_remindersSynced) {
      _remindersSynced = true;
      await _syncReminders();
    }
  }

  /// Uma falha nas notificações não deve deixar a lista em estado de erro.
  Future<void> _syncReminders() async {
    try {
      final habits = await _repo.getHabits();
      await _notifications.rescheduleAll([for (final h in habits) h.reminder]);
    } catch (e, st) {
      debugPrint('Falha ao reagendar lembretes: $e\n$st');
    }
  }

  Future<void> logHabit(
    HabitWithToday item, {
    bool? yesNo,
    double? quantity,
    DateTime? date,
  }) async {
    final dateKey =
        date != null ? HabitDateUtils.dateKey(date) : HabitDateUtils.todayKey();
    final isToday = dateKey == HabitDateUtils.todayKey();

    if (isToday) {
      _applyOptimisticToday(item.habit.id, yesNo: yesNo, quantity: quantity);
    }

    openHabitDetail(_ref, item.habit.id)
        ?.applyLogForDate(dateKey, yesNo: yesNo, quantity: quantity);

    try {
      if (item.type == HabitType.yesNo && yesNo != null) {
        await _repo.setYesNo(item.habit.id, dateKey, yesNo);
      } else if (item.type == HabitType.quantitative && quantity != null) {
        await _repo.setQuantity(item.habit.id, dateKey, quantity);
      }

      await openHabitDetail(_ref, item.habit.id)?.refresh();
      // Não invalidar globalStreakProvider aqui: ele observa esta lista e
      // recalcula-se quando o load publica o novo estado. Invalidá-lo a partir
      // deste notifier é uma dependência circular (bug A6).
      if (isToday) {
        await load(silent: true);
      }
    } catch (e) {
      // Repõe o que está na BD, desfazendo as atualizações otimistas.
      if (isToday) await load(silent: true);
      await openHabitDetail(_ref, item.habit.id)?.refresh();
      rethrow;
    }
  }

  void _applyOptimisticToday(
    String habitId, {
    bool? yesNo,
    double? quantity,
  }) {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(
      current.map((h) {
        if (h.habit.id != habitId) return h;
        if (yesNo == null && quantity == null) return h;
        final log = logForAction(
          h.habit,
          HabitDateUtils.todayKey(),
          yesNo: yesNo,
          quantity: quantity,
        );
        return HabitWithToday(
          habit: h.habit,
          completedToday: h.habit.isGoalMet(log),
          todayValue: quantity != null ? log?.value : h.todayValue,
          currentStreak: h.currentStreak,
        );
      }).toList(),
    );
  }

  Future<void> deleteHabit(String id) async {
    // Remove do estado antes de qualquer await: o Dismissible exige que o
    // item saia da árvore no mesmo frame em que é dispensado.
    final previous = state;
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.where((h) => h.habit.id != id).toList());
    }

    try {
      await _notifications.cancelHabitReminder(id);
      await _repo.deleteHabit(id);
    } catch (_) {
      state = previous;
      rethrow;
    }
    await load(silent: true);
  }
}
