import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maxima_rpg/config/theme.dart';
import 'package:maxima_rpg/models/dungeon.dart';
import 'package:maxima_rpg/models/character.dart';
import 'package:maxima_rpg/services/socket_service.dart';
import 'package:maxima_rpg/widgets/chat_widget.dart';
import 'package:maxima_rpg/widgets/sprite_widget.dart';
import 'package:maxima_rpg/widgets/stats_bar.dart';

/// Main game screen with split view: pixel art area (top) and chat area (bottom).
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TextEditingController _commandController = TextEditingController();
  final List<ChatMessage> _chatMessages = [];
  final ScrollController _chatScrollController = ScrollController();

  late SocketService _socketService;
  StreamSubscription<SocketMessage>? _messageSubscription;

  // Character state.
  Character _character = Character(
    characterId: 'temp',
    playerId: 'temp',
    name: 'Aventurero',
    characterClass: 'Guerrero',
    level: 1,
    hp: 100,
    maxHp: 100,
    xp: 0,
    attack: 10,
    defense: 5,
  );

  // Sprite state.
  SpriteState _currentSpriteState = SpriteState.idle;

  // Path choices (shown as buttons when the master offers paths).
  List<Map<String, String>> _pathChoices = [];

  Dungeon? _dungeon;

  @override
  void initState() {
    super.initState();
    _socketService = context.read<SocketService>();

    // Listen to socket messages for game events.
    _messageSubscription = _socketService.messageStream.listen(_handleMessage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get dungeon from route arguments.
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Dungeon && _dungeon == null) {
      _dungeon = args;
      _socketService.joinRoom(_dungeon!.dungeonId);
      _addSystemMessage(
        'Has entrado a: ${_dungeon!.name}',
      );
      _addMasterMessage(
        'Bienvenido a ${_dungeon!.name}. '
        'Las sombras se ciernen a tu alrededor. '
        '¿Que haras, aventurero?',
      );
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _commandController.dispose();
    _chatScrollController.dispose();
    _socketService.leaveRoom();
    super.dispose();
  }

  /// Handles incoming socket messages and updates the UI accordingly.
  void _handleMessage(SocketMessage msg) {
    setState(() {
      switch (msg.type) {
        case SocketMessageType.masterNarration:
          _addMasterMessage(msg.data['text'] ?? '');
          break;

        case SocketMessageType.combatResult:
          _addCombatMessage(msg.data['text'] ?? '');
          // Trigger attack animation.
          _setSpriteState(SpriteState.attack);
          // Update HP if provided.
          if (msg.data['hp'] != null) {
            _character = _character.copyWith(hp: msg.data['hp'] as int);
          }
          if (msg.data['xp'] != null) {
            _character = _character.copyWith(xp: msg.data['xp'] as int);
          }
          break;

        case SocketMessageType.chatMessage:
          _chatMessages.add(ChatMessage(
            type: ChatMessageType.player,
            sender: msg.data['sender'] ?? 'Jugador',
            text: msg.data['message'] ?? msg.data['text'] ?? '',
            timestamp: msg.timestamp,
          ));
          break;

        case SocketMessageType.playerUpdate:
          // Update character stats from server.
          if (msg.data['hp'] != null) {
            _character = _character.copyWith(hp: msg.data['hp'] as int);
          }
          if (msg.data['maxHp'] != null) {
            _character = _character.copyWith(maxHp: msg.data['maxHp'] as int);
          }
          if (msg.data['xp'] != null) {
            _character = _character.copyWith(xp: msg.data['xp'] as int);
          }
          if (msg.data['level'] != null) {
            _character = _character.copyWith(level: msg.data['level'] as int);
          }
          if (msg.data['attack'] != null) {
            _character =
                _character.copyWith(attack: msg.data['attack'] as int);
          }
          if (msg.data['defense'] != null) {
            _character =
                _character.copyWith(defense: msg.data['defense'] as int);
          }
          break;

        case SocketMessageType.dungeonProgress:
          _addSystemMessage(msg.data['text'] ?? 'Progreso en la mazmorra.');
          break;

        case SocketMessageType.pathChoice:
          // Show path choice buttons.
          final choices = msg.data['choices'] as List<dynamic>?;
          if (choices != null) {
            _pathChoices = choices
                .map((c) => {
                      'id': (c['id'] ?? '').toString(),
                      'label': (c['label'] ?? '').toString(),
                    })
                .toList();
          }
          _addMasterMessage(msg.data['text'] ?? 'Elige tu camino...');
          break;

        case SocketMessageType.systemMessage:
          _addSystemMessage(msg.data['text'] ?? '');
          break;

        case SocketMessageType.error:
          _addSystemMessage('[Error] ${msg.data['text'] ?? ''}');
          break;

        default:
          break;
      }
    });
    _scrollChatToBottom();
  }

  void _addMasterMessage(String text) {
    _chatMessages.add(ChatMessage(
      type: ChatMessageType.master,
      sender: 'Maestro',
      text: text,
      timestamp: DateTime.now(),
    ));
  }

  void _addSystemMessage(String text) {
    _chatMessages.add(ChatMessage(
      type: ChatMessageType.system,
      sender: 'Sistema',
      text: text,
      timestamp: DateTime.now(),
    ));
  }

  void _addCombatMessage(String text) {
    _chatMessages.add(ChatMessage(
      type: ChatMessageType.combat,
      sender: 'Combate',
      text: text,
      timestamp: DateTime.now(),
    ));
  }

  void _setSpriteState(SpriteState state) {
    setState(() {
      _currentSpriteState = state;
    });
    // Reset to idle after animation duration.
    final duration = state == SpriteState.attack
        ? const Duration(milliseconds: 600)
        : const Duration(milliseconds: 800);
    Future.delayed(duration, () {
      if (mounted) {
        setState(() {
          _currentSpriteState = SpriteState.idle;
        });
      }
    });
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendCommand() {
    final text = _commandController.text.trim();
    if (text.isEmpty) return;

    // Add the command as a player message locally.
    setState(() {
      _chatMessages.add(ChatMessage(
        type: ChatMessageType.player,
        sender: 'Tu',
        text: text,
        timestamp: DateTime.now(),
      ));
    });

    // Send to server.
    if (text.startsWith('/')) {
      _socketService.sendCommand(text);
    } else {
      _socketService.sendChatMessage(text);
    }

    _commandController.clear();
    _scrollChatToBottom();
  }

  void _selectPath(String pathId) {
    _socketService.selectPath(pathId);
    setState(() {
      _pathChoices = [];
      _setSpriteState(SpriteState.walkRight);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Stats bar at the top.
            StatsBar(
              hp: _character.hp,
              maxHp: _character.maxHp,
              xp: _character.xp,
              xpToNextLevel: _character.xpToNextLevel,
              level: _character.level,
              coins: 0,
              onBackPressed: () {
                _socketService.leaveRoom();
                Navigator.pop(context);
              },
            ),

            // Top half: Pixel art / sprite area.
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: RPGColors.darkGray,
                  border: Border(
                    bottom: BorderSide(
                      color: RPGColors.darkPurple.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    // Dungeon background gradient.
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.0,
                          colors: [
                            RPGColors.darkGrayLight,
                            RPGColors.black,
                          ],
                        ),
                      ),
                    ),

                    // Dungeon name overlay.
                    if (_dungeon != null)
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: Text(
                          _dungeon!.name,
                          style: RPGTextStyles.systemMessage.copyWith(
                            color: RPGColors.grayText.withOpacity(0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Sprite in the center.
                    Center(
                      child: SpriteWidget(
                        state: _currentSpriteState,
                        characterClass: _character.characterClass,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom half: Chat area.
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Path choice buttons (shown when the master offers paths).
                  if (_pathChoices.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      color: RPGColors.darkGray,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: _pathChoices.map((choice) {
                          return ElevatedButton(
                            onPressed: () =>
                                _selectPath(choice['id'] ?? ''),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: RPGColors.darkPurple,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            child: Text(
                              choice['label'] ?? '',
                              style: RPGTextStyles.button.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Chat messages.
                  Expanded(
                    child: ChatWidget(
                      messages: _chatMessages,
                      scrollController: _chatScrollController,
                    ),
                  ),

                  // Command input.
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: RPGColors.darkGray,
                    child: Row(
                      children: [
                        // Slash prefix indicator.
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                          decoration: BoxDecoration(
                            color: RPGColors.darkPurple.withOpacity(0.3),
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(24),
                            ),
                          ),
                          child: Text(
                            '/',
                            style: RPGTextStyles.playerChat.copyWith(
                              color: RPGColors.gold,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _commandController,
                            style: RPGTextStyles.playerChat,
                            decoration: InputDecoration(
                              hintText: 'atacar, inspeccionar, usar...',
                              hintStyle: TextStyle(
                                color: RPGColors.grayText.withOpacity(0.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: RPGColors.darkGrayLight,
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.horizontal(
                                  right: Radius.circular(24),
                                ),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.horizontal(
                                  right: Radius.circular(24),
                                ),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(24),
                                ),
                                borderSide: BorderSide(
                                  color: RPGColors.gold.withOpacity(0.5),
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _sendCommand(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _sendCommand,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: RPGColors.darkPurple,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send,
                              color: RPGColors.gold,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
