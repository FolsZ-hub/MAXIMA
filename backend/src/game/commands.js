/**
 * MAXIMA RPG - Chat Command Handler
 *
 * Parses chat messages that start with "/" and routes them to the appropriate
 * game system. Acts as the unified entry point for all player-initiated actions.
 *
 * Supported commands:
 *   /stats               - Display character stats
 *   /inventory (/inv)    - List inventory items
 *   /attack [target]     - Attack a target
 *   /hunt                - Find and fight a random enemy
 *   /move [dir]          - Move in a direction (Norte/Sur/Este/Oeste or 1/2/3)
 *   /use [item]          - Use an item from inventory
 *   /returning           - Revive a dead character (legacy system)
 *   /help                - Show available commands
 */

const { rollD20, calculateAttack, calculateHunt, useItem } = require('./combat');
const { generateLoot, formatLootMessage } = require('./loot');
const { activateReturning, getLegacyBonus, applyLegacyXpBonus } = require('./legacy');
const {
  getStatsMessage,
  getInventoryMessage,
  getDeathMessage,
  getReturningMessage,
  getMoveMessage,
  getHuntMessage,
  getCombatResultMessage,
  getItemUseMessage,
  getRandomEvent,
} = require('./master');

// ---------------------------------------------------------------------------
// Command definitions (for /help)
// ---------------------------------------------------------------------------

const COMMANDS = [
  { command: '/stats', description: 'Muestra las estadisticas de tu personaje (HP, XP, Monedas, Smart Coins).' },
  { command: '/inventory', description: 'Lista los objetos en tu inventario. Alias: /inv' },
  { command: '/attack [objetivo]', description: 'Ataca a un objetivo. Usa el sistema D20.' },
  { command: '/hunt', description: 'Busca y combate a un enemigo aleatorio en la mazmorra.' },
  { command: '/move [direccion]', description: 'Muevete en una direccion: Norte, Sur, Este, Oeste, o un numero de camino (1, 2, 3).' },
  { command: '/use [objeto]', description: 'Usa un objeto de tu inventario (pociones, pergaminos, equipar armas/armadura).' },
  { command: '/returning', description: 'Revive a tu personaje muerto usando Smart Coins. Otorga bonus de legado.' },
  { command: '/help', description: 'Muestra esta lista de comandos. ¿Que esperabas, un tutorial?' },
];

// Direction aliases
const DIRECTION_MAP = {
  norte: 'Norte',
  sur: 'Sur',
  este: 'Este',
  oeste: 'Oeste',
  n: 'Norte',
  s: 'Sur',
  e: 'Este',
  o: 'Oeste',
  w: 'Oeste',
  north: 'Norte',
  south: 'Sur',
  east: 'Este',
  west: 'Oeste',
  '1': '1',
  '2': '2',
  '3': '3',
};

// ---------------------------------------------------------------------------
// Command parser
// ---------------------------------------------------------------------------

/**
 * Parses a raw chat message into a command object.
 *
 * @param {string} rawMessage - The full chat message (e.g., "/attack goblin").
 * @returns {{ isCommand: boolean, command: string, args: string, rawMessage: string }}
 */
function parseCommand(rawMessage) {
  if (!rawMessage || typeof rawMessage !== 'string') {
    return { isCommand: false, command: '', args: '', rawMessage: rawMessage || '' };
  }

  const trimmed = rawMessage.trim();

  if (!trimmed.startsWith('/')) {
    return { isCommand: false, command: '', args: '', rawMessage: trimmed };
  }

  const parts = trimmed.split(/\s+/);
  const command = parts[0].toLowerCase();
  const args = parts.slice(1).join(' ').trim();

  return { isCommand: true, command, args, rawMessage: trimmed };
}

// ---------------------------------------------------------------------------
// Command handlers
// ---------------------------------------------------------------------------

/**
 * Handles /stats command.
 *
 * @param {object} characterData - The character's current data.
 * @returns {{ success: boolean, message: string, stats: object }}
 */
function handleStats(characterData) {
  if (!characterData) {
    return {
      success: false,
      message: 'No tienes un personaje. Crea uno primero. O no. El universo es indiferente.',
    };
  }

  const stats = {
    name: characterData.name || 'Aventurero Sin Nombre',
    hp: characterData.hp || 0,
    maxHp: characterData.maxHp || 100,
    attack: characterData.attack || 1,
    defense: characterData.defense || 0,
    xp: characterData.xp || 0,
    coins: characterData.coins || 0,
    smartCoins: characterData.smartCoins || 0,
    deaths: characterData.deaths || 0,
    level: characterData.level || 1,
  };

  const legacy = getLegacyBonus(characterData);
  const message = getStatsMessage(stats);

  return {
    success: true,
    message: message + (legacy.xpBonusPercent > 0
      ? `\n\nLegado: +${legacy.xpBonusPercent}% XP (${legacy.totalDeaths} muertes). ${legacy.description}`
      : ''),
    stats,
    legacy,
  };
}

/**
 * Handles /inventory command.
 *
 * @param {object} characterData - The character's current data.
 * @returns {{ success: boolean, message: string, inventory: Array }}
 */
function handleInventory(characterData) {
  if (!characterData) {
    return {
      success: false,
      message: 'No tienes personaje, mucho menos inventario.',
      inventory: [],
    };
  }

  const inventory = characterData.inventory || [];

  const header = getInventoryMessage({
    name: characterData.name,
    itemCount: inventory.length,
  });

  if (inventory.length === 0) {
    return {
      success: true,
      message: header + '\n\n(Vacio. Como el abismo. Como tu alma de aventurero.)',
      inventory: [],
    };
  }

  const itemLines = inventory.map((item, index) => {
    const details = [];
    if (item.damage) details.push(`DMG: ${item.damage}`);
    if (item.defense) details.push(`DEF: ${item.defense}`);
    if (item.healing) details.push(`HEAL: ${item.healing}`);
    if (item.effect) details.push(`Efecto: ${item.effect}`);

    const detailStr = details.length > 0 ? ` (${details.join(', ')})` : '';
    return `  [${index + 1}] ${item.name}${detailStr} - ${item.rarity || 'comun'}`;
  });

  return {
    success: true,
    message: header + '\n' + itemLines.join('\n'),
    inventory,
  };
}

/**
 * Handles /attack command.
 *
 * @param {object} characterData - The attacker character.
 * @param {string} targetArg     - Target name or identifier.
 * @param {object} [targetData]  - Pre-resolved target data (for PvP or known enemies).
 * @returns {{ success: boolean, message: string, roll: number, result: object|null }}
 */
function handleAttack(characterData, targetArg, targetData) {
  if (!characterData) {
    return {
      success: false,
      message: 'Necesitas un personaje para atacar. Los fantasmas de jugadores inactivos no cuentan.',
      roll: 0,
      result: null,
    };
  }

  if (characterData.hp <= 0 || characterData.alive === false) {
    return {
      success: false,
      message: 'Estas muerto. Los muertos no atacan. Usa /returning primero.',
      roll: 0,
      result: null,
    };
  }

  if (!targetArg && !targetData) {
    return {
      success: false,
      message: 'Atacar al aire no es una estrategia valida. Especifica un objetivo: /attack [nombre]',
      roll: 0,
      result: null,
    };
  }

  // If no pre-resolved target, this needs to be resolved by the caller
  if (!targetData) {
    return {
      success: false,
      message: null, // Signals that target resolution is needed
      needsTargetResolution: true,
      targetQuery: targetArg,
      roll: 0,
      result: null,
    };
  }

  const roll = rollD20();
  const result = calculateAttack(characterData, targetData, roll);

  // Apply legacy XP bonus if enemy defeated
  let xpGained = null;
  if (result.targetDefeated && targetData.xpReward) {
    xpGained = applyLegacyXpBonus(targetData.xpReward, characterData);
  }

  return {
    success: true,
    message: `🎲 Tirada D20: ${roll}\n${result.message}` +
      (xpGained ? `\n\n+${xpGained.totalXp} XP ganados (base: ${xpGained.baseXp}, legado: +${xpGained.bonusXp})` : ''),
    roll,
    result,
    xpGained,
  };
}

/**
 * Handles /hunt command.
 *
 * @param {object} characterData - The hunting character.
 * @param {string} [difficulty]  - Difficulty level for enemy generation.
 * @returns {{ success: boolean, message: string, huntResult: object|null }}
 */
function handleHunt(characterData, difficulty) {
  if (!characterData) {
    return {
      success: false,
      message: 'Necesitas existir para cazar. Primero crea un personaje.',
      huntResult: null,
    };
  }

  if (characterData.hp <= 0 || characterData.alive === false) {
    return {
      success: false,
      message: 'Estas muerto. Los cazadores muertos solo sirven de carnada. Usa /returning.',
      huntResult: null,
    };
  }

  const roll = rollD20();
  const huntResult = calculateHunt(characterData, roll, difficulty || 'easy');

  // Build narrative
  const parts = [huntResult.huntMessage, '', huntResult.encounterMessage];
  parts.push(`\n🎲 Tirada D20: ${roll}`);
  parts.push(huntResult.combatResult.message);

  if (huntResult.loot) {
    parts.push('\n🎁 Botin obtenido:');
    parts.push('  ' + formatLootMessage(huntResult.loot));
  }

  if (huntResult.enemyAttack) {
    parts.push('\n⚔️ El enemigo contraataca:');
    parts.push(`🎲 Tirada del enemigo: ${huntResult.enemyAttack.roll}`);
    parts.push(huntResult.enemyAttack.message);
  }

  // Apply legacy XP bonus if enemy defeated
  let xpGained = null;
  if (huntResult.combatResult.targetDefeated && huntResult.enemy.xpReward) {
    xpGained = applyLegacyXpBonus(huntResult.enemy.xpReward, characterData);
    parts.push(`\n+${xpGained.totalXp} XP ganados (base: ${xpGained.baseXp}, legado: +${xpGained.bonusXp})`);
  }

  return {
    success: true,
    message: parts.join('\n'),
    huntResult,
    xpGained,
  };
}

/**
 * Handles /move command.
 *
 * @param {object} characterData - The character moving.
 * @param {string} directionArg  - The direction or path number.
 * @param {object} [dungeonState] - Current dungeon state (if in a dungeon).
 * @returns {{ success: boolean, message: string, direction: string|null, pathIndex: number|null }}
 */
function handleMove(characterData, directionArg, dungeonState) {
  if (!characterData) {
    return {
      success: false,
      message: 'No puedes moverte si no existes. Filosofico, pero cierto.',
      direction: null,
      pathIndex: null,
    };
  }

  if (characterData.hp <= 0 || characterData.alive === false) {
    return {
      success: false,
      message: 'Los muertos no caminan. Bueno, los no-muertos si. Pero tu no eres uno. Todavia. Usa /returning.',
      direction: null,
      pathIndex: null,
    };
  }

  if (!directionArg) {
    return {
      success: false,
      message: 'Especifica una direccion: Norte, Sur, Este, Oeste, o un numero de camino (1, 2, 3). No puedes ir a "ninguna parte". Bueno, puedes, pero no es recomendable.',
      direction: null,
      pathIndex: null,
    };
  }

  const normalized = directionArg.toLowerCase().trim();
  const mapped = DIRECTION_MAP[normalized];

  if (!mapped) {
    return {
      success: false,
      message: `"${directionArg}" no es una direccion valida. Opciones: Norte, Sur, Este, Oeste, o numeros 1-3. ¿Intentas ir a una dimension desconocida?`,
      direction: null,
      pathIndex: null,
    };
  }

  // If it is a path number, resolve to a pathIndex (0-based)
  let pathIndex = null;
  if (['1', '2', '3'].includes(mapped)) {
    pathIndex = parseInt(mapped, 10) - 1;

    // Validate against dungeon paths if dungeon state is provided
    if (dungeonState) {
      const currentRoom = dungeonState.rooms && dungeonState.rooms[dungeonState.currentRoom];
      if (currentRoom && currentRoom.paths) {
        if (pathIndex >= currentRoom.paths.length) {
          return {
            success: false,
            message: `Solo hay ${currentRoom.paths.length} camino(s) disponible(s). Elegiste el ${mapped}. Las matematicas no son lo tuyo, ¿verdad?`,
            direction: null,
            pathIndex: null,
          };
        }
      }
    }
  }

  // Check for random event on movement
  const randomEvent = getRandomEvent();

  const moveMessage = getMoveMessage(mapped);
  let fullMessage = moveMessage;

  if (randomEvent.triggered) {
    fullMessage += '\n\n' + randomEvent.event.message;
  }

  return {
    success: true,
    message: fullMessage,
    direction: mapped,
    pathIndex,
    randomEvent: randomEvent.triggered ? randomEvent.event : null,
    needsDungeonMove: pathIndex !== null,
  };
}

/**
 * Handles /use command.
 *
 * @param {object} characterData - The character using an item.
 * @param {string} itemArg       - Name of the item to use.
 * @returns {{ success: boolean, message: string, effects: object }}
 */
function handleUse(characterData, itemArg) {
  if (!characterData) {
    return {
      success: false,
      message: 'No tienes personaje. Usar objetos imaginarios no funciona fuera de tu cabeza.',
      effects: {},
    };
  }

  if (!itemArg) {
    return {
      success: false,
      message: 'Especifica que quieres usar: /use [nombre del objeto]. Tu inventario no lee mentes. Aun.',
      effects: {},
    };
  }

  const result = useItem(characterData, itemArg, characterData.inventory || []);

  return {
    success: result.success,
    message: result.message,
    effects: result.effects,
    consumedItem: result.consumedItem,
    consumedIndex: result.consumedIndex,
  };
}

/**
 * Handles /returning command.
 *
 * @param {object} playerData    - The player account data.
 * @param {object} characterData - The dead character data.
 * @returns {{ success: boolean, message: string, result: object|null }}
 */
function handleReturning(playerData, characterData) {
  if (!playerData || !characterData) {
    return {
      success: false,
      message: 'Datos de jugador o personaje faltantes. La burocracia de la resurreccion es estricta.',
      result: null,
    };
  }

  const result = activateReturning(playerData, characterData);

  return {
    success: result.success,
    message: result.message,
    result: result.success ? result : null,
  };
}

/**
 * Handles /help command.
 *
 * @returns {{ success: boolean, message: string, commands: Array }}
 */
function handleHelp() {
  const lines = [
    '=== COMANDOS DISPONIBLES ===',
    'Bienvenido al manual de supervivencia. Leelo bien. No habra segunda oportunidad.',
    '(Bueno, si la hay. Se llama /returning. Cuesta Smart Coins.)',
    '',
  ];

  for (const cmd of COMMANDS) {
    lines.push(`  ${cmd.command}`);
    lines.push(`    ${cmd.description}`);
    lines.push('');
  }

  lines.push('Consejo del Maestro: Si no sabes que hacer, /hunt siempre es una opcion.');
  lines.push('No necesariamente una buena opcion. Pero una opcion.');

  return {
    success: true,
    message: lines.join('\n'),
    commands: COMMANDS,
  };
}

// ---------------------------------------------------------------------------
// Main command router
// ---------------------------------------------------------------------------

/**
 * Routes a parsed command to the appropriate handler.
 *
 * @param {string} rawMessage     - The raw chat message.
 * @param {object} context        - Contextual data for command execution.
 * @param {object} context.playerData     - Player account info.
 * @param {object} context.characterData  - Current character data.
 * @param {object} [context.targetData]   - Pre-resolved target (for /attack).
 * @param {object} [context.dungeonState] - Current dungeon state.
 * @param {string} [context.difficulty]   - Current difficulty context.
 * @returns {{ handled: boolean, response: object }}
 */
function routeCommand(rawMessage, context = {}) {
  const parsed = parseCommand(rawMessage);

  if (!parsed.isCommand) {
    return { handled: false, response: null };
  }

  const { command, args } = parsed;
  const { playerData, characterData, targetData, dungeonState, difficulty } = context;

  let response;

  switch (command) {
    case '/stats':
      response = handleStats(characterData);
      break;

    case '/inventory':
    case '/inv':
      response = handleInventory(characterData);
      break;

    case '/attack':
      response = handleAttack(characterData, args, targetData);
      break;

    case '/hunt':
      response = handleHunt(characterData, difficulty);
      break;

    case '/move':
      response = handleMove(characterData, args, dungeonState);
      break;

    case '/use':
      response = handleUse(characterData, args);
      break;

    case '/returning':
      response = handleReturning(playerData, characterData);
      break;

    case '/help':
      response = handleHelp();
      break;

    default:
      response = {
        success: false,
        message: `Comando desconocido: "${command}". Usa /help para ver los comandos disponibles. No es dificil. Bueno, para ti quizas si.`,
      };
      break;
  }

  return { handled: true, response };
}

// ---------------------------------------------------------------------------
// Socket.IO handler registration
// ---------------------------------------------------------------------------

/**
 * Registers the command handler as a Socket.IO listener. Incoming chat messages
 * are checked for commands and routed accordingly.
 *
 * Events listened:
 *   - 'chat:message' : { message, playerData, characterData, targetData?, dungeonState?, difficulty? }
 *
 * Events emitted:
 *   - 'chat:commandResult' : { handled, response }
 *   - 'chat:message'       : Rebroadcast for non-command messages
 *
 * @param {import('socket.io').Server} io
 * @param {import('socket.io').Socket} socket
 */
function registerCommandHandlers(io, socket) {
  socket.on('chat:message', (data, callback) => {
    try {
      const { message, playerData, characterData, targetData, dungeonState, difficulty, roomId } = data;

      if (!message || typeof message !== 'string') {
        if (callback) return callback({ success: false, error: 'Mensaje vacio o invalido.' });
        return;
      }

      const { handled, response } = routeCommand(message, {
        playerData,
        characterData,
        targetData,
        dungeonState,
        difficulty,
      });

      if (handled) {
        // Send command result back to the sender
        socket.emit('chat:commandResult', {
          command: parseCommand(message).command,
          response,
        });

        // If the command triggers a dungeon move, emit dungeon event
        if (response && response.needsDungeonMove && response.pathIndex !== null) {
          socket.emit('dungeon:moveRequested', {
            pathIndex: response.pathIndex,
            direction: response.direction,
          });
        }

        if (callback) callback({ success: true, handled: true, response });
      } else {
        // Not a command - broadcast as regular chat message
        const chatPayload = {
          sender: playerData ? playerData.username : 'Anonimo',
          senderId: playerData ? playerData.uid : null,
          message,
          timestamp: new Date().toISOString(),
        };

        if (roomId) {
          io.to(roomId).emit('chat:message', chatPayload);
        } else {
          io.emit('chat:message', chatPayload);
        }

        if (callback) callback({ success: true, handled: false });
      }
    } catch (err) {
      console.error('[Commands] Error processing chat message:', err);
      const errorMsg = 'Error al procesar tu mensaje. El Maestro esta ocupado contemplando tu fracaso.';
      if (callback) return callback({ success: false, error: errorMsg });
      socket.emit('chat:error', { error: errorMsg });
    }
  });
}

// ---------------------------------------------------------------------------
// Exports
// ---------------------------------------------------------------------------

module.exports = {
  parseCommand,
  routeCommand,
  handleStats,
  handleInventory,
  handleAttack,
  handleHunt,
  handleMove,
  handleUse,
  handleReturning,
  handleHelp,
  registerCommandHandlers,
  COMMANDS,
};
