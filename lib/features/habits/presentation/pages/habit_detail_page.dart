import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/habit_type.dart';
import '../../../../core/widgets/error_feedback.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_log_sheet.dart';
import '../widgets/habit_report_section.dart';
import '../../../../l10n/app_formats.dart';
import '../../../../l10n/app_localizations.dart';

class HabitDetailPage extends ConsumerWidget {
  const HabitDetailPage({super.key, required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(habitListProvider);
    final detailAsync = ref.watch(habitDetailNotifierProvider(habitId));
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.detailTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push('/habits/$habitId/edit'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.deleteHabitTitle),
                    content: Text(l10n.deleteHabitMessageGeneric),
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
                );
                if (confirm == true && context.mounted) {
                  final deleted = await runWithErrorFeedback(
                    context,
                    () => ref
                        .read(habitListProvider.notifier)
                        .deleteHabit(habitId),
                    message: l10n.errorDeleteHabit,
                  );
                  if (deleted && context.mounted) context.go('/');
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete',
                child: Text(l10n.detailDeleteMenu),
              ),
            ],
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorRetryView(
          message: l10n.errorLoadHabitDetail,
          onRetry: () =>
              ref.read(habitDetailNotifierProvider(habitId).notifier).refresh(),
        ),
        data: (detail) {
          if (detail == null) {
            return Center(child: Text(l10n.detailNotFound));
          }

          final habit = detail.habit;
          final type = HabitType.fromKey(habit.habitType);
          final unit = habit.unit ?? '';
          final notifier =
              ref.read(habitDetailNotifierProvider(habitId).notifier);
          final repo = ref.read(habitRepositoryProvider);
          final listItem = HabitWithToday(
            habit: habit,
            completedToday: detail.completedToday,
            todayValue: detail.todayValue,
          );

          Future<void> openLogForDay(DateTime day) async {
            final completed = await repo.isCompletedOnDate(habitId, day);
            final value = await repo.getValueForDate(habitId, day);
            if (!context.mounted) return;
            await showHabitLogSheet(
              context: context,
              item: listItem,
              date: day,
              completedOnDate: completed,
              valueOnDate: value,
              onSubmit: (yesNo, quantity) => notifier.logForDate(
                day,
                yesNo: yesNo,
                quantity: quantity,
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                habit.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (habit.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  habit.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(habit.category)),
                  Chip(
                    label: Text(
                      type == HabitType.quantitative
                          ? l10n.goalPerDay(
                              AppFormats.quantity(habit.goalValue, unit),
                            )
                          : l10n.yesNoTag,
                    ),
                  ),
                  if (habit.reminderEnabled)
                    Chip(
                      avatar: const Icon(Icons.notifications_active, size: 16),
                      label: Text(l10n.reminderActive),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () => openLogForDay(DateTime.now()),
                icon: Icon(
                  detail.completedToday
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                ),
                label: Text(
                  type == HabitType.quantitative
                      ? (detail.todayValue != null && detail.todayValue! > 0
                          ? l10n.logUpdateToday
                          : l10n.logValueToday)
                      : detail.completedToday
                          ? l10n.doneToday
                          : l10n.markDoneToday,
                ),
              ),
              const SizedBox(height: 24),
              HabitReportSection(
                type: type,
                unit: unit,
                goalValue: habit.goalValue,
                habitCreatedAt: habit.createdAt,
                yesNoReport: detail.yesNoReport,
                quantitativeReport: detail.quantitativeReport,
                onDayTap: openLogForDay,
              ),
            ],
          );
        },
      ),
    );
  }
}
