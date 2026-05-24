import 'package:flutter/material.dart';

import '../../../../core/models/habit_type.dart';
import '../../data/repositories/habit_repository_impl.dart';

class HabitTodayTile extends StatelessWidget {
  const HabitTodayTile({
    super.key,
    required this.item,
    required this.onTap,
    this.onToggle,
    this.onQuickLog,
  });

  final HabitWithToday item;
  final VoidCallback onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onQuickLog;

  static const _completedGreen = Color(0xFFE8F5E9);
  static const _completedBorder = Color(0xFF66BB6A);
  static const _pendingSurface = Color(0xFFFFF3E0);
  static const _pendingBorder = Color(0xFFFFB74D);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habit = item.habit;
    final isQuant = item.type == HabitType.quantitative;
    final unit = habit.unit ?? '';
    final done = item.completedToday;

    final bgColor = done ? _completedGreen : _pendingSurface;
    final borderColor = done ? _completedBorder : _pendingBorder;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isQuant ? onQuickLog : onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor.withValues(alpha: 0.85)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              GestureDetector(
                onTap: isQuant ? onQuickLog : onToggle,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: done
                        ? _completedBorder.withValues(alpha: 0.2)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: done ? _completedBorder : _pendingBorder,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    done
                        ? Icons.check_rounded
                        : isQuant
                            ? Icons.water_drop_outlined
                            : Icons.circle_outlined,
                    color: done ? _completedBorder : _pendingBorder,
                  ),
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
                        _Tag(label: habit.category, muted: done),
                        const SizedBox(width: 6),
                        _Tag(
                          label: isQuant
                              ? 'Meta: ${habit.goalValue}$unit'
                              : 'Sim / Não',
                          muted: done,
                        ),
                        if (item.currentStreak > 0) ...[
                          const SizedBox(width: 6),
                          _Tag(
                            label: '🔥 ${item.currentStreak}',
                            muted: done,
                          ),
                        ],
                      ],
                    ),
                    if (isQuant &&
                        item.todayValue != null &&
                        item.todayValue! > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Hoje: ${item.todayValue}${unit.isNotEmpty ? ' $unit' : ''} / ${habit.goalValue}$unit',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: done ? _completedBorder : _pendingBorder,
                            fontWeight: FontWeight.w600,
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
  const _Tag({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface
            .withValues(alpha: muted ? 0.6 : 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
