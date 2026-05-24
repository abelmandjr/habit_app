import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/models/habit_type.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/storage/user_settings_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/habit_report_calculator.dart';
import '../../../../core/utils/streak_calculator.dart';
import '../../data/repositories/habit_repository_impl.dart';

export '../../data/repositories/habit_repository_impl.dart';

final habitRepositoryProvider = Provider<HabitRepositoryImpl>((ref) {
  return HabitRepositoryImpl(ref.watch(dbProvider));
});

final habitListProvider =
    StateNotifierProvider<HabitListNotifier, AsyncValue<List<HabitWithToday>>>(
  (ref) => HabitListNotifier(ref),
);

final globalStreakProvider = FutureProvider<GlobalStreakStats>((ref) async {
  ref.watch(habitListProvider);
  return ref.watch(habitRepositoryProvider).getGlobalStreakStats();
});

class HabitListNotifier extends StateNotifier<AsyncValue<List<HabitWithToday>>> {
  HabitListNotifier(this._ref) : super(const AsyncLoading()) {
    load();
  }

  final Ref _ref;
  static var _remindersSynced = false;

  HabitRepositoryImpl get _repo => _ref.read(habitRepositoryProvider);
  NotificationService get _notifications =>
      _ref.read(notificationServiceProvider);

  Future<void> load({bool silent = false}) async {
    if (!silent) state = const AsyncLoading();
    try {
      final data = await _repo.getHabitsWithTodayStatus();
      state = AsyncData(data);

      if (!_remindersSynced) {
        _remindersSynced = true;
        final habits = await _ref.read(dbProvider).getAllHabits();
        for (final habit in habits) {
          await _notifications.syncHabitReminder(habit);
        }
      }
    } catch (e, st) {
      state = AsyncError(e, st);
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

    _ref
        .read(habitDetailNotifierProvider(item.habit.id).notifier)
        .applyLogForDate(dateKey, yesNo: yesNo, quantity: quantity);

    try {
      if (item.type == HabitType.yesNo && yesNo != null) {
        await _repo.setYesNoForDate(item.habit.id, dateKey, yesNo);
      } else if (item.type == HabitType.quantitative && quantity != null) {
        await _repo.setQuantitativeForDate(item.habit.id, dateKey, quantity);
      }

      _ref.invalidate(globalStreakProvider);
      await _ref
          .read(habitDetailNotifierProvider(item.habit.id).notifier)
          .refresh();
      if (isToday) {
        await load(silent: true);
      }
    } catch (e) {
      if (isToday) await load(silent: true);
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
        if (yesNo != null) {
          return HabitWithToday(
            habit: h.habit,
            completedToday: yesNo,
            todayValue: h.todayValue,
            currentStreak: h.currentStreak,
          );
        }
        if (quantity != null) {
          final met = quantity >= h.habit.goalValue;
          return HabitWithToday(
            habit: h.habit,
            completedToday: met,
            todayValue: quantity > 0 ? quantity : null,
            currentStreak: h.currentStreak,
          );
        }
        return h;
      }).toList(),
    );
  }

  Future<void> deleteHabit(String id) async {
    await _notifications.cancelHabitReminder(id);
    await _repo.deleteHabit(id);
    _ref.invalidate(globalStreakProvider);
    await load(silent: true);
  }
}

final habitDetailNotifierProvider = StateNotifierProvider.family<
    HabitDetailNotifier, AsyncValue<HabitDetailState?>, String>(
  (ref, id) => HabitDetailNotifier(ref, id),
);

class HabitDetailNotifier extends StateNotifier<AsyncValue<HabitDetailState?>> {
  HabitDetailNotifier(this._ref, this._habitId) : super(const AsyncLoading()) {
    refresh();
  }

  final Ref _ref;
  final String _habitId;

  HabitRepositoryImpl get _repo => _ref.read(habitRepositoryProvider);

  Future<void> refresh() async {
    if (state.valueOrNull == null) {
      state = const AsyncLoading();
    }

    try {
      final habit = await _repo.getHabitById(_habitId);
      if (habit == null) {
        state = const AsyncData(null);
        return;
      }

      final type = HabitType.fromKey(habit.habitType);
      final todayItems = await _repo.getHabitsWithTodayStatus();
      final todayItem = todayItems.firstWhere((h) => h.habit.id == _habitId);

      YesNoHabitReport? yesNoReport;
      QuantitativeHabitReport? quantitativeReport;

      if (type == HabitType.yesNo) {
        yesNoReport = await _repo.getYesNoReport(_habitId);
      } else {
        quantitativeReport = await _repo.getQuantitativeReport(_habitId);
      }

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
      state = AsyncError(e, st);
    }
  }

  Future<void> toggleToday() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (HabitType.fromKey(current.habit.habitType) != HabitType.yesNo) return;

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
    final type = HabitType.fromKey(current.habit.habitType);

    if (type == HabitType.yesNo && yesNo != null && current.yesNoReport != null) {
      final dates = Set<String>.from(current.yesNoReport!.completionDates);
      if (yesNo) {
        dates.add(dateKey);
      } else {
        dates.remove(dateKey);
      }
      state = AsyncData(
        current.copyWith(
          completedToday: isToday ? yesNo : current.completedToday,
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
      final met = quantity > 0 && quantity >= goal;
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
    final isToday = key == HabitDateUtils.todayKey();

    applyLogForDate(key, yesNo: yesNo, quantity: quantity);

    if (yesNo != null) {
      await _repo.setYesNoForDate(_habitId, key, yesNo);
    } else if (quantity != null) {
      await _repo.setQuantitativeForDate(_habitId, key, quantity);
    }

    _ref.invalidate(globalStreakProvider);
    if (isToday) {
      await _ref.read(habitListProvider.notifier).load(silent: true);
    }
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

  final HabitData habit;
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

  String get calendarDatesKey {
    final done = completionDates.toList()..sort();
    final logged = (quantitativeReport?.loggedDates ?? completionDates).toList()
      ..sort();
    return '${done.join('|')}::${logged.join('|')}';
  }
}

final habitFormProvider =
    StateNotifierProvider.autoDispose<HabitFormNotifier, HabitFormState>(
  (ref) => HabitFormNotifier(ref),
);

class HabitFormState {
  const HabitFormState({
    this.habitId,
    this.step = HabitFormStep.pickType,
    this.habitType,
    this.title = '',
    this.description = '',
    this.category = 'Geral',
    this.useCustomCategory = false,
    this.customCategory = '',
    this.goalValue = 1,
    this.unit = '',
    this.reminderEnabled = false,
    this.reminderTime,
    this.isLoading = false,
    this.isSaving = false,
  });

  final String? habitId;
  final HabitFormStep step;
  final HabitType? habitType;
  final String title;
  final String description;
  final String category;
  final bool useCustomCategory;
  final String customCategory;
  final int goalValue;
  final String unit;
  final bool reminderEnabled;
  final DateTime? reminderTime;
  final bool isLoading;
  final bool isSaving;

  bool get isEditing => habitId != null;

  String get resolvedCategory =>
      useCustomCategory ? customCategory.trim() : category;

  HabitFormState copyWith({
    String? habitId,
    HabitFormStep? step,
    HabitType? habitType,
    String? title,
    String? description,
    String? category,
    bool? useCustomCategory,
    String? customCategory,
    int? goalValue,
    String? unit,
    bool? reminderEnabled,
    DateTime? reminderTime,
    bool? isLoading,
    bool? isSaving,
  }) {
    return HabitFormState(
      habitId: habitId ?? this.habitId,
      step: step ?? this.step,
      habitType: habitType ?? this.habitType,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      useCustomCategory: useCustomCategory ?? this.useCustomCategory,
      customCategory: customCategory ?? this.customCategory,
      goalValue: goalValue ?? this.goalValue,
      unit: unit ?? this.unit,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

enum HabitFormStep { pickType, details }

class HabitFormNotifier extends StateNotifier<HabitFormState> {
  HabitFormNotifier(this._ref) : super(const HabitFormState());

  final Ref _ref;

  void selectType(HabitType type) {
    state = state.copyWith(
      habitType: type,
      step: HabitFormStep.details,
      goalValue: type == HabitType.quantitative ? 2 : 1,
      unit: type == HabitType.quantitative ? 'L' : '',
    );
  }

  Future<void> loadForEdit(String habitId) async {
    state = state.copyWith(isLoading: true, habitId: habitId);
    final habit = await _ref.read(habitRepositoryProvider).getHabitById(habitId);
    if (habit == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final type = HabitType.fromKey(habit.habitType);
    final categories = await _ref.read(userSettingsServiceProvider).getAllCategories();
    final isCustom = !defaultCategories.contains(habit.category);

    DateTime? reminderTime;
    if (habit.reminderHour != null && habit.reminderMinute != null) {
      final now = DateTime.now();
      reminderTime = DateTime(
        now.year,
        now.month,
        now.day,
        habit.reminderHour!,
        habit.reminderMinute!,
      );
    }

    state = HabitFormState(
      habitId: habitId,
      step: HabitFormStep.details,
      habitType: type,
      title: habit.title,
      description: habit.description,
      category: isCustom && categories.contains(habit.category)
          ? habit.category
          : (defaultCategories.contains(habit.category) ? habit.category : 'Geral'),
      useCustomCategory: isCustom,
      customCategory: isCustom ? habit.category : '',
      goalValue: habit.goalValue,
      unit: habit.unit ?? '',
      reminderEnabled: habit.reminderEnabled,
      reminderTime: reminderTime,
    );
  }

  void updateTitle(String v) => state = state.copyWith(title: v);
  void updateDescription(String v) => state = state.copyWith(description: v);
  void updateCategory(String v) => state = state.copyWith(category: v);
  void updateUseCustomCategory(bool v) =>
      state = state.copyWith(useCustomCategory: v);
  void updateCustomCategory(String v) =>
      state = state.copyWith(customCategory: v);
  void updateGoalValue(int v) => state = state.copyWith(goalValue: v);
  void updateUnit(String v) => state = state.copyWith(unit: v);
  void updateReminderEnabled(bool v) =>
      state = state.copyWith(reminderEnabled: v);
  void updateReminderTime(DateTime? v) =>
      state = state.copyWith(reminderTime: v);

  Future<bool> save() async {
    if (state.title.trim().isEmpty) return false;
    if (state.habitType == null) return false;

    final category = state.resolvedCategory;
    if (category.isEmpty) return false;

    if (state.habitType == HabitType.quantitative &&
        state.unit.trim().isEmpty) {
      return false;
    }

    state = state.copyWith(isSaving: true);
    final repo = _ref.read(habitRepositoryProvider);
    final notifications = _ref.read(notificationServiceProvider);
    final settings = _ref.read(userSettingsServiceProvider);

    final hour = state.reminderTime?.hour;
    final minute = state.reminderTime?.minute;

    try {
      if (state.useCustomCategory && state.customCategory.trim().isNotEmpty) {
        await settings.addCustomCategory(state.customCategory.trim());
        await _ref.read(categoriesProvider.notifier).reload();
      }

      if (state.isEditing) {
        final existing = await repo.getHabitById(state.habitId!);
        if (existing == null) return false;

        final updated = existing.copyWith(
          title: state.title.trim(),
          description: state.description.trim(),
          category: category,
          habitType: state.habitType!.storageKey,
          unit: Value(
            state.habitType == HabitType.quantitative
                ? state.unit.trim()
                : null,
          ),
          goalValue: state.goalValue,
          reminderEnabled: state.reminderEnabled,
          reminderHour: Value(state.reminderEnabled ? hour : null),
          reminderMinute: Value(state.reminderEnabled ? minute : null),
        );
        await repo.updateHabit(updated);
        await notifications.syncHabitReminder(updated);
      } else {
        final id = const Uuid().v4();
        await repo.createHabit(
          id: id,
          title: state.title.trim(),
          description: state.description.trim(),
          category: category,
          habitType: state.habitType!,
          goalValue: state.goalValue,
          unit: state.habitType == HabitType.quantitative
              ? state.unit.trim()
              : null,
          reminderEnabled: state.reminderEnabled,
          reminderHour: state.reminderEnabled ? hour : null,
          reminderMinute: state.reminderEnabled ? minute : null,
        );
        final created = await repo.getHabitById(id);
        if (created != null) {
          await notifications.syncHabitReminder(created);
        }
      }

      await _ref.read(habitListProvider.notifier).load(silent: true);
      if (state.habitId != null) {
        await _ref
            .read(habitDetailNotifierProvider(state.habitId!).notifier)
            .refresh();
      }
      return true;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}