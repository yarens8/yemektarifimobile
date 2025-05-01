class ApiConfig {
  // API'nin temel URL'i
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  
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