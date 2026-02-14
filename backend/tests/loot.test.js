const {
  generateLoot,
  generateTreasureLoot,
  distributeLoot,
  randomInt,
  pickRandom,
  rollRarity,
  formatLootMessage,
  RARITY,
} = require('../src/game/loot');

// ---------------------------------------------------------------------------
// randomInt
// ---------------------------------------------------------------------------

describe('randomInt', () => {
  test('returns values within range', () => {
    for (let i = 0; i < 100; i++) {
      const val = randomInt(5, 10);
      expect(val).toBeGreaterThanOrEqual(5);
      expect(val).toBeLessThanOrEqual(10);
    }
  });

  test('returns exact value when min equals max', () => {
    expect(randomInt(7, 7)).toBe(7);
  });
});

// ---------------------------------------------------------------------------
// pickRandom
// ---------------------------------------------------------------------------

describe('pickRandom', () => {
  test('returns an element from the array', () => {
    const arr = ['a', 'b', 'c'];
    for (let i = 0; i < 50; i++) {
      expect(arr).toContain(pickRandom(arr));
    }
  });

  test('returns the only element for single-element array', () => {
    expect(pickRandom(['only'])).toBe('only');
  });
});

// ---------------------------------------------------------------------------
// rollRarity
// ---------------------------------------------------------------------------

describe('rollRarity', () => {
  test('returns a valid rarity string', () => {
    const validRarities = Object.values(RARITY);
    for (let i = 0; i < 100; i++) {
      const rarity = rollRarity();
      expect(validRarities).toContain(rarity);
    }
  });
});

// ---------------------------------------------------------------------------
// generateLoot
// ---------------------------------------------------------------------------

describe('generateLoot', () => {
  test('returns object with item, coins, and xp', () => {
    const loot = generateLoot('easy', false);
    expect(loot).toHaveProperty('coins');
    expect(loot).toHaveProperty('xp');
    expect(loot.coins).toBeGreaterThanOrEqual(0);
    expect(loot.xp).toBeGreaterThanOrEqual(0);
  });

  test('boss loot has more coins and xp than normal', () => {
    // Run multiple times to get statistical certainty
    let bossTotal = 0;
    let normalTotal = 0;
    const iterations = 50;

    for (let i = 0; i < iterations; i++) {
      const bossLoot = generateLoot('medium', true);
      const normalLoot = generateLoot('medium', false);
      bossTotal += bossLoot.coins + bossLoot.xp;
      normalTotal += normalLoot.coins + normalLoot.xp;
    }

    expect(bossTotal).toBeGreaterThan(normalTotal);
  });

  test('defaults to easy for invalid difficulty', () => {
    const loot = generateLoot('invalid', false);
    expect(loot).toHaveProperty('coins');
    expect(loot).toHaveProperty('xp');
  });
});

// ---------------------------------------------------------------------------
// generateTreasureLoot
// ---------------------------------------------------------------------------

describe('generateTreasureLoot', () => {
  test('treasure loot always has an item', () => {
    for (let i = 0; i < 20; i++) {
      const loot = generateTreasureLoot('easy');
      expect(loot.item).not.toBeNull();
    }
  });
});

// ---------------------------------------------------------------------------
// distributeLoot
// ---------------------------------------------------------------------------

describe('distributeLoot', () => {
  const loot = { item: { name: 'Espada' }, coins: 100, xp: 50 };

  test('returns empty array for no players', () => {
    expect(distributeLoot(loot, [])).toEqual([]);
    expect(distributeLoot(loot, null)).toEqual([]);
  });

  test('gives all loot to single player', () => {
    const players = [{ id: 'p1', username: 'Hero' }];
    const result = distributeLoot(loot, players);
    expect(result).toHaveLength(1);
    expect(result[0].coins).toBe(100);
    expect(result[0].xp).toBe(50);
    expect(result[0].item).toEqual({ name: 'Espada' });
  });

  test('splits coins and xp equally among players', () => {
    const players = [
      { id: 'p1', username: 'Hero1' },
      { id: 'p2', username: 'Hero2' },
    ];
    const result = distributeLoot(loot, players);
    expect(result).toHaveLength(2);

    const totalCoins = result.reduce((sum, r) => sum + r.coins, 0);
    const totalXp = result.reduce((sum, r) => sum + r.xp, 0);
    expect(totalCoins).toBe(100);
    expect(totalXp).toBe(50);
  });

  test('item goes to exactly one player', () => {
    const players = [
      { id: 'p1', username: 'Hero1' },
      { id: 'p2', username: 'Hero2' },
      { id: 'p3', username: 'Hero3' },
    ];
    const result = distributeLoot(loot, players);
    const itemReceivers = result.filter((r) => r.item !== null);
    expect(itemReceivers).toHaveLength(1);
  });

  test('no item distributed when loot has no item', () => {
    const noItemLoot = { item: null, coins: 50, xp: 25 };
    const players = [
      { id: 'p1', username: 'Hero1' },
      { id: 'p2', username: 'Hero2' },
    ];
    const result = distributeLoot(noItemLoot, players);
    const itemReceivers = result.filter((r) => r.item !== null);
    expect(itemReceivers).toHaveLength(0);
  });
});

// ---------------------------------------------------------------------------
// formatLootMessage
// ---------------------------------------------------------------------------

describe('formatLootMessage', () => {
  test('formats loot with coins and xp', () => {
    const msg = formatLootMessage({ item: null, coins: 50, xp: 30 });
    expect(msg).toContain('50');
    expect(msg).toContain('30');
  });

  test('formats empty loot with cynical message', () => {
    const msg = formatLootMessage({ item: null, coins: 0, xp: 0 });
    expect(msg).toContain('Nada');
  });
});
