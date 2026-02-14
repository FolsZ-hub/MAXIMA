import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maxima_rpg/config/theme.dart';
import 'package:maxima_rpg/config/routes.dart';
import 'package:maxima_rpg/services/socket_service.dart';
import 'package:maxima_rpg/services/auth_service.dart';

/// Lobby screen – "Taberna del Aventurero".
/// Shows global chat, online players, and the dungeon entrance button.
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  int _onlinePlayers = 1;

  late SocketService _socketService;
  StreamSubscription<SocketMessage>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _socketService = context.read<SocketService>();

    // Connect to the server.
    final auth = context.read<AuthService>();
    _socketService.connect(
      userId: auth.user?.uid,
      username: auth.player?.username,
    );

    // Listen for incoming messages.
    _messageSubscription = _socketService.messageStream.listen((msg) {
      setState(() {
        _messages.add({
          'type': msg.type.name,
          'text': msg.data['text'] ?? msg.data['message'] ?? '',
          'sender': msg.data['sender'] ?? 'Sistema',
          'timestamp': msg.timestamp,
        });
      });
      _scrollToBottom();
    });

    // Add welcome message.
    _messages.add({
      'type': 'systemMessage',
      'text': 'Bienvenido a la Taberna del Aventurero. '
          'Aqui puedes hablar con otros aventureros antes de entrar a una mazmorra.',
      'sender': 'Sistema',
      'timestamp': DateTime.now(),
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    _socketService.sendChatMessage(text);

    // Optimistic local display.
    final auth = context.read<AuthService>();
    setState(() {
      _messages.add({
        'type': 'chatMessage',
        'text': text,
        'sender': auth.player?.username ?? 'Tu',
        'timestamp': DateTime.now(),
        'isLocal': true,
      });
    });
    _chatController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Taberna del Aventurero',
          style: RPGTextStyles.heading.copyWith(fontSize: 18),
        ),
        automaticallyImplyLeading: false,
        actions: [
          // Online players indicator.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$_onlinePlayers',
                  style: RPGTextStyles.systemMessage.copyWith(
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ),
          // Profile button.
          IconButton(
            icon: const Icon(Icons.person, color: RPGColors.gold),
            tooltip: 'Perfil',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
          // Settings button.
          IconButton(
            icon: const Icon(Icons.settings, color: RPGColors.gold),
            tooltip: 'Ajustes',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages list.
          Expanded(
            child: Container(
              color: RPGColors.black,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageTile(_messages[index]);
                },
              ),
            ),
          ),

          // Dungeon entrance button.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: RPGColors.darkGray,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.dungeonSelect);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: RPGColors.darkRed,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: RPGColors.gold, width: 1),
                ),
              ),
              child: Text(
                '¡Entrar a una Mazmorra!',
                style: RPGTextStyles.button.copyWith(fontSize: 18),
              ),
            ),
          ),

          // Chat input field.
          Container(
            padding: const EdgeInsets.all(12),
            color: RPGColors.darkGray,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: RPGTextStyles.playerChat,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: TextStyle(
                          color: RPGColors.grayText.withOpacity(0.5)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: RPGColors.darkPurple),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: RPGColors.darkPurple),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            const BorderSide(color: RPGColors.gold, width: 2),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: RPGColors.gold),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single chat message tile with style based on message type.
  Widget _buildMessageTile(Map<String, dynamic> message) {
    final type = message['type'] as String;
    final text = message['text'] as String;
    final sender = message['sender'] as String;

    TextStyle messageStyle;
    String prefix = '';

    switch (type) {
      case 'masterNarration':
        messageStyle = RPGTextStyles.masterNarration;
        prefix = '[Maestro] ';
        break;
      case 'systemMessage':
        messageStyle = RPGTextStyles.systemMessage;
        prefix = '[Sistema] ';
        break;
      case 'combatResult':
        messageStyle = RPGTextStyles.combatMessage;
        prefix = '[Combate] ';
        break;
      case 'chatMessage':
      default:
        messageStyle = RPGTextStyles.playerChat;
        prefix = '[$sender] ';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: prefix,
              style: messageStyle.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: text,
              style: messageStyle,
            ),
          ],
        ),
      ),
    );
  }
}
