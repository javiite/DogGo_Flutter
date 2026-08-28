import 'dart:io';

import '../core/errors/api_exception.dart';
import 'api_service.dart';

class EvidenciaService {
  Future<Map<String, dynamic>> subirFotoInicio({
    required int paseoId,
    required File archivo,
  }) async {
    return _subirFoto(paseoId: paseoId, archivo: archivo, tipo: 'inicio');
  }

  Future<Map<String, dynamic>> subirFotoFin({
    required int paseoId,
    required File archivo,
  }) async {
    return _subirFoto(paseoId: paseoId, archivo: archivo, tipo: 'fin');
  }

  Future<Map<String, dynamic>> _subirFoto({
    required int paseoId,
    required File archivo,
    required String tipo,
  }) async {
    if (!await archivo.exists()) {
      throw const ApiException(
        type: ApiErrorType.invalidResponse,
        message: 'El archivo seleccionado ya no existe.',
      );
    }

    final endpoint = tipo == 'inicio'
        ? '/api/paseos/$paseoId/foto-inicio'
        : '/api/paseos/$paseoId/foto-fin';
    final response = await ApiService.postMultipartAuth(
      endpoint,
      filePath: archivo.path,
      fileFieldName: 'archivo',
    );

    final statusCode = response['statusCode'] as int?;
    final rawBody = response['body'];
    final body = rawBody is Map
        ? Map<String, dynamic>.from(rawBody)
        : <String, dynamic>{};

    if (statusCode != null && statusCode >= 200 && statusCode < 300) {
      return body;
    }

    final serverMessage = body['message']?.toString().trim();
    throw ApiException(
      type: statusCode == 401 || statusCode == 403
          ? ApiErrorType.noSession
          : statusCode != null && statusCode >= 500
          ? ApiErrorType.serverUnavailable
          : ApiErrorType.invalidResponse,
      statusCode: statusCode,
      message: serverMessage == null || serverMessage.isEmpty
          ? 'No se pudo subir la evidencia.'
          : serverMessage,
    );
  }
}
