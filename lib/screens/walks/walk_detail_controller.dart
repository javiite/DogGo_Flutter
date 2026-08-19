import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../core/offline/offline_tracking_models.dart';
import '../../core/offline/offline_walk_cache_repository.dart';
import '../../core/offline/offline_walk_sync_service.dart';
import '../../services/background_tracking_service.dart';
import '../../services/paseo_mascotas_service.dart';
import '../../services/paseos_service.dart';
import '../../services/session_service.dart';
import '../../services/storage_service.dart';
import 'models/walk_detail.dart';
import 'walk_detail_state.dart';

enum WalkDetailAction { accept, reject, start, finish, cancel }

enum WalkDetailResultCode {
  completed,
  queued,
  invalidAction,
  missingWalk,
  finalEvidenceRequired,
  cancellationReasonRequired,
  failed,
}

class WalkDetailResult {
  final bool success;
  final String message;
  final WalkDetailResultCode code;

  const WalkDetailResult({
    required this.success,
    required this.message,
    required this.code,
  });

  const WalkDetailResult.success(this.message)
    : success = true,
      code = WalkDetailResultCode.completed;

  const WalkDetailResult.queued(this.message)
    : success = true,
      code = WalkDetailResultCode.queued;

  const WalkDetailResult.failure(
    this.message, {
    this.code = WalkDetailResultCode.failed,
  }) : success = false;
}

class WalkDetailController extends ChangeNotifier {
  final OfflineWalkSyncService _offlineSyncService;
  final OfflineWalkCacheRepository _cacheRepository;

  WalkDetailState _state;

  bool _disposed = false;
  bool _loadInProgress = false;
  bool _actionInProgress = false;

  WalkDetailController({
    int? id,
    int? walkId,
    Map<String, dynamic>? initialWalk,
    String? role,
    OfflineWalkSyncService? offlineSyncService,
    OfflineWalkCacheRepository? cacheRepository,
  }) : _offlineSyncService =
           offlineSyncService ?? OfflineWalkSyncService.instance,
       _cacheRepository = cacheRepository ?? OfflineWalkCacheRepository(),
       _state = WalkDetailState(
         requestedId: walkId ?? id ?? _extractId(initialWalk),
         role: role ?? '',
         walk: initialWalk == null ? null : WalkDetail.fromMap(initialWalk),
       );

  WalkDetailState get state => _state;

  Future<void> initialize() async {
    _setState(_state.copyWith(loading: true, clearError: true));

    try {
      final results = await Future.wait<dynamic>([
        StorageService.obtenerBaseUrl(),
        SessionService.obtenerRol(),
      ]);

      if (_disposed) {
        return;
      }

      final storedRole = results[1]?.toString().trim();

      _setState(
        _state.copyWith(
          baseUrl: results[0]?.toString(),
          role: storedRole != null && storedRole.isNotEmpty
              ? storedRole
              : _state.role,
        ),
      );
    } catch (_) {
      // Puede continuar con la información
      // recibida por navegación.
    }

    await loadDetail();
  }

  Future<void> refresh() {
    return loadDetail();
  }

  Future<void> loadDetail() async {
    if (_loadInProgress) {
      return;
    }

    final id = _state.walkId;

    if (id == null || id <= 0) {
      _setState(
        _state.copyWith(
          loading: false,
          error: _state.walk == null
              ? 'No se pudo identificar el paseo.'
              : null,
          clearError: _state.walk != null,
        ),
      );
      return;
    }

    _loadInProgress = true;

    if (_state.walk == null) {
      _setState(_state.copyWith(loading: true, clearError: true));
    }

    try {
      var response = await PaseoMascotasService.obtenerDetalle(id);

      // Compatibilidad si el backend anterior
      // sigue activo temporalmente.
      if (response['success'] != true) {
        response = await PaseosService.obtenerPaseoPorId(id);
      }

      if (_disposed) {
        return;
      }

      if (response['success'] != true) {
        throw Exception(
          _responseMessage(
            response,
            fallback: 'No se pudo cargar el detalle del paseo.',
          ),
        );
      }

      final detailMap = _normalizeDetail(response['data']);

      try {
        await _cacheRepository.saveWalkDetail(detailMap);
      } catch (_) {
        // Un fallo del caché no debe ocultar el detalle recibido.
      }

      _setState(
        _state.copyWith(
          loading: false,
          walk: WalkDetail.fromMap(detailMap),
          clearError: true,
        ),
      );
    } catch (error) {
      if (_disposed) {
        return;
      }

      try {
        final cachedDetail = await _cacheRepository.getWalkDetail(id);

        if (_disposed) return;

        if (cachedDetail != null) {
          _setState(
            _state.copyWith(
              loading: false,
              walk: WalkDetail.fromMap(cachedDetail),
              clearError: true,
            ),
          );
          return;
        }
      } catch (_) {
        // Se conserva el detalle de navegación o el error original.
      }

      _setState(
        _state.copyWith(
          loading: false,
          error: _state.walk == null ? _cleanError(error) : null,
          clearError: _state.walk != null,
        ),
      );
    } finally {
      _loadInProgress = false;
    }
  }

  Future<WalkDetailResult> perform(
    WalkDetailAction action, {
    String cancellationReason = '',
  }) async {
    if (_actionInProgress) {
      return const WalkDetailResult.failure(
        'Ya hay una acción en proceso.',
        code: WalkDetailResultCode.invalidAction,
      );
    }

    final walk = _state.walk;
    final id = _state.walkId;

    if (walk == null || id == null || id <= 0) {
      return const WalkDetailResult.failure(
        'No se pudo identificar el paseo.',
        code: WalkDetailResultCode.missingWalk,
      );
    }

    final hasPendingStart =
        action == WalkDetailAction.finish &&
        await _offlineSyncService.hasPendingOperation(
          id,
          PendingWalkOperationType.start,
        );
    final hasPendingEndEvidence =
        action == WalkDetailAction.finish &&
        await _offlineSyncService.hasPendingOperation(
          id,
          PendingWalkOperationType.uploadEndEvidence,
        );

    final validation = _validateAction(
      action,
      cancellationReason: cancellationReason,
      hasPendingStart: hasPendingStart,
      hasPendingEndEvidence: hasPendingEndEvidence,
    );

    if (validation != null) {
      return validation;
    }

    _actionInProgress = true;

    _setState(_state.copyWith(acting: true, clearError: true));

    try {
      Map<String, dynamic>? response;
      OfflineWalkSubmissionResult? offlineResult;

      late final String successMessage;
      late final String queuedMessage;

      switch (action) {
        case WalkDetailAction.accept:
          response = await PaseosService.aceptarPaseo(id);
          successMessage = 'Paseo aceptado correctamente.';
          queuedMessage = successMessage;
          break;

        case WalkDetailAction.reject:
          response = await PaseosService.rechazarPaseo(id);
          successMessage = 'Paseo rechazado correctamente.';
          queuedMessage = successMessage;
          break;

        case WalkDetailAction.start:
          offlineResult = await _offlineSyncService.submitStart(id);
          successMessage =
              'Paseo iniciado. Registra la evidencia inicial y activa el seguimiento.';
          queuedMessage =
              'Inicio guardado en el dispositivo. Registra la evidencia y continúa el paseo; se sincronizará al recuperar la conexión.';
          break;

        case WalkDetailAction.finish:
          offlineResult = await _offlineSyncService.submitFinish(id);
          successMessage = 'Paseo finalizado correctamente.';
          queuedMessage =
              'Finalización guardada en el dispositivo. El GPS y las evidencias se enviarán al recuperar la conexión.';
          break;

        case WalkDetailAction.cancel:
          offlineResult = await _offlineSyncService.submitCancel(
            id,
            reason: cancellationReason.trim(),
          );
          successMessage = 'Paseo cancelado correctamente.';
          queuedMessage =
              'Cancelación guardada en el dispositivo. Se enviará al recuperar la conexión.';
          break;
      }

      if (offlineResult != null) {
        if (action == WalkDetailAction.finish ||
            action == WalkDetailAction.cancel) {
          await _stopTrackingSafely();
        }

        if (offlineResult.queued) {
          await _applyOptimisticStatus(
            action,
            cancellationReason: cancellationReason,
          );
          return WalkDetailResult.queued(queuedMessage);
        }

        await loadDetail();
        return WalkDetailResult.success(successMessage);
      }

      if (response?['success'] != true) {
        throw Exception(
          _responseMessage(
            response ?? const <String, dynamic>{},
            fallback: 'No se pudo completar la acción.',
          ),
        );
      }

      if (action == WalkDetailAction.finish ||
          action == WalkDetailAction.cancel) {
        try {
          await BackgroundTrackingService.detenerTracking();
        } catch (_) {
          // La acción principal ya se completó.
        }
      }

      await loadDetail();

      return WalkDetailResult.success(successMessage);
    } catch (error) {
      return WalkDetailResult.failure(_cleanError(error));
    } finally {
      _actionInProgress = false;

      _setState(_state.copyWith(acting: false));
    }
  }

  Future<void> _stopTrackingSafely() async {
    try {
      await BackgroundTrackingService.detenerTracking();
    } catch (_) {
      // La operación local ya quedó guardada.
    }
  }

  Future<void> _applyOptimisticStatus(
    WalkDetailAction action, {
    String cancellationReason = '',
  }) async {
    final walk = _state.walk;
    if (walk == null) return;

    final now = DateTime.now().toIso8601String();
    final data = walk.toNavigationMap();

    switch (action) {
      case WalkDetailAction.start:
        data['estado'] = 'EnCurso';
        data['fechaInicio'] = now;
        break;
      case WalkDetailAction.finish:
        data['estado'] = 'Finalizado';
        data['fechaFin'] = now;
        break;
      case WalkDetailAction.cancel:
        data['estado'] = 'Cancelado';
        data['fechaCancelacion'] = now;
        data['motivoCancelacion'] = cancellationReason.trim();
        break;
      case WalkDetailAction.accept:
      case WalkDetailAction.reject:
        return;
    }

    _setState(
      _state.copyWith(walk: WalkDetail.fromMap(data), clearError: true),
    );

    try {
      await _cacheRepository.saveWalkDetail(data);
    } catch (_) {
      // La operación pendiente permanece protegida en su propia cola.
    }
  }

  Future<WalkDetailResult> proposePetChange({
    required List<int> acceptedPetIds,
    required String reason,
  }) async {
    if (_actionInProgress) {
      return const WalkDetailResult.failure(
        'Ya hay una acción en proceso.',
        code: WalkDetailResultCode.invalidAction,
      );
    }

    final id = _state.walkId;

    if (id == null || id <= 0) {
      return const WalkDetailResult.failure(
        'No se pudo identificar el paseo.',
        code: WalkDetailResultCode.missingWalk,
      );
    }

    if (!_state.canProposePetChange) {
      return const WalkDetailResult.failure(
        'No puedes proponer cambios en este paseo.',
        code: WalkDetailResultCode.invalidAction,
      );
    }

    final cleanIds = acceptedPetIds
        .where((petId) => petId > 0)
        .toSet()
        .toList();

    if (cleanIds.isEmpty) {
      return const WalkDetailResult.failure(
        'Selecciona al menos una mascota.',
        code: WalkDetailResultCode.invalidAction,
      );
    }

    final requestedIds = _state.walk!.requestedPets
        .map((pet) => pet.id)
        .toSet();

    if (cleanIds.any((petId) => !requestedIds.contains(petId))) {
      return const WalkDetailResult.failure(
        'La propuesta contiene una mascota inválida.',
        code: WalkDetailResultCode.invalidAction,
      );
    }

    if (cleanIds.length >= requestedIds.length) {
      return const WalkDetailResult.failure(
        'Para aceptar todas las mascotas usa el botón “Aceptar solicitud”.',
        code: WalkDetailResultCode.invalidAction,
      );
    }

    final cleanReason = reason.trim();

    if (cleanReason.length < 5) {
      return const WalkDetailResult.failure(
        'Explica brevemente por qué propones el cambio.',
        code: WalkDetailResultCode.invalidAction,
      );
    }

    _actionInProgress = true;

    _setState(_state.copyWith(acting: true, clearError: true));

    try {
      final response = await PaseoMascotasService.proponerCambio(
        paseoId: id,
        acceptedPetIds: cleanIds,
        reason: cleanReason,
      );

      if (response['success'] != true) {
        throw Exception(
          _responseMessage(
            response,
            fallback: 'No se pudo enviar la propuesta.',
          ),
        );
      }

      await loadDetail();

      return const WalkDetailResult.success('Propuesta enviada al dueño.');
    } catch (error) {
      return WalkDetailResult.failure(_cleanError(error));
    } finally {
      _actionInProgress = false;

      _setState(_state.copyWith(acting: false));
    }
  }

  Future<WalkDetailResult> updateRequestedPets({
    required List<int> petIds,
  }) async {
    if (_actionInProgress) {
      return const WalkDetailResult.failure(
        'Espera a que termine la acción actual.',
        code: WalkDetailResultCode.invalidAction,
      );
    }

    final id = _state.walkId;

    if (id == null || id <= 0) {
      return const WalkDetailResult.failure(
        'No se pudo identificar el paseo.',
        code: WalkDetailResultCode.missingWalk,
      );
    }

    if (!_state.canEditRequestedPets) {
      return const WalkDetailResult.failure(
        'Esta solicitud ya no permite cambiar las mascotas.',
        code: WalkDetailResultCode.invalidAction,
      );
    }

    final cleanIds = petIds
        .where((petId) => petId > 0)
        .toSet()
        .toList(growable: false);

    if (cleanIds.isEmpty) {
      return const WalkDetailResult.failure(
        'Selecciona por lo menos una mascota.',
        code: WalkDetailResultCode.invalidAction,
      );
    }

    if (cleanIds.length > 5) {
      return const WalkDetailResult.failure(
        'Puedes incluir hasta 5 mascotas en el mismo paseo.',
        code: WalkDetailResultCode.invalidAction,
      );
    }

    final currentIds =
        _state.walk?.requestedPets
            .map((pet) => pet.id)
            .where((petId) => petId > 0)
            .toSet() ??
        <int>{};

    final selectedIds = cleanIds.toSet();

    if (currentIds.length == selectedIds.length &&
        currentIds.containsAll(selectedIds)) {
      return const WalkDetailResult.failure(
        'No realizaste ningún cambio en las mascotas.',
        code: WalkDetailResultCode.invalidAction,
      );
    }

    _actionInProgress = true;

    _setState(_state.copyWith(acting: true, clearError: true));

    try {
      final response = await PaseoMascotasService.actualizarMascotas(
        paseoId: id,
        petIds: cleanIds,
      );

      if (response['success'] != true) {
        throw Exception(
          _responseMessage(
            response,
            fallback: 'No se pudieron actualizar las mascotas.',
          ),
        );
      }

      await loadDetail();

      return const WalkDetailResult.success(
        'Las mascotas del paseo fueron actualizadas.',
      );
    } catch (error) {
      return WalkDetailResult.failure(_cleanError(error));
    } finally {
      _actionInProgress = false;

      _setState(_state.copyWith(acting: false));
    }
  }

  Future<WalkDetailResult> respondPetChange({
    required bool accept,
    String reason = '',
  }) async {
    if (_actionInProgress) {
      return const WalkDetailResult.failure(
        'Ya hay una acción en proceso.',
        code: WalkDetailResultCode.invalidAction,
      );
    }

    final id = _state.walkId;

    if (id == null || id <= 0) {
      return const WalkDetailResult.failure(
        'No se pudo identificar el paseo.',
        code: WalkDetailResultCode.missingWalk,
      );
    }

    if (!_state.canRespondPetChange) {
      return const WalkDetailResult.failure(
        'Esta propuesta ya no puede responderse.',
        code: WalkDetailResultCode.invalidAction,
      );
    }

    final cleanReason = reason.trim();

    if (!accept && cleanReason.isNotEmpty && cleanReason.length < 3) {
      return const WalkDetailResult.failure(
        'Escribe un motivo un poco más completo.',
        code: WalkDetailResultCode.invalidAction,
      );
    }

    _actionInProgress = true;

    _setState(_state.copyWith(acting: true, clearError: true));

    try {
      final response = await PaseoMascotasService.responderCambio(
        paseoId: id,
        accept: accept,
        reason: cleanReason,
      );

      if (response['success'] != true) {
        throw Exception(
          _responseMessage(
            response,
            fallback: 'No se pudo responder la propuesta.',
          ),
        );
      }

      await loadDetail();

      return WalkDetailResult.success(
        accept
            ? 'Propuesta aceptada. El paseo quedó confirmado.'
            : 'Propuesta rechazada.',
      );
    } catch (error) {
      return WalkDetailResult.failure(_cleanError(error));
    } finally {
      _actionInProgress = false;

      _setState(_state.copyWith(acting: false));
    }
  }

  WalkDetailResult? _validateAction(
    WalkDetailAction action, {
    required String cancellationReason,
    bool hasPendingStart = false,
    bool hasPendingEndEvidence = false,
  }) {
    switch (action) {
      case WalkDetailAction.accept:
        if (!_state.canAccept) {
          return const WalkDetailResult.failure(
            'Este paseo ya no puede aceptarse.',
            code: WalkDetailResultCode.invalidAction,
          );
        }
        break;

      case WalkDetailAction.reject:
        if (!_state.canReject) {
          return const WalkDetailResult.failure(
            'Este paseo ya no puede rechazarse.',
            code: WalkDetailResultCode.invalidAction,
          );
        }
        break;

      case WalkDetailAction.start:
        if (!_state.canStart) {
          return const WalkDetailResult.failure(
            'Este paseo todavía no puede iniciarse.',
            code: WalkDetailResultCode.invalidAction,
          );
        }
        break;

      case WalkDetailAction.finish:
        if (_state.needsEndEvidence && !hasPendingEndEvidence) {
          return const WalkDetailResult.failure(
            'Antes de finalizar, registra la evidencia final.',
            code: WalkDetailResultCode.finalEvidenceRequired,
          );
        }

        if (!_state.canFinish && !hasPendingStart) {
          return const WalkDetailResult.failure(
            'Este paseo todavía no puede finalizarse.',
            code: WalkDetailResultCode.invalidAction,
          );
        }
        break;

      case WalkDetailAction.cancel:
        if (!_state.canCancel) {
          return const WalkDetailResult.failure(
            'Este paseo ya no puede cancelarse.',
            code: WalkDetailResultCode.invalidAction,
          );
        }

        if (cancellationReason.trim().length < 3) {
          return const WalkDetailResult.failure(
            'Escribe un motivo de cancelación más completo.',
            code: WalkDetailResultCode.cancellationReasonRequired,
          );
        }
        break;
    }

    return null;
  }

  Map<String, dynamic> _normalizeDetail(dynamic value) {
    dynamic data = value;

    if (data is Map) {
      data =
          data['data'] ??
          data['paseo'] ??
          data['detalle'] ??
          data['resultado'] ??
          data['result'] ??
          data['value'] ??
          data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw const FormatException(
      'El detalle del paseo no tiene un formato válido.',
    );
  }

  String _responseMessage(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    dynamic source = response['body'] ?? response;

    if (source is Map) {
      final value = source['message'] ?? source['mensaje'] ?? source['error'];

      final message = value?.toString().trim();

      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    final value =
        response['message'] ?? response['mensaje'] ?? response['error'];

    final message = value?.toString().trim();

    return message == null || message.isEmpty ? fallback : message;
  }

  String _cleanError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '')
        .replaceFirst('FormatException: ', '')
        .trim();

    return message.isEmpty ? 'No se pudo completar la acción.' : message;
  }

  void _setState(WalkDetailState newState) {
    if (_disposed) {
      return;
    }

    _state = newState;
    notifyListeners();
  }

  static int? _extractId(Map<String, dynamic>? map) {
    if (map == null) {
      return null;
    }

    final value = map['id'] ?? map['Id'] ?? map['paseoId'] ?? map['PaseoId'];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
