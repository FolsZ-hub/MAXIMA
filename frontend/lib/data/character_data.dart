import '../models/race_model.dart';
import '../models/class_model.dart';

/// Static data for all playable races in the game
const List<Race> availableRaces = [
  Race(
    name: 'Humano',
    description:
        'Versátil y adaptable. Donde otros ven límites, el humano ve oportunidades... o al menos eso dicen.',
    spritePath: 'assets/races/humano_base.png',
    bonus: '+1 a cualquier stat',
    statsBonus: {'any': 1},
  ),
  Race(
    name: 'Elfo',
    description:
        'Ágil, preciso y con una arrogancia que solo los siglos pueden dar.',
    spritePath: 'assets/races/elfo_base.png',
    bonus: '+2 Destreza, -1 Fuerza',
    statsBonus: {'destreza': 2, 'fuerza': -1},
  ),
  Race(
    name: 'Enano',
    description:
        'Bajo, robusto y más terco que una mula. Pero nadie lo dice en su cara.',
    spritePath: 'assets/races/enano_base.png',
    bonus: '+2 Constitución, -1 Carisma',
    statsBonus: {'constitucion': 2, 'carisma': -1},
  ),
  Race(
    name: 'Orco',
    description:
        'Grande, verde y con una tendencia preocupante a resolver todo con violencia.',
    spritePath: 'assets/races/orco_base.png',
    bonus: '+3 Fuerza, -2 Carisma',
    statsBonus: {'fuerza': 3, 'carisma': -2},
  ),
  Race(
    name: 'No-Muerto',
    description:
        'Técnicamente muerto, pero eso no le impide tener una agenda ocupada.',
    spritePath: 'assets/races/no_muerto_base.png',
    bonus: '+2 Constitución, -1 Destreza',
    statsBonus: {'constitucion': 2, 'destreza': -1},
  ),
];

/// Static data for all character classes and their subclasses
const List<CharacterClass> availableClasses = [
  // Guerrero class with Espadachín and Berserker subclasses
  CharacterClass(
    name: 'Guerrero',
    description: 'Maestro del acero y la violencia controlada',
    iconPath: 'assets/classes/guerrero.png',
    subclasses: {
      'espadachin': Subclass(
        name: 'Espadachín',
        weaponName: 'Espada de Hierro',
        weaponSprite: 'assets/weapons/espada_hierro.png',
        ability: 'Ataque Doble',
        abilityDescription: '10% de probabilidad de atacar dos veces',
        statsBonus: {'fuerza': 2, 'destreza': 1},
      ),
      'berserker': Subclass(
        name: 'Berserker',
        weaponName: 'Hacha de Guerra',
        weaponSprite: 'assets/weapons/hacha_guerra.png',
        ability: 'Furia Berserker',
        abilityDescription: 'Daño +50% cuando HP < 30%',
        statsBonus: {'fuerza': 3, 'constitucion': -1},
      ),
    },
  ),

  // Mago class with Piromante and Nigromante subclasses
  CharacterClass(
    name: 'Mago',
    description:
        'Domina las fuerzas arcanas... cuando no le explotan en la cara',
    iconPath: 'assets/classes/mago.png',
    subclasses: {
      'piromante': Subclass(
        name: 'Piromante',
        weaponName: 'Bastón de Fuego',
        weaponSprite: 'assets/weapons/baston_fuego.png',
        ability: 'Bola de Fuego',
        abilityDescription: '15% de probabilidad de quemar al enemigo',
        statsBonus: {'carisma': 2, 'destreza': 1},
      ),
      'nigromante': Subclass(
        name: 'Nigromante',
        weaponName: 'Grimorio Oscuro',
        weaponSprite: 'assets/weapons/grimorio_oscuro.png',
        ability: 'Drenar Vida',
        abilityDescription: 'Recupera 25% del daño infligido como HP',
        statsBonus: {'constitucion': 1, 'carisma': 2},
      ),
    },
  ),

  // Ladronzuelo class with Asesino and Explorador subclasses
  CharacterClass(
    name: 'Ladronzuelo',
    description: 'Silencioso, letal, y con los bolsillos siempre llenos',
    iconPath: 'assets/classes/ladronzuelo.png',
    subclasses: {
      'asesino': Subclass(
        name: 'Asesino',
        weaponName: 'Dagas Gemelas',
        weaponSprite: 'assets/weapons/dagas_gemelas.png',
        ability: 'Golpe Crítico',
        abilityDescription: '25% más de probabilidad de golpe crítico',
        statsBonus: {'destreza': 3, 'constitucion': -1},
      ),
      'explorador': Subclass(
        name: 'Explorador',
        weaponName: 'Arco Corto',
        weaponSprite: 'assets/weapons/arco_corto.png',
        ability: 'Ojo de Águila',
        abilityDescription: 'Nunca falla con tirada >= 8 (en vez de 10)',
        statsBonus: {'destreza': 2, 'carisma': 1},
      ),
    },
  ),

  // Clérigo class with Sanador and Paladín subclasses
  CharacterClass(
    name: 'Clérigo',
    description:
        'Sanador, protector, y la única razón por la que el grupo sigue vivo',
    iconPath: 'assets/classes/clerigo.png',
    subclasses: {
      'sanador': Subclass(
        name: 'Sanador',
        weaponName: 'Báculo Sagrado',
        weaponSprite: 'assets/weapons/baculo_sagrado.png',
        ability: 'Curación Divina',
        abilityDescription: 'Puede curar 20 HP a un aliado por turno',
        statsBonus: {'carisma': 2, 'constitucion': 1},
      ),
      'paladin': Subclass(
        name: 'Paladín',
        weaponName: 'Martillo Bendito',
        weaponSprite: 'assets/weapons/martillo_bendito.png',
        ability: 'Escudo Divino',
        abilityDescription: 'Reduce daño recibido en 25%',
        statsBonus: {'fuerza': 1, 'constitucion': 2},
      ),
    },
  ),
];
