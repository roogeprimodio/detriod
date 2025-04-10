class User {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool isAdmin;
  final double walletBalance;

  User({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.isAdmin = false,
    this.walletBalance = 0.0,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      isAdmin: map['isAdmin'] ?? false,
      walletBalance: (map['walletBalance'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'isAdmin': isAdmin,
      'walletBalance': walletBalance,
    };
  }

  User copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? isAdmin,
    double? walletBalance,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isAdmin: isAdmin ?? this.isAdmin,
      walletBalance: walletBalance ?? this.walletBalance,
    );
  }
}
