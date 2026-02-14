import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maxima_rpg/config/theme.dart';
import 'package:maxima_rpg/config/routes.dart';
import 'package:maxima_rpg/services/auth_service.dart';

/// Dark dungeon-themed login screen with animated opacity overlay.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Animated opacity for the dark overlay.
  late AnimationController _overlayAnimController;
  late Animation<double> _overlayOpacity;

  @override
  void initState() {
    super.initState();
    _overlayAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _overlayOpacity = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(
        parent: _overlayAnimController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _overlayAnimController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    final success = await authService.signIn(
      _emailController.text,
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.lobby);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dark background base.
          Container(color: RPGColors.black),

          // Animated dark overlay simulating dungeon ambiance.
          AnimatedBuilder(
            animation: _overlayOpacity,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      RPGColors.darkPurple.withOpacity(_overlayOpacity.value * 0.3),
                      RPGColors.black.withOpacity(_overlayOpacity.value),
                    ],
                  ),
                ),
              );
            },
          ),

          // Main content.
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // Logo placeholder.
                      _buildLogo(),
                      const SizedBox(height: 12),

                      // Title.
                      Text(
                        'MAXIMA',
                        style: RPGTextStyles.heading.copyWith(
                          fontSize: 36,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RPG de Mazmorra Multijugador',
                        style: RPGTextStyles.systemMessage.copyWith(
                          color: RPGColors.grayText,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Email field.
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: RPGTextStyles.playerChat,
                        decoration: const InputDecoration(
                          labelText: 'Correo del Aventurero',
                          prefixIcon: Icon(Icons.email_outlined,
                              color: RPGColors.gold),
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
                      const SizedBox(height: 20),

                      // Password field.
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: RPGTextStyles.playerChat,
                        decoration: InputDecoration(
                          labelText: 'Contrasena Secreta',
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: RPGColors.gold),
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
                            return 'Ingresa tu contrasena';
                          }
                          if (value.length < 6) {
                            return 'Minimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
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

                      // Login button.
                      Consumer<AuthService>(
                        builder: (context, auth, _) {
                          return SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _handleLogin,
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
                                      'Iniciar Sesion',
                                      style: RPGTextStyles.button,
                                    ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Register link.
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.register);
                        },
                        child: Text(
                          '¿Nuevo aqui? Unete a la mazmorra',
                          style: RPGTextStyles.label.copyWith(
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            decorationColor: RPGColors.gold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a placeholder logo container.
  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: RPGColors.gold, width: 2),
        color: RPGColors.darkGray,
        boxShadow: [
          BoxShadow(
            color: RPGColors.darkPurple.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.shield_outlined,
          size: 48,
          color: RPGColors.gold,
        ),
      ),
    );
  }
}

/// A builder widget that rebuilds when the given [animation] changes value.
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder2(
      animation: animation,
      builder: builder,
    );
  }
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder2({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}
