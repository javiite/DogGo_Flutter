import 'api_service.dart';

class TrackingService {
  Map<String, dynamic> _normalizarRespuesta(Map<String, dynamic> respuesta) {
    final statusCode = respuesta['statusCode'];

    final body = respuesta['body'];

    if (statusCode is int && statusCode >= 200 && statusCode < 300) {
      dynamic data = body;

      if (body is Map) {
        data =
            body['data'] ??
            body['ubicacion'] ??
            body['tracking'] ??
            body['ultimaUbicacion'] ??
            body['resultado'] ??
            body['result'] ??
            body['value'] ??
            body;
      }

      final normalized = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{'success': true, 'data': data};

      if (body is Map) {
        final monitoring = body['monitoreoRuta'] ?? body['MonitoreoRuta'];
        if (monitoring != null) {
          normalized['monitoreoRuta'] = monitoring;
        }
        normalized['success'] = body['success'] ?? body['Success'] ?? true;
      }

      return normalized;
    }

    String mensaje = 'Error al procesar tracking.';

    if (body is Map) {
      mensaje =
          body['message']?.toString() ??
          body['mensaje']?.toString() ??
          body['error']?.toString() ??
          mensaje;
    } else if (body != null) {
      mensaje = body.toString();
    }

    throw Exception('$mensaje Código: $statusCode');
  }

  List<Map<String, dynamic>> _normalizarLista(Map<String, dynamic> respuesta) {
    final statusCode = respuesta['statusCode'];

    final body = respuesta['body'];

    if (statusCode is int && statusCode >= 200 && statusCode < 300) {
      dynamic data = body;

      if (body is Map) {
        data =
            body['data'] ??
            body['ubicaciones'] ??
            body['historial'] ??
            body['ruta'] ??
            body['items'] ??
            body['resultado'] ??
            body['result'] ??
            body['value'];
      }

      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      return [];
    }

    String mensaje = 'Error al obtener historial de ubicaciones.';

    if (body is Map) {
      mensaje =
          body['message']?.toString() ??
          body['mensaje']?.toString() ??
          body['error']?.toString() ??
          mensaje;
    } else if (body != null) {
      mensaje = body.toString();
    }

    throw Exception('$mensaje Código: $statusCode');
  }

  Future<Map<String, dynamic>> enviarUbicacion({
    required int paseoId,
    required double latitud,
    required double longitud,
    double? precisionGpsMetros,
    DateTime? fechaLectura,
  }) async {
    final body = <String, dynamic>{
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

      'precisionGpsMetros': ?precisionGpsMetros,

      'PrecisionGpsMetros': ?precisionGpsMetros,

      if (fechaLectura != null)
        'fechaLectura': fechaLectura.toUtc().toIso8601String(),

      if (fechaLectura != null)
        'FechaLectura': fechaLectura.toUtc().toIso8601String(),
    };

    final endpoints = [
      '/api/paseos/$paseoId/ubicacion',
      '/api/Paseos/$paseoId/ubicacion',
      '/api/paseos/$paseoId/tracking',
      '/api/Paseos/$paseoId/tracking',
    ];

    Exception? ultimoError;

    for (final endpoint in endpoints) {
      try {
        final respuesta = await ApiService.postAuth(endpoint, body);

        return _normalizarRespuesta(respuesta);
      } catch (error) {
        ultimoError = Exception(error.toString());
      }
    }

    throw ultimoError ?? Exception('No se pudo enviar la ubicación.');
  }

  Future<Map<String, dynamic>> enviarUbicacionesLote({
    required int paseoId,
    required List<Map<String, dynamic>> puntos,
  }) async {
    if (puntos.isEmpty) {
      return <String, dynamic>{
        'paseoId': paseoId,
        'aceptadas': const <dynamic>[],
        'duplicadas': const <dynamic>[],
        'rechazadas': const <dynamic>[],
      };
    }

    final respuesta = await ApiService.postAuth(
      '/api/paseos/$paseoId/ubicaciones/lote',
      <String, dynamic>{'puntos': puntos},
    );

    return _normalizarRespuesta(respuesta);
  }

  Future<Map<String, dynamic>> obtenerUltimaUbicacion(int paseoId) async {
    final endpoints = [
      '/api/paseos/$paseoId/ubicacion',
      '/api/Paseos/$paseoId/ubicacion',
      '/api/paseos/$paseoId/ultima-ubicacion',
      '/api/Paseos/$paseoId/ultima-ubicacion',
    ];

    Exception? ultimoError;

    for (final endpoint in endpoints) {
      try {
        final respuesta = await ApiService.getAuth(endpoint);

        return _normalizarRespuesta(respuesta);
      } catch (error) {
        ultimoError = Exception(error.toString());
      }
    }

    throw ultimoError ?? Exception('No se pudo obtener la última ubicación.');
  }

  Future<List<Map<String, dynamic>>> obtenerHistorialUbicaciones(
    int paseoId,
  ) async {
    final endpoints = [
      '/api/paseos/$paseoId/ubicaciones',
      '/api/Paseos/$paseoId/ubicaciones',
      '/api/paseos/$paseoId/historial-ubicaciones',
      '/api/Paseos/$paseoId/historial-ubicaciones',
      '/api/paseos/$paseoId/ruta',
      '/api/Paseos/$paseoId/ruta',
    ];

    Exception? ultimoError;

    for (final endpoint in endpoints) {
      try {
        final respuesta = await ApiService.getAuth(endpoint);

        return _normalizarLista(respuesta);
      } catch (error) {
        ultimoError = Exception(error.toString());
      }
    }

    throw ultimoError ??
        Exception(
          'No se pudo obtener el historial '
          'de ubicaciones.',
        );
  }
}
