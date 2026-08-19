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

    final data =
        body['data'] ??
        body['usuario'] ??
        body['perfil'] ??
        body['resultado'] ??
        body['result'] ??
        body['value'];

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return body;
  }

  Future<Map<String, dynamic>> obtenerPerfil() async {
    final endpoints = [
      '/api/auth/perfil',
      '/api/Auth/perfil',
      '/api/auth/me',
      '/api/Auth/me',
      '/api/usuarios/perfil',
      '/api/Usuarios/perfil',
      '/api/usuario/perfil',
      '/api/Usuario/perfil',
    ];

    Exception? ultimoError;

    for (final endpoint in endpoints) {
      try {
        final respuesta = await ApiService.getAuth(endpoint);

        return _normalizarRespuesta(
          respuesta,
          errorDefault: 'No se pudo obtener el perfil.',
        );
      } catch (e) {
        ultimoError = Exception(e.toString());
      }
    }

    throw ultimoError ?? Exception('No se pudo obtener el perfil.');
  }

  Future<Map<String, dynamic>> actualizarPerfil({
    required String nombre,
    required String apellido,
    required String telefono,
  }) async {
    final body = {
      'nombre': nombre.trim(),
      'Nombre': nombre.trim(),
      'apellido': apellido.trim(),
      'Apellido': apellido.trim(),
      'telefono': telefono.trim(),
      'Telefono': telefono.trim(),
    };

    final endpoints = [
      '/api/auth/perfil',
      '/api/Auth/perfil',
      '/api/auth/actualizar-perfil',
      '/api/Auth/actualizar-perfil',
      '/api/usuarios/perfil',
      '/api/Usuarios/perfil',
      '/api/usuario/perfil',
      '/api/Usuario/perfil',
    ];

    Exception? ultimoError;

    for (final endpoint in endpoints) {
      try {
        final respuesta = await ApiService.putAuth(endpoint, body);

        return _normalizarRespuesta(
          respuesta,
          errorDefault: 'No se pudo actualizar el perfil.',
        );
      } catch (e) {
        ultimoError = Exception(e.toString());
      }
    }

    throw ultimoError ?? Exception('No se pudo actualizar el perfil.');
  }

  Future<Map<String, dynamic>> cambiarPassword({
    required String passwordActual,
    required String passwordNueva,
  }) async {
    final body = {
      'passwordActual': passwordActual,
      'PasswordActual': passwordActual,
      'contrasenaActual': passwordActual,
      'contraseñaActual': passwordActual,
      'currentPassword': passwordActual,
      'oldPassword': passwordActual,
      'passwordNueva': passwordNueva,
      'PasswordNueva': passwordNueva,
      'nuevaPassword': passwordNueva,
      'NuevaPassword': passwordNueva,
      'newPassword': passwordNueva,
      'password': passwordNueva,
    };

    final endpoints = [
      '/api/auth/cambiar-password',
      '/api/Auth/cambiar-password',
      '/api/auth/change-password',
      '/api/Auth/change-password',
      '/api/usuarios/cambiar-password',
      '/api/Usuarios/cambiar-password',
      '/api/usuario/cambiar-password',
      '/api/Usuario/cambiar-password',
    ];

    Exception? ultimoError;

    for (final endpoint in endpoints) {
      try {
        final respuesta = await ApiService.putAuth(endpoint, body);

        return _normalizarRespuesta(
          respuesta,
          errorDefault: 'No se pudo cambiar la contraseña.',
        );
      } catch (e) {
        ultimoError = Exception(e.toString());
      }
    }

    throw ultimoError ?? Exception('No se pudo cambiar la contraseña.');
  }

  Future<Map<String, dynamic>> obtenerPerfilDuenio() async {
    final endpoints = [
      '/api/duenio-perfil/mi-perfil',
      '/api/dueño-perfil/mi-perfil',
      '/api/duenioPerfil/mi-perfil',
      '/api/DuenioPerfil/mi-perfil',
    ];

    Exception? ultimoError;

    for (final endpoint in endpoints) {
      try {
        final respuesta = await ApiService.getAuth(endpoint);

        return _normalizarRespuesta(
          respuesta,
          errorDefault: 'No se pudo obtener el perfil de dueño.',
        );
      } catch (e) {
        ultimoError = Exception(e.toString());
      }
    }

    throw ultimoError ?? Exception('No se pudo obtener el perfil de dueño.');
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
      'Direccion': direccion?.trim(),
      'referenciasDireccion': referenciasDireccion?.trim(),
      'ReferenciasDireccion': referenciasDireccion?.trim(),
      'zona': zona?.trim(),
      'Zona': zona?.trim(),
      'latitud': latitud,
      'Latitud': latitud,
      'longitud': longitud,
      'Longitud': longitud,
      'descripcion': descripcion?.trim(),
      'Descripcion': descripcion?.trim(),
      'preferenciasPaseo': preferenciasPaseo?.trim(),
      'PreferenciasPaseo': preferenciasPaseo?.trim(),
      'estadoClave': estadoClave,
      'municipioClave': municipioClave,
    };

    final endpoints = [
      '/api/duenio-perfil/mi-perfil',
      '/api/dueño-perfil/mi-perfil',
      '/api/duenioPerfil/mi-perfil',
      '/api/DuenioPerfil/mi-perfil',
    ];

    Exception? ultimoError;

    for (final endpoint in endpoints) {
      try {
        final respuesta = await ApiService.putAuth(endpoint, body);

        return _normalizarRespuesta(
          respuesta,
          errorDefault: 'No se pudo actualizar el perfil de dueño.',
        );
      } catch (e) {
        ultimoError = Exception(e.toString());
      }
    }

    throw ultimoError ?? Exception('No se pudo actualizar el perfil de dueño.');
  }

  Future<Map<String, dynamic>> subirFotoPerfilDuenio(File foto) async {
    final endpoints = [
      '/api/duenio-perfil/foto',
      '/api/dueño-perfil/foto',
      '/api/duenioPerfil/foto',
      '/api/DuenioPerfil/foto',
    ];

    final nombresCampo = ['foto', 'fotoArchivo', 'archivo', 'file', 'imagen'];

    Exception? ultimoError;

    for (final endpoint in endpoints) {
      for (final campo in nombresCampo) {
        try {
          final respuesta = await ApiService.postMultipartAuth(
            endpoint,
            filePath: foto.path,
            fileFieldName: campo,
          );

          return _normalizarRespuesta(
            respuesta,
            errorDefault: 'No se pudo subir la foto de perfil.',
          );
        } catch (e) {
          ultimoError = Exception(e.toString());
        }
      }
    }

    throw ultimoError ?? Exception('No se pudo subir la foto de perfil.');
  }
}
