import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/widgets/loading_indicator.dart';

class GameManagementScreen extends StatefulWidget {
  const GameManagementScreen({super.key});

  @override
  State<GameManagementScreen> createState() => _GameManagementScreenState();
}

class _GameManagementScreenState extends State<GameManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bannerUrlController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _minPlayersController = TextEditingController();
  final _maxPlayersController = TextEditingController();
  final _minAgeController = TextEditingController();
  final _prizingController = TextEditingController();
  bool _isActive = true;

  List<String> _selectedCategories = [];
  List<String> _selectedPlatforms = [];

  final List<String> _availableCategories = [
    'Action',
    'Adventure',
    'RPG',
    'Strategy',
    'Sports',
    'Racing',
    'Fighting',
    'Battle Royale',
    'MOBA',
    'FPS',
    'Card Game',
  ];

  final List<String> _availablePlatforms = [
    'PC',
    'PlayStation',
    'Xbox',
    'Nintendo Switch',
    'Mobile',
    'Browser',
  ];

  void _showAddGameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Game'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Title is required' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Description is required' : null,
                ),
                const SizedBox(height: 16),
                const Text('Categories:'),
                Wrap(
                  spacing: 8,
                  children: _availableCategories.map((category) {
                    return FilterChip(
                      label: Text(category),
                      selected: _selectedCategories.contains(category),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.add(category);
                          } else {
                            _selectedCategories.remove(category);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Image URL is required' : null,
                ),
                const SizedBox(height: 16),
                const Text('Platforms:'),
                Wrap(
                  spacing: 8,
                  children: _availablePlatforms.map((platform) {
                    return FilterChip(
                      label: Text(platform),
                      selected: _selectedPlatforms.contains(platform),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedPlatforms.add(platform);
                          } else {
                            _selectedPlatforms.remove(platform);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                SwitchListTile(
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addGame,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addGame() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedPlatforms.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one platform'),
          ),
        );
        return;
      }

      if (_selectedCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one category'),
          ),
        );
        return;
      }

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        await FirebaseFirestore.instance.collection('games').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'bannerUrl': _bannerUrlController.text,
          'imageUrl': _imageUrlController.text,
          'requirements': _requirementsController.text,
          'minPlayers': int.parse(_minPlayersController.text),
          'maxPlayers': int.parse(_maxPlayersController.text),
          'minAge': int.parse(_minAgeController.text),
          'prizing': _prizingController.text,
          'categories': _selectedCategories,
          'platforms': _selectedPlatforms,
          'isActive': _isActive,
          'createdBy': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game added successfully')),
          );
          _resetForm();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding game: $e')),
          );
        }
      }
    }
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _bannerUrlController.clear();
    _imageUrlController.clear();
    _requirementsController.clear();
    _minPlayersController.clear();
    _maxPlayersController.clear();
    _minAgeController.clear();
    _prizingController.clear();
    setState(() {
      _selectedCategories = [];
      _selectedPlatforms = [];
      _isActive = true;
    });
  }

  void _editGame(String gameId, Map<String, dynamic> gameData) {
    _titleController.text = gameData['title'] ?? '';
    _descriptionController.text = gameData['description'] ?? '';
    _selectedCategories = List<String>.from(gameData['categories'] ?? []);
    _imageUrlController.text = gameData['imageUrl'] ?? '';
    _bannerUrlController.text = gameData['bannerUrl'] ?? '';
    _requirementsController.text = gameData['requirements'] ?? '';
    _selectedPlatforms = List<String>.from(gameData['platforms'] ?? []);
    _isActive = gameData['isActive'] ?? true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Game'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Title is required' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Description is required' : null,
                ),
                const SizedBox(height: 16),
                const Text('Categories:'),
                Wrap(
                  spacing: 8,
                  children: _availableCategories.map((category) {
                    return FilterChip(
                      label: Text(category),
                      selected: _selectedCategories.contains(category),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.add(category);
                          } else {
                            _selectedCategories.remove(category);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Image URL is required' : null,
                ),
                const SizedBox(height: 16),
                const Text('Platforms:'),
                Wrap(
                  spacing: 8,
                  children: _availablePlatforms.map((platform) {
                    return FilterChip(
                      label: Text(platform),
                      selected: _selectedPlatforms.contains(platform),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedPlatforms.add(platform);
                          } else {
                            _selectedPlatforms.remove(platform);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                SwitchListTile(
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateGame(gameId),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _updateGame(String gameId) async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedPlatforms.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one platform')),
        );
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('games').doc(gameId).update({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'categories': _selectedCategories,
          'imageUrl': _imageUrlController.text,
          'bannerUrl': _bannerUrlController.text,
          'requirements': _requirementsController.text,
          'platforms': _selectedPlatforms,
          'isActive': _isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game updated successfully')),
          );
          _resetForm();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating game: $e')),
          );
        }
      }
    }
  }

  void _deleteGame(String gameId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Game'),
        content: const Text('Are you sure you want to delete this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
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
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _bannerUrlController.dispose();
    _imageUrlController.dispose();
    _requirementsController.dispose();
    _minPlayersController.dispose();
    _maxPlayersController.dispose();
    _minAgeController.dispose();
    _prizingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Management'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('games')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const LoadingIndicator();
          }

          final games = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              final gameData = game.data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(gameData['imageUrl'] ?? ''),
                  ),
                  title: Text(gameData['title'] ?? 'Untitled Game'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Categories: ${(gameData['categories'] as List?)?.join(', ') ?? 'None'}'),
                      Text('Platforms: ${(gameData['platforms'] as List?)?.join(', ') ?? 'None'}'),
                      Text('Players: ${gameData['minPlayers'] ?? 0} - ${gameData['maxPlayers'] ?? 0}'),
                      Text('Min Age: ${gameData['minAge'] ?? 'N/A'}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editGame(game.id, gameData),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteGame(game.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGameDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
