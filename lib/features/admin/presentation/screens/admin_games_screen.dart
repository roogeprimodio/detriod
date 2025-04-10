import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../games/domain/models/game.dart';
import '../widgets/admin_nav_drawer.dart';

class AdminGamesScreen extends StatelessWidget {
  const AdminGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Games'),
      ),
      drawer: const AdminNavDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showGameDialog(context);
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
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
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final games = snapshot.data?.docs
                  .map((doc) => Game.fromFirestore(doc))
                  .toList() ??
              [];

          if (games.isEmpty) {
            return const Center(
              child: Text('No games found. Add your first game!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: game.imageUrl.isNotEmpty
                      ? Image.network(
                          game.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.games, size: 50);
                          },
                        )
                      : const Icon(Icons.games, size: 50),
                  title: Text(game.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(game.genre),
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(game.rating.toStringAsFixed(1)),
                          SizedBox(width: 12),
                          Icon(
                              game.isActive
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: 14,
                              color:
                                  game.isActive ? Colors.green : Colors.grey),
                          SizedBox(width: 4),
                          Text(game.isActive ? 'Active' : 'Inactive'),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showGameDialog(context, game);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _showDeleteConfirmation(context, game);
                        },
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

  void _showDeleteConfirmation(BuildContext context, Game game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${game.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              _deleteGame(game.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${game.title} deleted')),
              );
            },
            child: const Text('DELETE'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGame(String gameId) async {
    try {
      await FirebaseFirestore.instance.collection('games').doc(gameId).delete();
    } catch (e) {
      debugPrint('Error deleting game: $e');
    }
  }

  void _showGameDialog(BuildContext context, [Game? existingGame]) {
    final titleController =
        TextEditingController(text: existingGame?.title ?? '');
    final descriptionController =
        TextEditingController(text: existingGame?.description ?? '');
    final genreController =
        TextEditingController(text: existingGame?.genre ?? '');
    final imageUrlController =
        TextEditingController(text: existingGame?.imageUrl ?? '');
    final ratingController = TextEditingController(
        text: existingGame != null ? existingGame.rating.toString() : '0.0');
    bool isActive = existingGame?.isActive ?? true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingGame == null ? 'Add New Game' : 'Edit Game'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: genreController,
                  decoration: const InputDecoration(labelText: 'Genre'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a genre';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an image URL';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: ratingController,
                  decoration: const InputDecoration(labelText: 'Rating (0-5)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a rating';
                    }
                    final rating = double.tryParse(value);
                    if (rating == null || rating < 0 || rating > 5) {
                      return 'Rating must be between 0 and 5';
                    }
                    return null;
                  },
                ),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (value) {
                    isActive = value;
                    (context as Element).markNeedsBuild();
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final title = titleController.text.trim();
                final description = descriptionController.text.trim();
                final genre = genreController.text.trim();
                final imageUrl = imageUrlController.text.trim();
                final rating = double.parse(ratingController.text.trim());

                if (existingGame == null) {
                  _addGame(
                    title: title,
                    description: description,
                    genre: genre,
                    imageUrl: imageUrl,
                    rating: rating,
                    isActive: isActive,
                  );
                } else {
                  _updateGame(
                    existingGame.id,
                    title: title,
                    description: description,
                    genre: genre,
                    imageUrl: imageUrl,
                    rating: rating,
                    isActive: isActive,
                  );
                }
                Navigator.pop(context);
              }
            },
            child: Text(existingGame == null ? 'ADD' : 'UPDATE'),
          ),
        ],
      ),
    );
  }

  Future<void> _addGame({
    required String title,
    required String description,
    required String genre,
    required String imageUrl,
    required double rating,
    required bool isActive,
  }) async {
    try {
      final now = DateTime.now();
      final game = Game(
        id: '', // Empty ID will be replaced when saved
        title: title,
        description: description,
        genre: genre,
        imageUrl: imageUrl,
        rating: rating,
        isActive: isActive,
        releaseDate: now,
        createdBy: 'admin',
        createdAt: now,
      );

      final docRef = FirebaseFirestore.instance.collection('games').doc();
      final gameWithId = game.copyWith(id: docRef.id);
      await docRef.set(gameWithId.toMap());
    } catch (e) {
      debugPrint('Error adding game: $e');
    }
  }

  Future<void> _updateGame(
    String id, {
    required String title,
    required String description,
    required String genre,
    required String imageUrl,
    required double rating,
    required bool isActive,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('games').doc(id).update({
        'title': title,
        'description': description,
        'genre': genre,
        'imageUrl': imageUrl,
        'rating': rating,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating game: $e');
    }
  }
}
