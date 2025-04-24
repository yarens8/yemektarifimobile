class Favorite {
  final int userId;
  final int recipeId;

  Favorite({
    required this.userId,
    required this.recipeId,
  });

  // JSON'dan Favorite nesnesine dönüştürme
  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      userId: json['user_id'] as int,
      recipeId: json['recipe_id'] as int,
    );
  }

  // Favorite nesnesinden JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'recipe_id': recipeId,
    };
  }

  // Eşitlik kontrolü için override
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Favorite &&
        other.userId == userId &&
        other.recipeId == recipeId;
  }

  @override
  int get hashCode => userId.hashCode ^ recipeId.hashCode;
} 