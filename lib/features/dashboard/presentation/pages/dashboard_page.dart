import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../habits/presentation/widgets/habit_log_sheet.dart';
import '../../../habits/presentation/widgets/habit_today_tile.dart';
import '../../../habits/presentation/widgets/today_summary_card.dart';
import '../../../../core/storage/user_settings_service.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsState = ref.watch(habitListProvider);
    final userName = ref.watch(userNameProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/habits/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo hábito'),
      ),
      body: habitsState.when(
        data: (items) {
          final completed = items.where((h) => h.completedToday).length;

          return RefreshIndicator(
            onRefresh: () => ref.read(habitListProvider.notifier).load(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  title: const Text('Hábitos'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.person_outline_rounded),
                      tooltip: 'Editar nome',
                      onPressed: () => _editName(context, ref, userName),
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Text(
                        _greeting(userName),
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _subtitle(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 20),
                      if (items.isEmpty)
                        _EmptyState(onCreate: () => context.push('/habits/new'))
                      else ...[
                        TodaySummaryCard(
                          completed: completed,
                          total: items.length,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Hoje',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toque no hábito para registrar. Deslize para excluir.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 12),
                        ...items.map((item) => _DismissibleHabitCard(
                              item: item,
                              onDetails: () =>
                                  context.push('/habits/${item.habit.id}'),
                              onLog: () => showHabitLogSheet(
                                context: context,
                                item: item,
                                onSubmit: (yesNo, quantity) => ref
                                    .read(habitListProvider.notifier)
                                    .logHabit(item, yesNo: yesNo, quantity: quantity),
                              ),
                              onDelete: () => ref
                                  .read(habitListProvider.notifier)
                                  .deleteHabit(item.habit.id),
                            )),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
      ),
    );
  }

  String _greeting(String name) {
    final hour = DateTime.now().hour;
    final period = hour < 12
        ? 'Bom dia'
        : hour < 18
            ? 'Boa tarde'
            : 'Boa noite';
  final who = name.trim().isEmpty ? '' : ', ${name.trim()}';
    return '$period$who 👋';
  }

  String _subtitle() {
    final now = DateTime.now();
    const days = [
      'domingo',
      'segunda-feira',
      'terça-feira',
      'quarta-feira',
      'quinta-feira',
      'sexta-feira',
      'sábado',
    ];
    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return '${days[now.weekday % 7]}, ${now.day} de ${months[now.month - 1]}';
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seu nome'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Como devemos te chamar?',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (result != null) {
      await ref.read(userNameProvider.notifier).setName(result);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.self_improvement_rounded,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum hábito ainda',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Crie seu primeiro hábito e acompanhe seu progresso diário.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Criar hábito'),
          ),
        ],
      ),
    );
  }
}

class _DismissibleHabitCard extends StatelessWidget {
  const _DismissibleHabitCard({
    required this.item,
    required this.onDetails,
    required this.onLog,
    required this.onDelete,
  });

  final HabitWithToday item;
  final VoidCallback onDetails;
  final VoidCallback onLog;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(item.habit.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Excluir hábito?'),
                  content: Text(
                    'Deseja excluir "${item.habit.title}"? Todo o histórico será apagado.',
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
              ) ??
              false;
        },
        onDismissed: (_) => onDelete(),
        child: HabitTodayTile(
          item: item,
          onTap: onDetails,
          onQuickLog: onLog,
        ),
      ),
    );
  }
}
