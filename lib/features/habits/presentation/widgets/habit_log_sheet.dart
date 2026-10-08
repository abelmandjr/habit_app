import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/models/habit_type.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/error_feedback.dart';
import '../../domain/models/habit_with_today.dart';
import '../../../../l10n/app_formats.dart';
import '../../../../l10n/app_localizations.dart';

/// Bottom sheet para registar hábito (hoje ou data passada).
Future<void> showHabitLogSheet({
  required BuildContext context,
  required HabitWithToday item,
  required Future<void> Function(bool? yesNo, double? quantity) onSubmit,
  DateTime? date,
  bool? completedOnDate,
  double? valueOnDate,
}) {
  final targetDate = date ?? DateTime.now();
  final isToday = HabitDateUtils.dateKey(targetDate) == HabitDateUtils.todayKey();
  final completed = completedOnDate ?? (isToday ? item.completedToday : false);
  final value = valueOnDate ?? (isToday ? item.todayValue : null);

  // O sheet fecha antes de gravar; os erros aparecem no ecrã de origem.
  Future<void> submit(bool? yesNo, double? quantity) => runWithErrorFeedback(
        context,
        () => onSubmit(yesNo, quantity),
        message: AppLocalizations.of(context).errorSaveLog,
      );

  if (item.type == HabitType.yesNo) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _YesNoSheet(
        habitTitle: item.habit.title,
        date: targetDate,
        completedOnDate: completed,
        onSelect: (done) async {
          Navigator.pop(ctx);
          await submit(done, null);
        },
      ),
    );
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _QuantitativeSheet(
      habitTitle: item.habit.title,
      date: targetDate,
      unit: item.habit.unit ?? '',
      goal: item.habit.goalValue,
      currentValue: value,
      onSubmit: (v) async {
        Navigator.pop(ctx);
        await submit(null, v);
      },
    ),
  );
}

class _YesNoSheet extends StatelessWidget {
  const _YesNoSheet({
    required this.habitTitle,
    required this.date,
    required this.completedOnDate,
    required this.onSelect,
  });

  final String habitTitle;
  final DateTime date;
  final bool completedOnDate;
  final Future<void> Function(bool done) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final dateLabel = AppFormats.dayMonthYear(date);
    final isToday =
        HabitDateUtils.dateKey(date) == HabitDateUtils.todayKey();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            habitTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isToday ? l10n.today : dateLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isToday
                ? l10n.logQuestionToday
                : l10n.logPastDay,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onSelect(false),
                  icon: const Icon(Icons.close_rounded),
                  label: Text(l10n.no),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => onSelect(true),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(l10n.yes),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          if (completedOnDate) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => onSelect(false),
              child: Text(l10n.logRemoveDay),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuantitativeSheet extends StatefulWidget {
  const _QuantitativeSheet({
    required this.habitTitle,
    required this.date,
    required this.unit,
    required this.goal,
    required this.currentValue,
    required this.onSubmit,
  });

  final String habitTitle;
  final DateTime date;
  final String unit;
  final int goal;
  final double? currentValue;
  final Future<void> Function(double value) onSubmit;

  @override
  State<_QuantitativeSheet> createState() => _QuantitativeSheetState();
}

class _QuantitativeSheetState extends State<_QuantitativeSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentValue != null && widget.currentValue! > 0
          ? AppFormats.number(widget.currentValue!)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final goal = AppFormats.quantity(widget.goal, widget.unit);
    final isToday =
        HabitDateUtils.dateKey(widget.date) == HabitDateUtils.todayKey();

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.habitTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isToday
                ? l10n.logTodayGoal(goal)
                : l10n.logPastGoal(goal),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              // Vírgula ou ponto decimal (teclados PT mostram vírgula).
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
            ],
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.logValueLabel,
              suffixText: widget.unit.isNotEmpty ? widget.unit : null,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              final parsed = double.tryParse(
                _controller.text.replaceAll(',', '.'),
              );
              if (parsed == null) return;
              await widget.onSubmit(parsed);
            },
            child: Text(l10n.actionSave),
          ),
          if (widget.currentValue != null && widget.currentValue! > 0)
            TextButton(
              onPressed: () async {
                await widget.onSubmit(0);
              },
              child: Text(l10n.logClearDay),
            ),
        ],
      ),
    );
  }
}
