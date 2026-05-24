enum HabitType {
  yesNo('yesNo', 'Sim ou não'),
  quantitative('quantitative', 'Quantitativo');

  const HabitType(this.storageKey, this.label);

  final String storageKey;
  final String label;

  static HabitType fromKey(String key) {
    return HabitType.values.firstWhere(
      (t) => t.storageKey == key,
      orElse: () => HabitType.yesNo,
    );
  }
}
