import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStatsCard extends StatelessWidget {
  const AdminStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Platform Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('games').snapshots(),
              builder: (context, gamesSnapshot) {
                if (gamesSnapshot.hasError) {
                  return _buildErrorWidget('Error loading games');
                }
                if (gamesSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingWidget();
                }

                final totalGames = gamesSnapshot.data?.docs.length ?? 0;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('matches')
                      .snapshots(),
                  builder: (context, matchesSnapshot) {
                    if (matchesSnapshot.hasError) {
                      return _buildErrorWidget('Error loading matches');
                    }
                    if (matchesSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return _buildLoadingWidget();
                    }

                    final totalMatches = matchesSnapshot.data?.docs.length ?? 0;
                    int activeMatches = 0;
                    try {
                      activeMatches = matchesSnapshot.data?.docs.where((doc) {
                            // Safely check if 'status' exists and is 'ongoing'
                            final data = doc.data() as Map<String, dynamic>?;
                            return data != null &&
                                data.containsKey('status') &&
                                data['status'] == 'ongoing';
                          }).length ??
                          0;
                    } catch (e) {
                      debugPrint('Error calculating active matches: $e');
                      // Handle potential errors during filtering
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          context,
                          'Total Games',
                          totalGames.toString(),
                          Icons.games,
                          Colors.blue,
                        ),
                        _buildStatItem(
                          context,
                          'Total Matches',
                          totalMatches.toString(),
                          Icons.emoji_events,
                          Colors.orange,
                        ),
                        _buildStatItem(
                          context,
                          'Active Matches',
                          activeMatches.toString(),
                          Icons.play_circle,
                          Colors.green,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          message,
          style:
              const TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
