import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  final String id;
  final String gameId;
  final String title;
  final String description;
  final DateTime startTime;
  final int entryFee;
  final int prizePool;
  final int maxPlayers;
  final int registeredPlayers;
  final bool isActive;
  final String rules;
  final List<String> registeredUserIds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Match({
    required this.id,
    required this.gameId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.entryFee,
    required this.prizePool,
    required this.maxPlayers,
    this.registeredPlayers = 0,
    this.isActive = true,
    required this.rules,
    this.registeredUserIds = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory Match.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Match(
      id: doc.id,
      gameId: data['gameId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      entryFee: data['entryFee'] ?? 0,
      prizePool: data['prizePool'] ?? 0,
      maxPlayers: data['maxPlayers'] ?? 0,
      registeredPlayers: data['registeredPlayers'] ?? 0,
      isActive: data['isActive'] ?? true,
      rules: data['rules'] ?? '',
      registeredUserIds: List<String>.from(data['registeredUserIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gameId': gameId,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'entryFee': entryFee,
      'prizePool': prizePool,
      'maxPlayers': maxPlayers,
      'registeredPlayers': registeredPlayers,
      'isActive': isActive,
      'rules': rules,
      'registeredUserIds': registeredUserIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  Match copyWith({
    String? id,
    String? gameId,
    String? title,
    String? description,
    DateTime? startTime,
    int? entryFee,
    int? prizePool,
    int? maxPlayers,
    int? registeredPlayers,
    bool? isActive,
    String? rules,
    List<String>? registeredUserIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Match(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      entryFee: entryFee ?? this.entryFee,
      prizePool: prizePool ?? this.prizePool,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      registeredPlayers: registeredPlayers ?? this.registeredPlayers,
      isActive: isActive ?? this.isActive,
      rules: rules ?? this.rules,
      registeredUserIds: registeredUserIds ?? this.registeredUserIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
