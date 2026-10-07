enum HabitType {
  yesNo('yesNo'),
  quantitative('quantitative');

  const HabitType(this.storageKey);

  /// Valor guardado na BD. O texto mostrado vem do ARB (HabitTypeLabel).
  final String storageKey;

  static HabitType fromKey(String key) {
    return HabitType.values.firstWhere(
      (t) => t.storageKey == key,
      orElse: () => HabitType.yesNo,
    );
  }
}
