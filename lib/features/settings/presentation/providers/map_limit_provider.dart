import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapLimitNotifier extends Notifier<int> {
  static const _limitKey = 'map_markers_limit';

  @override
  int build() {
    _loadLimit();
    return 20; // Límite pertinente por defecto
  }

  Future<void> _loadLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final limit = prefs.getInt(_limitKey) ?? 20;
    state = limit;
  }

  Future<void> updateLimit(int newLimit) async {
    state = newLimit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_limitKey, newLimit);
  }
}

final mapLimitProvider = NotifierProvider<MapLimitNotifier, int>(() {
  return MapLimitNotifier();
});
