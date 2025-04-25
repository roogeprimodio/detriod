import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> uploadProfileImage(File file, String userId) async {
    try {
      final fileName = path.basename(file.path);
      final ref = _storage.ref().child('profile_images/$userId/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile image: $e');
      rethrow;
    }
  }

  static Future<String> uploadGameImage(File file, String gameId) async {
    try {
      final fileName = path.basename(file.path);
      final ref = _storage.ref().child('game_images/$gameId/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading game image: $e');
      rethrow;
    }
  }

  static Future<String> uploadMatchScreenshot(File file, String matchId) async {
    try {
      final fileName = path.basename(file.path);
      final ref = _storage.ref().child('match_screenshots/$matchId/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading match screenshot: $e');
      rethrow;
    }
  }

  static Future<void> deleteProfileImage(String userId, String fileName) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId/$fileName');
      await ref.delete();
    } catch (e) {
      print('Error deleting profile image: $e');
      rethrow;
    }
  }

  static Future<void> deleteGameImage(String gameId, String fileName) async {
    try {
      final ref = _storage.ref().child('game_images/$gameId/$fileName');
      await ref.delete();
    } catch (e) {
      print('Error deleting game image: $e');
      rethrow;
    }
  }

  static Future<void> deleteMatchScreenshot(String matchId, String fileName) async {
    try {
      final ref = _storage.ref().child('match_screenshots/$matchId/$fileName');
      await ref.delete();
    } catch (e) {
      print('Error deleting match screenshot: $e');
      rethrow;
    }
  }
} 