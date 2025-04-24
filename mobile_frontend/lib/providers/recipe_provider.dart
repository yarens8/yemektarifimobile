import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RecipeProvider extends ChangeNotifier {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _categories = [];
  Map<int, List<Map<String, dynamic>>> _recipesByCategory = {};
  bool _isLoading = true;

  // Getter'lar
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get categories => _categories;
  Map<int, List<Map<String, dynamic>>> get recipesByCategory => _recipesByCategory;
  List<Map<String, dynamic>> get recipes {
    return recipesByCategory.values.expand((list) => list).toList();
  }

  // İlk veri yüklemesi
  Future<void> loadInitialData() async {
    if (_categories.isNotEmpty) return; // Veriler zaten yüklüyse tekrar çekme
    await _refreshData();
  }

  // Verileri yenile
  Future<void> refreshData() async {
    await _refreshData();
  }

  // Verileri yenileme işlemi
  Future<void> _refreshData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Kategorileri ve tarifleri paralel olarak yükle
      final results = await Future.wait([
        _apiService.getCategories(),
        _apiService.getRecipes(),
      ]);

      _categories = results[0];
      final recipes = results[1];

      // Tarifleri kategorilere göre grupla
      _recipesByCategory.clear();
      for (var recipe in recipes) {
        final categoryId = recipe['category_id'] as int;
        if (!_recipesByCategory.containsKey(categoryId)) {
          _recipesByCategory[categoryId] = [];
        }
        _recipesByCategory[categoryId]!.add(recipe);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Belirli bir kategorinin tariflerini getir
  List<Map<String, dynamic>> getRecipesForCategory(int categoryId) {
    return _recipesByCategory[categoryId] ?? [];
  }

  // Yeni tarif eklendikten sonra
  Future<void> onRecipeAdded() async {
    await refreshData(); // Tüm verileri yenile
  }

  // Tarif silindikten sonra
  Future<void> onRecipeDeleted() async {
    await refreshData(); // Tüm verileri yenile
  }

  // Tarif arama
  Future<List<Map<String, dynamic>>> searchRecipes(String query) async {
    try {
      return await _apiService.searchRecipes(query);
    } catch (e) {
      rethrow;
    }
  }
} 