import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/game.dart';
import '../widgets/match_list.dart';

class GameDetailsScreen extends StatelessWidget {
  final Game game;

  const GameDetailsScreen({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(game.title),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game banner/image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                game.bannerUrl ?? game.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading image: $error');
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error_outline, size: 50),
                    ),
                  );
                },
              ),
            ),

            // Game details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories and Platforms
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...game.categories.map((category) => Chip(
                            label: Text(category),
                            backgroundColor: colorScheme.primaryContainer,
                            labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                          )),
                      ...game.platforms.map((platform) => Chip(
                            label: Text(platform),
                            backgroundColor: colorScheme.secondaryContainer,
                            labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
                          )),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'About',
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    game.description,
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  // Game Info
                  Text(
                    'Game Information',
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.people,
                    label: 'Players',
                    value: game.maxPlayers != null
                        ? '${game.minPlayers ?? 1} - ${game.maxPlayers}'
                        : '${game.minPlayers ?? 1}+',
                  ),
                  if (game.minAge != null)
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Age Requirement',
                      value: '${game.minAge}+',
                    ),
                  if (game.requirements?.isNotEmpty == true)
                    _buildInfoRow(
                      icon: Icons.computer,
                      label: 'Requirements',
                      value: game.requirements!,
                    ),
                  if (game.prizing?.isNotEmpty == true)
                    _buildInfoRow(
                      icon: Icons.emoji_events,
                      label: 'Prizing',
                      value: game.prizing!,
                    ),
                  _buildInfoRow(
                    icon: Icons.star,
                    label: 'Rating',
                    value: game.totalRatings > 0
                        ? '${game.rating.toStringAsFixed(1)} (${game.totalRatings} ratings)'
                        : 'No ratings yet',
                  ),
                  _buildInfoRow(
                    icon: Icons.access_time,
                    label: 'Added',
                    value: DateFormat('MMM d, yyyy').format(game.createdAt),
                  ),
                  const SizedBox(height: 24),

                  // Matches section
                  Text(
                    'Available Matches',
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  MatchList(gameId: game.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
