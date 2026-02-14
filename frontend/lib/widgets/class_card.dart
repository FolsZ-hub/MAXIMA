import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/class_model.dart';

/// Card widget for selecting a character class during character creation.
/// Displays the class icon, name, description, and available subclasses as chips.
class ClassCard extends StatelessWidget {
  final CharacterClass characterClass;
  final bool isSelected;
  final VoidCallback onTap;

  const ClassCard({
    super.key,
    required this.characterClass,
    required this.isSelected,
    required this.onTap,
  });

  /// Returns an icon based on the class name.
  IconData _getClassIcon() {
    switch (characterClass.name.toLowerCase()) {
      case 'guerrero':
        return Icons.shield;
      case 'mago':
        return Icons.auto_fix_high;
      case 'ladronzuelo':
        return Icons.visibility;
      case 'clerigo':
      case 'clérigo':
        return Icons.favorite;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8F1A1A)
              : const Color(0xFF3A3A3A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFCF9F1A)
                : const Color(0xFF4A1A8F).withOpacity(0.4),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFCF9F1A).withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon + name
            Row(
              children: [
                // Icon placeholder
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFCF9F1A).withOpacity(0.15)
                        : const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFCF9F1A).withOpacity(0.5)
                          : const Color(0xFF4A1A8F).withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    _getClassIcon(),
                    color: isSelected
                        ? const Color(0xFFCF9F1A)
                        : Colors.white54,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),

                // Class name and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        characterClass.name,
                        style: GoogleFonts.cinzel(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? const Color(0xFFCF9F1A)
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        characterClass.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Selection indicator
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFFCF9F1A),
                    size: 22,
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Divider
            Container(
              height: 1,
              color: isSelected
                  ? const Color(0xFFCF9F1A).withOpacity(0.2)
                  : const Color(0xFF4A1A8F).withOpacity(0.2),
            ),
            const SizedBox(height: 8),

            // Subclass label
            Text(
              'Subclases disponibles:',
              style: GoogleFonts.robotoMono(
                fontSize: 10,
                color: isSelected
                    ? const Color(0xFFCF9F1A).withOpacity(0.7)
                    : Colors.white38,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),

            // Subclass chips row
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: characterClass.subclasses.values.map((subclass) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFCF9F1A).withOpacity(0.12)
                        : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFCF9F1A).withOpacity(0.4)
                          : const Color(0xFF4A1A8F).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    subclass.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFFE8BF3A)
                          : Colors.white60,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
