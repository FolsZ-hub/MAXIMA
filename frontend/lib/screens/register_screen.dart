import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maxima_rpg/config/theme.dart';
import 'package:maxima_rpg/config/routes.dart';
import 'package:maxima_rpg/services/auth_service.dart';
import 'package:maxima_rpg/services/firebase_service.dart';
import 'package:maxima_rpg/models/character.dart';

/// Registration screen themed to match the dungeon aesthetic.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _characterNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Character class selection.
  String _selectedClass = 'Guerrero';
  final List<Map<String, dynamic>> _classes = [
    {
      'name': 'Guerrero',
      'icon': Icons.shield,
      'description': 'Fuerte en combate cuerpo a cuerpo',
    },
    {
      'name': 'Mago',
      'icon': Icons.auto_fix_high,
      'description': 'Domina las artes arcanas',
    },
    {
      'name': 'Ladronzuelo',
      'icon': Icons.visibility,
      'description': 'Sigiloso y letal en las sombras',
    },
    {
      'name': 'Clerigo',
      'icon': Icons.favorite,
      'description': 'Sanador y protector del grupo',
    },
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _characterNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    final firebaseService = context.read<FirebaseService>();

    final success = await authService.register(
      _emailController.text,
      _passwordController.text,
      _usernameController.text,
    );

    if (success && mounted) {
      // Create the initial character for the player.
      final user = authService.user;
      if (user != null) {
        final character = Character(
          characterId: '${user.uid}_char_1',
          playerId: user.uid,
          name: _characterNameController.text.trim(),
          characterClass: _selectedClass,
        );
        await firebaseService.createCharacter(character);
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.lobby);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              RPGColors.darkPurple.withOpacity(0.2),
              RPGColors.black,
              RPGColors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  // Back button.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: RPGColors.gold),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Title.
                  Text(
                    'Unirse a la Mazmorra',
                    style: RPGTextStyles.heading,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Master quote.
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: RPGColors.darkGray,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: RPGColors.gold.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      '"¡Ah, un nuevo alma perdida en busca de gloria! '
                      'Dime tu nombre, aventurero, y elige tu destino..."',
                      style: RPGTextStyles.masterNarration.copyWith(
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Username field.
                  TextFormField(
                    controller: _usernameController,
                    style: RPGTextStyles.playerChat,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de Usuario',
                      prefixIcon:
                          Icon(Icons.person_outline, color: RPGColors.gold),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa un nombre de usuario';
                      }
                      if (value.trim().length < 3) {
                        return 'Minimo 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Character name field.
                  TextFormField(
                    controller: _characterNameController,
                    style: RPGTextStyles.playerChat,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Personaje',
                      prefixIcon: Icon(Icons.badge_outlined,
                          color: RPGColors.gold),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Tu personaje necesita un nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email field.
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: RPGTextStyles.playerChat,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electronico',
                      prefixIcon:
                          Icon(Icons.email_outlined, color: RPGColors.gold),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa tu correo';
                      }
                      if (!value.contains('@')) {
                        return 'Correo no valido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field.
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: RPGTextStyles.playerChat,
                    decoration: InputDecoration(
                      labelText: 'Contrasena',
                      prefixIcon:
                          const Icon(Icons.lock_outline, color: RPGColors.gold),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: RPGColors.grayText,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa una contrasena';
                      }
                      if (value.length < 6) {
                        return 'Minimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Class selection.
                  Text(
                    'Elige tu Clase',
                    style: RPGTextStyles.subheading,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  _buildClassSelector(),
                  const SizedBox(height: 12),

                  // Error message display.
                  Consumer<AuthService>(
                    builder: (context, auth, _) {
                      if (auth.errorMessage != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            auth.errorMessage!,
                            style: RPGTextStyles.systemMessage.copyWith(
                              color: RPGColors.darkRed,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(height: 16),

                  // Register button.
                  Consumer<AuthService>(
                    builder: (context, auth, _) {
                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              auth.isLoading ? null : _handleRegister,
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: RPGColors.gold,
                                  ),
                                )
                              : Text(
                                  'Comenzar Aventura',
                                  style: RPGTextStyles.button,
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the character class selector as a grid of tappable cards.
  Widget _buildClassSelector() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        final classData = _classes[index];
        final isSelected = _selectedClass == classData['name'];

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedClass = classData['name'] as String;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? RPGColors.darkPurple.withOpacity(0.4)
                  : RPGColors.darkGrayLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? RPGColors.gold : RPGColors.darkPurple,
                width: isSelected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  classData['icon'] as IconData,
                  color: isSelected ? RPGColors.gold : RPGColors.grayText,
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  classData['name'] as String,
                  style: GoogleFonts.cinzel(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? RPGColors.gold : RPGColors.white,
                  ),
                ),
                Text(
                  classData['description'] as String,
                  style: RPGTextStyles.systemMessage.copyWith(fontSize: 9),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
