import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:recipe_app/services/auth_service.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/constants/api_constants.dart';

class RecipeService {
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
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((recipeData) => Recipe.fromJson(Map<String, dynamic>.from(recipeData))).toList();
      }
      throw Exception('Tarif önerileri alınamadı: ${response.statusCode}');
    } catch (e) {
      print('[DEBUG] Error in suggestRecipes: $e');
      throw Exception('Tarif önerileri alınırken bir hata oluştu: $e');
    }
  }
} 