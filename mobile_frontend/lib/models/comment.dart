class Comment {
  final int id;
  final String content;
  final DateTime createdAt;
  final int userId;
  final int recipeId;
  String? username; // User tablosundan gelecek

  Comment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.userId,
    required this.recipeId,
    this.username,
  });

  // JSON'dan Comment nesnesine dönüştürme
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as int,
      recipeId: json['recipe_id'] as int,
      username: json['username'] as String?,
    );
  }

  // Comment nesnesinden JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
      'recipe_id': recipeId,
      'username': username,
    };
  }

  // Yorum oluşturma tarihi formatı
  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }
} 