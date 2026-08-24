import 'api_service.dart';

class TrackingService {
  Map<String, dynamic> _normalizarRespuesta(Map<String, dynamic> respuesta) {
    final statusCode = respuesta['statusCode'];

    final body = respuesta['body'];

    if (statusCode is int && statusCode >= 200 && statusCode < 300) {
      dynamic data = body;

      if (body is Map) {
        data = body['data'] ?? body;
      }

      final normalized = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{'success': true, 'data': data};

      if (body is Map) {
        final monitoring = body['monitoreoRuta'];
        if (monitoring != null) {
          normalized['monitoreoRuta'] = monitoring;
        }
        normalized['success'] = body['success'] ?? true;
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
        data = body['data'];
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
      'latitud': latitud,
      'longitud': longitud,
      'precisionGpsMetros': ?precisionGpsMetros,
      if (fechaLectura != null)
        'fechaCaptura': fechaLectura.toUtc().toIso8601String(),
    };

    final respuesta = await ApiService.postAuth(
      '/api/paseos/$paseoId/ubicacion',
      body,
    );
    return _normalizarRespuesta(respuesta);
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
    final respuesta = await ApiService.getAuth(
      '/api/paseos/$paseoId/ubicacion',
    );
    return _normalizarRespuesta(respuesta);
  }

  Future<List<Map<String, dynamic>>> obtenerHistorialUbicaciones(
    int paseoId,
  ) async {
    final respuesta = await ApiService.getAuth(
      '/api/paseos/$paseoId/ubicaciones',
    );
    return _normalizarLista(respuesta);
  }
}
