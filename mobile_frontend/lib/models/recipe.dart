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
        print('Date parsing error: $e');
      }
    }

    // Decimal değerleri float'a dönüştür
    double parseDecimal(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Recipe(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      imageUrl: json['image_filename'],
      images: (json['images'] as List<dynamic>?)
              ?.map((image) => RecipeImage.fromJson(image))
              ?.toList() ?? [],
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      categoryId: json['category_id'] ?? 0,
      isFavorited: json['is_favorited'] ?? false,
      favoriteCount: parseDecimal(json['favorite_count']).toInt(),
      commentCount: parseDecimal(json['comment_count']).toInt(),
      views: parseDecimal(json['views']).toInt(),
      cookingTime: json['cooking_time']?.toString(),
      ingredients: json['ingredients'],
      instructions: json['instructions'],
      tips: json['tips'],
      servingSize: json['servings']?.toString(),
      difficulty: json['difficulty'],
      createdAt: parsedDate,
      averageRating: parseDecimal(json['average_rating']),
      ratingCount: parseDecimal(json['rating_count']).toInt(),
      userRating: json['user_rating'] != null ? parseDecimal(json['user_rating']).toInt() : null,
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