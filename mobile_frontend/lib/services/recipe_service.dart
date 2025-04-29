import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class RecipeService {
  // API'nin base URL'i
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  static const int maxRetries = 3;
  static const Duration timeout = Duration(seconds: 10);

  Future<List<Recipe>> getUserRecipes(int userId) async {
    print('Fetching recipes for userId: $userId');
    int retryCount = 0;
    Exception? lastError;
    
    while (retryCount < maxRetries) {
      try {
        final url = Uri.parse('$baseUrl/recipes/user/$userId');
        print('Attempt ${retryCount + 1}: Request URL: $url');

        final client = http.Client();
        try {
          final response = await client.get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Connection': 'keep-alive',
            },
          ).timeout(timeout);

          print('Response status code: ${response.statusCode}');
          if (response.statusCode == 200) {
            final responseBody = response.body;
            print('Response body length: ${responseBody.length}');
            
            if (responseBody.isEmpty) {
              throw Exception('Boş yanıt alındı');
            }

            final List<dynamic> data = json.decode(responseBody);
            return data.map((json) => Recipe.fromJson(json)).toList();
          } else {
            final error = _parseError(response);
            throw Exception(error);
          }
        } finally {
          client.close();
        }
      } catch (e) {
        print('Error in attempt ${retryCount + 1}: $e');
        lastError = e is Exception ? e : Exception(e.toString());
        
        if (retryCount < maxRetries - 1) {
          retryCount++;
          // Exponential backoff: Her denemede bekleme süresini artır
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
        }
        break;
      }
    }
    
    throw lastError ?? Exception('Bağlantı hatası: Sunucuya ulaşılamıyor');
  }

  Future<Recipe> getRecipeDetail(int recipeId) async {
    print('Fetching recipe detail for id: $recipeId');
    int retryCount = 0;
    Exception? lastError;
    
    while (retryCount < maxRetries) {
      try {
        final url = Uri.parse('$baseUrl/recipes/$recipeId');
        print('Attempt ${retryCount + 1}: Request URL: $url');

        final client = http.Client();
        try {
          final response = await client.get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Connection': 'keep-alive',
            },
          ).timeout(timeout);

          print('Response status code: ${response.statusCode}');
          if (response.statusCode == 200) {
            final responseBody = response.body;
            print('Response body: $responseBody');
            
            if (responseBody.isEmpty) {
              throw Exception('Boş yanıt alındı');
            }

            final Map<String, dynamic> data = json.decode(responseBody);
            return Recipe.fromJson(data);
          } else {
            final error = _parseError(response);
            throw Exception(error);
          }
        } finally {
          client.close();
        }
      } catch (e) {
        print('Error in attempt ${retryCount + 1}: $e');
        lastError = e is Exception ? e : Exception(e.toString());
        
        if (retryCount < maxRetries - 1) {
          retryCount++;
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
        }
        break;
      }
    }
    
    throw lastError ?? Exception('Bağlantı hatası: Sunucuya ulaşılamıyor');
  }

  String _parseError(http.Response response) {
    try {
      final body = json.decode(response.body);
      return body['error'] ?? 'Bilinmeyen bir hata oluştu';
    } catch (e) {
      return 'Sunucu yanıtı işlenemedi: ${response.statusCode}';
    }
  }

  Future<(bool, String)> addToFavorites(int userId, int recipeId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/add'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'recipe_id': recipeId,
        }),
      );

      final Map<String, dynamic> body = json.decode(response.body);
      if (response.statusCode == 200) {
        return (true, body['message']?.toString() ?? 'Tarif favorilere eklendi');
      } else {
        return (false, body['message']?.toString() ?? 'Bir hata oluştu');
      }
    } catch (e) {
      return (false, 'Bir hata oluştu: $e');
    }
  }

  Future<(bool, String)> removeFromFavorites(int userId, int recipeId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/favorites/remove'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'recipe_id': recipeId,
        }),
      );

      final Map<String, dynamic> body = json.decode(response.body);
      if (response.statusCode == 200) {
        return (true, body['message']?.toString() ?? 'Tarif favorilerden kaldırıldı');
      } else {
        return (false, body['message']?.toString() ?? 'Bir hata oluştu');
      }
    } catch (e) {
      return (false, 'Bir hata oluştu: $e');
    }
  }

  Future<bool> isFavorite(int userId, int recipeId) async {
    try {
      final uri = Uri.parse('$baseUrl/favorites/check').replace(
        queryParameters: {
          'user_id': userId.toString(),
          'recipe_id': recipeId.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body['is_favorite'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<Recipe>> getUserFavorites(int userId) async {
    print('Fetching favorite recipes for userId: $userId');
    int retryCount = 0;
    Exception? lastError;
    
    while (retryCount < maxRetries) {
      try {
        final uri = Uri.parse('$baseUrl/favorites').replace(
          queryParameters: {
            'user_id': userId.toString(),
          },
        );
        print('Attempt ${retryCount + 1}: Request URL: $uri');

        final client = http.Client();
        try {
          final response = await client.get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Connection': 'keep-alive',
            },
          ).timeout(timeout);

          print('Response status code: ${response.statusCode}');
          if (response.statusCode == 200) {
            final responseBody = response.body;
            print('Response body length: ${responseBody.length}');
            
            if (responseBody.isEmpty) {
              return [];
            }

            final Map<String, dynamic> data = json.decode(responseBody);
            final List<dynamic> recipes = data['recipes'] ?? [];
            return recipes.map((json) => Recipe.fromJson(json)).toList();
          } else {
            final error = _parseError(response);
            throw Exception(error);
          }
        } finally {
          client.close();
        }
      } catch (e) {
        print('Error in attempt ${retryCount + 1}: $e');
        lastError = e is Exception ? e : Exception(e.toString());
        
        if (retryCount < maxRetries - 1) {
          retryCount++;
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
        }
        break;
      }
    }
    
    throw lastError ?? Exception('Bağlantı hatası: Sunucuya ulaşılamıyor');
  }

  Future<List<Recipe>> getFavoriteRecipes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recipes/favorites'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['recipes'] ?? [];
        return data.map((json) => Recipe.fromJson(json)).toList();
      }
      throw Exception('Favori tarifler alınamadı');
    } catch (e) {
      throw Exception('Favori tarifler alınamadı: $e');
    }
  }
} 