// Estado do formulário de criar/editar hábito.
import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/habit_type.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/user_settings_service.dart';
import '../../data/habit_repository_provider.dart';
import '../../domain/entities/habit.dart';
import '../../domain/habit_reminders.dart';
import 'habit_detail_provider.dart';
import 'habit_list_provider.dart';

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
    final habit = await _ref.read(habitRepositoryProvider).getHabit(habitId);
    if (habit == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final type = habit.type;
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
    final isQuantitative = state.habitType == HabitType.quantitative;

    try {
      if (state.useCustomCategory && state.customCategory.trim().isNotEmpty) {
        await settings.addCustomCategory(state.customCategory.trim());
        await _ref.read(categoriesProvider.notifier).reload();
      }

      if (state.isEditing) {
        final existing = await repo.getHabit(state.habitId!);
        if (existing == null) return false;

        final updated = existing.copyWith(
          title: state.title.trim(),
          description: state.description.trim(),
          category: category,
          type: state.habitType!,
          unit: isQuantitative ? state.unit.trim() : null,
          goalValue: state.goalValue,
          reminderEnabled: state.reminderEnabled,
          reminderHour: state.reminderEnabled ? hour : null,
          reminderMinute: state.reminderEnabled ? minute : null,
        );
        await repo.updateHabit(updated);
        await notifications.syncHabitReminder(updated.reminder);
      } else {
        final created = Habit(
          id: const Uuid().v4(),
          title: state.title.trim(),
          description: state.description.trim(),
          category: category,
          type: state.habitType!,
          goalValue: state.goalValue,
          unit: isQuantitative ? state.unit.trim() : null,
          reminderEnabled: state.reminderEnabled,
          reminderHour: state.reminderEnabled ? hour : null,
          reminderMinute: state.reminderEnabled ? minute : null,
          createdAt: clock.now(),
        );
        await repo.createHabit(created);
        await notifications.syncHabitReminder(created.reminder);
      }

      await _ref.read(habitListProvider.notifier).load(silent: true);
      if (state.habitId != null) {
        await openHabitDetail(_ref, state.habitId!)?.refresh();
      }
      return true;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}