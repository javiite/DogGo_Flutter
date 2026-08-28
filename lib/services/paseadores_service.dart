import 'dart:io';

import 'api_service.dart';
import 'storage_service.dart';

class PaseadoresService {
  static Future<Map<String, dynamic>> obtenerPaseador(int paseadorId) async {
    final response = await ApiService.getAuth('/api/paseadores/$paseadorId');
    return _normalizarRespuesta(
      response,
      errorDefault: 'No se pudo obtener el perfil del paseador.',
    );
  }

  static Future<Map<String, dynamic>> obtenerPaseadores() async {
    final response = await ApiService.getAuth(
      '/api/paseadores/buscar?pagina=1&tamanioPagina=50',
    );

    final statusCode = response['statusCode'];
    final body = response['body'];

    if (statusCode == 200 && body is Map && body['success'] == true) {
      final currentUserId = await StorageService.obtenerUsuarioId();
      final data = _bodySeguro(body['data']);
      final walkers = _normalizarLista(data['elementos'])
          .where((item) {
            if (currentUserId == null || item is! Map) return true;
            final value = item['usuarioId'];
            return int.tryParse('$value') != currentUserId;
          })
          .toList(growable: false);
      return {'success': true, 'data': walkers};
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
    final response = await ApiService.getAuth('/api/paseadores/mi-perfil');
    return _normalizarRespuesta(
      response,
      errorDefault: 'No se pudo obtener el perfil de paseador.',
    );
  }

  static Future<Map<String, dynamic>> obtenerResenasMiPerfilPaseador() async {
    final response = await ApiService.getAuth(
      '/api/paseadores/mi-perfil/resenas',
    );
    return _normalizarRespuesta(
      response,
      errorDefault: 'No se pudieron obtener las reseñas del paseador.',
    );
  }

  static Future<Map<String, dynamic>> obtenerResenasPaseador(
    int paseadorId,
  ) async {
    final response = await ApiService.getAuth(
      '/api/paseadores/$paseadorId/resenas',
    );
    return _normalizarRespuesta(
      response,
      errorDefault: 'No se pudieron obtener las reseñas del paseador.',
    );
  }

  static Future<Map<String, dynamic>> guardarMiPerfilPaseador({
    required String descripcion,
    required String zonaServicio,
    required double tarifaPorHora,
    required int experienciaAnios,
    required bool disponible,
    String? estadoClave,
    String? municipioClave,
    int? radioServicioKm,
    double? latitud,
    double? longitud,
  }) async {
    final body = {
      'descripcion': descripcion.trim(),
      'zonaServicio': zonaServicio.trim(),
      'tarifaPorHora': tarifaPorHora,
      'experienciaAnios': experienciaAnios,
      'disponible': disponible,
      ...?estadoClave == null ? null : {'estadoClave': estadoClave},
      ...?municipioClave == null ? null : {'municipioClave': municipioClave},
      ...?radioServicioKm == null ? null : {'radioServicioKm': radioServicioKm},
      ...?latitud == null ? null : {'latitud': latitud},
      ...?longitud == null ? null : {'longitud': longitud},
    };

    final response = await ApiService.putAuth(
      '/api/paseadores/mi-perfil',
      body,
    );
    return _normalizarRespuesta(
      response,
      errorDefault: 'No se pudo guardar el perfil de paseador.',
    );
  }

  static Future<Map<String, dynamic>> subirFotoMiPerfilPaseador(
    File archivo,
  ) async {
    final response = await _postMultipartAuth(
      endpoint: '/api/paseadores/mi-perfil/foto',
      archivo: archivo,
      fieldName: 'foto',
    );
    return _normalizarRespuesta(
      response,
      errorDefault: 'No se pudo subir la foto de paseador.',
    );
  }

  static Future<Map<String, dynamic>> _postMultipartAuth({
    required String endpoint,
    required File archivo,
    required String fieldName,
  }) async {
    return ApiService.postMultipartAuth(
      endpoint,
      filePath: archivo.path,
      fileFieldName: fieldName,
    );
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

    final data = body['data'];

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {'data': data};
  }

  static List<dynamic> _normalizarLista(dynamic data) {
    if (data is List) {
      return data;
    }

    return [];
  }

  static Map<String, dynamic> _bodySeguro(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);

    return {'data': body};
  }

  static String _mensajeError(
    dynamic body, [
    String fallback = 'Error en la solicitud.',
  ]) {
    if (body is Map) {
      return body['message']?.toString() ?? fallback;
    }

    if (body != null) {
      final texto = body.toString().trim();
      if (texto.isNotEmpty) return texto;
    }

    return fallback;
  }
}
