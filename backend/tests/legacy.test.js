const {
  RETURNING_COST,
  XP_BONUS_PER_DEATH,
  getLegacyBonus,
  applyLegacyXpBonus,
  activateReturning,
  processCharacterDeath,
} = require('../src/game/legacy');

// ---------------------------------------------------------------------------
// getLegacyBonus
// ---------------------------------------------------------------------------

describe('getLegacyBonus', () => {
  test('0 deaths gives 0% XP bonus', () => {
    const result = getLegacyBonus({ deaths: 0 });
    expect(result.xpBonusPercent).toBe(0);
    expect(result.totalDeaths).toBe(0);
  });

  test('3 deaths gives 30% XP bonus', () => {
    const result = getLegacyBonus({ deaths: 3 });
    expect(result.xpBonusPercent).toBe(30);
    expect(result.totalDeaths).toBe(3);
  });

  test('10 deaths gives 100% XP bonus', () => {
    const result = getLegacyBonus({ deaths: 10 });
    expect(result.xpBonusPercent).toBe(100);
  });

  test('includes description text', () => {
    const result = getLegacyBonus({ deaths: 5 });
    expect(result.description).toBeTruthy();
    expect(typeof result.description).toBe('string');
  });

  test('nextRevivalCost equals RETURNING_COST', () => {
    const result = getLegacyBonus({ deaths: 1 });
    expect(result.nextRevivalCost).toBe(RETURNING_COST);
  });
});

// ---------------------------------------------------------------------------
// applyLegacyXpBonus
// ---------------------------------------------------------------------------

describe('applyLegacyXpBonus', () => {
  test('applies correct bonus for 2 deaths', () => {
    const result = applyLegacyXpBonus(100, { deaths: 2 });
    expect(result.baseXp).toBe(100);
    expect(result.bonusXp).toBe(20); // 20% of 100
    expect(result.totalXp).toBe(120);
    expect(result.bonusPercent).toBe(20);
  });

  test('no bonus for 0 deaths', () => {
    const result = applyLegacyXpBonus(100, { deaths: 0 });
    expect(result.bonusXp).toBe(0);
    expect(result.totalXp).toBe(100);
  });

  test('handles missing deaths field', () => {
    const result = applyLegacyXpBonus(50, {});
    expect(result.bonusXp).toBe(0);
    expect(result.totalXp).toBe(50);
  });
});

// ---------------------------------------------------------------------------
// activateReturning
// ---------------------------------------------------------------------------

describe('activateReturning', () => {
  const deadCharacter = {
    name: 'Thalric',
    hp: 0,
    maxHp: 100,
    deaths: 1,
    alive: false,
    inventory: [
      { name: 'Espada' },
      { name: 'Pocion' },
      { name: 'Escudo' },
      { name: 'Pergamino' },
    ],
  };

  test('succeeds with sufficient Smart Coins', () => {
    const player = { smartCoins: 10 };
    const result = activateReturning(player, deadCharacter);
    expect(result.success).toBe(true);
    expect(result.character).not.toBeNull();
    expect(result.character.alive).toBe(true);
    expect(result.character.hp).toBeGreaterThan(0);
    expect(result.smartCoinsSpent).toBe(RETURNING_COST);
  });

  test('fails with insufficient Smart Coins', () => {
    const player = { smartCoins: 2 };
    const result = activateReturning(player, deadCharacter);
    expect(result.success).toBe(false);
    expect(result.character).toBeNull();
  });

  test('fails if character is alive', () => {
    const player = { smartCoins: 10 };
    const aliveCharacter = { ...deadCharacter, hp: 50, alive: true };
    const result = activateReturning(player, aliveCharacter);
    expect(result.success).toBe(false);
  });

  test('retains approximately 50% of inventory', () => {
    const player = { smartCoins: 10 };
    const result = activateReturning(player, deadCharacter);
    expect(result.success).toBe(true);
    // With 4 items and 50% retention: ceil(4 * 0.5) = 2
    expect(result.inventoryRetained).toHaveLength(2);
    expect(result.inventoryLost).toHaveLength(2);
  });

  test('increments death counter', () => {
    const player = { smartCoins: 10 };
    const result = activateReturning(player, deadCharacter);
    expect(result.character.deaths).toBe(deadCharacter.deaths + 1);
  });

  test('revives at 50% maxHP', () => {
    const player = { smartCoins: 10 };
    const result = activateReturning(player, deadCharacter);
    expect(result.character.hp).toBe(50); // 50% of maxHp 100
  });
});

// ---------------------------------------------------------------------------
// processCharacterDeath
// ---------------------------------------------------------------------------

describe('processCharacterDeath', () => {
  test('returns death message and returning instructions', () => {
    const character = { name: 'Guerrero', deaths: 0 };
    const result = processCharacterDeath(character);
    expect(result.deathMessage).toBeTruthy();
    expect(result.canReturn).toBe(true);
    expect(result.returningCost).toBe(RETURNING_COST);
    expect(result.currentDeaths).toBe(1);
    expect(result.instruction).toContain('/returning');
  });

  test('increments death count correctly', () => {
    const character = { name: 'Mago', deaths: 5 };
    const result = processCharacterDeath(character);
    expect(result.currentDeaths).toBe(6);
  });
});
