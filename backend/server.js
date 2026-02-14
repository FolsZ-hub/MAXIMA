/**
 * MAXIMA RPG Backend - Main Entry Point
 *
 * Sets up Express + Socket.IO server with CORS, registers all game modules,
 * and handles player connection/disconnection lifecycle events.
 */

require('dotenv').config();

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

// Firebase initialization (must run before any module that uses Firestore)
const { db, admin } = require('./src/config/firebase');

// Middleware
const { createRateLimiter } = require('./src/middleware/rateLimit');

// Models (preload so they are available to game modules)
const Player = require('./src/models/player');
const Character = require('./src/models/character');
const Dungeon = require('./src/models/dungeon');

// Game modules
const { registerCombatHandlers } = require('./src/game/combat');
const { registerCommandHandlers } = require('./src/game/commands');
const { registerDungeonHandlers } = require('./src/game/dungeon');
const { registerLegacyHandlers } = require('./src/game/legacy');

// Multiplayer modules
const { registerRoomHandlers } = require('./src/multiplayer/rooms');
const { registerSyncHandlers } = require('./src/multiplayer/sync');

// ---------------------------------------------------------------------------
// Express application setup
// ---------------------------------------------------------------------------

const app = express();
const server = http.createServer(app);

// Parse allowed CORS origins from environment
const allowedOrigins = (process.env.CORS_ORIGINS || 'http://localhost:5173')
  .split(',')
  .map((origin) => origin.trim());

app.use(cors({ origin: allowedOrigins, credentials: true }));
app.use(express.json());

// Health-check endpoint
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ---------------------------------------------------------------------------
// Socket.IO setup
// ---------------------------------------------------------------------------

const io = new Server(server, {
  cors: {
    origin: allowedOrigins,
    methods: ['GET', 'POST'],
    credentials: true,
  },
  // Ping every 25 s, timeout after 60 s of silence
  pingInterval: 25000,
  pingTimeout: 60000,
});

// Track connected players: socketId -> { uid, username }
const connectedPlayers = new Map();

/**
 * Register command handlers from game modules.
 *
 * Each game module is expected to export a function with the signature:
 *   (socket, io, { connectedPlayers, db, admin }) => void
 *
 * Inside that function the module attaches its own socket.on(...) listeners.
 */
function registerGameModules(socket) {
  // Register game logic handlers
  registerCombatHandlers(io, socket);
  registerCommandHandlers(io, socket);
  registerDungeonHandlers(io, socket);
  registerLegacyHandlers(io, socket);

  // Register multiplayer handlers
  registerRoomHandlers(io, socket);
  registerSyncHandlers(io, socket);
}

// ---------------------------------------------------------------------------
// Connection lifecycle
// ---------------------------------------------------------------------------

io.on('connection', (socket) => {
  console.log(`[MAXIMA] Nueva conexion: ${socket.id}`);

  // Attach rate-limiter middleware to this socket
  const rateLimiter = createRateLimiter(socket);
  socket.use(rateLimiter);

  // --- Player authentication / join ------------------------------------------

  socket.on('player:join', async (data, callback) => {
    try {
      const { uid, username } = data;

      if (!uid || !username) {
        return callback && callback({ success: false, error: 'uid and username are required' });
      }

      // Store player reference
      connectedPlayers.set(socket.id, { uid, username });
      socket.join(`player:${uid}`);

      console.log(
        `[MAXIMA] Jugador conectado: ${username} (${uid}) | socket ${socket.id}`
      );

      // Notify other players
      // "Un nuevo aventurero ha llegado" - A new adventurer has arrived
      socket.broadcast.emit('player:joined', {
        uid,
        username,
        message: `Un nuevo aventurero ha llegado: ${username}`,
      });

      if (callback) {
        callback({ success: true, message: `Bienvenido a MAXIMA, ${username}!` });
      }
    } catch (err) {
      console.error('[MAXIMA] Error en player:join:', err);
      if (callback) {
        callback({ success: false, error: 'Internal server error' });
      }
    }
  });

  // --- Register all game module handlers ------------------------------------

  registerGameModules(socket);

  // --- Disconnection ---------------------------------------------------------

  socket.on('disconnect', (reason) => {
    const playerInfo = connectedPlayers.get(socket.id);

    if (playerInfo) {
      console.log(
        `[MAXIMA] Jugador desconectado: ${playerInfo.username} (${playerInfo.uid}) | razon: ${reason}`
      );

      // "El aventurero se ha marchado" - The adventurer has departed
      socket.broadcast.emit('player:left', {
        uid: playerInfo.uid,
        username: playerInfo.username,
        message: `El aventurero ${playerInfo.username} se ha marchado.`,
      });

      connectedPlayers.delete(socket.id);
    } else {
      console.log(`[MAXIMA] Socket desconectado: ${socket.id} | razon: ${reason}`);
    }
  });

  // --- Generic error handler -------------------------------------------------

  socket.on('error', (err) => {
    console.error(`[MAXIMA] Error en socket ${socket.id}:`, err);
  });
});

// ---------------------------------------------------------------------------
// Start the server
// ---------------------------------------------------------------------------

const PORT = parseInt(process.env.PORT, 10) || 3000;

server.listen(PORT, () => {
  console.log('=====================================================');
  console.log(`  MAXIMA RPG Backend corriendo en el puerto ${PORT}`);
  console.log(`  Entorno: ${process.env.NODE_ENV || 'development'}`);
  console.log(`  CORS origenes: ${allowedOrigins.join(', ')}`);
  console.log('=====================================================');
});

module.exports = { app, server, io };
