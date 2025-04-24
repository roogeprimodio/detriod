import 'package:flutter/material.dart';
import '../../features/admin/presentation/screens/admin_dashboard.dart';
import '../../features/admin/presentation/screens/match_management_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/games/presentation/screens/game_details_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/games/domain/models/game.dart';

class AppRouter {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String adminDashboard = '/admin-dashboard';
  static const String adminMatches = '/admin-matches';
  static const String gameDetails = '/game-details';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      case adminMatches:
        return MaterialPageRoute(builder: (_) => const MatchManagementScreen());
      case gameDetails:
        final game = settings.arguments as Game;
        return MaterialPageRoute(
          builder: (_) => GameDetailsScreen(game: game),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
