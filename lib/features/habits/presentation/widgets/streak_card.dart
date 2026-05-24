import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/utils/streak_calculator.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.streak});

  final StreakStats streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.local_fire_department_rounded,
                iconColor: Colors.orange,
                label: 'Sequência atual',
                value: '${streak.currentStreak}',
                unit: streak.currentStreak == 1 ? 'dia' : 'dias',
              ),
            ),
            Container(
              width: 1,
              height: 48,
              color: theme.dividerColor,
            ),
            Expanded(
              child: _StatTile(
                icon: Icons.emoji_events_rounded,
                iconColor: Colors.amber,
                label: 'Melhor sequência',
                value: '${streak.bestStreak}',
                unit: streak.bestStreak == 1 ? 'dia' : 'dias',
              ),
            ),
            Container(
              width: 1,
              height: 48,
              color: theme.dividerColor,
            ),
            Expanded(
              child: _StatTile(
                icon: Icons.check_circle_outline_rounded,
                iconColor: theme.colorScheme.primary,
                label: 'Total',
                value: '${streak.totalCompletions}',
                unit: 'dias',
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
