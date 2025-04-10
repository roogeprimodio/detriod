import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../games/domain/models/match.dart';
import '../../../games/domain/models/game.dart';
import '../widgets/admin_nav_drawer.dart';

class AdminMatchesScreen extends StatelessWidget {
  const AdminMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Matches'),
      ),
      drawer: const AdminNavDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showMatchDialog(context);
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .orderBy('startTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final matches = snapshot.data?.docs
                  .map((doc) => Match.fromFirestore(doc))
                  .toList() ??
              [];

          if (matches.isEmpty) {
            return const Center(
              child: Text('No matches found. Create your first match!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(match.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(match.description),
                      const SizedBox(height: 4),
                      Text(
                        'Start: ${DateFormat('MMM dd, yyyy - hh:mm a').format(match.startTime)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${match.currentParticipants}/${match.maxParticipants}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(match.status),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              match.status,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showMatchDialog(context, match);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _showDeleteConfirmation(context, match);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Colors.blue;
      case 'live':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void _showDeleteConfirmation(BuildContext context, Match match) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${match.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              _deleteMatch(match.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${match.title} deleted')),
              );
            },
            child: const Text('DELETE'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMatch(String matchId) async {
    try {
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting match: $e');
    }
  }

  void _showMatchDialog(BuildContext context, [Match? existingMatch]) {
    final titleController =
        TextEditingController(text: existingMatch?.title ?? '');
    final descriptionController =
        TextEditingController(text: existingMatch?.description ?? '');
    final maxParticipantsController = TextEditingController(
        text: existingMatch != null
            ? existingMatch.maxParticipants.toString()
            : '10');

    DateTime selectedStartTime =
        existingMatch?.startTime ?? DateTime.now().add(const Duration(days: 1));
    String selectedStatus = existingMatch?.status ?? 'Upcoming';
    String? selectedGameId = existingMatch?.gameId;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existingMatch == null ? 'Add New Match' : 'Edit Match'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('games')
                        .where('isActive', isEqualTo: true)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      final games = snapshot.data?.docs
                              .map((doc) => Game.fromFirestore(doc))
                              .toList() ??
                          [];

                      if (games.isEmpty) {
                        return const Text(
                            'No active games available. Please add a game first.');
                      }

                      // Set default game if none selected
                      if (selectedGameId == null && games.isNotEmpty) {
                        selectedGameId = games.first.id;
                      }

                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Game'),
                        value: selectedGameId,
                        items: games.map((game) {
                          return DropdownMenuItem<String>(
                            value: game.id,
                            child: Text(game.title),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedGameId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a game';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  ListTile(
                    title: const Text('Start Time'),
                    subtitle: Text(
                      DateFormat('MMM dd, yyyy - hh:mm a')
                          .format(selectedStartTime),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedStartTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );

                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime:
                              TimeOfDay.fromDateTime(selectedStartTime),
                        );

                        if (time != null) {
                          setState(() {
                            selectedStartTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                  TextFormField(
                    controller: maxParticipantsController,
                    decoration:
                        const InputDecoration(labelText: 'Max Participants'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter max participants';
                      }
                      final count = int.tryParse(value);
                      if (count == null || count < 2) {
                        return 'Must be at least 2 participants';
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Status'),
                    value: selectedStatus,
                    items: ['Upcoming', 'Live', 'Completed', 'Cancelled']
                        .map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate() &&
                    selectedGameId != null) {
                  final title = titleController.text.trim();
                  final description = descriptionController.text.trim();
                  final maxParticipants =
                      int.parse(maxParticipantsController.text.trim());

                  if (existingMatch == null) {
                    _addMatch(
                      gameId: selectedGameId!,
                      title: title,
                      description: description,
                      startTime: selectedStartTime,
                      maxParticipants: maxParticipants,
                      status: selectedStatus,
                    );
                  } else {
                    _updateMatch(
                      existingMatch.id,
                      gameId: selectedGameId!,
                      title: title,
                      description: description,
                      startTime: selectedStartTime,
                      maxParticipants: maxParticipants,
                      status: selectedStatus,
                      currentParticipants: existingMatch.currentParticipants,
                    );
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(existingMatch == null ? 'ADD' : 'UPDATE'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addMatch({
    required String gameId,
    required String title,
    required String description,
    required DateTime startTime,
    required int maxParticipants,
    required String status,
  }) async {
    try {
      final now = DateTime.now();
      final match = Match(
        id: '',
        gameId: gameId,
        title: title,
        description: description,
        startTime: startTime,
        maxParticipants: maxParticipants,
        currentParticipants: 0,
        status: status,
        participants: const [],
        createdBy: 'admin',
        createdAt: now,
      );

      final docRef = FirebaseFirestore.instance.collection('matches').doc();
      final matchWithId = match.copyWith(id: docRef.id);
      await docRef.set(matchWithId.toMap());
    } catch (e) {
      debugPrint('Error adding match: $e');
    }
  }

  Future<void> _updateMatch(
    String id, {
    required String gameId,
    required String title,
    required String description,
    required DateTime startTime,
    required int maxParticipants,
    required String status,
    required int currentParticipants,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('matches').doc(id).update({
        'gameId': gameId,
        'title': title,
        'description': description,
        'startTime': startTime,
        'maxParticipants': maxParticipants,
        'status': status,
        'currentParticipants': currentParticipants,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating match: $e');
    }
  }
}
