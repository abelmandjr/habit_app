import '../../data/repositories/habit_repository_impl.dart';
import '../providers/habit_list_preferences.dart';

List<HabitWithToday> applyHabitListPreferences(
  List<HabitWithToday> items,
  HabitListPreferences prefs,
) {
  var list = List<HabitWithToday>.from(items);

  if (prefs.hideCompleted) {
    list = list.where((h) => !h.completedToday).toList();
  }

  list.sort((a, b) {
    switch (prefs.sortBy) {
      case HabitSortOption.name:
        return a.habit.title.toLowerCase().compareTo(b.habit.title.toLowerCase());
      case HabitSortOption.category:
        final c = a.habit.category.toLowerCase().compareTo(
              b.habit.category.toLowerCase(),
            );
        return c != 0 ? c : a.habit.title.compareTo(b.habit.title);
      case HabitSortOption.progress:
        return b.progressRatio.compareTo(a.progressRatio);
      case HabitSortOption.streak:
        return b.currentStreak.compareTo(a.currentStreak);
      case HabitSortOption.newest:
        return b.habit.createdAt.compareTo(a.habit.createdAt);
    }
  });

  return list;
}
