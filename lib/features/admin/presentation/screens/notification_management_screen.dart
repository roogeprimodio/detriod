import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../../services/notification_service.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/providers/auth_provider.dart';

class NotificationManagementScreen extends StatelessWidget {
  const NotificationManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notification Management'),
        ),
        body: const Center(
          child: Text('Admin permissions required'),
        ),
      );
    }
    
    return const _NotificationManagementScreenContent();
  }
}

class _NotificationManagementScreenContent extends StatefulWidget {
  const _NotificationManagementScreenContent({Key? key}) : super(key: key);

  @override
  State<_NotificationManagementScreenContent> createState() => _NotificationManagementScreenContentState();
}

class _NotificationManagementScreenContentState extends State<_NotificationManagementScreenContent> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedType = 'general';
  String _selectedUser = 'all';
  Color _backgroundColor = Colors.blue;
  Color _textColor = Colors.white;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;

  final List<String> _notificationTypes = [
    'general',
    'game',
    'match',
    'system',
    'promotion',
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        _users = snapshot.docs.map((doc) => {
          'id': doc.id,
          'name': doc.data()['name'] ?? 'Unknown User',
          'email': doc.data()['email'] ?? 'No email',
        }).toList();
      });
    } catch (e) {
      print('Error loading users: $e');
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Admin permissions required')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notificationService = context.read<NotificationService>();
      
      await notificationService.sendNotificationToAllUsers(
        title: _titleController.text,
        body: _bodyController.text,
        type: _selectedType,
        data: {
          'backgroundColor': _backgroundColor.value.toRadixString(16),
          'textColor': _textColor.value.toRadixString(16),
          'targetUserId': _selectedUser == 'all' ? null : _selectedUser,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent successfully')),
        );
        _titleController.clear();
        _bodyController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Management'),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Notification Type
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Notification Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _notificationTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.capitalize()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedType = value!);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Target User
                    DropdownButtonFormField<String>(
                      value: _selectedUser,
                      decoration: const InputDecoration(
                        labelText: 'Target User',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('All Users'),
                        ),
                        ..._users.map((user) {
                          return DropdownMenuItem(
                            value: user['id'],
                            child: Text('${user['name']} (${user['email']})'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedUser = value!);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Body
                    TextFormField(
                      controller: _bodyController,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a message';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Color Selection
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Background Color'),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final color = await showDialog<Color>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Pick a color'),
                                      content: SingleChildScrollView(
                                        child: ColorPicker(
                                          pickerColor: _backgroundColor,
                                          onColorChanged: (color) {
                                            Navigator.pop(context, color);
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                  if (color != null) {
                                    setState(() => _backgroundColor = color);
                                  }
                                },
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _backgroundColor,
                                    border: Border.all(),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Text Color'),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final color = await showDialog<Color>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Pick a color'),
                                      content: SingleChildScrollView(
                                        child: ColorPicker(
                                          pickerColor: _textColor,
                                          onColorChanged: (color) {
                                            Navigator.pop(context, color);
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                  if (color != null) {
                                    setState(() => _textColor = color);
                                  }
                                },
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _textColor,
                                    border: Border.all(),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Preview
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleController.text.isEmpty ? 'Title' : _titleController.text,
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _bodyController.text.isEmpty ? 'Message' : _bodyController.text,
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Send Button
                    ElevatedButton(
                      onPressed: _sendNotification,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Send Notification'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 