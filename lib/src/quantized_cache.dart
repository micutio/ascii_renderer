import 'package:ascii_renderer/src/vector6.dart';

class Quantized6DCache<T> {
  final Map<int, T> _cache = {};
  static const int _steps = 15; // 4 bits per dimension (0..15)

  int _generateKey(Vector6 v) {
    int key = 0;
    for (int i = 0; i < 6; i++) {
      final q = (v[i] * _steps).round().clamp(0, _steps);
      key |= (q << (i * 4)); // Shift into 4-bit slots
    }
    return key;
  }

  T getOrFind(Vector6 target, T Function(Vector6) fallbackSearch) {
    final key = _generateKey(target);

    // Fast O(1) path
    final cached = _cache[key];
    if (cached != null) return cached;

    // Fallback path: Execute K-D tree search or linear search
    final result = fallbackSearch(target);
    _cache[key] = result;
    return result;
  }

  void clear() => _cache.clear();
}
