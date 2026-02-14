import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maxima_rpg/config/theme.dart';
import 'package:maxima_rpg/config/routes.dart';
import 'package:maxima_rpg/services/auth_service.dart';
import 'package:maxima_rpg/services/firebase_service.dart';

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
      // Navigate to character creation screen for full character setup.
      final user = authService.user;
      if (user != null && mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.characterCreation,
          arguments: {'userId': user.uid},
        );
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
                                  'Crear Cuenta',
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

}
