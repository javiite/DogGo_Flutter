import '../core/errors/api_exception.dart';
import '../screens/routes/models/doggo_route.dart';
import 'api_service.dart';

class RoutesService {
  RoutesService._();

  static Future<List<SavedDoggoRoute>> getSavedRoutes() async {
    final response = await ApiService.getAuth('/api/rutas-guardadas');

    final body = _requireSuccess(
      response,
      fallbackMessage: 'No se pudieron cargar tus rutas.',
    );

    final data = body['data'];

    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map>()
        .map((item) => SavedDoggoRoute.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  static Future<SavedDoggoRoute> getSavedRoute(int routeId) async {
    final response = await ApiService.getAuth('/api/rutas-guardadas/$routeId');

    final body = _requireSuccess(
      response,
      fallbackMessage: 'No se pudo cargar la ruta.',
    );

    return SavedDoggoRoute.fromMap(_requireDataMap(body));
  }

  static Future<SavedDoggoRoute> createSavedRoute(DoggoRouteDraft draft) async {
    final response = await ApiService.postAuth(
      '/api/rutas-guardadas',
      draft.toSavedRouteJson(),
    );

    final body = _requireSuccess(
      response,
      fallbackMessage: 'No se pudo guardar la ruta.',
    );

    return SavedDoggoRoute.fromMap(_requireDataMap(body));
  }

  static Future<SavedDoggoRoute> updateSavedRoute({
    required int routeId,
    required DoggoRouteDraft draft,
  }) async {
    final response = await ApiService.putAuth(
      '/api/rutas-guardadas/$routeId',
      draft.toSavedRouteJson(),
    );

    final body = _requireSuccess(
      response,
      fallbackMessage: 'No se pudo actualizar la ruta.',
    );

    return SavedDoggoRoute.fromMap(_requireDataMap(body));
  }

  static Future<SavedDoggoRoute> duplicateSavedRoute(int routeId) async {
    final response = await ApiService.postAuth(
      '/api/rutas-guardadas/$routeId/duplicar',
      const {},
    );

    final body = _requireSuccess(
      response,
      fallbackMessage: 'No se pudo duplicar la ruta.',
    );

    return SavedDoggoRoute.fromMap(_requireDataMap(body));
  }

  static Future<void> deleteSavedRoute(int routeId) async {
    final response = await ApiService.deleteAuth(
      '/api/rutas-guardadas/$routeId',
    );

    _requireSuccess(response, fallbackMessage: 'No se pudo eliminar la ruta.');
  }

  static Future<PlannedDoggoRoute> assignSavedRoute({
    required int walkId,
    required int savedRouteId,
  }) async {
    final response = await ApiService.putAuth(
      '/api/paseos/$walkId/ruta-planificada',
      {'rutaGuardadaId': savedRouteId},
    );

    final body = _requireSuccess(
      response,
      fallbackMessage: 'No se pudo asignar la ruta al paseo.',
    );

    return PlannedDoggoRoute.fromMap(_requireDataMap(body));
  }

  static Future<PlannedDoggoRoute> assignCustomRoute({
    required int walkId,
    required DoggoRouteDraft draft,
    bool saveAsTemplate = false,
    String? templateName,
  }) async {
    final response = await ApiService.putAuth(
      '/api/paseos/$walkId/ruta-planificada',
      draft.toAssignmentJson(
        saveAsTemplate: saveAsTemplate,
        templateName: templateName,
      ),
    );

    final body = _requireSuccess(
      response,
      fallbackMessage: 'No se pudo asignar la ruta al paseo.',
    );

    return PlannedDoggoRoute.fromMap(_requireDataMap(body));
  }

  static Future<PlannedDoggoRoute?> getPlannedRoute(int walkId) async {
    final response = await ApiService.getAuth(
      '/api/paseos/$walkId/ruta-planificada',
    );

    final statusCode = response['statusCode'];

    if (statusCode == 404) {
      return null;
    }

    final body = _requireSuccess(
      response,
      fallbackMessage: 'No se pudo consultar la ruta del paseo.',
    );

    return PlannedDoggoRoute.fromMap(_requireDataMap(body));
  }

  static Future<void> removePlannedRoute(int walkId) async {
    final response = await ApiService.deleteAuth(
      '/api/paseos/$walkId/ruta-planificada',
    );

    _requireSuccess(
      response,
      fallbackMessage: 'No se pudo quitar la ruta del paseo.',
    );
  }

  static Map<String, dynamic> _requireSuccess(
    Map<String, dynamic> response, {
    required String fallbackMessage,
  }) {
    final statusCode = response['statusCode'];

    final rawBody = response['body'] ?? response;

    final body = rawBody is Map
        ? Map<String, dynamic>.from(rawBody)
        : <String, dynamic>{};

    final validStatus =
        statusCode is int && statusCode >= 200 && statusCode < 300;

    final declaredSuccess = body['success'];

    final successful = declaredSuccess is bool
        ? declaredSuccess && validStatus
        : validStatus;

    if (!successful) {
      final message =
          (body['message'] ??
                  body['mensaje'] ??
                  body['error'] ??
                  fallbackMessage)
              .toString();

      throw ApiException(
        type: statusCode == 401 || statusCode == 403
            ? ApiErrorType.noSession
            : ApiErrorType.invalidResponse,
        message: message,
        statusCode: statusCode is int ? statusCode : null,
      );
    }

    return body;
  }

  static Map<String, dynamic> _requireDataMap(Map<String, dynamic> body) {
    final data = body['data'];

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw const ApiException(
      type: ApiErrorType.invalidResponse,
      message: 'El servidor devolvió una ruta incompleta.',
    );
  }
}
