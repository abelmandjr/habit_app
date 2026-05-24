import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/habit_type.dart';
import '../../../../core/utils/date_utils.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_log_sheet.dart';
import '../widgets/streak_calendar.dart';
import '../widgets/streak_card.dart';

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
          final last7 = _last7DaysData(detail.completionDates);
          final notifier =
              ref.read(habitDetailNotifierProvider(habitId).notifier);
          final listItem = HabitWithToday(
            habit: habit,
            completedToday: detail.completedToday,
            todayValue: detail.todayValue,
          );

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
                onPressed: () {
                  if (type == HabitType.quantitative) {
                    showHabitLogSheet(
                      context: context,
                      item: listItem,
                      onSubmit: (yesNo, quantity) => ref
                          .read(habitListProvider.notifier)
                          .logHabit(listItem, yesNo: yesNo, quantity: quantity),
                    );
                  } else {
                    notifier.toggleToday();
                  }
                },
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
              const SizedBox(height: 20),
              StreakCard(streak: detail.streak),
              const SizedBox(height: 20),
              StreakCalendar(
                key: ValueKey(detail.completionDates.length +
                    (detail.completedToday ? 1 : 0)),
                completionDates: detail.completionDates,
                onDayTap: (day) => notifier.toggleDate(day),
              ),
              const SizedBox(height: 24),
              Text(
                'Últimos 7 dias',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 1.2,
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= last7.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                last7[i].label,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(last7.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: last7[i].done ? 1 : 0.15,
                            color: last7[i].done
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<_DayBar> _last7DaysData(Set<String> dates) {
    final days = HabitDateUtils.lastDays(7);
    const labels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

    return List.generate(7, (i) {
      final day = days[i];
      final key = HabitDateUtils.dateKey(day);
      return _DayBar(
        label: labels[day.weekday % 7],
        done: dates.contains(key),
      );
    });
  }
}

class _DayBar {
  const _DayBar({required this.label, required this.done});
  final String label;
  final bool done;
}
