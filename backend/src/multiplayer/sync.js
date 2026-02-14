// sync.js - Socket.IO Synchronization for MAXIMA RPG
// Handles real-time state synchronization: player actions, chat, dungeon
// progress, and cooperative mechanics between players in the same room.

const {
  activeRooms,
  getPlayersInRoom,
  getRoomState,
  updateRoomState,
  leaveRoom,
  serializeRoom,
} = require('./rooms');

// ---------------------------------------------------------------------------
// Cooperative bonus constants
// ---------------------------------------------------------------------------
const COOP_DAMAGE_BONUS = 0.15;        // +15% damage when 2+ players attack same target
const COOP_HEAL_SPLASH_RATIO = 0.25;   // Healing affects nearby players at 25%
const COOP_MIN_ATTACKERS = 2;           // Minimum attackers to trigger damage bonus

// ---------------------------------------------------------------------------
// Connected players tracking
// Maps socketId -> { playerId, roomId }
// ---------------------------------------------------------------------------
const connectedPlayers = new Map();

// ---------------------------------------------------------------------------
// Helper: get the room object from the active store
// ---------------------------------------------------------------------------
function getRoom(roomId) {
  return activeRooms.get(roomId) || null;
}

// ---------------------------------------------------------------------------
// Cooperative mechanics
// ---------------------------------------------------------------------------

/**
 * Calculate cooperative damage bonus when multiple players attack
 * the same target in the same room.
 * @param {string} roomId
 * @param {string} targetId - The enemy being attacked.
 * @param {number} baseDamage - Raw damage before bonuses.
 * @param {string} attackerId - Player who dealt the hit.
 * @returns {{ finalDamage: number, bonusApplied: boolean, attackers: string[] }}
 */
function calculateCooperativeDamage(roomId, targetId, baseDamage, attackerId) {
  const room = getRoom(roomId);
  if (!room) return { finalDamage: baseDamage, bonusApplied: false, attackers: [] };

  // Track who is attacking which target this combat tick
  if (!room.state._attackLog) {
    room.state._attackLog = {};
  }

  const now = Date.now();

  // Initialize or update the attack log for this target
  if (!room.state._attackLog[targetId]) {
    room.state._attackLog[targetId] = {};
  }

  // Record this attacker with a timestamp (attacks within 5 seconds count)
  room.state._attackLog[targetId][attackerId] = now;

  // Clean stale entries (older than 5 seconds)
  const ATTACK_WINDOW_MS = 5000;
  const log = room.state._attackLog[targetId];
  for (const [pid, timestamp] of Object.entries(log)) {
    if (now - timestamp > ATTACK_WINDOW_MS) {
      delete log[pid];
    }
  }

  const attackers = Object.keys(log);
  const bonusApplied = attackers.length >= COOP_MIN_ATTACKERS;
  const finalDamage = bonusApplied
    ? Math.round(baseDamage * (1 + COOP_DAMAGE_BONUS))
    : baseDamage;

  return { finalDamage, bonusApplied, attackers };
}

/**
 * Distribute loot equally among all players in the room.
 * @param {string} roomId
 * @param {object[]} lootItems - Array of loot items to distribute.
 * @returns {object} Map of playerId -> assigned loot items.
 */
function distributeSharedLoot(roomId, lootItems) {
  const players = getPlayersInRoom(roomId);
  if (!players || players.length === 0 || !lootItems || lootItems.length === 0) {
    return {};
  }

  const distribution = {};
  for (const player of players) {
    distribution[player.id] = [];
  }

  // Round-robin distribution
  lootItems.forEach((item, index) => {
    const recipient = players[index % players.length];
    distribution[recipient.id].push(item);
  });

  return distribution;
}

/**
 * Apply partial healing to nearby players when one player heals.
 * @param {string} roomId
 * @param {string} healerId - Player who cast the heal.
 * @param {number} healAmount - Base heal amount.
 * @returns {object[]} Array of { playerId, healReceived } for splash targets.
 */
function applySplashHealing(roomId, healerId, healAmount) {
  const players = getPlayersInRoom(roomId);
  if (!players) return [];

  const splashHeal = Math.round(healAmount * COOP_HEAL_SPLASH_RATIO);
  const results = [];

  for (const player of players) {
    // Skip the healer themselves (they get the full heal from the caller)
    if (player.id === healerId) continue;

    results.push({
      playerId: player.id,
      playerName: player.name || player.id,
      healReceived: splashHeal,
    });
  }

  return results;
}

// ---------------------------------------------------------------------------
// registerSyncHandlers - Main entry point for sync event registration
// ---------------------------------------------------------------------------
/**
 * Registers all synchronization-related Socket.IO event handlers.
 * @param {import('socket.io').Server} io - The Socket.IO server instance.
 * @param {import('socket.io').Socket} socket - The individual client socket.
 */
function registerSyncHandlers(io, socket) {

  // Track connection
  socket.on('registerPlayer', ({ playerId, roomId }) => {
    if (playerId) {
      connectedPlayers.set(socket.id, { playerId, roomId: roomId || null });
      console.log(`[Sync] Player ${playerId} registered (socket ${socket.id})`);
    }
  });

  // -- playerAction ---------------------------------------------------------
  // Broadcast a player's action (move, attack, defend, useItem, etc.)
  // to every other player in the room.
  // -------------------------------------------------------------------------
  socket.on('playerAction', ({ roomId, action }, callback) => {
    try {
      if (!roomId || !action) {
        return callback && callback({
          success: false,
          error: 'Accion invalida. Hasta la nada requiere mas esfuerzo.',
        });
      }

      const room = getRoom(roomId);
      if (!room) {
        return callback && callback({
          success: false,
          error: 'Sala no encontrada. Lanzas tu ataque al vacio, como siempre.',
        });
      }

      const playerId = socket.data.playerId;
      let enrichedAction = { ...action, playerId, timestamp: Date.now() };

      // If this is an attack, check for cooperative damage bonus
      if (action.type === 'attack' && action.targetId && action.damage != null) {
        const coopResult = calculateCooperativeDamage(
          roomId, action.targetId, action.damage, playerId
        );

        enrichedAction.damage = coopResult.finalDamage;
        enrichedAction.coopBonusApplied = coopResult.bonusApplied;

        if (coopResult.bonusApplied) {
          enrichedAction.coopMessage =
            'Ataque coordinado. El enemigo casi siente respeto por ustedes. Casi.';
        }
      }

      // If this is a heal, apply splash healing
      if (action.type === 'heal' && action.healAmount != null) {
        const splashResults = applySplashHealing(roomId, playerId, action.healAmount);
        enrichedAction.splashHealing = splashResults;

        if (splashResults.length > 0) {
          enrichedAction.splashMessage =
            'Tu curacion alcanza a tus aliados. No por bondad, sino por proximidad.';
        }
      }

      // Broadcast action to everyone else in the room
      socket.to(roomId).emit('playerAction', enrichedAction);

      // Update room activity
      updateRoomState(roomId, { lastActivity: Date.now() });

      callback && callback({ success: true, action: enrichedAction });
    } catch (err) {
      console.error('[Sync] Error in playerAction:', err);
      callback && callback({
        success: false,
        error: 'Error procesando accion. El universo ignora tu esfuerzo.',
      });
    }
  });

  // -- chatMessage ----------------------------------------------------------
  // Broadcast a chat message to all players in the room.
  // -------------------------------------------------------------------------
  socket.on('chatMessage', ({ roomId, message }, callback) => {
    try {
      if (!roomId || !message) {
        return callback && callback({
          success: false,
          error: 'Mensaje vacio. Tu silencio dice mas que tus palabras.',
        });
      }

      const room = getRoom(roomId);
      if (!room) {
        return callback && callback({
          success: false,
          error: 'Sala no encontrada. Gritas al abismo, y el abismo bosteza.',
        });
      }

      const playerId = socket.data.playerId;
      const players = getPlayersInRoom(roomId);
      const senderPlayer = players ? players.find(p => p.id === playerId) : null;

      const chatPayload = {
        senderId: playerId,
        senderName: senderPlayer ? senderPlayer.name : 'Desconocido',
        message: message.text || message,
        type: message.type || 'chat', // chat, emote, system
        timestamp: Date.now(),
      };

      // Broadcast to the entire room (including sender so they get confirmation)
      io.to(roomId).emit('chatMessage', chatPayload);

      updateRoomState(roomId, { lastActivity: Date.now() });

      callback && callback({ success: true });
    } catch (err) {
      console.error('[Sync] Error in chatMessage:', err);
      callback && callback({
        success: false,
        error: 'Error al enviar mensaje. Ni tus palabras llegan a destino.',
      });
    }
  });

  // -- playerUpdate ---------------------------------------------------------
  // Sync a player's state changes (HP, inventory, position, etc.)
  // -------------------------------------------------------------------------
  socket.on('playerUpdate', ({ roomId, updates }, callback) => {
    try {
      if (!roomId || !updates) {
        return callback && callback({
          success: false,
          error: 'Actualizacion vacia. Nada cambio. Como tu vida.',
        });
      }

      const room = getRoom(roomId);
      if (!room) {
        return callback && callback({
          success: false,
          error: 'Sala no encontrada.',
        });
      }

      const playerId = socket.data.playerId;

      // Update the player data in the room's player map
      if (room.players.has(playerId)) {
        const currentData = room.players.get(playerId);
        room.players.set(playerId, {
          ...currentData,
          ...updates,
          id: playerId, // Ensure ID cannot be overwritten
          isHost: currentData.isHost, // Protect host flag
          lastUpdate: Date.now(),
        });
      }

      // Broadcast the update to other players
      socket.to(roomId).emit('playerUpdate', {
        playerId,
        updates,
        timestamp: Date.now(),
      });

      updateRoomState(roomId, { lastActivity: Date.now() });

      callback && callback({ success: true });
    } catch (err) {
      console.error('[Sync] Error in playerUpdate:', err);
      callback && callback({
        success: false,
        error: 'Error sincronizando estado. Tus aliados no saben que existes.',
      });
    }
  });

  // -- dungeonProgress ------------------------------------------------------
  // Sync dungeon room transitions: when the party moves to the next room.
  // -------------------------------------------------------------------------
  socket.on('dungeonProgress', ({ roomId, progress }, callback) => {
    try {
      if (!roomId || progress == null) {
        return callback && callback({
          success: false,
          error: 'Progreso invalido. Avanzar requiere datos, no fe ciega.',
        });
      }

      const room = getRoom(roomId);
      if (!room) {
        return callback && callback({
          success: false,
          error: 'Sala no encontrada.',
        });
      }

      // Only the host can advance dungeon progress
      const playerId = socket.data.playerId;
      if (room.hostPlayerId !== playerId) {
        return callback && callback({
          success: false,
          error: 'Solo el lider puede avanzar. Obedece o crea tu propia sala.',
        });
      }

      const stateUpdates = {
        currentRoomIndex: progress.roomIndex != null
          ? progress.roomIndex
          : (room.state.currentRoomIndex + 1),
        combatActive: progress.combatActive || false,
        enemies: progress.enemies || [],
      };

      updateRoomState(roomId, stateUpdates);

      // Broadcast transition to all players in the room
      io.to(roomId).emit('dungeonProgress', {
        ...stateUpdates,
        message: stateUpdates.combatActive
          ? 'Nuevos enemigos aparecen. Al menos tendran algo que culpar por su fracaso.'
          : 'La sala esta vacia. Disfruten el silencio antes de la proxima masacre.',
        timestamp: Date.now(),
      });

      console.log(
        `[Sync] Room ${roomId} advanced to dungeon room ${stateUpdates.currentRoomIndex}`
      );

      callback && callback({ success: true, state: stateUpdates });
    } catch (err) {
      console.error('[Sync] Error in dungeonProgress:', err);
      callback && callback({
        success: false,
        error: 'Error al avanzar. El destino los quiere estancados.',
      });
    }
  });

  // -- cooperativeBonus -----------------------------------------------------
  // Apply cooperative bonuses when players are in the same dungeon room.
  // This is a query endpoint: clients ask what bonuses are active.
  // -------------------------------------------------------------------------
  socket.on('cooperativeBonus', ({ roomId, context }, callback) => {
    try {
      if (!roomId) {
        return callback && callback({
          success: false,
          error: 'Se requiere roomId.',
        });
      }

      const room = getRoom(roomId);
      if (!room) {
        return callback && callback({
          success: false,
          error: 'Sala no encontrada.',
        });
      }

      const players = getPlayersInRoom(roomId);
      const playerCount = players ? players.length : 0;

      const bonuses = {
        damageBonus: playerCount >= COOP_MIN_ATTACKERS ? COOP_DAMAGE_BONUS : 0,
        healSplash: playerCount >= 2 ? COOP_HEAL_SPLASH_RATIO : 0,
        sharedLoot: playerCount >= 2,
        playerCount,
        message: _getCoopMessage(playerCount),
      };

      // If loot distribution was requested, compute it
      if (context && context.type === 'loot' && context.lootItems) {
        bonuses.lootDistribution = distributeSharedLoot(roomId, context.lootItems);

        // Broadcast loot assignment to all players
        io.to(roomId).emit('lootDistributed', {
          distribution: bonuses.lootDistribution,
          message: 'El botin se reparte. Nadie estara satisfecho, como es tradicion.',
          timestamp: Date.now(),
        });
      }

      callback && callback({ success: true, bonuses });
    } catch (err) {
      console.error('[Sync] Error in cooperativeBonus:', err);
      callback && callback({
        success: false,
        error: 'Error calculando bonificaciones. Cooperar nunca fue su fuerte.',
      });
    }
  });

  // -- disconnect -----------------------------------------------------------
  // Handle player disconnections gracefully.
  // -------------------------------------------------------------------------
  socket.on('disconnect', (reason) => {
    const roomId = socket.data.roomId;
    const playerId = socket.data.playerId;

    console.log(
      `[Sync] Socket ${socket.id} disconnected (reason: ${reason})` +
      (playerId ? `, player: ${playerId}` : '')
    );

    // Clean up connected players tracking
    connectedPlayers.delete(socket.id);

    if (!roomId || !playerId) return;

    // Remove the player from their room
    const result = leaveRoom(roomId, playerId);

    if (result.success && !result.roomDeleted) {
      const remaining = getPlayersInRoom(roomId);

      // Notify remaining players
      socket.to(roomId).emit('playerDisconnected', {
        playerId,
        reason,
        message: 'Un jugador se ha desvanecido. La mazmorra no espera a nadie.',
        newHostId: result.newHostId || null,
        remainingPlayers: remaining,
      });

      // If only one player remains, warn them
      if (remaining && remaining.length === 1) {
        socket.to(roomId).emit('systemMessage', {
          type: 'warning',
          message: 'Eres el ultimo. La soledad y los monstruos te acompañan. Buena suerte.',
          timestamp: Date.now(),
        });
      }
    }

    if (result.roomDeleted) {
      console.log(`[Sync] Room ${roomId} deleted (last player disconnected)`);
    }
  });
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/**
 * Returns a cynical narrator message based on party size.
 * @param {number} playerCount
 * @returns {string}
 */
function _getCoopMessage(playerCount) {
  if (playerCount <= 1) {
    return 'Estas solo. Sin bonificaciones. Sin esperanza. Como siempre.';
  }
  if (playerCount === 2) {
    return 'Dos almas perdidas. +15% daño cooperativo. Al menos moriran juntos.';
  }
  if (playerCount === 3) {
    return 'Tres aventureros. Los bonos cooperativos estan activos. Casi parecen competentes.';
  }
  return 'Grupo completo. Bonificaciones maximas. Cuatro idiotas son mejor que uno.';
}

// ---------------------------------------------------------------------------
// Exports
// ---------------------------------------------------------------------------
module.exports = {
  registerSyncHandlers,
  calculateCooperativeDamage,
  distributeSharedLoot,
  applySplashHealing,
  connectedPlayers,
  COOP_DAMAGE_BONUS,
  COOP_HEAL_SPLASH_RATIO,
  COOP_MIN_ATTACKERS,
};
