import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  gameAdded,
  matchAdded,
  matchStarting,
  matchRegistration,
  admin,
  wallet
}

class Notification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String? gameId;
  final String? matchId;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? additionalData;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.gameId,
    this.matchId,
    this.isRead = false,
    required this.createdAt,
    this.additionalData,
  });

  factory Notification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Notification(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${data['type']}',
        orElse: () => NotificationType.admin,
      ),
      gameId: data['gameId'],
      matchId: data['matchId'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      additionalData: data['additionalData'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'gameId': gameId,
      'matchId': matchId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'additionalData': additionalData,
    };
  }

  Notification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    String? gameId,
    String? matchId,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? additionalData,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      gameId: gameId ?? this.gameId,
      matchId: matchId ?? this.matchId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}
