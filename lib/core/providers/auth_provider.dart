import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isLoading = false;
  bool _isAdmin = false;
  static const String _persistenceKey = 'auth_persistence';

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Set persistence to LOCAL
    await _auth.setPersistence(Persistence.LOCAL);

    // Check for existing session
    final prefs = await SharedPreferences.getInstance();
    final isPersisted = prefs.getBool(_persistenceKey) ?? false;

    if (isPersisted) {
      // Try to get the current user
      _user = _auth.currentUser;
      if (_user != null) {
        await _updateUserData(_user!);
      }
    }

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _updateUserData(user);
        // Save persistence state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_persistenceKey, true);
      } else {
        _isAdmin = false;
        // Clear persistence state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_persistenceKey, false);
      }
      notifyListeners();
    });
  }

  Future<void> _updateUserData(User user) async {
    try {
      // Create base user data
      final userData = {
        'email': user.email,
        'lastLogin': FieldValue.serverTimestamp(),
      };

      // Get user document reference
      final userRef = _firestore.collection('users').doc(user.uid);
      
      // Try to get existing user data
      final doc = await userRef.get();
      
      if (!doc.exists) {
        // For new users, add additional fields
        userData.addAll({
          'name': user.displayName ?? 'Unknown User',
          'isAdmin': false,  // Never set admin status automatically
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Create new user document
        await userRef.set(userData);
        
        // Also create user profile if it doesn't exist
        final profileRef = _firestore.collection('userProfiles').doc(user.uid);
        if (!(await profileRef.get()).exists) {
          await profileRef.set({
            'name': user.displayName ?? 'Unknown User',
            'email': user.email,
            'bio': '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        
        _isAdmin = false;
      } else {
        // Update existing user's last login
        await userRef.update(userData);
        _isAdmin = doc.data()?['isAdmin'] ?? false;
      }
    } catch (e) {
      debugPrint('Error updating user data: $e');
      _isAdmin = false;  // Default to non-admin on error
    }
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAdmin => _isAdmin;
  bool get isAuthenticated => _user != null;

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // First authenticate with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Authentication failed');
      }

      // Get user document to check role
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();

      // If user document doesn't exist, create it
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'name': userCredential.user!.displayName ?? 'Unknown User',
          'isAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        // Just update last login
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      // Save persistence state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_persistenceKey, true);

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

      // Create the user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create initial user document
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'isAdmin': false,  // Never set admin status during signup
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // Create user profile
      await _firestore.collection('userProfiles').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'bio': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Save persistence state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_persistenceKey, true);

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
      
      // Clear persistence state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_persistenceKey, false);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }
}
