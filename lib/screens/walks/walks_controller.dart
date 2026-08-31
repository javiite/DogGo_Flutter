import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../core/offline/offline_walk_sync_service.dart';
import '../home/models/home_walk.dart';
import '../home/models/home_walk_status.dart';
import 'walks_repository.dart';
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
  final WalksRepository _repository;

  WalksState _state = const WalksState();

  bool _disposed = false;
  bool _requestInProgress = false;

  WalksController({
    this.initialRole,
    OfflineWalkSyncService? offlineSyncService,
    WalksRepository? repository,
  }) : _offlineSyncService =
           offlineSyncService ?? OfflineWalkSyncService.instance,
       _repository = repository ?? WalksRepository();

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
      final result = await _repository.getMine(initialRole: initialRole);

      if (_disposed) return;

      _setState(
        WalksState(
          loading: false,
          baseUrl: result.baseUrl,
          role: result.role,
          walks: result.walks,
          selectedStatus: _state.selectedStatus,
          searchQuery: _state.searchQuery,
        ),
      );
    } catch (error) {
      if (_disposed) return;

      try {
        final cached = await _repository.getCached(initialRole: initialRole);

        if (_disposed) return;

        if (cached != null) {
          _setState(
            WalksState(
              loading: false,
              baseUrl: cached.baseUrl,
              role: cached.role,
              walks: cached.walks,
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
      action: () => _repository.accept(id),
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
      action: () => _repository.reject(id),
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
