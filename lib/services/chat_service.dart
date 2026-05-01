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
            datos['mensajes'] ??
            datos['messages'] ??
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

  Map<String, dynamic> _normalizarRespuesta(dynamic respuesta) {
    dynamic datos = respuesta;

    if (respuesta is Map) {
      final statusCode = respuesta['statusCode'];
      final body = respuesta['body'];

      if (statusCode is int && (statusCode < 200 || statusCode >= 300)) {
        String mensaje = 'Error en la solicitud.';

        if (body is Map) {
          mensaje = body['message']?.toString() ??
              body['mensaje']?.toString() ??
              body['error']?.toString() ??
              mensaje;
        } else if (body != null) {
          mensaje = body.toString();
        }

        throw Exception(mensaje);
      }

      datos = body ?? respuesta;

      if (datos is Map) {
        datos = datos['data'] ??
            datos['mensaje'] ??
            datos['message'] ??
            datos['resultado'] ??
            datos['result'] ??
            datos['value'] ??
            datos;
      }
    }

    if (datos is Map<String, dynamic>) return datos;
    if (datos is Map) return Map<String, dynamic>.from(datos);

    return {
      'success': true,
      'data': datos,
    };
  }

  Future<List<Map<String, dynamic>>> obtenerMensajesPaseo(int paseoId) async {
    final endpoints = [
      '/api/chat/paseo/$paseoId',
      '/api/Chat/paseo/$paseoId',
      '/api/chat/$paseoId',
      '/api/Chat/$paseoId',
      '/api/mensajes/paseo/$paseoId',
      '/api/Mensajes/paseo/$paseoId',
      '/api/paseos/$paseoId/chat',
      '/api/Paseos/$paseoId/chat',
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

    throw ultimoError ?? Exception('No se pudieron cargar los mensajes.');
  }

  Future<Map<String, dynamic>> enviarMensaje({
    required int paseoId,
    required String contenido,
  }) async {
    final body = {
      'paseoId': paseoId,
      'PaseoId': paseoId,
      'contenido': contenido,
      'Contenido': contenido,
      'mensaje': contenido,
      'Mensaje': contenido,
      'texto': contenido,
      'Texto': contenido,
    };

    final endpoints = [
      '/api/chat/enviar',
      '/api/Chat/enviar',
      '/api/chat',
      '/api/Chat',
      '/api/mensajes',
      '/api/Mensajes',
      '/api/paseos/$paseoId/chat',
      '/api/Paseos/$paseoId/chat',
    ];

    Exception? ultimoError;

    for (final endpoint in endpoints) {
      try {
        final respuesta = await ApiService.postAuth(endpoint, body);
        return _normalizarRespuesta(respuesta);
      } catch (e) {
        ultimoError = Exception(e.toString());
      }
    }

    throw ultimoError ?? Exception('No se pudo enviar el mensaje.');
  }
}