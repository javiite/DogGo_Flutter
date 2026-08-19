import 'api_service.dart';

class PerrosService {
  static Future<Map<String, dynamic>> obtenerMisPerros() async {
    final response = await ApiService.getAuth('/api/perros');

    final result = _normalizeResponse(
      response,
      fallback: 'No se pudieron obtener los perros.',
    );

    if (result['success'] == true) {
      result['data'] = _normalizarLista(result['data']);
    }

    return result;
  }

  static Future<Map<String, dynamic>> obtenerPerroPorId(int id) async {
    final response = await ApiService.getAuth('/api/perros/$id');

    final result = _normalizeResponse(
      response,
      fallback: 'No se pudo obtener el perro.',
    );

    if (result['success'] == true) {
      result['data'] = _normalizarMapa(result['data']);
    }

    return result;
  }

  static Future<Map<String, dynamic>> obtenerFotos(int id) async {
    final response = await ApiService.getAuth('/api/perros/$id/fotos');

    final result = _normalizeResponse(
      response,
      fallback: 'No se pudo obtener la galería.',
    );

    if (result['success'] == true) {
      result['data'] = _normalizarLista(result['data']);
    }

    return result;
  }

  static Future<Map<String, dynamic>> registrarPerro({
    required String nombre,
    required String raza,
    required int edad,
    required String tamano,
    required String notas,
    String? fotoUrl,
    double? peso,
    String? sexo,
    bool? esterilizado,
    String? temperamento,
    String? nivelEnergia,
    bool? sociableConPerros,
    bool? sociableConPersonas,
    bool? sociableConNinos,
    String? comportamientoCorrea,
    bool? reactivo,
    bool? riesgoEscape,
    String? miedosDetonantes,
    String? comandosConocidos,
  }) async {
    final data = _petBody(
      nombre: nombre,
      raza: raza,
      edad: edad,
      tamano: tamano,
      notas: notas,
      fotoUrl: fotoUrl,
      peso: peso,
      sexo: sexo,
      esterilizado: esterilizado,
      temperamento: temperamento,
      nivelEnergia: nivelEnergia,
      sociableConPerros: sociableConPerros,
      sociableConPersonas: sociableConPersonas,
      sociableConNinos: sociableConNinos,
      comportamientoCorrea: comportamientoCorrea,
      reactivo: reactivo,
      riesgoEscape: riesgoEscape,
      miedosDetonantes: miedosDetonantes,
      comandosConocidos: comandosConocidos,
    );

    final response = await ApiService.postAuth('/api/perros', data);

    return _normalizeResponse(
      response,
      fallback: 'No se pudo registrar el perro.',
    );
  }

  static Future<Map<String, dynamic>> editarPerro({
    required int id,
    required String nombre,
    required String raza,
    required int edad,
    required String tamano,
    required String notas,
    String? fotoUrl,
    double? peso,
    String? sexo,
    bool? esterilizado,
    String? temperamento,
    String? nivelEnergia,
    bool? sociableConPerros,
    bool? sociableConPersonas,
    bool? sociableConNinos,
    String? comportamientoCorrea,
    bool? reactivo,
    bool? riesgoEscape,
    String? miedosDetonantes,
    String? comandosConocidos,
  }) async {
    final data = _petBody(
      nombre: nombre,
      raza: raza,
      edad: edad,
      tamano: tamano,
      notas: notas,
      fotoUrl: fotoUrl,
      peso: peso,
      sexo: sexo,
      esterilizado: esterilizado,
      temperamento: temperamento,
      nivelEnergia: nivelEnergia,
      sociableConPerros: sociableConPerros,
      sociableConPersonas: sociableConPersonas,
      sociableConNinos: sociableConNinos,
      comportamientoCorrea: comportamientoCorrea,
      reactivo: reactivo,
      riesgoEscape: riesgoEscape,
      miedosDetonantes: miedosDetonantes,
      comandosConocidos: comandosConocidos,
    );

    final response = await ApiService.putAuth('/api/perros/$id', data);

    return _normalizeResponse(
      response,
      fallback: 'No se pudo actualizar el perro.',
    );
  }

  // Método anterior: sube una foto y la convierte
  // directamente en la portada.
  static Future<Map<String, dynamic>> subirFotoPerro({
    required int id,
    required String filePath,
  }) async {
    final response = await ApiService.postMultipartAuth(
      '/api/perros/$id/foto',
      filePath: filePath,
      fileFieldName: 'foto',
    );

    return _normalizeResponse(response, fallback: 'No se pudo subir la foto.');
  }

  static Future<Map<String, dynamic>> agregarFotoGaleria({
    required int id,
    required String filePath,
    bool hacerPrincipal = false,
  }) async {
    final response = await ApiService.postMultipartAuth(
      '/api/perros/$id/fotos',
      filePath: filePath,
      fileFieldName: 'foto',
      fields: {'principal': hacerPrincipal.toString()},
    );

    return _normalizeResponse(
      response,
      fallback: 'No se pudo agregar la fotografía.',
    );
  }

  static Future<Map<String, dynamic>> marcarFotoPrincipal({
    required int id,
    required int fotoId,
  }) async {
    final response = await ApiService.putAuth(
      '/api/perros/$id/fotos/'
      '$fotoId/principal',
    );

    return _normalizeResponse(
      response,
      fallback: 'No se pudo cambiar la foto principal.',
    );
  }

  static Future<Map<String, dynamic>> eliminarFotoGaleria({
    required int id,
    required int fotoId,
  }) async {
    final response = await ApiService.deleteAuth(
      '/api/perros/$id/fotos/$fotoId',
    );

    return _normalizeResponse(
      response,
      fallback: 'No se pudo eliminar la fotografía.',
    );
  }

  static Future<Map<String, dynamic>> eliminarPerro(int id) async {
    final response = await ApiService.deleteAuth('/api/perros/$id');

    return _normalizeResponse(
      response,
      fallback: 'No se pudo eliminar el perro.',
    );
  }

  static Map<String, dynamic> _petBody({
    required String nombre,
    required String raza,
    required int edad,
    required String tamano,
    required String notas,
    String? fotoUrl,
    double? peso,
    String? sexo,
    bool? esterilizado,
    String? temperamento,
    String? nivelEnergia,
    bool? sociableConPerros,
    bool? sociableConPersonas,
    bool? sociableConNinos,
    String? comportamientoCorrea,
    bool? reactivo,
    bool? riesgoEscape,
    String? miedosDetonantes,
    String? comandosConocidos,
  }) {
    final data = <String, dynamic>{
      'nombre': nombre.trim(),
      'raza': raza.trim(),
      'edad': edad,
      'tamano': tamano.trim(),
      'tamanio': tamano.trim(),
      'tamaño': tamano.trim(),
      'notas': notas.trim(),
      'observaciones': notas.trim(),
      'peso': peso,
      'sexo': sexo,
      'esterilizado': esterilizado,
      'temperamento': temperamento?.trim(),
      'nivelEnergia': nivelEnergia,
      'sociableConPerros': sociableConPerros,
      'sociableConPersonas': sociableConPersonas,
      'sociableConNinos': sociableConNinos,
      'comportamientoCorrea': comportamientoCorrea,
      'reactivo': reactivo,
      'riesgoEscape': riesgoEscape,
      'miedosDetonantes': miedosDetonantes?.trim(),
      'comandosConocidos': comandosConocidos?.trim(),
    };

    final photo = fotoUrl?.trim() ?? '';

    if (photo.isNotEmpty) {
      data['fotoUrl'] = photo;
      data['imagenUrl'] = photo;
    }

    return data;
  }

  static Map<String, dynamic> _normalizeResponse(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    final statusCode = response['statusCode'];
    final rawBody = response['body'] ?? response;

    final body = rawBody is Map
        ? Map<String, dynamic>.from(rawBody)
        : <String, dynamic>{};

    final validStatus = statusCode is int
        ? statusCode >= 200 && statusCode < 300
        : false;

    final successValue = body['success'];
    final success = successValue is bool ? successValue : validStatus;

    return {
      'success': success,
      'message':
          (body['message'] ??
                  body['mensaje'] ??
                  response['message'] ??
                  fallback)
              .toString(),
      'data': body['data'] ?? body['Data'],
      'statusCode': statusCode,
    };
  }

  static List<dynamic> _normalizarLista(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      final possibleList =
          data['items'] ??
          data['perros'] ??
          data['fotos'] ??
          data['data'] ??
          data['result'] ??
          data['resultado'];

      if (possibleList is List) {
        return possibleList;
      }
    }

    return [];
  }

  static Map<String, dynamic> _normalizarMapa(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {};
  }
}
