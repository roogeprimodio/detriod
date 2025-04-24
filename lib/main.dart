import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'core/providers/auth_provider.dart' as app_auth;
import 'core/providers/theme_provider.dart';
import 'core/providers/notification_provider.dart';
import 'services/notification_service.dart';
import 'features/home/presentation/providers/user_profile_provider.dart';
import 'core/config/firebase_options.dart';
import 'core/config/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with special web configuration
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set auth persistence
  await firebase_auth.FirebaseAuth.instance.setPersistence(
    firebase_auth.Persistence.LOCAL,
  ).catchError((e) {
    debugPrint('Failed to set auth persistence: $e');
  });

  // Check for existing user
  final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    debugPrint('Found existing user: ${currentUser.email}');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        Provider<NotificationService>(
          create: (_) => NotificationService()..initialize(),
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(context.read<NotificationService>()),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Frenzy',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.theme.copyWith(
              iconTheme: IconThemeData(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: AppRouter.login,
            onGenerateRoute: AppRouter.generateRoute,
          );
        },
      ),
    );
  }
}
