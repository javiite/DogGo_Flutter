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
}