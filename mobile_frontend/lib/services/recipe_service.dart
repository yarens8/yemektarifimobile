import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';
import '../config/api_config.dart';

class RecipeService {
  // API'nin base URL'i
  static const String baseUrl = ApiConfig.baseUrl;
  static const int maxRetries = ApiConfig.maxRetries;
  static const Duration timeout = Duration(seconds: ApiConfig.timeoutSeconds);

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
        final url = Uri.parse('$baseUrl/favorites').replace(
          queryParameters: {
            'user_id': userId.toString(),
          },
        );
        print('Attempt ${retryCount + 1}: Request URL: $url');

        final client = http.Client();
        try {
          final response = await client.get(
            url,
            headers: ApiConfig.defaultHeaders,
          ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));

          print('Response status code: ${response.statusCode}');
          final responseBody = response.body;
          print('Response body: $responseBody');
          
          if (response.statusCode == 200) {
            if (responseBody.isEmpty) {
              throw Exception('Boş yanıt alındı');
            }

            final Map<String, dynamic> responseData = json.decode(responseBody);
            final List<dynamic> data = responseData['recipes'] ?? [];
            print('Backend response data: $data');
            
            final recipes = data.map((json) => Recipe.fromJson(json)).toList();
            return recipes;
          } else {
            final error = _parseError(response);
            throw Exception('Sunucu hatası: $error (Status: ${response.statusCode})');
          }
        } catch (e) {
          print('Error parsing response: $e');
          throw e;
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

  Future<Map<String, dynamic>> createRecipe({
    required String title,
    required int userId,
    required int categoryId,
    required String ingredients,
    required String instructions,
    String? servings,
    String? prepTime,
    String? cookTime,
    String? tips,
    String? imageUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recipes/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': title,
          'user_id': userId,
          'category_id': categoryId,
          'ingredients': ingredients,
          'instructions': instructions,
          'servings': servings,
          'prep_time': prepTime,
          'cook_time': cookTime,
          'tips': tips,
          'image_url': imageUrl,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'recipe': data['recipe'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Tarif eklenirken bir hata oluştu',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bir hata oluştu: $e',
      };
    }
  }

  // Tarife puan verme
  Future<Map<String, dynamic>> rateRecipe({
    required int recipeId,
    required int userId,
    required int rating,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recipes/$recipeId/rate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'rating': rating,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'average_rating': data['average_rating'],
          'rating_count': data['rating_count'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Puan verme işlemi başarısız oldu',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bir hata oluştu: $e',
      };
    }
  }

  // Kullanıcının verdiği puanı getirme
  Future<int?> getUserRating({
    required int recipeId,
    required int userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recipes/$recipeId/user-rating').replace(
          queryParameters: {
            'user_id': userId.toString(),
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['rating'];
      }
      return null;
    } catch (e) {
      print('Error getting user rating: $e');
      return null;
    }
  }
} 