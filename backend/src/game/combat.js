/**
 * MAXIMA RPG - D20 Combat System
 *
 * Core combat mechanics based on a D20 roll:
 *   - Roll >= 10 : hit  (damage = random(5..15) + attacker.attack - target.defense)
 *   - Roll === 20 : critical hit (damage doubled)
 *   - Roll === 1  : critical fail / fumble (attacker takes 5 self-damage)
 *   - Roll < 10   : miss
 *
 * Also handles hunting encounters and item usage during combat.
 */

const { randomInt, pickRandom, generateLoot } = require('./loot');
const {
  getEnemyEncounterMessage,
  getCombatResultMessage,
  getDeathMessage,
  getHuntMessage,
  getItemUseMessage,
} = require('./master');

// ---------------------------------------------------------------------------
// Enemy templates (used by hunt and dungeon encounters)
// ---------------------------------------------------------------------------

const ENEMY_TEMPLATES = {
  easy: [
    { name: 'Rata Gigante', type: 'default', hp: 15, attack: 3, defense: 1, xpReward: 8 },
    { name: 'Esqueleto Fragil', type: 'skeleton', hp: 20, attack: 4, defense: 2, xpReward: 10 },
    { name: 'Goblin Cobarde', type: 'goblin', hp: 18, attack: 5, defense: 1, xpReward: 10 },
    { name: 'Murcielago Rabioso', type: 'default', hp: 10, attack: 3, defense: 0, xpReward: 5 },
    { name: 'Slime Verdoso', type: 'default', hp: 25, attack: 2, defense: 3, xpReward: 7 },
  ],
  medium: [
    { name: 'Orco Guerrero', type: 'default', hp: 45, attack: 10, defense: 5, xpReward: 25 },
    { name: 'Esqueleto Armado', type: 'skeleton', hp: 35, attack: 8, defense: 7, xpReward: 22 },
    { name: 'Goblin Chamán', type: 'goblin', hp: 30, attack: 12, defense: 4, xpReward: 28 },
    { name: 'Araña Venenosa', type: 'default', hp: 40, attack: 9, defense: 3, xpReward: 20 },
    { name: 'Fantasma Iracundo', type: 'default', hp: 35, attack: 11, defense: 6, xpReward: 24 },
    { name: 'Troll de las Cavernas', type: 'default', hp: 55, attack: 8, defense: 8, xpReward: 30 },
  ],
  hard: [
    { name: 'Caballero Oscuro', type: 'default', hp: 80, attack: 18, defense: 12, xpReward: 50 },
    { name: 'Liche Menor', type: 'skeleton', hp: 70, attack: 22, defense: 8, xpReward: 55 },
    { name: 'Goblin Rey', type: 'goblin', hp: 65, attack: 16, defense: 14, xpReward: 45 },
    { name: 'Demonio de Sombras', type: 'default', hp: 90, attack: 20, defense: 10, xpReward: 60 },
    { name: 'Wyrm Joven', type: 'dragon', hp: 100, attack: 25, defense: 15, xpReward: 75 },
    { name: 'Hidra de Tres Cabezas', type: 'default', hp: 120, attack: 22, defense: 11, xpReward: 80 },
  ],
};

const BOSS_TEMPLATES = {
  easy: { name: 'Rey Rata', type: 'default', hp: 50, attack: 8, defense: 4, xpReward: 40, isBoss: true },
  medium: { name: 'Señor de los No-Muertos', type: 'skeleton', hp: 100, attack: 16, defense: 10, xpReward: 80, isBoss: true },
  hard: { name: 'Dragon Negro Ancestral', type: 'dragon', hp: 200, attack: 35, defense: 20, xpReward: 200, isBoss: true },
};

// Self-damage on fumble
const FUMBLE_DAMAGE = 5;

// ---------------------------------------------------------------------------
// Core combat functions
// ---------------------------------------------------------------------------

/**
 * Rolls a D20 (returns integer 1-20).
 * @returns {number}
 */
function rollD20() {
  return randomInt(1, 20);
}

/**
 * Calculates the result of an attack using D20 mechanics.
 *
 * @param {object} attacker - { name, attack, hp, ... }
 * @param {object} target   - { name, defense, hp, ... }
 * @param {number} roll     - The D20 roll value (1-20).
 * @returns {{
 *   hit: boolean,
 *   critical: boolean,
 *   fumble: boolean,
 *   damage: number,
 *   selfDamage: number,
 *   roll: number,
 *   message: string,
 *   targetHp: number,
 *   attackerHp: number,
 *   targetDefeated: boolean,
 *   attackerDefeated: boolean
 * }}
 */
function calculateAttack(attacker, target, roll) {
  const result = {
    hit: false,
    critical: false,
    fumble: false,
    damage: 0,
    selfDamage: 0,
    roll,
    message: '',
    targetHp: target.hp,
    attackerHp: attacker.hp,
    targetDefeated: false,
    attackerDefeated: false,
  };

  if (roll === 1) {
    // Critical fail - fumble
    result.fumble = true;
    result.selfDamage = FUMBLE_DAMAGE;
    result.attackerHp = Math.max(0, attacker.hp - FUMBLE_DAMAGE);
    result.attackerDefeated = result.attackerHp <= 0;
    result.message = getCombatResultMessage({
      type: 'fumble',
      selfDamage: FUMBLE_DAMAGE,
      targetName: target.name,
    });
  } else if (roll < 10) {
    // Miss
    result.message = getCombatResultMessage({
      type: 'miss',
      targetName: target.name,
    });
  } else {
    // Hit (roll >= 10)
    result.hit = true;
    let baseDamage = randomInt(5, 15) + (attacker.attack || 0) - Math.floor((target.defense || 0) * 0.7);
    baseDamage = Math.max(1, baseDamage); // Minimum 1 damage on hit

    if (roll === 20) {
      // Critical hit - double damage
      result.critical = true;
      result.damage = baseDamage * 2;
      result.message = getCombatResultMessage({
        type: 'critical',
        damage: result.damage,
        targetName: target.name,
      });
    } else {
      result.damage = baseDamage;
      result.message = getCombatResultMessage({
        type: 'hit',
        damage: result.damage,
        targetName: target.name,
      });
    }

    result.targetHp = Math.max(0, target.hp - result.damage);
    result.targetDefeated = result.targetHp <= 0;

    if (result.targetDefeated) {
      result.message += '\n' + getCombatResultMessage({
        type: 'enemyDefeated',
        targetName: target.name,
      });
    }
  }

  return result;
}

/**
 * Generates a random enemy based on difficulty and runs a full hunt encounter.
 *
 * @param {object} character - The player character { name, hp, attack, defense, ... }
 * @param {number} roll      - The D20 roll for the hunt.
 * @param {string} [difficulty='easy'] - 'easy' | 'medium' | 'hard'
 * @returns {{
 *   enemy: object,
 *   huntMessage: string,
 *   combatResult: object,
 *   loot: object|null,
 *   enemyAttack: object|null
 * }}
 */
function calculateHunt(character, roll, difficulty = 'easy') {
  const diff = ['easy', 'medium', 'hard'].includes(difficulty) ? difficulty : 'easy';
  const pool = ENEMY_TEMPLATES[diff];

  // Clone a random enemy so we do not mutate the template
  const enemy = JSON.parse(JSON.stringify(pickRandom(pool)));

  // Narrate the hunt
  const huntMessage = getHuntMessage(character);
  const encounterMessage = getEnemyEncounterMessage(enemy);

  // Player attacks first
  const combatResult = calculateAttack(character, enemy, roll);

  let loot = null;
  let enemyAttack = null;

  if (combatResult.targetDefeated) {
    // Enemy is dead - generate loot
    loot = generateLoot(diff, false);
  } else if (!combatResult.targetDefeated) {
    // Enemy retaliates if still alive
    const enemyRoll = rollD20();
    enemyAttack = calculateAttack(enemy, character, enemyRoll);

    if (enemyAttack.targetDefeated) {
      enemyAttack.message += '\n' + getDeathMessage(character);
    }
  }

  return {
    enemy,
    huntMessage,
    encounterMessage,
    combatResult,
    loot,
    enemyAttack,
  };
}

/**
 * Handles item usage logic.
 *
 * @param {object} character - The character using the item.
 * @param {string} itemName  - Name of the item to use.
 * @param {Array}  inventory - The character's inventory array.
 * @returns {{
 *   success: boolean,
 *   message: string,
 *   effects: object,
 *   consumedItem: object|null
 * }}
 */
function useItem(character, itemName, inventory) {
  if (!inventory || inventory.length === 0) {
    return {
      success: false,
      message: 'Tu inventario esta vacio. Como tu futuro en esta mazmorra.',
      effects: {},
      consumedItem: null,
    };
  }

  // Find item in inventory (case-insensitive partial match)
  const needle = itemName.toLowerCase().trim();
  const itemIndex = inventory.findIndex((i) =>
    i.name.toLowerCase().includes(needle)
  );

  if (itemIndex === -1) {
    return {
      success: false,
      message: `No tienes "${itemName}" en tu inventario. Revisa tu mochila, o tu ortografia.`,
      effects: {},
      consumedItem: null,
    };
  }

  const item = inventory[itemIndex];
  const effects = {};
  let consumed = false;

  switch (item.type) {
    case 'potion': {
      if (item.subtype === 'healing' || item.subtype === 'energy') {
        effects.healing = item.healing || 0;
        effects.newHp = Math.min(
          (character.maxHp || 100),
          (character.hp || 0) + effects.healing
        );
      } else if (item.subtype === 'buff') {
        effects.buff = {
          stat: item.buffStat,
          amount: item.buffAmount,
          duration: item.buffDuration,
        };
      } else if (item.subtype === 'immunity') {
        effects.immunity = { duration: item.immunityDuration || 2 };
      } else if (item.subtype === 'revive') {
        effects.revive = true;
        effects.healing = item.healing;
      }
      consumed = true;
      break;
    }

    case 'scroll': {
      if (item.subtype === 'attack') {
        effects.damage = item.damage || 0;
        effects.effect = item.effect;
      } else if (item.subtype === 'utility') {
        effects.effect = item.effect;
      }
      consumed = true;
      break;
    }

    case 'weapon': {
      effects.equip = true;
      effects.slot = 'weapon';
      effects.attackBonus = item.damage || 0;
      // Weapons are equipped, not consumed
      consumed = false;
      break;
    }

    case 'armor': {
      effects.equip = true;
      effects.slot = 'armor';
      effects.defenseBonus = item.defense || 0;
      // Armor is equipped, not consumed
      consumed = false;
      break;
    }

    default: {
      return {
        success: false,
        message: `No sabes como usar "${item.name}". Es como darte una calculadora a un troll. Decorativo, pero inutil.`,
        effects: {},
        consumedItem: null,
      };
    }
  }

  // Build narrated message
  const message = getItemUseMessage(item, character);

  return {
    success: true,
    message,
    effects,
    consumedItem: consumed ? item : null,
    consumedIndex: consumed ? itemIndex : -1,
  };
}

// ---------------------------------------------------------------------------
// Socket.IO handler registration
// ---------------------------------------------------------------------------

/**
 * Registers combat-related Socket.IO event listeners on the given socket.
 *
 * Events:
 *   - 'intentAttack' : { attackerId, targetId, characterData, targetData }
 *   - 'intentHunt'   : { characterData, difficulty }
 *   - 'intentUseItem': { characterData, itemName, inventory }
 *
 * @param {import('socket.io').Server} io
 * @param {import('socket.io').Socket} socket
 */
function registerCombatHandlers(io, socket) {
  // ---- Attack a specific target ----
  socket.on('intentAttack', (data, callback) => {
    try {
      const { characterData, targetData } = data;

      if (!characterData || !targetData) {
        const err = 'Datos de combate incompletos. Necesitas un atacante y un objetivo.';
        if (callback) return callback({ success: false, error: err });
        return socket.emit('combatError', { error: err });
      }

      const roll = rollD20();
      const result = calculateAttack(characterData, targetData, roll);

      const payload = {
        success: true,
        roll,
        result,
        attackerId: data.attackerId,
        targetId: data.targetId,
      };

      // If the target is defeated, generate loot
      if (result.targetDefeated) {
        payload.loot = generateLoot(data.difficulty || 'easy', targetData.isBoss || false);
      }

      // Broadcast to room if applicable
      if (data.roomId) {
        io.to(data.roomId).emit('combatResult', payload);
      } else {
        socket.emit('combatResult', payload);
      }

      if (callback) callback(payload);
    } catch (err) {
      console.error('[Combat] Error in intentAttack:', err);
      const errorMsg = 'Error interno de combate. El Maestro esta confundido.';
      if (callback) return callback({ success: false, error: errorMsg });
      socket.emit('combatError', { error: errorMsg });
    }
  });

  // ---- Hunt for a random enemy ----
  socket.on('intentHunt', (data, callback) => {
    try {
      const { characterData, difficulty } = data;

      if (!characterData) {
        const err = 'Necesitas un personaje para cazar. No puedes enviar el vacio a pelear.';
        if (callback) return callback({ success: false, error: err });
        return socket.emit('combatError', { error: err });
      }

      const roll = rollD20();
      const huntResult = calculateHunt(characterData, roll, difficulty || 'easy');

      const payload = {
        success: true,
        roll,
        ...huntResult,
      };

      socket.emit('huntResult', payload);
      if (callback) callback(payload);
    } catch (err) {
      console.error('[Combat] Error in intentHunt:', err);
      const errorMsg = 'Error en la caceria. Los monstruos estan en huelga.';
      if (callback) return callback({ success: false, error: errorMsg });
      socket.emit('combatError', { error: errorMsg });
    }
  });

  // ---- Use an item ----
  socket.on('intentUseItem', (data, callback) => {
    try {
      const { characterData, itemName, inventory } = data;

      if (!characterData || !itemName) {
        const err = 'Especifica que objeto quieres usar. Las adivinanzas son para los puzzles.';
        if (callback) return callback({ success: false, error: err });
        return socket.emit('itemError', { error: err });
      }

      const result = useItem(characterData, itemName, inventory || []);

      const payload = {
        ...result,
        characterId: data.characterId,
      };

      socket.emit('itemResult', payload);
      if (callback) callback(payload);
    } catch (err) {
      console.error('[Combat] Error in intentUseItem:', err);
      const errorMsg = 'Error al usar el objeto. Quizas esta maldito. O roto. Probablemente roto.';
      if (callback) return callback({ success: false, error: errorMsg });
      socket.emit('itemError', { error: errorMsg });
    }
  });
}

// ---------------------------------------------------------------------------
// Exports
// ---------------------------------------------------------------------------

module.exports = {
  rollD20,
  calculateAttack,
  calculateHunt,
  useItem,
  registerCombatHandlers,
  // Expose templates for dungeon module
  ENEMY_TEMPLATES,
  BOSS_TEMPLATES,
};
