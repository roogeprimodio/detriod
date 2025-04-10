import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frenzy/core/providers/theme_provider.dart';
import 'package:frenzy/core/providers/auth_provider.dart';
import 'package:frenzy/core/widgets/common_app_bar.dart';
import 'package:frenzy/features/games/domain/models/match.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserMatchesScreen extends StatelessWidget {
  const UserMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'My Matches',
        showThemeToggle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .where('participants', arrayContains: authProvider.user?.uid)
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

          final matches = snapshot.data?.docs ?? [];

          if (matches.isEmpty) {
            return Center(
              child: Text(
                'No matches found',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = Match.fromFirestore(matches[index]);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(match.title),
                  subtitle: Text(
                    '${match.currentParticipants}/${match.maxParticipants} Players',
                  ),
                  trailing: Text(
                    match.status,
                    style: TextStyle(
                      color: match.status == 'active'
                          ? colorScheme.primary
                          : colorScheme.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/match-details',
                      arguments: match,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
