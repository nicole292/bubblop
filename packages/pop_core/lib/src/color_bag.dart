import 'random.dart';

/// Deals orb colours from a shuffled bag holding every active colour twice,
/// so no colour can disappear for a long stretch.
class ColorBag {
  ColorBag(this._random);

  static const copiesPerColor = 2;

  final SeededRandom _random;
  final List<int> _bag = [];

  /// Next colour. [colorCount] only takes effect when the bag is refilled.
  int next(int colorCount) {
    if (_bag.isEmpty) _refill(colorCount);
    return _bag.removeLast();
  }

  void _refill(int colorCount) {
    for (var color = 0; color < colorCount; color++) {
      for (var i = 0; i < copiesPerColor; i++) {
        _bag.add(color);
      }
    }
    // Fisher–Yates shuffle.
    for (var i = _bag.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final tmp = _bag[i];
      _bag[i] = _bag[j];
      _bag[j] = tmp;
    }
  }
}
