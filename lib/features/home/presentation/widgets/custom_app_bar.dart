import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/notification_provider.dart';
import 'notifications_popup.dart';
import 'wallet_popup.dart';

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
        StreamBuilder<int>(
          stream: Provider.of<NotificationProvider>(context)
              .getUnreadCount(FirebaseAuth.instance.currentUser?.uid ?? ''),
          builder: (context, snapshot) {
            final hasUnread = snapshot.hasData && snapshot.data! > 0;
            return IconButton(
              tooltip: 'Notifications',
              icon: Stack(
                children: [
                  Icon(Icons.notifications_outlined,
                      color: hasUnread ? Theme.of(context).colorScheme.primary : null),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 400,
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                      ),
                      child: const NotificationsPopup(),
                    ),
                  ),
                );
              },
            );
          },
        ),
        const WalletPopup(),
        if (actions != null) ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 