import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frenzy/core/providers/theme_provider.dart';
import 'package:frenzy/core/providers/auth_provider.dart';
import 'package:frenzy/features/home/presentation/widgets/wallet_popup.dart';
import 'package:frenzy/core/models/user.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showThemeToggle;
  final List<Widget>? actions;

  const CommonAppBar({
    super.key,
    required this.title,
    this.showThemeToggle = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: colorScheme.surface,
      elevation: 0,
      actions: [
        // Wallet Button
        IconButton(
          icon: Icon(
            Icons.account_balance_wallet,
            color: colorScheme.primary,
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => WalletPopup(
                balance: authProvider.user?.walletBalance ?? 0.0,
                onAddFunds: () {
                  // TODO: Implement add funds
                  Navigator.pop(context);
                },
                onWithdraw: () {
                  // TODO: Implement withdraw
                  Navigator.pop(context);
                },
              ),
            );
          },
        ),
        // Theme Toggle
        if (showThemeToggle)
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: colorScheme.primary,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        // Additional Actions
        if (actions != null) ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
