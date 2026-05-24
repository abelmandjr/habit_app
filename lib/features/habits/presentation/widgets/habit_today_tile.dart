import 'package:flutter/material.dart';

import '../../../../core/models/habit_type.dart';
import '../../data/repositories/habit_repository_impl.dart';

class HabitTodayTile extends StatelessWidget {
  const HabitTodayTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onQuickLog,
  });

  final HabitWithToday item;
  final VoidCallback onTap;
  final VoidCallback onQuickLog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habit = item.habit;
    final isQuant = item.type == HabitType.quantitative;
    final unit = habit.unit ?? '';

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onQuickLog,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.completedToday
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.completedToday
                      ? Icons.check_rounded
                      : isQuant
                          ? Icons.water_drop_outlined
                          : Icons.task_alt_outlined,
                  color: item.completedToday
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Tag(label: habit.category),
                        const SizedBox(width: 6),
                        _Tag(
                          label: isQuant
                              ? 'Meta: ${habit.goalValue}$unit'
                              : 'Sim / Não',
                        ),
                      ],
                    ),
                    if (isQuant && item.todayValue != null && item.todayValue! > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Hoje: ${item.todayValue}${unit.isNotEmpty ? ' $unit' : ''} / ${habit.goalValue}$unit',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: item.completedToday
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onTap,
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Ver detalhes',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
