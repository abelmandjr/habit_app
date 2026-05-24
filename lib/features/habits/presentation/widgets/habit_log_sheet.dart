import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/models/habit_type.dart';
import '../../data/repositories/habit_repository_impl.dart';

/// Bottom sheet para marcar hábito sim/não ou quantitativo.
Future<void> showHabitLogSheet({
  required BuildContext context,
  required HabitWithToday item,
  required Future<void> Function(bool? yesNo, double? quantity) onSubmit,
}) {
  if (item.type == HabitType.yesNo) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _YesNoSheet(
        habitTitle: item.habit.title,
        completedToday: item.completedToday,
        onSelect: (done) async {
          Navigator.pop(ctx);
          await onSubmit(done, null);
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
      unit: item.habit.unit ?? '',
      goal: item.habit.goalValue,
      currentValue: item.todayValue,
      onSubmit: (value) async {
        Navigator.pop(ctx);
        await onSubmit(null, value);
      },
    ),
  );
}

class _YesNoSheet extends StatelessWidget {
  const _YesNoSheet({
    required this.habitTitle,
    required this.completedToday,
    required this.onSelect,
  });

  final String habitTitle;
  final bool completedToday;
  final Future<void> Function(bool done) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          const SizedBox(height: 8),
          Text(
            'Você fez este hábito hoje?',
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
                  label: const Text('Não'),
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
                  label: const Text('Sim'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          if (completedToday) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => onSelect(false),
              child: const Text('Desmarcar conclusão'),
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
    required this.unit,
    required this.goal,
    required this.currentValue,
    required this.onSubmit,
  });

  final String habitTitle;
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
          ? _formatValue(widget.currentValue!)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatValue(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = widget.unit.isNotEmpty ? ' ${widget.unit}' : '';

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
            'Meta diária: ${widget.goal}$unit',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Valor atingido hoje',
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
            child: const Text('Salvar'),
          ),
          if (widget.currentValue != null && widget.currentValue! > 0)
            TextButton(
              onPressed: () async {
                await widget.onSubmit(0);
              },
              child: const Text('Limpar registro de hoje'),
            ),
        ],
      ),
    );
  }
}
