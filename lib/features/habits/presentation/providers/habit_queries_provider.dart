// Consultas do domínio (estado de hoje, sequências, relatórios).
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/habit_repository_provider.dart';
import '../../domain/services/habit_queries.dart';

final habitQueriesProvider = Provider<HabitQueries>((ref) {
  return HabitQueries(ref.watch(habitRepositoryProvider));
});
