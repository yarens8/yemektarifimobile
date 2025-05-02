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
        
        // Mevcut tarif varsa, puanlama bilgilerini koru
        final existingRecipeIndex = _recipesByCategory[categoryId]!
            .indexWhere((r) => r['id'] == recipe['id']);
            
        if (existingRecipeIndex != -1) {
          // Mevcut tarifi güncelle ama puanlama bilgilerini koru
          final existingRecipe = _recipesByCategory[categoryId]![existingRecipeIndex];
          recipe['average_rating'] = recipe['average_rating'] ?? existingRecipe['average_rating'];
          recipe['rating_count'] = recipe['rating_count'] ?? existingRecipe['rating_count'];
          recipe['user_rating'] = recipe['user_rating'] ?? existingRecipe['user_rating'];
          _recipesByCategory[categoryId]![existingRecipeIndex] = recipe;
        } else {
          // Yeni tarif ekle
        _recipesByCategory[categoryId]!.add(recipe);
        }
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

  // Tarif puanlandıktan sonra tarifleri güncelle
  Future<void> updateRecipeRating(int recipeId, double averageRating, int ratingCount) async {
    try {
      // Tüm kategorilerdeki tarifleri kontrol et ve güncelle
      _recipesByCategory.forEach((categoryId, recipes) {
        for (var i = 0; i < recipes.length; i++) {
          if (recipes[i]['id'] == recipeId) {
            recipes[i]['average_rating'] = averageRating;
            recipes[i]['rating_count'] = ratingCount;
          }
        }
      });
      notifyListeners();
    } catch (e) {
      print('Error updating recipe rating: $e');
    }
  }
} 