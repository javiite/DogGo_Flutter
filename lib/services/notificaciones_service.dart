import 'api_service.dart';

class NotificacionesService {
  List<Map<String, dynamic>> _normalizarLista(dynamic respuesta) {
    dynamic datos = respuesta;

    if (respuesta is Map) {
      final statusCode = respuesta['statusCode'];
      final body = respuesta['body'];

      if (statusCode is int && (statusCode < 200 || statusCode >= 300)) {
        String mensaje = 'Error al cargar notificaciones.';

        if (body is Map) {
          mensaje = body['message']?.toString() ??
              body['mensaje']?.toString() ??
              body['error']?.toString() ??
              mensaje;
        }

        throw Exception(mensaje);
      }

      datos = body ?? respuesta;

      if (datos is Map) {
        datos = datos['data'] ??
            datos['notificaciones'] ??
            datos['notifications'] ??
            datos['items'] ??
            datos['resultado'] ??
            datos['result'] ??
            datos['value'];
      }
    }

    if (datos is! List) return [];

    return datos
        .where((item) => item is Map)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> obtenerNotificaciones() async {
    final endpoints = [
      '/api/notificaciones',
      '/api/Notificaciones',
      '/api/notificaciones/mis-notificaciones',
      '/api/Notificaciones/mis-notificaciones',
      '/api/usuarios/notificaciones',
      '/api/Usuarios/notificaciones',
    ];

    Exception? ultimoError;

    for (final endpoint in endpoints) {
      try {
        final respuesta = await ApiService.getAuth(endpoint);
        return _normalizarLista(respuesta);
      } catch (e) {
        ultimoError = Exception(e.toString());
      }
    }

    throw ultimoError ?? Exception('No se pudieron cargar las notificaciones.');
  }

  Future<void> marcarComoLeida(int notificacionId) async {
    final endpoints = [
      '/api/notificaciones/$notificacionId/leida',
      '/api/Notificaciones/$notificacionId/leida',
      '/api/notificaciones/marcar-leida/$notificacionId',
      '/api/Notificaciones/marcar-leida/$notificacionId',
    ];

    Exception? ultimoError;

    for (final endpoint in endpoints) {
      try {
        final respuesta = await ApiService.putAuth(endpoint);
        final statusCode = respuesta['statusCode'];

        if (statusCode is int && statusCode >= 200 && statusCode < 300) {
          return;
        }
      } catch (e) {
        ultimoError = Exception(e.toString());
      }
    }

    throw ultimoError ?? Exception('No se pudo marcar como leída.');
  }
}