import '../models/race_model.dart';
import '../models/class_model.dart';

/// Calculates initial character stats based on race and subclass selection
Map<String, int> calculateInitialStats({
  required Race race,
  required Subclass subclass,
}) {
  final baseStats = {
    'fuerza': 10,
    'destreza': 10,
    'constitucion': 10,
    'carisma': 10,
  };

  // Apply race bonus
  race.statsBonus.forEach((stat, value) {
    if (stat == 'any') {
      // Humans get +1 to strength by default
      baseStats['fuerza'] = (baseStats['fuerza'] ?? 0) + value;
    } else {
      baseStats[stat] = (baseStats[stat] ?? 0) + value;
    }
  });

  // Apply subclass bonus
  subclass.statsBonus.forEach((stat, value) {
    baseStats[stat] = (baseStats[stat] ?? 0) + value;
  });

  return baseStats;
}

/// Returns a formatted string summary of stats
String formatStats(Map<String, int> stats) {
  return stats.entries
      .map((e) => '${e.key[0].toUpperCase()}${e.key.substring(1)}: ${e.value}')
      .join(' | ');
}

/// Returns the stat difference from base (10) for display
Map<String, int> getStatDifferences(Map<String, int> stats) {
  return stats.map((key, value) => MapEntry(key, value - 10));
}
