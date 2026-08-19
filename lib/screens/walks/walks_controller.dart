import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../core/offline/offline_walk_cache_repository.dart';
import '../../core/offline/offline_walk_sync_service.dart';
import '../../services/paseos_service.dart';
import '../../services/session_service.dart';
import '../../services/storage_service.dart';
import '../home/models/home_walk.dart';
import '../home/models/home_walk_status.dart';
import 'walks_state.dart';

class WalkActionResult {
  final bool success;
  final String message;
  final bool queued;

  const WalkActionResult({
    required this.success,
    required this.message,
    this.queued = false,
  });
}

class WalksController extends ChangeNotifier {
  final String? initialRole;
  final OfflineWalkSyncService _offlineSyncService;
  final OfflineWalkCacheRepository _cacheRepository;

  WalksState _state = const WalksState();

  bool _disposed = false;
  bool _requestInProgress = false;

  WalksController({
    this.initialRole,
    OfflineWalkSyncService? offlineSyncService,
    OfflineWalkCacheRepository? cacheRepository,
  }) : _offlineSyncService =
           offlineSyncService ?? OfflineWalkSyncService.instance,
       _cacheRepository = cacheRepository ?? OfflineWalkCacheRepository();

  WalksState get state => _state;

  Future<void> initialize() {
    return loadWalks();
  }

  Future<void> refresh() {
    return loadWalks();
  }

  Future<void> loadWalks({bool silent = false}) async {
    if (_requestInProgress) return;

    _requestInProgress = true;

    if (!silent) {
      _setState(_state.copyWith(loading: true, clearError: true));
    }

    try {
      final results = await Future.wait<dynamic>([
        StorageService.obtenerBaseUrl(),
        SessionService.obtenerRol(),
        PaseosService.obtenerMisPaseos(),
      ]);

      if (_disposed) return;

      final baseUrl = results[0]?.toString();

      final savedRole = results[1]?.toString().trim();

      final role = savedRole != null && savedRole.isNotEmpty
          ? savedRole
          : initialRole ?? '';

      final response = _asMap(results[2]);

      if (response['success'] != true) {
        throw Exception(
          _responseMessage(
            response,
            fallback: 'No se pudieron cargar tus paseos.',
          ),
        );
      }

      final rawWalks = _normalizeList(response['data']);

      try {
        await _cacheRepository.saveWalkList(rawWalks);
      } catch (_) {
        // Un fallo del caché no debe ocultar datos recibidos de la API.
      }

      final walks = rawWalks
          .map((map) => HomeWalk.fromMap(map, baseUrl: baseUrl))
          .toList(growable: false);

      _setState(
        WalksState(
          loading: false,
          baseUrl: baseUrl,
          role: role,
          walks: walks,
          selectedStatus: _state.selectedStatus,
          searchQuery: _state.searchQuery,
        ),
      );
    } catch (error) {
      if (_disposed) return;

      try {
        final cachedWalks = await _cacheRepository.getWalkList();

        if (_disposed) return;

        if (cachedWalks.isNotEmpty) {
          final baseUrl = await StorageService.obtenerBaseUrl();
          final savedRole = await SessionService.obtenerRol();
          final role = savedRole?.trim().isNotEmpty == true
              ? savedRole!.trim()
              : initialRole ?? _state.role;
          final walks = cachedWalks
              .map((map) => HomeWalk.fromMap(map, baseUrl: baseUrl))
              .toList(growable: false);

          _setState(
            WalksState(
              loading: false,
              baseUrl: baseUrl,
              role: role,
              walks: walks,
              selectedStatus: _state.selectedStatus,
              searchQuery: _state.searchQuery,
            ),
          );
          return;
        }
      } catch (_) {
        // Se conserva el error original de red o de la API.
      }

      _setState(_state.copyWith(loading: false, error: _cleanError(error)));
    } finally {
      _requestInProgress = false;
    }
  }

  void search(String query) {
    _setState(_state.copyWith(searchQuery: query));
  }

  void selectStatus(HomeWalkStatus? status) {
    _setState(
      status == null
          ? _state.copyWith(clearSelectedStatus: true)
          : _state.copyWith(selectedStatus: status),
    );
  }

  void clearFilters() {
    _setState(
      _state.copyWith(
        searchQuery: '',
        clearSelectedStatus: true,
        clearError: true,
      ),
    );
  }

  void clearError() {
    if (_state.error == null) return;

    _setState(_state.copyWith(clearError: true));
  }

  Future<WalkActionResult> accept(HomeWalk walk) {
    final id = walk.id;

    if (id == null) {
      return Future.value(
        const WalkActionResult(
          success: false,
          message: 'No se encontró el identificador del paseo.',
        ),
      );
    }

    return _executeAction(
      walkId: id,
      action: () => PaseosService.aceptarPaseo(id),
      successMessage: 'Paseo aceptado correctamente.',
    );
  }

  Future<WalkActionResult> reject(HomeWalk walk) {
    final id = walk.id;

    if (id == null) {
      return Future.value(
        const WalkActionResult(
          success: false,
          message: 'No se encontró el identificador del paseo.',
        ),
      );
    }

    return _executeAction(
      walkId: id,
      action: () => PaseosService.rechazarPaseo(id),
      successMessage: 'Paseo rechazado correctamente.',
    );
  }

  Future<WalkActionResult> start(HomeWalk walk) {
    final id = walk.id;

    if (id == null) {
      return Future.value(
        const WalkActionResult(
          success: false,
          message: 'No se encontró el identificador del paseo.',
        ),
      );
    }

    return _executeOfflineAction(
      walkId: id,
      action: () => _offlineSyncService.submitStart(id),
      successMessage: 'Paseo iniciado correctamente.',
      queuedMessage:
          'Inicio guardado en el dispositivo. Se sincronizará al recuperar la conexión.',
    );
  }

  Future<WalkActionResult> finish(HomeWalk walk) {
    final id = walk.id;

    if (id == null) {
      return Future.value(
        const WalkActionResult(
          success: false,
          message: 'No se encontró el identificador del paseo.',
        ),
      );
    }

    return _executeOfflineAction(
      walkId: id,
      action: () => _offlineSyncService.submitFinish(id),
      successMessage: 'Paseo finalizado correctamente.',
      queuedMessage:
          'Finalización guardada. El GPS pendiente se enviará al recuperar la conexión.',
    );
  }

  Future<WalkActionResult> cancel(HomeWalk walk, {required String reason}) {
    final id = walk.id;

    if (id == null) {
      return Future.value(
        const WalkActionResult(
          success: false,
          message: 'No se encontró el identificador del paseo.',
        ),
      );
    }

    final cleanReason = reason.trim();

    if (cleanReason.isEmpty) {
      return Future.value(
        const WalkActionResult(
          success: false,
          message: 'Escribe el motivo de la cancelación.',
        ),
      );
    }

    return _executeOfflineAction(
      walkId: id,
      action: () => _offlineSyncService.submitCancel(id, reason: cleanReason),
      successMessage: 'Paseo cancelado correctamente.',
      queuedMessage:
          'Cancelación guardada en el dispositivo. Se enviará al recuperar la conexión.',
    );
  }

  Future<WalkActionResult> _executeAction({
    required int walkId,
    required Future<Map<String, dynamic>> Function() action,
    required String successMessage,
  }) async {
    if (_state.actionInProgress) {
      return const WalkActionResult(
        success: false,
        message: 'Espera a que termine la acción actual.',
      );
    }

    _setState(_state.copyWith(actionWalkId: walkId, clearError: true));

    try {
      final response = await action();

      if (_disposed) {
        return const WalkActionResult(
          success: false,
          message: 'La pantalla ya se cerró.',
        );
      }

      if (response['success'] != true) {
        throw Exception(
          _responseMessage(
            response,
            fallback: 'No se pudo completar la acción.',
          ),
        );
      }

      final message = _responseMessage(response, fallback: successMessage);

      _setState(_state.copyWith(clearActionWalk: true, clearError: true));

      await loadWalks(silent: true);

      return WalkActionResult(success: true, message: message);
    } catch (error) {
      final message = _cleanError(error);

      if (!_disposed) {
        _setState(_state.copyWith(clearActionWalk: true, error: message));
      }

      return WalkActionResult(success: false, message: message);
    }
  }

  Future<WalkActionResult> _executeOfflineAction({
    required int walkId,
    required Future<OfflineWalkSubmissionResult> Function() action,
    required String successMessage,
    required String queuedMessage,
  }) async {
    if (_state.actionInProgress) {
      return const WalkActionResult(
        success: false,
        message: 'Espera a que termine la acción actual.',
      );
    }

    _setState(_state.copyWith(actionWalkId: walkId, clearError: true));

    try {
      final result = await action();

      if (_disposed) {
        return const WalkActionResult(
          success: false,
          message: 'La pantalla ya se cerró.',
        );
      }

      _setState(_state.copyWith(clearActionWalk: true, clearError: true));

      if (result.queued) {
        return WalkActionResult(
          success: true,
          message: queuedMessage,
          queued: true,
        );
      }

      await loadWalks(silent: true);

      return WalkActionResult(success: true, message: successMessage);
    } catch (error) {
      final message = _cleanError(error);

      if (!_disposed) {
        _setState(_state.copyWith(clearActionWalk: true, error: message));
      }

      return WalkActionResult(success: false, message: message);
    }
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

      if (nested != null && nested != value) {
        return _normalizeList(nested);
      }
    }

    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  String _responseMessage(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    final value =
        response['message'] ?? response['mensaje'] ?? response['error'];

    final message = value?.toString().trim();

    if (message == null || message.isEmpty) {
      return fallback;
    }

    return message;
  }

  String _cleanError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '')
        .trim();

    return message.isEmpty ? 'No se pudieron cargar tus paseos.' : message;
  }

  void _setState(WalksState newState) {
    if (_disposed) return;

    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
