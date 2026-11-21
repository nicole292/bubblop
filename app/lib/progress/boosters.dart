/// Helps bought with coins on a level's goal card, used for that one try.
enum Booster {
  /// The bomb starts fully charged.
  bomb('Bomb ready', 'Start with the bomb charged', 40),

  /// Five more drops on a level with a drop limit.
  drops('+5 drops', 'Five extra drops', 30);

  const Booster(this.label, this.about, this.price);

  final String label;
  final String about;
  final int price;

  /// Extra drops this booster gives.
  static const extraDrops = 5;
}
