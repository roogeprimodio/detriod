import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frenzy/core/providers/theme_provider.dart';
import 'package:frenzy/core/widgets/common_app_bar.dart';
import 'package:frenzy/features/games/domain/models/game.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GameDetailsScreen extends StatelessWidget {
  final Game game;

  const GameDetailsScreen({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CommonAppBar(
        title: game.title,
        showThemeToggle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game Banner
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                image: game.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(game.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: game.imageUrl.isEmpty
                  ? Center(
                      child: Icon(
                        Icons.games,
                        size: 64,
                        color: colorScheme.primary,
                      ),
                    )
                  : null,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Game Title
                  Text(
                    game.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Game Genre
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      game.genre,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Game Description
                  Text(
                    game.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Rating
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        game.rating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Active Matches Section
                  Text(
                    'Active Matches',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Matches List
                  StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('games')
                        .doc(game.id)
                        .collection('matches')
                        .where('status', isEqualTo: 'active')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading matches: ${snapshot.error}',
                            style: TextStyle(color: colorScheme.error),
                          ),
                        );
                      }

                      final matches = snapshot.data?.docs ?? [];

                      if (matches.isEmpty) {
                        return Center(
                          child: Text(
                            'No active matches',
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final match = matches[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(match['title'] ?? 'Untitled Match'),
                              subtitle: Text(
                                '${match['currentParticipants'] ?? 0}/${match['maxParticipants'] ?? 0} Players',
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  // TODO: Navigate to match details
                                },
                                child: const Text('Join'),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Show create match dialog
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Match'),
      ),
    );
  }
}
