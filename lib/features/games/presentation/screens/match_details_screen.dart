import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frenzy/core/providers/theme_provider.dart';
import 'package:frenzy/core/providers/auth_provider.dart';
import 'package:frenzy/core/widgets/common_app_bar.dart';
import 'package:frenzy/features/games/domain/models/match.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchDetailsScreen extends StatelessWidget {
  final Match match;

  const MatchDetailsScreen({
    super.key,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'Match Details',
        showThemeToggle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match Title
            Text(
              match.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // Match Description
            Text(
              match.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 24),

            // Match Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: match.status == 'active'
                    ? colorScheme.primary.withOpacity(0.1)
                    : colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                match.status.toUpperCase(),
                style: TextStyle(
                  color: match.status == 'active'
                      ? colorScheme.primary
                      : colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Participants
            Text(
              'Participants',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Participants List
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where(FieldPath.documentId, whereIn: match.participants)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  );
                }

                final participants = snapshot.data?.docs ?? [];

                if (participants.isEmpty) {
                  return Center(
                    child: Text(
                      'No participants yet',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final participant =
                        participants[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: participant['photoUrl'] != null
                            ? NetworkImage(participant['photoUrl'])
                            : null,
                        child: participant['photoUrl'] == null
                            ? Text(participant['name']?[0] ?? '?')
                            : null,
                      ),
                      title: Text(participant['name'] ?? 'Unknown User'),
                      subtitle: Text(participant['email'] ?? ''),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: match.status == 'active' && !match.isFull
          ? FloatingActionButton.extended(
              onPressed: () {
                // TODO: Join match
              },
              icon: const Icon(Icons.add),
              label: const Text('Join Match'),
            )
          : null,
    );
  }
}
