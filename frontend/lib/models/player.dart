/// Represents a player account in the MAXIMA RPG system.
class Player {
  final String uid;
  final String username;
  int smartCoins;
  List<String> legacyCharacters; // IDs of dead characters kept for legacy bonuses
  Map<String, dynamic> settings;

  Player({
    required this.uid,
    required this.username,
    this.smartCoins = 0,
    List<String>? legacyCharacters,
    Map<String, dynamic>? settings,
  })  : legacyCharacters = legacyCharacters ?? [],
        settings = settings ?? {
          'soundEnabled': true,
          'notificationsEnabled': true,
          'serverUrl': 'http://localhost:3000',
        };

  /// Creates a [Player] instance from a Firestore document map.
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      uid: json['uid'] as String? ?? '',
      username: json['username'] as String? ?? 'Desconocido',
      smartCoins: json['smartCoins'] as int? ?? 0,
      legacyCharacters: (json['legacyCharacters'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      settings: (json['settings'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Converts this [Player] to a JSON-compatible map for Firestore storage.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'smartCoins': smartCoins,
      'legacyCharacters': legacyCharacters,
      'settings': settings,
    };
  }

  /// Creates a copy of this player with optional overrides.
  Player copyWith({
    String? uid,
    String? username,
    int? smartCoins,
    List<String>? legacyCharacters,
    Map<String, dynamic>? settings,
  }) {
    return Player(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      smartCoins: smartCoins ?? this.smartCoins,
      legacyCharacters: legacyCharacters ?? this.legacyCharacters,
      settings: settings ?? this.settings,
    );
  }

  @override
  String toString() =>
      'Player(uid: $uid, username: $username, coins: $smartCoins)';
}
