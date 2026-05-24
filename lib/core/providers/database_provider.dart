import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

final dbProvider = Provider<AppDatabase>((ref) => AppDatabase());
