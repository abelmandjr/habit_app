import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../providers/database_provider.dart';

const defaultCategories = [
  'Geral',
  'Saúde',
  'Fitness',
  'Estudo',
  'Trabalho',
  'Mindfulness',
];

final userSettingsServiceProvider = Provider<UserSettingsService>((ref) {
  return UserSettingsService(ref.watch(dbProvider));
});

final userNameProvider = StateNotifierProvider<UserNameNotifier, String>(
  (ref) => UserNameNotifier(ref.watch(userSettingsServiceProvider)),
);

class UserNameNotifier extends StateNotifier<String> {
  UserNameNotifier(this._service) : super('') {
    _load();
  }

  final UserSettingsService _service;

  Future<void> _load() async {
    state = await _service.getUserName();
  }

  Future<void> setName(String name) async {
    final trimmed = name.trim();
    await _service.setUserName(trimmed);
    state = trimmed;
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<String>>(
  (ref) => CategoriesNotifier(ref.watch(userSettingsServiceProvider)),
);

class CategoriesNotifier extends StateNotifier<List<String>> {
  CategoriesNotifier(this._service) : super(defaultCategories) {
    _load();
  }

  final UserSettingsService _service;

  Future<void> _load() async {
    state = await _service.getAllCategories();
  }

  Future<void> reload() async {
    state = await _service.getAllCategories();
  }

  Future<void> addCustom(String category) async {
    await _service.addCustomCategory(category);
    await reload();
  }
}

class UserSettingsService {
  UserSettingsService(this._db);

  final AppDatabase _db;

  Future<String> getUserName() => _db.getUserName();

  Future<void> setUserName(String name) => _db.setUserName(name);

  Future<List<String>> getCustomCategories() => _db.getCustomCategories();

  Future<List<String>> getAllCategories() async {
    final custom = await getCustomCategories();
    return [...defaultCategories, ...custom];
  }

  Future<void> addCustomCategory(String category) async {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;

    final custom = await getCustomCategories();
    final all = await getAllCategories();
    if (all.any((c) => c.toLowerCase() == trimmed.toLowerCase())) return;

    custom.add(trimmed);
    await _db.setCustomCategories(custom);
  }
}
