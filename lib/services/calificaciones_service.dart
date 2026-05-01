import 'api_service.dart';

class CalificacionesService {
  Map<String, dynamic> _normalizarRespuesta(Map<String, dynamic> respuesta) {
    final statusCode = respuesta['statusCode'];
    final body = respuesta['body'];

    if (statusCode is int && statusCode >= 200 && statusCode < 300) {
      if (body is Map<String, dynamic>) {
        final data = body['data'] ??
            body['calificacion'] ??
            body['resultado'] ??
            body['result'] ??
            body['value'] ??
            body;

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

      return {
        'success': true,
        'data': body,
      };
    }

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

  List<Map<String, dynamic>> _normalizarLista(Map<String, dynamic> respuesta) {
    final statusCode = respuesta['statusCode'];
    final body = respuesta['body'];

    if (statusCode is int && statusCode >= 200 && statusCode < 300) {
      dynamic datos = body;

      if (body is Map) {
        datos = body['data'] ??
            body['calificaciones'] ??
            body['reseñas'] ??
            body['resenas'] ??
            body['items'] ??
            body['resultado'] ??
            body['result'] ??
            body['value'];
      }

      if (datos is! List) return [];

      return datos
          .where((item) => item is Map)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    String mensaje = 'Error al cargar calificaciones.';

    if (body is Map) {
      mensaje = body['message']?.toString() ??
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
    final body = {
      'paseoId': paseoId,
      'PaseoId': paseoId,
      'puntaje': puntaje,
      'Puntaje': puntaje,
      'comentario': comentario,
      'Comentario': comentario,
    };

    final endpoints = [
      '/api/calificaciones',
      '/api/Calificaciones',
      '/api/calificaciones/calificar',
      '/api/Calificaciones/calificar',
      '/api/paseos/$paseoId/calificar',
      '/api/Paseos/$paseoId/calificar',
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

    throw ultimoError ?? Exception('No se pudo enviar la calificación.');
  }

  Future<List<Map<String, dynamic>>> obtenerCalificacionesPaseador(
    int paseadorId,
  ) async {
    final endpoints = [
      '/api/calificaciones/paseador/$paseadorId',
      '/api/Calificaciones/paseador/$paseadorId',
      '/api/paseadores/$paseadorId/calificaciones',
      '/api/Paseadores/$paseadorId/calificaciones',
      '/api/paseadores/$paseadorId/resenas',
      '/api/Paseadores/$paseadorId/resenas',
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

    throw ultimoError ?? Exception('No se pudieron cargar las calificaciones.');
  }

  Future<bool> paseoYaCalificado(int paseoId) async {
    final endpoints = [
      '/api/calificaciones/paseo/$paseoId/existe',
      '/api/Calificaciones/paseo/$paseoId/existe',
      '/api/paseos/$paseoId/calificacion',
      '/api/Paseos/$paseoId/calificacion',
    ];

    for (final endpoint in endpoints) {
      try {
        final respuesta = await ApiService.getAuth(endpoint);
        final statusCode = respuesta['statusCode'];
        final body = respuesta['body'];

        if (statusCode is int && statusCode >= 200 && statusCode < 300) {
          if (body is bool) return body;

          if (body is Map) {
            final valor = body['existe'] ??
                body['yaCalificado'] ??
                body['calificado'] ??
                body['success'] ??
                body['data'];

            if (valor is bool) return valor;

            final texto = valor?.toString().toLowerCase();
            if (texto == 'true') return true;
            if (texto == 'false') return false;
          }

          return true;
        }
      } catch (_) {}
    }

    return false;
  }
}