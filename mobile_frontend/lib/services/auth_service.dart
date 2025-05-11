import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // API'nin base URL'i
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  User? _currentUser;
  static const String _tokenKey = 'auth_token';

  // Setter method for currentUser
  void setCurrentUser(User user) {
    _currentUser = user;
  }

  // Kullanıcı girişi
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': data['user'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Giriş işlemi başarısız oldu',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bir hata oluştu: $e',
      };
    }
  }

  // Kullanıcı kaydı
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'user': data['user'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Kayıt işlemi başarısız oldu',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bir hata oluştu: $e',
      };
    }
  }

  // Kullanıcı bilgilerini getir
  Future<Map<String, dynamic>?> getUserDetails() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/user'),
        headers: {
          'Content-Type': 'application/json',
          // TODO: Token eklenecek
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['user'];
      }
      return null;
    } catch (e) {
      print('Kullanıcı bilgileri alınırken hata: $e');
      return null;
    }
  }

  // Profil bilgilerini güncelle
  Future<Map<String, dynamic>> updateProfile(String username, String email) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': data['user'],
          'message': data['message'] ?? 'Profil başarıyla güncellendi',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Profil güncellenirken bir hata oluştu',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bir hata oluştu: $e',
      };
    }
  }

  // Profil fotoğrafını güncelle
  Future<Map<String, dynamic>> updateProfilePhoto(File photo) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/profile/photo'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          photo.path,
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'photoUrl': data['photoUrl'],
          'message': data['message'] ?? 'Profil fotoğrafı başarıyla güncellendi',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Profil fotoğrafı güncellenirken bir hata oluştu',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bir hata oluştu: $e',
      };
    }
  }

  // Şifre değiştir
  Future<Map<String, dynamic>> changePassword(String email, String currentPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Şifre başarıyla değiştirildi',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Şifre değiştirilirken bir hata oluştu',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bir hata oluştu: $e',
      };
    }
  }

  // Token'ı kaydet
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Token'ı getir
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Token'ı sil
  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Kullanıcı giriş yapmış mı kontrol et
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
} 