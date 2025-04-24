class Recipe {
  final int recipeId;
  final String title;
  final String description;
  final int categoryId;
  final int viewCount;
  final String categoryName;
  final String imageUrl;

  Recipe({
    required this.recipeId,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.viewCount,
    required this.categoryName,
    required this.imageUrl,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      recipeId: json['RecipeID'] ?? 0,
      title: json['Title'] ?? '',
      description: json['Description'] ?? '',
      categoryId: json['CategoryID'] ?? 0,
      viewCount: json['ViewCount'] ?? 0,
      categoryName: json['CategoryName'] ?? '',
      imageUrl: json['ImageURL'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'RecipeID': recipeId,
      'Title': title,
      'Description': description,
      'CategoryID': categoryId,
      'ViewCount': viewCount,
      'CategoryName': categoryName,
      'ImageURL': imageUrl,
    };
  }
} 