import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:maxima_rpg/models/player.dart';

/// Wraps Firebase Authentication and provides reactive auth state.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  Player? _player;
  bool _isLoading = false;
  String? _errorMessage;

  /// The currently signed-in Firebase user.
  User? get user => _user;

  /// The player profile loaded from Firestore.
  Player? get player => _player;

  /// Whether an auth operation is in progress.
  bool get isLoading => _isLoading;

  /// The most recent error message, if any.
  String? get errorMessage => _errorMessage;

  /// Whether a user is currently signed in.
  bool get isSignedIn => _user != null;

  /// Stream of Firebase auth state changes.
  Stream<User?> get authStateStream => _auth.authStateChanges();

  AuthService() {
    // Listen to auth state changes and load player data.
    _auth.authStateChanges().listen((User? firebaseUser) async {
      _user = firebaseUser;
      if (firebaseUser != null) {
        await _loadPlayer(firebaseUser.uid);
      } else {
        _player = null;
      }
      notifyListeners();
    });
  }

  /// Signs in a user with email and password.
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _user = credential.user;

      if (_user != null) {
        await _loadPlayer(_user!.uid);
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  /// Registers a new user with email, password, and username.
  /// Also creates the player document in Firestore.
  Future<bool> register(
      String email, String password, String username) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _user = credential.user;

      if (_user != null) {
        // Create player profile in Firestore.
        final newPlayer = Player(
          uid: _user!.uid,
          username: username.trim(),
          smartCoins: 100, // Starting coins
        );

        await _firestore
            .collection('players')
            .doc(_user!.uid)
            .set(newPlayer.toJson());

        _player = newPlayer;
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _player = null;
    notifyListeners();
  }

  /// Returns the currently signed-in user (synchronous check).
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Loads the player profile from Firestore.
  Future<void> _loadPlayer(String uid) async {
    try {
      final doc = await _firestore.collection('players').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _player = Player.fromJson(doc.data()!);
      }
    } catch (e) {
      _errorMessage = 'Error cargando perfil: ${e.toString()}';
    }
  }

  /// Sets loading state and notifies listeners.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Maps Firebase Auth error codes to Spanish user-friendly messages.
  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No se encontro un aventurero con ese correo.';
      case 'wrong-password':
        return 'Contrasena incorrecta. Intenta de nuevo.';
      case 'email-already-in-use':
        return 'Ese correo ya esta registrado en la mazmorra.';
      case 'weak-password':
        return 'La contrasena es muy debil. Necesitas al menos 6 caracteres.';
      case 'invalid-email':
        return 'El correo no es valido.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento.';
      default:
        return 'Error de autenticacion: $code';
    }
  }
}
