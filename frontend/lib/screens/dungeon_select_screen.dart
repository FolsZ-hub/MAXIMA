import 'package:flutter/material.dart';
import 'package:maxima_rpg/config/theme.dart';
import 'package:maxima_rpg/config/routes.dart';
import 'package:maxima_rpg/models/dungeon.dart';
import 'package:maxima_rpg/widgets/dungeon_card.dart';

/// Screen where the player selects which dungeon to enter.
class DungeonSelectScreen extends StatelessWidget {
  const DungeonSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dungeons = Dungeon.getDefaultDungeons();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: RPGColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mazmorras',
          style: RPGTextStyles.heading.copyWith(fontSize: 18),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              RPGColors.darkPurple.withOpacity(0.1),
              RPGColors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Title quote from the Master.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '"Elige tu destino, mortal..."',
                  style: RPGTextStyles.masterNarration.copyWith(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Cada mazmorra esconde peligros y recompensas. '
                  'Elige sabiamente.',
                  style: RPGTextStyles.systemMessage,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Dungeon cards list.
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: dungeons.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DungeonCard(
                        dungeon: dungeons[index],
                        onTap: () {
                          _enterDungeon(context, dungeons[index]);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigates to the game screen with the selected dungeon.
  void _enterDungeon(BuildContext context, Dungeon dungeon) {
    Navigator.pushNamed(
      context,
      AppRoutes.game,
      arguments: dungeon,
    );
  }
}
