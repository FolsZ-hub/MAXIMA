const {
  ROOM_TYPES,
  generateRoom,
  generateDungeon,
  getPredefinedDungeon,
  listPredefinedDungeons,
  PREDEFINED_DUNGEONS,
  DIFFICULTY_CONFIG,
} = require('../src/game/dungeon');

// ---------------------------------------------------------------------------
// generateDungeon
// ---------------------------------------------------------------------------

describe('generateDungeon', () => {
  test('easy dungeon has 5 rooms', () => {
    const dungeon = generateDungeon('easy');
    expect(dungeon.rooms).toHaveLength(5);
    expect(dungeon.difficulty).toBe('easy');
  });

  test('medium dungeon has 8 rooms', () => {
    const dungeon = generateDungeon('medium');
    expect(dungeon.rooms).toHaveLength(8);
    expect(dungeon.difficulty).toBe('medium');
  });

  test('hard dungeon has 12 rooms', () => {
    const dungeon = generateDungeon('hard');
    expect(dungeon.rooms).toHaveLength(12);
    expect(dungeon.difficulty).toBe('hard');
  });

  test('first room is always a corridor', () => {
    for (let i = 0; i < 10; i++) {
      const dungeon = generateDungeon('easy');
      expect(dungeon.rooms[0].type).toBe(ROOM_TYPES.CORRIDOR);
    }
  });

  test('last room is BOSS for medium difficulty', () => {
    for (let i = 0; i < 10; i++) {
      const dungeon = generateDungeon('medium');
      const lastRoom = dungeon.rooms[dungeon.rooms.length - 1];
      expect(lastRoom.type).toBe(ROOM_TYPES.BOSS);
    }
  });

  test('last room is BOSS for hard difficulty', () => {
    for (let i = 0; i < 10; i++) {
      const dungeon = generateDungeon('hard');
      const lastRoom = dungeon.rooms[dungeon.rooms.length - 1];
      expect(lastRoom.type).toBe(ROOM_TYPES.BOSS);
    }
  });

  test('defaults to easy for invalid difficulty', () => {
    const dungeon = generateDungeon('invalid');
    expect(dungeon.rooms).toHaveLength(5);
    expect(dungeon.difficulty).toBe('easy');
  });

  test('all rooms are reachable from room 0 (BFS connectivity)', () => {
    // Run multiple times due to randomness
    for (let trial = 0; trial < 20; trial++) {
      const dungeon = generateDungeon('medium');
      const visited = new Set();
      const queue = [0];
      visited.add(0);

      while (queue.length > 0) {
        const current = queue.shift();
        const room = dungeon.rooms[current];
        if (room.paths) {
          for (const path of room.paths) {
            if (!visited.has(path.targetRoomIndex)) {
              visited.add(path.targetRoomIndex);
              queue.push(path.targetRoomIndex);
            }
          }
        }
      }

      // All rooms should be reachable
      expect(visited.size).toBe(dungeon.rooms.length);
    }
  });
});

// ---------------------------------------------------------------------------
// generateRoom
// ---------------------------------------------------------------------------

describe('generateRoom', () => {
  test('non-last room always has path to next room', () => {
    for (let i = 0; i < 50; i++) {
      const room = generateRoom(ROOM_TYPES.CORRIDOR, 'easy', 2, 10);
      const targets = room.paths.map((p) => p.targetRoomIndex);
      expect(targets).toContain(3); // Must include roomIndex + 1
    }
  });

  test('last room has no paths', () => {
    const room = generateRoom(ROOM_TYPES.BOSS, 'easy', 4, 5);
    expect(room.paths).toHaveLength(0);
  });

  test('room has correct type', () => {
    const room = generateRoom(ROOM_TYPES.TREASURE, 'medium', 1, 5);
    expect(room.type).toBe(ROOM_TYPES.TREASURE);
  });

  test('trap room has trap data', () => {
    const room = generateRoom(ROOM_TYPES.TRAP, 'medium', 1, 5);
    expect(room.trap).not.toBeNull();
    expect(room.trap.name).toBeTruthy();
    expect(room.trap.damage).toBeGreaterThan(0);
  });

  test('boss room has enemies and loot', () => {
    const room = generateRoom(ROOM_TYPES.BOSS, 'hard', 1, 5);
    expect(room.enemies.length).toBeGreaterThan(0);
    expect(room.enemies[0].isBoss).toBe(true);
    expect(room.loot).not.toBeNull();
  });

  test('rest room has healAmount', () => {
    const room = generateRoom(ROOM_TYPES.REST, 'easy', 1, 5);
    expect(room.isRest).toBe(true);
    expect(room.healAmount).toBeGreaterThan(0);
  });

  test('merchant room has merchant data', () => {
    const room = generateRoom(ROOM_TYPES.MERCHANT, 'medium', 1, 5);
    expect(room.merchant).not.toBeNull();
    expect(room.merchant.name).toBeTruthy();
    expect(room.merchant.items.length).toBeGreaterThan(0);
  });
});

// ---------------------------------------------------------------------------
// Predefined dungeons
// ---------------------------------------------------------------------------

describe('predefined dungeons', () => {
  test('getPredefinedDungeon returns valid dungeon for known IDs', () => {
    const dungeon = getPredefinedDungeon('catacumbas_del_novato');
    expect(dungeon).not.toBeNull();
    expect(dungeon.name).toBe('Catacumbas del Novato');
    expect(dungeon.difficulty).toBe('easy');
  });

  test('getPredefinedDungeon returns null for unknown ID', () => {
    expect(getPredefinedDungeon('inexistente')).toBeNull();
  });

  test('all predefined dungeons are listed', () => {
    const list = listPredefinedDungeons();
    expect(list.length).toBe(Object.keys(PREDEFINED_DUNGEONS).length);
  });

  test('predefined dungeon IDs match expected values', () => {
    const ids = Object.keys(PREDEFINED_DUNGEONS);
    expect(ids).toContain('catacumbas_del_novato');
    expect(ids).toContain('laberinto_obsidiana');
    expect(ids).toContain('abismo_dragon_negro');
  });

  test('returns deep copy (not reference)', () => {
    const d1 = getPredefinedDungeon('catacumbas_del_novato');
    const d2 = getPredefinedDungeon('catacumbas_del_novato');
    d1.name = 'modified';
    expect(d2.name).toBe('Catacumbas del Novato');
  });
});
