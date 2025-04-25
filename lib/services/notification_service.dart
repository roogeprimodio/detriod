import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _isLoading = true;
      _error = null;
      
      // Initialize local notifications for foreground
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
      await _localNotifications.initialize(initSettings);
      
      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> sendNotificationToAllUsers({
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Store notification in Firestore
      final notificationRef = await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': [],
        'status': 'unread',
        'backgroundColor': data?['backgroundColor'],
        'textColor': data?['textColor'],
        'targetUserId': data?['targetUserId'] ?? 'global',
      });

      // Show local notification if app is in foreground
      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default Channel',
            importance: Importance.high,
            color: data?['backgroundColor'] != null 
                ? Color(int.parse('FF${data!['backgroundColor']}', radix: 16))
                : Colors.blue,
            colorized: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      print('Error in sendNotificationToAllUsers: $e');
      rethrow;
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('notifications').doc(notificationId).update({
        'readBy': FieldValue.arrayUnion([userId]),
        'status': 'read',
      });
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Get real-time notifications stream
  Stream<QuerySnapshot> getNotifications() {
    return _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get unread notifications count
  Stream<int> getUnreadNotificationsCount() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('status', isEqualTo: 'unread')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => !(doc.get('readBy') as List).contains(userId))
            .length);
  }

  // Get notifications for specific user
  Stream<QuerySnapshot> getUserNotifications(String userId, {int limit = 20, DateTime? olderThan}) {
    print('Fetching notifications for user: $userId with limit: $limit, olderThan: $olderThan');
    
    Query baseQuery = _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true);

    if (olderThan != null) {
      baseQuery = baseQuery.where('createdAt', isLessThan: Timestamp.fromDate(olderThan));
    }

    baseQuery = baseQuery.limit(limit * 2); // Fetch more to account for filtering

    // Create a stream that retries a few times if needed
    return Stream.periodic(Duration(seconds: 1))
      .take(5) // Try for 5 seconds
      .asyncMap((_) async {
        // Check if user is authenticated
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          print('User not authenticated');
          throw 'User not authenticated';
        }
        
        print('User authenticated: ${currentUser.uid}');
        
        // Check if user document exists
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
            
        if (!userDoc.exists) {
          print('Creating user document');
          await _firestore.collection('users').doc(currentUser.uid).set({
            'email': currentUser.email,
            'name': currentUser.displayName ?? 'Unknown User',
            'isAdmin': false,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }
        
        // Test if we can read notifications
        final testSnapshot = await baseQuery.get();
        print('Successfully read ${testSnapshot.docs.length} notifications');
        return testSnapshot;
      })
      .take(1) // Only take the first successful result
      .asyncExpand((_) => baseQuery.snapshots()); // Convert to real-time stream
  }

  // Get unread notifications count for specific user
  Stream<int> getUserUnreadNotificationsCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('targetUserId', whereIn: ['global', userId])
        .snapshots()
        .map((snapshot) => snapshot.docs.where((doc) => 
            !doc.get('readBy').contains(userId) && 
            doc.get('status') == 'unread'
        ).length);
  }

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Color backgroundColor = Colors.white,
    Color textColor = Colors.black,
  }) async {
    try {
      // Store notification in Firestore
      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': [],
        'status': 'unread',
        'backgroundColor': backgroundColor.value.toRadixString(16),
        'textColor': textColor.value.toRadixString(16),
        'targetUserId': userId,
      });

      // Show local notification if app is in foreground and the notification is for the current user
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == userId) {
        await _localNotifications.show(
          DateTime.now().millisecond,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel',
              'Default Channel',
              importance: Importance.high,
              color: backgroundColor,
              colorized: true,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
    } catch (e) {
      print('Error in sendNotificationToUser: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final notifications = await _firestore
          .collection('notifications')
          .where('targetUserId', whereIn: ['global', userId])
          .where('status', isEqualTo: 'unread')
          .get();

      final batch = _firestore.batch();
      for (var doc in notifications.docs) {
        if (!doc.get('readBy').contains(userId)) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([userId]),
            'status': 'read',
          });
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  void dispose() {
    _localNotifications.cancelAll();
  }
} 