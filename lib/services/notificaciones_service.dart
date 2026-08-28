import 'api_service.dart';

class NotificacionesService {
  void _asegurarExito(
    Map<String, dynamic> respuesta, {
    required String mensajeDefault,
  }) {
    final statusCode = respuesta['statusCode'];
    final body = respuesta['body'];
    final statusOk = statusCode is int && statusCode >= 200 && statusCode < 300;

    if (statusOk && (body is! Map || body['success'] != false)) {
      return;
    }

    final message = body is Map ? body['message']?.toString().trim() : null;

    throw Exception(
      message == null || message.isEmpty ? mensajeDefault : message,
    );
  }

  List<Map<String, dynamic>> _normalizarLista(dynamic respuesta) {
    dynamic datos = respuesta;

    if (respuesta is Map) {
      final statusCode = respuesta['statusCode'];
      final body = respuesta['body'];

      if (statusCode is int && (statusCode < 200 || statusCode >= 300)) {
        final message = body is Map ? body['message']?.toString().trim() : null;
        throw Exception(
          message == null || message.isEmpty
              ? 'No se pudieron cargar las notificaciones.'
              : message,
        );
      }

      datos = body ?? respuesta;

      if (datos is Map) {
        datos = datos['data'];
      }
    }

    if (datos is! List) return [];

    return datos
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> obtenerNotificaciones() async {
    final respuesta = await ApiService.getAuth('/api/notificaciones');
    return _normalizarLista(respuesta);
  }

  Future<void> marcarComoLeida(int notificacionId) async {
    final respuesta = await ApiService.putAuth(
      '/api/notificaciones/$notificacionId/leida',
    );
    _asegurarExito(
      respuesta,
      mensajeDefault: 'No se pudo marcar la notificación como leída.',
    );
  }

  Future<void> marcarTodasComoLeidas() async {
    final respuesta = await ApiService.putAuth('/api/notificaciones/leidas');
    _asegurarExito(
      respuesta,
      mensajeDefault: 'No se pudieron marcar las notificaciones como leídas.',
    );
  }
}
