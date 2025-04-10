import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/game.dart';

class GameRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'games';

  GameRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get all active games
  Stream<List<Game>> getActiveGames() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Game.fromFirestore(doc)).toList());
  }

  // Get game by ID
  Future<Game?> getGameById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return Game.fromFirestore(doc);
  }

  // Create new game
  Future<String> createGame(Game game) async {
    final docRef = await _firestore.collection(_collection).add(game.toMap());
    return docRef.id;
  }

  // Update game
  Future<void> updateGame(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update(data);
  }

  // Delete game (soft delete by setting isActive to false)
  Future<void> deleteGame(String id) async {
    await _firestore
        .collection(_collection)
        .doc(id)
        .update({'isActive': false});
  }

  // Get games by genre
  Stream<List<Game>> getGamesByGenre(String genre) {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .where('genre', isEqualTo: genre)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Game.fromFirestore(doc)).toList());
  }

  // Get games by platform
  Stream<List<Game>> getGamesByPlatform(String platform) {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .where('platforms', arrayContains: platform)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Game.fromFirestore(doc)).toList());
  }

  // Search games by title
  Stream<List<Game>> searchGames(String query) {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Game.fromFirestore(doc)).toList());
  }
}
