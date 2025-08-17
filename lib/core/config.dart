import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (Platform.isIOS || Platform.isAndroid) {
      // Use your machine's IP address when running on physical device
      // Replace with your actual IP address
      return 'http://192.168.0.195:8080';
    }
    // Use localhost for desktop/web
    return 'http://localhost:8080';
  }
}