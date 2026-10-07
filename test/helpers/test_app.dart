import 'package:flutter/material.dart';
import 'package:habit_app/l10n/app_localizations.dart';
import 'package:habit_app/main.dart' show appLocale;

/// `MaterialApp` com as localizações da app (PT-PT), para testes de ecrãs.
Widget testApp(Widget home) => MaterialApp(
      locale: appLocale,
      supportedLocales: const [appLocale],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );

/// Textos da app, para comparar nos testes sem os repetir.
final testL10n = lookupAppLocalizations(const Locale('pt'));
