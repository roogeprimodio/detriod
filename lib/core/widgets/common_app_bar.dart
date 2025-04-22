import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frenzy/core/providers/theme_provider.dart';
import 'package:frenzy/core/providers/auth_provider.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showThemeToggle;

  const CommonAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showThemeToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final List<Widget> appBarActions = [];
    final authProvider = context.watch<AuthProvider>();

    // Add wallet icon if user is authenticated
    if (authProvider.isAuthenticated) {
      appBarActions.add(
        IconButton(
          icon: const Icon(Icons.account_balance_wallet),
          onPressed: () {
            // TODO: Show wallet screen
          },
        ),
      );
    }

    // Add theme toggle if enabled
    if (showThemeToggle) {
      appBarActions.add(
        IconButton(
          icon: Icon(
            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
          ),
          onPressed: () => themeProvider.toggleTheme(),
        ),
      );
    }

    // Add custom actions if provided
    if (actions != null) {
      appBarActions.addAll(actions!);
    }

    return AppBar(
      title: Text(title),
      actions: appBarActions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
