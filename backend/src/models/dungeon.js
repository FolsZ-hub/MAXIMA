/**
 * Dungeon Model
 *
 * Represents a dungeon instance in MAXIMA. Dungeons contain a sequence of
 * rooms, each potentially holding enemies and loot. Players progress through
 * rooms to earn rewards.
 */

const { v4: uuidv4 } = require('uuid');

// ---------------------------------------------------------------------------
// Difficulty presets
// ---------------------------------------------------------------------------

const DIFFICULTY_SETTINGS = {
  // "Facil" = Easy, "Normal" = Normal, "Dificil" = Hard, "Pesadilla" = Nightmare
  Facil:     { enemyHpMultiplier: 0.8, enemyAtkMultiplier: 0.8, rewardMultiplier: 1.0 },
  Normal:    { enemyHpMultiplier: 1.0, enemyAtkMultiplier: 1.0, rewardMultiplier: 1.5 },
  Dificil:   { enemyHpMultiplier: 1.4, enemyAtkMultiplier: 1.3, rewardMultiplier: 2.0 },
  Pesadilla: { enemyHpMultiplier: 2.0, enemyAtkMultiplier: 1.8, rewardMultiplier: 3.0 },
};

// ---------------------------------------------------------------------------
// Dungeon class
// ---------------------------------------------------------------------------

class Dungeon {
  /**
   * @param {Object}  data
   * @param {string}  [data.dungeonId]      - Unique dungeon instance ID
   * @param {string}   data.name            - Display name of the dungeon
   * @param {string}  [data.difficulty]     - One of: Facil, Normal, Dificil, Pesadilla
   * @param {Array}   [data.rooms]          - Ordered array of room objects
   * @param {Array}   [data.enemies]        - Enemy templates available in this dungeon
   * @param {Object}  [data.reward]         - Reward granted upon completion
   * @param {number}  [data.currentRoom=0]  - Index of the room the party is currently in
   * @param {string}  [data.status]         - Dungeon status: active, completed, failed
   * @param {string}  [data.createdAt]
   */
  constructor({
    dungeonId = null,
    name,
    difficulty = 'Normal',
    rooms = [],
    enemies = [],
    reward = null,
    currentRoom = 0,
    status = 'active',
    createdAt = null,
  }) {
    // Validate difficulty
    if (!DIFFICULTY_SETTINGS[difficulty]) {
      throw new Error(
        `Dificultad invalida: "${difficulty}". ` +
          `Opciones: ${Object.keys(DIFFICULTY_SETTINGS).join(', ')}`
      );
    }

    this.dungeonId = dungeonId || uuidv4();
    this.name = name;
    this.difficulty = difficulty;
    this.rooms = rooms;
    this.enemies = enemies;
    this.reward = reward || { smartCoins: 0, xp: 0, items: [] };
    this.currentRoom = currentRoom;
    this.status = status;
    this.createdAt = createdAt || new Date().toISOString();
  }

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  /**
   * Convert to a plain object for Firestore storage.
   * @returns {Object}
   */
  toFirestore() {
    return {
      dungeonId: this.dungeonId,
      name: this.name,
      difficulty: this.difficulty,
      rooms: this.rooms,
      enemies: this.enemies,
      reward: this.reward,
      currentRoom: this.currentRoom,
      status: this.status,
      createdAt: this.createdAt,
    };
  }

  /**
   * Create a Dungeon instance from a Firestore document.
   * @param {Object} doc - Firestore document data (or snapshot)
   * @returns {Dungeon}
   */
  static fromFirestore(doc) {
    const data = doc.data ? doc.data() : doc;
    return new Dungeon({
      dungeonId: data.dungeonId,
      name: data.name,
      difficulty: data.difficulty || 'Normal',
      rooms: data.rooms || [],
      enemies: data.enemies || [],
      reward: data.reward || { smartCoins: 0, xp: 0, items: [] },
      currentRoom: data.currentRoom || 0,
      status: data.status || 'active',
      createdAt: data.createdAt || null,
    });
  }

  // ---------------------------------------------------------------------------
  // Room navigation
  // ---------------------------------------------------------------------------

  /**
   * Get the current room object.
   * @returns {Object|null}
   */
  getCurrentRoom() {
    if (this.currentRoom < 0 || this.currentRoom >= this.rooms.length) {
      return null;
    }
    return this.rooms[this.currentRoom];
  }

  /**
   * Advance to the next room.
   * @returns {{ advanced: boolean, room: Object|null, completed: boolean }}
   */
  advanceRoom() {
    if (this.status !== 'active') {
      return { advanced: false, room: null, completed: this.status === 'completed' };
    }

    const nextIndex = this.currentRoom + 1;

    if (nextIndex >= this.rooms.length) {
      // "La mazmorra ha sido conquistada!" - The dungeon has been conquered!
      this.status = 'completed';
      return { advanced: false, room: null, completed: true };
    }

    this.currentRoom = nextIndex;
    return { advanced: true, room: this.rooms[nextIndex], completed: false };
  }

  // ---------------------------------------------------------------------------
  // Difficulty helpers
  // ---------------------------------------------------------------------------

  /**
   * Get the difficulty multipliers for this dungeon.
   * @returns {{ enemyHpMultiplier: number, enemyAtkMultiplier: number, rewardMultiplier: number }}
   */
  getDifficultySettings() {
    return DIFFICULTY_SETTINGS[this.difficulty] || DIFFICULTY_SETTINGS.Normal;
  }

  /**
   * Mark the dungeon as failed.
   */
  fail() {
    this.status = 'failed';
  }

  /**
   * Check whether the dungeon is still in progress.
   * @returns {boolean}
   */
  isActive() {
    return this.status === 'active';
  }

  /**
   * Return a brief summary string for display in chat.
   * @returns {string}
   */
  getSummary() {
    const roomProgress = `${this.currentRoom + 1}/${this.rooms.length}`;
    // "Mazmorra" = Dungeon
    return (
      `Mazmorra: ${this.name} | Dificultad: ${this.difficulty} | ` +
      `Sala: ${roomProgress} | Estado: ${this.status}`
    );
  }
}

module.exports = Dungeon;
module.exports.DIFFICULTY_SETTINGS = DIFFICULTY_SETTINGS;
