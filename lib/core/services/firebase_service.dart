import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Get Firestore instance
  static FirebaseFirestore get firestore => _firestore;

  // Get Auth instance
  static FirebaseAuth get auth => _auth;

  // Check if user is admin
  static bool isUserAdmin() {
    final user = currentUser;
    return user != null &&
        user.email != null &&
        user.email!.toLowerCase().endsWith('@admin.com');
  }

  // Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // Update user data
  static Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      final user = currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update(data);
    } catch (e) {
      debugPrint('Error updating user data: $e');
      rethrow;
    }
  }

  // Games methods
  static Stream<QuerySnapshot> getGames() {
    return _firestore
        .collection('games')
        .where('isActive', isEqualTo: true)
        .orderBy('releaseDate', descending: true)
        .snapshots();
  }

  static Future<DocumentSnapshot> getGameById(String gameId) {
    return _firestore.collection('games').doc(gameId).get();
  }

  // Matches methods
  static Stream<QuerySnapshot> getMatchesForGame(String gameId) {
    return _firestore
        .collection('matches')
        .where('gameId', isEqualTo: gameId)
        .where('isActive', isEqualTo: true)
        .orderBy('date', descending: false)
        .snapshots();
  }

  static Future<DocumentSnapshot> getMatchById(String matchId) {
    return _firestore.collection('matches').doc(matchId).get();
  }

  // Registration methods
  static Future<void> registerForMatch(
      String matchId, Map<String, dynamic> userData) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if user already registered
    final existingRegistrations = await _firestore
        .collection('registrations')
        .where('matchId', isEqualTo: matchId)
        .where('userId', isEqualTo: user.uid)
        .get();

    if (existingRegistrations.docs.isNotEmpty) {
      throw Exception('You are already registered for this match');
    }

    // Get match details to check capacity
    final matchDoc = await getMatchById(matchId);
    final matchData = matchDoc.data() as Map<String, dynamic>;

    if (matchData['currentParticipants'] >= matchData['maxParticipants']) {
      throw Exception('This match is already full');
    }

    // Create registration
    await _firestore.collection('registrations').add({
      'matchId': matchId,
      'userId': user.uid,
      'userName': userData['name'] ?? user.displayName ?? 'Anonymous',
      'userEmail': user.email,
      'registrationDate': FieldValue.serverTimestamp(),
      'paymentStatus': 'pending',
      'paymentAmount': matchData['entryFee'] ?? 0,
      'status': 'registered'
    });

    // Update match participant count
    await _firestore
        .collection('matches')
        .doc(matchId)
        .update({'currentParticipants': FieldValue.increment(1)});

    // Update user's registered matches
    await _firestore.collection('users').doc(user.uid).update({
      'registeredMatches': FieldValue.arrayUnion([matchId])
    });
  }

  // Admin methods
  static Future<void> createGame(Map<String, dynamic> gameData) async {
    if (!isUserAdmin()) throw Exception('Only admins can create games');

    await _firestore.collection('games').add({
      ...gameData,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true
    });
  }

  static Future<void> updateGame(
      String gameId, Map<String, dynamic> gameData) async {
    if (!isUserAdmin()) throw Exception('Only admins can update games');

    await _firestore.collection('games').doc(gameId).update(gameData);
  }

  static Future<void> deleteGame(String gameId) async {
    if (!isUserAdmin()) throw Exception('Only admins can delete games');

    await _firestore
        .collection('games')
        .doc(gameId)
        .update({'isActive': false});
  }

  static Future<void> createMatch(Map<String, dynamic> matchData) async {
    if (!isUserAdmin()) throw Exception('Only admins can create matches');

    await _firestore.collection('matches').add({
      ...matchData,
      'currentParticipants': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true
    });
  }

  static Future<void> updateMatch(
      String matchId, Map<String, dynamic> matchData) async {
    if (!isUserAdmin()) throw Exception('Only admins can update matches');

    await _firestore.collection('matches').doc(matchId).update(matchData);
  }

  static Future<void> deleteMatch(String matchId) async {
    if (!isUserAdmin()) throw Exception('Only admins can delete matches');

    await _firestore
        .collection('matches')
        .doc(matchId)
        .update({'isActive': false});
  }

  // User profile methods
  static Future<DocumentSnapshot> getUserProfile() async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    return await _firestore.collection('users').doc(user.uid).get();
  }

  static Future<void> updateUserProfile(
      Map<String, dynamic> profileData) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('users').doc(user.uid).set(
        {...profileData, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
  }

  // Get user's registered matches
  static Stream<QuerySnapshot> getUserRegistrations() {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('registrations')
        .where('userId', isEqualTo: user.uid)
        .orderBy('registrationDate', descending: true)
        .snapshots();
  }
}
