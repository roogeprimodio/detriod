import 'package:flutter/material.dart';
import 'package:frenzy/features/home/presentation/widgets/notifications_popup.dart';
import 'package:frenzy/features/home/presentation/widgets/wallet_popup.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      actions: [
        const NotificationsPopup(),
        const WalletPopup(),
        if (actions != null) ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 