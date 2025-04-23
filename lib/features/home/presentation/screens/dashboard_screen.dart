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

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('games')
          .where('isActive', isEqualTo: true)
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
        final docs = snapshot.data?.docs ?? [];
        debugPrint('Docs count: ${docs.length}');

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_esports_outlined,
                  size: 64,
                  color: colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No active games available',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for new games',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        final games = docs.map((doc) {
          debugPrint('Processing game doc: ${doc.id}');
          try {
            return Game.fromFirestore(doc);
          } catch (e) {
            debugPrint('Error parsing game ${doc.id}: $e');
            return null;
          }
        }).where((game) => game != null).cast<Game>().toList();

        debugPrint('Successfully parsed ${games.length} games');

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
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  debugPrint('Navigating to game details: ${game.id}');
                  Navigator.pushNamed(
                    context,
                    AppRouter.gameDetails,
                    arguments: game,
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Game image
                    Expanded(
                      flex: 3,
                      child: Image.network(
                        game.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error loading image for game ${game.id}: $error');
                          return Container(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 32,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                          );
                        },
                      ),
                    ),

                    // Game info
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              game.title,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),

                            // Categories
                            if (game.categories.isNotEmpty)
                              Text(
                                game.categories.first,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                            const Spacer(),

                            // Players and rating
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Players
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      game.maxPlayers != null
                                          ? '${game.minPlayers ?? 1}-${game.maxPlayers}'
                                          : '${game.minPlayers ?? 1}+',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),

                                // Rating
                                if (game.totalRatings > 0)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        game.rating.toStringAsFixed(1),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
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
}
