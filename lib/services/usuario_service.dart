import 'dart:io';

import 'api_service.dart';

class UsuarioService {
  Map<String, dynamic> _bodySeguro(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);

    return {'data': body};
  }

  String _mensajeError(
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

  Map<String, dynamic> _normalizarRespuesta(
    Map<String, dynamic> respuesta, {
    String errorDefault = 'Error en la solicitud.',
  }) {
    final statusCode = respuesta['statusCode'];
    final bodyRaw = respuesta['body'];
    final body = _bodySeguro(bodyRaw);

    final statusOk = statusCode is int && statusCode >= 200 && statusCode < 300;

    if (!statusOk) {
      throw Exception(_mensajeError(bodyRaw, errorDefault));
    }

    if (body.containsKey('success') && body['success'] == false) {
      throw Exception(_mensajeError(body, errorDefault));
    }

    final data = body['data'];

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return body;
  }

  Future<Map<String, dynamic>> obtenerPerfil() async {
    final respuesta = await ApiService.getAuth('/api/auth/perfil');
    return _normalizarRespuesta(
      respuesta,
      errorDefault: 'No se pudo obtener el perfil.',
    );
  }

  Future<Map<String, dynamic>> actualizarPerfil({
    required String nombre,
    required String apellido,
    required String telefono,
  }) async {
    final body = {
      'nombre': nombre.trim(),
      'apellido': apellido.trim(),
      'telefono': telefono.trim(),
    };
    final respuesta = await ApiService.putAuth('/api/auth/perfil', body);
    return _normalizarRespuesta(
      respuesta,
      errorDefault: 'No se pudo actualizar el perfil.',
    );
  }

  Future<Map<String, dynamic>> cambiarPassword({
    required String passwordActual,
    required String passwordNueva,
  }) async {
    final body = {
      'currentPassword': passwordActual,
      'newPassword': passwordNueva,
    };
    final respuesta = await ApiService.putAuth(
      '/api/auth/cambiar-password',
      body,
    );
    return _normalizarRespuesta(
      respuesta,
      errorDefault: 'No se pudo cambiar la contraseña.',
    );
  }

  Future<Map<String, dynamic>> obtenerPerfilDuenio() async {
    final respuesta = await ApiService.getAuth('/api/duenio-perfil/mi-perfil');
    return _normalizarRespuesta(
      respuesta,
      errorDefault: 'No se pudo obtener el perfil de dueño.',
    );
  }

  Future<Map<String, dynamic>> actualizarPerfilDuenio({
    String? direccion,
    String? referenciasDireccion,
    String? zona,
    double? latitud,
    double? longitud,
    String? descripcion,
    String? preferenciasPaseo,
    String? estadoClave,
    String? municipioClave,
  }) async {
    final body = {
      'direccion': direccion?.trim(),
      'referenciasDireccion': referenciasDireccion?.trim(),
      'zona': zona?.trim(),
      'latitud': latitud,
      'longitud': longitud,
      'descripcion': descripcion?.trim(),
      'preferenciasPaseo': preferenciasPaseo?.trim(),
      'estadoClave': estadoClave,
      'municipioClave': municipioClave,
    };
    final respuesta = await ApiService.putAuth(
      '/api/duenio-perfil/mi-perfil',
      body,
    );
    return _normalizarRespuesta(
      respuesta,
      errorDefault: 'No se pudo actualizar el perfil de dueño.',
    );
  }

  Future<Map<String, dynamic>> subirFotoPerfilDuenio(File foto) async {
    final respuesta = await ApiService.postMultipartAuth(
      '/api/duenio-perfil/foto',
      filePath: foto.path,
      fileFieldName: 'foto',
    );
    return _normalizarRespuesta(
      respuesta,
      errorDefault: 'No se pudo subir la foto de perfil.',
    );
  }
}
