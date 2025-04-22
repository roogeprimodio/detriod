// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frenzy/features/auth/presentation/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:frenzy/core/providers/auth_provider.dart';
import 'package:frenzy/core/providers/theme_provider.dart';
import 'package:frenzy/features/home/presentation/providers/user_profile_provider.dart';
import 'package:frenzy/features/home/presentation/screens/home_screen.dart';
import 'package:frenzy/features/home/presentation/screens/dashboard_screen.dart';
import 'package:frenzy/features/admin/presentation/screens/admin_dashboard.dart';
import 'package:frenzy/features/admin/presentation/screens/game_management_screen.dart';
import 'package:frenzy/features/admin/presentation/screens/match_management_screen.dart';
import 'package:frenzy/core/widgets/common_app_bar.dart';
import 'package:frenzy/core/widgets/common_bottom_nav.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('LoginScreen shows User and Admin tabs',
        (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthProvider()),
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider(create: (_) => UserProfileProvider()),
            ],
            child: const LoginScreen(),
          ),
        ),
      );

      // Verify that both tabs are present
      expect(find.text('User Login'), findsOneWidget);
      expect(find.text('Admin Login'), findsOneWidget);
    });

    testWidgets('Admin tab validates admin email format',
        (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthProvider()),
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider(create: (_) => UserProfileProvider()),
            ],
            child: const LoginScreen(),
          ),
        ),
      );

      // Switch to admin tab
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();

      // Enter non-admin email
      await tester.enterText(
          find.byKey(const Key('admin_email_field')), 'user@example.com');
      await tester.enterText(
          find.byKey(const Key('admin_password_field')), 'password123');
      await tester.tap(find.byKey(const Key('admin_login_button')));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Admin email must end with @admin.com'), findsOneWidget);
    });

    testWidgets('User tab prevents admin email login',
        (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthProvider()),
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider(create: (_) => UserProfileProvider()),
            ],
            child: const LoginScreen(),
          ),
        ),
      );

      // Enter admin email in user tab
      await tester.enterText(
          find.byKey(const Key('user_email_field')), 'admin@admin.com');
      await tester.enterText(
          find.byKey(const Key('user_password_field')), 'password123');
      await tester.tap(find.byKey(const Key('user_login_button')));
      await tester.pumpAndSettle();

      // Verify error message
      expect(
          find.text(
              'This is an admin email. Please use the admin tab to login.'),
          findsOneWidget);
    });
  });

  group('Home Screen Tests', () {
    testWidgets('HomeScreen displays structure with initial Dashboard tab',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Verify CommonAppBar is present with initial title
      expect(find.byType(CommonAppBar), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);

      // Verify CommonBottomNav is present
      expect(find.byType(CommonBottomNav), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify TabBarView is present
      expect(find.byType(TabBarView), findsOneWidget);

      // Verify the initial screen shown is DashboardScreen
      expect(find.byType(StreamBuilder<QuerySnapshot>), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('Live'));
      await tester.pumpAndSettle();
      expect(find.text('Live View'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);
    });
  });

  group('Dashboard Screen Tests', () {
    testWidgets('DashboardScreen initially shows loading indicator',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DashboardScreen()),
          ),
        ),
      );

      expect(find.byType(StreamBuilder<QuerySnapshot>), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Admin Dashboard Tests', () {
    testWidgets('Admin dashboard shows statistics and quick actions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const MaterialApp(
            home: AdminDashboard(),
          ),
        ),
      );

      // Verify app bar title
      expect(find.text('Admin Dashboard'), findsOneWidget);

      // Verify welcome text
      expect(find.text('Welcome, Admin'), findsOneWidget);

      // Verify statistics card
      expect(find.text('Platform Statistics'), findsOneWidget);

      // Verify quick actions
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Add New Game'), findsOneWidget);
      expect(find.text('Create Match'), findsOneWidget);
    });
  });

  group('Admin Games Screen Tests', () {
    testWidgets('Admin games screen shows game list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const MaterialApp(
            home: GameManagementScreen(),
          ),
        ),
      );

      // Verify app bar title
      expect(find.text('Manage Games'), findsOneWidget);

      // Verify add button exists
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Verify list view exists
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('Admin Matches Screen Tests', () {
    testWidgets('Admin matches screen shows match list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const MaterialApp(
            home: MatchManagementScreen(),
          ),
        ),
      );

      // Verify app bar title
      expect(find.text('Manage Matches'), findsOneWidget);

      // Verify add button exists
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Verify list view exists
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
