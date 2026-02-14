const {
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
  COMMANDS,
} = require('../src/game/commands');

// ---------------------------------------------------------------------------
// parseCommand
// ---------------------------------------------------------------------------

describe('parseCommand', () => {
  test('parses /stats as a command', () => {
    const result = parseCommand('/stats');
    expect(result.isCommand).toBe(true);
    expect(result.command).toBe('/stats');
    expect(result.args).toBe('');
  });

  test('parses /attack goblin with args', () => {
    const result = parseCommand('/attack goblin cobarde');
    expect(result.isCommand).toBe(true);
    expect(result.command).toBe('/attack');
    expect(result.args).toBe('goblin cobarde');
  });

  test('non-command message returns isCommand false', () => {
    const result = parseCommand('hola mundo');
    expect(result.isCommand).toBe(false);
    expect(result.command).toBe('');
  });

  test('empty string returns isCommand false', () => {
    const result = parseCommand('');
    expect(result.isCommand).toBe(false);
  });

  test('null input returns isCommand false', () => {
    const result = parseCommand(null);
    expect(result.isCommand).toBe(false);
  });

  test('trims whitespace', () => {
    const result = parseCommand('  /help  ');
    expect(result.isCommand).toBe(true);
    expect(result.command).toBe('/help');
  });

  test('command is case-insensitive', () => {
    const result = parseCommand('/STATS');
    expect(result.command).toBe('/stats');
  });
});

// ---------------------------------------------------------------------------
// handleStats
// ---------------------------------------------------------------------------

describe('handleStats', () => {
  test('returns stats for valid character', () => {
    const character = {
      name: 'Thalric',
      hp: 70,
      maxHp: 100,
      attack: 20,
      defense: 5,
      xp: 50,
      coins: 30,
      smartCoins: 10,
      deaths: 1,
      level: 3,
    };
    const result = handleStats(character);
    expect(result.success).toBe(true);
    expect(result.message).toBeTruthy();
    expect(result.stats.name).toBe('Thalric');
    expect(result.stats.hp).toBe(70);
  });

  test('fails without character data', () => {
    const result = handleStats(null);
    expect(result.success).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// handleInventory
// ---------------------------------------------------------------------------

describe('handleInventory', () => {
  test('shows inventory items', () => {
    const character = {
      name: 'Mago',
      inventory: [{ name: 'Pocion de Salud', damage: null, healing: 30, rarity: 'comun' }],
    };
    const result = handleInventory(character);
    expect(result.success).toBe(true);
    expect(result.message).toContain('Pocion de Salud');
  });

  test('shows empty inventory message', () => {
    const character = { name: 'Novato', inventory: [] };
    const result = handleInventory(character);
    expect(result.success).toBe(true);
    expect(result.message).toContain('Vacio');
  });
});

// ---------------------------------------------------------------------------
// handleHelp
// ---------------------------------------------------------------------------

describe('handleHelp', () => {
  test('returns list of commands', () => {
    const result = handleHelp();
    expect(result.success).toBe(true);
    expect(result.commands).toEqual(COMMANDS);
    expect(result.message).toContain('/stats');
    expect(result.message).toContain('/help');
  });
});

// ---------------------------------------------------------------------------
// handleMove
// ---------------------------------------------------------------------------

describe('handleMove', () => {
  test('accepts valid direction', () => {
    const character = { name: 'Explorer', hp: 50, alive: true };
    const result = handleMove(character, 'norte');
    expect(result.success).toBe(true);
    expect(result.direction).toBe('Norte');
  });

  test('rejects invalid direction', () => {
    const character = { name: 'Explorer', hp: 50, alive: true };
    const result = handleMove(character, 'arriba');
    expect(result.success).toBe(false);
  });

  test('fails without direction argument', () => {
    const character = { name: 'Explorer', hp: 50, alive: true };
    const result = handleMove(character, '');
    expect(result.success).toBe(false);
  });

  test('path numbers set needsDungeonMove', () => {
    const character = { name: 'Explorer', hp: 50, alive: true };
    const result = handleMove(character, '1');
    expect(result.success).toBe(true);
    expect(result.pathIndex).toBe(0);
    expect(result.needsDungeonMove).toBe(true);
  });

  test('dead character cannot move', () => {
    const character = { name: 'Dead', hp: 0, alive: false };
    const result = handleMove(character, 'norte');
    expect(result.success).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// routeCommand
// ---------------------------------------------------------------------------

describe('routeCommand', () => {
  test('routes /help to handleHelp', () => {
    const { handled, response } = routeCommand('/help', {});
    expect(handled).toBe(true);
    expect(response.success).toBe(true);
    expect(response.commands).toBeDefined();
  });

  test('non-command message is not handled', () => {
    const { handled, response } = routeCommand('hello world', {});
    expect(handled).toBe(false);
    expect(response).toBeNull();
  });

  test('unknown command returns error response', () => {
    const { handled, response } = routeCommand('/unknown', {});
    expect(handled).toBe(true);
    expect(response.success).toBe(false);
  });

  test('routes /inv as alias for /inventory', () => {
    const character = { name: 'Test', inventory: [] };
    const { handled, response } = routeCommand('/inv', { characterData: character });
    expect(handled).toBe(true);
    expect(response.success).toBe(true);
  });
});
