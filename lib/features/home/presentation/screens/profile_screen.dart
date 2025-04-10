import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frenzy/core/providers/theme_provider.dart';
import 'package:frenzy/core/providers/auth_provider.dart';
import 'package:frenzy/features/home/presentation/providers/user_profile_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frenzy/core/config/app_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _gameUidController = TextEditingController();
  bool _isEditing = false;
  List<Map<String, dynamic>> _gameHistory = [];
  bool _isLoadingHistory = false;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoadingNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadGameHistory();
    _loadNotifications();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _gameUidController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      await context.read<UserProfileProvider>().loadProfile(user.uid);
      final profile = context.read<UserProfileProvider>().profile;
      if (profile != null) {
        _nameController.text = profile.name;
        _bioController.text = profile.bio;
      }

      // Load game UID from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data()!.containsKey('gameUid')) {
        _gameUidController.text = userDoc.data()!['gameUid'] ?? '';
      }
    }
  }

  Future<void> _loadGameHistory() async {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      setState(() {
        _isLoadingHistory = true;
      });

      try {
        final historySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('gameHistory')
            .orderBy('timestamp', descending: true)
            .limit(10)
            .get();

        setState(() {
          _gameHistory = historySnapshot.docs.map((doc) => doc.data()).toList();
        });
      } catch (e) {
        debugPrint('Error loading game history: $e');
      } finally {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    await context.read<UserProfileProvider>().updateProfile(
          name: _nameController.text.trim(),
          bio: _bioController.text.trim(),
        );

    // Update game UID
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'gameUid': _gameUidController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      setState(() => _isEditing = false);
    }
  }

  Future<void> _logout() async {
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signOut();

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.login);
      }
    } catch (e) {
      debugPrint('Error logging out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    final user = context.watch<AuthProvider>().user;
    final profileProvider = context.watch<UserProfileProvider>();
    final profile = profileProvider.profile;
    final isLoading = profileProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _nameController.text = profile?.name ?? '';
                  _bioController.text = profile?.bio ?? '';
                });
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Profile Header
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary.withOpacity(0.8),
                              colorScheme.primary.withOpacity(0.4),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Profile Image
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.onPrimary.withOpacity(0.2),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.shadow.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: profile?.profileImageUrl ??
                                      'https://drive.google.com/uc?export=view&id=YOUR_DEFAULT_PROFILE_IMAGE_ID',
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    child: Icon(
                                      Icons.person,
                                      size: 48,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // User Email
                            Text(
                              user?.email ?? 'User',
                              style: TextStyle(
                                fontSize: 18,
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Profile Form
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Name Field
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: TextFormField(
                                controller: _nameController,
                                enabled: _isEditing,
                                decoration: InputDecoration(
                                  labelText: 'Name',
                                  prefixIcon: Icon(Icons.person_outline,
                                      color: colorScheme.primary),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                validator: (value) {
                                  if (_isEditing &&
                                      (value == null || value.isEmpty)) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Bio Field
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: TextFormField(
                                controller: _bioController,
                                enabled: _isEditing,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Bio',
                                  prefixIcon: Icon(Icons.description_outlined,
                                      color: colorScheme.primary),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Game UID Field
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: TextFormField(
                                controller: _gameUidController,
                                enabled: _isEditing,
                                decoration: InputDecoration(
                                  labelText: 'Game UID',
                                  hintText: 'Enter your game ID',
                                  prefixIcon: Icon(Icons.games,
                                      color: colorScheme.primary),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Save Button
                            if (_isEditing)
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 1000),
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: child,
                                  );
                                },
                                child: SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed:
                                        isLoading ? null : _updateProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 5,
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'Save Changes',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Game History Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Game History',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _isLoadingHistory
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : _gameHistory.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(
                                          'No game history yet',
                                          style: TextStyle(
                                            color: colorScheme.onSurface
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: _gameHistory.length,
                                      itemBuilder: (context, index) {
                                        final game = _gameHistory[index];
                                        return Card(
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: colorScheme
                                                  .primary
                                                  .withOpacity(0.1),
                                              child: Icon(
                                                Icons.games,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                            title: Text(game['gameName'] ??
                                                'Unknown Game'),
                                            subtitle: Text(
                                              'Played on: ${_formatDate(game['timestamp'])}',
                                            ),
                                            trailing: Text(
                                              'Score: ${game['score'] ?? 'N/A'}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Logout Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.error,
                            foregroundColor: colorScheme.onError,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown date';

    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
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
