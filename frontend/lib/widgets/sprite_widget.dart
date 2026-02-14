import 'package:flutter/material.dart';
import 'package:maxima_rpg/config/theme.dart';

/// Possible sprite animation states.
enum SpriteState {
  idle,
  attack,
  walkLeft,
  walkRight,
  hurt,
  death,
}

/// Displays a character sprite with animated state transitions.
/// Uses colored placeholder containers since actual sprite assets are not available.
/// AnimatedSwitcher handles smooth transitions between states.
class SpriteWidget extends StatelessWidget {
  final SpriteState state;
  final String characterClass;
  final double size;

  const SpriteWidget({
    super.key,
    required this.state,
    this.characterClass = 'Guerrero',
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _getAnimationDuration(),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        // Use a slide + fade transition for movement states.
        if (state == SpriteState.walkLeft || state == SpriteState.walkRight) {
          final offset = state == SpriteState.walkLeft
              ? Tween<Offset>(
                  begin: const Offset(0.3, 0), end: Offset.zero)
              : Tween<Offset>(
                  begin: const Offset(-0.3, 0), end: Offset.zero);
          return SlideTransition(
            position: offset.animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        }

        // Scale transition for attacks.
        if (state == SpriteState.attack) {
          return ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.elasticOut),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        }

        // Default fade transition.
        return FadeTransition(opacity: animation, child: child);
      },
      child: _buildSprite(),
    );
  }

  /// Returns the animation duration based on the current state.
  Duration _getAnimationDuration() {
    switch (state) {
      case SpriteState.attack:
        return const Duration(milliseconds: 300);
      case SpriteState.walkLeft:
      case SpriteState.walkRight:
        return const Duration(milliseconds: 500);
      case SpriteState.hurt:
        return const Duration(milliseconds: 250);
      case SpriteState.death:
        return const Duration(milliseconds: 800);
      case SpriteState.idle:
      default:
        return const Duration(milliseconds: 400);
    }
  }

  /// Builds the colored placeholder sprite container.
  /// Each state has a distinct visual representation.
  Widget _buildSprite() {
    return Container(
      key: ValueKey<SpriteState>(state),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getSpriteColor(),
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        border: Border.all(
          color: _getBorderColor(),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getGlowColor(),
            blurRadius: _getGlowRadius(),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // State indicator icon.
          Icon(
            _getStateIcon(),
            color: _getIconColor(),
            size: size * 0.5,
          ),

          // Class label at the bottom.
          Positioned(
            bottom: 4,
            child: Text(
              _getClassAbbreviation(),
              style: RPGTextStyles.systemMessage.copyWith(
                fontSize: 8,
                color: RPGColors.white.withOpacity(0.6),
              ),
            ),
          ),

          // State label at the top.
          Positioned(
            top: 4,
            child: Text(
              _getStateLabel(),
              style: RPGTextStyles.systemMessage.copyWith(
                fontSize: 7,
                color: RPGColors.grayText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the background color based on the sprite state.
  Color _getSpriteColor() {
    switch (state) {
      case SpriteState.idle:
        return RPGColors.darkGrayLight;
      case SpriteState.attack:
        return RPGColors.darkRed.withOpacity(0.6);
      case SpriteState.walkLeft:
      case SpriteState.walkRight:
        return RPGColors.darkPurple.withOpacity(0.4);
      case SpriteState.hurt:
        return RPGColors.darkRed.withOpacity(0.8);
      case SpriteState.death:
        return RPGColors.black;
    }
  }

  /// Returns the border color based on the character class.
  Color _getBorderColor() {
    switch (characterClass) {
      case 'Guerrero':
        return RPGColors.darkRed;
      case 'Mago':
        return RPGColors.darkPurple;
      case 'Ladronzuelo':
        return RPGColors.grayText;
      case 'Clerigo':
        return RPGColors.gold;
      default:
        return RPGColors.darkPurple;
    }
  }

  Color _getGlowColor() {
    switch (state) {
      case SpriteState.attack:
        return RPGColors.darkRed.withOpacity(0.5);
      case SpriteState.hurt:
        return RPGColors.redLight.withOpacity(0.6);
      case SpriteState.death:
        return RPGColors.darkRed.withOpacity(0.3);
      default:
        return RPGColors.darkPurple.withOpacity(0.2);
    }
  }

  double _getGlowRadius() {
    switch (state) {
      case SpriteState.attack:
        return 15;
      case SpriteState.hurt:
        return 12;
      case SpriteState.death:
        return 8;
      default:
        return 6;
    }
  }

  double _getBorderRadius() {
    switch (state) {
      case SpriteState.death:
        return 4;
      default:
        return 12;
    }
  }

  /// Returns the icon representing the current state.
  IconData _getStateIcon() {
    switch (state) {
      case SpriteState.idle:
        return _getClassIcon();
      case SpriteState.attack:
        return Icons.bolt;
      case SpriteState.walkLeft:
        return Icons.arrow_back;
      case SpriteState.walkRight:
        return Icons.arrow_forward;
      case SpriteState.hurt:
        return Icons.heart_broken;
      case SpriteState.death:
        return Icons.close;
    }
  }

  /// Returns the icon for the character class (used in idle state).
  IconData _getClassIcon() {
    switch (characterClass) {
      case 'Guerrero':
        return Icons.shield;
      case 'Mago':
        return Icons.auto_fix_high;
      case 'Ladronzuelo':
        return Icons.visibility;
      case 'Clerigo':
        return Icons.favorite;
      default:
        return Icons.person;
    }
  }

  Color _getIconColor() {
    switch (state) {
      case SpriteState.attack:
        return RPGColors.goldLight;
      case SpriteState.hurt:
        return RPGColors.white;
      case SpriteState.death:
        return RPGColors.darkRed;
      default:
        return RPGColors.gold;
    }
  }

  String _getClassAbbreviation() {
    switch (characterClass) {
      case 'Guerrero':
        return 'GUE';
      case 'Mago':
        return 'MAG';
      case 'Ladronzuelo':
        return 'LAD';
      case 'Clerigo':
        return 'CLE';
      default:
        return '???';
    }
  }

  String _getStateLabel() {
    switch (state) {
      case SpriteState.idle:
        return 'IDLE';
      case SpriteState.attack:
        return 'ATK';
      case SpriteState.walkLeft:
        return 'MOV';
      case SpriteState.walkRight:
        return 'MOV';
      case SpriteState.hurt:
        return 'HIT';
      case SpriteState.death:
        return 'RIP';
    }
  }
}
