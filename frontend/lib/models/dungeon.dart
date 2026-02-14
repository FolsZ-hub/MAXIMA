/// Represents a dungeon available for exploration in the MAXIMA RPG.
class Dungeon {
  final String dungeonId;
  final String name;
  final String difficulty; // Facil, Media, Dificil
  final String description;
  final String imagePath;
  final int reward; // Smart Coins reward
  final int minLevel;

  const Dungeon({
    required this.dungeonId,
    required this.name,
    required this.difficulty,
    required this.description,
    this.imagePath = '',
    this.reward = 0,
    this.minLevel = 1,
  });

  /// Creates a [Dungeon] from a Firestore document map.
  factory Dungeon.fromJson(Map<String, dynamic> json) {
    return Dungeon(
      dungeonId: json['dungeonId'] as String? ?? '',
      name: json['name'] as String? ?? 'Mazmorra Desconocida',
      difficulty: json['difficulty'] as String? ?? 'Facil',
      description: json['description'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? '',
      reward: json['reward'] as int? ?? 0,
      minLevel: json['minLevel'] as int? ?? 1,
    );
  }

  /// Converts this [Dungeon] to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'dungeonId': dungeonId,
      'name': name,
      'difficulty': difficulty,
      'description': description,
      'imagePath': imagePath,
      'reward': reward,
      'minLevel': minLevel,
    };
  }

  /// Returns a predefined list of available dungeons.
  static List<Dungeon> getDefaultDungeons() {
    return const [
      Dungeon(
        dungeonId: 'catacumbas_novato',
        name: 'Catacumbas del Novato',
        difficulty: 'Facil',
        description:
            'Un lugar húmedo y oscuro, perfecto para los que recién empiezan '
            'su camino. Esqueletos débiles y trampas simples te esperan.',
        reward: 50,
        minLevel: 1,
      ),
      Dungeon(
        dungeonId: 'laberinto_obsidiana',
        name: 'Laberinto de las Lágrimas de Obsidiana',
        difficulty: 'Media',
        description:
            'Paredes de obsidiana que lloran un líquido oscuro. Criaturas '
            'sombrías acechan en cada esquina. No apto para cobardes.',
        reward: 150,
        minLevel: 5,
      ),
      Dungeon(
        dungeonId: 'abismo_dragon',
        name: 'Abismo del Dragón Negro',
        difficulty: 'Dificil',
        description:
            'Las profundidades donde el Dragón Negro duerme su sueño eterno. '
            'Solo los más valientes y poderosos sobreviven. La muerte permanente acecha.',
        reward: 500,
        minLevel: 10,
      ),
    ];
  }

  @override
  String toString() => 'Dungeon($name, $difficulty, minLv$minLevel)';
}
