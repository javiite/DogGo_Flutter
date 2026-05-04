import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'storage_service.dart';

class EvidenciaService {
  Future<String> _baseUrl() async {
    final baseUrl = await StorageService.obtenerBaseUrl();

    if (baseUrl == null || baseUrl.trim().isEmpty) {
      throw Exception('No hay URL del servidor configurada.');
    }

    final limpia = baseUrl.trim();

    if (limpia.endsWith('/')) {
      return limpia.substring(0, limpia.length - 1);
    }

    return limpia;
  }

  Future<String> _token() async {
    final token = await StorageService.obtenerToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('No hay token guardado. Inicia sesión otra vez.');
    }

    return token.trim();
  }

  Map<String, dynamic> _normalizarRespuesta(http.Response response) {
    dynamic body;

    try {
      body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    } catch (_) {
      body = {
        'message': response.body,
      };
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map<String, dynamic>) {
        return body;
      }

      if (body is Map) {
        return Map<String, dynamic>.from(body);
      }

      return {
        'success': true,
        'data': body,
      };
    }

    String mensaje = 'Error al subir evidencia.';

    if (body is Map) {
      mensaje = body['message']?.toString() ??
          body['mensaje']?.toString() ??
          body['error']?.toString() ??
          mensaje;
    } else if (body != null) {
      mensaje = body.toString();
    }

    throw Exception('$mensaje Código: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> subirFotoInicio({
    required int paseoId,
    required File archivo,
  }) async {
    return _subirFoto(
      paseoId: paseoId,
      archivo: archivo,
      tipo: 'inicio',
    );
  }

  Future<Map<String, dynamic>> subirFotoFin({
    required int paseoId,
    required File archivo,
  }) async {
    return _subirFoto(
      paseoId: paseoId,
      archivo: archivo,
      tipo: 'fin',
    );
  }

  Future<Map<String, dynamic>> _subirFoto({
    required int paseoId,
    required File archivo,
    required String tipo,
  }) async {
    if (!await archivo.exists()) {
      throw Exception('El archivo seleccionado ya no existe.');
    }

    final baseUrl = await _baseUrl();
    final token = await _token();

    final endpoints = tipo == 'inicio'
        ? [
            '/api/paseos/$paseoId/foto-inicio',
            '/api/Paseos/$paseoId/foto-inicio',
            '/api/paseos/foto-inicio/$paseoId',
            '/api/Paseos/foto-inicio/$paseoId',
            '/api/evidencias/paseo/$paseoId/inicio',
            '/api/Evidencias/paseo/$paseoId/inicio',
          ]
        : [
            '/api/paseos/$paseoId/foto-fin',
            '/api/Paseos/$paseoId/foto-fin',
            '/api/paseos/foto-fin/$paseoId',
            '/api/Paseos/foto-fin/$paseoId',
            '/api/evidencias/paseo/$paseoId/fin',
            '/api/Evidencias/paseo/$paseoId/fin',
          ];

    final fileFields = [
      'archivo',
      'Archivo',
      'foto',
      'Foto',
      'imagen',
      'Imagen',
      'file',
      'File',
    ];

    Exception? ultimoError;

    for (final endpoint in endpoints) {
      for (final fileField in fileFields) {
        try {
          final uri = Uri.parse('$baseUrl$endpoint');

          final request = http.MultipartRequest('POST', uri);

          request.headers['Authorization'] = 'Bearer $token';
          request.headers['Accept'] = 'application/json';

          request.fields['paseoId'] = paseoId.toString();
          request.fields['PaseoId'] = paseoId.toString();
          request.fields['tipo'] = tipo;
          request.fields['Tipo'] = tipo;

          request.files.add(
            await http.MultipartFile.fromPath(
              fileField,
              archivo.path,
            ),
          );

          final response = await _enviarMultipart(request);

          return _normalizarRespuesta(response);
        } catch (e) {
          ultimoError = Exception(e.toString());
        }
      }
    }

    throw ultimoError ?? Exception('No se pudo subir la evidencia.');
  }

  Future<http.Response> _enviarMultipart(http.MultipartRequest request) async {
    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }
}
