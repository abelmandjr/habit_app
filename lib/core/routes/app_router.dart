import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/habits/presentation/pages/habit_detail_page.dart';
import '../../features/habits/presentation/pages/habit_form_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/habits/new',
      builder: (context, state) => const HabitFormPage(),
    ),
    GoRoute(
      path: '/habits/:id',
      builder: (context, state) => HabitDetailPage(
        habitId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/habits/:id/edit',
      builder: (context, state) => HabitFormPage(
        habitId: state.pathParameters['id'],
      ),
    ),
  ],
);
