import 'dart:ui' show Locale;

/// Língua da app: português de Portugal (decisão 5).
///
/// É `pt_PT`, e não só `pt`, para que os plurais sigam a regra de Portugal
/// (o 0 é plural: "0 dias"); a regra de `pt` é a do Brasil ("0 dia").
const appLocale = Locale('pt', 'PT');
