import 'package:flutter/material.dart';

/// Mensagens de erro mostradas ao utilizador.
abstract final class ErrorMessages {
  static const saveLog = 'Não foi possível guardar o registo. Tenta novamente.';
  static const deleteHabit =
      'Não foi possível eliminar o hábito. Tenta novamente.';
  static const saveHabit = 'Não foi possível guardar o hábito. Tenta novamente.';
  static const saveName = 'Não foi possível guardar o nome. Tenta novamente.';
  static const loadHabit = 'Não foi possível abrir o hábito.';
  static const loadData = 'Não foi possível carregar os dados.';
}

/// Corre [action] e, se falhar, regista o erro e mostra [message] num SnackBar.
///
/// O ScaffoldMessenger é obtido antes da ação, para a mensagem aparecer mesmo
/// que o widget de origem (um sheet, um item eliminado) já tenha saído da árvore.
/// Devolve `true` se a ação terminou sem erros.
Future<bool> runWithErrorFeedback(
  BuildContext context,
  Future<void> Function() action, {
  required String message,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await action();
    return true;
  } catch (e, st) {
    debugPrint('$message\n$e\n$st');
    if (messenger != null && messenger.mounted) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
    return false;
  }
}

/// Estado de erro de um ecrã, com botão para tentar de novo.
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    required this.onRetry,
    this.message = ErrorMessages.loadData,
  });

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}
