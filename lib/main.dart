import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/notification_service.dart';
import 'core/providers/database_provider.dart';
import 'core/routes/app_router.dart';
import 'core/theme/light_theme.dart';

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

  @override
  void initState() {
    super.initState();
    // onShow (e não onResume): dispara quando a app volta a ficar visível,
    // mesmo que a janela ainda não tenha foco (no dispositivo, voltar à app
    // pode ficar em `inactive` sem passar a `resumed`).
    _lifecycle = AppLifecycleListener(
      onShow: () => unawaited(_onReturn()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// Ao voltar à app (ex.: das definições "Alarmes e lembretes"), reagenda os
  /// lembretes se a permissão de alarmes exatos mudou.
  Future<void> _onReturn() async {
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
