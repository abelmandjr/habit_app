// Estado do ecrã de detalhe de um hábito.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/habit_type.dart';
import '../../../../core/utils/date_utils.dart';
import '../../data/habit_repository_provider.dart';
import '../../domain/entities/habit.dart';
import '../../domain/models/habit_with_today.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/services/habit_queries.dart';
import '../../domain/services/habit_report_calculator.dart';
import '../../domain/services/streak_calculator.dart';
import 'habit_list_provider.dart';
import 'habit_log_action.dart';
import 'habit_queries_provider.dart';

/// Estado do detalhe de um hábito. É descartado quando o ecrã fecha
/// (autoDispose, bug M7).
final habitDetailNotifierProvider = StateNotifierProvider.autoDispose
    .family<HabitDetailNotifier, AsyncValue<HabitDetailState?>, String>(
  (ref, id) => HabitDetailNotifier(ref, id),
);

/// O notifier do detalhe de [habitId], só se esse ecrã estiver aberto.
///
/// Ler o provider diretamente criava-o (com consultas à BD) para cada hábito
/// tocado no dashboard, e ficava vivo para sempre (bug M7); com autoDispose
/// seria criado e logo descartado.
HabitDetailNotifier? openHabitDetail(Ref ref, String habitId) {
  final provider = habitDetailNotifierProvider(habitId);
  return ref.exists(provider) ? ref.read(provider.notifier) : null;
}

class HabitDetailNotifier extends StateNotifier<AsyncValue<HabitDetailState?>> {
  HabitDetailNotifier(this._ref, this._habitId) : super(const AsyncLoading()) {
    unawaited(refresh());
  }

  final Ref _ref;
  final String _habitId;

  HabitRepository get _repo => _ref.read(habitRepositoryProvider);
  HabitQueries get _queries => _ref.read(habitQueriesProvider);

  Future<void> refresh() async {
    if (state.valueOrNull == null) {
      state = const AsyncLoading();
    }

    try {
      // Só o hábito deste ecrã (antes carregava a lista inteira).
      final todayItem = await _queries.getHabitWithToday(_habitId);
      if (!mounted) return;
      if (todayItem == null) {
        state = const AsyncData(null);
        return;
      }

      final habit = todayItem.habit;
      final type = habit.type;

      YesNoHabitReport? yesNoReport;
      QuantitativeHabitReport? quantitativeReport;

      if (type == HabitType.yesNo) {
        yesNoReport = await _queries.getYesNoReport(_habitId);
      } else {
        quantitativeReport = await _queries.getQuantitativeReport(_habitId);
      }
      if (!mounted) return;

      state = AsyncData(
        HabitDetailState(
          habit: habit,
          completedToday: todayItem.completedToday,
          todayValue: todayItem.todayValue,
          yesNoReport: yesNoReport,
          quantitativeReport: quantitativeReport,
        ),
      );
    } catch (e, st) {
      if (mounted) state = AsyncError(e, st);
    }
  }

  Future<void> toggleToday() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.habit.type != HabitType.yesNo) return;

    await _ref.read(habitListProvider.notifier).logHabit(
          HabitWithToday(
            habit: current.habit,
            completedToday: current.completedToday,
            todayValue: current.todayValue,
          ),
          yesNo: !current.completedToday,
        );
  }

  void applyLogForDate(
    String dateKey, {
    bool? yesNo,
    double? quantity,
  }) {
    final current = state.valueOrNull;
    if (current == null) return;

    final isToday = dateKey == HabitDateUtils.todayKey();
    final type = current.habit.type;

    if (type == HabitType.yesNo && yesNo != null && current.yesNoReport != null) {
      final dates = Set<String>.from(current.yesNoReport!.completionDates);
      final met = current.habit.isGoalMet(
        logForAction(current.habit, dateKey, yesNo: yesNo),
      );
      if (met) {
        dates.add(dateKey);
      } else {
        dates.remove(dateKey);
      }
      state = AsyncData(
        current.copyWith(
          completedToday: isToday ? met : current.completedToday,
          yesNoReport: HabitReportCalculator.buildYesNoReport(
            habit: current.habit,
            completionDates: dates,
          ),
        ),
      );
      return;
    }

    if (type == HabitType.quantitative &&
        quantity != null &&
        current.quantitativeReport != null) {
      final report = current.quantitativeReport!;
      final goal = current.habit.goalValue;
      final met = current.habit.isGoalMet(
        logForAction(current.habit, dateKey, quantity: quantity),
      );
      final dates = Set<String>.from(report.goalMetDates);
      final logged = Set<String>.from(report.loggedDates);
      if (met) {
        dates.add(dateKey);
      } else {
        dates.remove(dateKey);
      }
      if (quantity > 0) {
        logged.add(dateKey);
      } else {
        logged.remove(dateKey);
      }
      state = AsyncData(
        current.copyWith(
          completedToday: isToday ? met : current.completedToday,
          todayValue: isToday ? (quantity > 0 ? quantity : null) : current.todayValue,
          quantitativeReport: QuantitativeHabitReport(
            todayValue: isToday ? quantity : report.todayValue,
            dailyAverage: report.dailyAverage,
            totalAccumulated: report.totalAccumulated,
            bestDayValue: report.bestDayValue,
            bestDayDate: report.bestDayDate,
            goalProgress: isToday && goal > 0
                ? (quantity / goal).clamp(0.0, 1.0)
                : report.goalProgress,
            goalMetToday: isToday ? met : report.goalMetToday,
            history: report.history,
            streak: StreakCalculator.compute(dates),
            goalMetDates: dates,
            loggedDates: logged,
          ),
        ),
      );
    }
  }

  Future<void> logForDate(
    DateTime day, {
    bool? yesNo,
    double? quantity,
  }) async {
    final key = HabitDateUtils.dateKey(day);

    applyLogForDate(key, yesNo: yesNo, quantity: quantity);
    // Obtido antes de esperar: o ecrã pode fechar entretanto.
    final list = _ref.read(habitListProvider.notifier);

    try {
      if (yesNo != null) {
        await _repo.setYesNo(_habitId, key, yesNo);
      } else if (quantity != null) {
        await _repo.setQuantity(_habitId, key, quantity);
      }
    } catch (_) {
      // Repõe o que está na BD, desfazendo a atualização otimista.
      await refresh();
      rethrow;
    }

    // A lista recarrega sempre (também num dia passado, que muda a sequência
    // mostrada no tile); o streak global observa-a e recalcula-se.
    await list.load(silent: true);
    await refresh();
  }
}

class HabitDetailState {
  const HabitDetailState({
    required this.habit,
    required this.completedToday,
    this.todayValue,
    this.yesNoReport,
    this.quantitativeReport,
  });

  final Habit habit;
  final bool completedToday;
  final double? todayValue;
  final YesNoHabitReport? yesNoReport;
  final QuantitativeHabitReport? quantitativeReport;

  HabitDetailState copyWith({
    bool? completedToday,
    double? todayValue,
    YesNoHabitReport? yesNoReport,
    QuantitativeHabitReport? quantitativeReport,
  }) {
    return HabitDetailState(
      habit: habit,
      completedToday: completedToday ?? this.completedToday,
      todayValue: todayValue ?? this.todayValue,
      yesNoReport: yesNoReport ?? this.yesNoReport,
      quantitativeReport: quantitativeReport ?? this.quantitativeReport,
    );
  }

  StreakStats get streak =>
      yesNoReport?.streak ??
      quantitativeReport?.streak ??
      const StreakStats(
        currentStreak: 0,
        bestStreak: 0,
        completedToday: false,
        totalCompletions: 0,
      );

  Set<String> get completionDates =>
      yesNoReport?.completionDates ??
      quantitativeReport?.goalMetDates ??
      {};
}
