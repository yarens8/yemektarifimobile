import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:dio/dio.dart';

class ApiService {
  // Fiziksel cihaz için gerçek IP adresi
  static const String baseUrl =
      'http://10.0.2.2:5000'; // Android Emulator için localhost
  final _logger = Logger('ApiService');
  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  ApiService() {
    // Interceptor ekle
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) async {
        _logger.severe('API Hatası: ${e.message}');
        if (e.response != null) {
          _logger.severe('Yanıt verisi: ${e.response?.data}');
        }

        // Bağlantı hatası durumunda yeniden dene
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.unknown) {
          _logger.info('Bağlantı hatası. Yeniden deneniyor...');

          // 3 kez yeniden deneme yap
          for (var i = 0; i < 3; i++) {
            try {
              final response = await _dio.fetch(e.requestOptions);
              return handler.resolve(response);
            } catch (retryError) {
              _logger.severe('Yeniden deneme başarısız: $retryError');
              await Future.delayed(
                  const Duration(seconds: 2)); // 2 saniye bekle
            }
          }
        }
        return handler.next(e);
      },
    ));
  }

  // Kategorileri getir
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      print('Fetching categories...');  // Debug print
      final response = await _dio.get('/api/categories');
      print('Categories response: ${response.data}');  // Debug print
      
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      print('Invalid categories response format');  // Debug print
      return [];
    } catch (e) {
      print('Error fetching categories: $e');  // Debug print
      return [];
    }
  }

  // Tüm tarifleri getir
  Future<List<Map<String, dynamic>>> getRecipes() async {
    try {
      _logger.info('Tüm tarifler için API isteği yapılıyor...');
      final response = await _dio.get('/api/recipes');
      _logger.info('API yanıtı alındı. Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return List<Map<String, dynamic>>.from(data);
      }
      throw Exception('Tarifler alınamadı: ${response.statusCode}');
    } on DioException catch (e) {
      _logger.severe('Dio hatası: ${e.message}');
      if (e.type == DioExceptionType.unknown) {
        throw Exception(
            'Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.');
      }
      rethrow;
    } catch (e) {
      _logger.severe('Beklenmeyen hata: $e');
      rethrow;
    }
  }

  // Kategoriye göre tarifleri getir
  Future<List<Map<String, dynamic>>> getRecipesByCategory(
      int categoryId) async {
    try {
      print('Fetching recipes for category $categoryId...');  // Debug print
      final response = await _dio.get('/api/recipes/category/$categoryId');
      print('Category recipes response: ${response.data}');  // Debug print
      
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      print('Invalid category recipes response format');  // Debug print
      return [];
    } catch (e) {
      print('Error fetching category recipes: $e');  // Debug print
      return [];
    }
  }

  // Tarif detayını getir
  Future<Map<String, dynamic>> getRecipeDetail(int recipeId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/recipes/$recipeId'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Tarif detayı yüklenirken hata: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Tarif detayı yüklenirken hata: $e');
    }
  }

  // Tarif ara
  Future<List<Map<String, dynamic>>> searchRecipes(String query) async {
    try {
      print('Searching recipes with query: $query');  // Debug print
      final response = await _dio.get('/api/recipes/search', queryParameters: {'q': query});
      print('Search response: ${response.data}');  // Debug print
      
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      print('Invalid search response format');  // Debug print
      return [];
    } catch (e) {
      print('Error searching recipes: $e');  // Debug print
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTopRecipes() async {
    try {
      print('Fetching top recipes...');  // Debug print
      final response = await _dio.get('/api/top-recipes');
      print('Top recipes response: ${response.data}');  // Debug print
      
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      print('Invalid recipes response format');  // Debug print
      return [];
    } catch (e) {
      print('Error fetching recipes: $e');  // Debug print
      return [];
    }
  }
}
