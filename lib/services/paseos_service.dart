import 'api_service.dart';

class PaseosService {
  static Future<Map<String, dynamic>> obtenerMisPaseos() async {
    final response = await ApiService.getAuth('/api/paseos/mis-paseos');

    final statusCode = response['statusCode'];
    final body = response['body'];

    if (statusCode == 200 && body is Map && body['success'] == true) {
      return {'success': true, 'data': body['data']};
    }

    return {
      'success': false,
      'message': body is Map
          ? body['message'] ?? 'No se pudieron obtener los paseos.'
          : 'No se pudieron obtener los paseos.',
      'statusCode': statusCode,
    };
  }

  static Future<Map<String, dynamic>> obtenerProgramacion(int id) async {
    final response = await ApiService.getAuth('/api/paseos/programaciones/$id');
    return _normalizarRespuesta(response, 'Programación obtenida.');
  }

  static Future<Map<String, dynamic>> actualizarPaseoProgramado({
    required int programacionId,
    required int paseoId,
    required DateTime fechaProgramada,
    required int duracionMinutos,
    required List<int> perroIds,
  }) async {
    final response = await ApiService.putAuth(
      '/api/paseos/programaciones/$programacionId/paseos/$paseoId',
      {
        'fechaProgramada': fechaProgramada.toIso8601String(),
        'duracionMinutos': duracionMinutos,
        'perroIds': perroIds,
      },
    );
    return _normalizarRespuesta(response, 'Paseo actualizado correctamente.');
  }

  static Future<Map<String, dynamic>> cancelarProgramacion(
    int id, {
    String? motivo,
  }) async {
    final response = await ApiService.putAuth(
      '/api/paseos/programaciones/$id/cancelar',
      {'motivo': motivo?.trim()},
    );
    return _normalizarRespuesta(
      response,
      'Programación cancelada correctamente.',
    );
  }

  static Future<Map<String, dynamic>> aceptarProgramacion(int id) async {
    final response = await ApiService.putAuth(
      '/api/paseos/programaciones/$id/aceptar',
    );
    return _normalizarRespuesta(
      response,
      'Programación aceptada correctamente.',
    );
  }

  static Future<Map<String, dynamic>> responderPaseoProgramado({
    required int programacionId,
    required int paseoId,
    required bool aceptar,
    String? motivo,
  }) async {
    final response = await ApiService.putAuth(
      '/api/paseos/programaciones/$programacionId/paseos/$paseoId/respuesta',
      {
        'aceptar': aceptar,
        if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
      },
    );
    return _normalizarRespuesta(
      response,
      aceptar
          ? 'Paseo aceptado correctamente.'
          : 'Paseo rechazado correctamente.',
    );
  }

  static Future<Map<String, dynamic>> aceptarPaseo(int id) async {
    final response = await ApiService.putAuth('/api/paseos/$id/aceptar');
    return _normalizarRespuesta(response, 'Paseo aceptado correctamente.');
  }

  static Future<Map<String, dynamic>> rechazarPaseo(int id) async {
    final response = await ApiService.putAuth('/api/paseos/$id/rechazar');
    return _normalizarRespuesta(response, 'Paseo rechazado correctamente.');
  }

  static Future<Map<String, dynamic>> iniciarPaseo(int id) async {
    final response = await ApiService.putAuth('/api/paseos/$id/iniciar');
    return _normalizarRespuesta(response, 'Paseo iniciado correctamente.');
  }

  static Future<Map<String, dynamic>> finalizarPaseo(int id) async {
    final response = await ApiService.putAuth('/api/paseos/$id/finalizar');
    return _normalizarRespuesta(response, 'Paseo finalizado correctamente.');
  }

  static Future<Map<String, dynamic>> cancelarPaseo(
    int id, {
    String? motivo,
  }) async {
    final data = <String, dynamic>{};

    if (motivo != null && motivo.trim().isNotEmpty) {
      data['motivo'] = motivo.trim();
    }

    final response = await ApiService.putAuth('/api/paseos/$id/cancelar', data);

    return _normalizarRespuesta(response, 'Paseo cancelado correctamente.');
  }

  static Map<String, dynamic> _normalizarRespuesta(
    Map<String, dynamic> response,
    String okMessage,
  ) {
    final statusCode = response['statusCode'];
    final body = response['body'];

    if (statusCode == 200 && body is Map && body['success'] == true) {
      return {
        'success': true,
        'message': body['message'] ?? okMessage,
        'data': body['data'],
      };
    }

    return {
      'success': false,
      'message': body is Map
          ? '${body['message'] ?? 'No se pudo completar la acción.'} Código: $statusCode'
          : 'No se pudo completar la acción. Código: $statusCode',
      'statusCode': statusCode,
      'data': body,
    };
  }
}
