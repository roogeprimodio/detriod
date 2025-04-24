import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frenzy/core/providers/theme_provider.dart';
import 'package:frenzy/core/providers/auth_provider.dart';
import 'package:frenzy/core/widgets/admin_scaffold.dart';
import 'package:frenzy/features/admin/presentation/screens/user_management_screen.dart';
import 'package:frenzy/features/admin/presentation/screens/game_management_screen.dart';
import 'package:frenzy/features/admin/presentation/screens/match_management_screen.dart';
import 'package:frenzy/features/admin/presentation/screens/reports_screen.dart';
import 'package:frenzy/features/admin/presentation/screens/notification_management_screen.dart';
import 'package:frenzy/features/admin/presentation/screens/stream_management_screen.dart';
import 'package:frenzy/features/admin/presentation/screens/data_export_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final themeProvider = context.watch<ThemeProvider>();

    return AdminScaffold(
      title: 'Admin Dashboard',
      actions: [
        IconButton(
          icon: Icon(
            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
          ),
          onPressed: () => themeProvider.toggleTheme(),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await context.read<AuthProvider>().signOut();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        ),
      ],
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section with Stats
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    user?.email ?? 'Admin',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildStatistics(),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Main Actions Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildActionCard(
                  context,
                  'Notifications',
                  Icons.notifications,
                  Colors.purple,
                  () => Navigator.pushNamed(context, '/notification-management'),
                ),
                _buildActionCard(
                  context,
                  'Live Streaming',
                  Icons.live_tv,
                  Colors.red,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StreamManagementScreen(),
                    ),
                  ),
                ),
                _buildActionCard(
                  context,
                  'Export Data',
                  Icons.download,
                  Colors.teal,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DataExportScreen(),
                    ),
                  ),
                ),
                _buildActionCard(
                  context,
                  'Game Management',
                  Icons.games,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GameManagementScreen(),
                    ),
                  ),
                ),
                _buildActionCard(
                  context,
                  'Match Management',
                  Icons.emoji_events,
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MatchManagementScreen(),
                    ),
                  ),
                ),
                _buildActionCard(
                  context,
                  'User Management',
                  Icons.people,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserManagementScreen(),
                    ),
                  ),
                ),
                _buildActionCard(
                  context,
                  'Reports & Analytics',
                  Icons.analytics,
                  Colors.purple,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportsScreen(),
                    ),
                  ),
                ),
                _buildActionCard(
                  context,
                  'Notifications',
                  Icons.notifications,
                  Colors.red,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationManagementScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Activity Section
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('games').snapshots(),
      builder: (context, gamesSnapshot) {
        if (gamesSnapshot.hasError) {
          return _buildErrorWidget('Error loading statistics');
        }

        if (gamesSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        }

        final totalGames = gamesSnapshot.data?.docs.length ?? 0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('matches').snapshots(),
          builder: (context, matchesSnapshot) {
            if (matchesSnapshot.hasError) {
              return _buildErrorWidget('Error loading statistics');
            }

            if (matchesSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingWidget();
            }

            final totalMatches = matchesSnapshot.data?.docs.length ?? 0;
            final activeMatches = matchesSnapshot.data?.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'ongoing';
            }).length ?? 0;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, usersSnapshot) {
                if (usersSnapshot.hasError) {
                  return _buildErrorWidget('Error loading statistics');
                }

                if (usersSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingWidget();
                }

                final totalUsers = usersSnapshot.data?.docs.length ?? 0;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildStatItem(
                        context,
                        Icons.games,
                        Colors.white,
                        'Total Games',
                        totalGames.toString(),
                        true,
                      ),
                      const SizedBox(width: 24),
                      _buildStatItem(
                        context,
                        Icons.emoji_events,
                        Colors.white,
                        'Total Matches',
                        totalMatches.toString(),
                        true,
                      ),
                      const SizedBox(width: 24),
                      _buildStatItem(
                        context,
                        Icons.play_circle,
                        Colors.white,
                        'Active Matches',
                        activeMatches.toString(),
                        true,
                      ),
                      const SizedBox(width: 24),
                      _buildStatItem(
                        context,
                        Icons.person,
                        Colors.white,
                        'Total Users',
                        totalUsers.toString(),
                        true,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget('Error loading recent activity');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        }

        final activities = snapshot.data?.docs ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportsScreen(),
                    ),
                  ),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index].data() as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.emoji_events,
                      color: Colors.orange,
                    ),
                    title: Text('New Match: ${activity['title'] ?? 'Untitled Match'}'),
                    subtitle: Text(_formatDate(activity['createdAt'])),
                    trailing: Text(
                      'Status: ${activity['status'] ?? 'Unknown'}',
                      style: TextStyle(
                        color: activity['status'] == 'ongoing' ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          message,
          style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    Color color,
    String label,
    String value,
    bool isLight,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isLight ? Colors.white24 : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isLight ? Colors.white : color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isLight ? Colors.white : null,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isLight ? Colors.white70 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'game':
        return Icons.games;
      case 'match':
        return Icons.emoji_events;
      case 'user':
        return Icons.person;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'game':
        return Colors.blue;
      case 'match':
        return Colors.orange;
      case 'user':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Invalid date';
  }
}
