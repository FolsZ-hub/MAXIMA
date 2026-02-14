import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Message types received through socket events.
enum SocketMessageType {
  masterNarration,
  systemMessage,
  chatMessage,
  combatResult,
  huntResult,
  itemResult,
  playerUpdate,
  roomUpdate,
  dungeonEntered,
  dungeonRoom,
  dungeonList,
  commandResult,
  legacyResult,
  rateLimited,
  error,
}

/// A socket message with its type and payload.
class SocketMessage {
  final SocketMessageType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  SocketMessage({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Singleton service that manages WebSocket communication with the game server.
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  String _serverUrl = 'http://localhost:3000';
  String? _currentRoomId;

  // Stream controllers for reactive UI updates.
  final StreamController<SocketMessage> _messageController =
      StreamController<SocketMessage>.broadcast();
  final StreamController<Map<String, dynamic>> _combatResultController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _huntResultController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _itemResultController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _chatMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _commandResultController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _roomUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _dungeonController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _playerUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _legacyController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _rateLimitedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  // Public streams for widgets to listen to.
  Stream<SocketMessage> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get combatResultStream =>
      _combatResultController.stream;
  Stream<Map<String, dynamic>> get huntResultStream =>
      _huntResultController.stream;
  Stream<Map<String, dynamic>> get itemResultStream =>
      _itemResultController.stream;
  Stream<Map<String, dynamic>> get chatMessageStream =>
      _chatMessageController.stream;
  Stream<Map<String, dynamic>> get commandResultStream =>
      _commandResultController.stream;
  Stream<Map<String, dynamic>> get roomUpdateStream =>
      _roomUpdateController.stream;
  Stream<Map<String, dynamic>> get dungeonStream =>
      _dungeonController.stream;
  Stream<Map<String, dynamic>> get playerUpdateStream =>
      _playerUpdateController.stream;
  Stream<Map<String, dynamic>> get legacyStream =>
      _legacyController.stream;
  Stream<Map<String, dynamic>> get rateLimitedStream =>
      _rateLimitedController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _socket?.connected ?? false;
  String? get currentRoomId => _currentRoomId;

  /// Updates the server URL before connecting.
  void setServerUrl(String url) {
    _serverUrl = url;
  }

  /// Connects to the game server and registers all event listeners.
  void connect({String? userId, String? username}) {
    _socket?.disconnect();

    _socket = io.io(
      _serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setQuery({
            if (userId != null) 'userId': userId,
            if (username != null) 'username': username,
          })
          .build(),
    );

    _registerListeners();
    _socket!.connect();
  }

  /// Disconnects from the server and cleans up resources.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentRoomId = null;
    _connectionController.add(false);
  }

  /// Registers all socket event listeners.
  void _registerListeners() {
    final socket = _socket;
    if (socket == null) return;

    // ── Connection lifecycle ──────────────────────────────────────────

    socket.onConnect((_) {
      _connectionController.add(true);
      _addMessage(SocketMessageType.systemMessage, {
        'text': 'Conectado al servidor de MAXIMA.',
      });
    });

    socket.onDisconnect((_) {
      _connectionController.add(false);
      _addMessage(SocketMessageType.systemMessage, {
        'text': 'Desconectado del servidor.',
      });
    });

    socket.onConnectError((error) {
      _connectionController.add(false);
      _addMessage(SocketMessageType.error, {
        'text': 'Error de conexion: $error',
      });
    });

    // ── Combat events ────────────────────────────────────────────────

    socket.on('combatResult', (data) {
      final payload = _toMap(data);
      _combatResultController.add(payload);
      _addMessage(SocketMessageType.combatResult, payload);
    });

    socket.on('combatError', (data) {
      final payload = _toMap(data);
      _addMessage(SocketMessageType.error, payload);
    });

    // ── Hunt events ──────────────────────────────────────────────────

    socket.on('huntResult', (data) {
      final payload = _toMap(data);
      _huntResultController.add(payload);
      _addMessage(SocketMessageType.huntResult, payload);
    });

    // ── Item events ──────────────────────────────────────────────────

    socket.on('itemResult', (data) {
      final payload = _toMap(data);
      _itemResultController.add(payload);
      _addMessage(SocketMessageType.itemResult, payload);
    });

    socket.on('itemError', (data) {
      final payload = _toMap(data);
      _addMessage(SocketMessageType.error, payload);
    });

    // ── Chat events ──────────────────────────────────────────────────

    socket.on('chat:message', (data) {
      final payload = _toMap(data);
      _chatMessageController.add(payload);
      _addMessage(SocketMessageType.chatMessage, payload);
    });

    socket.on('chat:commandResult', (data) {
      final payload = _toMap(data);
      _commandResultController.add(payload);
      _addMessage(SocketMessageType.commandResult, payload);
    });

    socket.on('chat:error', (data) {
      final payload = _toMap(data);
      _addMessage(SocketMessageType.error, payload);
    });

    // ── Dungeon events ───────────────────────────────────────────────

    socket.on('dungeon:entered', (data) {
      final payload = _toMap(data);
      _dungeonController.add(payload);
      _addMessage(SocketMessageType.dungeonEntered, payload);
    });

    socket.on('dungeon:roomEntered', (data) {
      final payload = _toMap(data);
      _dungeonController.add(payload);
      _addMessage(SocketMessageType.dungeonRoom, payload);
    });

    socket.on('dungeon:generated', (data) {
      final payload = _toMap(data);
      _dungeonController.add(payload);
      _addMessage(SocketMessageType.dungeonEntered, payload);
    });

    socket.on('dungeon:listResult', (data) {
      final payload = _toMap(data);
      _dungeonController.add(payload);
      _addMessage(SocketMessageType.dungeonList, payload);
    });

    socket.on('dungeon:error', (data) {
      final payload = _toMap(data);
      _addMessage(SocketMessageType.error, payload);
    });

    socket.on('dungeon:moveRequested', (data) {
      final payload = _toMap(data);
      _dungeonController.add(payload);
      _addMessage(SocketMessageType.dungeonRoom, payload);
    });

    // ── Legacy events ────────────────────────────────────────────────

    socket.on('legacy:returningResult', (data) {
      final payload = _toMap(data);
      _legacyController.add(payload);
      _addMessage(SocketMessageType.legacyResult, payload);
    });

    socket.on('legacy:bonusInfo', (data) {
      final payload = _toMap(data);
      _legacyController.add(payload);
      _addMessage(SocketMessageType.legacyResult, payload);
    });

    socket.on('legacy:deathResult', (data) {
      final payload = _toMap(data);
      _legacyController.add(payload);
      _addMessage(SocketMessageType.legacyResult, payload);
    });

    socket.on('legacy:returned', (data) {
      final payload = _toMap(data);
      _legacyController.add(payload);
      _addMessage(SocketMessageType.legacyResult, payload);
    });

    socket.on('legacy:characterDied', (data) {
      final payload = _toMap(data);
      _legacyController.add(payload);
      _addMessage(SocketMessageType.legacyResult, payload);
    });

    socket.on('legacy:error', (data) {
      final payload = _toMap(data);
      _addMessage(SocketMessageType.error, payload);
    });

    // ── Room events ──────────────────────────────────────────────────

    socket.on('room:created', (data) {
      final payload = _toMap(data);
      _roomUpdateController.add(payload);
      _addMessage(SocketMessageType.roomUpdate, payload);
    });

    socket.on('room:playerJoined', (data) {
      final payload = _toMap(data);
      _roomUpdateController.add(payload);
      _addMessage(SocketMessageType.roomUpdate, payload);
    });

    socket.on('room:playerLeft', (data) {
      final payload = _toMap(data);
      _roomUpdateController.add(payload);
      _addMessage(SocketMessageType.roomUpdate, payload);
    });

    socket.on('room:state', (data) {
      final payload = _toMap(data);
      _roomUpdateController.add(payload);
      _addMessage(SocketMessageType.roomUpdate, payload);
    });

    socket.on('room:error', (data) {
      final payload = _toMap(data);
      _addMessage(SocketMessageType.error, payload);
    });

    // ── Player events ────────────────────────────────────────────────

    socket.on('player:joined', (data) {
      final payload = _toMap(data);
      _playerUpdateController.add(payload);
      _addMessage(SocketMessageType.playerUpdate, payload);
    });

    socket.on('player:left', (data) {
      final payload = _toMap(data);
      _playerUpdateController.add(payload);
      _addMessage(SocketMessageType.playerUpdate, payload);
    });

    // ── Rate limiting ────────────────────────────────────────────────

    socket.on('rateLimited', (data) {
      final payload = _toMap(data);
      _rateLimitedController.add(payload);
      _addMessage(SocketMessageType.rateLimited, payload);
    });
  }

  // ── Helper ───────────────────────────────────────────────────────────

  /// Safely converts incoming socket data to a Map.
  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'text': data.toString()};
  }

  /// Adds a message to the general message stream.
  void _addMessage(SocketMessageType type, Map<String, dynamic> data) {
    _messageController.add(SocketMessage(type: type, data: data));
  }

  // ── Emit: Player ─────────────────────────────────────────────────────

  /// Announces the player to the server.
  void joinPlayer(String uid, String username) {
    _socket?.emit('player:join', {
      'uid': uid,
      'username': username,
    });
  }

  // ── Emit: Chat ───────────────────────────────────────────────────────

  /// Sends a game command to the server (e.g., /attack, /use, /inspect).
  void sendCommand(String command) {
    _socket?.emit('chat:message', {
      'message': command,
    });
  }

  /// Sends a chat message with full context to the current room.
  void sendChatMessage(
    String message, {
    Map<String, dynamic>? playerData,
    Map<String, dynamic>? characterData,
    Map<String, dynamic>? targetData,
    Map<String, dynamic>? dungeonState,
    String? difficulty,
  }) {
    _socket?.emit('chat:message', {
      'message': message,
      if (playerData != null) 'playerData': playerData,
      if (characterData != null) 'characterData': characterData,
      if (targetData != null) 'targetData': targetData,
      if (dungeonState != null) 'dungeonState': dungeonState,
      if (difficulty != null) 'difficulty': difficulty,
      if (_currentRoomId != null) 'roomId': _currentRoomId,
    });
  }

  // ── Emit: Combat ─────────────────────────────────────────────────────

  /// Sends an attack intent to the server.
  void sendAttack(
    Map<String, dynamic> characterData,
    Map<String, dynamic> targetData, {
    String? attackerId,
    String? targetId,
    String? roomId,
    String? difficulty,
  }) {
    _socket?.emit('intentAttack', {
      'characterData': characterData,
      'targetData': targetData,
      if (attackerId != null) 'attackerId': attackerId,
      if (targetId != null) 'targetId': targetId,
      if (roomId != null) 'roomId': roomId,
      if (difficulty != null) 'difficulty': difficulty,
    });
  }

  /// Sends a hunt intent to the server.
  void sendHunt(Map<String, dynamic> characterData, String difficulty) {
    _socket?.emit('intentHunt', {
      'characterData': characterData,
      'difficulty': difficulty,
    });
  }

  /// Sends an item-use intent to the server.
  void sendUseItem(
    Map<String, dynamic> characterData,
    String itemName,
    List<dynamic> inventory, {
    String? characterId,
  }) {
    _socket?.emit('intentUseItem', {
      'characterData': characterData,
      'itemName': itemName,
      'inventory': inventory,
      if (characterId != null) 'characterId': characterId,
    });
  }

  // ── Emit: Dungeon ────────────────────────────────────────────────────

  /// Enters a dungeon by ID or difficulty.
  void enterDungeon({String? dungeonId, String? difficulty}) {
    _socket?.emit('dungeon:enter', {
      if (dungeonId != null) 'dungeonId': dungeonId,
      if (difficulty != null) 'difficulty': difficulty,
    });
  }

  /// Moves to a path inside a dungeon.
  void moveDungeon(Map<String, dynamic> dungeon, int pathIndex) {
    _socket?.emit('dungeon:move', {
      'dungeon': dungeon,
      'pathIndex': pathIndex,
    });
  }

  /// Requests the list of available dungeons.
  void listDungeons() {
    _socket?.emit('dungeon:list', {});
  }

  /// Generates a new procedural dungeon.
  void generateDungeon(String difficulty) {
    _socket?.emit('dungeon:generate', {
      'difficulty': difficulty,
    });
  }

  /// Selects a path choice during dungeon exploration (alias for moveDungeon).
  void selectPath(Map<String, dynamic> dungeon, int pathIndex) {
    moveDungeon(dungeon, pathIndex);
  }

  // ── Emit: Legacy ─────────────────────────────────────────────────────

  /// Sends a returning/revival request.
  void sendReturning(
    Map<String, dynamic> playerData,
    Map<String, dynamic> characterData, {
    String? roomId,
    String? playerId,
  }) {
    _socket?.emit('legacy:returning', {
      'playerData': playerData,
      'characterData': characterData,
      if (roomId != null) 'roomId': roomId,
      if (playerId != null) 'playerId': playerId,
    });
  }

  /// Requests legacy bonus information for a character.
  void getLegacyBonus(Map<String, dynamic> characterData) {
    _socket?.emit('legacy:getBonus', {
      'characterData': characterData,
    });
  }

  /// Reports a character death.
  void sendDeath(
    Map<String, dynamic> characterData, {
    String? roomId,
    String? playerId,
  }) {
    _socket?.emit('legacy:death', {
      'characterData': characterData,
      if (roomId != null) 'roomId': roomId,
      if (playerId != null) 'playerId': playerId,
    });
  }

  // ── Emit: Room ───────────────────────────────────────────────────────

  /// Joins a game room by its ID.
  void joinRoom(String roomId, {Map<String, dynamic>? playerData}) {
    _currentRoomId = roomId;
    _socket?.emit('room:join', {
      'roomId': roomId,
      if (playerData != null) 'playerData': playerData,
    });
  }

  /// Leaves the current game room.
  void leaveRoom() {
    if (_currentRoomId != null) {
      _socket?.emit('room:leave', {'roomId': _currentRoomId});
      _currentRoomId = null;
    }
  }

  // ── Lifecycle ────────────────────────────────────────────────────────

  /// Disposes all stream controllers. Call on app shutdown.
  void dispose() {
    disconnect();
    _messageController.close();
    _combatResultController.close();
    _huntResultController.close();
    _itemResultController.close();
    _chatMessageController.close();
    _commandResultController.close();
    _roomUpdateController.close();
    _dungeonController.close();
    _playerUpdateController.close();
    _legacyController.close();
    _rateLimitedController.close();
    _connectionController.close();
  }
}
