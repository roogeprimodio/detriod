import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_profile_provider.dart';
import 'package:frenzy/core/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String email;

  const ProfileScreen({Key? key, required this.userId, required this.email}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Colors.blue;
      case 'live':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<UserProfileProvider>();
      provider.listenToUserProfile(widget.userId);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _updateControllers(profile) {
    _nameController.text = profile.name;
    _usernameController.text = profile.username;
    _bioController.text = profile.bio;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProfileProvider>();
    final profile = provider.profile;
    final isLoading = provider.isLoading;
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              provider.createUserProfile(widget.userId, widget.email);
            },
            child: const Text('Create Profile'),
          ),
        ),
      );
    }

    // Update controllers when profile changes
    if (!_isEditing) {
      _updateControllers(profile);
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with edit and logout buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (profile.isAdmin)
                  IconButton(
                    icon: const Icon(Icons.admin_panel_settings),
                    onPressed: () {
                      // TODO: Navigate to admin settings
                    },
                  ),
                const Spacer(),
                IconButton(
                  icon: Icon(_isEditing ? Icons.close : Icons.edit),
                  onPressed: () {
                    setState(() {
                      if (_isEditing) {
                        _updateControllers(profile);
                      }
                      _isEditing = !_isEditing;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    context.read<AuthProvider>().signOut();
                  },
                ),
              ],
            ),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.2),
                        width: 4,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundImage: NetworkImage(profile.profileImageUrl),
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.camera_alt,
                            color: colorScheme.onPrimary,
                            size: 20,
                          ),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 512,
                              maxHeight: 512,
                              imageQuality: 75,
                            );
                            
                            if (image != null) {
                              await provider.updateProfileImage(widget.userId, image.path);
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Name',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Username',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.alternate_email, color: colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              enabled: _isEditing,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Bio',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined, color: colorScheme.primary),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    provider.updateProfile(
                      userId: widget.userId,
                      name: _nameController.text,
                      username: _usernameController.text,
                      bio: _bioController.text,
                    );
                    setState(() => _isEditing = false);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                ),
              ),
            ],
            const SizedBox(height: 32),
            const Row(
              children: [
                Icon(Icons.sports_esports),
                SizedBox(width: 8),
                Text(
                  'Registered Matches',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('matches')
                  .where('registeredUsers', arrayContains: widget.userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final matches = snapshot.data!.docs;

                if (matches.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: const Text('No registered matches yet'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(match['title'] ?? 'Untitled Match'),
                        subtitle: Text(
                          'Game: ${match['gameName'] ?? 'Unknown'} • '
                          'Date: ${match['date'] != null ? (match['date'] as Timestamp).toDate().toString().split(' ')[0] : 'TBD'}',
                        ),
                        trailing: match['status'] != null
                            ? Chip(
                                label: Text(
                                  match['status'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: _getStatusColor(match['status']),
                              )
                            : null,
                        onTap: () {
                          // TODO: Navigate to match details
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
