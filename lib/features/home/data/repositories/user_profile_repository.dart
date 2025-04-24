import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:frenzy/features/home/domain/models/user_profile.dart';

class UserProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'users';

  UserProfileRepository(this._firestore);

  Stream<UserProfile?> getUserProfile(String userId) {
    return _firestore
        .collection(_collection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  Future<UserProfile> createUserProfile(String userId, String email) async {
    final profile = UserProfile(
      id: userId,
      email: email,
      name: '',
      username: '',
      photoUrl: '',
      profileImageUrl: '',
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(_collection)
        .doc(userId)
        .set(profile.toFirestore());

    return profile;
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _firestore
        .collection(_collection)
        .doc(profile.id)
        .update(profile.toFirestore());
  }

  Future<void> deleteUserProfile(String userId) async {
    await _firestore.collection(_collection).doc(userId).delete();
  }

  Future<String> uploadProfileImage(String userId, String imagePath) async {
    final file = File(imagePath);
    final ref = _storage.ref().child('profile_images/$userId.jpg');
    
    try {
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }
}
