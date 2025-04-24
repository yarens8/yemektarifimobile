class Ingredient {
  final int id;
  final String name;
  final int categoryId;

  Ingredient({
    required this.id,
    required this.name,
    required this.categoryId,
  });

  // JSON'dan Ingredient nesnesine dönüştürme
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as int,
      name: json['name'] as String,
      categoryId: json['category_id'] as int,
    );
  }

  // Ingredient nesnesinden JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
    };
  }

  // Örnek malzeme listesi
  static List<Ingredient> getSampleIngredients() {
    return [
      // Sebzeler (category_id: 1)
      Ingredient(id: 1, name: 'Domates', categoryId: 1),
      Ingredient(id: 2, name: 'Salatalık', categoryId: 1),
      Ingredient(id: 3, name: 'Biber', categoryId: 1),
      Ingredient(id: 4, name: 'Patlıcan', categoryId: 1),
      Ingredient(id: 5, name: 'Havuç', categoryId: 1),
      Ingredient(id: 6, name: 'Soğan', categoryId: 1),
      Ingredient(id: 7, name: 'Sarımsak', categoryId: 1),
      Ingredient(id: 8, name: 'Patates', categoryId: 1),
      Ingredient(id: 9, name: 'Ispanak', categoryId: 1),
      Ingredient(id: 10, name: 'Kabak', categoryId: 1),

      // Meyveler (category_id: 2)
      Ingredient(id: 11, name: 'Elma', categoryId: 2),
      Ingredient(id: 12, name: 'Armut', categoryId: 2),
      Ingredient(id: 13, name: 'Muz', categoryId: 2),
      Ingredient(id: 14, name: 'Portakal', categoryId: 2),
      Ingredient(id: 15, name: 'Limon', categoryId: 2),
      Ingredient(id: 16, name: 'Çilek', categoryId: 2),
      Ingredient(id: 17, name: 'Üzüm', categoryId: 2),
      Ingredient(id: 18, name: 'Karpuz', categoryId: 2),
      Ingredient(id: 19, name: 'Kavun', categoryId: 2),
      Ingredient(id: 20, name: 'Şeftali', categoryId: 2),

      // Etler (category_id: 3)
      Ingredient(id: 21, name: 'Kıyma', categoryId: 3),
      Ingredient(id: 22, name: 'Kuşbaşı', categoryId: 3),
      Ingredient(id: 23, name: 'Tavuk Göğsü', categoryId: 3),
      Ingredient(id: 24, name: 'Tavuk But', categoryId: 3),
      Ingredient(id: 25, name: 'Dana Antrikot', categoryId: 3),
      Ingredient(id: 26, name: 'Kuzu Pirzola', categoryId: 3),
      Ingredient(id: 27, name: 'Hindi', categoryId: 3),
      Ingredient(id: 28, name: 'Sucuk', categoryId: 3),

      // Deniz Ürünleri (category_id: 4)
      Ingredient(id: 29, name: 'Hamsi', categoryId: 4),
      Ingredient(id: 30, name: 'Levrek', categoryId: 4),
    ];
  }
} 