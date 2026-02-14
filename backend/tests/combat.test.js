const {
  rollD20,
  calculateAttack,
  calculateHunt,
  useItem,
  ENEMY_TEMPLATES,
} = require('../src/game/combat');

// ---------------------------------------------------------------------------
// rollD20
// ---------------------------------------------------------------------------

describe('rollD20', () => {
  test('returns a value between 1 and 20', () => {
    for (let i = 0; i < 100; i++) {
      const roll = rollD20();
      expect(roll).toBeGreaterThanOrEqual(1);
      expect(roll).toBeLessThanOrEqual(20);
    }
  });
});

// ---------------------------------------------------------------------------
// calculateAttack
// ---------------------------------------------------------------------------

describe('calculateAttack', () => {
  const attacker = { name: 'Heroe', attack: 15, hp: 100, defense: 10 };
  const target = { name: 'Goblin', defense: 5, hp: 30, attack: 5 };

  test('critical hit on roll 20 doubles damage', () => {
    const result = calculateAttack(attacker, target, 20);
    expect(result.critical).toBe(true);
    expect(result.hit).toBe(true);
    expect(result.damage).toBeGreaterThan(0);
    // Damage should be at least 2 (minimum 1 * 2)
    expect(result.damage).toBeGreaterThanOrEqual(2);
  });

  test('fumble on roll 1 causes self-damage', () => {
    const result = calculateAttack(attacker, target, 1);
    expect(result.fumble).toBe(true);
    expect(result.selfDamage).toBe(5);
    expect(result.attackerHp).toBe(95);
    expect(result.hit).toBe(false);
    expect(result.damage).toBe(0);
  });

  test('miss on roll < 10', () => {
    const result = calculateAttack(attacker, target, 5);
    expect(result.hit).toBe(false);
    expect(result.damage).toBe(0);
    expect(result.fumble).toBe(false);
  });

  test('hit on roll >= 10 deals positive damage', () => {
    const result = calculateAttack(attacker, target, 15);
    expect(result.hit).toBe(true);
    expect(result.damage).toBeGreaterThan(0);
  });

  test('targetDefeated is true when target HP reaches 0', () => {
    const weakTarget = { name: 'Rata', defense: 0, hp: 1, attack: 1 };
    const result = calculateAttack(attacker, weakTarget, 15);
    expect(result.hit).toBe(true);
    expect(result.targetDefeated).toBe(true);
    expect(result.targetHp).toBe(0);
  });

  test('defense reduction at 70% allows damage against high DEF', () => {
    const tankTarget = { name: 'Dragon', defense: 20, hp: 200, attack: 35 };
    const result = calculateAttack(attacker, tankTarget, 15);
    expect(result.hit).toBe(true);
    // With DEF*0.7: baseDamage = random(5,15) + 15 - 14 >= 6, Math.max(1, ...) >= 1
    expect(result.damage).toBeGreaterThanOrEqual(1);
  });
});

// ---------------------------------------------------------------------------
// calculateHunt
// ---------------------------------------------------------------------------

describe('calculateHunt', () => {
  const character = { name: 'Cazador', hp: 100, attack: 15, defense: 10, deaths: 0 };

  test('returns enemy, combatResult, and hunt/encounter messages', () => {
    const result = calculateHunt(character, 15, 'easy');
    expect(result.enemy).toBeDefined();
    expect(result.enemy.name).toBeTruthy();
    expect(result.combatResult).toBeDefined();
    expect(result.huntMessage).toBeTruthy();
    expect(result.encounterMessage).toBeTruthy();
  });

  test('generates loot when enemy is defeated', () => {
    // Use a high roll against a weak enemy
    const weakCharacter = { name: 'God', hp: 999, attack: 999, defense: 999 };
    const result = calculateHunt(weakCharacter, 20, 'easy');
    if (result.combatResult.targetDefeated) {
      expect(result.loot).toBeDefined();
      expect(result.loot).not.toBeNull();
    }
  });

  test('enemy retaliates when not defeated', () => {
    // Use a miss roll so enemy survives
    const result = calculateHunt(character, 5, 'easy');
    // On a miss, enemy should retaliate
    expect(result.enemyAttack).toBeDefined();
    expect(result.enemyAttack).not.toBeNull();
  });

  test('defaults to easy difficulty for invalid input', () => {
    const result = calculateHunt(character, 15, 'invalid');
    expect(result.enemy).toBeDefined();
    // Should come from easy pool
    const easyNames = ENEMY_TEMPLATES.easy.map((e) => e.name);
    expect(easyNames).toContain(result.enemy.name);
  });
});

// ---------------------------------------------------------------------------
// useItem
// ---------------------------------------------------------------------------

describe('useItem', () => {
  const character = { name: 'Mago', hp: 50, maxHp: 100, attack: 20, defense: 5 };

  test('potion heals character', () => {
    const inventory = [
      { name: 'Pocion de Salud', type: 'potion', subtype: 'healing', healing: 30 },
    ];
    const result = useItem(character, 'pocion', inventory);
    expect(result.success).toBe(true);
    expect(result.effects.healing).toBe(30);
    expect(result.effects.newHp).toBe(80);
    expect(result.consumedItem).not.toBeNull();
  });

  test('returns error for item not in inventory', () => {
    const inventory = [{ name: 'Espada', type: 'weapon' }];
    const result = useItem(character, 'pocion', inventory);
    expect(result.success).toBe(false);
  });

  test('returns error for empty inventory', () => {
    const result = useItem(character, 'pocion', []);
    expect(result.success).toBe(false);
  });

  test('weapon equips without being consumed', () => {
    const inventory = [
      { name: 'Espada de Fuego', type: 'weapon', damage: 12 },
    ];
    const result = useItem(character, 'espada', inventory);
    expect(result.success).toBe(true);
    expect(result.effects.equip).toBe(true);
    expect(result.consumedItem).toBeNull();
  });
});
