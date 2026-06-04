import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AppAuthProvider extends ChangeNotifier {
  AppAuthProvider() {
    _subscription = _authService.authStateChanges.listen((user) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _subscription;

  User? _user;
  bool _isLoading = true;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _user != null;
  String? get error => _error;

  Future<void> signIn({required String email, required String password}) async {
    await _runAuthAction(
      () => _authService.signIn(email: email, password: password),
    );
  }

  Future<void> createAccount({
    required String email,
    required String password,
  }) async {
    await _runAuthAction(
      () => _authService.createAccount(email: email, password: password),
    );
  }

  Future<void> signOut() async {
    _error = null;
    await _authService.signOut();
  }

  Future<void> _runAuthAction(Future<dynamic> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await action();
    } on FirebaseAuthException catch (error) {
      _error = _friendlyAuthMessage(error);
      rethrow;
    } catch (error) {
      _error = 'Authentication failed: $error';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _friendlyAuthMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'The email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account already exists for that email address.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
