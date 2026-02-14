import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/weapon_model.dart';

/// Compact widget for displaying a weapon's details in the character creation
/// preview area. Shows name, damage, rarity indicator, and optional effect.
class WeaponDisplay extends StatelessWidget {
  final Weapon weapon;

  const WeaponDisplay({
    super.key,
    required this.weapon,
  });

  /// Returns an icon based on the weapon name keywords.
  IconData _getWeaponIcon() {
    final lower = weapon.name.toLowerCase();
    if (lower.contains('martillo') || lower.contains('maza')) {
      return Icons.gavel;
    } else if (lower.contains('daga') || lower.contains('cuchillo')) {
      return Icons.content_cut;
    } else if (lower.contains('arco')) {
      return Icons.arrow_upward;
    } else if (lower.contains('baston') || lower.contains('bastón') || lower.contains('cetro')) {
      return Icons.bolt;
    } else if (lower.contains('espada') || lower.contains('sable')) {
      return Icons.gavel;
    }
    return Icons.sports_kabaddi;
  }

  /// Returns the rarity display color.
  Color _getRarityColor() {
    switch (weapon.rarity.toLowerCase()) {
      case 'common':
      case 'comun':
      case 'común':
        return Colors.grey;
      case 'uncommon':
      case 'poco comun':
      case 'poco común':
        return Colors.greenAccent.shade400;
      case 'rare':
      case 'rara':
      case 'raro':
        return Colors.blueAccent;
      case 'legendary':
      case 'legendaria':
      case 'legendario':
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }

  /// Returns the rarity label in Spanish.
  String _getRarityLabel() {
    switch (weapon.rarity.toLowerCase()) {
      case 'common':
      case 'comun':
      case 'común':
        return 'Comun';
      case 'uncommon':
      case 'poco comun':
      case 'poco común':
        return 'Poco comun';
      case 'rare':
      case 'rara':
      case 'raro':
        return 'Rara';
      case 'legendary':
      case 'legendaria':
      case 'legendario':
        return 'Legendaria';
      default:
        return weapon.rarity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _getRarityColor();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFCF9F1A).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weapon icon placeholder
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: rarityColor.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Icon(
              _getWeaponIcon(),
              color: const Color(0xFFCF9F1A),
              size: 36,
            ),
          ),
          const SizedBox(width: 12),

          // Weapon details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Weapon name
                Text(
                  weapon.name,
                  style: GoogleFonts.cinzel(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFCF9F1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Rarity indicator with colored dot
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: rarityColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: rarityColor.withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getRarityLabel(),
                      style: TextStyle(
                        color: rarityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Damage info
                Row(
                  children: [
                    const Icon(
                      Icons.flash_on,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Dano: ${weapon.damage}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Effect text (if present)
                if (weapon.effect != null && weapon.effect!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    weapon.effect!,
                    style: GoogleFonts.cinzel(
                      fontSize: 10,
                      color: const Color(0xFFCF9F1A),
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
