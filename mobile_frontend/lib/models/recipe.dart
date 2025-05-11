import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' show HttpDate;
import 'package:intl/intl.dart';

class Recipe {
  final int id;
  final String title;
  final String description;
  final String ingredients;
  final String instructions;
  final String? imageUrl;
  final List<RecipeImage> images;
  final String? servingSize;
  final String? cookingTime;
  final String? prepTime;
  final String? tips;
  final String? difficulty;
  final int userId;
  final String username;
  final int categoryId;
  final bool isFavorited;
  final int favoriteCount;
  final int commentCount;
  final int views;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double averageRating;
  final int ratingCount;
  final int? userRating;
  List<String>? matchingIngredients;
  List<String>? requiredIngredients;
  int? matchCount;
  final String imageFilename;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.instructions,
    this.imageUrl,
    required this.images,
    this.servingSize,
    this.cookingTime,
    this.prepTime,
    this.tips,
    this.difficulty,
    required this.userId,
    required this.username,
    required this.categoryId,
    this.isFavorited = false,
    this.favoriteCount = 0,
    this.commentCount = 0,
    this.views = 0,
    required this.createdAt,
    required this.updatedAt,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.userRating,
    this.matchingIngredients,
    this.requiredIngredients,
    this.matchCount,
    this.imageFilename = '',
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      ingredients: json['ingredients'] ?? '',
      instructions: json['instructions'] ?? '',
      imageUrl: json['image_url'],
      images: (json['images'] as List<dynamic>?)?.map((image) => RecipeImage.fromJson(image)).toList() ?? [],
      servingSize: json['serving_size'],
      cookingTime: json['cooking_time'],
      prepTime: json['prep_time'],
      tips: json['tips'],
      difficulty: json['difficulty'],
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? 'Anonim',
      categoryId: json['category_id'] ?? 0,
      isFavorited: json['is_favorited'] ?? false,
      favoriteCount: json['favorite_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      views: json['views'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      ratingCount: json['rating_count'] ?? 0,
      userRating: json['user_rating'],
      matchingIngredients: json['matching_ingredients'] != null 
          ? List<String>.from(json['matching_ingredients'])
          : null,
      requiredIngredients: json['required_ingredients'] != null 
          ? List<String>.from(json['required_ingredients'])
          : null,
      matchCount: json['match_count'] ?? 0,
      imageFilename: json['image_filename'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'image_url': imageUrl,
      'images': images.map((image) => image.toJson()).toList(),
      'serving_size': servingSize,
      'cooking_time': cookingTime,
      'prep_time': prepTime,
      'tips': tips,
      'difficulty': difficulty,
      'user_id': userId,
      'username': username,
      'category_id': categoryId,
      'is_favorited': isFavorited,
      'favorite_count': favoriteCount,
      'comment_count': commentCount,
      'views': views,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'average_rating': averageRating,
      'rating_count': ratingCount,
      'user_rating': userRating,
      'matching_ingredients': matchingIngredients,
      'required_ingredients': requiredIngredients,
      'match_count': matchCount,
      'image_filename': imageFilename,
    };
  }
}

class RecipeImage {
  final int id;
  final int recipeId;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecipeImage({
    required this.id,
    required this.recipeId,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecipeImage.fromJson(Map<String, dynamic> json) {
    return RecipeImage(
      id: json['id'],
      recipeId: json['recipe_id'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
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