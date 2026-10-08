import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../domain/repositories/habit_repository.dart';
import 'repositories/drift_habit_repository.dart';

/// Implementação do [HabitRepository] usada pela app (BD local, Drift).
/// Nos testes substitui-se com `habitRepositoryProvider.overrideWithValue`.
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return DriftHabitRepository(ref.watch(dbProvider));
});
