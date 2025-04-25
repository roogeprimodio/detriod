import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../features/notifications/domain/models/notification.dart' as models;

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService;

  NotificationProvider(this._notificationService) {
    initialize();
  }

  bool get isInitialized => _notificationService.isInitialized;
  bool get isLoading => _notificationService.isLoading;
  String? get error => _notificationService.error;

  Future<void> initialize() async {
    if (!_notificationService.isInitialized) {
      await _notificationService.initialize();
      notifyListeners();
    }
  }

  Stream<List<models.Notification>> getUserNotifications(String userId, {int limit = 20, DateTime? olderThan}) {
    return _notificationService.getUserNotifications(userId, limit: limit, olderThan: olderThan).map((querySnapshot) {
      final filteredDocs = querySnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final targetUserId = data['targetUserId'];
        return targetUserId == null || targetUserId == 'global' || targetUserId == userId;
      });
      return filteredDocs.map((doc) => models.Notification.fromFirestore(doc)).toList();
    });
  }

  Stream<int> getUnreadCount(String userId) {
    return _notificationService.getUserUnreadNotificationsCount(userId);
  }

  Future<void> markAsRead(String notificationId) async {
    await _notificationService.markNotificationAsRead(notificationId);
    notifyListeners();
  }

  Future<void> markAllAsRead(String userId) async {
    await _notificationService.markAllAsRead(userId);
    notifyListeners();
  }

  Future<void> sendNotificationToAllUsers({
    required String title,
    required String body,
    required String type,
    Color backgroundColor = Colors.white,
    Color textColor = Colors.black,
  }) async {
    await _notificationService.sendNotificationToAllUsers(
      title: title,
      body: body,
      type: type,
      data: {
        'backgroundColor': backgroundColor.value.toRadixString(16),
        'textColor': textColor.value.toRadixString(16),
      },
    );
    notifyListeners();
  }

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Color backgroundColor = Colors.white,
    Color textColor = Colors.black,
  }) async {
    await _notificationService.sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      type: type,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
} 