import 'package:flutter/material.dart';
import 'package:maxima_rpg/config/theme.dart';

/// Horizontal stats bar displayed at the top of the game screen.
/// Shows HP (red), XP progress (blue), Level, and Coins.
class StatsBar extends StatelessWidget {
  final int hp;
  final int maxHp;
  final int xp;
  final int xpToNextLevel;
  final int level;
  final int coins;
  final VoidCallback? onBackPressed;

  const StatsBar({
    super.key,
    required this.hp,
    required this.maxHp,
    required this.xp,
    required this.xpToNextLevel,
    required this.level,
    required this.coins,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hpFraction = maxHp > 0 ? (hp / maxHp).clamp(0.0, 1.0) : 0.0;
    final xpFraction =
        xpToNextLevel > 0 ? (xp / xpToNextLevel).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: RPGColors.darkGray,
        border: Border(
          bottom: BorderSide(color: RPGColors.darkPurple, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Back button.
          if (onBackPressed != null)
            GestureDetector(
              onTap: onBackPressed,
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.arrow_back, color: RPGColors.gold, size: 20),
              ),
            ),

          // Level badge.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: RPGColors.darkPurple.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RPGColors.gold, width: 1),
            ),
            child: Text(
              'Nv.$level',
              style: RPGTextStyles.label.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // HP bar.
          Expanded(
            flex: 3,
            child: _buildProgressBar(
              label: 'HP',
              value: hp,
              maxValue: maxHp,
              fraction: hpFraction,
              fillColor: _getHpColor(hpFraction),
              backgroundColor: RPGColors.darkRed.withOpacity(0.2),
              icon: Icons.favorite,
              iconColor: RPGColors.darkRed,
            ),
          ),
          const SizedBox(width: 6),

          // XP bar.
          Expanded(
            flex: 3,
            child: _buildProgressBar(
              label: 'XP',
              value: xp,
              maxValue: xpToNextLevel,
              fraction: xpFraction,
              fillColor: Colors.blueAccent,
              backgroundColor: Colors.blueAccent.withOpacity(0.15),
              icon: Icons.auto_awesome,
              iconColor: Colors.blueAccent,
            ),
          ),
          const SizedBox(width: 8),

          // Coins display.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on,
                  color: RPGColors.gold, size: 16),
              const SizedBox(width: 3),
              Text(
                '$coins',
                style: RPGTextStyles.label.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a progress bar with label, icon, and fill animation.
  Widget _buildProgressBar({
    required String label,
    required int value,
    required int maxValue,
    required double fraction,
    required Color fillColor,
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row.
        Row(
          children: [
            Icon(icon, color: iconColor, size: 10),
            const SizedBox(width: 3),
            Text(
              '$label: $value/$maxValue',
              style: RPGTextStyles.systemMessage.copyWith(fontSize: 9),
            ),
          ],
        ),
        const SizedBox(height: 2),

        // Bar.
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                // Background.
                Container(
                  width: double.infinity,
                  color: backgroundColor,
                ),
                // Fill.
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction,
                  child: Container(
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Returns the HP bar color based on the current HP fraction.
  /// Green when high, yellow when medium, red when low.
  Color _getHpColor(double fraction) {
    if (fraction > 0.6) return Colors.greenAccent.shade700;
    if (fraction > 0.3) return Colors.orangeAccent;
    return RPGColors.darkRed;
  }
}

/// An animated version of [FractionallySizedBox] that smoothly transitions
/// its [widthFactor] over the given [duration].
class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  final AlignmentGeometry alignment;
  final double widthFactor;
  final Widget? child;

  const AnimatedFractionallySizedBox({
    super.key,
    required super.duration,
    super.curve,
    this.alignment = Alignment.center,
    required this.widthFactor,
    this.child,
  });

  @override
  AnimatedWidgetBaseState<AnimatedFractionallySizedBox> createState() =>
      _AnimatedFractionallySizedBoxState();
}

class _AnimatedFractionallySizedBoxState
    extends AnimatedWidgetBaseState<AnimatedFractionallySizedBox> {
  Tween<double>? _widthFactor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _widthFactor = visitor(
      _widthFactor,
      widget.widthFactor,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: widget.alignment,
      widthFactor: _widthFactor?.evaluate(animation) ?? widget.widthFactor,
      child: widget.child,
    );
  }
}
