import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/habit_type.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/user_settings_service.dart';
import '../../../../core/widgets/error_feedback.dart';
import '../providers/habit_provider.dart';
import '../../../../l10n/app_formats.dart';
import '../../../../l10n/app_localizations.dart';
import '../utils/labels.dart';

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
      unawaited(Future.microtask(() async {
        if (!mounted) return;
        final loaded = await runWithErrorFeedback(
          context,
          () => ref.read(habitFormProvider.notifier).loadForEdit(widget.habitId!),
          message: AppLocalizations.of(context).errorLoadHabit,
        );
        if (!mounted) return;
        if (loaded) {
          _syncControllers();
        } else {
          context.pop();
        }
      }));
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
    final l10n = AppLocalizations.of(context);
    final pageTitle = isEditing ? l10n.formEditTitle : l10n.formNewTitle;

    if (form.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(pageTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!isEditing && form.step == HabitFormStep.pickType) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.formNewTitle)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.formTypeQuestion,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.formTypeHelp,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              _TypeCard(
                icon: Icons.check_circle_outline_rounded,
                title: l10n.habitTypeYesNo,
                subtitle: l10n.habitTypeYesNoExamples,
                onTap: () =>
                    ref.read(habitFormProvider.notifier).selectType(HabitType.yesNo),
              ),
              const SizedBox(height: 12),
              _TypeCard(
                icon: Icons.water_drop_outlined,
                title: l10n.habitTypeQuantitative,
                subtitle: l10n.habitTypeQuantitativeExamples,
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
        title: Text(pageTitle),
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
              label: Text(form.habitType!.label(l10n)),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: l10n.formTitleLabel,
              hintText: isQuant
                  ? l10n.formTitleHintQuantitative
                  : l10n.formTitleHintYesNo,
            ),
            textCapitalization: TextCapitalization.sentences,
            onChanged: ref.read(habitFormProvider.notifier).updateTitle,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: l10n.formDescriptionLabel,
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged:
                ref.read(habitFormProvider.notifier).updateDescription,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.formCategory,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.formCustomCategorySwitch),
            value: form.useCustomCategory,
            onChanged: (v) {
              ref.read(habitFormProvider.notifier).updateUseCustomCategory(v);
            },
          ),
          if (form.useCustomCategory)
            TextField(
              controller: _customCategoryController,
              decoration: InputDecoration(
                labelText: l10n.formCustomCategoryLabel,
                hintText: l10n.formCustomCategoryHint,
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
              decoration: InputDecoration(
                labelText: l10n.formUnitLabel,
                hintText: l10n.formUnitHint,
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
                  l10n.formDailyGoal,
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
                  AppFormats.quantity(form.goalValue, form.unit),
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
            title: Text(l10n.formReminder),
            subtitle: Text(l10n.formReminderSubtitle),
            value: form.reminderEnabled,
            onChanged: _onReminderToggled,
          ),
          if (form.reminderEnabled)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time_rounded),
              title: Text(
                form.reminderTime != null
                    ? _formatTime(form.reminderTime!)
                    : l10n.formPickTime,
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
          if (form.reminderEnabled &&
              ref.watch(exactAlarmsAllowedProvider).valueOrNull == false)
            _InexactReminderWarning(onOpenSettings: _openExactAlarmSettings),
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
            label: Text(isEditing ? l10n.formSaveChanges : l10n.formCreate),
          ),
        ],
      ),
    );
  }

  /// A permissão de notificações só é pedida quando se liga um lembrete.
  Future<void> _onReminderToggled(bool enabled) async {
    final notifier = ref.read(habitFormProvider.notifier);
    final l10n = AppLocalizations.of(context);
    if (!enabled) {
      notifier.updateReminderEnabled(false);
      return;
    }

    var granted = false;
    await runWithErrorFeedback(
      context,
      () async => granted =
          await ref.read(notificationServiceProvider).requestPermission(),
      message: l10n.errorRequestNotificationPermission,
    );
    if (!mounted) return;
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notificationPermissionDenied)),
      );
      return;
    }

    notifier.updateReminderEnabled(true);
    if (ref.read(habitFormProvider).reminderTime == null) {
      final now = DateTime.now();
      notifier.updateReminderTime(DateTime(now.year, now.month, now.day, 9, 0));
    }

    await _askForExactAlarms();
  }

  /// Sem alarmes exatos, o lembrete fica ligado em modo inexato e o
  /// formulário mostra um aviso (ver _InexactReminderWarning).
  Future<void> _askForExactAlarms() async {
    final service = ref.read(notificationServiceProvider);
    final l10n = AppLocalizations.of(context);
    var allowed = true;
    await runWithErrorFeedback(
      context,
      () async => allowed = await service.canScheduleExactAlarms(),
      message: l10n.errorCheckAlarmPermission,
    );
    if (allowed || !mounted) return;

    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.exactAlarmTitle),
        content: Text(l10n.exactAlarmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionNotNow),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionOpenSettings),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (open == true) {
      await _openExactAlarmSettings();
    } else {
      ref.invalidate(exactAlarmsAllowedProvider);
    }
  }

  Future<void> _openExactAlarmSettings() async {
    await runWithErrorFeedback(
      context,
      () => ref.read(notificationServiceProvider).openExactAlarmSettings(),
      message: AppLocalizations.of(context).errorOpenSettings,
    );
    if (mounted) ref.invalidate(exactAlarmsAllowedProvider);
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

    final l10n = AppLocalizations.of(context);
    var ok = false;
    final saved = await runWithErrorFeedback(
      context,
      () async => ok = await ref.read(habitFormProvider.notifier).save(),
      message: l10n.errorSaveHabit,
    );
    if (!saved || !mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.habitId != null ? l10n.formUpdated : l10n.formCreated,
          ),
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.formValidation)),
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

/// Aviso mostrado quando o lembrete está ligado mas a app não pode agendar
/// alarmes exatos ("Alarmes e lembretes" desligado).
class _InexactReminderWarning extends StatelessWidget {
  const _InexactReminderWarning({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.exactAlarmWarning,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOpenSettings,
                child: Text(l10n.actionOpenSettings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
