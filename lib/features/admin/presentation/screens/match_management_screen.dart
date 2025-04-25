import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/models/match.dart';
import '../../../../services/notification_service.dart';
import 'package:provider/provider.dart';

class MatchManagementScreen extends StatefulWidget {
  const MatchManagementScreen({super.key});

  @override
  State<MatchManagementScreen> createState() => _MatchManagementScreenState();
}

class _MatchManagementScreenState extends State<MatchManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedGameId;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rulesController = TextEditingController();
  final _entryFeeController = TextEditingController();
  final _prizePoolController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _streamUrlController = TextEditingController();
  final _discordUrlController = TextEditingController();
  final _passwordController = TextEditingController();

  DateTime _startTime = DateTime.now().add(const Duration(days: 1));
  DateTime _endTime = DateTime.now().add(const Duration(days: 1, hours: 2));
  String _selectedFormat = 'Solo';
  String _selectedBracketType = 'Single Elimination';
  String _selectedStatus = 'Upcoming';
  bool _isPrivate = false;

  final List<String> _formats = ['Solo', 'Duo', 'Squad', 'Team'];
  final List<String> _bracketTypes = [
    'Single Elimination',
    'Double Elimination',
    'Round Robin',
    'Swiss System'
  ];
  final List<String> _statuses = ['Upcoming', 'Live', 'Completed', 'Cancelled'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    _entryFeeController.dispose();
    _prizePoolController.dispose();
    _maxParticipantsController.dispose();
    _streamUrlController.dispose();
    _discordUrlController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartTime) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: isStartTime ? _startTime : _endTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStartTime ? _startTime : _endTime),
      );

      if (time != null) {
        setState(() {
          final newDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          if (isStartTime) {
            _startTime = newDateTime;
            if (_endTime.isBefore(_startTime)) {
              _endTime = _startTime.add(const Duration(hours: 2));
            }
          } else {
            if (newDateTime.isAfter(_startTime)) {
              _endTime = newDateTime;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('End time must be after start time')),
              );
            }
          }
        });
      }
    }
  }

  void _resetForm() {
    _selectedGameId = null;
    _titleController.clear();
    _descriptionController.clear();
    _rulesController.clear();
    _entryFeeController.clear();
    _prizePoolController.clear();
    _maxParticipantsController.clear();
    _streamUrlController.clear();
    _discordUrlController.clear();
    _passwordController.clear();
    setState(() {
      _startTime = DateTime.now().add(const Duration(days: 1));
      _endTime = DateTime.now().add(const Duration(days: 1, hours: 2));
      _selectedFormat = 'Solo';
      _selectedBracketType = 'Single Elimination';
      _selectedStatus = 'Upcoming';
      _isPrivate = false;
    });
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
        return Colors.grey;
    }
  }

  Future<void> _showDeleteConfirmation(Match match) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Match'),
        content: Text('Are you sure you want to delete "${match.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _deleteMatch(match.id);
    }
  }

  Future<void> _deleteMatch(String matchId) async {
    try {
      await FirebaseFirestore.instance.collection('matches').doc(matchId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting match: $e')),
        );
      }
    }
  }

  void _showAddMatchDialog() {
    _resetForm();
    _showMatchDialog();
  }

  void _showEditMatchDialog(Match match) {
    _selectedGameId = match.gameId;
    _titleController.text = match.title;
    _descriptionController.text = match.description;
    _rulesController.text = match.rules;
    _entryFeeController.text = match.entryFee.toString();
    _prizePoolController.text = match.prizePool.toString();
    _maxParticipantsController.text = match.maxParticipants.toString();
    _streamUrlController.text = match.streamUrl;
    _discordUrlController.text = match.discordUrl;
    _passwordController.text = match.password ?? '';
    setState(() {
      _startTime = match.startTime;
      _endTime = match.endTime;
      _selectedFormat = match.format;
      _selectedBracketType = match.bracketType;
      _selectedStatus = match.status;
      _isPrivate = match.isPrivate;
    });
    _showMatchDialog(existingMatch: match);
  }

  void _showMatchDialog({Match? existingMatch}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingMatch == null ? 'Create New Match' : 'Edit Match'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('games')
                      .where('isActive', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final games = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      value: _selectedGameId,
                      decoration: const InputDecoration(labelText: 'Select Game'),
                      items: games.map((game) {
                        final gameData = game.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: game.id,
                          child: Text(gameData['title'] ?? 'Untitled Game'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedGameId = value);
                      },
                      validator: (value) =>
                          value == null ? 'Please select a game' : null,
                    );
                  },
                ),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Title is required' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Description is required' : null,
                ),
                TextFormField(
                  controller: _rulesController,
                  decoration: const InputDecoration(labelText: 'Rules'),
                  maxLines: 3,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Rules are required' : null,
                ),
                ListTile(
                  title: const Text('Start Time'),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy - hh:mm a').format(_startTime),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDateTime(context, true),
                ),
                ListTile(
                  title: const Text('End Time'),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy - hh:mm a').format(_endTime),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDateTime(context, false),
                ),
                TextFormField(
                  controller: _entryFeeController,
                  decoration: const InputDecoration(labelText: 'Entry Fee'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Entry fee is required';
                    if (double.tryParse(value!) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _prizePoolController,
                  decoration: const InputDecoration(labelText: 'Prize Pool'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Prize pool is required';
                    if (double.tryParse(value!) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _maxParticipantsController,
                  decoration: const InputDecoration(labelText: 'Max Participants'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Max participants is required';
                    }
                    final number = int.tryParse(value!);
                    if (number == null || number < 2) {
                      return 'Please enter a valid number (min: 2)';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedFormat,
                  decoration: const InputDecoration(labelText: 'Format'),
                  items: _formats
                      .map((format) => DropdownMenuItem(
                            value: format,
                            child: Text(format),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedFormat = value);
                    }
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedBracketType,
                  decoration: const InputDecoration(labelText: 'Bracket Type'),
                  items: _bracketTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedBracketType = value);
                    }
                  },
                ),
                if (existingMatch != null)
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: _statuses
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedStatus = value);
                      }
                    },
                  ),
                TextFormField(
                  controller: _streamUrlController,
                  decoration: const InputDecoration(labelText: 'Stream URL'),
                ),
                TextFormField(
                  controller: _discordUrlController,
                  decoration: const InputDecoration(labelText: 'Discord URL'),
                ),
                SwitchListTile(
                  title: const Text('Private Match'),
                  value: _isPrivate,
                  onChanged: (value) => setState(() => _isPrivate = value),
                ),
                if (_isPrivate)
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) => _isPrivate && (value?.isEmpty ?? true)
                        ? 'Password is required for private matches'
                        : null,
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
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  final matchData = {
                    'gameId': _selectedGameId,
                    'title': _titleController.text,
                    'description': _descriptionController.text,
                    'rules': _rulesController.text,
                    'startTime': Timestamp.fromDate(_startTime),
                    'endTime': Timestamp.fromDate(_endTime),
                    'entryFee': double.parse(_entryFeeController.text),
                    'prizePool': double.parse(_prizePoolController.text),
                    'maxParticipants': int.parse(_maxParticipantsController.text),
                    'currentParticipants':
                        existingMatch?.currentParticipants ?? 0,
                    'format': _selectedFormat,
                    'bracketType': _selectedBracketType,
                    'status': _selectedStatus,
                    'streamUrl': _streamUrlController.text,
                    'discordUrl': _discordUrlController.text,
                    'isPrivate': _isPrivate,
                    if (_isPrivate) 'password': _passwordController.text,
                    'participants': existingMatch?.participants ?? [],
                    'results': existingMatch?.results ?? {},
                    if (existingMatch == null) ...{
                      'createdBy': user.uid,
                      'createdAt': FieldValue.serverTimestamp(),
                    },
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  if (existingMatch != null) {
                    await FirebaseFirestore.instance
                        .collection('matches')
                        .doc(existingMatch.id)
                        .update(matchData);
                  } else {
                    await FirebaseFirestore.instance
                        .collection('matches')
                        .add(matchData);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          existingMatch == null
                              ? 'Match created successfully'
                              : 'Match updated successfully',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                      ),
                    );
                  }
                }
              }
            },
            child: Text(existingMatch == null ? 'CREATE' : 'UPDATE'),
          ),
        ],
      ),
    );
  }

  Future<void> _createOrUpdateMatch({
    required String gameId,
    required String name,
    required String description,
    required DateTime startTime,
    required int maxPlayers,
    required double entryFee,
    required double prizePool,
    String? matchId,
  }) async {
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      
      if (matchId == null) {
        // Creating new match
        await FirebaseFirestore.instance
            .collection('matches')
            .add({
          'gameId': gameId,
          'title': name,
          'description': description,
          'startTime': startTime,
          'maxParticipants': maxPlayers,
          'entryFee': entryFee,
          'prizePool': prizePool,
          'status': 'upcoming',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Send notification for new match
        await notificationService.sendNotificationToAllUsers(
          title: 'New Match Available!',
          body: 'Join the new match: $name',
          type: 'match',
        );
      } else {
        // Updating existing match
        await FirebaseFirestore.instance
            .collection('matches')
            .doc(matchId)
            .update({
          'title': name,
          'description': description,
          'startTime': startTime,
          'maxParticipants': maxPlayers,
          'entryFee': entryFee,
          'prizePool': prizePool,
        });
        
        // Send notification for match update
        await notificationService.sendNotificationToAllUsers(
          title: 'Match Updated',
          body: 'The match $name has been updated',
          type: 'match',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(matchId == null ? 'Match created successfully' : 'Match updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateMatchStatus(String matchId, String status) async {
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      final matchDoc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .get();
      final matchData = matchDoc.data() as Map<String, dynamic>;
      
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Send notification for status change
      await notificationService.sendNotificationToAllUsers(
        title: 'Match Status Update',
        body: 'Match ${matchData['title']} is now $status',
        type: 'match',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Match status updated to $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Management'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMatchDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .orderBy('startTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const LoadingIndicator();
          }

          final matches = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = Match.fromFirestore(matches[index]);
              return Card(
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
                      Text(
                        'End: ${DateFormat('MMM dd, yyyy - hh:mm a').format(match.endTime)}',
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
                        onPressed: () => _showEditMatchDialog(match),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _showDeleteConfirmation(match),
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
}
