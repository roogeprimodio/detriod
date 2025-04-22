import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:html' show window;
import 'package:frenzy/core/providers/auth_provider.dart';
import 'package:frenzy/core/providers/theme_provider.dart';
import 'package:frenzy/features/home/presentation/providers/user_profile_provider.dart';
import 'package:frenzy/features/auth/presentation/screens/login_screen.dart';
import 'package:frenzy/features/home/presentation/screens/home_screen.dart';
import 'package:frenzy/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:frenzy/core/config/firebase_options.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Initializing Firebase...');

    // Initialize Firebase with error handling
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Firebase initialization timed out');
      },
    );

    debugPrint('Firebase initialized successfully');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('Error initializing Firebase: $e');
    debugPrint('Stack trace: $stackTrace');

    // Show error screen with retry button
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error initializing Firebase:\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Reload the page to retry initialization
                    window.location.reload();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Frenzy',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.isLoading) {
                  debugPrint('Auth state: Loading');
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!authProvider.isAuthenticated) {
                  debugPrint('Auth state: Not Authenticated -> LoginScreen');
                  return const LoginScreen();
                }

                // If authenticated, check admin status directly from AuthProvider
                if (authProvider.isAdmin) {
                  debugPrint(
                      'Auth state: Authenticated, isAdmin=true -> AdminDashboardScreen');
                  return const AdminDashboardScreen();
                } else {
                  debugPrint(
                      'Auth state: Authenticated, isAdmin=false -> HomeScreen');
                  return const HomeScreen();
                }
              },
            ),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/admin': (context) => const AdminDashboardScreen(),
            },
          );
        },
      ),
    );
  }
}
