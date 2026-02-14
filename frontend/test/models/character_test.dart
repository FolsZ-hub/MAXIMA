import 'package:flutter_test/flutter_test.dart';
import 'package:maxima_rpg/models/character.dart';

void main() {
  group('Character', () {
    test('fromJson/toJson roundtrip preserves all fields', () {
      final json = {
        'characterId': 'char_001',
        'playerId': 'uid_123',
        'name': 'Thalric',
        'characterClass': 'Mago',
        'race': 'Elfo',
        'subclass': 'Piromante',
        'weapon': {'name': 'Bastón de Fuego', 'damage': '1d8'},
        'stats': {'fuerza': 9, 'destreza': 12, 'constitucion': 10, 'carisma': 12},
        'level': 3,
        'hp': 60,
        'maxHp': 70,
        'xp': 45,
        'attack': 22,
        'defense': 5,
        'inventory': [
          {'name': 'Pocion', 'type': 'potion'},
        ],
        'isAlive': true,
      };

      final character = Character.fromJson(json);
      final output = character.toJson();

      expect(output['characterId'], 'char_001');
      expect(output['playerId'], 'uid_123');
      expect(output['name'], 'Thalric');
      expect(output['characterClass'], 'Mago');
      expect(output['race'], 'Elfo');
      expect(output['subclass'], 'Piromante');
      expect(output['weapon']['name'], 'Bastón de Fuego');
      expect(output['stats']['fuerza'], 9);
      expect(output['stats']['destreza'], 12);
      expect(output['level'], 3);
      expect(output['hp'], 60);
      expect(output['maxHp'], 70);
      expect(output['xp'], 45);
      expect(output['attack'], 22);
      expect(output['defense'], 5);
      expect((output['inventory'] as List).length, 1);
      expect(output['isAlive'], true);
    });

    test('optional fields default correctly', () {
      final character = Character(
        characterId: 'c1',
        playerId: 'p1',
        name: 'Nuevo',
        characterClass: 'Guerrero',
      );

      expect(character.race, '');
      expect(character.subclass, '');
      expect(character.weapon, isEmpty);
      expect(character.stats, isEmpty);
      expect(character.level, 1);
      expect(character.hp, 100);
      expect(character.maxHp, 100);
      expect(character.xp, 0);
      expect(character.attack, 10);
      expect(character.defense, 5);
      expect(character.inventory, isEmpty);
      expect(character.isAlive, true);
    });

    test('copyWith overrides specified fields', () {
      final original = Character(
        characterId: 'c1',
        playerId: 'p1',
        name: 'Original',
        characterClass: 'Mago',
        hp: 70,
        level: 5,
      );

      final copy = original.copyWith(name: 'Copia', hp: 30, level: 6);

      expect(copy.name, 'Copia');
      expect(copy.hp, 30);
      expect(copy.level, 6);
      // Unchanged fields
      expect(copy.characterId, 'c1');
      expect(copy.playerId, 'p1');
      expect(copy.characterClass, 'Mago');
    });

    test('xpToNextLevel and xpProgress compute correctly', () {
      final character = Character(
        characterId: 'c1',
        playerId: 'p1',
        name: 'Test',
        characterClass: 'Guerrero',
        level: 5,
        xp: 250,
      );

      expect(character.xpToNextLevel, 500); // 5 * 100
      expect(character.xpProgress, 0.5); // 250/500
    });

    test('hpFraction computes correctly', () {
      final character = Character(
        characterId: 'c1',
        playerId: 'p1',
        name: 'Test',
        characterClass: 'Guerrero',
        hp: 75,
        maxHp: 100,
      );

      expect(character.hpFraction, 0.75);
    });

    test('fromJson handles missing optional fields gracefully', () {
      final json = {
        'characterId': 'c1',
        'playerId': 'p1',
        'name': 'Minimal',
        'characterClass': 'Guerrero',
      };

      final character = Character.fromJson(json);
      expect(character.race, '');
      expect(character.subclass, '');
      expect(character.weapon, isEmpty);
      expect(character.stats, isEmpty);
      expect(character.isAlive, true);
    });
  });
}
