/**
 * Character Model
 *
 * Represents a playable character in MAXIMA. Each character belongs to a
 * player and has RPG stats that grow via XP and level-ups.
 */

const { v4: uuidv4 } = require('uuid');

// ---------------------------------------------------------------------------
// Class-specific stat growth tables
// ---------------------------------------------------------------------------
// Each class defines how much each stat increases per level-up.
// "Guerrero" = Warrior, "Mago" = Mage, "Picaro" = Rogue, "Sanador" = Healer

const CLASS_STAT_GROWTH = {
  Guerrero: { maxHp: 12, attack: 4, defense: 3 },
  Mago:     { maxHp: 6,  attack: 5, defense: 1 },
  Picaro:   { maxHp: 8,  attack: 3, defense: 2 },
  Sanador:  { maxHp: 10, attack: 2, defense: 2 },
};

// Base stats for a brand-new level-1 character of each class
const CLASS_BASE_STATS = {
  Guerrero: { hp: 120, maxHp: 120, attack: 15, defense: 12 },
  Mago:     { hp: 70,  maxHp: 70,  attack: 20, defense: 5  },
  Picaro:   { hp: 90,  maxHp: 90,  attack: 18, defense: 8  },
  Sanador:  { hp: 100, maxHp: 100, attack: 10, defense: 10 },
};

// XP required to reach the next level: threshold[level] = xp needed
// Follows a simple quadratic curve: 100 * level^1.5 (rounded)
function xpForNextLevel(currentLevel) {
  return Math.floor(100 * Math.pow(currentLevel, 1.5));
}

// ---------------------------------------------------------------------------
// Character class
// ---------------------------------------------------------------------------

class Character {
  /**
   * @param {Object} data
   * @param {string}   [data.characterId]    - Unique character ID (auto-generated)
   * @param {string}    data.playerId        - Owner player UID
   * @param {string}    data.name            - Character display name
   * @param {string}    data.characterClass  - One of: Guerrero, Mago, Picaro, Sanador
   * @param {number}   [data.level=1]
   * @param {number}   [data.hp]
   * @param {number}   [data.maxHp]
   * @param {number}   [data.xp=0]
   * @param {number}   [data.attack]
   * @param {number}   [data.defense]
   * @param {Array}    [data.inventory]
   * @param {boolean}  [data.isAlive=true]
   * @param {string}   [data.createdAt]
   */
  constructor({
    characterId = null,
    playerId,
    name,
    characterClass,
    level = 1,
    hp = null,
    maxHp = null,
    xp = 0,
    attack = null,
    defense = null,
    inventory = [],
    isAlive = true,
    createdAt = null,
  }) {
    // Validate class
    if (!CLASS_BASE_STATS[characterClass]) {
      throw new Error(
        `Clase de personaje invalida: "${characterClass}". ` +
          `Opciones: ${Object.keys(CLASS_BASE_STATS).join(', ')}`
      );
    }

    const base = CLASS_BASE_STATS[characterClass];

    this.characterId = characterId || uuidv4();
    this.playerId = playerId;
    this.name = name;
    this.characterClass = characterClass;
    this.level = level;
    this.hp = hp !== null ? hp : base.hp;
    this.maxHp = maxHp !== null ? maxHp : base.maxHp;
    this.xp = xp;
    this.attack = attack !== null ? attack : base.attack;
    this.defense = defense !== null ? defense : base.defense;
    this.inventory = inventory;
    this.isAlive = isAlive;
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
      characterId: this.characterId,
      playerId: this.playerId,
      name: this.name,
      characterClass: this.characterClass,
      level: this.level,
      hp: this.hp,
      maxHp: this.maxHp,
      xp: this.xp,
      attack: this.attack,
      defense: this.defense,
      inventory: this.inventory,
      isAlive: this.isAlive,
      createdAt: this.createdAt,
    };
  }

  /**
   * Create a Character instance from a Firestore document.
   * @param {Object} doc - Firestore document data (or snapshot)
   * @returns {Character}
   */
  static fromFirestore(doc) {
    const data = doc.data ? doc.data() : doc;
    return new Character({
      characterId: data.characterId,
      playerId: data.playerId,
      name: data.name,
      characterClass: data.characterClass,
      level: data.level,
      hp: data.hp,
      maxHp: data.maxHp,
      xp: data.xp,
      attack: data.attack,
      defense: data.defense,
      inventory: data.inventory || [],
      isAlive: data.isAlive !== undefined ? data.isAlive : true,
      createdAt: data.createdAt || null,
    });
  }

  // ---------------------------------------------------------------------------
  // Combat
  // ---------------------------------------------------------------------------

  /**
   * Apply damage to the character, respecting defense.
   * Effective damage = max(1, rawDamage - defense).
   * If HP drops to 0, the character dies.
   *
   * @param {number} rawDamage - Incoming damage before defense reduction
   * @returns {{ damageTaken: number, remainingHp: number, died: boolean }}
   */
  takeDamage(rawDamage) {
    if (!this.isAlive) {
      // "Este personaje ya ha caido en batalla" - This character has already fallen
      return { damageTaken: 0, remainingHp: this.hp, died: false };
    }

    const effectiveDamage = Math.max(1, rawDamage - this.defense);
    this.hp = Math.max(0, this.hp - effectiveDamage);

    if (this.hp === 0) {
      this.isAlive = false;
    }

    return {
      damageTaken: effectiveDamage,
      remainingHp: this.hp,
      died: !this.isAlive,
    };
  }

  /**
   * Heal the character by a given amount. Cannot exceed maxHp.
   * Dead characters cannot be healed (use revive first).
   *
   * @param {number} amount - HP to restore
   * @returns {{ healed: number, currentHp: number }}
   */
  heal(amount) {
    if (!this.isAlive) {
      // "No se puede curar a un personaje caido" - Cannot heal a fallen character
      return { healed: 0, currentHp: this.hp };
    }

    const before = this.hp;
    this.hp = Math.min(this.maxHp, this.hp + Math.max(0, amount));
    const healed = this.hp - before;

    return { healed, currentHp: this.hp };
  }

  /**
   * Revive a dead character with a percentage of max HP.
   * @param {number} [hpPercent=0.5] - Fraction of maxHp to restore (0.0 - 1.0)
   * @returns {boolean} true if revived, false if was already alive
   */
  revive(hpPercent = 0.5) {
    if (this.isAlive) return false;

    this.isAlive = true;
    this.hp = Math.max(1, Math.floor(this.maxHp * hpPercent));
    return true;
  }

  // ---------------------------------------------------------------------------
  // Progression
  // ---------------------------------------------------------------------------

  /**
   * Add XP and trigger level-ups as needed.
   * @param {number} amount - XP to add
   * @returns {{ newXp: number, levelsGained: number, newLevel: number }}
   */
  addXp(amount) {
    if (amount <= 0) {
      return { newXp: this.xp, levelsGained: 0, newLevel: this.level };
    }

    this.xp += amount;
    let levelsGained = 0;

    // Check for multiple level-ups in case of large XP gains
    while (this.xp >= xpForNextLevel(this.level)) {
      this.xp -= xpForNextLevel(this.level);
      this.levelUp();
      levelsGained++;
    }

    return {
      newXp: this.xp,
      levelsGained,
      newLevel: this.level,
    };
  }

  /**
   * Level up: increase level and boost stats based on character class.
   * HP is fully restored on level-up.
   */
  levelUp() {
    const growth = CLASS_STAT_GROWTH[this.characterClass];

    if (!growth) {
      // Fallback for unknown classes (should not happen due to constructor check)
      this.level++;
      return;
    }

    this.level++;
    this.maxHp += growth.maxHp;
    this.attack += growth.attack;
    this.defense += growth.defense;

    // Full heal on level-up - "El poder recorre tu cuerpo" (Power surges through your body)
    this.hp = this.maxHp;
  }

  // ---------------------------------------------------------------------------
  // Utility
  // ---------------------------------------------------------------------------

  /**
   * Get the XP required to reach the next level.
   * @returns {number}
   */
  xpToNextLevel() {
    return xpForNextLevel(this.level);
  }

  /**
   * Return a brief summary string for display in chat.
   * @returns {string}
   */
  getSummary() {
    const status = this.isAlive ? 'Vivo' : 'Caido';
    return (
      `[${this.characterClass}] ${this.name} | ` +
      `Nv.${this.level} | HP: ${this.hp}/${this.maxHp} | ` +
      `ATK: ${this.attack} DEF: ${this.defense} | ${status}`
    );
  }
}

// Export the class and helpers so other modules can use them
module.exports = Character;
module.exports.CLASS_STAT_GROWTH = CLASS_STAT_GROWTH;
module.exports.CLASS_BASE_STATS = CLASS_BASE_STATS;
module.exports.xpForNextLevel = xpForNextLevel;
