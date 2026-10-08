import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/utils/streak_calculator.dart';
import '../../../../l10n/app_localizations.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.streak});

  final StreakStats streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.local_fire_department_rounded,
                iconColor: Colors.orange,
                label: l10n.streakCurrent,
                value: '${streak.currentStreak}',
                unit: l10n.dayUnit(streak.currentStreak),
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
                label: l10n.streakBest,
                value: '${streak.bestStreak}',
                unit: l10n.dayUnit(streak.bestStreak),
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
                label: l10n.streakTotal,
                value: '${streak.totalCompletions}',
                unit: l10n.dayUnit(streak.totalCompletions),
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
