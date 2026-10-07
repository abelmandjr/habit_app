import '../../../../core/models/habit_type.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/habit_list_preferences.dart';

/// Textos dos enums do domínio, vindos do ARB.
extension HabitTypeLabel on HabitType {
  String label(AppLocalizations l10n) => switch (this) {
        HabitType.yesNo => l10n.habitTypeYesNo,
        HabitType.quantitative => l10n.habitTypeQuantitative,
      };
}

extension HabitSortOptionLabel on HabitSortOption {
  String label(AppLocalizations l10n) => switch (this) {
        HabitSortOption.name => l10n.sortName,
        HabitSortOption.category => l10n.sortCategory,
        HabitSortOption.progress => l10n.sortProgress,
        HabitSortOption.streak => l10n.sortStreak,
        HabitSortOption.newest => l10n.sortNewest,
      };
}
