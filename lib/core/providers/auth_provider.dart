import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isLoading = false;
  bool _isAdmin = false;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        try {
          // Get user data from Firestore
          final doc = await _firestore.collection('users').doc(user.uid).get();
          
          // Check if user exists in Firestore
          if (!doc.exists) {
            // Create user document if it doesn't exist
            await _firestore.collection('users').doc(user.uid).set({
              'email': user.email,
              'isAdmin': user.email?.toLowerCase().endsWith('@admin.com') ?? false,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
          
          // Update admin status from Firestore
          _isAdmin = doc.data()?['isAdmin'] ?? false;
        } catch (e) {
          debugPrint('Error getting user data: $e');
          // Fallback to email check if Firestore fails
          _isAdmin = user.email?.toLowerCase().endsWith('@admin.com') ?? false;
        }
      } else {
        _isAdmin = false;
      }
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAdmin => _isAdmin;
  bool get isAuthenticated => _user != null;

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'isAdmin': email.toLowerCase().endsWith('@admin.com'),
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _isAdmin = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }
}
