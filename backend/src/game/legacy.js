/**
 * MAXIMA RPG - Legacy / Returning System
 *
 * When a character dies they can be revived using the "Returning" mechanic:
 *   - Costs 5 Smart Coins per revival
 *   - Grants a stacking +10% XP bonus per death (legacy bonus)
 *   - Retains 50% of inventory from the previous life
 *   - Death counter increments permanently
 *
 * The system rewards persistence: the more you die, the faster you level,
 * because clearly you need all the help you can get.
 */

const { pickRandom, randomInt } = require('./loot');
const { getReturningMessage, getDeathMessage } = require('./master');

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

// Smart Coin cost per revival
const RETURNING_COST = 5;

// XP bonus per death (cumulative, additive)
const XP_BONUS_PER_DEATH = 10; // 10% per death

// Fraction of inventory retained on revival
const INVENTORY_RETENTION_RATE = 0.5; // 50%

// Base HP on revival (percentage of max HP)
const REVIVAL_HP_PERCENTAGE = 0.5; // Revive at 50% HP

// ---------------------------------------------------------------------------
// Core legacy functions
// ---------------------------------------------------------------------------

/**
 * Calculates the accumulated legacy bonus for a character.
 *
 * @param {object} character - Must have a `deaths` field (number).
 * @returns {{
 *   xpBonusPercent: number,
 *   totalDeaths: number,
 *   nextRevivalCost: number,
 *   description: string
 * }}
 */
function getLegacyBonus(character) {
  const deaths = character.deaths || 0;
  const xpBonusPercent = deaths * XP_BONUS_PER_DEATH;

  let description;
  if (deaths === 0) {
    description = 'Sin muertes registradas. Impresionante... o no has jugado lo suficiente.';
  } else if (deaths <= 3) {
    description = `Has muerto ${deaths} veces. Tu bonus de legado es +${xpBonusPercent}% XP. La perseverancia es admirable. La incompetencia, menos.`;
  } else if (deaths <= 7) {
    description = `${deaths} muertes. +${xpBonusPercent}% XP de legado. A este ritmo, la Muerte te va a dar descuento por volumen.`;
  } else {
    description = `${deaths} muertes. +${xpBonusPercent}% XP. Eres practicamente inmortal. No porque no mueras, sino porque te niegas a quedarte muerto.`;
  }

  return {
    xpBonusPercent,
    totalDeaths: deaths,
    nextRevivalCost: RETURNING_COST,
    description,
  };
}

/**
 * Applies the legacy XP bonus to a raw XP amount.
 *
 * @param {number} baseXp     - The raw XP earned.
 * @param {object} character  - Must have a `deaths` field.
 * @returns {{ baseXp: number, bonusXp: number, totalXp: number, bonusPercent: number }}
 */
function applyLegacyXpBonus(baseXp, character) {
  const deaths = character.deaths || 0;
  const bonusPercent = deaths * XP_BONUS_PER_DEATH;
  const bonusXp = Math.floor(baseXp * (bonusPercent / 100));

  return {
    baseXp,
    bonusXp,
    totalXp: baseXp + bonusXp,
    bonusPercent,
  };
}

/**
 * Activates the Returning mechanic to revive a dead character.
 *
 * @param {object} player     - The player account. Must have `smartCoins` field.
 * @param {object} character  - The dead character to revive. Must have:
 *   - hp, maxHp, deaths, inventory, alive (or isDead)
 * @returns {{
 *   success: boolean,
 *   message: string,
 *   character: object|null,
 *   smartCoinsSpent: number,
 *   inventoryRetained: Array,
 *   inventoryLost: Array,
 *   legacyBonus: object
 * }}
 */
function activateReturning(player, character) {
  // Validate: is the character actually dead?
  if (character.hp > 0 && character.alive !== false) {
    return {
      success: false,
      message: 'Tu personaje esta vivo. No puedes revivir a alguien que no ha muerto. Todavia.',
      character: null,
      smartCoinsSpent: 0,
      inventoryRetained: [],
      inventoryLost: [],
      legacyBonus: null,
    };
  }

  // Validate: does the player have enough Smart Coins?
  const currentSmartCoins = player.smartCoins || 0;
  if (currentSmartCoins < RETURNING_COST) {
    return {
      success: false,
      message: `No tienes suficientes Smart Coins. Necesitas ${RETURNING_COST}, tienes ${currentSmartCoins}. La resurrecion no es gratis. Ni la vida, ni la muerte, ni nada en esta mazmorra.`,
      character: null,
      smartCoinsSpent: 0,
      inventoryRetained: [],
      inventoryLost: [],
      legacyBonus: null,
    };
  }

  // Process revival
  const revivedCharacter = { ...character };

  // Increment death counter
  revivedCharacter.deaths = (character.deaths || 0) + 1;

  // Restore HP to a percentage of max
  const maxHp = character.maxHp || 100;
  revivedCharacter.hp = Math.floor(maxHp * REVIVAL_HP_PERCENTAGE);
  revivedCharacter.maxHp = maxHp;
  revivedCharacter.alive = true;

  // Process inventory retention (keep 50%)
  const originalInventory = character.inventory || [];
  const retainCount = Math.ceil(originalInventory.length * INVENTORY_RETENTION_RATE);

  // Shuffle and split inventory
  const shuffled = [...originalInventory].sort(() => Math.random() - 0.5);
  const inventoryRetained = shuffled.slice(0, retainCount);
  const inventoryLost = shuffled.slice(retainCount);
  revivedCharacter.inventory = inventoryRetained;

  // Calculate legacy bonus
  const legacyBonus = getLegacyBonus(revivedCharacter);

  // Generate narrated message
  const narrativeMessage = getReturningMessage({
    name: character.name,
    legacyBonus: legacyBonus.xpBonusPercent,
  });

  // Build detailed summary
  const summaryParts = [narrativeMessage];
  summaryParts.push(`\n--- RETURNING ---`);
  summaryParts.push(`Smart Coins gastadas: ${RETURNING_COST}`);
  summaryParts.push(`HP restaurado: ${revivedCharacter.hp}/${maxHp}`);
  summaryParts.push(`Muertes totales: ${revivedCharacter.deaths}`);
  summaryParts.push(`Bonus de legado: +${legacyBonus.xpBonusPercent}% XP`);

  if (inventoryRetained.length > 0) {
    summaryParts.push(`Objetos conservados (${inventoryRetained.length}): ${inventoryRetained.map((i) => i.name).join(', ')}`);
  }
  if (inventoryLost.length > 0) {
    summaryParts.push(`Objetos perdidos (${inventoryLost.length}): ${inventoryLost.map((i) => i.name).join(', ')}`);
  }
  if (originalInventory.length === 0) {
    summaryParts.push('No tenias objetos. Empezar de cero es tu especialidad.');
  }

  return {
    success: true,
    message: summaryParts.join('\n'),
    character: revivedCharacter,
    smartCoinsSpent: RETURNING_COST,
    inventoryRetained,
    inventoryLost,
    legacyBonus,
  };
}

/**
 * Processes a character death, recording stats and preparing for potential revival.
 *
 * @param {object} character - The character that just died.
 * @returns {{
 *   deathMessage: string,
 *   canReturn: boolean,
 *   returningCost: number,
 *   currentDeaths: number
 * }}
 */
function processCharacterDeath(character) {
  const deathMessage = getDeathMessage(character);

  return {
    deathMessage,
    canReturn: true,
    returningCost: RETURNING_COST,
    currentDeaths: (character.deaths || 0) + 1, // Includes this death
    instruction: `Usa /returning para revivir por ${RETURNING_COST} Smart Coins. O quédate muerto. La mazmorra no juzga.`,
  };
}

// ---------------------------------------------------------------------------
// Socket.IO handler registration
// ---------------------------------------------------------------------------

/**
 * Registers legacy/returning-related Socket.IO event listeners.
 *
 * Events:
 *   - 'legacy:returning'  : { playerData, characterData }
 *   - 'legacy:getBonus'   : { characterData }
 *   - 'legacy:death'      : { characterData }
 *
 * @param {import('socket.io').Server} io
 * @param {import('socket.io').Socket} socket
 */
function registerLegacyHandlers(io, socket) {
  // Activate Returning (revive character)
  socket.on('legacy:returning', (data, callback) => {
    try {
      const { playerData, characterData } = data;

      if (!playerData || !characterData) {
        const err = 'Datos incompletos. Necesitamos al jugador y al personaje para la resurreccion.';
        if (callback) return callback({ success: false, error: err });
        return socket.emit('legacy:error', { error: err });
      }

      const result = activateReturning(playerData, characterData);

      if (result.success) {
        // Broadcast the revival to the room/dungeon
        if (data.roomId) {
          io.to(data.roomId).emit('legacy:returned', {
            playerId: data.playerId || playerData.id,
            characterName: characterData.name,
            message: result.message,
          });
        }
      }

      socket.emit('legacy:returningResult', result);
      if (callback) callback(result);
    } catch (err) {
      console.error('[Legacy] Error in legacy:returning:', err);
      const errorMsg = 'Error en el proceso de Returning. Ni la resurreccion funciona bien aqui.';
      if (callback) return callback({ success: false, error: errorMsg });
      socket.emit('legacy:error', { error: errorMsg });
    }
  });

  // Get legacy bonus info
  socket.on('legacy:getBonus', (data, callback) => {
    try {
      const { characterData } = data;

      if (!characterData) {
        const err = 'No se proporcionaron datos de personaje.';
        if (callback) return callback({ success: false, error: err });
        return socket.emit('legacy:error', { error: err });
      }

      const bonus = getLegacyBonus(characterData);
      const payload = { success: true, ...bonus };

      socket.emit('legacy:bonusInfo', payload);
      if (callback) callback(payload);
    } catch (err) {
      console.error('[Legacy] Error in legacy:getBonus:', err);
      if (callback) callback({ success: false, error: 'Error al consultar el legado.' });
    }
  });

  // Process character death
  socket.on('legacy:death', (data, callback) => {
    try {
      const { characterData } = data;

      if (!characterData) {
        const err = 'No hay personaje para matar. Ironico.';
        if (callback) return callback({ success: false, error: err });
        return socket.emit('legacy:error', { error: err });
      }

      const deathResult = processCharacterDeath(characterData);

      // Broadcast death to room
      if (data.roomId) {
        io.to(data.roomId).emit('legacy:characterDied', {
          playerId: data.playerId,
          characterName: characterData.name,
          deathMessage: deathResult.deathMessage,
        });
      }

      const payload = { success: true, ...deathResult };
      socket.emit('legacy:deathResult', payload);
      if (callback) callback(payload);
    } catch (err) {
      console.error('[Legacy] Error in legacy:death:', err);
      if (callback) callback({ success: false, error: 'Error al procesar la muerte.' });
    }
  });
}

// ---------------------------------------------------------------------------
// Exports
// ---------------------------------------------------------------------------

module.exports = {
  RETURNING_COST,
  XP_BONUS_PER_DEATH,
  INVENTORY_RETENTION_RATE,
  getLegacyBonus,
  applyLegacyXpBonus,
  activateReturning,
  processCharacterDeath,
  registerLegacyHandlers,
};
