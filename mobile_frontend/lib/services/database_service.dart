import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class DatabaseService {
  static final _logger = Logger('DatabaseService');
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android Emulator için localhost

  static Future<List<Map<String, dynamic>>> query(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$endpoint'));

      if (response.statusCode == 200) {
        _logger.info('API çağrısı başarılı: $endpoint');
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception('API hatası: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('API çağrısı hatası: $e');
      rethrow;
    }
  }

  static Future<void> execute(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        _logger.info('API çağrısı başarılı: $endpoint');
      } else {
        throw Exception('API hatası: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('API çağrısı hatası: $e');
      rethrow;
    }
  }

  // Örnek kullanımlar:
  static Future<List<Map<String, dynamic>>> getCategories() async {
    return await query('categories');
  }

  static Future<List<Map<String, dynamic>>> getRecipes() async {
    return await query('recipes');
  }

  static Future<List<Map<String, dynamic>>> getRecipesByCategory(
      int categoryId) async {
    return await query('recipes/category/$categoryId');
  }

  static Future<void> addRecipe(Map<String, dynamic> recipeData) async {
    await execute('recipes', recipeData);
  }
}
