/// Model representing a playable race in the RPG
class Race {
  final String name;
  final String description;
  final String spritePath;
  final String bonus; // Human-readable bonus text
  final Map<String, int> statsBonus; // Stat modifications

  const Race({
    required this.name,
    required this.description,
    required this.spritePath,
    required this.bonus,
    required this.statsBonus,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'spritePath': spritePath,
    'bonus': bonus,
    'statsBonus': statsBonus,
  };

  factory Race.fromJson(Map<String, dynamic> json) => Race(
    name: json['name'] as String,
    description: json['description'] as String,
    spritePath: json['spritePath'] as String,
    bonus: json['bonus'] as String,
    statsBonus: Map<String, int>.from(json['statsBonus'] as Map),
  );
}
