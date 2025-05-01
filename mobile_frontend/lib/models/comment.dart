import 'package:intl/intl.dart';

class Comment {
  final int id;
  final String content;
  final DateTime? createdAt;
  final int userId;
  final int recipeId;
  final String? username;

  Comment({
    required this.id,
    required this.content,
    this.createdAt,
    required this.userId,
    required this.recipeId,
    this.username,
  });

  // JSON'dan Comment nesnesine dönüştürme
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      content: json['content'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      userId: json['user_id'],
      recipeId: json['recipe_id'],
      username: json['username'],
    );
  }

  // Comment nesnesinden JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'created_at': createdAt?.toIso8601String(),
      'user_id': userId,
      'recipe_id': recipeId,
      'username': username,
    };
  }

  // Yorum oluşturma tarihi formatı
  String get formattedDate {
    if (createdAt == null) return '';
    return DateFormat('dd.MM.yyyy HH:mm').format(createdAt!);
  }
} 