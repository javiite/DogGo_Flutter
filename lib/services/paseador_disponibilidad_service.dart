import 'api_service.dart';

abstract final class PaseadorDisponibilidadService {
  static const _endpoint = '/api/disponibilidad/mi-agenda';

  static Future<Map<String, dynamic>> obtenerMiAgenda({
    DateTime? desdeUtc,
    DateTime? hastaUtc,
  }) async {
    final query = <String, String>{};
    if (desdeUtc != null) {
      query['desdeUtc'] = desdeUtc.toUtc().toIso8601String();
    }
    if (hastaUtc != null) {
      query['hastaUtc'] = hastaUtc.toUtc().toIso8601String();
    }
    final suffix = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    final response = await ApiService.getAuth('$_endpoint$suffix');
    _requireSuccess(response, 'No se pudo cargar tu disponibilidad.');
    return _map(_body(response)['data']);
  }

  static Future<Map<String, dynamic>> obtenerDisponibilidadPublica({
    required int paseadorId,
    required DateTime desdeUtc,
    required DateTime hastaUtc,
  }) async {
    final query = Uri(
      queryParameters: {
        'desdeUtc': desdeUtc.toUtc().toIso8601String(),
        'hastaUtc': hastaUtc.toUtc().toIso8601String(),
      },
    ).query;
    final response = await ApiService.getAuth(
      '/api/disponibilidad/paseadores/$paseadorId?$query',
    );
    _requireSuccess(response, 'No se pudo consultar la agenda del paseador.');
    return _map(_body(response)['data']);
  }

  static Future<void> guardarMiAgenda({
    required bool disponible,
    required String zonaHoraria,
    required List<Map<String, dynamic>> horarios,
  }) async {
    final response = await ApiService.putAuth(_endpoint, {
      'disponible': disponible,
      'zonaHoraria': zonaHoraria,
      'horarios': horarios,
    });
    _requireSuccess(response, 'No se pudo guardar tu disponibilidad.');
  }

  static Future<Map<String, dynamic>> crearBloqueo({
    required DateTime inicioUtc,
    required DateTime finUtc,
    String? motivo,
  }) async {
    final response = await ApiService.postAuth('$_endpoint/bloqueos', {
      'inicioUtc': inicioUtc.toUtc().toIso8601String(),
      'finUtc': finUtc.toUtc().toIso8601String(),
      'motivo': motivo?.trim().isEmpty == true ? null : motivo?.trim(),
    });
    _requireSuccess(response, 'No se pudo guardar el bloqueo.');
    return _map(_body(response)['data']);
  }

  static Future<void> eliminarBloqueo(int bloqueoId) async {
    final response = await ApiService.deleteAuth(
      '$_endpoint/bloqueos/$bloqueoId',
    );
    _requireSuccess(response, 'No se pudo eliminar el bloqueo.');
  }

  static void _requireSuccess(Map<String, dynamic> response, String fallback) {
    final body = _body(response);
    final status = response['statusCode'];
    if (status is int &&
        status >= 200 &&
        status < 300 &&
        body['success'] != false) {
      return;
    }
    throw Exception(body['message'] ?? body['error'] ?? fallback);
  }

  static Map<String, dynamic> _body(Map<String, dynamic> response) {
    return _map(response['body'] ?? response);
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }
}
