import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/game.dart';
import '../widgets/game_card.dart';

class GamesListScreen extends StatelessWidget {
  const GamesListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('games')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Error loading games: ${snapshot.error}');
            return Center(
              child: Text(
                'Error loading games. Please try again.',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allGames = snapshot.data?.docs ?? [];
          debugPrint('Total games found: ${allGames.length}');

          if (allGames.isEmpty) {
            return const Center(
              child: Text('No active games available'),
            );
          }

          // Convert to Game objects and sort by creation date
          final games = allGames.map((doc) {
            try {
              return Game.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing game ${doc.id}: $e');
              return null;
            }
          }).where((game) => game != null).toList();

          games.sort((a, b) => b!.createdAt.compareTo(a!.createdAt));

          debugPrint('Parsed games: ${games.length}');

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: games.length,
            itemBuilder: (context, index) {
              return GameCard(game: games[index]!);
            },
          );
        },
      ),
    );
  }
}
