import 'api_service.dart';

class PublicOwnerService {
  static Future<Map<String, dynamic>> getProfile(int ownerId) async {
    final response = await ApiService.getAuth(
      '/api/duenios/$ownerId/perfil-publico',
    );
    dynamic data = response['body'] ?? response;
    if (data is Map) data = data['data'] ?? data;
    if (data is! Map) throw Exception('No se pudo cargar el perfil del dueño.');
    return Map<String, dynamic>.from(data);
  }
}
