import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frenzy/core/providers/theme_provider.dart';
import 'package:frenzy/core/providers/auth_provider.dart';
import 'package:frenzy/core/widgets/common_app_bar.dart';
import 'package:frenzy/core/widgets/common_bottom_nav.dart';
// Import placeholder screens (create these files if they don't exist)
import 'package:frenzy/features/home/presentation/screens/dashboard_screen.dart';
import 'package:frenzy/features/home/presentation/screens/live_view_screen.dart';
import 'package:frenzy/features/home/presentation/screens/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late TabController _tabController;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoadingNotifications = false;

  // Define the screens for the tabs
  final List<Widget> _screens = [
    const DashboardScreen(), // Screen containing the game grid
    const LiveViewScreen(), // Placeholder for Live View
    const ProfileScreen(), // Placeholder for Profile
  ];

  // Define the items for the bottom navigation
  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.live_tv_outlined),
      activeIcon: Icon(Icons.live_tv),
      label: 'Live',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _screens.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      } else if (_tabController.index != _currentIndex) {
        // Handle programmatic changes if needed, or ensure sync
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });

    // Load notifications
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      setState(() {
        _isLoadingNotifications = true;
      });

      try {
        final notificationsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .limit(20)
            .get();

        setState(() {
          _notifications =
              notificationsSnapshot.docs.map((doc) => doc.data()).toList();
        });
      } catch (e) {
        debugPrint('Error loading notifications: $e');
      } finally {
        setState(() {
          _isLoadingNotifications = false;
        });
      }
    }
  }

  void _showNotificationsPopup() {
    showDialog(
      context: context,
      builder: (context) => NotificationsPopup(
        notifications: _notifications,
        isLoading: _isLoadingNotifications,
        onRefresh: _loadNotifications,
      ),
    );
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Live View';
      case 2:
        return 'Profile';
      default:
        return 'Frenzy';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Use CommonAppBar with dynamic title
      appBar: CommonAppBar(
        title: _getTitleForIndex(_currentIndex),
        // Add notification icon to the app bar
        actions: [
          // Notifications Button
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  Icons.notifications,
                  color: colorScheme.primary,
                ),
                if (_notifications.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${_notifications.length}',
                        style: TextStyle(
                          color: colorScheme.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showNotificationsPopup,
          ),
        ],
      ),
      // Use TabBarView for the main content
      body: TabBarView(
        controller: _tabController,
        children: _screens,
      ),
      // Use CommonBottomNav
      bottomNavigationBar: CommonBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _tabController.animateTo(index);
          });
        },
        items: _navItems,
      ),
    );
  }
}

class NotificationsPopup extends StatefulWidget {
  final List<Map<String, dynamic>> notifications;
  final bool isLoading;
  final VoidCallback onRefresh;

  const NotificationsPopup({
    super.key,
    required this.notifications,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  State<NotificationsPopup> createState() => _NotificationsPopupState();
}

class _NotificationsPopupState extends State<NotificationsPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Notifications',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.reverse().then((_) {
                            Navigator.pop(context);
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Notifications List
                Expanded(
                  child: widget.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : widget.notifications.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_off,
                                      size: 48,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No notifications',
                                      style: TextStyle(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.7),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                widget.onRefresh();
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: widget.notifications.length,
                                itemBuilder: (context, index) {
                                  final notification =
                                      widget.notifications[index];
                                  final isRead =
                                      notification['isRead'] ?? false;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    color: isRead
                                        ? colorScheme.surface
                                        : colorScheme.primary.withOpacity(0.05),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: _getNotificationColor(
                                                notification['type'],
                                                colorScheme)
                                            .withOpacity(0.1),
                                        child: Icon(
                                          _getNotificationIcon(
                                              notification['type']),
                                          color: _getNotificationColor(
                                              notification['type'],
                                              colorScheme),
                                        ),
                                      ),
                                      title: Text(
                                        notification['title'] ?? 'Notification',
                                        style: TextStyle(
                                          fontWeight: isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(notification['message'] ?? ''),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(
                                                notification['timestamp']),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        // Mark as read
                                        if (!isRead) {
                                          _markAsRead(notification['id']);
                                        }

                                        // Handle notification action
                                        _handleNotificationAction(notification);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String? type, ColorScheme colorScheme) {
    switch (type) {
      case 'match':
        return colorScheme.primary;
      case 'achievement':
        return Colors.amber;
      case 'system':
        return Colors.blue;
      case 'error':
        return colorScheme.error;
      default:
        return colorScheme.primary;
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'match':
        return Icons.games;
      case 'achievement':
        return Icons.emoji_events;
      case 'system':
        return Icons.info;
      case 'error':
        return Icons.error;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown date';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return '${difference.inHours} hours ago';
      }
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _markAsRead(String? id) {
    if (id == null) return;

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(id)
        .update({'isRead': true});
  }

  void _handleNotificationAction(Map<String, dynamic> notification) {
    final type = notification['type'];
    final action = notification['action'];

    // Close the popup
    Navigator.pop(context);

    // Handle different notification types
    switch (type) {
      case 'match':
        // Navigate to match details
        if (action != null) {
          // Navigate to the appropriate screen based on the action
          // For example: Navigator.pushNamed(context, action);
        }
        break;
      case 'achievement':
        // Show achievement details
        break;
      case 'system':
        // Handle system notification
        break;
      default:
        // Default action
        break;
    }
  }
}
