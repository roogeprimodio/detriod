import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frenzy/core/widgets/admin_scaffold.dart';
import 'dart:html' as html;
import 'dart:convert';

class DataExportScreen extends StatelessWidget {
  const DataExportScreen({super.key});

  Future<void> _exportUserData() async {
    try {
      final users = await FirebaseFirestore.instance.collection('users').get();
      final userProfiles =
          await FirebaseFirestore.instance.collection('userProfiles').get();

      // Combine user data with profiles
      final Map<String, Map<String, dynamic>> combinedData = {};
      
      for (final user in users.docs) {
        combinedData[user.id] = {
          'email': user.data()['email'] ?? '',
          'createdAt': user.data()['createdAt']?.toDate().toString() ?? '',
          'isAdmin': user.data()['isAdmin'] ?? false,
        };
      }

      for (final profile in userProfiles.docs) {
        if (combinedData.containsKey(profile.id)) {
          combinedData[profile.id]?.addAll({
            'username': profile.data()['username'] ?? '',
            'phoneNumber': profile.data()['phoneNumber'] ?? '',
            'country': profile.data()['country'] ?? '',
            'bio': profile.data()['bio'] ?? '',
          });
        }
      }

      // Convert to CSV
      final List<List<dynamic>> rows = [
        [
          'User ID',
          'Email',
          'Created At',
          'Is Admin',
          'Username',
          'Phone Number',
          'Country',
          'Bio'
        ],
      ];

      combinedData.forEach((userId, data) {
        rows.add([
          userId,
          data['email'],
          data['createdAt'],
          data['isAdmin'],
          data['username'],
          data['phoneNumber'],
          data['country'],
          data['bio'],
        ]);
      });

      final csvData = rows.map((row) => row.join(',')).join('\n');
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'user_data_${DateTime.now().toIso8601String()}.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Error exporting data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Data Export',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export User Data',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Download a CSV file containing all user data including profiles, registration dates, and contact information.',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _exportUserData,
                        icon: const Icon(Icons.download),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Export User Data'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Export Guide',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('User Data Export'),
                      subtitle: Text(
                        'Includes user profiles, contact information, and account details',
                      ),
                    ),
                    const ListTile(
                      leading: Icon(Icons.security),
                      title: Text('Data Security'),
                      subtitle: Text(
                        'Exported data is sensitive. Handle with care and follow data protection guidelines.',
                      ),
                    ),
                    const ListTile(
                      leading: Icon(Icons.format_list_bulleted),
                      title: Text('CSV Format'),
                      subtitle: Text(
                        'Data is exported in CSV format, compatible with Excel and other spreadsheet software.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
