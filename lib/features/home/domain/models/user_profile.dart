import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  user,
  admin,
  superAdmin
}

class UserProfile {
  final String id;
  final String email;
  final String name;
  final String username;
  final String bio;
  final String photoUrl;
  final String profileImageUrl;
  final UserRole role;
  final Map<String, bool> permissions;
  final List<String> registeredMatches;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.username,
    this.bio = '',
    required this.photoUrl,
    required this.profileImageUrl,
    this.role = UserRole.user,
    this.permissions = const {},
    this.registeredMatches = const [],
    required this.createdAt,
    this.updatedAt,
  });

  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;
  bool get isSuperAdmin => role == UserRole.superAdmin;

  bool hasPermission(String permission) {
    if (isSuperAdmin) return true;
    return permissions[permission] ?? false;
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      bio: data['bio'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.user,
      ),
      permissions: Map<String, bool>.from(data['permissions'] ?? {}),
      registeredMatches: List<String>.from(data['registeredMatches'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory UserProfile.fromMap(String id, Map<String, dynamic> map) {
    return UserProfile(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      bio: map['bio'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${map['role']}',
        orElse: () => UserRole.user,
      ),
      permissions: Map<String, bool>.from(map['permissions'] ?? {}),
      registeredMatches: List<String>.from(map['registeredMatches'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'username': username,
      'bio': bio,
      'photoUrl': photoUrl,
      'profileImageUrl': profileImageUrl,
      'role': role.toString().split('.').last,
      'permissions': permissions,
      'registeredMatches': registeredMatches,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  Map<String, dynamic> toFirestore() => toMap();

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? username,
    String? bio,
    String? photoUrl,
    String? profileImageUrl,
    UserRole? role,
    Map<String, bool>? permissions,
    List<String>? registeredMatches,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      registeredMatches: registeredMatches ?? this.registeredMatches,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
