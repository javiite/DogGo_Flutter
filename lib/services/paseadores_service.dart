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
}
