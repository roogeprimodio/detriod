import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  final String id;
  final String gameId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final int maxParticipants;
  final int currentParticipants;
  final String status;
  final List<String> participants;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double entryFee;
  final double prizePool;
  final String rules;
  final String format;
  final String bracketType;
  final bool isPrivate;
  final String? password;
  final Map<String, dynamic> results;
  final String streamUrl;
  final String discordUrl;

  Match({
    required this.id,
    required this.gameId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.status,
    required this.participants,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    required this.entryFee,
    required this.prizePool,
    required this.rules,
    required this.format,
    required this.bracketType,
    required this.isPrivate,
    this.password,
    required this.results,
    required this.streamUrl,
    required this.discordUrl,
  });

  factory Match.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Match(
      id: doc.id,
      gameId: data['gameId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxParticipants: data['maxParticipants'] ?? 0,
      currentParticipants: data['currentParticipants'] ?? 0,
      status: data['status'] ?? 'Upcoming',
      participants: List<String>.from(data['participants'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      entryFee: (data['entryFee'] ?? 0).toDouble(),
      prizePool: (data['prizePool'] ?? 0).toDouble(),
      rules: data['rules'] ?? '',
      format: data['format'] ?? '',
      bracketType: data['bracketType'] ?? '',
      isPrivate: data['isPrivate'] ?? false,
      password: data['password'],
      results: Map<String, dynamic>.from(data['results'] ?? {}),
      streamUrl: data['streamUrl'] ?? '',
      discordUrl: data['discordUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gameId': gameId,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'status': status,
      'participants': participants,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'entryFee': entryFee,
      'prizePool': prizePool,
      'rules': rules,
      'format': format,
      'bracketType': bracketType,
      'isPrivate': isPrivate,
      if (password != null) 'password': password,
      'results': results,
      'streamUrl': streamUrl,
      'discordUrl': discordUrl,
    };
  }

  Match copyWith({
    String? id,
    String? gameId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    int? maxParticipants,
    int? currentParticipants,
    String? status,
    List<String>? participants,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? entryFee,
    double? prizePool,
    String? rules,
    String? format,
    String? bracketType,
    bool? isPrivate,
    String? password,
    Map<String, dynamic>? results,
    String? streamUrl,
    String? discordUrl,
  }) {
    return Match(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      entryFee: entryFee ?? this.entryFee,
      prizePool: prizePool ?? this.prizePool,
      rules: rules ?? this.rules,
      format: format ?? this.format,
      bracketType: bracketType ?? this.bracketType,
      isPrivate: isPrivate ?? this.isPrivate,
      password: password ?? this.password,
      results: results ?? this.results,
      streamUrl: streamUrl ?? this.streamUrl,
      discordUrl: discordUrl ?? this.discordUrl,
    );
  }
}
