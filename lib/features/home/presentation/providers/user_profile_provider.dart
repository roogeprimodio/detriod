import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frenzy/features/home/data/repositories/user_profile_repository.dart';
import 'package:frenzy/features/home/domain/models/user_profile.dart';

class UserProfileProvider extends ChangeNotifier {
  final UserProfileRepository _repository;
  UserProfile? _profile;
  Stream<UserProfile?>? _profileStream;

  UserProfileProvider()
      : _repository = UserProfileRepository(FirebaseFirestore.instance);

  UserProfile? get profile => _profile;
  bool get isLoading => _profile == null;

  void listenToUserProfile(String userId) {
    _profileStream = _repository.getUserProfile(userId);
    _profileStream?.listen((profile) {
      _profile = profile;
      notifyListeners();
    });
  }

  Future<void> createUserProfile(String userId, String email) async {
    try {
      _profile = await _repository.createUserProfile(userId, email);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String userId,
    String? name,
    String? username,
    String? bio,
    String? photoUrl,
    String? profileImageUrl,
  }) async {
    if (_profile == null) return;

    try {
      final updatedProfile = _profile!.copyWith(
        name: name,
        username: username,
        bio: bio,
        photoUrl: photoUrl,
        profileImageUrl: profileImageUrl,
      );

      await _repository.updateUserProfile(updatedProfile);
      _profile = updatedProfile;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfileImage(String userId, String imagePath) async {
    try {
      if (_profile != null) {
        // Upload image to Firebase Storage
        final downloadUrl =
            await _repository.uploadProfileImage(userId, imagePath);

        // Update profile with new image URL
        final updatedProfile = _profile!.copyWith(profileImageUrl: downloadUrl);
        await _repository.updateUserProfile(updatedProfile);
        _profile = updatedProfile;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }
}
