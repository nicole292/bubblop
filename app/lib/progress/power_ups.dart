import 'dart:ui';

/// Helps bought with coins in the shop and kept until used. Each one is
/// used from the power-up bar under the board while playing.
enum PowerUp {
  /// A bomb ready to drop, even before the bomb meter is full.
  bomb('Bomb', 'Blast a 3×3 square wherever you drop it', 50, Color(0xFFFF8A1A)),

  /// Pops every ball of the next ball's colour at once.
  rainbow('Rainbow pop', 'Pop every ball of your next colour at once', 80, Color(0xFFB04CFF)),

  /// No rising rows for a few drops.
  freeze('Freeze', 'No new rows for the next $freezeDrops drops', 40, Color(0xFF2EB8F0)),

  /// More drops on a level with a drop limit.
  drops('+$extraDrops drops', '$extraDrops more drops on a level with a drop limit', 30, Color(0xFF3D7BFF));

  const PowerUp(this.label, this.about, this.price, this.color);

  final String label;
  final String about;
  final int price;
  final Color color;

  static const freezeDrops = 5;
  static const extraDrops = 5;

  /// The most of one power-up you can carry.
  static const maxStock = 99;
}
