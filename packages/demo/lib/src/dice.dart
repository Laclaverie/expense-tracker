/// Seeded randomness of the made-up household: the same seed lives the same
/// life on every machine and every Dart version (xorshift64*, not
/// `dart:math`'s `Random`, whose sequence may change between SDKs).
class Dice {
  Dice(int seed) : _state = (seed * 0x9E3779B97F4A7C15) | 1;

  int _state;

  int _next() {
    var x = _state;
    x ^= x >>> 12;
    x ^= x << 25;
    x ^= x >>> 27;
    _state = x;
    return x * 0x2545F4914F6CDD1D;
  }

  /// In [0, 1).
  double unit() => (_next() >>> 11) / 9007199254740992.0;

  /// Between [min] and [max], both included.
  int range(int min, int max) => min + (unit() * (max - min + 1)).floor();

  bool chance(double p) => unit() < p;

  T pick<T>(List<T> items) => items[range(0, items.length - 1)];

  /// Roughly normal, mean 0, standard deviation 1 (sum of uniforms).
  double normal() {
    var s = 0.0;
    for (var i = 0; i < 12; i++) {
      s += unit();
    }
    return s - 6;
  }

  /// [typical] cents with a relative spread, never below a fifth of it.
  int around(int typical, double spread) {
    final v = (typical * (1 + spread * normal())).round();
    return v < typical ~/ 5 ? typical ~/ 5 : v;
  }
}
