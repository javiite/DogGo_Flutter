import 'api_service.dart';

class UsuarioService {
  static Future<Map<String, dynamic>> obtenerPerfil() async {
    final response = await ApiService.getAuth('/api/auth/perfil');

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
      'message': body['message'] ?? 'No se pudo obtener el perfil.',
    };
  }

  static Future<Map<String, dynamic>> actualizarPerfil({
    required String nombre,
    required String apellido,
    required String telefono,
  }) async {
    final response = await ApiService.putAuth(
      '/api/auth/perfil',
      {
        'nombre': nombre,
        'apellido': apellido,
        'telefono': telefono,
      },
    );

    final statusCode = response['statusCode'];
    final body = response['body'];

    if ((statusCode == 200 || statusCode == 204) &&
        (body is Map ? (body['success'] ?? true) : true)) {
      return {
        'success': true,
        'message': body is Map
            ? (body['message'] ?? 'Perfil actualizado correctamente.')
            : 'Perfil actualizado correctamente.',
      };
    }

    return {
      'success': false,
      'message': body['message'] ?? 'No se pudo actualizar el perfil.',
    };
  }
}