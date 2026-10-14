/// A small deterministic random number generator (xorshift32).
///
/// We use our own instead of `dart:math` Random so the same seed produces the
/// same game on every device and Dart version. Daily challenges, replays and
/// bug reports depend on that.
class SeededRandom {
  SeededRandom(int seed) : _state = _initialState(seed) {
    // Warm up so that similar seeds (1, 2, 3...) diverge immediately.
    for (var i = 0; i < 8; i++) {
      nextUint32();
    }
  }

  static const _mask = 0xFFFFFFFF;
  int _state;

  static int _initialState(int seed) {
    final s = (seed ^ 0x9E3779B9) & _mask;
    return s == 0 ? 0x6D2B79F5 : s;
  }

  int nextUint32() {
    var x = _state;
    x ^= (x << 13) & _mask;
    x ^= x >> 17;
    x ^= (x << 5) & _mask;
    _state = x;
    return x;
  }

  /// A value in `0 <= value < max`.
  int nextInt(int max) => nextUint32() % max;
}
