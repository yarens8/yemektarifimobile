class ApiConfig {
  // API'nin temel URL'i
  static const String baseUrl = 'http://10.0.2.2:5000/api';  // Android Emulator için localhost
  // static const String baseUrl = 'http://localhost:5000/api';  // iOS Simulator için
  
  // API istekleri için timeout süresi
  static const int timeoutSeconds = 30;
  
  // Maksimum yeniden deneme sayısı
  static const int maxRetries = 3;

  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Connection': 'keep-alive',
  };
} 