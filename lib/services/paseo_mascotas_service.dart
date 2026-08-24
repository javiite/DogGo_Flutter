import 'api_service.dart';

class PaseoMascotasService {
  PaseoMascotasService._();

  static Future<Map<String, dynamic>> obtenerDetalle(int paseoId) async {
    final response = await ApiService.getAuth('/api/paseos/$paseoId/mascotas');

    return _normalize(
      response,
      successMessage: 'Detalle del paseo obtenido.',
      fallbackMessage: 'No se pudo obtener el detalle de las mascotas.',
    );
  }

  static Future<Map<String, dynamic>> proponerCambio({
    required int paseoId,
    required List<int> acceptedPetIds,
    required String reason,
  }) async {
    final cleanIds = acceptedPetIds.where((id) => id > 0).toSet().toList();

    final response = await ApiService.postAuth(
      '/api/paseos/$paseoId/'
      'proponer-cambio-mascotas',
      {'perroIdsAceptados': cleanIds, 'motivo': reason.trim()},
    );

    return _normalize(
      response,
      successMessage: 'Propuesta enviada al dueño.',
      fallbackMessage: 'No se pudo enviar la propuesta.',
    );
  }

  static Future<Map<String, dynamic>> responderCambio({
    required int paseoId,
    required bool accept,
    String? reason,
  }) async {
    final cleanReason = reason?.trim() ?? '';

    final response = await ApiService.postAuth(
      '/api/paseos/$paseoId/'
      'responder-cambio-mascotas',
      {'aceptar': accept, if (cleanReason.isNotEmpty) 'motivo': cleanReason},
    );

    return _normalize(
      response,
      successMessage: accept ? 'Propuesta aceptada.' : 'Propuesta rechazada.',
      fallbackMessage: 'No se pudo responder la propuesta.',
    );
  }

  static Future<Map<String, dynamic>> actualizarMascotas({
    required int paseoId,
    required List<int> petIds,
    String? observations,
  }) async {
    final cleanIds = petIds.where((id) => id > 0).toSet().toList();

    final cleanObservations = observations?.trim() ?? '';

    final response = await ApiService.putAuth('/api/paseos/$paseoId/mascotas', {
      'perroIds': cleanIds,
      if (cleanObservations.isNotEmpty) 'observaciones': cleanObservations,
    });

    return _normalize(
      response,
      successMessage: 'Mascotas actualizadas.',
      fallbackMessage: 'No se pudieron actualizar las mascotas.',
    );
  }

  static Map<String, dynamic> _normalize(
    Map<String, dynamic> response, {
    required String successMessage,
    required String fallbackMessage,
  }) {
    final statusCode = response['statusCode'];

    dynamic body = response['body'] ?? response;

    final bodyMap = body is Map
        ? Map<String, dynamic>.from(body)
        : <String, dynamic>{};

    final successfulStatus = statusCode is int
        ? statusCode >= 200 && statusCode < 300
        : false;

    final declaredSuccess = bodyMap['success'];

    final success = declaredSuccess is bool
        ? declaredSuccess
        : successfulStatus;

    final message =
        (bodyMap['message'] ??
                bodyMap['mensaje'] ??
                response['message'] ??
                (success ? successMessage : fallbackMessage))
            .toString();

    dynamic data = bodyMap['data'];

    if (data is Map) {
      data = Map<String, dynamic>.from(data);
    }

    return {
      'success': success,
      'message': message,
      'data': data,
      'statusCode': statusCode,
    };
  }
}
