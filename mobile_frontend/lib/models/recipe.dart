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
    print('Parsing recipe JSON: $json');

    // Güvenli string dönüşümü
    String safeString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      return value.toString();
    }

    // Güvenli int dönüşümü
    int safeInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Güvenli bool dönüşümü
    bool safeBool(dynamic value, [bool defaultValue = false]) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) return value.toLowerCase() == 'true';
      return defaultValue;
    }

    DateTime? parsedDate;
    if (json['created_at'] != null) {
      try {
        parsedDate = DateTime.parse(json['created_at'].toString());
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

    // Liste dönüşümü için güvenli metod
    List<RecipeImage> parseImages(dynamic imagesData) {
      if (imagesData == null) return [];
      if (imagesData is! List) return [];
      return imagesData.map((image) => RecipeImage.fromJson(image is Map<String, dynamic> ? image : {})).toList();
    }

    try {
      return Recipe(
        id: safeInt(json['id']),
        title: safeString(json['title'], 'İsimsiz Tarif'),
        description: safeString(json['description']),
        imageUrl: safeString(json['image_filename']),
        images: parseImages(json['images']),
        userId: safeInt(json['user_id']),
        username: safeString(json['username'], 'Anonim'),
        categoryId: safeInt(json['category_id']),
        isFavorited: safeBool(json['is_favorited']),
        favoriteCount: safeInt(json['favorite_count']),
        commentCount: safeInt(json['comment_count']),
        views: safeInt(json['views']),
        cookingTime: safeString(json['cooking_time'], '30 dakika'),
        ingredients: safeString(json['ingredients']),
        instructions: safeString(json['instructions']),
        tips: safeString(json['tips']),
        servingSize: safeString(json['serving_size']),
        difficulty: safeString(json['difficulty']),
        createdAt: parsedDate,
        averageRating: parseDecimal(json['average_rating']),
        ratingCount: safeInt(json['rating_count']),
        userRating: json['user_rating'] != null ? safeInt(json['user_rating']) : null,
      );
    } catch (e) {
      print('Error parsing recipe: $e');
      // Minimum gerekli alanlarla bir Recipe objesi döndür
      return Recipe(
        id: safeInt(json['id']),
        title: safeString(json['title'], 'Bilinmeyen Tarif'),
        images: [],
        userId: safeInt(json['user_id']),
        username: safeString(json['username'], 'Anonim'),
        categoryId: safeInt(json['category_id']),
      );
    }
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