class User {
  final int id;
  final String username;
  final String email;
  final String? profileImage;
  final String? appearance;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImage,
    this.appearance,
  });

  // JSON'dan User nesnesine dönüştürme
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      profileImage: json['profile_image'] as String?,
      appearance: json['appearance'] as String?,
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
    };
  }

  // Kullanıcı bilgilerini güncelleme için kopya oluşturma
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? profileImage,
    String? appearance,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      appearance: appearance ?? this.appearance,
    );
  }
} 