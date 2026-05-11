import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class PaseadoresService {
  static Future<Map<String, dynamic>> obtenerPaseadores() async {
    final response = await ApiService.getAuth('/api/paseadores');

    final statusCode = response['statusCode'];
    final body = response['body'];

    if (statusCode == 200 && body is Map && body['success'] == true) {
      return {
        'success': true,
        'data': _normalizarLista(body['data']),
      };
    }

    return {
      'success': false,
      'message': body is Map
          ? body['message'] ?? 'No se pudieron obtener los paseadores.'
          : 'No se pudieron obtener los paseadores.',
      'statusCode': statusCode,
    };
  }

  static Future<Map<String, dynamic>> obtenerMiPerfilPaseador() async {
    final endpoints = [
      '/api/paseadores/mi-perfil',
      '/api/paseadores/perfil',
      '/api/Paseadores/mi-perfil',
      '/api/Paseadores/perfil',
    ];

    Exception? ultimoError;

    for (final endpoint in endpoints) {
      try {
        final response = await ApiService.getAuth(endpoint);
        return _normalizarRespuesta(
          response,
          errorDefault: 'No se pudo obtener el perfil de paseador.',
        );
      } catch (e) {
        ultimoError = Exception(e.toString());
      }
    }

    throw ultimoError ?? Exception('No se pudo obtener el perfil de paseador.');
  }

  static Future<Map<String, dynamic>> obtenerResenasMiPerfilPaseador() async {
    final endpoints = [
      '/api/paseadores/mi-perfil/resenas',
      '/api/paseadores/mi-perfil/reseñas',
      '/api/paseadores/mi-perfil/calificaciones',
      '/api/Paseadores/mi-perfil/resenas',
      '/api/Paseadores/mi-perfil/reseñas',
      '/api/Paseadores/mi-perfil/calificaciones',
    ];

    Exception? ultimoError;

    for (final endpoint in endpoints) {
      try {
        final response = await ApiService.getAuth(endpoint);
        return _normalizarRespuesta(
          response,
          errorDefault: 'No se pudieron obtener las reseñas del paseador.',
        );
      } catch (e) {
        ultimoError = Exception(e.toString());
      }
    }

    throw ultimoError ??
        Exception('No se pudieron obtener las reseñas del paseador.');
  }

  static Future<Map<String, dynamic>> obtenerResenasPaseador(
    int paseadorId,
  ) async {
    final endpoints = [
      '/api/paseadores/$paseadorId/resenas',
      '/api/paseadores/$paseadorId/reseñas',
      '/api/paseadores/$paseadorId/calificaciones',
      '/api/Paseadores/$paseadorId/resenas',
      '/api/Paseadores/$paseadorId/reseñas',
      '/api/Paseadores/$paseadorId/calificaciones',
    ];

    Exception? ultimoError;

    for (final endpoint in endpoints) {
      try {
        final response = await ApiService.getAuth(endpoint);
        return _normalizarRespuesta(
          response,
          errorDefault: 'No se pudieron obtener las reseñas del paseador.',
        );
      } catch (e) {
        ultimoError = Exception(e.toString());
      }
    }

    throw ultimoError ??
        Exception('No se pudieron obtener las reseñas del paseador.');
  }

  static Future<Map<String, dynamic>> guardarMiPerfilPaseador({
    required String descripcion,
    required String zonaServicio,
    required double tarifaPorHora,
    required int experienciaAnios,
    required bool disponible,
  }) async {
    final body = {
      'descripcion': descripcion.trim(),
      'Descripcion': descripcion.trim(),
      'zonaServicio': zonaServicio.trim(),
      'ZonaServicio': zonaServicio.trim(),
      'zona': zonaServicio.trim(),
      'Zona': zonaServicio.trim(),
      'tarifaPorHora': tarifaPorHora,
      'TarifaPorHora': tarifaPorHora,
      'tarifa': tarifaPorHora,
      'Tarifa': tarifaPorHora,
      'experienciaAnios': experienciaAnios,
      'ExperienciaAnios': experienciaAnios,
      'experiencia': experienciaAnios,
      'Experiencia': experienciaAnios,
      'disponible': disponible,
      'Disponible': disponible,
    };

    final endpoints = [
      '/api/paseadores/mi-perfil',
      '/api/paseadores/perfil',
      '/api/Paseadores/mi-perfil',
      '/api/Paseadores/perfil',
    ];

    Exception? ultimoError;

    for (final endpoint in endpoints) {
      try {
        final response = await ApiService.putAuth(endpoint, body);
        return _normalizarRespuesta(
          response,
          errorDefault: 'No se pudo guardar el perfil de paseador.',
        );
      } catch (_) {
        try {
          final response = await ApiService.postAuth(endpoint, body);
          return _normalizarRespuesta(
            response,
            errorDefault: 'No se pudo guardar el perfil de paseador.',
          );
        } catch (ePost) {
          ultimoError = Exception(ePost.toString());
        }
      }
    }

    throw ultimoError ?? Exception('No se pudo guardar el perfil de paseador.');
  }

  static Future<Map<String, dynamic>> subirFotoMiPerfilPaseador(
    File archivo,
  ) async {
    final endpoints = [
      '/api/paseadores/mi-perfil/foto',
      '/api/paseadores/perfil/foto',
      '/api/Paseadores/mi-perfil/foto',
      '/api/Paseadores/perfil/foto',
    ];

    Exception? ultimoError;

    for (final endpoint in endpoints) {
      try {
        final response = await _postMultipartAuth(
          endpoint: endpoint,
          archivo: archivo,
          fieldName: 'foto',
        );

        return _normalizarRespuesta(
          response,
          errorDefault: 'No se pudo subir la foto de paseador.',
        );
      } catch (e) {
        ultimoError = Exception(e.toString());
      }
    }

    throw ultimoError ?? Exception('No se pudo subir la foto de paseador.');
  }

  static Future<Map<String, dynamic>> _postMultipartAuth({
    required String endpoint,
    required File archivo,
    required String fieldName,
  }) async {
    final baseUrl = await ApiService.obtenerBaseUrl();
    final token = await ApiService.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay token guardado. Inicia sesión otra vez.');
    }

    final url = Uri.parse('$baseUrl$endpoint');

    final request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.files.add(
      await http.MultipartFile.fromPath(
        fieldName,
        archivo.path,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    dynamic responseBody;

    try {
      responseBody =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};
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

  static Map<String, dynamic> _normalizarRespuesta(
    Map<String, dynamic> respuesta, {
    required String errorDefault,
  }) {
    final statusCode = respuesta['statusCode'];
    final bodyRaw = respuesta['body'];

    final statusOk = statusCode is int && statusCode >= 200 && statusCode < 300;

    if (!statusOk) {
      throw Exception(_mensajeError(bodyRaw, errorDefault));
    }

    final body = _bodySeguro(bodyRaw);

    if (body['success'] == false) {
      throw Exception(_mensajeError(body, errorDefault));
    }

    final data = body['data'] ??
        body['paseador'] ??
        body['perfil'] ??
        body['resultado'] ??
        body['result'] ??
        body['value'] ??
        body;

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {
      'data': data,
    };
  }

  static List<dynamic> _normalizarLista(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      final posibleLista = data['items'] ??
          data['paseadores'] ??
          data['data'] ??
          data['result'] ??
          data['resultado'];

      if (posibleLista is List) {
        return posibleLista;
      }
    }

    return [];
  }

  static Map<String, dynamic> _bodySeguro(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);

    return {
      'data': body,
    };
  }

  static String _mensajeError(
    dynamic body, [
    String fallback = 'Error en la solicitud.',
  ]) {
    if (body is Map) {
      return body['message']?.toString() ??
          body['mensaje']?.toString() ??
          body['error']?.toString() ??
          body['title']?.toString() ??
          fallback;
    }

    if (body != null) {
      final texto = body.toString().trim();
      if (texto.isNotEmpty) return texto;
    }

    return fallback;
  }
}