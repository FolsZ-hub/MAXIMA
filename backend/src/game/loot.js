/**
 * MAXIMA RPG - Loot System
 *
 * Manages loot generation, rarity rolls, item databases, and loot distribution.
 * All item descriptions and flavour text are in Spanish with a cynical narrator tone.
 *
 * Rarity probabilities:
 *   Common     60%
 *   Uncommon   25%
 *   Rare       10%
 *   Legendary   5%
 */

// ---------------------------------------------------------------------------
// Rarity tiers and roll thresholds (cumulative percentages)
// ---------------------------------------------------------------------------

const RARITY = {
  COMMON: 'common',
  UNCOMMON: 'uncommon',
  RARE: 'rare',
  LEGENDARY: 'legendary',
};

const RARITY_THRESHOLDS = [
  { max: 60, rarity: RARITY.COMMON },
  { max: 85, rarity: RARITY.UNCOMMON },
  { max: 95, rarity: RARITY.RARE },
  { max: 100, rarity: RARITY.LEGENDARY },
];

const RARITY_LABELS = {
  [RARITY.COMMON]: 'Comun',
  [RARITY.UNCOMMON]: 'Poco comun',
  [RARITY.RARE]: 'Raro',
  [RARITY.LEGENDARY]: 'Legendario',
};

const RARITY_COLORS = {
  [RARITY.COMMON]: '#9d9d9d',
  [RARITY.UNCOMMON]: '#1eff00',
  [RARITY.RARE]: '#0070dd',
  [RARITY.LEGENDARY]: '#ff8000',
};

// ---------------------------------------------------------------------------
// Item database
// ---------------------------------------------------------------------------

const ITEMS = {
  // --- Weapons ---
  weapons: {
    [RARITY.COMMON]: [
      {
        name: 'Daga Oxidada',
        type: 'weapon',
        subtype: 'dagger',
        damage: 3,
        rarity: RARITY.COMMON,
        description: 'Una daga que ha visto mejores dias. Muchos mejores dias.',
        value: 5,
      },
      {
        name: 'Garrote de Madera',
        type: 'weapon',
        subtype: 'club',
        damage: 4,
        rarity: RARITY.COMMON,
        description: 'Basicamente un palo. Pero un palo con proposito.',
        value: 3,
      },
      {
        name: 'Espada Mellada',
        type: 'weapon',
        subtype: 'sword',
        damage: 5,
        rarity: RARITY.COMMON,
        description: 'Alguien la uso para cortar queso. Se nota.',
        value: 8,
      },
    ],
    [RARITY.UNCOMMON]: [
      {
        name: 'Espada de Acero Templado',
        type: 'weapon',
        subtype: 'sword',
        damage: 10,
        rarity: RARITY.UNCOMMON,
        description: 'Una espada decente. Casi impresionante, si no fueras tu quien la empuna.',
        value: 25,
      },
      {
        name: 'Hacha del Lenador Furioso',
        type: 'weapon',
        subtype: 'axe',
        damage: 12,
        rarity: RARITY.UNCOMMON,
        description: 'Forjada con la rabia de mil arboles talados injustamente.',
        value: 30,
      },
      {
        name: 'Arco del Cazador Solitario',
        type: 'weapon',
        subtype: 'bow',
        damage: 9,
        rarity: RARITY.UNCOMMON,
        description: 'Solitario porque nadie queria cazar con el. Ahora entiendes por que.',
        value: 22,
      },
    ],
    [RARITY.RARE]: [
      {
        name: 'Hoja de Sombras',
        type: 'weapon',
        subtype: 'sword',
        damage: 18,
        rarity: RARITY.RARE,
        description: 'Una espada forjada en la oscuridad. Literalmente, el herrero no pagaba la luz.',
        value: 75,
      },
      {
        name: 'Martillo de Truenos',
        type: 'weapon',
        subtype: 'hammer',
        damage: 22,
        rarity: RARITY.RARE,
        description: 'Cada golpe suena como una tormenta. Los vecinos se quejan constantemente.',
        value: 85,
      },
      {
        name: 'Baculo del Archimago Borracho',
        type: 'weapon',
        subtype: 'staff',
        damage: 16,
        rarity: RARITY.RARE,
        description: 'Canaliza poder arcano... cuando el usuario no esta tambaleandose.',
        value: 70,
      },
    ],
    [RARITY.LEGENDARY]: [
      {
        name: 'Excalibur del Descuento',
        type: 'weapon',
        subtype: 'sword',
        damage: 35,
        rarity: RARITY.LEGENDARY,
        description: 'La espada legendaria. Bueno, una replica. Pero bastante convincente.',
        value: 250,
      },
      {
        name: 'Guadana del Destino Final',
        type: 'weapon',
        subtype: 'scythe',
        damage: 40,
        rarity: RARITY.LEGENDARY,
        description: 'La Muerte la perdio en una apuesta. Su perdida, tu ganancia... temporalmente.',
        value: 300,
      },
    ],
  },

  // --- Armor ---
  armor: {
    [RARITY.COMMON]: [
      {
        name: 'Armadura de Cuero Cuarteado',
        type: 'armor',
        subtype: 'light',
        defense: 2,
        rarity: RARITY.COMMON,
        description: 'Protege tanto como una camiseta gruesa. Huele peor.',
        value: 5,
      },
      {
        name: 'Escudo de Madera Podrida',
        type: 'armor',
        subtype: 'shield',
        defense: 3,
        rarity: RARITY.COMMON,
        description: 'Mas decorativo que funcional. Como tu presencia en el grupo.',
        value: 4,
      },
    ],
    [RARITY.UNCOMMON]: [
      {
        name: 'Cota de Malla Remendada',
        type: 'armor',
        subtype: 'medium',
        defense: 6,
        rarity: RARITY.UNCOMMON,
        description: 'Tiene agujeros, pero en lugares estrategicamente no-vitales. Esperemos.',
        value: 28,
      },
      {
        name: 'Yelmo del Caballero Cobarde',
        type: 'armor',
        subtype: 'helmet',
        defense: 4,
        rarity: RARITY.UNCOMMON,
        description: 'Su anterior dueno huyo de cada batalla. Al menos su cabeza sobrevivio.',
        value: 20,
      },
    ],
    [RARITY.RARE]: [
      {
        name: 'Armadura de Escamas de Dragon',
        type: 'armor',
        subtype: 'heavy',
        defense: 12,
        rarity: RARITY.RARE,
        description: 'Hecha de escamas reales de dragon. El dragon quiere que se las devuelvas.',
        value: 90,
      },
      {
        name: 'Capa de Invisibilidad Defectuosa',
        type: 'armor',
        subtype: 'cloak',
        defense: 5,
        rarity: RARITY.RARE,
        description: 'Te hace invisible... del cuello para abajo. Util para fiestas, supongo.',
        value: 65,
      },
    ],
    [RARITY.LEGENDARY]: [
      {
        name: 'Coraza del Titan Caido',
        type: 'armor',
        subtype: 'heavy',
        defense: 20,
        rarity: RARITY.LEGENDARY,
        description: 'Forjada con lagrimas de un titan. Pesa como uno tambien.',
        value: 280,
      },
    ],
  },

  // --- Potions ---
  potions: {
    [RARITY.COMMON]: [
      {
        name: 'Pocion de Salud Menor',
        type: 'potion',
        subtype: 'healing',
        healing: 15,
        rarity: RARITY.COMMON,
        description: 'Sabe a jarabe para la tos mezclado con esperanza barata.',
        value: 5,
      },
      {
        name: 'Pocion de Salud',
        type: 'potion',
        subtype: 'healing',
        healing: 25,
        rarity: RARITY.COMMON,
        description: 'El clasico liquido rojo. Nadie sabe que contiene. Nadie pregunta.',
        value: 10,
      },
      {
        name: 'Pocion de Energia',
        type: 'potion',
        subtype: 'energy',
        healing: 10,
        rarity: RARITY.COMMON,
        description: 'Basicamente cafe medieval con un toque de magia cuestionable.',
        value: 7,
      },
    ],
    [RARITY.UNCOMMON]: [
      {
        name: 'Pocion de Salud Mayor',
        type: 'potion',
        subtype: 'healing',
        healing: 50,
        rarity: RARITY.UNCOMMON,
        description: 'Regenera heridas considerables. Los efectos secundarios incluyen optimismo temporal.',
        value: 25,
      },
      {
        name: 'Elixir de Fuerza',
        type: 'potion',
        subtype: 'buff',
        healing: 0,
        buffStat: 'attack',
        buffAmount: 5,
        buffDuration: 3,
        rarity: RARITY.UNCOMMON,
        description: 'Te sentiras fuerte. Seras fuerte. Brevemente.',
        value: 30,
      },
      {
        name: 'Elixir de Coraza',
        type: 'potion',
        subtype: 'buff',
        healing: 0,
        buffStat: 'defense',
        buffAmount: 5,
        buffDuration: 3,
        rarity: RARITY.UNCOMMON,
        description: 'Tu piel se endurece como piedra. Tu inteligencia, lamentablemente, no.',
        value: 30,
      },
    ],
    [RARITY.RARE]: [
      {
        name: 'Pocion de Salud Suprema',
        type: 'potion',
        subtype: 'healing',
        healing: 100,
        rarity: RARITY.RARE,
        description: 'Cura casi todo. Excepto la estupidez. Eso es incurable.',
        value: 60,
      },
      {
        name: 'Frasco de Inmunidad',
        type: 'potion',
        subtype: 'immunity',
        healing: 0,
        immunityDuration: 2,
        rarity: RARITY.RARE,
        description: 'Dos turnos de invulnerabilidad. Usalo sabiamente. (No lo haras.)',
        value: 75,
      },
    ],
    [RARITY.LEGENDARY]: [
      {
        name: 'Lagrima de Fenix',
        type: 'potion',
        subtype: 'revive',
        healing: 999,
        rarity: RARITY.LEGENDARY,
        description: 'Devuelve a los muertos. El fenix lloro porque vio tu historial de combate.',
        value: 500,
      },
    ],
  },

  // --- Scrolls ---
  scrolls: {
    [RARITY.COMMON]: [
      {
        name: 'Pergamino de Luz',
        type: 'scroll',
        subtype: 'utility',
        effect: 'light',
        damage: 0,
        rarity: RARITY.COMMON,
        description: 'Ilumina la oscuridad. Tambien revela lo feo que es todo. De nada.',
        value: 3,
      },
      {
        name: 'Pergamino de Chispa',
        type: 'scroll',
        subtype: 'attack',
        effect: 'spark',
        damage: 8,
        rarity: RARITY.COMMON,
        description: 'Un hechizo ofensivo basico. Muy basico. Como tu estrategia.',
        value: 8,
      },
    ],
    [RARITY.UNCOMMON]: [
      {
        name: 'Pergamino de Bola de Fuego',
        type: 'scroll',
        subtype: 'attack',
        effect: 'fireball',
        damage: 25,
        rarity: RARITY.UNCOMMON,
        description: 'Lanza una bola de fuego. Intenta no quemarte a ti mismo esta vez.',
        value: 35,
      },
      {
        name: 'Pergamino de Teletransporte',
        type: 'scroll',
        subtype: 'utility',
        effect: 'teleport',
        damage: 0,
        rarity: RARITY.UNCOMMON,
        description: 'Te transporta a la entrada de la mazmorra. Perfecto para cobardes eficientes.',
        value: 30,
      },
    ],
    [RARITY.RARE]: [
      {
        name: 'Pergamino de Tormenta Arcana',
        type: 'scroll',
        subtype: 'attack',
        effect: 'arcane_storm',
        damage: 50,
        rarity: RARITY.RARE,
        description: 'Invoca una tormenta magica devastadora. Los efectos especiales son impresionantes.',
        value: 80,
      },
      {
        name: 'Pergamino de Resurrecion',
        type: 'scroll',
        subtype: 'utility',
        effect: 'resurrect',
        damage: 0,
        rarity: RARITY.RARE,
        description: 'Revive a un aliado caido. El aliado no necesariamente te lo agradecera.',
        value: 90,
      },
    ],
    [RARITY.LEGENDARY]: [
      {
        name: 'Pergamino del Apocalipsis',
        type: 'scroll',
        subtype: 'attack',
        effect: 'apocalypse',
        damage: 100,
        rarity: RARITY.LEGENDARY,
        description: 'Destruccion total. El autor del pergamino tenia problemas de manejo de ira.',
        value: 400,
      },
    ],
  },
};

// ---------------------------------------------------------------------------
// Coin drop tables by difficulty
// ---------------------------------------------------------------------------

const COIN_DROPS = {
  easy: { min: 2, max: 10 },
  medium: { min: 8, max: 25 },
  hard: { min: 20, max: 60 },
};

const XP_DROPS = {
  easy: { min: 5, max: 15 },
  medium: { min: 12, max: 30 },
  hard: { min: 25, max: 60 },
};

// Boss multiplier for drops
const BOSS_MULTIPLIER = 3;

// ---------------------------------------------------------------------------
// Helper functions
// ---------------------------------------------------------------------------

/**
 * Returns a random integer between min (inclusive) and max (inclusive).
 * @param {number} min
 * @param {number} max
 * @returns {number}
 */
function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

/**
 * Rolls rarity based on weighted probabilities.
 * @returns {string} One of the RARITY values.
 */
function rollRarity() {
  const roll = randomInt(1, 100);
  for (const tier of RARITY_THRESHOLDS) {
    if (roll <= tier.max) {
      return tier.rarity;
    }
  }
  return RARITY.COMMON;
}

/**
 * Picks a random element from an array.
 * @param {Array} arr
 * @returns {*}
 */
function pickRandom(arr) {
  if (!arr || arr.length === 0) return null;
  return arr[randomInt(0, arr.length - 1)];
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Generates a random loot drop based on difficulty and whether the source is a boss.
 *
 * @param {string} difficulty - 'easy' | 'medium' | 'hard'
 * @param {boolean} [isBoss=false] - If true, guarantees higher rarity and multiplied rewards.
 * @returns {{ item: object|null, coins: number, xp: number }}
 */
function generateLoot(difficulty = 'easy', isBoss = false) {
  const diff = ['easy', 'medium', 'hard'].includes(difficulty) ? difficulty : 'easy';

  // Roll coins and XP
  const coinRange = COIN_DROPS[diff];
  const xpRange = XP_DROPS[diff];
  let coins = randomInt(coinRange.min, coinRange.max);
  let xp = randomInt(xpRange.min, xpRange.max);

  if (isBoss) {
    coins *= BOSS_MULTIPLIER;
    xp *= BOSS_MULTIPLIER;
  }

  // Determine if an item drops (70% chance, 100% from bosses)
  const itemDropChance = isBoss ? 100 : 70;
  let item = null;

  if (randomInt(1, 100) <= itemDropChance) {
    // Roll rarity - bosses get a minimum of uncommon
    let rarity = rollRarity();
    if (isBoss && rarity === RARITY.COMMON) {
      rarity = RARITY.UNCOMMON;
    }

    // Pick a random item category
    const categories = ['weapons', 'armor', 'potions', 'scrolls'];
    const category = pickRandom(categories);
    const pool = ITEMS[category][rarity];

    if (pool && pool.length > 0) {
      // Deep clone so the original database is never mutated
      item = JSON.parse(JSON.stringify(pickRandom(pool)));
    }
  }

  return { item, coins, xp };
}

/**
 * Generates loot specifically from a treasure room (guaranteed item, better odds).
 *
 * @param {string} difficulty
 * @returns {{ item: object|null, coins: number, xp: number }}
 */
function generateTreasureLoot(difficulty = 'medium') {
  const diff = ['easy', 'medium', 'hard'].includes(difficulty) ? difficulty : 'medium';

  const coinRange = COIN_DROPS[diff];
  let coins = randomInt(coinRange.min, coinRange.max) * 2;
  let xp = randomInt(5, 10);

  // Guaranteed item with boosted rarity
  let rarity = rollRarity();
  // Bump common to uncommon in treasure rooms
  if (rarity === RARITY.COMMON) {
    rarity = RARITY.UNCOMMON;
  }

  const categories = ['weapons', 'armor', 'potions', 'scrolls'];
  const category = pickRandom(categories);
  const pool = ITEMS[category][rarity];
  let item = null;

  if (pool && pool.length > 0) {
    item = JSON.parse(JSON.stringify(pickRandom(pool)));
  }

  return { item, coins, xp };
}

/**
 * Distributes loot among a group of players equally.
 * Coins and XP are split. The item goes to a random player.
 *
 * @param {{ item: object|null, coins: number, xp: number }} loot
 * @param {Array<object>} players - Array of player objects with at least { id, username }.
 * @returns {Array<{ playerId: string, username: string, coins: number, xp: number, item: object|null }>}
 */
function distributeLoot(loot, players) {
  if (!players || players.length === 0) return [];

  const count = players.length;
  const coinsEach = Math.floor(loot.coins / count);
  const xpEach = Math.floor(loot.xp / count);

  // Remainder coins go to a random lucky player
  const coinsRemainder = loot.coins % count;
  const luckyIndex = randomInt(0, count - 1);

  // If there is an item, it goes to a random player
  const itemWinnerIndex = loot.item ? randomInt(0, count - 1) : -1;

  // Audit trail for loot distribution
  console.log(
    `[Loot] Distribuyendo a ${count} jugadores: ` +
    `${loot.coins} monedas (${coinsEach}c/u, resto ${coinsRemainder} -> jugador ${luckyIndex}), ` +
    `${loot.xp} XP (${xpEach}c/u)` +
    (loot.item ? `, item "${loot.item.name}" -> jugador ${itemWinnerIndex}` : ', sin item')
  );

  return players.map((player, index) => ({
    playerId: player.id || player.uid,
    username: player.username,
    coins: coinsEach + (index === luckyIndex ? coinsRemainder : 0),
    xp: xpEach,
    item: index === itemWinnerIndex ? loot.item : null,
  }));
}

/**
 * Looks up an item by name (case-insensitive) in the entire item database.
 *
 * @param {string} itemName
 * @returns {object|null} The item template, or null if not found.
 */
function findItemByName(itemName) {
  if (!itemName) return null;
  const needle = itemName.toLowerCase().trim();

  for (const category of Object.values(ITEMS)) {
    for (const rarityPool of Object.values(category)) {
      for (const item of rarityPool) {
        if (item.name.toLowerCase() === needle) {
          return JSON.parse(JSON.stringify(item));
        }
      }
    }
  }
  return null;
}

/**
 * Returns all items of a given type.
 *
 * @param {string} type - 'weapon' | 'armor' | 'potion' | 'scroll'
 * @returns {Array<object>}
 */
function getItemsByType(type) {
  const categoryMap = {
    weapon: 'weapons',
    armor: 'armor',
    potion: 'potions',
    scroll: 'scrolls',
  };

  const categoryKey = categoryMap[type];
  if (!categoryKey || !ITEMS[categoryKey]) return [];

  const results = [];
  for (const pool of Object.values(ITEMS[categoryKey])) {
    results.push(...pool);
  }
  return results;
}

/**
 * Formats a loot drop into a human-readable Spanish string.
 *
 * @param {{ item: object|null, coins: number, xp: number }} loot
 * @returns {string}
 */
function formatLootMessage(loot) {
  const parts = [];

  if (loot.coins > 0) {
    parts.push(`${loot.coins} monedas de oro`);
  }
  if (loot.xp > 0) {
    parts.push(`${loot.xp} puntos de experiencia`);
  }
  if (loot.item) {
    const rarityLabel = RARITY_LABELS[loot.item.rarity] || 'Desconocido';
    parts.push(`[${rarityLabel}] ${loot.item.name} - "${loot.item.description}"`);
  }

  if (parts.length === 0) {
    return 'Nada. Absolutamente nada. El universo es cruel y vacio, como tu inventario.';
  }

  return parts.join('\n  ');
}

// ---------------------------------------------------------------------------
// Exports
// ---------------------------------------------------------------------------

module.exports = {
  RARITY,
  RARITY_LABELS,
  RARITY_COLORS,
  ITEMS,
  generateLoot,
  generateTreasureLoot,
  distributeLoot,
  findItemByName,
  getItemsByType,
  formatLootMessage,
  rollRarity,
  // Expose helpers for other modules
  randomInt,
  pickRandom,
};
