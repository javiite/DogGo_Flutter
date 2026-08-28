import 'api_service.dart';

abstract final class AdvancedExperienceService {
  static const _root = '/api/vida-doggo';

  static Future<Map<String, dynamic>> summary() async =>
      _map(await ApiService.getAuth('$_root/resumen'));

  static Future<List<Map<String, dynamic>>> matching() async =>
      _list(await ApiService.getAuth('$_root/matching'));

  static Future<Map<String, dynamic>> trust(int walkerId) async =>
      _map(await ApiService.getAuth('$_root/paseadores/$walkerId/confianza'));

  static Future<Map<String, dynamic>> saveWalkerPreference(
    int walkerId, {
    required bool favorite,
    required bool backup,
    int priority = 0,
  }) async => _map(
    await ApiService.putAuth('$_root/paseadores/$walkerId/preferencia', {
      'esFavorito': favorite,
      'esSuplente': backup,
      'prioridad': priority,
    }),
  );

  static Future<Map<String, dynamic>> recommendations({
    required int walkerId,
    int durationMinutes = 60,
    int pets = 1,
  }) async => _map(
    await ApiService.getAuth(
      '$_root/planificacion/recomendaciones'
      '?paseadorId=$walkerId&duracionMinutos=$durationMinutes&mascotas=$pets',
    ),
  );

  static Future<Map<String, dynamic>> walkPlan(int walkId) async =>
      _map(await ApiService.getAuth('$_root/paseos/$walkId/planificacion'));

  static Future<Map<String, dynamic>> saveWalkPlan(
    int walkId,
    Map<String, dynamic> data,
  ) async => _map(
    await ApiService.putAuth('$_root/paseos/$walkId/planificacion', data),
  );

  static Future<Map<String, dynamic>> requestReschedule(
    int walkId, {
    required DateTime proposedDate,
    required String reason,
  }) async => _map(
    await ApiService.postAuth('$_root/paseos/$walkId/reprogramacion', {
      'fechaPropuestaUtc': proposedDate.toUtc().toIso8601String(),
      'motivo': reason.trim(),
    }),
  );

  static Future<Map<String, dynamic>> answerReschedule(
    int walkId, {
    required bool accept,
  }) async => _map(
    await ApiService.postAuth(
      '$_root/paseos/$walkId/reprogramacion/responder',
      {'aceptar': accept},
    ),
  );

  static Future<Map<String, dynamic>> updateArrival(
    int walkId, {
    required String state,
    int? etaMinutes,
  }) async => _map(
    await ApiService.postAuth('$_root/paseos/$walkId/llegada', {
      'estado': state,
      'etaMinutos': ?etaMinutes,
    }),
  );

  static Future<Map<String, dynamic>> petCare(int petId) async =>
      _map(await ApiService.getAuth('$_root/perros/$petId/cuidados'));

  static Future<Map<String, dynamic>> savePetCare(
    int petId,
    Map<String, dynamic> data,
  ) async =>
      _map(await ApiService.putAuth('$_root/perros/$petId/cuidados', data));

  static Future<Map<String, dynamic>> petAchievements(int petId) async =>
      _map(await ApiService.getAuth('$_root/perros/$petId/logros'));

  static Future<Map<String, dynamic>> family() async =>
      _map(await ApiService.getAuth('$_root/familia'));

  static Future<Map<String, dynamic>> saveFamily(String name) async =>
      _map(await ApiService.putAuth('$_root/familia', {'nombre': name.trim()}));

  static Future<Map<String, dynamic>> addFamilyMember({
    required String email,
    required bool canRequestWalks,
    required bool canEditCare,
  }) async => _map(
    await ApiService.postAuth('$_root/familia/miembros', {
      'email': email.trim(),
      'puedeSolicitarPaseos': canRequestWalks,
      'puedeEditarCuidados': canEditCare,
    }),
  );

  static Future<Map<String, dynamic>> removeFamilyMember(int memberId) async =>
      _map(await ApiService.deleteAuth('$_root/familia/miembros/$memberId'));

  static Future<Map<String, dynamic>> leaveFamily() async =>
      _map(await ApiService.deleteAuth('$_root/familia/salir'));

  static Map<String, dynamic> _map(Map<String, dynamic> response) {
    final status = response['statusCode'];
    final body = response['body'];
    if (status is int && (status < 200 || status >= 300)) {
      throw Exception(_message(body));
    }
    dynamic value = body ?? response;
    if (value is Map) value = value['data'] ?? value;
    return value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _list(Map<String, dynamic> response) {
    final status = response['statusCode'];
    final body = response['body'];
    if (status is int && (status < 200 || status >= 300)) {
      throw Exception(_message(body));
    }
    dynamic value = body;
    if (value is Map) value = value['data'];
    return value is List
        ? value
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : const [];
  }

  static String _message(dynamic body) => body is Map
      ? body['message']?.toString() ?? 'No se pudo completar la acción.'
      : 'No se pudo completar la acción.';
}
