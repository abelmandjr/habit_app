import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/habit_type.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_log_sheet.dart';
import '../widgets/habit_report_section.dart';

class HabitDetailPage extends ConsumerWidget {
  const HabitDetailPage({super.key, required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(habitDetailNotifierProvider(habitId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes'),
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
                    title: const Text('Excluir hábito?'),
                    content: const Text(
                      'Todo o histórico será apagado. Esta ação não pode ser desfeita.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Excluir'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await ref.read(habitListProvider.notifier).deleteHabit(habitId);
                  if (context.mounted) context.go('/');
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('Excluir hábito'),
              ),
            ],
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Hábito não encontrado'));
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
                          ? 'Meta: ${habit.goalValue}$unit/dia'
                          : 'Sim / Não',
                    ),
                  ),
                  if (habit.reminderEnabled)
                    const Chip(
                      avatar: Icon(Icons.notifications_active, size: 16),
                      label: Text('Lembrete ativo'),
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
                          ? 'Atualizar registro de hoje'
                          : 'Registrar valor de hoje')
                      : detail.completedToday
                          ? 'Concluído hoje'
                          : 'Marcar como feito hoje',
                ),
              ),
              const SizedBox(height: 24),
              HabitReportSection(
                key: ValueKey(
                  '${detail.completedToday}_${detail.todayValue}_${detail.yesNoReport?.daysDone}_${detail.quantitativeReport?.todayValue}',
                ),
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
