import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/widgets/loading_indicator.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _periods = ['Daily', 'Weekly', 'Monthly'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _periods.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _periods.map((period) => Tab(text: period)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _periods.map((period) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('matches')
                .where('status', isEqualTo: 'completed')
                .orderBy('completedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const LoadingIndicator();
              }

              final matches = snapshot.data!.docs;
              int totalMatches = matches.length;
              double totalRevenue = matches.fold(
                0,
                (sum, match) {
                  final entryFee = (match.data() as Map)['entryFee'];
                  return sum + (entryFee is num ? entryFee.toDouble() : 0);
                },
              );
              int totalPlayers = matches.fold(
                0,
                (sum, match) {
                  final players = (match.data() as Map)['registeredPlayers'] as List?;
                  return sum + (players?.length ?? 0);
                },
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$period Overview',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildStatCard(
                          'Total Matches',
                          totalMatches.toString(),
                          Icons.sports_esports,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Total Revenue',
                          '\$${totalRevenue.toStringAsFixed(2)}',
                          Icons.attach_money,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Total Players',
                          totalPlayers.toString(),
                          Icons.people,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Avg. Players/Match',
                          (totalPlayers / totalMatches).toStringAsFixed(1),
                          Icons.analytics,
                          Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Recent Matches',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: matches.length.clamp(0, 5),
                      itemBuilder: (context, index) {
                        final match = matches[index].data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(match['title'] ?? 'Untitled Match'),
                          subtitle: Text(
                            'Entry Fee: \$${match['entryFee']?.toString() ?? '0'}\n'
                            'Players: ${(match['registeredPlayers'] as List?)?.length ?? 0}',
                          ),
                          trailing: Text(
                            'Revenue: \$${(match['entryFee'] ?? 0) * ((match['registeredPlayers'] as List?)?.length ?? 0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
