import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

final ThemeData lightTheme = FlexThemeData.light(
  scheme: FlexScheme.indigo,
  useMaterial3: true,
  subThemesData: const FlexSubThemesData(
    defaultRadius: 24,
    cardRadius: 24,
    inputDecoratorRadius: 16,
    elevatedButtonRadius: 18,
  ),
);