/**
 * MAXIMA RPG - Master Narrator System
 *
 * The Master is the sardonic, cynical narrator of every adventure. All narrative
 * text is written in Spanish with dark humour and vivid, descriptive prose.
 *
 * Each message function provides at least 3 variants so the experience never
 * feels repetitive (well, as non-repetitive as the crushing cycle of dungeon
 * crawling can be).
 */

const { randomInt, pickRandom } = require('./loot');

// ---------------------------------------------------------------------------
// Enemy encounter messages
// ---------------------------------------------------------------------------

const ENEMY_ENCOUNTER_MESSAGES = {
  default: [
    (e) => `De entre las sombras surge un ${e.name} (HP: ${e.hp}, ATK: ${e.attack}, DEF: ${e.defense}). Te mira con una mezcla de hambre y desprecio. La sensacion es mutua.`,
    (e) => `Un ${e.name} aparece ante ti (HP: ${e.hp}, ATK: ${e.attack}, DEF: ${e.defense}). Parece tan decepcionado de verte como tu de verlo a el.`,
    (e) => `Oh, maravilloso. Un ${e.name} (HP: ${e.hp}, ATK: ${e.attack}, DEF: ${e.defense}) bloquea tu camino. Porque tu dia no podia empeorar, pero el universo ama los desafios.`,
    (e) => `El suelo tiembla. Las antorchas parpadean. Un ${e.name} (HP: ${e.hp}, ATK: ${e.attack}, DEF: ${e.defense}) emerge de la penumbra, listo para arruinar tus planes de supervivencia.`,
    (e) => `Escuchas un gruñido. Huele a azufre y a decisiones cuestionables. Un ${e.name} (HP: ${e.hp}, ATK: ${e.attack}, DEF: ${e.defense}) te ha encontrado. Felicidades.`,
  ],
  skeleton: [
    (e) => `Un ${e.name} se levanta del suelo con un crujido oseo (HP: ${e.hp}). Literalmente no tiene organos, pero de alguna forma te odia.`,
    (e) => `Los huesos se ensamblan frente a ti formando un ${e.name} (HP: ${e.hp}). Sonrie. Bueno, siempre sonrie. No tiene labios.`,
    (e) => `Un ${e.name} te saluda agitando un femur (HP: ${e.hp}). No esta claro si es el suyo o de un aventurero anterior.`,
  ],
  goblin: [
    (e) => `Un ${e.name} salta de detras de una roca (HP: ${e.hp}). Huele peor de lo que se ve, y se ve terrible.`,
    (e) => `"¡Oro! ¡Dame oro!" chilla un ${e.name} (HP: ${e.hp}). Su plan de negocio es cuestionable pero su entusiasmo es admirable.`,
    (e) => `Un ${e.name} te apunta con un cuchillo oxidado (HP: ${e.hp}). Parece que lo encontro en la basura. El cuchillo tambien.`,
  ],
  dragon: [
    (e) => `El aire se calienta. Las piedras se derriten. Un ${e.name} despliega sus alas (HP: ${e.hp}, ATK: ${e.attack}). Fue un placer conocerte. Brevemente.`,
    (e) => `Un ${e.name} te observa desde su trono de huesos (HP: ${e.hp}, ATK: ${e.attack}). Has confundido valentia con estupidez, aventurero.`,
    (e) => `${e.name} bosteza, revelando filas de dientes del tamaño de tu espada (HP: ${e.hp}, ATK: ${e.attack}). Parece aburrido. Tu eres su entretenimiento.`,
  ],
};

/**
 * Returns a narrated enemy encounter message.
 * @param {object} enemy - { name, hp, attack, defense, type }
 * @returns {string}
 */
function getEnemyEncounterMessage(enemy) {
  const type = enemy.type ? enemy.type.toLowerCase() : 'default';
  const pool = ENEMY_ENCOUNTER_MESSAGES[type] || ENEMY_ENCOUNTER_MESSAGES.default;
  const template = pickRandom(pool);
  return template(enemy);
}

// ---------------------------------------------------------------------------
// Trap messages
// ---------------------------------------------------------------------------

const TRAP_MESSAGES = [
  (t) => `¡CLIC! El suelo cede bajo tus pies. Una trampa de ${t.name} se activa. ${t.damage} puntos de dano. El arquitecto de esta mazmorra era un sociata con talento.`,
  (t) => `Sientes un pinchazo. Luego ardor. La trampa de ${t.name} te recuerda que mirar donde pisas no es solo un consejo, es supervivencia. -${t.damage} HP.`,
  (t) => `Una ${t.name} se activa con un mecanismo que claramente alguien diseño con mucho amor y odio hacia los aventureros. Recibes ${t.damage} de dano.`,
  (t) => `"¿Que es ese ruido?" te preguntas. Es el sonido de ${t.name} quitandote ${t.damage} puntos de vida. La proxima vez, no toques cosas aleatorias.`,
  (t) => `La trampa de ${t.name} funciona perfectamente. ${t.damage} de dano. Quien la hizo estaria orgulloso. Tu, no tanto.`,
];

/**
 * Returns a narrated trap activation message.
 * @param {object} trap - { name, damage, type }
 * @returns {string}
 */
function getTrapMessage(trap) {
  const template = pickRandom(TRAP_MESSAGES);
  return template(trap);
}

// ---------------------------------------------------------------------------
// Merchant messages
// ---------------------------------------------------------------------------

const MERCHANT_MESSAGES = [
  (m) => `Un mercader aparece de la nada. "${m.greeting || '¡Bienvenido, bienvenido!'}" dice ${m.name}, frotandose las manos con una codicia que casi admiras. Tiene ${m.itemCount || 'varios'} articulos en venta.`,
  (m) => `"¡Psst! ¡Aventurero!" susurra ${m.name} desde las sombras. "Tengo mercancia... especial." Es un comerciante, no un criminal. Aunque la diferencia aqui es academica.`,
  (m) => `${m.name} ha montado un puesto de venta en medio de una mazmorra llena de monstruos. Su valentia comercial es inversamente proporcional a su sentido comun. Tiene articulos que podrian salvarte la vida... a un precio.`,
  (m) => `"¡Ah, un cliente!" exclama ${m.name} con la alegria de alguien que no ha visto un ser vivo en semanas. "Todo tiene precio, amigo. Especialmente tu desesperacion."`,
];

/**
 * Returns a narrated merchant encounter message.
 * @param {object} merchant - { name, greeting, itemCount }
 * @returns {string}
 */
function getMerchantMessage(merchant) {
  const template = pickRandom(MERCHANT_MESSAGES);
  return template(merchant);
}

// ---------------------------------------------------------------------------
// Death messages
// ---------------------------------------------------------------------------

const DEATH_MESSAGES = [
  (c) => `${c.name || 'Aventurero'} ha caido. El silencio llena la mazmorra mientras otro heroe se convierte en parte de la decoracion. Descansa en... bueno, en pedazos.`,
  (c) => `Y asi termina la leyenda de ${c.name || 'un aventurero mas'}. No con una explosion, sino con un quejido humedo y patetico. Los bardos no cantaran sobre esto.`,
  (c) => `${c.name || 'El aventurero'} ha muerto. De nuevo. A este ritmo, la Muerte le va a dar tarjeta de cliente frecuente.`,
  (c) => `Game Over para ${c.name || 'el heroe'}. Bueno, "heroe" es generoso. Digamos "persona que entro a una mazmorra y descubrio las consecuencias de sus acciones."`,
  (c) => `${c.name || 'Aventurero'} cae al suelo con toda la gracia de un saco de papas lanzado desde un segundo piso. HP: 0. Dignidad: inexistente.`,
];

/**
 * Returns a cynical death narration.
 * @param {object} character - { name }
 * @returns {string}
 */
function getDeathMessage(character) {
  const template = pickRandom(DEATH_MESSAGES);
  return template(character);
}

// ---------------------------------------------------------------------------
// Returning (revival) messages
// ---------------------------------------------------------------------------

const RETURNING_MESSAGES = [
  (c) => `${c.name || 'Aventurero'} regresa de entre los muertos. La Muerte le ha devuelto, probablemente porque era un inquilino insoportable. Bienvenido de vuelta, con un +${c.legacyBonus || 10}% de bonus de XP por tu... experiencia previa con el fracaso.`,
  (c) => `Una luz brillante. Un coro celestial barato. ${c.name || 'El aventurero'} ha vuelto. El mas alla lo ha rechazado. No es la primera vez que le rechazan. +${c.legacyBonus || 10}% XP de legado.`,
  (c) => `¡RETURNING activado! ${c.name || 'Aventurero'} se sacude el polvo de la tumba y se levanta. "¿Me extranaron?" Nadie responde. +${c.legacyBonus || 10}% bonus de experiencia acumulado.`,
  (c) => `El ciclo se repite. ${c.name || 'El aventurero'} abre los ojos, escupe tierra, y se pregunta por que sigue haciendo esto. Ah, si. El bonus de +${c.legacyBonus || 10}% XP. La adiccion al progreso incremental.`,
];

/**
 * Returns a revival narration.
 * @param {object} character - { name, legacyBonus }
 * @returns {string}
 */
function getReturningMessage(character) {
  const template = pickRandom(RETURNING_MESSAGES);
  return template(character);
}

// ---------------------------------------------------------------------------
// Dungeon entrance messages
// ---------------------------------------------------------------------------

const DUNGEON_ENTRANCE_MESSAGES = [
  (d) => `Te adentras en "${d.name}". El aire huele a humedad, peligro y malas decisiones de vida. Dificultad: ${d.difficulty}. Salas: ${d.roomCount}. Probabilidad de que sobrevivas: discutible.`,
  (d) => `Las puertas de "${d.name}" se abren con un chirrido dramatico. Casi como si la mazmorra supiera que vienes. Dificultad: ${d.difficulty}. Buena suerte. La vas a necesitar.`,
  (d) => `Bienvenido a "${d.name}". Poblacion: monstruos, trampas, y tu ego a punto de ser destruido. Dificultad: ${d.difficulty}. ${d.roomCount} salas te separan de la gloria... o del olvido.`,
  (d) => `"${d.name}" te da la bienvenida con un escalofrio que recorre tu columna. ${d.roomCount} salas. Dificultad ${d.difficulty}. Que los dados esten a tu favor, porque la suerte claramente no lo esta.`,
];

/**
 * Returns a dramatic dungeon entrance narration.
 * @param {object} dungeon - { name, difficulty, roomCount }
 * @returns {string}
 */
function getDungeonEntranceMessage(dungeon) {
  const template = pickRandom(DUNGEON_ENTRANCE_MESSAGES);
  return template(dungeon);
}

// ---------------------------------------------------------------------------
// Path choice messages
// ---------------------------------------------------------------------------

const PATH_CHOICE_MESSAGES = [
  (paths) => {
    const list = paths.map((p, i) => `  [${i + 1}] ${p.description}`).join('\n');
    return `El camino se bifurca. Porque nada puede ser simple.\n${list}\nElige sabiamente. O no. No es como si hubieras tomado buenas decisiones hasta ahora.`;
  },
  (paths) => {
    const list = paths.map((p, i) => `  [${i + 1}] ${p.description}`).join('\n');
    return `Ante ti se abren ${paths.length} caminos:\n${list}\nCada uno promete peligro. La diferencia es el tipo de peligro. Elige.`;
  },
  (paths) => {
    const list = paths.map((p, i) => `  [${i + 1}] ${p.description}`).join('\n');
    return `Momento de decision. ${paths.length} opciones se presentan:\n${list}\nRecuerda: no existe la opcion correcta. Solo la menos incorrecta.`;
  },
];

/**
 * Returns a path choice narration.
 * @param {Array<{ description: string }>} paths
 * @returns {string}
 */
function getPathChoiceMessage(paths) {
  const template = pickRandom(PATH_CHOICE_MESSAGES);
  return template(paths);
}

// ---------------------------------------------------------------------------
// Combat result messages
// ---------------------------------------------------------------------------

const COMBAT_RESULT_MESSAGES = {
  hit: [
    (r) => `¡Impacto! Tu ataque conecta con fuerza, causando ${r.damage} de dano a ${r.targetName}. No esta mal. Para ti.`,
    (r) => `Golpeas a ${r.targetName} por ${r.damage} de dano. El monstruo parece ofendido. Tu, satisfecho. Momentaneamente.`,
    (r) => `Tu arma encuentra su objetivo. ${r.damage} de dano a ${r.targetName}. Un golpe solido. Disfruta la sensacion, es rara en tu caso.`,
  ],
  miss: [
    (r) => `Fallas miserablemente. Tu ataque corta el aire con la precision de un ciego lanzando dardos. ${r.targetName} parece decepcionado por ti.`,
    (r) => `El ataque no conecta. Ni cerca. ${r.targetName} probablemente se rio, si es que los monstruos se rien. (Si lo hacen. De ti.)`,
    (r) => `Abanicar el aire no cuenta como atacar, aventurero. Tu golpe falla contra ${r.targetName}. Intenta apuntar la proxima vez.`,
  ],
  critical: [
    (r) => `¡¡CRITICO!! ¡Un golpe devastador! ${r.damage} de dano a ${r.targetName}! Hasta el Maestro esta impresionado. Y eso no pasa seguido.`,
    (r) => `¡GOLPE CRITICO! ¡${r.damage} de dano! ${r.targetName} nunca vio venir eso. Honestamente, nadie lo vio venir. Menos de ti.`,
    (r) => `¡NAT 20! ¡La perfeccion existe y por una vez la has alcanzado! ${r.damage} de dano critico a ${r.targetName}. Saborea este momento.`,
  ],
  fumble: [
    (r) => `¡PIFIA CRITICA! Tiras un 1. Tu arma se vuelve contra ti. Te causas ${r.selfDamage} de dano a ti mismo. El ${r.targetName} no puede creer tu incompetencia.`,
    (r) => `¡FUMBLE! Un 1 natural. Te tropiezas con tu propia arma y recibes ${r.selfDamage} de dano. ${r.targetName} considera dejarte vivir por lastima.`,
    (r) => `¡DESASTRE! Nat 1. En un movimiento que desafia la logica, te apunalas solo por ${r.selfDamage} de dano. ${r.targetName} aplaude sarcasticamente.`,
  ],
  enemyDefeated: [
    (r) => `¡${r.targetName} ha sido derrotado! Cae al suelo con un ultimo suspiro dramatico. Contra todo pronostico, has ganado.`,
    (r) => `${r.targetName} cae. Victoria. Temporal, como todas, pero victoria al fin. Recoge tu botin antes de que venga algo peor.`,
    (r) => `¡Victoria! ${r.targetName} yace derrotado. No te emociones mucho, la mazmorra tiene mas donde vino ese.`,
  ],
  playerDefeated: [
    (r) => `Has sido derrotado por ${r.targetName}. Tu cuerpo cae al suelo con la elegancia de un costal de cemento.`,
    (r) => `${r.targetName} acaba contigo. Game over. Pero siempre puedes volver... si tienes Smart Coins y falta de dignidad.`,
    (r) => `Caes ante ${r.targetName}. El monstruo ni siquiera sudo. Tu legado es una mancha de sangre en el piso de la mazmorra.`,
  ],
};

/**
 * Returns a narrated combat result message.
 * @param {object} result - { type, damage, selfDamage, targetName }
 *   type: 'hit' | 'miss' | 'critical' | 'fumble' | 'enemyDefeated' | 'playerDefeated'
 * @returns {string}
 */
function getCombatResultMessage(result) {
  const pool = COMBAT_RESULT_MESSAGES[result.type] || COMBAT_RESULT_MESSAGES.hit;
  const template = pickRandom(pool);
  return template(result);
}

// ---------------------------------------------------------------------------
// Random events (10% chance)
// ---------------------------------------------------------------------------

const RANDOM_EVENTS = [
  {
    type: 'merchant',
    message: 'Un mercader errante aparece de las sombras, cargando un saco lleno de articulos de dudosa procedencia. "¿Interesado en comprar algo, aventurero?"',
    data: {
      name: 'Mercader Errante',
      greeting: '¡Las mejores ofertas de la mazmorra!',
      items: ['Pocion de Salud', 'Pergamino de Chispa', 'Daga Oxidada'],
    },
  },
  {
    type: 'treasure',
    message: 'Encuentras un cofre olvidado detras de unas rocas. Brilla con una luz sospechosamente invitadora. ¿Sera tesoro o trampa? (Spoiler: aqui todo es ambas cosas.)',
    data: { lootBonus: true },
  },
  {
    type: 'trap',
    message: 'El suelo cruje bajo tus pies. Una trampa de pinchos se activa. Porque caminar no puede ser simplemente caminar en una mazmorra.',
    data: { damage: randomInt(3, 10), trapName: 'Pinchos Ocultos' },
  },
  {
    type: 'treasure',
    message: 'Una bolsa de monedas yace en el suelo. Probablemente de alguien que murio aqui. Sus perdidas, tus ganancias. Asi funciona la economia de mazmorras.',
    data: { bonusCoins: randomInt(5, 20) },
  },
  {
    type: 'healing',
    message: 'Una fuente de agua cristalina brota de la pared. Bebes con cautela. Sorprendentemente, no esta envenenada. Recuperas algo de vida.',
    data: { healing: randomInt(10, 25) },
  },
  {
    type: 'trap',
    message: 'Un dardo envenenado sale de la pared y te roza el brazo. El dolor es agudo pero tu orgullo duele mas.',
    data: { damage: randomInt(5, 12), trapName: 'Dardo Envenenado' },
  },
  {
    type: 'merchant',
    message: 'Un goblin con un sombrero de copa aparece con una manta llena de objetos. "¡Todo barato! ¡Solo un poco robado!" Su honestidad es refrescante.',
    data: {
      name: 'Grak el Comerciante',
      greeting: '¡Bienvenido al emporio de Grak!',
      items: ['Pocion de Salud Menor', 'Garrote de Madera'],
    },
  },
  {
    type: 'buff',
    message: 'Un espiritu ancestral aparece brevemente y te bendice. Sientes una oleada de fuerza temporal. "Usala bien," susurra. No lo haras.',
    data: { buffStat: 'attack', buffAmount: 3, buffDuration: 3 },
  },
  {
    type: 'treasure',
    message: 'Detras de una pared falsa descubres un pequeño alijo. Contiene objetos que alguien escondio y nunca volvio a buscar. Eso no es buen presagio, pero el botin es botin.',
    data: { lootBonus: true },
  },
  {
    type: 'nothing',
    message: 'No pasa nada. Absolutamente nada. Disfrutas un breve momento de paz en la mazmorra. Es inquietante.',
    data: {},
  },
];

/**
 * Rolls for a random event (10% chance of something happening).
 * @returns {{ triggered: boolean, event: object|null }}
 */
function getRandomEvent() {
  const roll = randomInt(1, 100);

  if (roll <= 10) {
    const event = pickRandom(RANDOM_EVENTS);
    return {
      triggered: true,
      event: JSON.parse(JSON.stringify(event)),
    };
  }

  return { triggered: false, event: null };
}

// ---------------------------------------------------------------------------
// Item usage messages
// ---------------------------------------------------------------------------

const ITEM_USE_MESSAGES = {
  potion: [
    (item, char) => `${char.name || 'Aventurero'} bebe la ${item.name}. Sabe horrible, pero funciona. Recuperas ${item.healing} HP. A veces la medicina sabe a desesperacion.`,
    (item, char) => `Destapas la ${item.name} y la bebes de un trago. ${item.healing} HP restaurados. Tu cuerpo agradece, tu paladar no.`,
    (item, char) => `${char.name || 'El aventurero'} consume ${item.name}. +${item.healing} HP. La etiqueta dice "agitar antes de usar". No la agitaste. Funciona igual.`,
  ],
  scroll: [
    (item, char) => `${char.name || 'Aventurero'} desenrolla el ${item.name}. Las runas brillan. El pergamino se desintegra. El efecto de "${item.effect}" se activa. Magia de un solo uso: la obsolescencia programada del mundo fantastico.`,
    (item, char) => `Lees el ${item.name} en voz alta. Las palabras magicas resuenan en la mazmorra. Efecto: ${item.effect}. El pergamino se convierte en ceniza. No hay reembolsos.`,
    (item, char) => `${char.name || 'El aventurero'} invoca el poder del ${item.name}. ${item.effect} activado. El pergamino se consume en llamas azules. Espectacular, pero no reutilizable.`,
  ],
  weapon: [
    (item, char) => `${char.name || 'Aventurero'} equipa ${item.name} (+${item.damage} ATK). Te sientes mas peligroso. Los monstruos, bueno, ya veremos.`,
    (item, char) => `Empunas ${item.name}. Dano base: ${item.damage}. "${item.description}". Nada dice "estoy listo para morir" como un arma nueva.`,
    (item, char) => `${item.name} ahora es tu arma equipada. +${item.damage} de dano. ${char.name || 'El aventurero'} hace un par de movimientos de practica. Mediocres, pero entusiastas.`,
  ],
  armor: [
    (item, char) => `${char.name || 'Aventurero'} se pone ${item.name} (+${item.defense} DEF). Te ves ridiculo, pero al menos estaras un poco mas protegido.`,
    (item, char) => `Equipas ${item.name}. +${item.defense} defensa. "${item.description}". La moda y la funcionalidad rara vez coinciden en las mazmorras.`,
    (item, char) => `${item.name} equipada. Defensa +${item.defense}. ${char.name || 'El aventurero'} se siente marginalmente menos vulnerable al dolor.`,
  ],
};

/**
 * Returns a narrated item usage message.
 * @param {object} item
 * @param {object} character
 * @returns {string}
 */
function getItemUseMessage(item, character) {
  const pool = ITEM_USE_MESSAGES[item.type] || ITEM_USE_MESSAGES.potion;
  const template = pickRandom(pool);
  return template(item, character);
}

// ---------------------------------------------------------------------------
// Hunt messages (finding an enemy in the wild)
// ---------------------------------------------------------------------------

const HUNT_MESSAGES = [
  (char) => `${char.name || 'Aventurero'} se adentra en la oscuridad buscando problemas. Como si los problemas no te encontraran solos.`,
  (char) => `"Vamos a cazar," dice ${char.name || 'el aventurero'} con mas confianza de la que merece. La mazmorra escucha. La mazmorra se rie.`,
  (char) => `${char.name || 'El aventurero'} busca algo que matar. La ironia de ser cazador y presa simultaneamente no se le escapa. Bueno, a lo mejor si.`,
];

/**
 * Returns a hunting narration.
 * @param {object} character
 * @returns {string}
 */
function getHuntMessage(character) {
  const template = pickRandom(HUNT_MESSAGES);
  return template(character);
}

// ---------------------------------------------------------------------------
// Inventory display messages
// ---------------------------------------------------------------------------

const INVENTORY_MESSAGES = [
  (c) => `Inventario de ${c.name || 'Aventurero'}: ${c.itemCount || 0} objetos. Algunos utiles, otros... bueno, llevalos si te hacen feliz.`,
  (c) => `${c.name || 'El aventurero'} revisa su mochila. ${c.itemCount || 0} objetos. Es como una venta de garaje ambulante.`,
  (c) => `Contenido de tu mochila (${c.itemCount || 0} objetos). Cada uno cuenta la historia de un monstruo derrotado o un mercader estafado.`,
];

/**
 * Returns an inventory header message.
 * @param {object} character
 * @returns {string}
 */
function getInventoryMessage(character) {
  const template = pickRandom(INVENTORY_MESSAGES);
  return template(character);
}

// ---------------------------------------------------------------------------
// Stats display messages
// ---------------------------------------------------------------------------

const STATS_MESSAGES = [
  (c) => `📊 Estadisticas de ${c.name || 'Aventurero'}:\n  ❤️  HP: ${c.hp}/${c.maxHp}\n  ⚔️  ATK: ${c.attack}\n  🛡️  DEF: ${c.defense}\n  ✨ XP: ${c.xp}\n  💰 Monedas: ${c.coins}\n  🪙 Smart Coins: ${c.smartCoins}\n  💀 Muertes: ${c.deaths || 0}\nImpresionante. O deprimente. Depende de tu punto de vista.`,
];

/**
 * Returns a formatted stats display message.
 * @param {object} character
 * @returns {string}
 */
function getStatsMessage(character) {
  const template = pickRandom(STATS_MESSAGES);
  return template(character);
}

// ---------------------------------------------------------------------------
// Generic move / exploration messages
// ---------------------------------------------------------------------------

const MOVE_MESSAGES = [
  (dir) => `Te mueves hacia el ${dir}. Cada paso resuena en la oscuridad. La mazmorra te observa con interes morbido.`,
  (dir) => `Avanzas al ${dir}. Las antorchas parpadean a tu paso, como si la mazmorra te dijera "bienvenido al siguiente error".`,
  (dir) => `Direccion: ${dir}. Te adentras mas en lo desconocido. Lo desconocido, por su parte, ya te conoce bien.`,
];

/**
 * Returns a movement narration.
 * @param {string} direction
 * @returns {string}
 */
function getMoveMessage(direction) {
  const template = pickRandom(MOVE_MESSAGES);
  return template(direction);
}

// ---------------------------------------------------------------------------
// Exports
// ---------------------------------------------------------------------------

module.exports = {
  getEnemyEncounterMessage,
  getTrapMessage,
  getMerchantMessage,
  getDeathMessage,
  getReturningMessage,
  getDungeonEntranceMessage,
  getPathChoiceMessage,
  getCombatResultMessage,
  getRandomEvent,
  getItemUseMessage,
  getHuntMessage,
  getInventoryMessage,
  getStatsMessage,
  getMoveMessage,
};
