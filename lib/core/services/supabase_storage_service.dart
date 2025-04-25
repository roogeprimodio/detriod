import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class SupabaseStorageService {
  static final SupabaseClient _supabase = SupabaseClient(
    'https://lqmlebwpgtnwsoiccxrg.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxxbWxlYndwZ3Rud3NvaWNjeHJnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI4OTE3MzUsImV4cCI6MjA1ODQ2NzczNX0.eft_o8fhnFGjLqiQRWTFQk6Hn3UDrXzWBK2C553g5mE',
  );

  // Bucket names
  static const String _profileImagesBucket = 'profile-images';
  static const String _gameImagesBucket = 'game-images';
  static const String _matchScreenshotsBucket = 'match-screenshots';

  static Future<String> _getFirebaseToken() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final token = await user.getIdToken();
    if (token == null) throw Exception('Failed to get Firebase token');
    return token;
  }

  static Future<String> uploadProfileImage(File file, String userId) async {
    try {
      final fileName = path.basename(file.path);
      final token = await _getFirebaseToken();
      
      final response = await _supabase.storage
          .from(_profileImagesBucket)
          .uploadBinary(
            '$userId/$fileName',
            await file.readAsBytes(),
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      return _supabase.storage
          .from(_profileImagesBucket)
          .getPublicUrl('$userId/$fileName');
    } catch (e) {
      print('Error uploading profile image: $e');
      rethrow;
    }
  }

  static Future<String> uploadGameImage(File file, String gameId) async {
    try {
      final fileName = path.basename(file.path);
      final token = await _getFirebaseToken();
      
      final response = await _supabase.storage
          .from(_gameImagesBucket)
          .uploadBinary(
            '$gameId/$fileName',
            await file.readAsBytes(),
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      return _supabase.storage
          .from(_gameImagesBucket)
          .getPublicUrl('$gameId/$fileName');
    } catch (e) {
      print('Error uploading game image: $e');
      rethrow;
    }
  }

  static Future<String> uploadMatchScreenshot(File file, String matchId) async {
    try {
      final fileName = path.basename(file.path);
      final token = await _getFirebaseToken();
      
      final response = await _supabase.storage
          .from(_matchScreenshotsBucket)
          .uploadBinary(
            '$matchId/$fileName',
            await file.readAsBytes(),
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      return _supabase.storage
          .from(_matchScreenshotsBucket)
          .getPublicUrl('$matchId/$fileName');
    } catch (e) {
      print('Error uploading match screenshot: $e');
      rethrow;
    }
  }

  static Future<void> deleteProfileImage(String userId, String fileName) async {
    try {
      final token = await _getFirebaseToken();
      await _supabase.storage
          .from(_profileImagesBucket)
          .remove(['$userId/$fileName']);
    } catch (e) {
      print('Error deleting profile image: $e');
      rethrow;
    }
  }

  static Future<void> deleteGameImage(String gameId, String fileName) async {
    try {
      final token = await _getFirebaseToken();
      await _supabase.storage
          .from(_gameImagesBucket)
          .remove(['$gameId/$fileName']);
    } catch (e) {
      print('Error deleting game image: $e');
      rethrow;
    }
  }

  static Future<void> deleteMatchScreenshot(String matchId, String fileName) async {
    try {
      final token = await _getFirebaseToken();
      await _supabase.storage
          .from(_matchScreenshotsBucket)
          .remove(['$matchId/$fileName']);
    } catch (e) {
      print('Error deleting match screenshot: $e');
      rethrow;
    }
  }
} 