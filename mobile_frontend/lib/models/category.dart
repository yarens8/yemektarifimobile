class Category {
  final int id;
  final String name;
  final String icon;

  Category({
    required this.id,
    required this.name,
    required this.icon,
  });

  // JSON'dan Category nesnesine dönüştürme
  factory Category.fromJson(Map<String, dynamic> json) {
    dynamic rawId = json['id'];
    int id;
    
    if (rawId is int) {
      id = rawId;
    } else if (rawId is String) {
      id = int.tryParse(rawId) ?? 0;
    } else {
      id = 0;
    }

    return Category(
      id: id,
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
    );
  }

  // Category nesnesinden JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
    };
  }

  // Kategorilerin statik listesi
  static List<Category> getPresetCategories() {
    return [
      Category(id: 1, name: 'Ana Yemek', icon: ''),
      Category(id: 2, name: 'Çorba', icon: ''),
      Category(id: 3, name: 'Salata', icon: ''),
      Category(id: 4, name: 'Tatlı', icon: ''),
      Category(id: 5, name: 'Aperatif', icon: ''),
      Category(id: 6, name: 'İçecek', icon: ''),
      Category(id: 7, name: 'Kahvaltılık', icon: ''),
      Category(id: 8, name: 'Tümü', icon: ''),
    ];
  }
} 