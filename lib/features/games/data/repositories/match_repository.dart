import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/match.dart';

class MatchRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'matches';

  MatchRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Match>> getActiveMatchesForGame(String gameId) async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection(_collection)
        .where('gameId', isEqualTo: gameId)
        .where('status', whereIn: ['upcoming', 'ongoing'])
        .where('startTime', isGreaterThanOrEqualTo: now)
        .orderBy('startTime')
        .get();

    return snapshot.docs.map((doc) => Match.fromFirestore(doc)).toList();
  }

  Future<Match?> getMatchById(String matchId) async {
    final doc = await _firestore.collection(_collection).doc(matchId).get();
    if (!doc.exists) return null;
    return Match.fromFirestore(doc);
  }

  Future<Match> createMatch(Match match) async {
    final docRef = _firestore.collection(_collection).doc();
    final matchWithId = match.copyWith(id: docRef.id);
    await docRef.set(matchWithId.toMap());
    return matchWithId;
  }

  Future<void> updateMatch(Match match) async {
    await _firestore
        .collection(_collection)
        .doc(match.id)
        .update(match.toMap());
  }

  Future<void> joinMatch(String matchId, String userId, String username) async {
    await _firestore.runTransaction((transaction) async {
      final matchRef = _firestore.collection(_collection).doc(matchId);
      final matchDoc = await transaction.get(matchRef);

      if (!matchDoc.exists) {
        throw Exception('Match not found');
      }

      final match = Match.fromFirestore(matchDoc);
      if (match.isFull) {
        throw Exception('Match is full');
      }

      final participantExists = match.participants
          .any((participant) => participant['userId'] == userId);
      if (participantExists) {
        throw Exception('User already joined this match');
      }

      final updatedParticipants =
          List<Map<String, dynamic>>.from(match.participants)
            ..add({
              'userId': userId,
              'username': username,
              'joinedAt': FieldValue.serverTimestamp(),
            });

      transaction.update(matchRef, {
        'participants': updatedParticipants,
        'currentParticipants': match.currentParticipants + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> leaveMatch(String matchId, String userId) async {
    await _firestore.runTransaction((transaction) async {
      final matchRef = _firestore.collection(_collection).doc(matchId);
      final matchDoc = await transaction.get(matchRef);

      if (!matchDoc.exists) {
        throw Exception('Match not found');
      }

      final match = Match.fromFirestore(matchDoc);
      final participantIndex = match.participants
          .indexWhere((participant) => participant['userId'] == userId);

      if (participantIndex == -1) {
        throw Exception('User is not in this match');
      }

      final updatedParticipants =
          List<Map<String, dynamic>>.from(match.participants)
            ..removeAt(participantIndex);

      transaction.update(matchRef, {
        'participants': updatedParticipants,
        'currentParticipants': match.currentParticipants - 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<List<Match>> getUserMatches(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('participants', arrayContains: {'userId': userId})
        .orderBy('startTime', descending: true)
        .get();

    return snapshot.docs.map((doc) => Match.fromFirestore(doc)).toList();
  }

  Future<List<Match>> getUpcomingMatches() async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'upcoming')
        .where('startTime', isGreaterThan: now)
        .orderBy('startTime')
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => Match.fromFirestore(doc)).toList();
  }

  Future<List<Match>> getOngoingMatches() async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'ongoing')
        .orderBy('startTime', descending: true)
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => Match.fromFirestore(doc)).toList();
  }
}
