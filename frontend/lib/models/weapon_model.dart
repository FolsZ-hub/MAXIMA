/// Model representing a weapon in the RPG
class Weapon {
  final String name;
  final String sprite;
  final String damage;
  final String? effect;
  final String rarity; // common, uncommon, rare, legendary

  const Weapon({
    required this.name,
    required this.sprite,
    required this.damage,
    this.effect,
    this.rarity = 'common',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'sprite': sprite,
    'damage': damage,
    'effect': effect,
    'rarity': rarity,
  };

  factory Weapon.fromJson(Map<String, dynamic> json) => Weapon(
    name: json['name'] as String,
    sprite: json['sprite'] as String,
    damage: json['damage'] as String,
    effect: json['effect'] as String?,
    rarity: json['rarity'] as String? ?? 'common',
  );
}
