import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  final String? targetUserId;
  final List<String> readBy;
  final String status;
  final Color backgroundColor;
  final Color textColor;
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
    this.targetUserId,
    this.readBy = const [],
    this.status = 'unread',
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.additionalData,
  });

  factory Notification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final readBy = List<String>.from(data['readBy'] ?? []);
    
    return Notification(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['body'] ?? '', // Changed from 'message' to 'body'
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${data['type']}',
        orElse: () => NotificationType.admin,
      ),
      gameId: data['gameId'],
      matchId: data['matchId'],
      isRead: currentUserId != null && readBy.contains(currentUserId),
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      targetUserId: data['targetUserId'],
      readBy: readBy,
      status: data['status'] ?? 'unread',
      backgroundColor: data['backgroundColor'] != null ? Color(int.parse('FF${data['backgroundColor']}', radix: 16)) : Colors.white,
      textColor: data['textColor'] != null ? Color(int.parse('FF${data['textColor']}', radix: 16)) : Colors.black,
      additionalData: data['data'], // Changed from 'additionalData' to 'data'
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': message,
      'type': type.toString().split('.').last,
      'gameId': gameId,
      'matchId': matchId,
      'targetUserId': targetUserId,
      'readBy': readBy,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'backgroundColor': backgroundColor.value.toRadixString(16),
      'textColor': textColor.value.toRadixString(16),
      'data': additionalData,
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
