import 'api_service.dart';

class UsuarioService {
  Map<String, dynamic> _normalizarRespuesta(Map<String, dynamic> respuesta) {
    final statusCode = respuesta['statusCode'];
    final body = respuesta['body'];

    if (statusCode is int && statusCode >= 200 && statusCode < 300) {
      if (body is Map<String, dynamic>) {
        final data = body['data'] ??
            body['usuario'] ??
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

    String mensaje = 'Error en la solicitud.';

    if (body is Map) {
      mensaje = body['message']?.toString() ??
          body['mensaje']?.toString() ??
          body['error']?.toString() ??
          mensaje;
    } else if (body != null) {
      mensaje = body.toString();
    }

    throw Exception(mensaje);
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
        return _normalizarRespuesta(respuesta);
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
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
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
        return _normalizarRespuesta(respuesta);
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
      'passwordNueva': passwordNueva,
      'nuevaPassword': passwordNueva,
      'newPassword': passwordNueva,
      'currentPassword': passwordActual,
    };

    final endpoints = [
      '/api/auth/cambiar-password',
      '/api/Auth/cambiar-password',
      '/api/auth/change-password',
      '/api/Auth/change-password',
      '/api/usuarios/cambiar-password',
      '/api/Usuarios/cambiar-password',
    ];

    Exception? ultimoError;

    for (final endpoint in endpoints) {
      try {
        final respuesta = await ApiService.putAuth(endpoint, body);
        return _normalizarRespuesta(respuesta);
      } catch (e) {
        ultimoError = Exception(e.toString());
      }
    }

    throw ultimoError ?? Exception('No se pudo cambiar la contraseña.');
  }
}