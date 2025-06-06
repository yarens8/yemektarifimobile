import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';
import '../models/comment.dart';
import '../config/api_config.dart';
import '../utils/api_constants.dart';
import '../services/auth_service.dart';

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

        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 30)); // Timeout süresini artırdık

        print('Response status code: ${response.statusCode}');
        if (response.statusCode == 200) {
          final responseBody = response.body;
          print('Response body: $responseBody');
          
          if (responseBody.isEmpty) {
            return [];
          }

          try {
            final List<dynamic> jsonData = json.decode(responseBody);
            print('Parsed JSON data: $jsonData');
            return jsonData.map((json) => Recipe.fromJson(json)).toList();
          } catch (e) {
            print('JSON parsing error: $e');
            throw Exception('Veri işlenirken hata oluştu: $e');
          }
        } else {
          final error = _parseError(response);
          throw Exception(error);
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
          final responseBody = utf8.decode(response.bodyBytes);
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

  // Yorum işlemleri için fonksiyonlar
  Future<List<Comment>> getRecipeComments(int recipeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recipes/$recipeId/comments'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Comment.fromJson(json)).toList();
      } else {
        throw Exception('Yorumlar alınamadı');
      }
    } catch (e) {
      throw Exception('Yorumlar alınırken bir hata oluştu: $e');
    }
  }

  Future<Map<String, dynamic>?> addComment({
    required int recipeId,
    required int userId,
    required String content,
  }) async {
    try {
      print('Adding comment with data: recipeId=$recipeId, userId=$userId, content=$content');
      final response = await http.post(
        Uri.parse('$baseUrl/recipes/$recipeId/comments'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'content': content,
        }),
      );

      print('Comment add response status: ${response.statusCode}');
      print('Comment add response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'id': data['id'],
          'content': content,
          'user_id': userId,
          'recipe_id': recipeId,
          'created_at': DateTime.now().toIso8601String(),
          'username': data['username'],
        };
      } else {
        print('Comment add failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  Future<bool> deleteComment(int commentId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/comments/$commentId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Yorum silinirken bir hata oluştu: $e');
    }
  }

  Future<Recipe> getRecipeById(int id) async {
    print('Fetching recipe with id: $id');
    int retryCount = 0;
    Exception? lastError;
    
    while (retryCount < maxRetries) {
      try {
        final url = Uri.parse('$baseUrl/recipes/$id');
        print('Attempt ${retryCount + 1}: Request URL: $url');

        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 30));

        print('Response status code: ${response.statusCode}');
        print('Response headers: ${response.headers}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final responseBody = response.body;
          
          if (responseBody.isEmpty) {
            throw Exception('Tarif bulunamadı');
          }

          try {
            final dynamic jsonData = json.decode(responseBody);
            print('Parsed JSON data type: ${jsonData.runtimeType}');
            print('Parsed JSON data: $jsonData');
            
            // API yanıtı bir liste olarak geliyorsa ilk elemanı al
            if (jsonData is List) {
              if (jsonData.isEmpty) {
                throw Exception('Tarif bulunamadı');
              }
              return Recipe.fromJson(jsonData[0]);
            }
            
            // API yanıtı bir map olarak geliyorsa direkt kullan
            if (jsonData is Map<String, dynamic>) {
              return Recipe.fromJson(jsonData);
            }
            
            throw Exception('Geçersiz veri formatı');
          } catch (e) {
            print('JSON parsing error: $e');
            throw Exception('Veri işlenirken hata oluştu: $e');
          }
        } else {
          final error = _parseError(response);
          throw Exception(error);
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

  Future<List<Recipe>> suggestRecipes({
    required List<String> ingredients,
    Map<String, dynamic>? filters,
  }) async {
    try {
      print('[DEBUG] suggestRecipes called with:');
      print('Ingredients: $ingredients');
      print('Filters: $filters');

      final bodyData = {
        'selectedIngredients': ingredients,
        'filters': filters ?? {},
      };
      print('[DEBUG] Request body: ${jsonEncode(bodyData)}');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/mobile/suggest_recipes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await AuthService.getToken()}',
        },
        body: jsonEncode(bodyData),
      );

      print('[DEBUG] Response status: ${response.statusCode}');
      print('[DEBUG] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((recipeData) => Recipe.fromJson(Map<String, dynamic>.from(recipeData))).toList();
      }
      throw Exception('Tarif önerileri alınamadı: ${response.statusCode}');
    } catch (e) {
      print('[DEBUG] Error in suggestRecipes: $e');
      throw Exception('Tarif önerileri alınırken bir hata oluştu: $e');
    }
  }
} 