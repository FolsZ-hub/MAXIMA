/**
 * Player Model
 *
 * Represents a player account in MAXIMA. A player may own multiple legacy
 * characters and accumulate SmartCoins (in-game currency).
 */

const { v4: uuidv4 } = require('uuid');

class Player {
  /**
   * @param {Object} data
   * @param {string}   data.uid              - Unique player identifier (Firebase Auth UID)
   * @param {string}   data.username          - Display name
   * @param {number}  [data.smartCoins=0]     - In-game currency balance
   * @param {Array}   [data.legacyCharacters] - Array of character IDs owned by the player
   * @param {Object}  [data.settings]         - Player-specific settings / preferences
   * @param {string}  [data.activeCharacterId]- Currently selected character ID
   * @param {string}  [data.createdAt]        - ISO timestamp of account creation
   * @param {string}  [data.lastLogin]        - ISO timestamp of last login
   */
  constructor({
    uid,
    username,
    smartCoins = 0,
    legacyCharacters = [],
    settings = {},
    activeCharacterId = null,
    createdAt = null,
    lastLogin = null,
  }) {
    this.uid = uid;
    this.username = username;
    this.smartCoins = smartCoins;
    this.legacyCharacters = legacyCharacters;
    this.settings = {
      language: 'es',        // Idioma predeterminado: espanol
      notifications: true,
      soundEnabled: true,
      ...settings,
    };
    this.activeCharacterId = activeCharacterId;
    this.createdAt = createdAt || new Date().toISOString();
    this.lastLogin = lastLogin || new Date().toISOString();
  }

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  /**
   * Convert this player instance to a plain object suitable for Firestore.
   * @returns {Object}
   */
  toFirestore() {
    return {
      uid: this.uid,
      username: this.username,
      smartCoins: this.smartCoins,
      legacyCharacters: this.legacyCharacters,
      settings: this.settings,
      activeCharacterId: this.activeCharacterId,
      createdAt: this.createdAt,
      lastLogin: this.lastLogin,
    };
  }

  /**
   * Create a Player instance from a Firestore document snapshot.
   * @param {Object} doc - Firestore document data
   * @returns {Player}
   */
  static fromFirestore(doc) {
    const data = doc.data ? doc.data() : doc;
    return new Player({
      uid: data.uid,
      username: data.username,
      smartCoins: data.smartCoins || 0,
      legacyCharacters: data.legacyCharacters || [],
      settings: data.settings || {},
      activeCharacterId: data.activeCharacterId || null,
      createdAt: data.createdAt || null,
      lastLogin: data.lastLogin || null,
    });
  }

  // ---------------------------------------------------------------------------
  // SmartCoins management
  // ---------------------------------------------------------------------------

  /**
   * Add (or subtract) SmartCoins. Balance will never drop below zero.
   * @param {number} amount - Positive to add, negative to subtract
   * @returns {number} The new balance
   */
  addSmartCoins(amount) {
    if (typeof amount !== 'number' || isNaN(amount)) {
      throw new Error('addSmartCoins: amount must be a valid number');
    }

    this.smartCoins = Math.max(0, this.smartCoins + amount);
    return this.smartCoins;
  }

  // ---------------------------------------------------------------------------
  // Character helpers
  // ---------------------------------------------------------------------------

  /**
   * Get the currently active character ID.
   * Falls back to the first character in legacyCharacters if none is set.
   * @returns {string|null}
   */
  getActiveCharacter() {
    if (this.activeCharacterId) {
      return this.activeCharacterId;
    }

    // Fallback: use the first character if available
    if (this.legacyCharacters.length > 0) {
      this.activeCharacterId = this.legacyCharacters[0];
      return this.activeCharacterId;
    }

    // "El jugador no tiene personajes" - The player has no characters
    return null;
  }

  /**
   * Register a new character ID to this player's legacy roster.
   * @param {string} characterId
   */
  addCharacter(characterId) {
    if (!this.legacyCharacters.includes(characterId)) {
      this.legacyCharacters.push(characterId);
    }

    // Auto-select if this is the first character
    if (!this.activeCharacterId) {
      this.activeCharacterId = characterId;
    }
  }

  /**
   * Update the last login timestamp to now.
   */
  refreshLogin() {
    this.lastLogin = new Date().toISOString();
  }
}

module.exports = Player;
