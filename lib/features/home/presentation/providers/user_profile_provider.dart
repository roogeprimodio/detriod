import 'package:flutter/material.dart';
import 'package:frenzy/features/home/data/repositories/user_profile_repository.dart';
import 'package:frenzy/features/home/domain/models/user_profile.dart';

class UserProfileProvider extends ChangeNotifier {
  final UserProfileRepository _repository;
  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;

  UserProfileProvider({UserProfileRepository? repository})
      : _repository = repository ?? UserProfileRepository();

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProfile(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _profile = await _repository.getUserProfile(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? profileImageUrl,
  }) async {
    if (_profile == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedProfile = _profile!.copyWith(
        name: name,
        bio: bio,
        profileImageUrl: profileImageUrl,
      );

      await _repository.updateUserProfile(updatedProfile);
      _profile = updatedProfile;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateProfileImage(String userId, String imageUrl) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.updateProfileImage(userId, imageUrl);
      if (_profile != null) {
        _profile = _profile!.copyWith(profileImageUrl: imageUrl);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
}
