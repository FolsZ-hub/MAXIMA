import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/race_model.dart';
import '../models/class_model.dart';
import '../models/character.dart';
import '../data/character_data.dart';
import '../utils/stats_calculator.dart';
import '../services/firebase_service.dart';
import '../widgets/race_card.dart';
import '../widgets/class_card.dart';
import '../config/theme.dart';
import '../config/routes.dart';

// =============================================================================
// CharacterCreationScreen
//
// Full-featured character creation flow for the MAXIMA RPG. The player picks
// a race, class, subclass, names their character, previews computed stats,
// and persists everything to Firebase before entering the lobby.
// =============================================================================

class CharacterCreationScreen extends StatefulWidget {
  /// The Firebase UID of the authenticated player.
  final String userId;

  const CharacterCreationScreen({super.key, required this.userId});

  @override
  State<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  // ---- Form state ----
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // ---- Selection state ----
  Race? _selectedRace;
  CharacterClass? _selectedClass;
  Subclass? _selectedSubclass;
  String? _selectedSubclassName; // key inside CharacterClass.subclasses map

  // ---- Derived / UI state ----
  String? _masterMessage;
  bool _isLoading = false;
  Map<String, int>? _calculatedStats;

  // ---- Scroll controller for auto-scrolling on selection ----
  final ScrollController _scrollController = ScrollController();

  // ---- References to data ----
  List<Race> get _races => availableRaces;
  List<CharacterClass> get _classes => availableClasses;

  @override
  void initState() {
    super.initState();
    // Set the initial narrator message.
    _masterMessage =
        'Antes de adentrarte en la oscuridad, necesitas un nombre. '
        'Uno que inspire terror... o al menos risa.';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Selection handlers
  // ---------------------------------------------------------------------------

  /// Called when the player taps a race card.
  void _onRaceSelected(Race race) {
    setState(() {
      _selectedRace = race;
      // Reset downstream selections when race changes.
      _selectedClass = null;
      _selectedSubclass = null;
      _selectedSubclassName = null;
      _calculatedStats = null;
      _masterMessage =
          'Un ${race.name}... ${race.description} ${race.bonus}.';
    });
    _scrollToBottom();
  }

  /// Called when the player taps a class card.
  void _onClassSelected(CharacterClass characterClass) {
    setState(() {
      _selectedClass = characterClass;
      // Reset subclass when class changes.
      _selectedSubclass = null;
      _selectedSubclassName = null;
      _calculatedStats = null;
      _masterMessage =
          '${characterClass.name}... ${characterClass.description}. '
          'Veamos qué especialización eliges.';
    });
    _scrollToBottom();
  }

  /// Called when the player taps a subclass option.
  void _onSubclassSelected(String key, Subclass subclass) {
    setState(() {
      _selectedSubclass = subclass;
      _selectedSubclassName = key;

      // Calculate stats based on race + subclass.
      _calculatedStats = calculateInitialStats(
        race: _selectedRace!,
        subclass: subclass,
      );

      _masterMessage =
          'Un ${_selectedClass!.name} ${subclass.name}... '
          '${subclass.ability}. ${subclass.abilityDescription}.';
    });
    _scrollToBottom();
  }

  /// Auto-scroll to the bottom after a short delay so new sections are visible.
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 350), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Character creation / Firebase persistence
  // ---------------------------------------------------------------------------

  /// Returns `true` when every required field has been filled.
  bool get _isFormComplete {
    final nameValid = _nameController.text.trim().isNotEmpty &&
        RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ0-9 ]+$')
            .hasMatch(_nameController.text.trim());
    return nameValid &&
        _selectedRace != null &&
        _selectedClass != null &&
        _selectedSubclass != null &&
        _calculatedStats != null;
  }

  /// Validates form, builds the [Character], persists to Firestore, and
  /// navigates to the lobby.
  Future<void> _onConfirm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isFormComplete) return;

    setState(() => _isLoading = true);

    try {
      final characterId =
          DateTime.now().millisecondsSinceEpoch.toString();

      // Derive combat stats from the calculated stat block.
      final stats = _calculatedStats!;
      final fuerza = stats['fuerza'] ?? 10;
      final constitucion = stats['constitucion'] ?? 10;
      final destreza = stats['destreza'] ?? 10;

      // HP derived from constitution, attack from strength, defense from dexterity.
      final maxHp = 80 + (constitucion * 2);
      final attack = 5 + fuerza;
      final defense = 3 + destreza;

      // Build the starting weapon as an inventory item.
      final startingWeapon = <String, dynamic>{
        'name': _selectedSubclass!.weaponName,
        'sprite': _selectedSubclass!.weaponSprite,
        'type': 'weapon',
        'equipped': true,
      };

      final character = Character(
        characterId: characterId,
        playerId: widget.userId,
        name: _nameController.text.trim(),
        characterClass: _selectedClass!.name,
        level: 1,
        hp: maxHp,
        maxHp: maxHp,
        xp: 0,
        attack: attack,
        defense: defense,
        inventory: [startingWeapon],
        isAlive: true,
      );

      final firebaseService = FirebaseService();

      // Persist the character document.
      await firebaseService.createCharacter(character);

      // Store extended fields (race, subclass, weapon, stats) that are not
      // part of the base Character model but are needed for gameplay.
      await firebaseService.updateCharacter(characterId, {
        'race': _selectedRace!.name,
        'subclass': _selectedSubclass!.name,
        'weapon': _selectedSubclass!.weaponName,
        'stats': _calculatedStats,
      });

      // Update the player's active character and add to legacy list.
      await firebaseService.updatePlayer(widget.userId, {
        'activeCharacterId': characterId,
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.lobby);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al crear personaje: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: RPGColors.darkRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  RPGColors.darkPurple.withOpacity(0.3),
                  RPGColors.black,
                  RPGColors.black,
                ],
              ),
            ),
          ),

          // Main content.
          SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildMasterMessage(),
                    const SizedBox(height: 24),
                    _buildNameInput(),
                    const SizedBox(height: 32),
                    _buildRaceSection(),
                    const SizedBox(height: 8),
                    _buildClassSection(),
                    const SizedBox(height: 8),
                    _buildSubclassSection(),
                    const SizedBox(height: 8),
                    _buildPreviewSection(),
                    const SizedBox(height: 16),
                    _buildConfirmButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Full-screen loading overlay.
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: RPGColors.gold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section builders
  // ---------------------------------------------------------------------------

  /// Page header with title and subtitle.
  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          'Forja tu Destino',
          style: GoogleFonts.cinzel(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: RPGColors.gold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Elige sabiamente, mortal...',
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: Colors.white70,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Narrator message box that updates contextually.
  Widget _buildMasterMessage() {
    if (_masterMessage == null) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: _masterMessage != null ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: RPGColors.darkGray,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: RPGColors.gold.withOpacity(0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: RPGColors.darkPurple.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Narrator icon.
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: RPGColors.darkPurple.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_stories,
                  color: RPGColors.gold,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maestro de Mazmorra',
                      style: GoogleFonts.cinzel(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: RPGColors.gold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _masterMessage!,
                      style: RPGTextStyles.masterNarration.copyWith(
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Character name text field with validation.
  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nombre del Personaje',
          style: GoogleFonts.cinzel(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: RPGColors.gold,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _nameController,
          maxLength: 15,
          style: RPGTextStyles.playerChat,
          decoration: InputDecoration(
            labelText: 'Nombre del Personaje',
            labelStyle: RPGTextStyles.label,
            hintText: 'Ej: Thalric el Implacable',
            hintStyle: TextStyle(
              color: RPGColors.grayText.withOpacity(0.5),
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.badge_outlined,
              color: RPGColors.gold,
            ),
            counterStyle: const TextStyle(color: RPGColors.grayText),
            filled: true,
            fillColor: RPGColors.darkGrayLight,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: RPGColors.darkPurple,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: RPGColors.gold,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: RPGColors.darkRed,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: RPGColors.darkRed,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Tu personaje necesita un nombre';
            }
            if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ0-9 ]+$')
                .hasMatch(value.trim())) {
              return 'Solo letras, numeros y espacios';
            }
            return null;
          },
          onChanged: (_) => setState(() {}), // refresh button state
        ),
      ],
    );
  }

  // ---- Race selection section ----

  Widget _buildRaceSection() {
    return _buildAnimatedSection(
      visible: true, // Always visible.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Elige tu Raza'),
          const SizedBox(height: 12),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: _races.map((race) {
                return RaceCard(
                  race: race,
                  isSelected: _selectedRace?.name == race.name,
                  onTap: () => _onRaceSelected(race),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Class selection section ----

  Widget _buildClassSection() {
    return _buildAnimatedSection(
      visible: _selectedRace != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildSectionTitle('Elige tu Clase'),
          const SizedBox(height: 12),
          ..._classes.map((characterClass) {
            return ClassCard(
              characterClass: characterClass,
              isSelected: _selectedClass?.name == characterClass.name,
              onTap: () => _onClassSelected(characterClass),
            );
          }),
        ],
      ),
    );
  }

  // ---- Subclass selection section ----

  Widget _buildSubclassSection() {
    if (_selectedClass == null) {
      return const SizedBox.shrink();
    }

    final subclasses = _selectedClass!.subclasses;

    return _buildAnimatedSection(
      visible: _selectedClass != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildSectionTitle('Elige tu Especializacion'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: subclasses.entries.map((entry) {
              final key = entry.key;
              final subclass = entry.value;
              final isSelected = _selectedSubclassName == key;

              return GestureDetector(
                onTap: () => _onSubclassSelected(key, subclass),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: MediaQuery.of(context).size.width * 0.42,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? RPGColors.darkPurple.withOpacity(0.5)
                        : RPGColors.darkGrayLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? RPGColors.gold
                          : RPGColors.darkPurple.withOpacity(0.4),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: RPGColors.gold.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subclass name.
                      Text(
                        subclass.name,
                        style: GoogleFonts.cinzel(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? RPGColors.gold
                              : RPGColors.white,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Weapon name.
                      Row(
                        children: [
                          Icon(
                            Icons.gavel,
                            size: 14,
                            color: isSelected
                                ? RPGColors.goldLight
                                : RPGColors.grayText,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              subclass.weaponName,
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: isSelected
                                    ? RPGColors.goldLight
                                    : Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Divider.
                      Container(
                        height: 1,
                        color: isSelected
                            ? RPGColors.gold.withOpacity(0.2)
                            : RPGColors.darkPurple.withOpacity(0.2),
                      ),
                      const SizedBox(height: 6),

                      // Ability name.
                      Text(
                        subclass.ability,
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? RPGColors.gold
                              : Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Ability description.
                      Text(
                        subclass.abilityDescription,
                        style: GoogleFonts.roboto(
                          fontSize: 10,
                          color: Colors.white54,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---- Preview section ----

  Widget _buildPreviewSection() {
    if (_selectedSubclass == null || _calculatedStats == null) {
      return const SizedBox.shrink();
    }

    final stats = _calculatedStats!;
    final diffs = getStatDifferences(stats);

    return _buildAnimatedSection(
      visible: _selectedSubclass != null && _calculatedStats != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildSectionTitle('Vista Previa'),
          const SizedBox(height: 16),

          // Character sprite placeholder and summary.
          Center(
            child: Column(
              children: [
                // Sprite placeholder: race initial + class icon overlay.
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: RPGColors.darkGray,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: RPGColors.gold.withOpacity(0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: RPGColors.darkPurple.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Race initial - large.
                      Text(
                        _selectedRace!.name[0],
                        style: GoogleFonts.cinzel(
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          color: RPGColors.gold.withOpacity(0.3),
                        ),
                      ),
                      // Class icon overlay.
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: RPGColors.darkPurple,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: RPGColors.gold.withOpacity(0.5),
                            ),
                          ),
                          child: Icon(
                            _getClassIcon(_selectedClass!.name),
                            color: RPGColors.gold,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Character name display.
                Text(
                  _nameController.text.trim().isNotEmpty
                      ? _nameController.text.trim()
                      : 'Sin Nombre',
                  style: GoogleFonts.cinzel(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: RPGColors.gold,
                  ),
                ),
                const SizedBox(height: 4),

                // Race + Class + Subclass summary.
                Text(
                  '${_selectedRace!.name} - ${_selectedClass!.name} '
                  '(${_selectedSubclass!.name})',
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats grid (2x2).
          _buildStatsGrid(stats, diffs),
          const SizedBox(height: 20),

          // Weapon display.
          _buildWeaponDisplay(),
          const SizedBox(height: 16),

          // Character summary text.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: RPGColors.darkGrayLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: RPGColors.darkPurple.withOpacity(0.4),
              ),
            ),
            child: Text(
              'Nivel 1 | HP: ${80 + (stats['constitucion'] ?? 10) * 2} | '
              'ATK: ${5 + (stats['fuerza'] ?? 10)} | '
              'DEF: ${3 + (stats['destreza'] ?? 10)}',
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                color: RPGColors.goldLight,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the 2x2 stat grid with values and diff indicators.
  Widget _buildStatsGrid(Map<String, int> stats, Map<String, int> diffs) {
    final statEntries = stats.entries.toList();

    // Stat display names and icons.
    final statMeta = <String, Map<String, dynamic>>{
      'fuerza': {'label': 'Fuerza', 'icon': Icons.fitness_center},
      'destreza': {'label': 'Destreza', 'icon': Icons.speed},
      'constitucion': {'label': 'Constitucion', 'icon': Icons.shield},
      'carisma': {'label': 'Carisma', 'icon': Icons.record_voice_over},
    };

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemCount: statEntries.length,
      itemBuilder: (context, index) {
        final entry = statEntries[index];
        final key = entry.key;
        final value = entry.value;
        final diff = diffs[key] ?? 0;
        final meta = statMeta[key] ??
            {'label': key, 'icon': Icons.circle};

        final diffColor = diff > 0
            ? const Color(0xFF4CAF50)
            : diff < 0
                ? RPGColors.darkRed
                : RPGColors.grayText;
        final diffText = diff > 0
            ? '+$diff'
            : diff < 0
                ? '$diff'
                : '+0';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: RPGColors.darkGray,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: RPGColors.darkPurple.withOpacity(0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                meta['icon'] as IconData,
                color: RPGColors.gold.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta['label'] as String,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '$value',
                          style: GoogleFonts.robotoMono(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: RPGColors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          diffText,
                          style: GoogleFonts.robotoMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: diffColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Inline weapon display showing the subclass starting weapon.
  Widget _buildWeaponDisplay() {
    final subclass = _selectedSubclass;
    if (subclass == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RPGColors.darkGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: RPGColors.gold.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Weapon icon placeholder.
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: RPGColors.darkPurple.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: RPGColors.gold.withOpacity(0.4),
              ),
            ),
            child: const Icon(
              Icons.gavel,
              color: RPGColors.gold,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Arma Inicial',
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    color: RPGColors.grayText,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subclass.weaponName,
                  style: GoogleFonts.cinzel(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: RPGColors.goldLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Habilidad: ${subclass.ability}',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Confirm button ----

  Widget _buildConfirmButton() {
    final canConfirm = _isFormComplete && !_isLoading;

    return _buildAnimatedSection(
      visible: _selectedSubclass != null && _calculatedStats != null,
      child: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: canConfirm ? _onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canConfirm ? RPGColors.darkPurple : RPGColors.darkGray,
                foregroundColor: RPGColors.gold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: canConfirm
                        ? RPGColors.gold.withOpacity(0.6)
                        : RPGColors.darkPurple.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                elevation: canConfirm ? 6 : 0,
                shadowColor: RPGColors.gold.withOpacity(0.3),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: RPGColors.gold,
                      ),
                    )
                  : Text(
                      'Forjar Destino',
                      style: GoogleFonts.cinzel(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: canConfirm
                            ? RPGColors.gold
                            : RPGColors.grayText,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  /// Wraps [child] in AnimatedOpacity + AnimatedSize for smooth reveal.
  Widget _buildAnimatedSection({
    required bool visible,
    required Widget child,
  }) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: visible ? child : const SizedBox.shrink(),
      ),
    );
  }

  /// Section title with consistent Cinzel gold styling.
  Widget _buildSectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: RPGColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.cinzel(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: RPGColors.gold,
          ),
        ),
      ],
    );
  }

  /// Returns an icon for the given class name.
  IconData _getClassIcon(String className) {
    switch (className.toLowerCase()) {
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
}
