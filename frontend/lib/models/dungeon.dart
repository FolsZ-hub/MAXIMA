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
        dungeonId: 'catacumbas_del_novato',
        name: 'Catacumbas del Novato',
        difficulty: 'easy',
        description:
            'Un lugar húmedo y oscuro, perfecto para los que recién empiezan '
            'su camino. Esqueletos débiles y trampas simples te esperan.',
        reward: 50,
        minLevel: 1,
      ),
      Dungeon(
        dungeonId: 'laberinto_obsidiana',
        name: 'Laberinto de las Lágrimas de Obsidiana',
        difficulty: 'medium',
        description:
            'Paredes de obsidiana que lloran un líquido oscuro. Criaturas '
            'sombrías acechan en cada esquina. No apto para cobardes.',
        reward: 150,
        minLevel: 5,
      ),
      Dungeon(
        dungeonId: 'abismo_dragon_negro',
        name: 'Abismo del Dragón Negro',
        difficulty: 'hard',
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

/// Represents a path connecting one room to another in a dungeon.
class DungeonPath {
  final int targetRoomIndex;
  final String description;

  const DungeonPath({
    required this.targetRoomIndex,
    required this.description,
  });

  factory DungeonPath.fromJson(Map<String, dynamic> json) {
    return DungeonPath(
      targetRoomIndex: json['targetRoomIndex'] as int? ?? 0,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetRoomIndex': targetRoomIndex,
      'description': description,
    };
  }
}

/// Represents a trap found inside a dungeon room.
class DungeonTrap {
  final String name;
  final int damage;
  final String type; // physical, magic, fire

  const DungeonTrap({
    required this.name,
    required this.damage,
    required this.type,
  });

  factory DungeonTrap.fromJson(Map<String, dynamic> json) {
    return DungeonTrap(
      name: json['name'] as String? ?? '',
      damage: json['damage'] as int? ?? 0,
      type: json['type'] as String? ?? 'physical',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'damage': damage,
      'type': type,
    };
  }
}

/// Represents a merchant that can appear inside a dungeon room.
class DungeonMerchant {
  final String name;
  final String greeting;
  final List<Map<String, dynamic>> items;
  final int itemCount;

  const DungeonMerchant({
    required this.name,
    required this.greeting,
    required this.items,
    required this.itemCount,
  });

  factory DungeonMerchant.fromJson(Map<String, dynamic> json) {
    return DungeonMerchant(
      name: json['name'] as String? ?? '',
      greeting: json['greeting'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      itemCount: json['itemCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'greeting': greeting,
      'items': items,
      'itemCount': itemCount,
    };
  }
}

/// Represents a single room inside a dungeon.
class DungeonRoom {
  final String id;
  final int index;
  final String type; // corridor, treasure, trap, merchant, boss, puzzle, rest
  final String description;
  final List<Map<String, dynamic>> enemies;
  final Map<String, dynamic>? loot;
  final DungeonTrap? trap;
  final DungeonMerchant? merchant;
  final Map<String, dynamic>? puzzle;
  final bool isRest;
  final int? healAmount;
  final List<DungeonPath> paths;

  const DungeonRoom({
    required this.id,
    required this.index,
    required this.type,
    required this.description,
    this.enemies = const [],
    this.loot,
    this.trap,
    this.merchant,
    this.puzzle,
    this.isRest = false,
    this.healAmount,
    this.paths = const [],
  });

  factory DungeonRoom.fromJson(Map<String, dynamic> json) {
    return DungeonRoom(
      id: json['id'] as String? ?? '',
      index: json['index'] as int? ?? 0,
      type: json['type'] as String? ?? 'corridor',
      description: json['description'] as String? ?? '',
      enemies: (json['enemies'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      loot: json['loot'] != null
          ? Map<String, dynamic>.from(json['loot'] as Map)
          : null,
      trap: json['trap'] != null
          ? DungeonTrap.fromJson(
              Map<String, dynamic>.from(json['trap'] as Map))
          : null,
      merchant: json['merchant'] != null
          ? DungeonMerchant.fromJson(
              Map<String, dynamic>.from(json['merchant'] as Map))
          : null,
      puzzle: json['puzzle'] != null
          ? Map<String, dynamic>.from(json['puzzle'] as Map)
          : null,
      isRest: json['isRest'] as bool? ?? false,
      healAmount: json['healAmount'] as int?,
      paths: (json['paths'] as List<dynamic>?)
              ?.map((e) => DungeonPath.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'index': index,
      'type': type,
      'description': description,
      'enemies': enemies,
      if (loot != null) 'loot': loot,
      if (trap != null) 'trap': trap!.toJson(),
      if (merchant != null) 'merchant': merchant!.toJson(),
      if (puzzle != null) 'puzzle': puzzle,
      'isRest': isRest,
      if (healAmount != null) 'healAmount': healAmount,
      'paths': paths.map((p) => p.toJson()).toList(),
    };
  }
}

/// Tracks the exploration state of a dungeon session.
class DungeonState {
  final String dungeonId;
  final String name;
  final String difficulty;
  final List<DungeonRoom> rooms;
  int currentRoom;
  bool completed;
  final String? createdAt;

  DungeonState({
    required this.dungeonId,
    required this.name,
    required this.difficulty,
    required this.rooms,
    this.currentRoom = 0,
    this.completed = false,
    this.createdAt,
  });

  factory DungeonState.fromJson(Map<String, dynamic> json) {
    return DungeonState(
      dungeonId: json['dungeonId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'easy',
      rooms: (json['rooms'] as List<dynamic>?)
              ?.map((e) => DungeonRoom.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      currentRoom: json['currentRoom'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dungeonId': dungeonId,
      'name': name,
      'difficulty': difficulty,
      'rooms': rooms.map((r) => r.toJson()).toList(),
      'currentRoom': currentRoom,
      'completed': completed,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}
