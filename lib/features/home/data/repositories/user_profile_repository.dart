import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frenzy/features/home/domain/models/user_profile.dart';

class UserProfileRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'users';

  UserProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final docSnapshot =
          await _firestore.collection(_collection).doc(userId).get();

      if (docSnapshot.exists) {
        return UserProfile.fromMap(userId, docSnapshot.data()!);
      }

      // Create a new profile if it doesn't exist
      final defaultProfile = UserProfile(
        id: userId,
        name: '',
        bio: '',
        profileImageUrl:
            'https://drive.google.com/uc?export=view&id=YOUR_DEFAULT_PROFILE_IMAGE_ID',
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(userId)
          .set(defaultProfile.toMap());

      return defaultProfile;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(profile.id)
          .update(profile.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfileImage(String userId, String imageUrl) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
}
