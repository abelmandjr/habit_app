import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HabitSortOption {
  name('Nome'),
  category('Categoria'),
  progress('Progresso hoje'),
  streak('Streak'),
  newest('Mais recentes');

  const HabitSortOption(this.label);
  final String label;
}

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
