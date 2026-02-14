/// Model representing a character class and its subclasses
class Subclass {
  final String name;
  final String weaponName;
  final String weaponSprite;
  final String ability;
  final String abilityDescription;
  final Map<String, int> statsBonus;

  const Subclass({
    required this.name,
    required this.weaponName,
    required this.weaponSprite,
    required this.ability,
    required this.abilityDescription,
    required this.statsBonus,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'weaponName': weaponName,
    'weaponSprite': weaponSprite,
    'ability': ability,
    'abilityDescription': abilityDescription,
    'statsBonus': statsBonus,
  };

  factory Subclass.fromJson(Map<String, dynamic> json) => Subclass(
    name: json['name'] as String,
    weaponName: json['weaponName'] as String,
    weaponSprite: json['weaponSprite'] as String,
    ability: json['ability'] as String,
    abilityDescription: json['abilityDescription'] as String,
    statsBonus: Map<String, int>.from(json['statsBonus'] as Map),
  );
}

class CharacterClass {
  final String name;
  final String description;
  final String iconPath;
  final Map<String, Subclass> subclasses;

  const CharacterClass({
    required this.name,
    required this.description,
    required this.iconPath,
    required this.subclasses,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'iconPath': iconPath,
    'subclasses': subclasses.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory CharacterClass.fromJson(Map<String, dynamic> json) {
    final subclassesMap = (json['subclasses'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, Subclass.fromJson(v as Map<String, dynamic>)),
    );
    return CharacterClass(
      name: json['name'] as String,
      description: json['description'] as String,
      iconPath: json['iconPath'] as String,
      subclasses: subclassesMap,
    );
  }
}
