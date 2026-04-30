import 'api_service.dart';

class PerrosService {
  static Future<Map<String, dynamic>> obtenerMisPerros() async {
    final response = await ApiService.getAuth('/api/perros');

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
      'message': body['message'] ?? 'No se pudieron obtener los perros.',
    };
  }

  static Future<Map<String, dynamic>> obtenerPerroPorId(int id) async {
    final response = await ApiService.getAuth('/api/perros/$id');

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
      'message': body['message'] ?? 'No se pudo obtener el perro.',
    };
  }

  static Future<Map<String, dynamic>> registrarPerro({
    required String nombre,
    required String raza,
    required int edad,
    required String tamano,
    required String notas,
  }) async {
    final response = await ApiService.post(
      '/api/perros',
      {
        'nombre': nombre,
        'raza': raza,
        'edad': edad,
        'tamano': tamano,
        'notas': notas,
      },
    );

    final statusCode = response['statusCode'];
    final body = response['body'];

    if ((statusCode == 200 || statusCode == 201) && body['success'] == true) {
      return {
        'success': true,
        'message': body['message'] ?? 'Perro registrado correctamente.',
        'data': body['data'],
      };
    }

    return {
      'success': false,
      'message': body['message'] ?? 'No se pudo registrar el perro.',
    };
  }

  static Future<Map<String, dynamic>> editarPerro({
    required int id,
    required String nombre,
    required String raza,
    required int edad,
    required String tamano,
    required String notas,
  }) async {
    final response = await ApiService.putAuth(
      '/api/perros/$id',
      {
        'nombre': nombre,
        'raza': raza,
        'edad': edad,
        'tamano': tamano,
        'notas': notas,
      },
    );

    final statusCode = response['statusCode'];
    final body = response['body'];

    if (statusCode == 200 && body['success'] == true) {
      return {
        'success': true,
        'message': body['message'] ?? 'Perro actualizado correctamente.',
        'data': body['data'],
      };
    }

    return {
      'success': false,
      'message': body['message'] ?? 'No se pudo actualizar el perro.',
    };
  }

  static Future<Map<String, dynamic>> eliminarPerro(int id) async {
    final response = await ApiService.deleteAuth('/api/perros/$id');

    final statusCode = response['statusCode'];
    final body = response['body'];

    if (statusCode == 200 && body['success'] == true) {
      return {
        'success': true,
        'message': body['message'] ?? 'Perro eliminado correctamente.',
      };
    }

    return {
      'success': false,
      'message': body['message'] ?? 'No se pudo eliminar el perro.',
    };
  }
}