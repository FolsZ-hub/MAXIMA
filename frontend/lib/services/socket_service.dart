import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Message types received through socket events.
enum SocketMessageType {
  masterNarration,
  systemMessage,
  chatMessage,
  combatResult,
  playerUpdate,
  roomUpdate,
  dungeonProgress,
  pathChoice,
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
  final StreamController<Map<String, dynamic>> _attackResultController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _chatMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _roomUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _dungeonProgressController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _playerUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  // Public streams for widgets to listen to.
  Stream<SocketMessage> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get attackResultStream =>
      _attackResultController.stream;
  Stream<Map<String, dynamic>> get chatMessageStream =>
      _chatMessageController.stream;
  Stream<Map<String, dynamic>> get roomUpdateStream =>
      _roomUpdateController.stream;
  Stream<Map<String, dynamic>> get dungeonProgressStream =>
      _dungeonProgressController.stream;
  Stream<Map<String, dynamic>> get playerUpdateStream =>
      _playerUpdateController.stream;
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

    // Game event listeners
    socket.on('attackResult', (data) {
      final payload = Map<String, dynamic>.from(data as Map);
      _attackResultController.add(payload);
      _addMessage(SocketMessageType.combatResult, payload);
    });

    socket.on('chatMessage', (data) {
      final payload = Map<String, dynamic>.from(data as Map);
      _chatMessageController.add(payload);
      _addMessage(SocketMessageType.chatMessage, payload);
    });

    socket.on('roomUpdate', (data) {
      final payload = Map<String, dynamic>.from(data as Map);
      _roomUpdateController.add(payload);
      _addMessage(SocketMessageType.roomUpdate, payload);
    });

    socket.on('dungeonProgress', (data) {
      final payload = Map<String, dynamic>.from(data as Map);
      _dungeonProgressController.add(payload);
      _addMessage(SocketMessageType.dungeonProgress, payload);
    });

    socket.on('playerUpdate', (data) {
      final payload = Map<String, dynamic>.from(data as Map);
      _playerUpdateController.add(payload);
      _addMessage(SocketMessageType.playerUpdate, payload);
    });

    socket.on('masterNarration', (data) {
      final payload = Map<String, dynamic>.from(data as Map);
      _addMessage(SocketMessageType.masterNarration, payload);
    });

    socket.on('pathChoice', (data) {
      final payload = Map<String, dynamic>.from(data as Map);
      _addMessage(SocketMessageType.pathChoice, payload);
    });

    socket.on('error', (data) {
      final payload = data is Map
          ? Map<String, dynamic>.from(data)
          : {'text': data.toString()};
      _addMessage(SocketMessageType.error, payload);
    });
  }

  /// Adds a message to the general message stream.
  void _addMessage(SocketMessageType type, Map<String, dynamic> data) {
    _messageController.add(SocketMessage(type: type, data: data));
  }

  /// Sends a game command to the server (e.g., /attack, /use, /inspect).
  void sendCommand(String command) {
    _socket?.emit('command', {
      'command': command,
      'roomId': _currentRoomId,
    });
  }

  /// Joins a game room by its ID.
  void joinRoom(String roomId) {
    _currentRoomId = roomId;
    _socket?.emit('joinRoom', {'roomId': roomId});
  }

  /// Leaves the current game room.
  void leaveRoom() {
    if (_currentRoomId != null) {
      _socket?.emit('leaveRoom', {'roomId': _currentRoomId});
      _currentRoomId = null;
    }
  }

  /// Sends a chat message to the current room.
  void sendChatMessage(String message) {
    _socket?.emit('chatMessage', {
      'message': message,
      'roomId': _currentRoomId,
    });
  }

  /// Selects a path choice during dungeon exploration.
  void selectPath(String pathId) {
    _socket?.emit('selectPath', {
      'pathId': pathId,
      'roomId': _currentRoomId,
    });
  }

  /// Disposes all stream controllers. Call on app shutdown.
  void dispose() {
    disconnect();
    _messageController.close();
    _attackResultController.close();
    _chatMessageController.close();
    _roomUpdateController.close();
    _dungeonProgressController.close();
    _playerUpdateController.close();
    _connectionController.close();
  }
}
