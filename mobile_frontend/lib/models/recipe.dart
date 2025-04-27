class Recipe {
  final int id;
  final String title;
  final String? description;
  final String? imageFilename;
  final List<RecipeImage> images;
  final User user;
  final bool isFavorited;
  final int favoriteCount;
  final int commentCount;
  final int views;
  final String? preparationTime;
  final String? ingredients;
  final String? instructions;
  final String? tips;
  final int? servingCount;
  final String? difficulty;

  Recipe({
    required this.id,
    required this.title,
    this.description,
    this.imageFilename,
    required this.images,
    required this.user,
    this.isFavorited = false,
    this.favoriteCount = 0,
    this.commentCount = 0,
    this.views = 0,
    this.preparationTime,
    this.ingredients,
    this.instructions,
    this.tips,
    this.servingCount,
    this.difficulty,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    List<RecipeImage> recipeImages = [];
    
    if (json['image_filename'] != null && json['image_filename'].toString().isNotEmpty) {
      print('Tarif başlığı: ${json['title']}');
      print('Image filename: ${json['image_filename']}');
      recipeImages.add(RecipeImage(
        id: 0,
        imageUrl: json['image_filename'].toString().split('/').last
      ));
    }
    
    if (json['images'] is List) {
      print('Images listesi: ${json['images']}');
      recipeImages.addAll(
        (json['images'] as List).map((image) {
          if (image is Map) {
            String filename = image['url'] ?? image['image_url'] ?? image['imageUrl'] ?? '';
            return RecipeImage(
              id: image['id'] ?? 0,
              imageUrl: filename.split('/').last
            );
          }
          return RecipeImage(id: 0, imageUrl: image.toString().split('/').last);
        }).toList()
      );
    }

    User recipeUser;
    if (json['user'] != null && json['user'] is Map) {
      recipeUser = User.fromJson(json['user']);
    } else {
      recipeUser = User(
        id: json['user_id'] ?? 0,
        username: json['username'] ?? 'Anonim',
        profileImage: json['profile_image'],
      );
    }

    return Recipe(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      imageFilename: json['image_filename'],
      images: recipeImages,
      user: recipeUser,
      isFavorited: json['is_favorited'] ?? false,
      favoriteCount: json['favorite_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      views: json['views'] ?? 0,
      preparationTime: json['preparation_time']?.toString(),
      ingredients: json['ingredients']?.toString(),
      instructions: json['instructions']?.toString(),
      tips: json['tips']?.toString(),
      servingCount: json['serving_count'] is int ? json['serving_count'] : null,
      difficulty: json['difficulty']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_filename': imageFilename,
      'views': views,
      'preparation_time': preparationTime,
      'ingredients': ingredients,
      'instructions': instructions,
      'is_favorited': isFavorited,
      'favorite_count': favoriteCount,
      'comment_count': commentCount,
      'tips': tips,
      'serving_count': servingCount,
      'difficulty': difficulty,
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