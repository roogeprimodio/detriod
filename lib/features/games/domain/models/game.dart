import 'package:cloud_firestore/cloud_firestore.dart';

class Game {
  final String id;
  final String title;
  final String description;
  final String genre;
  final String imageUrl;
  final double rating;
  final bool isActive;
  final DateTime releaseDate;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Game({
    required this.id,
    required this.title,
    required this.description,
    required this.genre,
    required this.imageUrl,
    required this.rating,
    required this.isActive,
    required this.releaseDate,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'genre': genre,
      'imageUrl': imageUrl,
      'rating': rating,
      'isActive': isActive,
      'releaseDate': Timestamp.fromDate(releaseDate),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory Game.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Game(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      genre: data['genre'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      isActive: data['isActive'] ?? true,
      releaseDate: (data['releaseDate'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Game copyWith({
    String? id,
    String? title,
    String? description,
    String? genre,
    String? imageUrl,
    double? rating,
    bool? isActive,
    DateTime? releaseDate,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Game(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      genre: genre ?? this.genre,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      isActive: isActive ?? this.isActive,
      releaseDate: releaseDate ?? this.releaseDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
