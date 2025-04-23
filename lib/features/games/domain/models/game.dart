import 'package:cloud_firestore/cloud_firestore.dart';

class Game {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String? bannerUrl;
  final String? requirements;
  final int? minPlayers;
  final int? maxPlayers;
  final int? minAge;
  final String? prizing;
  final List<String> categories;
  final List<String> platforms;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double rating;
  final int totalRatings;

  Game({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.bannerUrl,
    this.requirements,
    this.minPlayers,
    this.maxPlayers,
    this.minAge,
    this.prizing,
    required this.categories,
    required this.platforms,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.rating = 0.0,
    this.totalRatings = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'bannerUrl': bannerUrl,
      'requirements': requirements,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'minAge': minAge,
      'prizing': prizing,
      'categories': categories,
      'platforms': platforms,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'rating': rating,
      'totalRatings': totalRatings,
    };
  }

  factory Game.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Game(
      id: doc.id,
      title: data['title']?.toString() ?? 'Untitled Game',
      description: data['description']?.toString() ?? 'No description available',
      imageUrl: data['imageUrl']?.toString() ?? '',
      bannerUrl: data['bannerUrl']?.toString(),
      requirements: data['requirements']?.toString(),
      minPlayers: data['minPlayers'] as int?,
      maxPlayers: data['maxPlayers'] as int?,
      minAge: data['minAge'] as int?,
      prizing: data['prizing']?.toString(),
      categories: (data['categories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      platforms: (data['platforms'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isActive: data['isActive'] as bool? ?? true,
      createdBy: data['createdBy']?.toString() ?? 'Unknown',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
    );
  }

  Game copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? bannerUrl,
    String? requirements,
    int? minPlayers,
    int? maxPlayers,
    int? minAge,
    String? prizing,
    List<String>? categories,
    List<String>? platforms,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? rating,
    int? totalRatings,
  }) {
    return Game(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      requirements: requirements ?? this.requirements,
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      minAge: minAge ?? this.minAge,
      prizing: prizing ?? this.prizing,
      categories: categories ?? this.categories,
      platforms: platforms ?? this.platforms,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
    );
  }
}
