import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maxima_rpg/config/theme.dart';
import 'package:maxima_rpg/config/routes.dart';
import 'package:maxima_rpg/services/auth_service.dart';
import 'package:maxima_rpg/services/socket_service.dart';

/// Settings screen with toggles for sound/notifications, server URL, and logout.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _notificationsEnabled = true;
  final TextEditingController _serverUrlController =
      TextEditingController(text: 'http://localhost:3000');

  @override
  void initState() {
    super.initState();
    // Load settings from player profile.
    final auth = context.read<AuthService>();
    final settings = auth.player?.settings ?? {};
    _soundEnabled = settings['soundEnabled'] as bool? ?? true;
    _notificationsEnabled = settings['notificationsEnabled'] as bool? ?? true;
    _serverUrlController.text =
        settings['serverUrl'] as String? ?? 'http://localhost:3000';
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RPGColors.darkGray,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: RPGColors.darkPurple),
        ),
        title: Text(
          '¿Abandonar la mazmorra?',
          style: RPGTextStyles.subheading,
        ),
        content: Text(
          'Tu progreso se guardara, pero seras desconectado del servidor.',
          style: RPGTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: RPGTextStyles.label,
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: RPGColors.darkRed,
            ),
            child: Text(
              'Salir',
              style: RPGTextStyles.button.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Disconnect socket and sign out.
      context.read<SocketService>().disconnect();
      await context.read<AuthService>().signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: RPGColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ajustes',
          style: RPGTextStyles.heading.copyWith(fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sound toggle.
          _buildSettingCard(
            icon: _soundEnabled ? Icons.volume_up : Icons.volume_off,
            title: 'Sonido',
            subtitle: _soundEnabled ? 'Activado' : 'Desactivado',
            trailing: Switch(
              value: _soundEnabled,
              activeColor: RPGColors.gold,
              activeTrackColor: RPGColors.darkPurple,
              inactiveTrackColor: RPGColors.darkGrayLight,
              onChanged: (value) {
                setState(() => _soundEnabled = value);
              },
            ),
          ),
          const SizedBox(height: 12),

          // Notifications toggle.
          _buildSettingCard(
            icon: _notificationsEnabled
                ? Icons.notifications_active
                : Icons.notifications_off,
            title: 'Notificaciones',
            subtitle:
                _notificationsEnabled ? 'Activadas' : 'Desactivadas',
            trailing: Switch(
              value: _notificationsEnabled,
              activeColor: RPGColors.gold,
              activeTrackColor: RPGColors.darkPurple,
              inactiveTrackColor: RPGColors.darkGrayLight,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
            ),
          ),
          const SizedBox(height: 12),

          // Server URL setting.
          _buildSettingCard(
            icon: Icons.dns,
            title: 'URL del Servidor',
            subtitle: _serverUrlController.text,
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: RPGColors.gold, size: 20),
              onPressed: _showServerUrlDialog,
            ),
          ),
          const SizedBox(height: 32),

          // Version info.
          Center(
            child: Text(
              'MAXIMA RPG v1.0.0',
              style: RPGTextStyles.systemMessage,
            ),
          ),
          const SizedBox(height: 32),

          // Logout button.
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: RPGColors.white),
              label: Text(
                'Cerrar Sesion',
                style: RPGTextStyles.button,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: RPGColors.darkRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: RPGColors.gold, width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: RPGColors.darkGray,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: RPGColors.darkPurple.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: RPGColors.gold, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: RPGTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 2),
                Text(subtitle, style: RPGTextStyles.systemMessage),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  void _showServerUrlDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RPGColors.darkGray,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: RPGColors.darkPurple),
        ),
        title: Text(
          'URL del Servidor',
          style: RPGTextStyles.subheading,
        ),
        content: TextField(
          controller: _serverUrlController,
          style: RPGTextStyles.playerChat,
          decoration: const InputDecoration(
            hintText: 'http://localhost:3000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: RPGTextStyles.label),
          ),
          ElevatedButton(
            onPressed: () {
              // Update the socket service URL.
              context
                  .read<SocketService>()
                  .setServerUrl(_serverUrlController.text.trim());
              setState(() {});
              Navigator.pop(context);
            },
            child: Text(
              'Guardar',
              style: RPGTextStyles.button.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
