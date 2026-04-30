import 'api_service.dart';

class PaseosService {
  static Future<Map<String, dynamic>> obtenerMisPaseos() async {
    final response = await ApiService.getAuth('/api/paseos/mis-paseos');

    final statusCode = response['statusCode'];
    final body = response['body'];

    if (statusCode == 200 && body['success'] == true) {
      return {
        'success': true,
        'data': body['data'],
      };
    }

    return {
      'success': false,
      'message': body['message'] ?? 'No se pudieron obtener los paseos.',
    };
  }

  static Future<Map<String, dynamic>> obtenerPaseoPorId(int id) async {
    final response = await ApiService.getAuth('/api/paseos/$id');

    final statusCode = response['statusCode'];
    final body = response['body'];

    if (statusCode == 200 && body['success'] == true) {
      return {
        'success': true,
        'data': body['data'],
      };
    }

    return {
      'success': false,
      'message': body['message'] ?? 'No se pudo obtener el paseo.',
    };
  }

  static Future<Map<String, dynamic>> crearPaseo({
    required int paseadorId,
    required int perroId,
    required DateTime fechaProgramada,
    required int duracionMinutos,
  }) async {
    final response = await ApiService.post(
      '/api/paseos',
      {
        'paseadorId': paseadorId,
        'perroId': perroId,
        'fechaProgramada': fechaProgramada.toIso8601String(),
        'duracionMinutos': duracionMinutos,
      },
    );

    final statusCode = response['statusCode'];
    final body = response['body'];

    if ((statusCode == 200 || statusCode == 201) && body['success'] == true) {
      return {
        'success': true,
        'message': body['message'] ?? 'Paseo creado correctamente.',
        'data': body['data'],
      };
    }

    return {
      'success': false,
      'message': body['message'] ?? 'No se pudo crear el paseo.',
    };
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

  static Future<Map<String, dynamic>> cancelarPaseo(int id) async {
    final response = await ApiService.putAuth('/api/paseos/$id/cancelar', {});
    return _normalizarRespuesta(response, 'Paseo cancelado correctamente.');
  }

  static Map<String, dynamic> _normalizarRespuesta(
    Map<String, dynamic> response,
    String okMessage,
  ) {
    final statusCode = response['statusCode'];
    final body = response['body'];

    if (statusCode == 200 && body['success'] == true) {
      return {
        'success': true,
        'message': body['message'] ?? okMessage,
      };
    }

    return {
      'success': false,
      'message': body['message'] ?? 'No se pudo completar la acción.',
    };
  }
}