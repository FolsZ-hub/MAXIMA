import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget that displays Master/DM narration messages with RPG styling.
/// Features a gold left border, fade-in animation, and the signature
/// cynical narrator tone rendered in Cinzel italic gold text.
class MasterMessage extends StatelessWidget {
  final String message;
  final bool animate;

  const MasterMessage(this.message, {super.key, this.animate = true});

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: const Border(
          left: BorderSide(color: Color(0xFFCF9F1A), width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCF9F1A).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Master" label
          Text(
            'El Master dice:',
            style: GoogleFonts.cinzel(
              fontSize: 10,
              color: const Color(0xFFCF9F1A).withOpacity(0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),

          // Message content
          Text(
            message,
            style: GoogleFonts.cinzel(
              fontSize: 14,
              color: const Color(0xFFCF9F1A),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );

    // Wrap in a fade-in + slide-up animation when enabled
    if (animate) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - value)),
              child: child,
            ),
          );
        },
        child: content,
      );
    }

    return content;
  }
}
