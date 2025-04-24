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
  final double entryFee;

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
    required this.entryFee,
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
      'entryFee': entryFee,
    };
  }

  factory Match.fromMap(Map<String, dynamic> map) {
    // Handle null timestamps with default values
    final startTime = map['startTime'] != null 
        ? (map['startTime'] as Timestamp).toDate()
        : DateTime.now().add(const Duration(days: 1));
    
    final createdAt = map['createdAt'] != null 
        ? (map['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    
    final updatedAt = map['updatedAt'] != null 
        ? (map['updatedAt'] as Timestamp).toDate()
        : null;

    return Match(
      id: map['id'] ?? '',
      gameId: map['gameId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startTime: startTime,
      maxParticipants: map['maxParticipants']?.toInt() ?? 0,
      currentParticipants: map['currentParticipants']?.toInt() ?? 0,
      status: map['status'] ?? 'upcoming',
      participants: List<Map<String, dynamic>>.from(map['participants'] ?? []),
      createdBy: map['createdBy'] ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      entryFee: (map['entryFee'] ?? 0.0).toDouble(),
    );
  }

  factory Match.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id; // Ensure the document ID is included
    return Match.fromMap(data);
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
    double? entryFee,
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
      entryFee: entryFee ?? this.entryFee,
    );
  }
}
