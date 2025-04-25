import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/widgets/loading_indicator.dart';
import 'package:frenzy/core/widgets/admin_scaffold.dart';
import 'package:frenzy/core/widgets/common_app_bar.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getUserData(Map<String, dynamic> userData) {
    // Debug print to see raw user data
    debugPrint('Raw user data: $userData');

    // Determine role based on available fields
    String role;
    if (userData['role'] != null) {
      role = userData['role'].toString().toLowerCase();
    } else if (userData['isAdmin'] == true) {
      role = 'admin';
    } else {
      role = 'player';
    }

    // Get name from various possible fields
    String name = userData['displayName'] ?? 
                 userData['name'] ?? 
                 userData['username'] ?? 
                 'Unknown User';

    // Get email from various possible fields
    String email = userData['email'] ?? 'No email';

    // Get profile image from various possible fields
    String? profileImage = userData['photoURL'] ?? 
                          userData['profileImage'] ?? 
                          userData['photoUrl'] ?? 
                          userData['profileImageUrl'];

    // Get UID from various possible fields
    String uid = userData['uid'] ?? 
                userData['id'] ?? 
                '';

    // Get wallet balance
    double walletBalance = (userData['walletBalance'] ?? 0).toDouble();

    return {
      'name': name,
      'email': email,
      'role': role,
      'isActive': userData['isActive'] ?? true,
      'createdAt': userData['createdAt'] ?? Timestamp.now(),
      'lastLogin': userData['lastLogin'] ?? Timestamp.now(),
      'profileImage': profileImage,
      'uid': uid,
      'walletBalance': walletBalance,
    };
  }

  Future<void> _showUserDetails(Map<String, dynamic> userData) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: userData['profileImage'] != null
                          ? NetworkImage(userData['profileImage'])
                          : null,
                      child: userData['profileImage'] == null
                          ? Text(userData['name'][0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['name'],
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            userData['email'],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow('User ID', userData['uid']),
                _buildDetailRow('Role', userData['role'].toString().toUpperCase()),
                _buildDetailRow('Status', userData['isActive'] ? 'Active' : 'Inactive'),
                _buildDetailRow('Joined', _formatDate(userData['createdAt'])),
                _buildDetailRow('Last Login', _formatDate(userData['lastLogin'])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': newRole,
        'isAdmin': newRole == 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User role updated to $newRole')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating role: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateUserStatus(String userId, bool isActive) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${isActive ? 'activated' : 'deactivated'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildUserList(String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? [];
        
        // Debug print to see all users
        for (var doc in users) {
          debugPrint('Firestore User: ${doc.data()}');
        }

        final filteredUsers = users.where((doc) {
          final userData = doc.data() as Map<String, dynamic>;
          final processedData = _getUserData(userData);
          
          // Debug print for each user's role determination
          debugPrint('Processing user: ${processedData['name']}');
          debugPrint('Raw role: ${userData['role']}');
          debugPrint('Raw isAdmin: ${userData['isAdmin']}');
          debugPrint('Processed role: ${processedData['role']}');
          
          return processedData['role'] == role;
        }).toList();

        // Debug print to see how many users we're filtering
        debugPrint('Total users: ${users.length}, Filtered users: ${filteredUsers.length}');

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  role == 'admin' ? Icons.admin_panel_settings : Icons.people,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${role}s found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final userDoc = filteredUsers[index];
            final userData = _getUserData(userDoc.data() as Map<String, dynamic>);
            final userId = userDoc.id;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: userData['profileImage'] != null
                      ? NetworkImage(userData['profileImage'])
                      : null,
                  child: userData['profileImage'] == null
                      ? Text(userData['name'][0].toUpperCase())
                      : null,
                ),
                title: Text(
                  userData['name'],
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userData['email']),
                    Text(
                      'Joined: ${_formatDate(userData['createdAt'])}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () => _showUserDetails(userData),
                    ),
                    if (role == 'player')
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'admin',
                            child: Text('Make Admin'),
                          ),
                        ],
                        onSelected: (value) => _updateUserRole(userId, value),
                      ),
                    Switch(
                      value: userData['isActive'],
                      onChanged: (value) => _updateUserStatus(userId, value),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'User Management',
      scrollController: _scrollController,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Players'),
              Tab(text: 'Admins'),
            ],
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList('player'),
                _buildUserList('admin'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
