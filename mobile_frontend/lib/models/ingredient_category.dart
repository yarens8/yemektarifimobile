class IngredientCategory {
  final int id;
  final String name;
  final String icon;

  IngredientCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  // JSON'dan IngredientCategory nesnesine dönüştürme
  factory IngredientCategory.fromJson(Map<String, dynamic> json) {
    return IngredientCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      icon: json['icon'] as String,
    );
  }

  // IngredientCategory nesnesinden JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
    };
  }

  // Örnek kategori listesi
  static List<IngredientCategory> getSampleCategories() {
    return [
      IngredientCategory(id: 1, name: 'Sebzeler', icon: 'fa-carrot'),
      IngredientCategory(id: 2, name: 'Meyveler', icon: 'fa-apple-alt'),
      IngredientCategory(id: 3, name: 'Et & Tavuk', icon: 'fa-drumstick'),
      IngredientCategory(id: 4, name: 'Deniz Ürünleri', icon: 'fa-fish'),
      IngredientCategory(id: 5, name: 'Baharatlar', icon: 'fa-mortar-pestle'),
      IngredientCategory(id: 6, name: 'Baklagiller', icon: 'fa-seedling'),
      IngredientCategory(id: 7, name: 'Süt Ürünleri', icon: 'fa-cheese'),
      IngredientCategory(id: 8, name: 'Yağlar', icon: 'fa-oil-can'),
      IngredientCategory(id: 9, name: 'Tahıllar', icon: 'fa-bread-slice'),
      IngredientCategory(id: 10, name: 'İçecekler', icon: 'fa-glass-water'),
    ];
  }

  // Kategori ID'sine göre ikon getirme
  static String getIconForCategory(int categoryId) {
    final category = getSampleCategories().firstWhere(
      (category) => category.id == categoryId,
      orElse: () => IngredientCategory(id: 0, name: '', icon: 'fa-question'),
    );
    return category.icon;
  }
} 