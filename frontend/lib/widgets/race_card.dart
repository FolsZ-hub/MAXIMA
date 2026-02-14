import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/race_model.dart';

/// Card widget for selecting a character race during character creation.
/// Displays the race sprite placeholder, name, description, and stat bonus.
class RaceCard extends StatelessWidget {
  final Race race;
  final bool isSelected;
  final VoidCallback onTap;

  const RaceCard({
    super.key,
    required this.race,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 130,
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A1A8F) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFCF9F1A)
                : const Color(0xFF4A1A8F).withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFCF9F1A).withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sprite placeholder - colored container with first letter
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6A3AAF).withOpacity(0.5)
                    : const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFCF9F1A).withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Text(
                  race.name[0],
                  style: GoogleFonts.cinzel(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? const Color(0xFFCF9F1A)
                        : Colors.white54,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Race name
            Text(
              race.name,
              style: GoogleFonts.cinzel(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color(0xFFCF9F1A)
                    : Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Description
            Text(
              race.description,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Bonus text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFCF9F1A).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                race.bonus,
                style: const TextStyle(
                  color: Color(0xFFCF9F1A),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
