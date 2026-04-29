import 'api_service.dart';

class PaseadoresService {
  static Future<Map<String, dynamic>> obtenerPaseadores() async {
    final response = await ApiService.getAuth('/api/paseadores');

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
      'message': body['message'] ?? 'No se pudieron obtener los paseadores.',
    };
  }
}