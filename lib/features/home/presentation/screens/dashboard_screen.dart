import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../games/domain/models/game.dart';
import 'package:provider/provider.dart';
import 'package:frenzy/core/providers/theme_provider.dart';
import 'package:frenzy/core/config/app_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    // Add a direct fetch of a game doc to debug field names
    // This is ONLY for debugging - remove after troubleshooting
    _debugCheckGame();

    // The Scaffold is provided by HomeScreen, so we just return the body content.
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('games')
          .where('isActive', isEqualTo: true)
          .orderBy('releaseDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // Print detailed debug info for every stream update
        debugPrint('====== DASHBOARD STREAM UPDATE ======');
        debugPrint('Stream connection state: ${snapshot.connectionState}');
        debugPrint('Has error: ${snapshot.hasError}');
        if (snapshot.hasError) {
          debugPrint('Error details: ${snapshot.error}');
          debugPrint('Error stack trace: ${snapshot.stackTrace}');
          return Center(
            child: Text('Error loading games: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('Dashboard Stream: Waiting for data...');
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        debugPrint('Has data: ${snapshot.hasData}');
        if (snapshot.hasData) {
          debugPrint('Docs count: ${snapshot.data?.docs.length}');
          if (snapshot.data!.docs.isNotEmpty) {
            // Log first doc to see what we're getting
            final firstDoc =
                snapshot.data!.docs.first.data() as Map<String, dynamic>;
            debugPrint('First doc: $firstDoc');
          }
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          debugPrint('Dashboard Stream: No active games found.');
          return const Center(
            child:
                Text('No active games available right now. Check back later!'),
          );
        }

        final games =
            snapshot.data!.docs.map((doc) => Game.fromFirestore(doc)).toList();
        debugPrint('Dashboard Stream: Found ${games.length} games.');

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            // Provide default values for potentially missing data
            final imageUrl = game.imageUrl;
            final title = game.title.isNotEmpty ? game.title : 'Untitled Game';
            final genre = game.genre.isNotEmpty ? game.genre : 'Unknown Genre';
            final rating = game.rating;

            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRouter.gameDetails,
                    arguments: game,
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint(
                                    'Error loading image for $title: $error');
                                return const Center(
                                  child: Icon(Icons.games,
                                      size: 50, color: Colors.grey),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            )
                          : const Center(
                              child: Icon(Icons.games,
                                  size: 50, color: Colors.grey),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title, // Use default value
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            genre, // Use default value
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                // Ensure rating is displayed correctly
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
    );
  }

  // Debug method to directly check a game document
  Future<void> _debugCheckGame() async {
    try {
      // Get all games without filters to see what's actually in the collection
      final snapshot =
          await FirebaseFirestore.instance.collection('games').get();
      debugPrint('=== DEBUG DIRECT CHECK ===');
      debugPrint(
          'Total games in collection (unfiltered): ${snapshot.docs.length}');

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('First game ID: ${doc.id}');
        debugPrint('Fields: ${data.keys.join(', ')}');

        // Check for isActive field specifically
        if (data.containsKey('isActive')) {
          debugPrint('isActive field exists: ${data['isActive']}');
          debugPrint('isActive field type: ${data['isActive'].runtimeType}');
        } else {
          // Check for spelling variations
          final possibleFieldNames = data.keys
              .where((key) =>
                  key.toLowerCase().contains('active') ||
                  key.toLowerCase().contains('enabled') ||
                  key.toLowerCase().contains('status'))
              .toList();

          if (possibleFieldNames.isNotEmpty) {
            debugPrint(
                'Possible isActive field alternatives: $possibleFieldNames');
            for (final field in possibleFieldNames) {
              debugPrint('$field value: ${data[field]}');
            }
          } else {
            debugPrint('No field similar to isActive found');
          }
        }

        // Check for title field
        if (data.containsKey('title')) {
          debugPrint('title field exists: ${data['title']}');
        } else if (data.containsKey('tittle')) {
          // Common typo
          debugPrint('tittle field exists instead of title: ${data['tittle']}');
        }
      } else {
        debugPrint('No games found at all in the collection!');
      }
    } catch (e) {
      debugPrint('Error in debug check: $e');
    }
  }
}
