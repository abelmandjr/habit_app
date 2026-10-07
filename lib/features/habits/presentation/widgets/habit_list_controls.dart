import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/habit_list_preferences.dart';
import '../../../../l10n/app_localizations.dart';
import '../utils/labels.dart';

class HabitListControls extends ConsumerWidget {
  const HabitListControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(habitListPreferencesProvider);
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showSortSheet(context, ref, prefs.sortBy),
            icon: const Icon(Icons.sort_rounded, size: 18),
            label: Text(
              prefs.sortBy.label(l10n),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: Text(l10n.hideDone),
          selected: prefs.hideCompleted,
          onSelected: (v) =>
              ref.read(habitListPreferencesProvider.notifier).setHideCompleted(v),
        ),
      ],
    );
  }

  void _showSortSheet(
    BuildContext context,
    WidgetRef ref,
    HabitSortOption current,
  ) {
    unawaited(showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context).sortBy,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ...HabitSortOption.values.map(
              (option) => ListTile(
                leading: Icon(
                  option == current
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                ),
                title: Text(option.label(AppLocalizations.of(context))),
                onTap: () {
                  ref
                      .read(habitListPreferencesProvider.notifier)
                      .setSortBy(option);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ));
  }
}
