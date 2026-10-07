import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/notification_service.dart';
import 'core/providers/database_provider.dart';
import 'core/routes/app_router.dart';
import 'core/theme/light_theme.dart';
import 'core/utils/date_utils.dart';
import 'features/habits/presentation/providers/habit_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final AppLifecycleListener _lifecycle;

  /// Dia mostrado como "hoje"; muda à meia-noite ou ao voltar à app.
  late String _dayKey;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _dayKey = HabitDateUtils.todayKey();
    _scheduleMidnightTimer();
    // onShow (e não onResume): dispara quando a app volta a ficar visível,
    // mesmo que a janela ainda não tenha foco (no dispositivo, voltar à app
    // pode ficar em `inactive` sem passar a `resumed`).
    _lifecycle = AppLifecycleListener(
      onShow: () => unawaited(_onReturn()),
      onHide: () => _midnightTimer?.cancel(),
    );
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  /// Com a app visível, passa para o novo dia logo depois da meia-noite.
  void _scheduleMidnightTimer() {
    _midnightTimer?.cancel();
    _midnightTimer = Timer(
      HabitDateUtils.untilNextDay(clock.now()) + const Duration(seconds: 1),
      () {
        _checkDayChange();
        _scheduleMidnightTimer();
      },
    );
  }

  /// Se o dia mudou, recarrega a lista e os detalhes para o novo "hoje".
  void _checkDayChange() {
    final today = HabitDateUtils.todayKey();
    if (today == _dayKey) return;
    _dayKey = today;
    unawaited(ref.read(habitListProvider.notifier).load(silent: true));
    ref.invalidate(habitDetailNotifierProvider);
  }

  /// Ao voltar à app: passa para o novo dia, se mudou, e reagenda os
  /// lembretes se a permissão de alarmes exatos mudou (ex.: ao voltar das
  /// definições "Alarmes e lembretes").
  Future<void> _onReturn() async {
    _checkDayChange();
    _scheduleMidnightTimer();
    try {
      await ref
          .read(notificationServiceProvider)
          .syncExactAlarmPermission(ref.read(dbProvider));
    } catch (e) {
      debugPrint('Falha ao verificar alarmes exatos: $e');
    }
    if (mounted) ref.invalidate(exactAlarmsAllowedProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      routerConfig: appRouter,
    );
  }
}
