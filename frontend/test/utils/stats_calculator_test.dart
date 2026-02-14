import 'package:flutter_test/flutter_test.dart';
import 'package:maxima_rpg/utils/stats_calculator.dart';
import 'package:maxima_rpg/models/race_model.dart';
import 'package:maxima_rpg/models/class_model.dart';
import 'package:maxima_rpg/data/character_data.dart';

void main() {
  // Helper to find race by name
  Race findRace(String name) =>
      availableRaces.firstWhere((r) => r.name == name);

  // Helper to find subclass by class name and subclass key
  Subclass findSubclass(String className, String subclassKey) =>
      availableClasses
          .firstWhere((c) => c.name == className)
          .subclasses[subclassKey]!;

  group('calculateInitialStats', () {
    test('Elfo Piromante: destreza=12, fuerza=9', () {
      final race = findRace('Elfo');
      final subclass = findSubclass('Mago', 'piromante');

      final stats = calculateInitialStats(race: race, subclass: subclass);

      // Base 10 + Elfo (destreza+2, fuerza-1) + Piromante (carisma+2, destreza+1)
      expect(stats['fuerza'], 9); // 10 - 1
      expect(stats['destreza'], 13); // 10 + 2 + 1
      expect(stats['constitucion'], 10); // unchanged
      expect(stats['carisma'], 12); // 10 + 2
    });

    test('Humano Espadachín: fuerza bonus via "any"', () {
      final race = findRace('Humano');
      final subclass = findSubclass('Guerrero', 'espadachin');

      final stats = calculateInitialStats(race: race, subclass: subclass);

      // Base 10 + Humano (any+1 → fuerza+1) + Espadachín (fuerza+2, destreza+1)
      expect(stats['fuerza'], 13); // 10 + 1 + 2
      expect(stats['destreza'], 11); // 10 + 1
      expect(stats['constitucion'], 10); // unchanged
      expect(stats['carisma'], 10); // unchanged
    });

    test('Enano Berserker: high constitucion and fuerza', () {
      final race = findRace('Enano');
      final subclass = findSubclass('Guerrero', 'berserker');

      final stats = calculateInitialStats(race: race, subclass: subclass);

      // Base 10 + Enano (constitucion+2, carisma-1) + Berserker (fuerza+3, constitucion-1)
      expect(stats['fuerza'], 13); // 10 + 3
      expect(stats['constitucion'], 11); // 10 + 2 - 1
      expect(stats['carisma'], 9); // 10 - 1
    });

    test('Orco Paladín: balanced build', () {
      final race = findRace('Orco');
      final subclass = findSubclass('Clérigo', 'paladin');

      final stats = calculateInitialStats(race: race, subclass: subclass);

      // Base 10 + Orco (fuerza+3, carisma-2) + Paladín (fuerza+1, constitucion+2)
      expect(stats['fuerza'], 14); // 10 + 3 + 1
      expect(stats['constitucion'], 12); // 10 + 2
      expect(stats['carisma'], 8); // 10 - 2
      expect(stats['destreza'], 10); // unchanged
    });

    test('No-Muerto Nigromante: constitucion and carisma focused', () {
      final race = findRace('No-Muerto');
      final subclass = findSubclass('Mago', 'nigromante');

      final stats = calculateInitialStats(race: race, subclass: subclass);

      // Base 10 + No-Muerto (constitucion+2, destreza-1) + Nigromante (constitucion+1, carisma+2)
      expect(stats['constitucion'], 13); // 10 + 2 + 1
      expect(stats['carisma'], 12); // 10 + 2
      expect(stats['destreza'], 9); // 10 - 1
      expect(stats['fuerza'], 10); // unchanged
    });
  });

  group('formatStats', () {
    test('formats stats as readable string', () {
      final stats = {
        'fuerza': 12,
        'destreza': 10,
        'constitucion': 8,
        'carisma': 14,
      };
      final result = formatStats(stats);

      expect(result, contains('Fuerza: 12'));
      expect(result, contains('Destreza: 10'));
      expect(result, contains('Constitucion: 8'));
      expect(result, contains('Carisma: 14'));
    });
  });

  group('getStatDifferences', () {
    test('calculates differences from base 10', () {
      final stats = {
        'fuerza': 13,
        'destreza': 9,
        'constitucion': 10,
        'carisma': 12,
      };
      final diffs = getStatDifferences(stats);

      expect(diffs['fuerza'], 3);
      expect(diffs['destreza'], -1);
      expect(diffs['constitucion'], 0);
      expect(diffs['carisma'], 2);
    });
  });
}
