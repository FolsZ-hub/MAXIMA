import 'package:flutter/material.dart';
import 'package:maxima_rpg/screens/login_screen.dart';
import 'package:maxima_rpg/screens/register_screen.dart';
import 'package:maxima_rpg/screens/lobby_screen.dart';
import 'package:maxima_rpg/screens/profile_screen.dart';
import 'package:maxima_rpg/screens/settings_screen.dart';
import 'package:maxima_rpg/screens/dungeon_select_screen.dart';
import 'package:maxima_rpg/screens/game_screen.dart';

/// Route name constants used for navigation throughout the app.
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String lobby = '/lobby';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String dungeonSelect = '/dungeon_select';
  static const String dungeon = '/dungeon';
  static const String game = '/game';
}

/// Generates a [Route] for the given [RouteSettings].
/// Returns the login screen for any unknown routes.
Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.login:
      return _buildRoute(const LoginScreen(), settings);

    case AppRoutes.register:
      return _buildRoute(const RegisterScreen(), settings);

    case AppRoutes.lobby:
      return _buildRoute(const LobbyScreen(), settings);

    case AppRoutes.profile:
      return _buildRoute(const ProfileScreen(), settings);

    case AppRoutes.settings:
      return _buildRoute(const SettingsScreen(), settings);

    case AppRoutes.dungeonSelect:
      return _buildRoute(const DungeonSelectScreen(), settings);

    case AppRoutes.dungeon:
    case AppRoutes.game:
      return _buildRoute(const GameScreen(), settings);

    default:
      return _buildRoute(const LoginScreen(), settings);
  }
}

/// Helper to build a [MaterialPageRoute] with a fade transition.
PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
