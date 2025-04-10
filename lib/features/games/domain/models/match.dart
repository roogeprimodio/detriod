import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  final String id;
  final String gameId;
  final String title;
  final String description;
  final DateTime startTime;
  final int maxParticipants;
  final int currentParticipants;
  final String status; // 'upcoming', 'ongoing', 'completed', 'cancelled'
  final List<Map<String, dynamic>> participants;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Match({
    required this.id,
    required this.gameId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.status,
    required this.participants,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isFull => currentParticipants >= maxParticipants;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameId': gameId,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'status': status,
      'participants': participants,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory Match.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Match(
      id: doc.id,
      gameId: data['gameId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      maxParticipants: data['maxParticipants'] ?? 0,
      currentParticipants: data['currentParticipants'] ?? 0,
      status: data['status'] ?? 'upcoming',
      participants: List<Map<String, dynamic>>.from(data['participants'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Match copyWith({
    String? id,
    String? gameId,
    String? title,
    String? description,
    DateTime? startTime,
    int? maxParticipants,
    int? currentParticipants,
    String? status,
    List<Map<String, dynamic>>? participants,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Match(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
