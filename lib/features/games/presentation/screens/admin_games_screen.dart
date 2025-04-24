import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/game.dart';
import 'package:frenzy/core/widgets/common_app_bar.dart';

class AdminGamesScreen extends StatelessWidget {
  const AdminGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Manage Games',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGameDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('games')
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

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No games available. Add your first game!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final game = Game.fromFirestore(doc);
              return Dismissible(
                key: Key(game.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Game'),
                      content: Text('Are you sure you want to delete "${game.title}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('games')
                        .doc(game.id)
                        .delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${game.title} deleted successfully')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting game: $e')),
                    );
                  }
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(game.title),
                        subtitle: Text(game.description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                game.isActive ? Icons.visibility : Icons.visibility_off,
                                color: game.isActive ? Colors.green : Colors.grey,
                              ),
                              onPressed: () => _toggleGameStatus(context, game),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditGameDialog(context, game),
                            ),
                          ],
                        ),
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

  Future<void> _toggleGameStatus(BuildContext context, Game game) async {
    try {
      await FirebaseFirestore.instance
          .collection('games')
          .doc(game.id)
          .update({'isActive': !game.isActive});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${game.title} ${game.isActive ? 'disabled' : 'enabled'}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating game status: $e')),
        );
      }
    }
  }

  void _showAddGameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddEditGameDialog(),
    );
  }

  void _showEditGameDialog(BuildContext context, Game game) {
    showDialog(
      context: context,
      builder: (context) => AddEditGameDialog(game: game),
    );
  }
}

class AddEditGameDialog extends StatefulWidget {
  final Game? game;

  const AddEditGameDialog({super.key, this.game});

  @override
  AddEditGameDialogState createState() => AddEditGameDialogState();
}

class AddEditGameDialogState extends State<AddEditGameDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isActive = true;
  String _selectedCategory = 'Action';

  static const List<String> _categories = [
    'Action',
    'Adventure',
    'RPG',
    'Strategy',
    'Sports',
    'Racing',
    'Puzzle',
    'Shooter',
    'Fighting',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.game != null) {
      _titleController.text = widget.game!.title;
      _descriptionController.text = widget.game!.description;
      _imageUrlController.text = widget.game!.imageUrl;
      _isActive = widget.game!.isActive;
      _selectedCategory = widget.game!.categories.isNotEmpty
          ? widget.game!.categories.first
          : _categories.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final gameData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': _imageUrlController.text.trim().isEmpty
            ? 'https://via.placeholder.com/300x200?text=Game'
            : _imageUrlController.text.trim(),
        'categories': [_selectedCategory],
        'platforms': ['All'],
        'isActive': _isActive,
        'rating': 0.0,
        'totalRatings': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.game != null) {
        await FirebaseFirestore.instance
            .collection('games')
            .doc(widget.game!.id)
            .update(gameData);
      } else {
        gameData['createdAt'] = FieldValue.serverTimestamp();
        gameData['createdBy'] = 'admin';
        await FirebaseFirestore.instance.collection('games').add(gameData);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.game != null
                ? 'Game updated successfully'
                : 'Game added successfully'),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.game != null ? 'Edit Game' : 'Add New Game'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.trim().isEmpty == true ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value?.trim().isEmpty == true ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (Optional)',
                  hintText: 'Leave empty for default image',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
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
          onPressed: _submitForm,
          child: Text(widget.game != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
