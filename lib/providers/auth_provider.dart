import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppAuthProvider extends ChangeNotifier {
  // Edited to centralize Firebase Auth so every screen can access the same signed-in user through Provider.
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final StreamSubscription<User?> _authSubscription;

  User? _user;
  bool _isLoading = true;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _user != null;
  String? get errorMessage => _errorMessage;

  AppAuthProvider() {
    // Edited to react to sign-in/sign-out across app restarts without manually passing credentials between screens.
    _authSubscription = _auth.authStateChanges().listen((user) {
      _user = user;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    await _runAuthAction(
      () => _auth.signInWithEmailAndPassword(email: email, password: password),
    );
  }

  Future<void> register(String email, String password) async {
    await _runAuthAction(
      () => _auth.createUserWithEmailAndPassword(email: email, password: password),
    );
  }

  Future<void> signOut() async {
    // Edited to let users switch accounts so each account sees only its own plant profiles and device branch.
    await _auth.signOut();
  }

  Future<void> _runAuthAction(Future<UserCredential> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } on FirebaseAuthException catch (error) {
      _errorMessage = error.message ?? 'Authentication failed. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
