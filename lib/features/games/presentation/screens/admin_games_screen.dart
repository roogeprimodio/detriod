import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/game.dart';
import '../widgets/game_card.dart';

class AdminGamesScreen extends StatelessWidget {
  const AdminGamesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Games'),
        elevation: 0,
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
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No games available. Add your first game!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final game = Game.fromFirestore(doc);
              return Dismissible(
                key: Key(game.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) => _confirmDelete(context, game),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                child: Stack(
                  children: [
                    GameCard(game: game),
                    Positioned(
                      top: 16,
                      right: 24,
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              game.isActive ? Icons.visibility : Icons.visibility_off,
                              color: game.isActive ? Colors.green : Colors.grey,
                            ),
                            onPressed: () => _toggleGameStatus(game),
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
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _toggleGameStatus(Game game) async {
    try {
      await FirebaseFirestore.instance
          .collection('games')
          .doc(game.id)
          .update({'isActive': !game.isActive});
    } catch (e) {
      debugPrint('Error toggling game status: $e');
    }
  }

  Future<bool> _confirmDelete(BuildContext context, Game game) async {
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
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          await FirebaseFirestore.instance
              .collection('games')
              .doc(game.id)
              .delete();
          return true;
        } catch (e) {
          debugPrint('Error deleting game: $e');
          return false;
        }
      }
      return false;
    });
  }

  void _showAddGameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const GameFormDialog(),
    );
  }

  void _showEditGameDialog(BuildContext context, Game game) {
    showDialog(
      context: context,
      builder: (context) => GameFormDialog(game: game),
    );
  }
}

class GameFormDialog extends StatefulWidget {
  final Game? game;

  const GameFormDialog({Key? key, this.game}) : super(key: key);

  @override
  _GameFormDialogState createState() => _GameFormDialogState();
}

class _GameFormDialogState extends State<GameFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _genreController;
  late TextEditingController _imageUrlController;
  late double _rating;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.game?.title ?? '');
    _descriptionController = TextEditingController(text: widget.game?.description ?? '');
    _genreController = TextEditingController(text: widget.game?.genre ?? '');
    _imageUrlController = TextEditingController(text: widget.game?.imageUrl ?? '');
    _rating = widget.game?.rating ?? 0.0;
    _isActive = widget.game?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _genreController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final gameData = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'genre': _genreController.text,
          'imageUrl': _imageUrlController.text,
          'rating': _rating,
          'isActive': _isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (widget.game != null) {
          // Update existing game
          await FirebaseFirestore.instance
              .collection('games')
              .doc(widget.game!.id)
              .update(gameData);
        } else {
          // Create new game
          gameData['createdAt'] = FieldValue.serverTimestamp();
          gameData['createdBy'] = 'admin';
          gameData['releaseDate'] = FieldValue.serverTimestamp();
          
          await FirebaseFirestore.instance
              .collection('games')
              .add(gameData);
        }

        if (mounted) Navigator.pop(context);
      } catch (e) {
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
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value?.isEmpty == true ? 'Title is required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _genreController,
                decoration: const InputDecoration(labelText: 'Genre'),
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Rating: '),
                  Expanded(
                    child: Slider(
                      value: _rating,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      label: _rating.toStringAsFixed(1),
                      onChanged: (value) => setState(() => _rating = value),
                    ),
                  ),
                ],
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
          onPressed: _submitForm,
          child: Text(widget.game != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
