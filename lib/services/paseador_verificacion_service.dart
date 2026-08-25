import 'dart:io';

import '../core/errors/api_exception.dart';
import 'api_service.dart';

abstract final class PaseadorVerificacionService {
  static const String _endpoint = '/api/paseadores/verificacion';

  static Future<Map<String, dynamic>> obtenerEstado() async {
    final response = await ApiService.getAuth(_endpoint);
    return _extraerDatos(response);
  }

  static Future<String> cargarDocumento({
    required String tipo,
    required File archivo,
  }) async {
    final response = await ApiService.postMultipartAuth(
      '$_endpoint/documentos/$tipo',
      filePath: archivo.path,
      fileFieldName: 'archivo',
    );
    return _extraerMensaje(response, 'Documento guardado correctamente.');
  }

  static Future<String> solicitarRevision() async {
    final response = await ApiService.postAuth(
      '$_endpoint/solicitar',
      const {},
    );
    return _extraerMensaje(response, 'Solicitud enviada correctamente.');
  }

  static Map<String, dynamic> _extraerDatos(Map<String, dynamic> response) {
    final body = response['body'];
    final statusCode = response['statusCode'] as int?;
    if (statusCode == 200 && body is Map && body['success'] == true) {
      final data = body['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
    }

    throw _error(response, 'No se pudo consultar tu verificación.');
  }

  static String _extraerMensaje(
    Map<String, dynamic> response,
    String fallback,
  ) {
    final body = response['body'];
    final statusCode = response['statusCode'] as int?;
    if (statusCode != null &&
        statusCode >= 200 &&
        statusCode < 300 &&
        body is Map &&
        body['success'] == true) {
      final message = body['message']?.toString().trim();
      return message == null || message.isEmpty ? fallback : message;
    }

    throw _error(response, fallback);
  }

  static ApiException _error(Map<String, dynamic> response, String fallback) {
    final body = response['body'];
    final statusCode = response['statusCode'] as int?;
    final serverMessage = body is Map
        ? body['message']?.toString().trim()
        : null;
    return ApiException(
      type: statusCode != null && statusCode >= 500
          ? ApiErrorType.serverUnavailable
          : ApiErrorType.invalidResponse,
      statusCode: statusCode,
      message: serverMessage == null || serverMessage.isEmpty
          ? fallback
          : serverMessage,
    );
  }
}
