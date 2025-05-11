class User {
  final int id;
  final String username;
  final String email;
  final String? profileImage;
  final String? appearance;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImage,
    this.appearance,
    required this.createdAt,
    required this.updatedAt,
  });

  // JSON'dan User nesnesine dönüştürme
  factory User.fromJson(Map<String, dynamic> json) {
  return User(
    id: json['id'],
    username: json['username'] ?? '',
    email: json['email'] ?? '',
    profileImage: json['profile_image'],
    appearance: json['appearance'],
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
  );
}

  // User nesnesinden JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profile_image': profileImage,
      'appearance': appearance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Kullanıcı bilgilerini güncelleme için kopya oluşturma
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? profileImage,
    String? appearance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      appearance: appearance ?? this.appearance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 