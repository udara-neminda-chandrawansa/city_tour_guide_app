import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'DatabaseHelper.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // Local signup method using SQLite
  Future<bool> localSignUp({
    required String email,
    required String password,
    String? username
  }) async {
    try {
      // Check if user already exists
      final existingUser = await _dbHelper.getUserByEmail(email);
      if (existingUser != null) {
        throw Exception('User already exists');
      }

      // Insert user into local database
      await _dbHelper.insertUser({
        'email': email,
        'password': _hashPassword(password), // In real app, use proper hashing
        'username': username
      });

      // Optionally sync with Firebase if needed
      await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );

      notifyListeners();
      return true;
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }

  // Local login method using SQLite
  Future<bool> localLogin({
    required String email,
    required String password
  }) async {
    try {
      final user = await _dbHelper.getUserByEmail(email);

      if (user == null) {
        throw Exception('User not found');
      }

      // Compare passwords (in real app, use proper password hashing)
      if (user['password'] != _hashPassword(password)) {
        throw Exception('Invalid password');
      }

      // Firebase authentication as a backup/sync
      await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );

      notifyListeners();
      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Very basic password hashing (use a proper method in production)
  String _hashPassword(String password) {
    // IMPORTANT: This is NOT secure. Use proper hashing in production.
    return password.hashCode.toString();
  }

  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }
}