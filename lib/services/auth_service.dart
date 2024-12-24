import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  static void handleAuthStateChanges(BuildContext context) {
    authStateChanges().listen((User? user) {
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }
}
