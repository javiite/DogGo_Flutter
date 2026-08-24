import 'api_service.dart';

class ChatService {
  List<Map<String, dynamic>> _normalizarLista(dynamic respuesta) {
    dynamic datos = respuesta;

    if (respuesta is Map) {
      final statusCode = respuesta['statusCode'];
      final body = respuesta['body'];

      if (statusCode is int && (statusCode < 200 || statusCode >= 300)) {
        String mensaje = 'Error al cargar mensajes.';

        if (body is Map) {
          mensaje = body['message']?.toString() ?? mensaje;
        } else if (body != null) {
          mensaje = body.toString();
        }

        throw Exception(mensaje);
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

  Map<String, dynamic> _normalizarRespuesta(dynamic respuesta) {
    dynamic datos = respuesta;

    if (respuesta is Map) {
      final statusCode = respuesta['statusCode'];
      final body = respuesta['body'];

      if (statusCode is int && (statusCode < 200 || statusCode >= 300)) {
        String mensaje = 'Error en la solicitud.';

        if (body is Map) {
          mensaje = body['message']?.toString() ?? mensaje;
        } else if (body != null) {
          mensaje = body.toString();
        }

        throw Exception(mensaje);
      }

      datos = body ?? respuesta;

      if (datos is Map) {
        final interno = datos['data'];

        if (interno is Map) {
          datos = interno;
        }
      }
    }

    if (datos is Map<String, dynamic>) return datos;
    if (datos is Map) return Map<String, dynamic>.from(datos);

    return {'success': true, 'data': datos};
  }

  Future<List<Map<String, dynamic>>> obtenerMensajesPaseo(int paseoId) async {
    final respuesta = await ApiService.getAuth(
      '/api/chat/paseos/$paseoId/mensajes',
    );
    return _normalizarLista(respuesta);
  }

  Future<Map<String, dynamic>> enviarMensaje({
    required int paseoId,
    required String contenido,
  }) async {
    final texto = contenido.trim();

    if (texto.isEmpty) {
      throw Exception('Escribe un mensaje antes de enviarlo.');
    }

    final respuesta = await ApiService.postAuth(
      '/api/chat/paseos/$paseoId/mensajes',
      {'contenido': texto},
    );
    return _normalizarRespuesta(respuesta);
  }

  Future<void> marcarComoLeidos(int paseoId) async {
    final respuesta = await ApiService.putAuth(
      '/api/chat/paseos/$paseoId/leidos',
    );
    _normalizarRespuesta(respuesta);
  }
}
