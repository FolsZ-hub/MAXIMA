/**
 * MAXIMA RPG - Procedural Dungeon Generation
 *
 * Generates dungeons with themed rooms, enemies, loot, and traps.
 * Supports three difficulty tiers and includes predefined story dungeons.
 *
 * Room types: CORRIDOR, TREASURE, TRAP, MERCHANT, BOSS, PUZZLE, REST
 */

const { randomInt, pickRandom, generateLoot, generateTreasureLoot } = require('./loot');
const { ENEMY_TEMPLATES, BOSS_TEMPLATES } = require('./combat');
const {
  getDungeonEntranceMessage,
  getPathChoiceMessage,
  getEnemyEncounterMessage,
  getTrapMessage,
  getMerchantMessage,
  getRandomEvent,
} = require('./master');

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const ROOM_TYPES = {
  CORRIDOR: 'corridor',
  TREASURE: 'treasure',
  TRAP: 'trap',
  MERCHANT: 'merchant',
  BOSS: 'boss',
  PUZZLE: 'puzzle',
  REST: 'rest',
};

const DIFFICULTY_CONFIG = {
  easy: { roomCount: 5, enemyTier: 'easy', bossCount: 0, trapChance: 15 },
  medium: { roomCount: 8, enemyTier: 'medium', bossCount: 1, trapChance: 25 },
  hard: { roomCount: 12, enemyTier: 'hard', bossCount: 2, trapChance: 35 },
};

// ---------------------------------------------------------------------------
// Room description templates (cynical narrator, Spanish)
// ---------------------------------------------------------------------------

const ROOM_DESCRIPTIONS = {
  [ROOM_TYPES.CORRIDOR]: [
    'Un pasillo largo y oscuro. El eco de tus pasos es tu unica compania. Bueno, eso y las aranas. Muchas aranas.',
    'Otro corredor identico al anterior. El arquitecto de esta mazmorra claramente tenia un presupuesto limitado y cero imaginacion.',
    'Un tunel estrecho donde las paredes gotean algo que prefieres no investigar. Huele a humedad y a arrepentimiento.',
    'Un pasadizo curvado que parece no terminar nunca. Como tu deuda con el mercader de la entrada.',
    'Las antorchas en las paredes iluminan un corredor de piedra. Algunas estan apagadas. Como tus esperanzas.',
  ],
  [ROOM_TYPES.TREASURE]: [
    '¡Una sala del tesoro! Cofres alineados contra la pared brillan con promesas de riqueza. Probablemente es una trampa. Pero el brillo... el brillo es irresistible.',
    'Entras a una camara llena de monedas y objetos relucientes. Alguien los dejo aqui. Ese alguien probablemente murio cerca. No pienses en eso.',
    'Un pequeño santuario con un pedestal dorado. Sobre el, un cofre ornamentado te invita a abrirlo. La palabra "invita" y "obliga" son intercambiables aqui.',
  ],
  [ROOM_TYPES.TRAP]: [
    'Esta sala se ve sospechosamente vacia. Demasiado limpia. Demasiado tranquila. Si tu sentido aracnido no te advierte, nada lo hara.',
    'El suelo tiene marcas de arañazos. Las paredes, agujeros diminutos. El techo, manchas oscuras. Todo esto grita "trampa" pero tu decides entrar igual.',
    'Una habitacion con un pasillo estrecho y baldosas de diferentes colores. No es un juego. Bueno, si lo es. Pero las consecuencias son reales.',
  ],
  [ROOM_TYPES.MERCHANT]: [
    'Una gruta sorprendentemente acogedora con una alfombra y un mostrador improvisado. El capitalismo sobrevive incluso en las mazmorras.',
    'Un rincón iluminado donde alguien ha montado una tienda. Hay estanterias con pociones, armas de segunda mano, y un cartel que dice "No se aceptan devoluciones."',
    'Una caverna convertida en mercado. Un comerciante te sonrie con demasiados dientes. La mitad no son suyos originalmente.',
  ],
  [ROOM_TYPES.BOSS]: [
    'La sala se abre en un espacio enorme. Columnas rotas flanquean un trono de huesos. Algo se mueve en las sombras. Algo grande. Algo hambriento.',
    'Un portal de energia oscura vibra en el centro de la habitacion. El aire es denso, electrico. Has llegado al final. O al final ha llegado a ti.',
    'La camara del jefe. Huesos de aventureros anteriores decoran el suelo como una alfombra macabra. Bienvenido al evento principal.',
  ],
  [ROOM_TYPES.PUZZLE]: [
    'Una habitacion con simbolos arcanos en las paredes y un mecanismo complejo en el centro. Requiere cerebro. Ojala hubieras traido uno.',
    'Ante ti hay tres palancas, un enigma grabado en piedra, y la sensacion de que tu CI esta siendo evaluado. Spoiler: el resultado no sera halagador.',
    'Una sala con baldosas que se iluminan en secuencia. Es un puzzle. La solucion incorrecta activa... bueno, algo malo. La correcta probablemente tambien.',
  ],
  [ROOM_TYPES.REST]: [
    'Una pequeña gruta con una fogata magica que no consume oxigeno. Puedes descansar aqui. Brevemente. La mazmorra no tiene paciencia.',
    'Un area de descanso con bancos de piedra y un manantial de agua limpia. El unico lugar en esta mazmorra donde no quieren matarte. Probablemente.',
    'Una sala segura. Relativamente. El fuego crepita, el agua fluye, y por un momento puedes fingir que no estas en un laberinto de muerte. Reconfortante.',
  ],
};

// ---------------------------------------------------------------------------
// Trap definitions
// ---------------------------------------------------------------------------

const TRAPS = {
  easy: [
    { name: 'Pinchos Oxidados', damage: 5, type: 'physical' },
    { name: 'Baldosa Resbaladiza', damage: 3, type: 'physical' },
    { name: 'Gas Somnoliento', damage: 4, type: 'magic' },
  ],
  medium: [
    { name: 'Flechas Envenenadas', damage: 12, type: 'physical' },
    { name: 'Fuego Griego', damage: 15, type: 'fire' },
    { name: 'Runas Explosivas', damage: 10, type: 'magic' },
    { name: 'Foso de Acido', damage: 18, type: 'physical' },
  ],
  hard: [
    { name: 'Guillotina Pendular', damage: 25, type: 'physical' },
    { name: 'Tormenta de Cuchillas', damage: 30, type: 'physical' },
    { name: 'Maldicion de Agonia', damage: 20, type: 'magic' },
    { name: 'Explosion Arcana', damage: 35, type: 'magic' },
    { name: 'Trampa Dimensional', damage: 28, type: 'magic' },
  ],
};

// ---------------------------------------------------------------------------
// Merchant inventories
// ---------------------------------------------------------------------------

const MERCHANT_INVENTORIES = {
  easy: [
    { name: 'Pocion de Salud Menor', price: 5, type: 'potion' },
    { name: 'Pocion de Salud', price: 10, type: 'potion' },
    { name: 'Daga Oxidada', price: 8, type: 'weapon' },
    { name: 'Pergamino de Luz', price: 5, type: 'scroll' },
  ],
  medium: [
    { name: 'Pocion de Salud Mayor', price: 25, type: 'potion' },
    { name: 'Elixir de Fuerza', price: 30, type: 'potion' },
    { name: 'Espada de Acero Templado', price: 40, type: 'weapon' },
    { name: 'Pergamino de Bola de Fuego', price: 35, type: 'scroll' },
    { name: 'Cota de Malla Remendada', price: 35, type: 'armor' },
  ],
  hard: [
    { name: 'Pocion de Salud Suprema', price: 60, type: 'potion' },
    { name: 'Hoja de Sombras', price: 100, type: 'weapon' },
    { name: 'Pergamino de Tormenta Arcana', price: 80, type: 'scroll' },
    { name: 'Armadura de Escamas de Dragon', price: 120, type: 'armor' },
    { name: 'Frasco de Inmunidad', price: 75, type: 'potion' },
  ],
};

// ---------------------------------------------------------------------------
// Merchant name pool
// ---------------------------------------------------------------------------

const MERCHANT_NAMES = [
  'Rodrigo el Astuto',
  'Minerva la Tacaña',
  'Grak el Comerciante',
  'Doña Elvira',
  'El Viejo Braulio',
  'Sombra Mercantil',
  'Tuk-Tuk el Goblin Emprendedor',
];

// ---------------------------------------------------------------------------
// Path descriptions
// ---------------------------------------------------------------------------

const PATH_DESCRIPTIONS = [
  'Un pasillo oscuro hacia el norte. Se escuchan gruñidos distantes.',
  'Una escalera descendente hacia el este. El aire se vuelve mas frio.',
  'Un arco de piedra al oeste. Runas tenues brillan en el dintel.',
  'Un tunel angosto al sur. Gotas de agua resuenan en la distancia.',
  'Una puerta de madera reforzada. Algo la golpea desde el otro lado.',
  'Un camino cubierto de musgo. Huele a tierra humeda y a secretos.',
  'Una abertura en la pared. Mas alla, una luz parpadea debilmente.',
  'Escaleras que suben en espiral. El eco sugiere una camara amplia arriba.',
  'Un puente de piedra sobre un abismo. No mires abajo. En serio.',
  'Un pasadizo estrecho con marcas de garras en las paredes.',
];

// ---------------------------------------------------------------------------
// Room generation
// ---------------------------------------------------------------------------

/**
 * Generates a single room of the specified type and difficulty.
 *
 * @param {string} type       - One of ROOM_TYPES values.
 * @param {string} difficulty - 'easy' | 'medium' | 'hard'
 * @param {number} roomIndex  - Index of the room within the dungeon.
 * @param {number} totalRooms - Total number of rooms in the dungeon.
 * @returns {object} The fully populated room object.
 */
function generateRoom(type, difficulty, roomIndex = 0, totalRooms = 5) {
  const diff = ['easy', 'medium', 'hard'].includes(difficulty) ? difficulty : 'easy';

  const room = {
    id: `room_${roomIndex}`,
    index: roomIndex,
    type,
    description: pickRandom(ROOM_DESCRIPTIONS[type] || ROOM_DESCRIPTIONS[ROOM_TYPES.CORRIDOR]),
    enemies: [],
    loot: null,
    trap: null,
    merchant: null,
    puzzle: null,
    isRest: false,
    paths: [],
  };

  // Generate paths to next rooms (unless this is the last room)
  if (roomIndex < totalRooms - 1) {
    const pathCount = randomInt(1, Math.min(3, totalRooms - roomIndex - 1));
    const availableDescs = [...PATH_DESCRIPTIONS];

    for (let i = 0; i < pathCount; i++) {
      const descIndex = randomInt(0, availableDescs.length - 1);
      const desc = availableDescs.splice(descIndex, 1)[0];
      room.paths.push({
        targetRoomIndex: roomIndex + 1 + i,
        description: desc || 'Un camino oscuro se abre ante ti.',
      });
    }

    // Ensure at least one valid path
    if (room.paths.length === 0) {
      room.paths.push({
        targetRoomIndex: roomIndex + 1,
        description: pickRandom(PATH_DESCRIPTIONS),
      });
    }
  }

  // Populate room based on type
  switch (type) {
    case ROOM_TYPES.CORRIDOR: {
      // 50% chance of enemies in a corridor
      if (randomInt(1, 100) <= 50) {
        const enemyCount = randomInt(1, 2);
        const pool = ENEMY_TEMPLATES[diff] || ENEMY_TEMPLATES.easy;
        for (let i = 0; i < enemyCount; i++) {
          room.enemies.push(JSON.parse(JSON.stringify(pickRandom(pool))));
        }
      }
      break;
    }

    case ROOM_TYPES.TREASURE: {
      room.loot = generateTreasureLoot(diff);
      // 30% chance of a guardian enemy
      if (randomInt(1, 100) <= 30) {
        const pool = ENEMY_TEMPLATES[diff] || ENEMY_TEMPLATES.easy;
        room.enemies.push(JSON.parse(JSON.stringify(pickRandom(pool))));
      }
      break;
    }

    case ROOM_TYPES.TRAP: {
      const trapPool = TRAPS[diff] || TRAPS.easy;
      room.trap = JSON.parse(JSON.stringify(pickRandom(trapPool)));
      // Small chance of loot after surviving the trap
      if (randomInt(1, 100) <= 25) {
        room.loot = generateLoot(diff, false);
      }
      break;
    }

    case ROOM_TYPES.MERCHANT: {
      const merchantItems = MERCHANT_INVENTORIES[diff] || MERCHANT_INVENTORIES.easy;
      room.merchant = {
        name: pickRandom(MERCHANT_NAMES),
        greeting: '¡Bienvenido, aventurero! Todo tiene precio.',
        items: JSON.parse(JSON.stringify(merchantItems)),
        itemCount: merchantItems.length,
      };
      break;
    }

    case ROOM_TYPES.BOSS: {
      const boss = JSON.parse(JSON.stringify(BOSS_TEMPLATES[diff] || BOSS_TEMPLATES.easy));
      room.enemies.push(boss);
      // Boss always drops loot
      room.loot = generateLoot(diff, true);
      break;
    }

    case ROOM_TYPES.PUZZLE: {
      room.puzzle = generatePuzzle(diff);
      // Reward for solving the puzzle
      room.loot = generateLoot(diff, false);
      break;
    }

    case ROOM_TYPES.REST: {
      room.isRest = true;
      room.healAmount = diff === 'easy' ? 20 : diff === 'medium' ? 15 : 10;
      break;
    }
  }

  return room;
}

// ---------------------------------------------------------------------------
// Puzzle generation
// ---------------------------------------------------------------------------

const PUZZLES = [
  {
    description: 'Tres estatuas te miran. Cada una sostiene un simbolo: Sol, Luna, Estrella. Una inscripcion dice: "El que brilla en la noche mas oscura ilumina el camino."',
    answer: 'estrella',
    hint: 'No es el sol, el ya descanso. No es la luna, ella refleja. Es lo que brilla por si mismo.',
    rewardMultiplier: 1.5,
  },
  {
    description: 'Un mecanismo con cuatro engranajes de colores: Rojo, Azul, Verde, Dorado. "Solo el color de la tierra fertil hara girar la vida."',
    answer: 'verde',
    hint: 'Piensa en campos, bosques, esperanza. O en dinero. Ambos funcionan.',
    rewardMultiplier: 1.5,
  },
  {
    description: 'Una puerta con tres cerraduras. Tres llaves cuelgan de la pared: Hierro, Plata, Hueso. "La puerta se abre ante aquello que fue vida."',
    answer: 'hueso',
    hint: 'Fue parte de un ser vivo. Ahora es solo una llave. La metafora es obvia.',
    rewardMultiplier: 1.5,
  },
  {
    description: 'Un espejo muestra tu reflejo... pero al reves. Debajo, un acertijo: "Di mi nombre al reves y el camino se abrira." Tu nombre brilla en el espejo invertido.',
    answer: 'nombre_invertido',
    hint: 'Lee tu nombre de derecha a izquierda. Simple, pero efectivo.',
    rewardMultiplier: 1.3,
  },
  {
    description: 'Cuatro palancas numeradas del 1 al 4. "La suma de la vida es par, pero la llave es impar." Solo dos palancas deben bajarse.',
    answer: '1,3',
    hint: 'Impares. Uno y tres. La matematica basica salva vidas.',
    rewardMultiplier: 1.4,
  },
];

/**
 * Generates a puzzle for a puzzle room.
 * @param {string} difficulty
 * @returns {object}
 */
function generatePuzzle(difficulty) {
  const puzzle = JSON.parse(JSON.stringify(pickRandom(PUZZLES)));
  puzzle.difficulty = difficulty;
  puzzle.solved = false;

  // Scale penalty for wrong answers based on difficulty
  puzzle.failPenalty = difficulty === 'easy' ? 5 : difficulty === 'medium' ? 10 : 20;

  return puzzle;
}

// ---------------------------------------------------------------------------
// Dungeon generation
// ---------------------------------------------------------------------------

/**
 * Generates a complete procedural dungeon.
 *
 * @param {string} difficulty - 'easy' | 'medium' | 'hard'
 * @returns {object} The full dungeon object with rooms, metadata, and messages.
 */
function generateDungeon(difficulty = 'easy') {
  const diff = ['easy', 'medium', 'hard'].includes(difficulty) ? difficulty : 'easy';
  const config = DIFFICULTY_CONFIG[diff];

  const dungeon = {
    id: `dungeon_${Date.now()}_${randomInt(1000, 9999)}`,
    name: generateDungeonName(diff),
    difficulty: diff,
    roomCount: config.roomCount,
    rooms: [],
    currentRoom: 0,
    completed: false,
    createdAt: new Date().toISOString(),
  };

  // Define room type distribution
  const roomTypes = buildRoomTypeSequence(config);

  // Generate each room
  for (let i = 0; i < config.roomCount; i++) {
    const type = roomTypes[i] || ROOM_TYPES.CORRIDOR;
    const room = generateRoom(type, diff, i, config.roomCount);
    dungeon.rooms.push(room);
  }

  // Generate entrance message
  dungeon.entranceMessage = getDungeonEntranceMessage(dungeon);

  return dungeon;
}

/**
 * Builds the sequence of room types for a dungeon.
 * Ensures a good mix while placing bosses at the end and rest areas strategically.
 *
 * @param {object} config
 * @returns {Array<string>}
 */
function buildRoomTypeSequence(config) {
  const { roomCount, bossCount, trapChance } = config;
  const types = [];

  for (let i = 0; i < roomCount; i++) {
    if (i === 0) {
      // First room is always a corridor (entry room)
      types.push(ROOM_TYPES.CORRIDOR);
    } else if (i === roomCount - 1 && bossCount > 0) {
      // Last room is the boss room (if the dungeon has a boss)
      types.push(ROOM_TYPES.BOSS);
    } else if (i === Math.floor(roomCount / 2)) {
      // Mid-point rest area
      types.push(ROOM_TYPES.REST);
    } else {
      // Random room type
      const roll = randomInt(1, 100);
      if (roll <= trapChance) {
        types.push(ROOM_TYPES.TRAP);
      } else if (roll <= trapChance + 15) {
        types.push(ROOM_TYPES.TREASURE);
      } else if (roll <= trapChance + 25) {
        types.push(ROOM_TYPES.MERCHANT);
      } else if (roll <= trapChance + 35) {
        types.push(ROOM_TYPES.PUZZLE);
      } else {
        types.push(ROOM_TYPES.CORRIDOR);
      }
    }
  }

  // Insert additional boss rooms for hard difficulty
  if (bossCount > 1) {
    const midBossIndex = Math.floor(roomCount * 0.7);
    if (midBossIndex > 0 && midBossIndex < roomCount - 1) {
      types[midBossIndex] = ROOM_TYPES.BOSS;
    }
  }

  return types;
}

/**
 * Generates a random dungeon name based on difficulty.
 * @param {string} difficulty
 * @returns {string}
 */
function generateDungeonName(difficulty) {
  const names = {
    easy: [
      'Cueva del Principiante Optimista',
      'Sotano del Granjero Desaparecido',
      'Madriguera de las Ratas Insolentes',
      'Cripta del Abuelo Olvidado',
    ],
    medium: [
      'Templo de la Serpiente Dormida',
      'Minas del Rey Codicioso',
      'Catacumbas del Eco Eterno',
      'Fortaleza de los Huesos Cantantes',
    ],
    hard: [
      'Abismo del Tormento Infinito',
      'Cidadela del Vacio Primordial',
      'Laberinto de la Desesperacion Absoluta',
      'Trono del Dios Muerto',
    ],
  };

  return pickRandom(names[difficulty] || names.easy);
}

// ---------------------------------------------------------------------------
// Predefined story dungeons
// ---------------------------------------------------------------------------

const PREDEFINED_DUNGEONS = {
  /**
   * Catacumbas del Novato - Easy dungeon for beginners
   */
  catacumbas_del_novato: {
    id: 'catacumbas_del_novato',
    name: 'Catacumbas del Novato',
    difficulty: 'easy',
    description: 'Las catacumbas debajo de la taberna del pueblo. Dicen que un grupo de ratas gigantes se ha instalado ahi. Perfecto para tu primera aventura. Y posiblemente la ultima.',
    levelRequirement: 1,
    rooms: [
      {
        id: 'cdn_01',
        index: 0,
        type: ROOM_TYPES.CORRIDOR,
        description: 'La entrada de las catacumbas huele a cerveza rancia y a roedores. Las escaleras bajan hacia la oscuridad. Alguien grabo "AYUDA" en la pared. Motivador.',
        enemies: [],
        loot: null,
        trap: null,
        merchant: null,
        puzzle: null,
        isRest: false,
        paths: [{ targetRoomIndex: 1, description: 'Escaleras descendentes cubiertas de telaranas.' }],
      },
      {
        id: 'cdn_02',
        index: 1,
        type: ROOM_TYPES.CORRIDOR,
        description: 'Un pasillo angosto con huesos de pollo en el suelo. Las ratas comen mejor que tu.',
        enemies: [
          { name: 'Rata Gigante', type: 'default', hp: 15, attack: 3, defense: 1, xpReward: 8 },
          { name: 'Rata Gigante', type: 'default', hp: 15, attack: 3, defense: 1, xpReward: 8 },
        ],
        loot: null,
        trap: null,
        merchant: null,
        puzzle: null,
        isRest: false,
        paths: [
          { targetRoomIndex: 2, description: 'Un tunel que se abre hacia la izquierda.' },
          { targetRoomIndex: 3, description: 'Un agujero en la pared derecha. Cabe una persona delgada.' },
        ],
      },
      {
        id: 'cdn_03',
        index: 2,
        type: ROOM_TYPES.TRAP,
        description: 'Una sala circular con el suelo sospechosamente brillante. Alguien derramo aceite aqui. A proposito.',
        enemies: [],
        loot: null,
        trap: { name: 'Baldosa Resbaladiza', damage: 5, type: 'physical' },
        merchant: null,
        puzzle: null,
        isRest: false,
        paths: [{ targetRoomIndex: 4, description: 'Una puerta de madera vieja al fondo.' }],
      },
      {
        id: 'cdn_04',
        index: 3,
        type: ROOM_TYPES.TREASURE,
        description: 'Un pequeño almacen olvidado. Barriles de vino (vacio, obviamente) y un cofre cubierto de polvo.',
        enemies: [],
        loot: null, // Generated at runtime
        trap: null,
        merchant: null,
        puzzle: null,
        isRest: false,
        paths: [{ targetRoomIndex: 4, description: 'Un pasadizo que se une al camino principal.' }],
      },
      {
        id: 'cdn_05',
        index: 4,
        type: ROOM_TYPES.BOSS,
        description: 'La camara final. Un nido enorme de ratas rodea a su lider: el Rey Rata, una bestia del tamaño de un perro con una corona hecha de huesos de aventureros.',
        enemies: [
          { name: 'Rey Rata', type: 'default', hp: 50, attack: 8, defense: 4, xpReward: 40, isBoss: true },
        ],
        loot: null, // Generated at runtime
        trap: null,
        merchant: null,
        puzzle: null,
        isRest: false,
        paths: [],
      },
    ],
  },

  /**
   * Laberinto de las Lagrimas de Obsidiana - Medium dungeon with 3 levels
   */
  laberinto_obsidiana: {
    id: 'laberinto_obsidiana',
    name: 'Laberinto de las Lagrimas de Obsidiana',
    difficulty: 'medium',
    description: 'Un laberinto antiguo construido por una civilizacion que adoraba a un dios de la tristeza. Cada pared esta hecha de obsidiana negra que llora un liquido viscoso. Tres niveles de puzzles, trampas y un señor de los no-muertos esperandote al final. Suena divertido, ¿no?',
    levelRequirement: 5,
    rooms: [
      // Level 1 - Entrance
      {
        id: 'lto_01',
        index: 0,
        type: ROOM_TYPES.CORRIDOR,
        description: 'La entrada del laberinto. Paredes de obsidiana negra reflejan tu imagen distorsionada. La version reflejada parece mas inteligente. Probablemente lo es.',
        enemies: [],
        loot: null,
        trap: null,
        merchant: null,
        puzzle: null,
        isRest: false,
        paths: [
          { targetRoomIndex: 1, description: 'Pasillo norte con runas pulsantes en el suelo.' },
          { targetRoomIndex: 2, description: 'Pasillo este con un brillo ambar al final.' },
        ],
      },
      {
        id: 'lto_02',
        index: 1,
        type: ROOM_TYPES.PUZZLE,
        description: 'Una sala hexagonal con seis columnas. Cada columna tiene un simbolo diferente. En el centro, un pedestal con ranuras.',
        enemies: [],
        loot: null,
        trap: null,
        merchant: null,
        puzzle: {
          description: 'Seis simbolos: Fuego, Agua, Tierra, Aire, Luz, Sombra. La inscripcion dice: "Opuestos se atraen, complementarios abren el camino." Debes emparejar los simbolos correctamente.',
          answer: 'fuego-agua,tierra-aire,luz-sombra',
          hint: 'Cada elemento tiene su opuesto natural.',
          rewardMultiplier: 1.5,
          difficulty: 'medium',
          solved: false,
          failPenalty: 10,
        },
        isRest: false,
        paths: [{ targetRoomIndex: 3, description: 'Una escalera descendente se revela tras resolver el puzzle.' }],
      },
      {
        id: 'lto_03',
        index: 2,
        type: ROOM_TYPES.MERCHANT,
        description: 'Una gruta lateral donde un esqueleto animado ha montado una tienda. Si, un esqueleto comerciante. La no-vida tiene sus emprendedores.',
        enemies: [],
        loot: null,
        trap: null,
        merchant: {
          name: 'Huesitos el Emprendedor',
          greeting: '¡Clickety-clack! ¡Ofertas de muerte! Literalmente.',
          items: [
            { name: 'Pocion de Salud Mayor', price: 25, type: 'potion' },
            { name: 'Elixir de Fuerza', price: 30, type: 'potion' },
            { name: 'Pergamino de Bola de Fuego', price: 35, type: 'scroll' },
          ],
          itemCount: 3,
        },
        puzzle: null,
        isRest: false,
        paths: [{ targetRoomIndex: 3, description: 'Volver al camino principal y bajar al segundo nivel.' }],
      },
      // Level 2 - Depths
      {
        id: 'lto_04',
        index: 3,
        type: ROOM_TYPES.CORRIDOR,
        description: 'Segundo nivel. El aire es mas frio. Las paredes de obsidiana lloran mas intensamente. El liquido parece seguirte con la mirada. Si, el liquido tiene mirada. No preguntes.',
        enemies: [
          { name: 'Fantasma Iracundo', type: 'default', hp: 35, attack: 11, defense: 6, xpReward: 24 },
        ],
        loot: null,
        trap: null,
        merchant: null,
        puzzle: null,
        isRest: false,
        paths: [
          { targetRoomIndex: 4, description: 'Un corredor con trampa visible. Al menos esta vez puedes verla.' },
          { targetRoomIndex: 5, description: 'Un camino que baja en espiral.' },
        ],
      },
      {
        id: 'lto_05',
        index: 4,
        type: ROOM_TYPES.TRAP,
        description: 'Una sala alargada con baldosas alternas blancas y negras. Es un tablero de ajedrez. Y tu eres el peon.',
        enemies: [],
        loot: null,
        trap: { name: 'Runas Explosivas', damage: 10, type: 'magic' },
        merchant: null,
        puzzle: null,
        isRest: false,
        paths: [{ targetRoomIndex: 5, description: 'Al otro lado de la trampa, una puerta de obsidiana.' }],
      },
      {
        id: 'lto_06',
        index: 5,
        type: ROOM_TYPES.REST,
        description: 'Un santuario abandonado a un dios olvidado. La fuente en el centro aun funciona. El agua sabe a lagrimas. Porque literalmente son lagrimas de obsidiana purificadas.',
        enemies: [],
        loot: null,
        trap: null,
        merchant: null,
        puzzle: null,
        isRest: true,
        healAmount: 15,
        paths: [{ targetRoomIndex: 6, description: 'Escaleras finales hacia las profundidades.' }],
      },
      // Level 3 - Boss
      {
        id: 'lto_07',
        index: 6,
        type: ROOM_TYPES.TREASURE,
        description: 'Una antecamara del jefe con cofres que pertenecieron a aventureros anteriores. Sus huesos estan aqui tambien. Los cofres, al menos, son utiles.',
        enemies: [
          { name: 'Esqueleto Armado', type: 'skeleton', hp: 35, attack: 8, defense: 7, xpReward: 22 },
        ],
        loot: null,
        trap: null,
        merchant: null,
        puzzle: null,
        isRest: false,
        paths: [{ targetRoomIndex: 7, description: 'La puerta final. Energia oscura pulsa desde el otro lado.' }],
      },
      {
        id: 'lto_08',
        index: 7,
        type: ROOM_TYPES.BOSS,
        description: 'El trono de obsidiana domina la sala. Sobre el, el Señor de los No-Muertos se levanta, sus ojos ardiendo con fuego azul. "Otra polilla que vuela hacia la llama," dice con una voz que resuena en tus huesos.',
        enemies: [
          { name: 'Señor de los No-Muertos', type: 'skeleton', hp: 100, attack: 16, defense: 10, xpReward: 80, isBoss: true },
        ],
        loot: null,
        trap: null,
        merchant: null,
        puzzle: null,
        isRest: false,
        paths: [],
      },
    ],
  },

  /**
   * Abismo del Dragon Negro - Hard dungeon, level 10+ required
   */
  abismo_dragon_negro: {
    id: 'abismo_dragon_negro',
    name: 'Abismo del Dragon Negro',
    difficulty: 'hard',
    description: 'Las profundidades donde duerme el Dragon Negro Ancestral. Solo los mas valientes (o mas estupidos) se atreven a entrar. La diferencia entre valentia y estupidez aqui es puramente academica. Nivel 10+ recomendado. Enfasis en "recomendado".',
    levelRequirement: 10,
    rooms: [
      {
        id: 'adn_01',
        index: 0,
        type: ROOM_TYPES.CORRIDOR,
        description: 'La boca de la cueva exhala calor volcanico. El suelo esta cubierto de ceniza y huesos carbonizados. Un cartel dice "Ultima oportunidad para dar la vuelta." Nadie lo lee.',
        enemies: [
          { name: 'Demonio de Sombras', type: 'default', hp: 90, attack: 20, defense: 10, xpReward: 60 },
        ],
        loot: null,
        trap: null,
        merchant: null,
        puzzle: null,
        isRest: false,
        paths: [
          { targetRoomIndex: 1, description: 'Tunel de lava solidificada hacia el norte.' },
          { targetRoomIndex: 2, description: 'Grietas en la pared este. Brilla algo detras.' },
        ],
      },
      {
        id: 'adn_02',
        index: 1,
        type: ROOM_TYPES.TRAP,
        description: 'Un salon amplio con pilares de roca volcanica. El suelo esta agrietado. Debajo, lava burbujeante espera con paciencia geologica.',
        enemies: [],
        loot: null,
        trap: { name: 'Explosion Arcana', damage: 35, type: 'magic' },
        merchant: null,
        puzzle: null,
        isRest: false,
        paths: [{ targetRoomIndex: 3, description: 'Un puente de piedra sobre el rio de lava.' }],
      },
      {
        id: 'adn_03',
        index: 2,
        type: ROOM_TYPES.TREASURE,
        description: 'Una camara secreta llena de tesoros acumulados durante siglos. El dragon es un coleccionista. Tu eres un ladron. Esta es la dinamica.',
        enemies: [
          { name: 'Wyrm Joven', type: 'dragon', hp: 100, attack: 25, defense: 15, xpReward: 75 },
        ],
        loot: null,
        trap: null,
        merchant: null,
        puzzle: null,
        isRest: false,
        paths: [{ targetRoomIndex: 3, description: 'De vuelta al camino principal, con suerte y con tesoro.' }],
      },
      {
        id: 'adn_04',
        index: 3,
        type: ROOM_TYPES.CORRIDOR,
        description: 'Un pasillo de obsidiana negra y roja. Las paredes estan calientes al tacto. Grabados arcanos cuentan la historia del dragon: destruccion, mas destruccion, y un poco mas de destruccion.',
        enemies: [
          { name: 'Caballero Oscuro', type: 'default', hp: 80, attack: 18, defense: 12, xpReward: 50 },
          { name: 'Liche Menor', type: 'skeleton', hp: 70, attack: 22, defense: 8, xpReward: 55 },
        ],
        loot: null,
        trap: null,
        merchant: null,
        puzzle: null,
        isRest: false,
        paths: [
          { targetRoomIndex: 4, description: 'Un arco masivo de hueso de dragon.' },
          { targetRoomIndex: 5, description: 'Una gruta lateral con luz de fuego.' },
        ],
      },
      {
        id: 'adn_05',
        index: 4,
        type: ROOM_TYPES.PUZZLE,
        description: 'Una camara con cuatro altares, cada uno representando un elemento. En el centro, una esfera de cristal flota en el aire.',
        enemies: [],
        loot: null,
        trap: null,
        merchant: null,
        puzzle: {
          description: 'Cuatro altares: Fuego, Hielo, Rayo, Tierra. La esfera muestra una vision: un dragon rodeado de llamas siendo golpeado por un rayo helado. "El enemigo del fuego no es el agua, sino aquello que lo congela desde el cielo."',
          answer: 'hielo,rayo',
          hint: 'El dragon es fuego. Necesitas algo frio que caiga del cielo. Hielo + Rayo.',
          rewardMultiplier: 2.0,
          difficulty: 'hard',
          solved: false,
          failPenalty: 20,
        },
        isRest: false,
        paths: [{ targetRoomIndex: 6, description: 'La solucion revela un pasadizo secreto hacia abajo.' }],
      },
      {
        id: 'adn_06',
        index: 5,
        type: ROOM_TYPES.MERCHANT,
        description: 'Un mercader demoniaco ha montado tienda junto a un rio de lava. "Los precios estan calientes," dice sin ironia.',
        enemies: [],
        loot: null,
        trap: null,
        merchant: {
          name: 'Zarathis el Infernal',
          greeting: '¿Necesitas suministros? La muerte es mala para los negocios... la tuya, no la de los monstruos.',
          items: [
            { name: 'Pocion de Salud Suprema', price: 60, type: 'potion' },
            { name: 'Frasco de Inmunidad', price: 75, type: 'potion' },
            { name: 'Pergamino de Tormenta Arcana', price: 80, type: 'scroll' },
            { name: 'Hoja de Sombras', price: 100, type: 'weapon' },
          ],
          itemCount: 4,
        },
        puzzle: null,
        isRest: false,
        paths: [{ targetRoomIndex: 6, description: 'Hacia las profundidades finales.' }],
      },
      {
        id: 'adn_07',
        index: 6,
        type: ROOM_TYPES.REST,
        description: 'Un oasis imposible en medio del infierno. Una fuente de agua helada brota de la roca volcanica. Magia antigua la protege. Descansa. Lo que viene despues lo requerira.',
        enemies: [],
        loot: null,
        trap: null,
        merchant: null,
        puzzle: null,
        isRest: true,
        healAmount: 10,
        paths: [{ targetRoomIndex: 7, description: 'El camino final desciende hacia el calor abrasador.' }],
      },
      {
        id: 'adn_08',
        index: 7,
        type: ROOM_TYPES.CORRIDOR,
        description: 'El penultimo corredor. Huesos de heroes pasados flanquean el camino como una guardia de honor macabra. Sus armaduras aun humean.',
        enemies: [
          { name: 'Hidra de Tres Cabezas', type: 'default', hp: 120, attack: 22, defense: 11, xpReward: 80 },
        ],
        loot: null,
        trap: null,
        merchant: null,
        puzzle: null,
        isRest: false,
        paths: [{ targetRoomIndex: 8, description: 'Las puertas del trono del dragon. No hay vuelta atras.' }],
      },
      {
        id: 'adn_09',
        index: 8,
        type: ROOM_TYPES.BOSS,
        description: 'Una caverna del tamaño de una catedral. Montañas de oro y joyas cubren el suelo. Y sobre ellas, enroscado como una pesadilla viviente, el Dragon Negro Ancestral abre un ojo del tamaño de tu cabeza. "Otro insecto," murmura, y el mundo tiembla.',
        enemies: [
          { name: 'Dragon Negro Ancestral', type: 'dragon', hp: 200, attack: 35, defense: 20, xpReward: 200, isBoss: true },
        ],
        loot: null,
        trap: null,
        merchant: null,
        puzzle: null,
        isRest: false,
        paths: [],
      },
      {
        id: 'adn_10',
        index: 9,
        type: ROOM_TYPES.TREASURE,
        description: 'El tesoro del dragon. Si has llegado hasta aqui, te lo has ganado. Miles de monedas, armas legendarias, y la satisfaccion de saber que eres mas terco que un lagarto gigante con mal temperamento.',
        enemies: [],
        loot: null,
        trap: null,
        merchant: null,
        puzzle: null,
        isRest: false,
        paths: [],
      },
    ],
  },
};

// ---------------------------------------------------------------------------
// Dungeon retrieval / management
// ---------------------------------------------------------------------------

/**
 * Returns a deep copy of a predefined dungeon by its ID.
 *
 * @param {string} dungeonId
 * @returns {object|null}
 */
function getPredefinedDungeon(dungeonId) {
  const dungeon = PREDEFINED_DUNGEONS[dungeonId];
  if (!dungeon) return null;
  return JSON.parse(JSON.stringify(dungeon));
}

/**
 * Returns a list of available predefined dungeons (metadata only).
 * @returns {Array<{ id: string, name: string, difficulty: string, description: string, levelRequirement: number }>}
 */
function listPredefinedDungeons() {
  return Object.values(PREDEFINED_DUNGEONS).map((d) => ({
    id: d.id,
    name: d.name,
    difficulty: d.difficulty,
    description: d.description,
    levelRequirement: d.levelRequirement,
  }));
}

// ---------------------------------------------------------------------------
// Socket.IO handler registration
// ---------------------------------------------------------------------------

/**
 * Registers dungeon-related Socket.IO event listeners on the given socket.
 *
 * Events:
 *   - 'dungeon:generate' : { difficulty }
 *   - 'dungeon:enter'    : { dungeonId } (predefined) or { difficulty } (procedural)
 *   - 'dungeon:move'     : { dungeonId, pathIndex }
 *   - 'dungeon:list'     : {} (lists available dungeons)
 *
 * @param {import('socket.io').Server} io
 * @param {import('socket.io').Socket} socket
 */
function registerDungeonHandlers(io, socket) {
  // List available predefined dungeons
  socket.on('dungeon:list', (data, callback) => {
    try {
      const dungeons = listPredefinedDungeons();
      const payload = { success: true, dungeons };
      socket.emit('dungeon:listResult', payload);
      if (callback) callback(payload);
    } catch (err) {
      console.error('[Dungeon] Error in dungeon:list:', err);
      if (callback) callback({ success: false, error: 'Error al listar mazmorras.' });
    }
  });

  // Generate a procedural dungeon
  socket.on('dungeon:generate', (data, callback) => {
    try {
      const dungeon = generateDungeon(data.difficulty || 'easy');
      const payload = { success: true, dungeon };
      socket.emit('dungeon:generated', payload);
      if (callback) callback(payload);
    } catch (err) {
      console.error('[Dungeon] Error in dungeon:generate:', err);
      if (callback) callback({ success: false, error: 'Error al generar la mazmorra.' });
    }
  });

  // Enter a dungeon (predefined or generate new one)
  socket.on('dungeon:enter', (data, callback) => {
    try {
      let dungeon;

      if (data.dungeonId) {
        dungeon = getPredefinedDungeon(data.dungeonId);
        if (!dungeon) {
          const err = `La mazmorra "${data.dungeonId}" no existe. Como tu sentido de la orientacion.`;
          if (callback) return callback({ success: false, error: err });
          return socket.emit('dungeon:error', { error: err });
        }
      } else {
        dungeon = generateDungeon(data.difficulty || 'easy');
      }

      // Generate runtime loot for treasure and boss rooms
      dungeon.rooms.forEach((room) => {
        if (room.type === ROOM_TYPES.TREASURE && !room.loot) {
          room.loot = generateTreasureLoot(dungeon.difficulty);
        }
        if (room.type === ROOM_TYPES.BOSS && !room.loot) {
          room.loot = generateLoot(dungeon.difficulty, true);
        }
      });

      const entranceMessage = getDungeonEntranceMessage(dungeon);
      const firstRoom = dungeon.rooms[0];
      let pathMessage = '';
      if (firstRoom.paths && firstRoom.paths.length > 0) {
        pathMessage = getPathChoiceMessage(firstRoom.paths);
      }

      // Check for random event
      const randomEvent = getRandomEvent();

      const payload = {
        success: true,
        dungeon,
        entranceMessage,
        currentRoom: firstRoom,
        pathMessage,
        randomEvent: randomEvent.triggered ? randomEvent.event : null,
      };

      socket.emit('dungeon:entered', payload);
      if (callback) callback(payload);
    } catch (err) {
      console.error('[Dungeon] Error in dungeon:enter:', err);
      if (callback) callback({ success: false, error: 'Error al entrar a la mazmorra.' });
    }
  });

  // Move to a different room within a dungeon
  socket.on('dungeon:move', (data, callback) => {
    try {
      const { dungeon, pathIndex } = data;

      if (!dungeon || !dungeon.rooms) {
        const err = 'No estas en ninguna mazmorra. Intenta entrar a una primero.';
        if (callback) return callback({ success: false, error: err });
        return socket.emit('dungeon:error', { error: err });
      }

      const currentRoom = dungeon.rooms[dungeon.currentRoom];
      if (!currentRoom || !currentRoom.paths || currentRoom.paths.length === 0) {
        const err = 'No hay caminos disponibles. Estas atrapado. O has completado la mazmorra.';
        if (callback) return callback({ success: false, error: err });
        return socket.emit('dungeon:error', { error: err });
      }

      const selectedPath = currentRoom.paths[pathIndex];
      if (!selectedPath) {
        const err = `Camino invalido. Las opciones son del 1 al ${currentRoom.paths.length}. No te inventes caminos.`;
        if (callback) return callback({ success: false, error: err });
        return socket.emit('dungeon:error', { error: err });
      }

      const nextRoomIndex = selectedPath.targetRoomIndex;
      const nextRoom = dungeon.rooms[nextRoomIndex];

      if (!nextRoom) {
        const err = 'El camino lleva a... la nada. Un error dimensional. Intenta otro camino.';
        if (callback) return callback({ success: false, error: err });
        return socket.emit('dungeon:error', { error: err });
      }

      // Build room narration
      let roomMessage = nextRoom.description;

      // Handle room type specifics
      if (nextRoom.enemies && nextRoom.enemies.length > 0) {
        const enemyMessages = nextRoom.enemies.map((e) => getEnemyEncounterMessage(e));
        roomMessage += '\n\n' + enemyMessages.join('\n');
      }
      if (nextRoom.trap) {
        roomMessage += '\n\n' + getTrapMessage(nextRoom.trap);
      }
      if (nextRoom.merchant) {
        roomMessage += '\n\n' + getMerchantMessage(nextRoom.merchant);
      }
      if (nextRoom.isRest) {
        roomMessage += `\n\nPuedes descansar aqui y recuperar ${nextRoom.healAmount} HP. Usa /rest para descansar.`;
      }

      let pathMessage = '';
      if (nextRoom.paths && nextRoom.paths.length > 0) {
        pathMessage = getPathChoiceMessage(nextRoom.paths);
      }

      // Check for random event
      const randomEvent = getRandomEvent();

      const payload = {
        success: true,
        previousRoom: dungeon.currentRoom,
        currentRoom: nextRoom,
        currentRoomIndex: nextRoomIndex,
        roomMessage,
        pathMessage,
        randomEvent: randomEvent.triggered ? randomEvent.event : null,
        dungeonCompleted: nextRoom.paths.length === 0 && nextRoom.type !== ROOM_TYPES.BOSS,
      };

      socket.emit('dungeon:roomEntered', payload);
      if (callback) callback(payload);
    } catch (err) {
      console.error('[Dungeon] Error in dungeon:move:', err);
      if (callback) callback({ success: false, error: 'Error al moverse en la mazmorra.' });
    }
  });
}

// ---------------------------------------------------------------------------
// Exports
// ---------------------------------------------------------------------------

module.exports = {
  ROOM_TYPES,
  generateRoom,
  generateDungeon,
  getPredefinedDungeon,
  listPredefinedDungeons,
  registerDungeonHandlers,
  // Expose for testing
  PREDEFINED_DUNGEONS,
  DIFFICULTY_CONFIG,
};
