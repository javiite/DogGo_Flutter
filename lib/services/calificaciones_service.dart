import 'api_service.dart';

class CalificacionesService {
  Map<String, dynamic> _normalizarRespuesta(Map<String, dynamic> respuesta) {
    final statusCode = respuesta['statusCode'];
    final body = respuesta['body'];

    if (statusCode is int && statusCode >= 200 && statusCode < 300) {
      if (body is Map<String, dynamic>) {
        final data = body['data'] ?? body;

        if (data is Map<String, dynamic>) {
          return data;
        }

        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }

        return body;
      }

      if (body is Map) {
        return Map<String, dynamic>.from(body);
      }

      return {'success': true, 'data': body};
    }

    String mensaje = 'Error en la solicitud.';

    if (body is Map) {
      mensaje =
          body['message']?.toString() ??
          body['mensaje']?.toString() ??
          body['error']?.toString() ??
          mensaje;
    } else if (body != null) {
      mensaje = body.toString();
    }

    throw Exception(mensaje);
  }

  List<Map<String, dynamic>> _normalizarLista(Map<String, dynamic> respuesta) {
    final statusCode = respuesta['statusCode'];
    final body = respuesta['body'];

    if (statusCode is int && statusCode >= 200 && statusCode < 300) {
      dynamic datos = body;

      if (body is Map) datos = body['data'];

      if (datos is! List) return [];

      return datos
          .where((item) => item is Map)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    String mensaje = 'Error al cargar calificaciones.';

    if (body is Map) {
      mensaje =
          body['message']?.toString() ??
          body['mensaje']?.toString() ??
          body['error']?.toString() ??
          mensaje;
    }

    throw Exception(mensaje);
  }

  Future<Map<String, dynamic>> calificarPaseo({
    required int paseoId,
    required int puntaje,
    required String comentario,
  }) async {
    final body = {'puntaje': puntaje, 'comentario': comentario};

    final respuesta = await ApiService.postAuth(
      '/api/calificaciones/paseos/$paseoId',
      body,
    );
    return _normalizarRespuesta(respuesta);
  }

  Future<List<Map<String, dynamic>>> obtenerCalificacionesPaseador(
    int paseadorId,
  ) async {
    final respuesta = await ApiService.getAuth(
      '/api/calificaciones/paseadores/$paseadorId',
    );
    return _normalizarLista(respuesta);
  }

  Future<bool> paseoYaCalificado(int paseoId) async {
    final respuesta = await ApiService.getAuth(
      '/api/calificaciones/paseos/$paseoId',
    );
    final statusCode = respuesta['statusCode'];
    return statusCode is int && statusCode >= 200 && statusCode < 300;
  }
}
