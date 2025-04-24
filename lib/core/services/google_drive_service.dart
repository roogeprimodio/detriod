import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/google_drive_credentials.dart';

class GoogleDriveService {
  static const _scopes = [drive.DriveApi.driveFileScope];
  
  // API Keys for different platforms
  static const _apiKeys = {
    'ios': 'AIzaSyB2jaigD_bry2pbpH-lgwD6aHanjULrOhY',
    'web': 'AIzaSyA2t_Fftxinhujz1C4m192d1KAHkcEeOX0',
    'android': 'AIzaSyCTh6GU0oSr9k0fMDhF4pKY84R8GcwnN_I',
  };

  static String get _currentApiKey {
    if (kIsWeb) return _apiKeys['web']!;
    if (Platform.isIOS) return _apiKeys['ios']!;
    if (Platform.isAndroid) return _apiKeys['android']!;
    return _apiKeys['web']!; // Default to web key
  }

  static Future<drive.DriveApi> _getDriveApi() async {
    final credentials = ServiceAccountCredentials.fromJson(googleDriveCredentials);
    final client = await clientViaServiceAccount(credentials, _scopes);
    return drive.DriveApi(client);
  }

  static Future<String> uploadFile(File file, String folderId) async {
    try {
      final driveApi = await _getDriveApi();
      final fileName = path.basename(file.path);
      
      final drive.File fileMetadata = drive.File()
        ..name = fileName
        ..parents = [folderId];

      final media = drive.Media(file.openRead(), file.lengthSync());
      final uploadedFile = await driveApi.files.create(
        fileMetadata,
        uploadMedia: media,
      );

      // Make the file publicly accessible
      await driveApi.permissions.create(
        drive.Permission()
          ..type = 'anyone'
          ..role = 'reader',
        uploadedFile.id!,
      );

      return 'https://drive.google.com/uc?export=view&id=${uploadedFile.id}';
    } catch (e) {
      print('Error uploading file to Google Drive: $e');
      rethrow;
    }
  }

  static Future<void> deleteFile(String fileId) async {
    try {
      final driveApi = await _getDriveApi();
      await driveApi.files.delete(fileId);
    } catch (e) {
      print('Error deleting file from Google Drive: $e');
      rethrow;
    }
  }

  static Future<String> createFolder(String folderName) async {
    try {
      final driveApi = await _getDriveApi();
      final drive.File folderMetadata = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder';

      final folder = await driveApi.files.create(folderMetadata);
      return folder.id!;
    } catch (e) {
      print('Error creating folder in Google Drive: $e');
      rethrow;
    }
  }

  static Future<List<drive.File>> listFiles(String folderId) async {
    try {
      final driveApi = await _getDriveApi();
      final response = await driveApi.files.list(
        q: "'$folderId' in parents",
        spaces: 'drive',
      );
      return response.files ?? [];
    } catch (e) {
      print('Error listing files from Google Drive: $e');
      rethrow;
    }
  }
} 