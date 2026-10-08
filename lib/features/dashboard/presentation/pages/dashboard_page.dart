import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/habit_type.dart';
import '../../../../core/utils/habit_report_calculator.dart';
import '../../../habits/presentation/providers/habit_list_preferences.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../habits/presentation/utils/habit_list_utils.dart';
import '../../../habits/presentation/widgets/habit_list_controls.dart';
import '../../../habits/presentation/widgets/habit_log_sheet.dart';
import '../../../habits/presentation/widgets/habit_today_tile.dart';
import '../../../habits/presentation/widgets/global_streak_banner.dart';
import '../../../habits/presentation/widgets/today_summary_card.dart';
import '../../../../core/storage/user_settings_service.dart';
import '../../../../core/widgets/error_feedback.dart';
import '../../../../l10n/app_formats.dart';
import '../../../../l10n/app_localizations.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsState = ref.watch(habitListProvider);
    final listPrefs = ref.watch(habitListPreferencesProvider);
    final userName = ref.watch(userNameProvider);
    final globalStreak = ref.watch(globalStreakProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/habits/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.dashboardNewHabit),
      ),
      body: habitsState.when(
        data: (items) {
          final completed = items.where((h) => h.completedToday).length;
          final visibleItems =
              applyHabitListPreferences(items, listPrefs);

          return RefreshIndicator(
            onRefresh: () => ref.read(habitListProvider.notifier).load(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  title: Text(l10n.dashboardTitle),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.person_outline_rounded),
                      tooltip: l10n.dashboardEditName,
                      onPressed: () => _editName(context, ref, userName),
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Text(
                        _greeting(l10n, userName),
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppFormats.weekdayDayMonth(DateTime.now()),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      globalStreak.when(
                        data: (stats) => GlobalStreakBanner(stats: stats),
                        loading: () => const GlobalStreakBanner(
                          stats: GlobalStreakStats(
                            currentStreak: 0,
                            bestStreak: 0,
                          ),
                        ),
                        error: (_, _) => const GlobalStreakBanner(
                          stats: GlobalStreakStats(
                            currentStreak: 0,
                            bestStreak: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (items.isEmpty)
                        _EmptyState(onCreate: () => context.push('/habits/new'))
                      else ...[
                        TodaySummaryCard(
                          completed: completed,
                          total: items.length,
                        ),
                        const SizedBox(height: 16),
                        const HabitListControls(),
                        const SizedBox(height: 16),
                        Text(
                          l10n.today,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.dashboardHint,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 12),
                        if (visibleItems.isEmpty && items.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              l10n.dashboardAllDone,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          )
                        else
                          ...visibleItems.map((item) => _DismissibleHabitCard(
                                item: item,
                                ref: ref,
                                onDetails: () =>
                                    context.push('/habits/${item.habit.id}'),
                                onDelete: () => runWithErrorFeedback(
                                  context,
                                  () => ref
                                      .read(habitListProvider.notifier)
                                      .deleteHabit(item.habit.id),
                                  message: l10n.errorDeleteHabit,
                                ),
                              )),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorRetryView(
          message: l10n.errorLoadHabits,
          onRetry: () => ref.read(habitListProvider.notifier).load(),
        ),
      ),
    );
  }

  String _greeting(AppLocalizations l10n, String name) {
    final hour = DateTime.now().hour;
    final period = hour < 12
        ? l10n.greetingMorning
        : hour < 18
            ? l10n.greetingAfternoon
            : l10n.greetingEvening;
    final who = name.trim();
    return who.isEmpty
        ? l10n.greetingWithoutName(period)
        : l10n.greetingWithName(period, who);
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.nameDialogTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.nameDialogHint,
            border: const OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    if (result != null) {
      if (!context.mounted) return;
      await runWithErrorFeedback(
        context,
        () => ref.read(userNameProvider.notifier).setName(result),
        message: l10n.errorSaveName,
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.self_improvement_rounded,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.emptyTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.emptyMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.formCreate),
          ),
        ],
      ),
    );
  }
}

class _DismissibleHabitCard extends StatelessWidget {
  const _DismissibleHabitCard({
    required this.item,
    required this.ref,
    required this.onDetails,
    required this.onDelete,
  });

  final HabitWithToday item;
  final WidgetRef ref;
  final VoidCallback onDetails;

  /// Elimina o hábito e devolve `true` se correu bem.
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(item.habit.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        // A eliminação corre aqui e não no onDismissed: o cartão só é dado
        // como dispensado se a eliminação resultar. Se falhar, volta ao lugar
        // (evita "dismissed Dismissible still in tree" no rollback).
        confirmDismiss: (_) async {
          final l10n = AppLocalizations.of(context);
          final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.deleteHabitTitle),
                  content: Text(l10n.deleteHabitMessage(item.habit.title)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.actionCancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.actionDelete),
                    ),
                  ],
                ),
              ) ??
              false;
          if (!confirmed) return false;
          return onDelete();
        },
        child: HabitTodayTile(
          item: item,
          onTap: onDetails,
          onToggle: item.type == HabitType.yesNo
              ? () => runWithErrorFeedback(
                    context,
                    () => ref.read(habitListProvider.notifier).logHabit(
                          item,
                          yesNo: !item.completedToday,
                        ),
                    message: AppLocalizations.of(context).errorSaveLog,
                  )
              : null,
          onQuickLog: () => showHabitLogSheet(
            context: context,
            item: item,
            onSubmit: (yesNo, quantity) => ref
                .read(habitListProvider.notifier)
                .logHabit(item, yesNo: yesNo, quantity: quantity),
          ),
        ),
      ),
    );
  }
}
