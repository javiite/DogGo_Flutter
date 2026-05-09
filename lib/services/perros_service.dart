import 'api_service.dart';

class PerrosService {
  static Future<Map<String, dynamic>> obtenerMisPerros() async {
    final response = await ApiService.getAuth('/api/perros');

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
          ? body['message'] ?? 'No se pudieron obtener los perros.'
          : 'No se pudieron obtener los perros.',
      'statusCode': statusCode,
    };
  }

  static Future<Map<String, dynamic>> obtenerPerroPorId(int id) async {
    final response = await ApiService.getAuth('/api/perros/$id');

    final statusCode = response['statusCode'];
    final body = response['body'];

    if (statusCode == 200 && body is Map && body['success'] == true) {
      return {
        'success': true,
        'data': _normalizarMapa(body['data']),
      };
    }

    return {
      'success': false,
      'message': body is Map
          ? body['message'] ?? 'No se pudo obtener el perro.'
          : 'No se pudo obtener el perro.',
      'statusCode': statusCode,
    };
  }

  static Future<Map<String, dynamic>> registrarPerro({
    required String nombre,
    required String raza,
    required int edad,
    required String tamano,
    required String notas,
    String? fotoUrl,
  }) async {
    final Map<String, dynamic> data = {
      'nombre': nombre.trim(),
      'Nombre': nombre.trim(),
      'raza': raza.trim(),
      'Raza': raza.trim(),
      'edad': edad,
      'Edad': edad,
      'tamano': tamano.trim(),
      'Tamano': tamano.trim(),
      'tamanio': tamano.trim(),
      'Tamanio': tamano.trim(),
      'tamaño': tamano.trim(),
      'Tamaño': tamano.trim(),
      'notas': notas.trim(),
      'Notas': notas.trim(),
      'observaciones': notas.trim(),
      'Observaciones': notas.trim(),
    };

    final foto = fotoUrl?.trim() ?? '';

    if (foto.isNotEmpty) {
      data['fotoUrl'] = foto;
      data['FotoUrl'] = foto;
      data['imagenUrl'] = foto;
      data['ImagenUrl'] = foto;
      data['urlFoto'] = foto;
      data['UrlFoto'] = foto;
      data['fotoPerroUrl'] = foto;
      data['FotoPerroUrl'] = foto;
    }

    final response = await ApiService.postAuth(
      '/api/perros',
      data,
    );

    final statusCode = response['statusCode'];
    final body = response['body'];

    if ((statusCode == 200 || statusCode == 201) &&
        body is Map &&
        body['success'] == true) {
      return {
        'success': true,
        'message': body['message'] ?? 'Perro registrado correctamente.',
        'data': body['data'],
      };
    }

    return {
      'success': false,
      'message': body is Map
          ? body['message'] ??
              'No se pudo registrar el perro. Verifica que hayas iniciado sesión.'
          : 'No se pudo registrar el perro. Verifica que hayas iniciado sesión.',
      'statusCode': statusCode,
    };
  }

  static Future<Map<String, dynamic>> editarPerro({
    required int id,
    required String nombre,
    required String raza,
    required int edad,
    required String tamano,
    required String notas,
    String? fotoUrl,
  }) async {
    final Map<String, dynamic> data = {
      'nombre': nombre.trim(),
      'Nombre': nombre.trim(),
      'raza': raza.trim(),
      'Raza': raza.trim(),
      'edad': edad,
      'Edad': edad,
      'tamano': tamano.trim(),
      'Tamano': tamano.trim(),
      'tamanio': tamano.trim(),
      'Tamanio': tamano.trim(),
      'tamaño': tamano.trim(),
      'Tamaño': tamano.trim(),
      'notas': notas.trim(),
      'Notas': notas.trim(),
      'observaciones': notas.trim(),
      'Observaciones': notas.trim(),
    };

    final foto = fotoUrl?.trim() ?? '';

    if (foto.isNotEmpty) {
      data['fotoUrl'] = foto;
      data['FotoUrl'] = foto;
      data['imagenUrl'] = foto;
      data['ImagenUrl'] = foto;
      data['urlFoto'] = foto;
      data['UrlFoto'] = foto;
      data['fotoPerroUrl'] = foto;
      data['FotoPerroUrl'] = foto;
    }

    final response = await ApiService.putAuth(
      '/api/perros/$id',
      data,
    );

    final statusCode = response['statusCode'];
    final body = response['body'];

    if (statusCode == 200 && body is Map && body['success'] == true) {
      return {
        'success': true,
        'message': body['message'] ?? 'Perro actualizado correctamente.',
        'data': body['data'],
      };
    }

    return {
      'success': false,
      'message': body is Map
          ? body['message'] ?? 'No se pudo actualizar el perro.'
          : 'No se pudo actualizar el perro.',
      'statusCode': statusCode,
    };
  }

  static Future<Map<String, dynamic>> subirFotoPerro({
    required int id,
    required String filePath,
  }) async {
    final nombresCampo = [
      'foto',
      'archivo',
      'file',
      'imagen',
    ];

    Map<String, dynamic>? ultimaRespuesta;

    for (final nombreCampo in nombresCampo) {
      final response = await ApiService.postMultipartAuth(
        '/api/perros/$id/foto',
        filePath: filePath,
        fileFieldName: nombreCampo,
      );

      final statusCode = response['statusCode'];
      final body = response['body'];

      if ((statusCode == 200 || statusCode == 201) &&
          body is Map &&
          body['success'] == true) {
        return {
          'success': true,
          'message': body['message'] ?? 'Foto del perro actualizada.',
          'data': body['data'],
          'statusCode': statusCode,
        };
      }

      ultimaRespuesta = {
        'success': false,
        'message': body is Map
            ? body['message'] ?? 'No se pudo subir la foto del perro.'
            : 'No se pudo subir la foto del perro.',
        'statusCode': statusCode,
      };

      if (statusCode == 401 || statusCode == 403 || statusCode == 404) {
        break;
      }
    }

    return ultimaRespuesta ??
        {
          'success': false,
          'message': 'No se pudo subir la foto del perro.',
        };
  }

  static Future<Map<String, dynamic>> eliminarPerro(int id) async {
    final response = await ApiService.deleteAuth('/api/perros/$id');

    final statusCode = response['statusCode'];
    final body = response['body'];

    if (statusCode == 200 && body is Map && body['success'] == true) {
      return {
        'success': true,
        'message': body['message'] ?? 'Perro eliminado correctamente.',
      };
    }

    return {
      'success': false,
      'message': body is Map
          ? body['message'] ?? 'No se pudo eliminar el perro.'
          : 'No se pudo eliminar el perro.',
      'statusCode': statusCode,
    };
  }

  static List<dynamic> _normalizarLista(dynamic data) {
    if (data is List) return data;

    if (data is Map) {
      final posibleLista = data['items'] ??
          data['perros'] ??
          data['data'] ??
          data['result'] ??
          data['resultado'];

      if (posibleLista is List) return posibleLista;
    }

    return [];
  }

  static Map<String, dynamic> _normalizarMapa(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}