import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiService {
  static Future<String> obtenerBaseUrl() async {
    final baseUrl = await StorageService.obtenerBaseUrl();

    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('No hay URL del servidor configurada.');
    }

    return baseUrl;
  }

  static Future<String?> obtenerToken() async {
    return await StorageService.obtenerToken();
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final baseUrl = await obtenerBaseUrl();
    final url = Uri.parse('$baseUrl$endpoint');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    return _armarRespuesta(response);
  }

  static Future<Map<String, dynamic>> postAuth(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final baseUrl = await obtenerBaseUrl();
    final token = await obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay token guardado. Inicia sesión otra vez.');
    }

    final url = Uri.parse('$baseUrl$endpoint');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return _armarRespuesta(response);
  }

  static Future<Map<String, dynamic>> getAuth(String endpoint) async {
    final baseUrl = await obtenerBaseUrl();
    final token = await obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay token guardado. Inicia sesión otra vez.');
    }

    final url = Uri.parse('$baseUrl$endpoint');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return _armarRespuesta(response);
  }

  static Future<Map<String, dynamic>> putAuth(
    String endpoint, [
    Map<String, dynamic>? body,
  ]) async {
    final baseUrl = await obtenerBaseUrl();
    final token = await obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay token guardado. Inicia sesión otra vez.');
    }

    final url = Uri.parse('$baseUrl$endpoint');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body != null ? jsonEncode(body) : null,
    );

    return _armarRespuesta(response);
  }

  static Future<Map<String, dynamic>> deleteAuth(String endpoint) async {
    final baseUrl = await obtenerBaseUrl();
    final token = await obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay token guardado. Inicia sesión otra vez.');
    }

    final url = Uri.parse('$baseUrl$endpoint');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return _armarRespuesta(response);
  }

  static Map<String, dynamic> _armarRespuesta(http.Response response) {
    dynamic responseBody;

    try {
      responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    } catch (_) {
      responseBody = {
        'success': false,
        'message': response.body,
      };
    }

    return {
      'statusCode': response.statusCode,
      'body': responseBody,
    };
  }
}