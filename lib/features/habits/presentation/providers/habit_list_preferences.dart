import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O texto mostrado vem do ARB (HabitSortOptionLabel).
enum HabitSortOption { name, category, progress, streak, newest }

class HabitListPreferences {
  const HabitListPreferences({
    this.sortBy = HabitSortOption.name,
    this.hideCompleted = false,
  });

  final HabitSortOption sortBy;
  final bool hideCompleted;

  HabitListPreferences copyWith({
    HabitSortOption? sortBy,
    bool? hideCompleted,
  }) {
    return HabitListPreferences(
      sortBy: sortBy ?? this.sortBy,
      hideCompleted: hideCompleted ?? this.hideCompleted,
    );
  }
}

final habitListPreferencesProvider =
    StateNotifierProvider<HabitListPreferencesNotifier, HabitListPreferences>(
  (ref) => HabitListPreferencesNotifier(),
);

class HabitListPreferencesNotifier extends StateNotifier<HabitListPreferences> {
  HabitListPreferencesNotifier() : super(const HabitListPreferences());

  void setSortBy(HabitSortOption option) => state = state.copyWith(sortBy: option);

  void setHideCompleted(bool value) =>
      state = state.copyWith(hideCompleted: value);
}
