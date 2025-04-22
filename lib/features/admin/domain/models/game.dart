import 'package:cloud_firestore/cloud_firestore.dart';

class Game {
  final String id;
  final String title;
  final String description;
  final String genre;
  final String imageUrl;
  final List<String> platforms;
  final bool isActive;
  final double rating;
  final int totalRatings;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Game({
    required this.id,
    required this.title,
    required this.description,
    required this.genre,
    required this.imageUrl,
    required this.platforms,
    required this.isActive,
    required this.rating,
    required this.totalRatings,
    required this.createdAt,
    this.updatedAt,
  });

  factory Game.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Game(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      genre: data['genre'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      platforms: List<String>.from(data['platforms'] ?? []),
      isActive: data['isActive'] ?? true,
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'genre': genre,
      'imageUrl': imageUrl,
      'platforms': platforms,
      'isActive': isActive,
      'rating': rating,
      'totalRatings': totalRatings,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  Game copyWith({
    String? title,
    String? description,
    String? genre,
    String? imageUrl,
    List<String>? platforms,
    bool? isActive,
    double? rating,
    int? totalRatings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Game(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      genre: genre ?? this.genre,
      imageUrl: imageUrl ?? this.imageUrl,
      platforms: platforms ?? this.platforms,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
