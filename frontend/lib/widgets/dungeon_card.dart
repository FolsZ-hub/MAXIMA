import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maxima_rpg/config/theme.dart';
import 'package:maxima_rpg/models/dungeon.dart';

/// Card widget for dungeon selection.
/// Shows dungeon icon placeholder, name, difficulty badge, description, and rewards.
/// Difficulty is color-coded: green = easy, gold = medium, red = hard.
class DungeonCard extends StatelessWidget {
  final Dungeon dungeon;
  final VoidCallback? onTap;

  const DungeonCard({
    super.key,
    required this.dungeon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: RPGColors.darkGray,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _getDifficultyColor().withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _getDifficultyColor().withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon, name, and difficulty badge.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RPGColors.darkGrayLight,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  // Dungeon icon placeholder.
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _getDifficultyColor().withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _getDifficultyColor().withOpacity(0.4),
                      ),
                    ),
                    child: Icon(
                      _getDungeonIcon(),
                      color: _getDifficultyColor(),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name and difficulty.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dungeon.name,
                          style: GoogleFonts.cinzel(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: RPGColors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        _buildDifficultyBadge(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Description.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                dungeon.description,
                style: RPGTextStyles.systemMessage.copyWith(
                  height: 1.5,
                  fontSize: 12,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Footer with reward, min level, and enemies.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: RPGColors.black.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Reward.
                  _buildInfoChip(
                    icon: Icons.monetization_on,
                    label: '${dungeon.reward} SC',
                    color: RPGColors.gold,
                  ),

                  // Min level.
                  _buildInfoChip(
                    icon: Icons.star,
                    label: 'Nv. ${dungeon.minLevel}+',
                    color: RPGColors.purpleLight,
                  ),

                  // Enemies indicator.
                  _buildInfoChip(
                    icon: Icons.groups,
                    label: _getEnemyCount(),
                    color: _getDifficultyColor(),
                  ),

                  // Enter arrow.
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor().withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: _getDifficultyColor(),
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the color-coded difficulty badge.
  Widget _buildDifficultyBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getDifficultyColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getDifficultyColor().withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        _getDifficultyLabel(),
        style: RPGTextStyles.systemMessage.copyWith(
          color: _getDifficultyColor(),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  /// Builds a small info chip with an icon and label.
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: RPGTextStyles.systemMessage.copyWith(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Returns the color for the dungeon difficulty.
  Color _getDifficultyColor() {
    switch (dungeon.difficulty) {
      case 'Facil':
        return Colors.greenAccent.shade400;
      case 'Media':
        return RPGColors.gold;
      case 'Dificil':
        return RPGColors.darkRed;
      default:
        return RPGColors.grayText;
    }
  }

  /// Returns the translated difficulty label.
  String _getDifficultyLabel() {
    switch (dungeon.difficulty) {
      case 'Facil':
        return 'FACIL';
      case 'Media':
        return 'MEDIA';
      case 'Dificil':
        return 'DIFICIL';
      default:
        return dungeon.difficulty.toUpperCase();
    }
  }

  /// Returns an icon representing the dungeon type/difficulty.
  IconData _getDungeonIcon() {
    switch (dungeon.difficulty) {
      case 'Facil':
        return Icons.brightness_3; // Catacombs / easy
      case 'Media':
        return Icons.terrain; // Labyrinth / medium
      case 'Dificil':
        return Icons.local_fire_department; // Dragon abyss / hard
      default:
        return Icons.castle;
    }
  }

  /// Returns a descriptive enemy count based on difficulty.
  String _getEnemyCount() {
    switch (dungeon.difficulty) {
      case 'Facil':
        return '3-5';
      case 'Media':
        return '5-10';
      case 'Dificil':
        return '10+';
      default:
        return '?';
    }
  }
}
