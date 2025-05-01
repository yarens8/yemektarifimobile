import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' show HttpDate;
import 'package:intl/intl.dart';

class Recipe {
  final int id;
  final String title;
  final String? description;
  final String? imageUrl;
  final List<RecipeImage> images;
  final int userId;
  final String username;
  final int categoryId;
  final bool isFavorited;
  final int favoriteCount;
  final int commentCount;
  final int views;
  final String? preparationTime;
  final String? cookingTime;
  final String? ingredients;
  final String? instructions;
  final String? tips;
  final String? servingSize;
  final String? difficulty;
  final DateTime? createdAt;
  final double averageRating;
  final int ratingCount;
  final int? userRating;

  Recipe({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    required this.images,
    required this.userId,
    required this.username,
    required this.categoryId,
    this.isFavorited = false,
    this.favoriteCount = 0,
    this.commentCount = 0,
    this.views = 0,
    this.preparationTime,
    this.cookingTime,
    this.ingredients,
    this.instructions,
    this.tips,
    this.servingSize,
    this.difficulty,
    this.createdAt,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.userRating,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['created_at'] != null) {
      try {
        parsedDate = DateTime.parse(json['created_at']);
      } catch (e) {
        try {
          parsedDate = HttpDate.parse(json['created_at']);
        } catch (e) {
          try {
            final dateStr = json['created_at'].toString();
            if (dateStr.contains('GMT')) {
              final formatter = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US');
              parsedDate = formatter.parse(dateStr);
            } else {
              parsedDate = DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateStr);
            }
          } catch (e) {
            print('Tarih ayrıştırma hatası: ${e.toString()}');
            print('Ayrıştırılamayan tarih: ${json['created_at']}');
            parsedDate = null;
          }
        }
      }
    }

    return Recipe(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      imageUrl: json['image_filename'] ?? '',
      images: [],
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      categoryId: json['category_id'] ?? 0,
      views: json['views'] ?? 0,
      preparationTime: json['preparation_time']?.toString(),
      cookingTime: json['cooking_time']?.toString(),
      ingredients: json['ingredients'],
      instructions: json['instructions'],
      tips: json['tips'],
      servingSize: json['serving_size']?.toString(),
      difficulty: json['difficulty'],
      createdAt: parsedDate,
      isFavorited: json['is_favorited'] ?? false,
      favoriteCount: json['favorite_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['rating_count'] ?? 0,
      userRating: json['user_rating'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_filename': imageUrl,
      'user_id': userId,
      'username': username,
      'category_id': categoryId,
      'views': views,
      'preparation_time': preparationTime,
      'cooking_time': cookingTime,
      'ingredients': ingredients,
      'instructions': instructions,
      'tips': tips,
      'serving_size': servingSize,
      'difficulty': difficulty,
      'created_at': createdAt?.toIso8601String(),
      'average_rating': averageRating,
      'rating_count': ratingCount,
      'user_rating': userRating,
    };
  }
}

class RecipeImage {
  final int id;
  final String imageUrl;

  RecipeImage({
    required this.id,
    required this.imageUrl,
  });

  factory RecipeImage.fromJson(Map<String, dynamic> json) {
    String url = json['image_url'] ?? json['imageUrl'] ?? json['url'] ?? '';
    return RecipeImage(
      id: json['id'] ?? 0,
      imageUrl: url,
    );
  }
}

class User {
  final int id;
  final String username;
  final String? profileImage;

  User({
    required this.id,
    required this.username,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      profileImage: json['profileImage'],
    );
  }
} 