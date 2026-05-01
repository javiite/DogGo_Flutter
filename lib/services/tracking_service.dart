import 'api_service.dart';

class TrackingService {
  Map<String, dynamic> _normalizarRespuesta(Map<String, dynamic> respuesta) {
    final statusCode = respuesta['statusCode'];
    final body = respuesta['body'];

    if (statusCode is int && statusCode >= 200 && statusCode < 300) {
      dynamic data = body;

      if (body is Map) {
        data = body['data'] ??
            body['ubicacion'] ??
            body['tracking'] ??
            body['ultimaUbicacion'] ??
            body['resultado'] ??
            body['result'] ??
            body['value'] ??
            body;
      }

      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);

      return {
        'success': true,
        'data': data,
      };
    }

    String mensaje = 'Error al procesar tracking.';

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

  Future<Map<String, dynamic>> enviarUbicacion({
    required int paseoId,
    required double latitud,
    required double longitud,
  }) async {
    final body = {
      'paseoId': paseoId,
      'PaseoId': paseoId,
      'latitud': latitud,
      'Latitud': latitud,
      'longitud': longitud,
      'Longitud': longitud,
      'latitudActual': latitud,
      'LatitudActual': latitud,
      'longitudActual': longitud,
      'LongitudActual': longitud,
    };

    final endpoints = [
      '/api/paseos/$paseoId/ubicacion',
      '/api/Paseos/$paseoId/ubicacion',
      '/api/paseos/$paseoId/tracking',
      '/api/Paseos/$paseoId/tracking',
      '/api/ubicaciones',
      '/api/Ubicaciones',
      '/api/tracking',
      '/api/Tracking',
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

    throw ultimoError ?? Exception('No se pudo enviar la ubicación.');
  }

  Future<Map<String, dynamic>> obtenerUltimaUbicacion(int paseoId) async {
    final endpoints = [
      '/api/paseos/$paseoId/ubicacion',
      '/api/Paseos/$paseoId/ubicacion',
      '/api/paseos/$paseoId/ultima-ubicacion',
      '/api/Paseos/$paseoId/ultima-ubicacion',
      '/api/ubicaciones/paseo/$paseoId/ultima',
      '/api/Ubicaciones/paseo/$paseoId/ultima',
      '/api/tracking/paseo/$paseoId',
      '/api/Tracking/paseo/$paseoId',
    ];

    Exception? ultimoError;

    for (final endpoint in endpoints) {
      try {
        final respuesta = await ApiService.getAuth(endpoint);
        return _normalizarRespuesta(respuesta);
      } catch (e) {
        ultimoError = Exception(e.toString());
      }
    }

    throw ultimoError ?? Exception('No se pudo obtener la última ubicación.');
  }
}