import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  final _authService = AuthService();

  User? get currentUser => _currentUser;

  // Kullanıcı bilgilerini güncelle
  void setUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  // Kullanıcı çıkış yap
  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }

  // Kullanıcı bilgilerini API'den al
  Future<void> fetchUserDetails() async {
    try {
      final userDetails = await _authService.getUserDetails();
      if (userDetails != null) {
        _currentUser = User.fromJson(userDetails);
        notifyListeners();
      }
    } catch (e) {
      print('Kullanıcı bilgileri alınırken hata: $e');
    }
  }
} 