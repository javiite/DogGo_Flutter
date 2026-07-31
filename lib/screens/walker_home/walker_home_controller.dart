import 'package:flutter/foundation.dart';

import '../../services/paseadores_service.dart';
import '../../services/paseos_service.dart';
import '../../services/storage_service.dart';
import '../home/home_state.dart';
import '../home/models/home_walk.dart';
import '../home/models/home_walk_status.dart';
import 'models/walker_home_profile.dart';
import 'walker_home_state.dart';

enum WalkerHomeResultCode {
  success,
  invalidWalk,
  unavailableProfile,
  failed,
}

class WalkerHomeResult {
  final bool success;
  final String message;
  final WalkerHomeResultCode code;

  const WalkerHomeResult({
    required this.success,
    required this.message,
    required this.code,
  });

  const WalkerHomeResult.success(
    this.message,
  )   : success = true,
        code = WalkerHomeResultCode.success;

  const WalkerHomeResult.failure(
    this.message, {
    this.code = WalkerHomeResultCode.failed,
  }) : success = false;
}

class WalkerHomeController
    extends ChangeNotifier {
  WalkerHomeState _state =
      const WalkerHomeState();

  bool _disposed = false;
  bool _initialized = false;
  bool _refreshInProgress = false;

  WalkerHomeState get state => _state;

  Future<void> initialize() async {
    if (_initialized || _disposed) {
      return;
    }

    _initialized = true;

    _setState(
      _state.copyWith(
        initialLoading: true,
        clearError: true,
        clearMessage: true,
      ),
    );

    try {
      final baseUrl =
          await StorageService.obtenerBaseUrl();

      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          baseUrl: baseUrl,
        ),
      );

      await Future.wait([
        loadProfile(),
        loadWalks(),
      ]);
    } finally {
      if (!_disposed) {
        _setState(
          _state.copyWith(
            initialLoading: false,
          ),
        );
      }
    }
  }

  Future<void> refresh() async {
    if (_refreshInProgress ||
        _disposed) {
      return;
    }

    _refreshInProgress = true;

    _setState(
      _state.copyWith(
        refreshing: true,
        clearError: true,
        clearMessage: true,
      ),
    );

    try {
      await Future.wait([
        loadProfile(),
        loadWalks(),
      ]);
    } finally {
      _refreshInProgress = false;

      if (!_disposed) {
        _setState(
          _state.copyWith(
            refreshing: false,
          ),
        );
      }
    }
  }

  Future<void> loadProfile() async {
    if (_disposed) {
      return;
    }

    _setState(
      _state.copyWith(
        profileLoading: true,
        clearError: true,
      ),
    );

    try {
      final response =
          await PaseadoresService
              .obtenerMiPerfilPaseador();

      if (_disposed) {
        return;
      }

      final profile =
          WalkerHomeProfile.fromMap(
        response,
        baseUrl: _state.baseUrl,
      );

      _setState(
        _state.copyWith(
          profileLoading: false,
          profile: profile,
          clearError: true,
        ),
      );
    } catch (error) {
      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          profileLoading: false,
          error: _cleanError(
            error,
            fallback:
                'No se pudo cargar tu perfil de paseador.',
          ),
        ),
      );
    }
  }

  Future<void> loadWalks() async {
    if (_disposed) {
      return;
    }

    _setState(
      _state.copyWith(
        walksLoading: true,
        clearError: true,
      ),
    );

    try {
      final response =
          await PaseosService
              .obtenerMisPaseos();

      if (_disposed) {
        return;
      }

      if (response['success'] != true) {
        throw Exception(
          response['message'] ??
              'No se pudieron cargar los paseos.',
        );
      }

      final maps =
          HomeState.normalizeMapList(
        response['data'],
        possibleKeys: const [
          'items',
          'paseos',
          'data',
          'result',
          'resultado',
        ],
      );

      final walks = maps
          .map(
            (map) => HomeWalk.fromMap(
              map,
              baseUrl: _state.baseUrl,
            ),
          )
          .toList();

      _setState(
        _state.copyWith(
          walksLoading: false,
          walks: walks,
          clearError: true,
        ),
      );
    } catch (error) {
      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          walksLoading: false,
          error: _cleanError(
            error,
            fallback:
                'No se pudieron cargar tus paseos.',
          ),
        ),
      );
    }
  }

  Future<WalkerHomeResult>
      setAvailability(
    bool available,
  ) async {
    if (_state.availabilitySaving) {
      return const WalkerHomeResult.failure(
        'La disponibilidad ya se está actualizando.',
      );
    }

    final profile = _state.profile;

    if (profile == null) {
      return const WalkerHomeResult.failure(
        'Primero debes cargar tu perfil de paseador.',
        code: WalkerHomeResultCode
            .unavailableProfile,
      );
    }

    if (profile.available == available) {
      return WalkerHomeResult.success(
        available
            ? 'Ya apareces como disponible.'
            : 'Tu disponibilidad ya está desactivada.',
      );
    }

    _setState(
      _state.copyWith(
        availabilitySaving: true,
        clearError: true,
        clearMessage: true,
      ),
    );

    try {
      await PaseadoresService
          .guardarMiPerfilPaseador(
        descripcion: profile.description,
        zonaServicio: profile.serviceZone,
        tarifaPorHora:
            profile.hourlyRate,
        experienciaAnios:
            profile.experienceYears,
        disponible: available,
      );

      if (_disposed) {
        return const WalkerHomeResult.failure(
          'La pantalla ya no está disponible.',
        );
      }

      final updated = profile.copyWith(
        available: available,
      );

      final message = available
          ? 'Ahora apareces como disponible para recibir solicitudes.'
          : 'Tu disponibilidad quedó desactivada.';

      _setState(
        _state.copyWith(
          availabilitySaving: false,
          profile: updated,
          message: message,
          clearError: true,
        ),
      );

      return WalkerHomeResult.success(
        message,
      );
    } catch (error) {
      final message = _cleanError(
        error,
        fallback:
            'No se pudo actualizar tu disponibilidad.',
      );

      if (!_disposed) {
        _setState(
          _state.copyWith(
            availabilitySaving: false,
            error: message,
          ),
        );
      }

      return WalkerHomeResult.failure(
        message,
      );
    } finally {
      if (!_disposed &&
          _state.availabilitySaving) {
        _setState(
          _state.copyWith(
            availabilitySaving: false,
          ),
        );
      }
    }
  }

  Future<WalkerHomeResult>
      acceptRequest(
    HomeWalk walk,
  ) async {
    return _respondToRequest(
      walk,
      accept: true,
    );
  }

  Future<WalkerHomeResult>
      rejectRequest(
    HomeWalk walk,
  ) async {
    return _respondToRequest(
      walk,
      accept: false,
    );
  }

  Future<WalkerHomeResult>
      _respondToRequest(
    HomeWalk walk, {
    required bool accept,
  }) async {
    final id = walk.id;

    if (id == null || id <= 0) {
      return const WalkerHomeResult.failure(
        'No se encontró el identificador del paseo.',
        code:
            WalkerHomeResultCode.invalidWalk,
      );
    }

    if (walk.status !=
        HomeWalkStatus.pending) {
      return const WalkerHomeResult.failure(
        'Esta solicitud ya cambió de estado.',
        code:
            WalkerHomeResultCode.invalidWalk,
      );
    }

    if (_state.actingWalkId != null) {
      return const WalkerHomeResult.failure(
        'Ya se está procesando otra solicitud.',
      );
    }

    _setState(
      _state.copyWith(
        actingWalkId: id,
        clearError: true,
        clearMessage: true,
      ),
    );

    try {
      final response = accept
          ? await PaseosService
              .aceptarPaseo(id)
          : await PaseosService
              .rechazarPaseo(id);

      if (response['success'] != true) {
        throw Exception(
          response['message'] ??
              'No se pudo completar la acción.',
        );
      }

      if (_disposed) {
        return const WalkerHomeResult.failure(
          'La pantalla ya no está disponible.',
        );
      }

      final message =
          response['message']
                  ?.toString()
                  .trim()
                  .isNotEmpty ==
              true
          ? response['message'].toString()
          : accept
              ? 'Paseo aceptado correctamente.'
              : 'Solicitud rechazada.';

      _setState(
        _state.copyWith(
          clearActingWalk: true,
          message: message,
          clearError: true,
        ),
      );

      await loadWalks();

      return WalkerHomeResult.success(
        message,
      );
    } catch (error) {
      final message = _cleanError(
        error,
        fallback: accept
            ? 'No se pudo aceptar el paseo.'
            : 'No se pudo rechazar la solicitud.',
      );

      if (!_disposed) {
        _setState(
          _state.copyWith(
            clearActingWalk: true,
            error: message,
          ),
        );
      }

      return WalkerHomeResult.failure(
        message,
      );
    } finally {
      if (!_disposed &&
          _state.actingWalkId != null) {
        _setState(
          _state.copyWith(
            clearActingWalk: true,
          ),
        );
      }
    }
  }

  void clearFeedback() {
    if (_state.error == null &&
        _state.message == null) {
      return;
    }

    _setState(
      _state.copyWith(
        clearError: true,
        clearMessage: true,
      ),
    );
  }

  String _cleanError(
    Object error, {
    required String fallback,
  }) {
    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '')
        .trim();

    return message.isEmpty
        ? fallback
        : message;
  }

  void _setState(
    WalkerHomeState newState,
  ) {
    if (_disposed) {
      return;
    }

    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}