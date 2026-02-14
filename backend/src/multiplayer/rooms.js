// rooms.js - Room Management for MAXIMA RPG
// Manages multiplayer game rooms: creation, joining, leaving, and state tracking.

const { v4: uuidv4 } = require('uuid');

// ---------------------------------------------------------------------------
// In-memory store of active rooms
// Key: roomId (string), Value: room object
// ---------------------------------------------------------------------------
const activeRooms = new Map();

const MAX_PLAYERS_PER_ROOM = 4;

// ---------------------------------------------------------------------------
// createRoom - Create a new game room for a dungeon session
// ---------------------------------------------------------------------------
/**
 * Creates a new room tied to a specific dungeon.
 * @param {string} dungeonId - The dungeon this room is running.
 * @param {object} hostPlayer - The player who created the room.
 *   Expected shape: { id, name, class, level, hp, maxHp, stats }
 * @returns {object} The newly created room.
 */
function createRoom(dungeonId, hostPlayer) {
  const roomId = uuidv4();

  const room = {
    id: roomId,
    dungeonId,
    hostPlayerId: hostPlayer.id,
    maxPlayers: MAX_PLAYERS_PER_ROOM,
    players: new Map(),
    state: {
      currentRoomIndex: 0,   // Which dungeon room the party is in
      combatActive: false,
      enemies: [],
      lootPool: [],
      startedAt: Date.now(),
      lastActivity: Date.now(),
    },
    createdAt: Date.now(),
  };

  // Add the host as the first player
  room.players.set(hostPlayer.id, {
    ...hostPlayer,
    joinedAt: Date.now(),
    ready: true,
    isHost: true,
  });

  activeRooms.set(roomId, room);
  return room;
}

// ---------------------------------------------------------------------------
// joinRoom - Add a player to an existing room
// ---------------------------------------------------------------------------
/**
 * Adds a player to a room if it exists and is not full.
 * @param {string} roomId
 * @param {object} player - Player data (same shape as hostPlayer in createRoom).
 * @returns {{ success: boolean, room?: object, error?: string }}
 */
function joinRoom(roomId, player) {
  const room = activeRooms.get(roomId);

  if (!room) {
    return {
      success: false,
      error: 'La sala no existe. Quizas nunca existio. Como tus esperanzas.',
    };
  }

  if (room.players.size >= room.maxPlayers) {
    return {
      success: false,
      error: 'La sala esta llena. Hasta el sufrimiento tiene un aforo maximo.',
    };
  }

  if (room.players.has(player.id)) {
    return {
      success: false,
      error: 'Ya estas en esta sala. La repeticion no cambiara tu destino.',
    };
  }

  room.players.set(player.id, {
    ...player,
    joinedAt: Date.now(),
    ready: false,
    isHost: false,
  });

  room.state.lastActivity = Date.now();

  return { success: true, room };
}

// ---------------------------------------------------------------------------
// leaveRoom - Remove a player from a room
// ---------------------------------------------------------------------------
/**
 * Removes a player from a room. Deletes the room if it becomes empty.
 * If the host leaves, ownership transfers to the next player.
 * @param {string} roomId
 * @param {string} playerId
 * @returns {{ success: boolean, roomDeleted: boolean, newHostId?: string, error?: string }}
 */
function leaveRoom(roomId, playerId) {
  const room = activeRooms.get(roomId);

  if (!room) {
    return { success: false, roomDeleted: false, error: 'Sala no encontrada.' };
  }

  if (!room.players.has(playerId)) {
    return {
      success: false,
      roomDeleted: false,
      error: 'No estas en esta sala. No puedes huir de donde nunca estuviste.',
    };
  }

  room.players.delete(playerId);

  // If the room is now empty, delete it entirely
  if (room.players.size === 0) {
    activeRooms.delete(roomId);
    return { success: true, roomDeleted: true };
  }

  // If the leaving player was the host, transfer ownership
  let newHostId = null;
  if (room.hostPlayerId === playerId) {
    const nextPlayer = room.players.values().next().value;
    newHostId = nextPlayer.id;
    nextPlayer.isHost = true;
    room.hostPlayerId = newHostId;
  }

  room.state.lastActivity = Date.now();

  return { success: true, roomDeleted: false, newHostId };
}

// ---------------------------------------------------------------------------
// getRoomState - Return the current state of a room
// ---------------------------------------------------------------------------
/**
 * @param {string} roomId
 * @returns {object|null} The room state or null if room doesn't exist.
 */
function getRoomState(roomId) {
  const room = activeRooms.get(roomId);
  if (!room) return null;
  return room.state;
}

// ---------------------------------------------------------------------------
// getPlayersInRoom - List all players in a room
// ---------------------------------------------------------------------------
/**
 * @param {string} roomId
 * @returns {object[]|null} Array of player objects, or null if room not found.
 */
function getPlayersInRoom(roomId) {
  const room = activeRooms.get(roomId);
  if (!room) return null;
  return Array.from(room.players.values());
}

// ---------------------------------------------------------------------------
// updateRoomState - Merge partial updates into a room's state
// ---------------------------------------------------------------------------
/**
 * @param {string} roomId
 * @param {object} updates - Partial state to merge.
 * @returns {boolean} True if the room was found and updated.
 */
function updateRoomState(roomId, updates) {
  const room = activeRooms.get(roomId);
  if (!room) return false;

  room.state = {
    ...room.state,
    ...updates,
    lastActivity: Date.now(),
  };

  return true;
}

// ---------------------------------------------------------------------------
// serializeRoom - Convert a room to a plain JSON-safe object
// (Maps are not JSON-serializable)
// ---------------------------------------------------------------------------
function serializeRoom(room) {
  if (!room) return null;
  return {
    id: room.id,
    dungeonId: room.dungeonId,
    hostPlayerId: room.hostPlayerId,
    maxPlayers: room.maxPlayers,
    playerCount: room.players.size,
    players: Array.from(room.players.values()),
    state: room.state,
    createdAt: room.createdAt,
  };
}

// ---------------------------------------------------------------------------
// getAvailableRooms - List all rooms that still have open slots
// ---------------------------------------------------------------------------
function getAvailableRooms() {
  const rooms = [];
  for (const room of activeRooms.values()) {
    if (room.players.size < room.maxPlayers) {
      rooms.push(serializeRoom(room));
    }
  }
  return rooms;
}

// ---------------------------------------------------------------------------
// registerRoomHandlers - Attach Socket.IO event listeners for room management
// ---------------------------------------------------------------------------
/**
 * Registers socket events related to room lifecycle.
 * @param {import('socket.io').Server} io - The Socket.IO server instance.
 * @param {import('socket.io').Socket} socket - The individual client socket.
 */
function registerRoomHandlers(io, socket) {

  // -- createRoom -----------------------------------------------------------
  socket.on('createRoom', ({ dungeonId, player }, callback) => {
    try {
      if (!dungeonId || !player || !player.id) {
        return callback({
          success: false,
          error: 'Datos insuficientes. Ni el caos se organiza solo.',
        });
      }

      const room = createRoom(dungeonId, player);
      const roomId = room.id;

      // The creator joins the Socket.IO room channel
      socket.join(roomId);
      // Store the roomId on the socket for disconnect handling
      socket.data.roomId = roomId;
      socket.data.playerId = player.id;

      console.log(
        `[Rooms] Room ${roomId} created by ${player.name || player.id} for dungeon ${dungeonId}`
      );

      callback({ success: true, room: serializeRoom(room) });
    } catch (err) {
      console.error('[Rooms] Error creating room:', err);
      callback({
        success: false,
        error: 'Error interno al crear la sala. El destino conspira en tu contra.',
      });
    }
  });

  // -- joinRoom -------------------------------------------------------------
  socket.on('joinRoom', ({ roomId, player }, callback) => {
    try {
      if (!roomId || !player || !player.id) {
        return callback({
          success: false,
          error: 'Faltan datos. Intenta de nuevo, si es que te importa.',
        });
      }

      const result = joinRoom(roomId, player);

      if (!result.success) {
        return callback({ success: false, error: result.error });
      }

      // Join the Socket.IO channel
      socket.join(roomId);
      socket.data.roomId = roomId;
      socket.data.playerId = player.id;

      // Notify everyone else in the room
      socket.to(roomId).emit('playerJoined', {
        player,
        message: `${player.name || 'Un alma perdida'} se ha unido a la sala. Otro mas para el sacrificio.`,
        playerCount: result.room.players.size,
      });

      console.log(`[Rooms] ${player.name || player.id} joined room ${roomId}`);

      callback({ success: true, room: serializeRoom(result.room) });
    } catch (err) {
      console.error('[Rooms] Error joining room:', err);
      callback({
        success: false,
        error: 'Error al unirse. Hasta las puertas te rechazan.',
      });
    }
  });

  // -- leaveRoom ------------------------------------------------------------
  socket.on('leaveRoom', (callback) => {
    try {
      const roomId = socket.data.roomId;
      const playerId = socket.data.playerId;

      if (!roomId || !playerId) {
        return callback({
          success: false,
          error: 'No estas en ninguna sala. La soledad es tu unica compañera.',
        });
      }

      const result = leaveRoom(roomId, playerId);

      if (!result.success) {
        return callback({ success: false, error: result.error });
      }

      // Notify remaining players before leaving the channel
      if (!result.roomDeleted) {
        const remaining = getPlayersInRoom(roomId);
        socket.to(roomId).emit('playerLeft', {
          playerId,
          message: `Un cobarde ha abandonado el grupo. Los que quedan cargaran con su vergüenza.`,
          newHostId: result.newHostId || null,
          remainingPlayers: remaining,
        });
      }

      // Leave the Socket.IO channel
      socket.leave(roomId);
      socket.data.roomId = null;
      socket.data.playerId = null;

      console.log(`[Rooms] Player ${playerId} left room ${roomId}`);

      callback({
        success: true,
        roomDeleted: result.roomDeleted,
      });
    } catch (err) {
      console.error('[Rooms] Error leaving room:', err);
      callback({
        success: false,
        error: 'Error al salir. Ni escapar te sale bien.',
      });
    }
  });

  // -- getRooms -------------------------------------------------------------
  socket.on('getRooms', (callback) => {
    try {
      const rooms = getAvailableRooms();
      callback({
        success: true,
        rooms,
        message: rooms.length > 0
          ? 'Salas disponibles. Elige tu perdicion.'
          : 'No hay salas. Crea una y arrastra a otros contigo.',
      });
    } catch (err) {
      console.error('[Rooms] Error listing rooms:', err);
      callback({
        success: false,
        error: 'Error al listar salas. El vacio te mira de vuelta.',
      });
    }
  });
}

// ---------------------------------------------------------------------------
// Exports
// ---------------------------------------------------------------------------
module.exports = {
  activeRooms,
  createRoom,
  joinRoom,
  leaveRoom,
  getRoomState,
  getPlayersInRoom,
  updateRoomState,
  serializeRoom,
  getAvailableRooms,
  registerRoomHandlers,
  MAX_PLAYERS_PER_ROOM,
};
