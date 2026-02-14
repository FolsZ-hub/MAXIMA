/// Represents a playable character in the MAXIMA RPG.
class Character {
  final String characterId;
  final String playerId;
  String name;
  String characterClass; // Guerrero, Mago, Ladronzuelo, Clerigo
  int level;
  int hp;
  int maxHp;
  int xp;
  int attack;
  int defense;
  List<Map<String, dynamic>> inventory;
  bool isAlive;

  Character({
    required this.characterId,
    required this.playerId,
    required this.name,
    required this.characterClass,
    this.level = 1,
    this.hp = 100,
    this.maxHp = 100,
    this.xp = 0,
    this.attack = 10,
    this.defense = 5,
    List<Map<String, dynamic>>? inventory,
    this.isAlive = true,
  }) : inventory = inventory ?? [];

  /// Creates a [Character] from a Firestore document map.
  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      characterId: json['characterId'] as String? ?? '',
      playerId: json['playerId'] as String? ?? '',
      name: json['name'] as String? ?? 'Sin Nombre',
      characterClass: json['characterClass'] as String? ?? 'Guerrero',
      level: json['level'] as int? ?? 1,
      hp: json['hp'] as int? ?? 100,
      maxHp: json['maxHp'] as int? ?? 100,
      xp: json['xp'] as int? ?? 0,
      attack: json['attack'] as int? ?? 10,
      defense: json['defense'] as int? ?? 5,
      inventory: (json['inventory'] as List<dynamic>?)
              ?.map((item) => Map<String, dynamic>.from(item as Map))
              .toList() ??
          [],
      isAlive: json['isAlive'] as bool? ?? true,
    );
  }

  /// Converts this [Character] to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'characterId': characterId,
      'playerId': playerId,
      'name': name,
      'characterClass': characterClass,
      'level': level,
      'hp': hp,
      'maxHp': maxHp,
      'xp': xp,
      'attack': attack,
      'defense': defense,
      'inventory': inventory,
      'isAlive': isAlive,
    };
  }

  /// Returns the XP required to reach the next level.
  int get xpToNextLevel => level * 100;

  /// Returns the XP progress as a value between 0.0 and 1.0.
  double get xpProgress => xp / xpToNextLevel;

  /// Returns the HP fraction as a value between 0.0 and 1.0.
  double get hpFraction => maxHp > 0 ? hp / maxHp : 0.0;

  /// Creates a copy with optional overrides.
  Character copyWith({
    String? characterId,
    String? playerId,
    String? name,
    String? characterClass,
    int? level,
    int? hp,
    int? maxHp,
    int? xp,
    int? attack,
    int? defense,
    List<Map<String, dynamic>>? inventory,
    bool? isAlive,
  }) {
    return Character(
      characterId: characterId ?? this.characterId,
      playerId: playerId ?? this.playerId,
      name: name ?? this.name,
      characterClass: characterClass ?? this.characterClass,
      level: level ?? this.level,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      xp: xp ?? this.xp,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      inventory: inventory ?? this.inventory,
      isAlive: isAlive ?? this.isAlive,
    );
  }

  @override
  String toString() =>
      'Character($name, $characterClass, Lv$level, HP:$hp/$maxHp)';
}
