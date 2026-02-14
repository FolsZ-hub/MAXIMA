import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maxima_rpg/config/theme.dart';
import 'package:maxima_rpg/services/auth_service.dart';
import 'package:maxima_rpg/services/firebase_service.dart';
import 'package:maxima_rpg/models/character.dart';

/// Profile screen showing character stats, inventory, coins, and legacy characters.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Character? _activeCharacter;
  List<Character> _legacyCharacters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCharacterData();
  }

  Future<void> _loadCharacterData() async {
    final auth = context.read<AuthService>();
    final firebase = context.read<FirebaseService>();
    final uid = auth.user?.uid;

    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final alive = await firebase.getAliveCharacters(uid);
      final legacy = await firebase.getLegacyCharacters(uid);

      setState(() {
        _activeCharacter = alive.isNotEmpty ? alive.first : null;
        _legacyCharacters = legacy;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final player = auth.player;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: RPGColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Perfil del Aventurero',
          style: RPGTextStyles.heading.copyWith(fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: RPGColors.gold),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Player info header.
                  _buildPlayerHeader(player?.username ?? 'Aventurero'),
                  const SizedBox(height: 24),

                  // Smart Coins balance.
                  _buildCoinsSection(player?.smartCoins ?? 0),
                  const SizedBox(height: 24),

                  // Active character stats.
                  if (_activeCharacter != null) ...[
                    _buildSectionTitle('Personaje Activo'),
                    const SizedBox(height: 12),
                    _buildCharacterStats(_activeCharacter!),
                    const SizedBox(height: 24),

                    // Inventory.
                    _buildSectionTitle('Inventario'),
                    const SizedBox(height: 12),
                    _buildInventory(_activeCharacter!),
                    const SizedBox(height: 24),
                  ] else
                    _buildNoCharacterMessage(),

                  // Legacy characters.
                  _buildSectionTitle('Personajes Caidos (Legado)'),
                  const SizedBox(height: 12),
                  _buildLegacyCharacters(),
                ],
              ),
            ),
    );
  }

  Widget _buildPlayerHeader(String username) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RPGColors.darkGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RPGColors.darkPurple),
      ),
      child: Row(
        children: [
          // Avatar placeholder.
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: RPGColors.darkPurple.withOpacity(0.4),
              border: Border.all(color: RPGColors.gold, width: 2),
            ),
            child: const Icon(
              Icons.person,
              color: RPGColors.gold,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: RPGTextStyles.heading.copyWith(fontSize: 20)),
                const SizedBox(height: 4),
                if (_activeCharacter != null)
                  Text(
                    '${_activeCharacter!.name} - ${_activeCharacter!.characterClass}',
                    style: RPGTextStyles.systemMessage,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinsSection(int coins) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: RPGColors.darkGrayLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RPGColors.gold.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Smart Coins', style: RPGTextStyles.subheading),
          Row(
            children: [
              const Icon(Icons.monetization_on, color: RPGColors.gold, size: 24),
              const SizedBox(width: 8),
              Text(
                '$coins',
                style: RPGTextStyles.heading.copyWith(fontSize: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: RPGTextStyles.subheading);
  }

  Widget _buildCharacterStats(Character character) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RPGColors.darkGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RPGColors.darkPurple),
      ),
      child: Column(
        children: [
          _buildStatRow('Nivel', '${character.level}', Icons.star,
              RPGColors.gold),
          const Divider(color: RPGColors.darkPurple, height: 16),
          _buildStatRow(
              'HP',
              '${character.hp} / ${character.maxHp}',
              Icons.favorite,
              RPGColors.darkRed),
          const Divider(color: RPGColors.darkPurple, height: 16),
          _buildStatRow(
            'XP',
            '${character.xp} / ${character.xpToNextLevel}',
            Icons.auto_awesome,
            Colors.blueAccent,
          ),
          const Divider(color: RPGColors.darkPurple, height: 16),
          _buildStatRow('Ataque', '${character.attack}', Icons.bolt,
              RPGColors.redLight),
          const Divider(color: RPGColors.darkPurple, height: 16),
          _buildStatRow(
              'Defensa', '${character.defense}', Icons.shield,
              RPGColors.purpleLight),
          const Divider(color: RPGColors.darkPurple, height: 16),
          _buildStatRow('Clase', character.characterClass,
              Icons.person_outline, RPGColors.gold),
        ],
      ),
    );
  }

  Widget _buildStatRow(
      String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: RPGTextStyles.body),
          const Spacer(),
          Text(
            value,
            style: RPGTextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventory(Character character) {
    if (character.inventory.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RPGColors.darkGray,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Tu inventario esta vacio. Explora mazmorras para encontrar objetos.',
          style: RPGTextStyles.systemMessage,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: character.inventory.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: RPGColors.darkGrayLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: RPGColors.darkPurple.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory_2, color: RPGColors.gold, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name']?.toString() ?? 'Objeto',
                      style: RPGTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item['description'] != null)
                      Text(
                        item['description'].toString(),
                        style: RPGTextStyles.systemMessage,
                      ),
                  ],
                ),
              ),
              if (item['quantity'] != null)
                Text(
                  'x${item['quantity']}',
                  style: RPGTextStyles.label,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoCharacterMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: RPGColors.darkGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber, color: RPGColors.gold, size: 48),
          const SizedBox(height: 12),
          Text(
            'No tienes un personaje activo.',
            style: RPGTextStyles.subheading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Crea uno nuevo desde el lobby.',
            style: RPGTextStyles.systemMessage,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyCharacters() {
    if (_legacyCharacters.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RPGColors.darkGray,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Aun no tienes personajes caidos. ¡Que siga asi!',
          style: RPGTextStyles.systemMessage,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: _legacyCharacters.map((character) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: RPGColors.darkGray,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: RPGColors.darkRed.withOpacity(0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.skull, color: RPGColors.darkRed, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          character.name,
                          style: RPGTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: RPGColors.darkRed,
                          ),
                        ),
                        Text(
                          '${character.characterClass} - Nivel ${character.level}',
                          style: RPGTextStyles.systemMessage,
                        ),
                      ],
                    ),
                  ),
                  // Returning button – use /returning command for legacy bonus.
                  ElevatedButton(
                    onPressed: () {
                      // Would trigger /returning command via socket.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Invocando el legado de ${character.name}...',
                            style: RPGTextStyles.playerChat,
                          ),
                          backgroundColor: RPGColors.darkPurple,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RPGColors.darkRed,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    child: Text(
                      '/returning',
                      style: RPGTextStyles.label.copyWith(
                        fontSize: 11,
                        color: RPGColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Bonus de legado: +${(character.level * 0.5).toInt()} ATK, '
                '+${(character.level * 0.3).toInt()} DEF',
                style: RPGTextStyles.systemMessage.copyWith(
                  color: RPGColors.goldLight,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
