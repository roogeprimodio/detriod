import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frenzy/features/games/domain/models/game.dart';
import 'package:frenzy/features/games/domain/models/match.dart';
import 'package:frenzy/features/games/presentation/screens/game_details_screen.dart';
import 'package:frenzy/core/providers/auth_provider.dart';
import 'package:frenzy/core/providers/theme_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  group('GameDetailsScreen Widget Tests', () {
    testWidgets('Displays matches and navigates to match details',
        (WidgetTester tester) async {
      // Mock game and match data
      final game = Game(
          id: 'game1',
          title: 'Test Game',
          genre: 'Action',
          description: 'A test game',
          imageUrl: '',
          rating: 4.5,
          isActive: true,
          releaseDate: DateTime.now(),
          createdBy: 'admin',
          createdAt: DateTime.now());
      final match = Match(
          id: 'match1',
          gameId: 'game1',
          title: 'Test Match',
          description: 'A test match',
          startTime: DateTime.now(),
          maxParticipants: 10,
          currentParticipants: 5,
          status: 'ongoing',
          participants: [],
          createdBy: 'admin',
          createdAt: DateTime.now());

      // Mock Firestore
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('matches').add(match.toMap());

      // Build the widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            home: GameDetailsScreen(game: game),
          ),
        ),
      );

      // Verify match is displayed
      expect(find.text('Test Match'), findsOneWidget);
      expect(find.text('5/10 Players'), findsOneWidget);

      // Tap on Join button
      await tester.tap(find.text('Join'));
      await tester.pumpAndSettle();

      // Verify navigation to match details
      expect(find.text('Match Details'), findsOneWidget);
      expect(find.text('Test Match'), findsOneWidget);
    });
  });
}
