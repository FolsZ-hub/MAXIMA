import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:maxima_rpg/models/player.dart';
import 'package:maxima_rpg/models/character.dart';
import 'package:maxima_rpg/models/dungeon.dart';

/// Service for all Firestore CRUD operations (players, characters, rooms/dungeons).
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Players collection
  // ---------------------------------------------------------------------------

  /// Reference to the players collection.
  CollectionReference<Map<String, dynamic>> get _playersRef =>
      _firestore.collection('players');

  /// Creates a new player document.
  Future<void> createPlayer(Player player) async {
    await _playersRef.doc(player.uid).set(player.toJson());
  }

  /// Reads a player by their UID.
  Future<Player?> getPlayer(String uid) async {
    final doc = await _playersRef.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return Player.fromJson(doc.data()!);
  }

  /// Updates an existing player document (merge to avoid overwriting).
  Future<void> updatePlayer(String uid, Map<String, dynamic> data) async {
    await _playersRef.doc(uid).update(data);
  }

  /// Deletes a player document.
  Future<void> deletePlayer(String uid) async {
    await _playersRef.doc(uid).delete();
  }

  /// Returns a real-time stream of a player document.
  Stream<Player?> playerStream(String uid) {
    return _playersRef.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return Player.fromJson(snapshot.data()!);
    });
  }

  // ---------------------------------------------------------------------------
  // Characters collection
  // ---------------------------------------------------------------------------

  /// Reference to the characters collection.
  CollectionReference<Map<String, dynamic>> get _charactersRef =>
      _firestore.collection('characters');

  /// Creates a new character document.
  Future<void> createCharacter(Character character) async {
    await _charactersRef.doc(character.characterId).set(character.toJson());
  }

  /// Reads a character by its ID.
  Future<Character?> getCharacter(String characterId) async {
    final doc = await _charactersRef.doc(characterId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Character.fromJson(doc.data()!);
  }

  /// Gets all characters for a specific player.
  Future<List<Character>> getCharactersByPlayer(String playerId) async {
    final query = await _charactersRef
        .where('playerId', isEqualTo: playerId)
        .get();
    return query.docs
        .map((doc) => Character.fromJson(doc.data()))
        .toList();
  }

  /// Gets all alive characters for a specific player.
  Future<List<Character>> getAliveCharacters(String playerId) async {
    final query = await _charactersRef
        .where('playerId', isEqualTo: playerId)
        .where('isAlive', isEqualTo: true)
        .get();
    return query.docs
        .map((doc) => Character.fromJson(doc.data()))
        .toList();
  }

  /// Gets all dead (legacy) characters for a specific player.
  Future<List<Character>> getLegacyCharacters(String playerId) async {
    final query = await _charactersRef
        .where('playerId', isEqualTo: playerId)
        .where('isAlive', isEqualTo: false)
        .get();
    return query.docs
        .map((doc) => Character.fromJson(doc.data()))
        .toList();
  }

  /// Updates a character document.
  Future<void> updateCharacter(
      String characterId, Map<String, dynamic> data) async {
    await _charactersRef.doc(characterId).update(data);
  }

  /// Deletes a character document.
  Future<void> deleteCharacter(String characterId) async {
    await _charactersRef.doc(characterId).delete();
  }

  /// Returns a real-time stream of a character document.
  Stream<Character?> characterStream(String characterId) {
    return _charactersRef.doc(characterId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return Character.fromJson(snapshot.data()!);
    });
  }

  // ---------------------------------------------------------------------------
  // Rooms / Dungeons collection
  // ---------------------------------------------------------------------------

  /// Reference to the rooms collection.
  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _firestore.collection('rooms');

  /// Reference to the dungeons collection.
  CollectionReference<Map<String, dynamic>> get _dungeonsRef =>
      _firestore.collection('dungeons');

  /// Creates a new room for a dungeon session.
  Future<String> createRoom(Map<String, dynamic> roomData) async {
    final doc = await _roomsRef.add(roomData);
    return doc.id;
  }

  /// Reads a room by its ID.
  Future<Map<String, dynamic>?> getRoom(String roomId) async {
    final doc = await _roomsRef.doc(roomId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  /// Updates a room document.
  Future<void> updateRoom(String roomId, Map<String, dynamic> data) async {
    await _roomsRef.doc(roomId).update(data);
  }

  /// Deletes a room document.
  Future<void> deleteRoom(String roomId) async {
    await _roomsRef.doc(roomId).delete();
  }

  /// Returns a real-time stream of a room document.
  Stream<Map<String, dynamic>?> roomStream(String roomId) {
    return _roomsRef.doc(roomId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return snapshot.data();
    });
  }

  /// Gets all available dungeons from Firestore.
  Future<List<Dungeon>> getDungeons() async {
    final query = await _dungeonsRef.get();
    if (query.docs.isEmpty) {
      // Return default dungeons if none exist in Firestore.
      return Dungeon.getDefaultDungeons();
    }
    return query.docs
        .map((doc) => Dungeon.fromJson(doc.data()))
        .toList();
  }

  /// Creates or updates a dungeon definition.
  Future<void> setDungeon(Dungeon dungeon) async {
    await _dungeonsRef.doc(dungeon.dungeonId).set(dungeon.toJson());
  }

  /// Deletes a dungeon definition.
  Future<void> deleteDungeon(String dungeonId) async {
    await _dungeonsRef.doc(dungeonId).delete();
  }
}
