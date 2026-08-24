import 'api_service.dart';

class NotificacionesService {
  List<Map<String, dynamic>> _normalizarLista(dynamic respuesta) {
    dynamic datos = respuesta;

    if (respuesta is Map) {
      final statusCode = respuesta['statusCode'];
      final body = respuesta['body'];

      if (statusCode is int && (statusCode < 200 || statusCode >= 300)) {
        return [];
      }

      datos = body ?? respuesta;

      if (datos is Map) {
        datos = datos['data'];
      }
    }

    if (datos is! List) return [];

    return datos
        .where((item) => item is Map)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> obtenerNotificaciones() async {
    final respuesta = await ApiService.getAuth('/api/notificaciones');
    final statusCode = respuesta['statusCode'];
    if (statusCode == 401 || statusCode == 403) return [];
    return _normalizarLista(respuesta);
  }

  Future<void> marcarComoLeida(int notificacionId) async {
    await ApiService.putAuth('/api/notificaciones/$notificacionId/leida');
  }
}
