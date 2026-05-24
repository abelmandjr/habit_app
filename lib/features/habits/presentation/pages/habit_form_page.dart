import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/habit_type.dart';
import '../../../../core/storage/user_settings_service.dart';
import '../providers/habit_provider.dart';

class HabitFormPage extends ConsumerStatefulWidget {
  const HabitFormPage({super.key, this.habitId});

  final String? habitId;

  @override
  ConsumerState<HabitFormPage> createState() => _HabitFormPageState();
}

class _HabitFormPageState extends ConsumerState<HabitFormPage> {
  static const _unitSuggestions = ['L', 'ml', 'kg', 'g', 'km', 'm', 'min', 'h'];

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _customCategoryController;
  late final TextEditingController _unitController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _customCategoryController = TextEditingController();
    _unitController = TextEditingController();

    if (widget.habitId != null) {
      Future.microtask(() async {
        await ref.read(habitFormProvider.notifier).loadForEdit(widget.habitId!);
        _syncControllers();
      });
    }
  }

  void _syncControllers() {
    final form = ref.read(habitFormProvider);
    _titleController.text = form.title;
    _descriptionController.text = form.description;
    _customCategoryController.text = form.customCategory;
    _unitController.text = form.unit;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(habitFormProvider);
    final categories = ref.watch(categoriesProvider);
    final isEditing = widget.habitId != null;

    if (form.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(isEditing ? 'Editar hábito' : 'Novo hábito')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!isEditing && form.step == HabitFormStep.pickType) {
      return Scaffold(
        appBar: AppBar(title: const Text('Novo hábito')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Qual o tipo de hábito?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Escolha como você vai registrar este hábito no dia a dia.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              _TypeCard(
                icon: Icons.check_circle_outline_rounded,
                title: 'Sim ou não',
                subtitle: 'Ex: meditar, tomar remédio, ler',
                onTap: () =>
                    ref.read(habitFormProvider.notifier).selectType(HabitType.yesNo),
              ),
              const SizedBox(height: 12),
              _TypeCard(
                icon: Icons.water_drop_outlined,
                title: 'Quantitativo',
                subtitle: 'Ex: beber água, caminhar, estudar horas',
                onTap: () => ref
                    .read(habitFormProvider.notifier)
                    .selectType(HabitType.quantitative),
              ),
            ],
          ),
        ),
      );
    }

    final isQuant = form.habitType == HabitType.quantitative;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar hábito' : 'Novo hábito'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (form.habitType != null)
            Chip(
              avatar: Icon(
                isQuant ? Icons.water_drop_outlined : Icons.check_rounded,
                size: 18,
              ),
              label: Text(form.habitType!.label),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Título',
              hintText: isQuant ? 'Ex: Beber água' : 'Ex: Meditar',
            ),
            textCapitalization: TextCapitalization.sentences,
            onChanged: ref.read(habitFormProvider.notifier).updateTitle,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Descrição (opcional)',
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged:
                ref.read(habitFormProvider.notifier).updateDescription,
          ),
          const SizedBox(height: 16),
          Text(
            'Categoria',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Criar categoria personalizada'),
            value: form.useCustomCategory,
            onChanged: (v) {
              ref.read(habitFormProvider.notifier).updateUseCustomCategory(v);
            },
          ),
          if (form.useCustomCategory)
            TextField(
              controller: _customCategoryController,
              decoration: const InputDecoration(
                labelText: 'Sua categoria',
                hintText: 'Ex: Espiritual, Finanças',
              ),
              textCapitalization: TextCapitalization.words,
              onChanged:
                  ref.read(habitFormProvider.notifier).updateCustomCategory,
            )
          else
            DropdownButtonFormField<String>(
              initialValue: categories.contains(form.category)
                  ? form.category
                  : categories.first,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  ref.read(habitFormProvider.notifier).updateCategory(v);
                }
              },
            ),
          const SizedBox(height: 16),
          if (isQuant) ...[
            TextField(
              controller: _unitController,
              decoration: const InputDecoration(
                labelText: 'Unidade',
                hintText: 'Ex: L, kg, min',
              ),
              onChanged: ref.read(habitFormProvider.notifier).updateUnit,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _unitSuggestions.map((u) {
                return ActionChip(
                  label: Text(u),
                  onPressed: () {
                    _unitController.text = u;
                    ref.read(habitFormProvider.notifier).updateUnit(u);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Meta diária',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: form.goalValue > 1
                      ? () => ref
                          .read(habitFormProvider.notifier)
                          .updateGoalValue(form.goalValue - 1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '${form.goalValue}${form.unit.isNotEmpty ? ' ${form.unit}' : ''}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: () => ref
                      .read(habitFormProvider.notifier)
                      .updateGoalValue(form.goalValue + 1),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
          const Divider(height: 32),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Lembrete diário'),
            subtitle: const Text('Notificação no horário escolhido'),
            value: form.reminderEnabled,
            onChanged: (v) {
              ref.read(habitFormProvider.notifier).updateReminderEnabled(v);
              if (v && form.reminderTime == null) {
                final now = DateTime.now();
                ref.read(habitFormProvider.notifier).updateReminderTime(
                      DateTime(now.year, now.month, now.day, 9, 0),
                    );
              }
            },
          ),
          if (form.reminderEnabled)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time_rounded),
              title: Text(
                form.reminderTime != null
                    ? _formatTime(form.reminderTime!)
                    : 'Escolher horário',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final initial = form.reminderTime ?? DateTime.now();
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(initial),
                );
                if (picked != null) {
                  ref.read(habitFormProvider.notifier).updateReminderTime(
                        DateTime(
                          initial.year,
                          initial.month,
                          initial.day,
                          picked.hour,
                          picked.minute,
                        ),
                      );
                }
              },
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: form.isSaving ? null : _save,
            icon: form.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(isEditing ? 'Salvar alterações' : 'Criar hábito'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _save() async {
    ref.read(habitFormProvider.notifier).updateTitle(_titleController.text);
    ref
        .read(habitFormProvider.notifier)
        .updateDescription(_descriptionController.text);
    ref
        .read(habitFormProvider.notifier)
        .updateCustomCategory(_customCategoryController.text);
    ref.read(habitFormProvider.notifier).updateUnit(_unitController.text);

    final ok = await ref.read(habitFormProvider.notifier).save();
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.habitId != null ? 'Hábito atualizado' : 'Hábito criado',
          ),
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha título, categoria e unidade (se quantitativo)',
          ),
        ),
      );
    }
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
