import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frenzy/core/services/firebase_service.dart';
import 'package:frenzy/core/models/user.dart';

class AuthProvider extends ChangeNotifier {
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isLoading = false;
  bool _isAdmin = false;

  AuthProvider() {
    _auth.authStateChanges().listen((firebase.User? firebaseUser) async {
      if (firebaseUser != null) {
        // Get user data from Firestore
        final userDoc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (userDoc.exists) {
          _user = User.fromMap({
            'uid': firebaseUser.uid,
            'email': firebaseUser.email ?? '',
            'displayName': firebaseUser.displayName,
            'photoURL': firebaseUser.photoURL,
            'isAdmin': userDoc.data()?['isAdmin'] ?? false,
            'walletBalance': userDoc.data()?['walletBalance'] ?? 0.0,
          });
        } else {
          // Create new user document if it doesn't exist
          _user = User(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL,
            isAdmin: false,
            walletBalance: 0.0,
          );
          await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .set(_user!.toMap());
        }
        _isAdmin = await FirebaseService.isUserAdmin();
      } else {
        _user = null;
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
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error signing in: $e');
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

      if (userCredential.user != null) {
        final isAdmin = email.toLowerCase().endsWith("@admin.com");
        final newUser = User(
          uid: userCredential.user!.uid,
          email: email,
          displayName: name,
          isAdmin: isAdmin,
          walletBalance: 0.0,
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(newUser.toMap());
      }
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    }
  }
}
