import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/widgets/loading_indicator.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  void _toggleUserRole(String userId, bool currentIsAdmin) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isAdmin': !currentIsAdmin,
      });
      
    } catch (e) {
      debugPrint('Error toggling user role: $e');
    }
  }

  void _toggleUserStatus(String userId, bool currentIsActive) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isActive': !currentIsActive,
      });
    } catch (e) {
      debugPrint('Error toggling user status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const LoadingIndicator();
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userData = user.data() as Map<String, dynamic>;
              final isAdmin = userData['isAdmin'] ?? false;
              final isActive = userData['isActive'] ?? true;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(userData['photoUrl'] ?? ''),
                    child: userData['photoUrl'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(userData['displayName'] ?? 'Anonymous'),
                  subtitle: Text(userData['email'] ?? 'No email'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: isActive,
                        onChanged: (value) => _toggleUserStatus(user.id, isActive),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          isAdmin ? Icons.admin_panel_settings : Icons.person,
                          color: isAdmin ? Colors.blue : null,
                        ),
                        onPressed: () => _toggleUserRole(user.id, isAdmin),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
