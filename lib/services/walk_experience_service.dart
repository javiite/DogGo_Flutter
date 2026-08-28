import 'api_service.dart';
import 'storage_service.dart';

class WalkExperienceService {
  static Future<Map<String, dynamic>> security(int walkId) async => _map(
    await ApiService.getAuth('/api/paseos/$walkId/experiencia/seguridad'),
  );

  static Future<Map<String, dynamic>> generatePins(
    int walkId, {
    required bool deliveryRequiresPin,
  }) async => _map(
    await ApiService.postAuth('/api/paseos/$walkId/experiencia/pines', {
      'entregaRequierePin': deliveryRequiresPin,
    }),
  );

  static Future<Map<String, dynamic>> confirmTransfer(
    int walkId, {
    required String type,
    String? pin,
  }) async => _map(
    await ApiService.postAuth(
      '/api/paseos/$walkId/experiencia/confirmaciones',
      {'tipo': type, if (pin?.trim().isNotEmpty == true) 'pin': pin!.trim()},
    ),
  );

  static Future<List<Map<String, dynamic>>> events(int walkId) async => _list(
    await ApiService.getAuth('/api/paseos/$walkId/experiencia/eventos'),
  );

  static Future<Map<String, dynamic>> registerEvent(
    int walkId, {
    required String type,
    String? description,
    String? value,
    double? latitude,
    double? longitude,
  }) async => _map(
    await ApiService.postAuth('/api/paseos/$walkId/experiencia/eventos', {
      'tipo': type,
      if (description?.trim().isNotEmpty == true)
        'descripcion': description!.trim(),
      if (value?.trim().isNotEmpty == true) 'valor': value!.trim(),
      'latitud': ?latitude,
      'longitud': ?longitude,
    }),
  );

  static Future<Map<String, dynamic>> uploadEventPhoto(
    int walkId,
    String path, {
    String description = '',
  }) async => _map(
    await ApiService.postMultipartAuth(
      '/api/paseos/$walkId/experiencia/eventos/foto',
      filePath: path,
      fields: {'descripcion': description.trim()},
    ),
  );

  static Future<Map<String, dynamic>> report(int walkId) async =>
      _map(await ApiService.getAuth('/api/paseos/$walkId/experiencia/reporte'));

  static Future<Map<String, dynamic>> petHistory(int petId) async =>
      _map(await ApiService.getAuth('/api/perros/$petId/historial-paseos'));

  static Future<Map<String, dynamic>> createShareLink(
    int walkId, {
    int validHours = 6,
  }) async {
    final data = _map(
      await ApiService.postAuth(
        '/api/paseos/$walkId/experiencia/seguimiento-compartido',
        {'horasVigencia': validHours},
      ),
    );
    final token = data['token']?.toString() ?? '';
    final baseUrl = await StorageService.obtenerBaseUrl() ?? '';
    data['url'] = '$baseUrl/seguimiento/$token';
    return data;
  }

  static Future<void> revokeShareLink(int walkId) async {
    _map(
      await ApiService.deleteAuth(
        '/api/paseos/$walkId/experiencia/seguimiento-compartido',
      ),
    );
  }

  static Map<String, dynamic> _map(Map<String, dynamic> response) {
    final status = response['statusCode'];
    final body = response['body'];
    if (status is int && (status < 200 || status >= 300)) {
      throw Exception(
        body is Map
            ? body['message']?.toString() ?? 'No se pudo completar la acción.'
            : 'No se pudo completar la acción.',
      );
    }
    dynamic value = body ?? response;
    if (value is Map) value = value['data'] ?? value;
    return value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _list(Map<String, dynamic> response) {
    final status = response['statusCode'];
    final body = response['body'];
    if (status is int && (status < 200 || status >= 300)) {
      throw Exception(
        body is Map
            ? body['message']?.toString() ??
                  'No se pudieron cargar los eventos.'
            : 'No se pudieron cargar los eventos.',
      );
    }
    dynamic value = body;
    if (value is Map) value = value['data'];
    return value is List
        ? value
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : const [];
  }
}
