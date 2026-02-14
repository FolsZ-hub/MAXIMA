/**
 * Rate Limiter Middleware for Socket.IO
 *
 * Prevents command spam by enforcing per-socket cooldowns:
 *   - Attack commands:  2 000 ms cooldown
 *   - All other commands: 1 000 ms cooldown
 *
 * When a player sends commands too quickly, the socket receives a
 * 'rateLimited' event with details about the remaining wait time.
 */

// Cooldown durations in milliseconds
const COOLDOWN_ATTACK_MS = 2000;
const COOLDOWN_DEFAULT_MS = 1000;

// Events that use the longer (attack) cooldown
const ATTACK_EVENTS = new Set([
  'combat:attack',
  'combat:skill',
  'combat:special',
  'dungeon:attack',
]);

// Events that should bypass the rate limiter entirely (system / internal)
const EXEMPT_EVENTS = new Set([
  'player:join',
  'disconnect',
  'disconnecting',
  'error',
  'ping',
  'pong',
]);

/**
 * Create a rate-limiter middleware function bound to a specific socket.
 *
 * Usage inside server.js:
 *   const rateLimiter = createRateLimiter(socket);
 *   socket.use(rateLimiter);
 *
 * @param {import('socket.io').Socket} socket - The socket to rate-limit
 * @returns {Function} Socket.IO middleware (packet, next)
 */
function createRateLimiter(socket) {
  // Map of eventName -> last invocation timestamp
  const lastCommandTime = new Map();

  /**
   * Socket.IO middleware signature: receives the raw packet array and a next
   * callback. Calling next() forwards the event; calling next(error) blocks it.
   */
  return function rateLimitMiddleware(packet, next) {
    const eventName = packet[0];

    // Let exempt (system) events pass through immediately
    if (EXEMPT_EVENTS.has(eventName)) {
      return next();
    }

    const now = Date.now();
    const cooldown = ATTACK_EVENTS.has(eventName) ? COOLDOWN_ATTACK_MS : COOLDOWN_DEFAULT_MS;
    const lastTime = lastCommandTime.get(eventName) || 0;
    const elapsed = now - lastTime;

    if (elapsed < cooldown) {
      const remaining = cooldown - elapsed;

      // Notify the client they are being rate-limited
      // "Demasiado rapido! Espera un momento." - Too fast! Wait a moment.
      socket.emit('rateLimited', {
        event: eventName,
        cooldownMs: cooldown,
        remainingMs: remaining,
        message: `Demasiado rapido! Espera ${(remaining / 1000).toFixed(1)}s antes de usar "${eventName}" de nuevo.`,
      });

      // Block the event from reaching its handler
      return next(new Error('Rate limited'));
    }

    // Record this invocation and allow the event through
    lastCommandTime.set(eventName, now);
    return next();
  };
}

module.exports = { createRateLimiter, COOLDOWN_ATTACK_MS, COOLDOWN_DEFAULT_MS };
