import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:frenzy/core/widgets/admin_scaffold.dart';
import 'package:frenzy/core/widgets/common_app_bar.dart';
import '../../../../services/notification_service.dart';
import 'package:provider/provider.dart';

class GameManagementScreen extends StatefulWidget {
  const GameManagementScreen({super.key});

  @override
  State<GameManagementScreen> createState() => _GameManagementScreenState();
}

class _GameManagementScreenState extends State<GameManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  File? _imageFile;
  bool _isLoading = false;
  final _scrollController = ScrollController();
  String? _editingGameId;
  String? _existingImageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _existingImageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _existingImageUrl;
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('game_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      final gameData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_editingGameId != null) {
        await FirebaseFirestore.instance
            .collection('games')
            .doc(_editingGameId)
            .update(gameData);
      } else {
        await FirebaseFirestore.instance.collection('games').add({
          ...gameData,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingGameId != null
                  ? 'Game updated successfully'
                  : 'Game added successfully',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddEditGameDialog({
    String? gameId,
    Map<String, dynamic>? existingGame,
  }) async {
    final nameController = TextEditingController(text: existingGame?['name']);
    final descriptionController = TextEditingController(text: existingGame?['description']);
    String? imageUrl = existingGame?['imageUrl'];
    bool isActive = existingGame?['isActive'] ?? true;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingGame == null ? 'Add Game' : 'Edit Game'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Game Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              if (imageUrl != null)
                Image.network(
                  imageUrl,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Pick Image'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Active'),
                  const Spacer(),
                  Switch(
                    value: isActive,
                    onChanged: (value) => isActive = value,
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a game name')),
                );
                return;
              }
              Navigator.pop(context, {
                'name': nameController.text,
                'description': descriptionController.text,
                'imageUrl': imageUrl,
                'isActive': isActive,
              });
            },
            child: Text(existingGame == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        if (gameId == null) {
          // Add new game
          await FirebaseFirestore.instance.collection('games').add({
            ...result,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Update existing game
          await FirebaseFirestore.instance.collection('games').doc(gameId).update(result);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                gameId == null ? 'Game added successfully' : 'Game updated successfully',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _showDeleteConfirmation(String gameId, String gameName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Game'),
        content: Text('Are you sure you want to delete "$gameName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('games').doc(gameId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting game: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Game Management',
      scrollController: _scrollController,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditGameDialog(),
        child: const Icon(Icons.add),
      ),
      body: _buildGameList(),
    );
  }

  Widget _buildGameList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('games')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final games = snapshot.data?.docs ?? [];

        if (games.isEmpty) {
          return const Center(
            child: Text('No games found'),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final gameDoc = games[index];
            final gameData = gameDoc.data() as Map<String, dynamic>;
            final gameId = gameDoc.id;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: gameData['imageUrl'] != null
                      ? NetworkImage(gameData['imageUrl'])
                      : null,
                  child: gameData['imageUrl'] == null
                      ? const Icon(Icons.games)
                      : null,
                ),
                title: Text(
                  gameData['name'],
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gameData['description'] ?? 'No description'),
                    Text(
                      'Created: ${_formatDate(gameData['createdAt'])}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showAddEditGameDialog(
                        gameId: gameId,
                        existingGame: gameData,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(
                        gameId,
                        gameData['name'],
                      ),
                    ),
                    Switch(
                      value: gameData['isActive'] ?? true,
                      onChanged: (value) => _updateGameStatus(gameId, value),
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

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      return date.toDate().toString();
    } else if (date is DateTime) {
      return date.toString();
    } else {
      throw Exception('Unsupported date format');
    }
  }

  void _updateGameStatus(String gameId, bool value) async {
    try {
      await FirebaseFirestore.instance
          .collection('games')
          .doc(gameId)
          .update({'isActive': value});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Game ${value ? 'activated' : 'deactivated'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _addOrUpdateGame({
    required String name,
    required String description,
    required bool isActive,
    String? gameId,
    String? imageUrl,
  }) async {
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      
      if (gameId == null) {
        // Adding new game
        await FirebaseFirestore.instance.collection('games').add({
          'name': name,
          'description': description,
          'isActive': isActive,
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Send notification for new game
        await notificationService.sendNotificationToAllUsers(
          title: 'New Game Available!',
          body: 'Check out the new game: $name',
          type: 'game',
        );
      } else {
        // Updating existing game
        await FirebaseFirestore.instance.collection('games').doc(gameId).update({
          'name': name,
          'description': description,
          'isActive': isActive,
          if (imageUrl != null) 'imageUrl': imageUrl,
        });
        
        // Send notification for game update
        await notificationService.sendNotificationToAllUsers(
          title: 'Game Updated',
          body: 'The game $name has been updated',
          type: 'game',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(gameId == null ? 'Game added successfully' : 'Game updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
