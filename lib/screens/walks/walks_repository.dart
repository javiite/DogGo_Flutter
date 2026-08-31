import '../../core/offline/offline_walk_cache_repository.dart';
import '../../core/session/user_role.dart';
import '../../services/paseos_service.dart';
import '../../services/session_service.dart';
import '../../services/storage_service.dart';
import '../home/models/home_walk.dart';

class WalksLoadResult {
  final String? baseUrl;
  final UserRole role;
  final List<HomeWalk> walks;

  const WalksLoadResult({
    required this.baseUrl,
    required this.role,
    required this.walks,
  });
}

class WalksRepository {
  final OfflineWalkCacheRepository _cache;

  WalksRepository({OfflineWalkCacheRepository? cache})
    : _cache = cache ?? OfflineWalkCacheRepository();

  Future<WalksLoadResult> getMine({String? initialRole}) async {
    final results = await Future.wait<dynamic>([
      StorageService.obtenerBaseUrl(),
      SessionService.obtenerRol(),
      PaseosService.obtenerMisPaseos(),
    ]);
    final baseUrl = results[0]?.toString();
    final role = UserRoleCodec.parse(
      results[1]?.toString().trim().isNotEmpty == true
          ? results[1]?.toString()
          : initialRole,
    );
    final response = _asMap(results[2]);
    if (response['success'] != true) {
      throw Exception(_message(response, 'No se pudieron cargar tus paseos.'));
    }

    final rawWalks = _normalizeList(response['data']);
    try {
      await _cache.saveWalkList(rawWalks);
    } catch (_) {
      // El caché es una ayuda offline; la respuesta remota sigue siendo válida.
    }
    return _buildResult(baseUrl, role, rawWalks);
  }

  Future<WalksLoadResult?> getCached({String? initialRole}) async {
    final rawWalks = await _cache.getWalkList();
    if (rawWalks.isEmpty) return null;
    final baseUrl = await StorageService.obtenerBaseUrl();
    final savedRole = await SessionService.obtenerRol();
    return _buildResult(
      baseUrl,
      UserRoleCodec.parse(
        savedRole?.trim().isNotEmpty == true ? savedRole : initialRole,
      ),
      rawWalks,
    );
  }

  Future<Map<String, dynamic>> accept(int id) {
    return PaseosService.aceptarPaseo(id);
  }

  Future<Map<String, dynamic>> reject(int id) {
    return PaseosService.rechazarPaseo(id);
  }

  WalksLoadResult _buildResult(
    String? baseUrl,
    UserRole role,
    List<Map<String, dynamic>> rawWalks,
  ) {
    return WalksLoadResult(
      baseUrl: baseUrl,
      role: role,
      walks: rawWalks
          .map((map) => HomeWalk.fromMap(map, baseUrl: baseUrl))
          .toList(growable: false),
    );
  }

  List<Map<String, dynamic>> _normalizeList(dynamic value) {
    if (value is Map) {
      final nested =
          value['data'] ??
          value['paseos'] ??
          value['items'] ??
          value['resultado'] ??
          value['result'] ??
          value['value'];
      if (nested != null && nested != value) return _normalizeList(nested);
    }
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    return value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }

  String _message(Map<String, dynamic> response, String fallback) {
    final value =
        response['message'] ?? response['mensaje'] ?? response['error'];
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }
}
