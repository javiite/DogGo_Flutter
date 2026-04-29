import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String baseUrlKey = 'base_url';
  static const String tokenKey = 'auth_token';

  static Future<void> guardarBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(baseUrlKey, url);
  }

  static Future<String?> obtenerBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(baseUrlKey);
  }

  static Future<void> limpiarBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(baseUrlKey);
  }

  static Future<void> guardarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  static Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<void> limpiarToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }
}