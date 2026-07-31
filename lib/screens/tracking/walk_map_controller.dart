import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../services/session_service.dart';
import '../../services/tracking_service.dart';
import '../walks/models/walk_detail.dart';
import 'models/tracking_point.dart';
import 'walk_map_state.dart';

class WalkMapController extends ChangeNotifier {
  final TrackingService _service;

  WalkMapState _state;

  Timer? _timer;
  bool _disposed = false;
  bool _loadInProgress = false;

  WalkMapController({
    required Map<String, dynamic> walkData,
    TrackingService? service,
  })  : _service =
            service ?? TrackingService(),
        _state = WalkMapState(
          walk: WalkDetail.fromMap(walkData),
        );

  WalkMapState get state => _state;

  Future<void> initialize() async {
    try {
      final role =
          await SessionService.obtenerRol();

      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          role: role ?? '',
        ),
      );
    } catch (_) {
      // El mapa puede mostrarse aunque no se
      // consiga recuperar el rol.
    }

    await loadRoute();

    if (_disposed) {
      return;
    }

    _timer?.cancel();

    if (_state.walk.isInProgress) {
      _timer = Timer.periodic(
        const Duration(seconds: 10),
        (_) {
          if (!_disposed) {
            loadRoute(silent: true);
          }
        },
      );
    }
  }

  Future<void> refresh() {
    return loadRoute();
  }

  Future<void> loadRoute({
    bool silent = false,
  }) async {
    if (_loadInProgress || _disposed) {
      return;
    }

    if (!_state.shouldLoadTracking) {
      _setState(
        _state.copyWith(
          loading: false,
          refreshing: false,
          route: const [],
          clearLatestPoint: true,
          clearError: true,
        ),
      );
      return;
    }

    final id = _state.walk.id;

    if (id <= 0) {
      _setState(
        _state.copyWith(
          loading: false,
          refreshing: false,
          error:
              'No se pudo identificar el paseo.',
        ),
      );
      return;
    }

    _loadInProgress = true;

    _setState(
      _state.copyWith(
        loading:
            !silent && _state.route.isEmpty,
        refreshing:
            silent || _state.route.isNotEmpty,
        clearError: true,
      ),
    );

    Object? historyError;

    try {
      List<TrackingPoint> route = const [];
      TrackingPoint? latestPoint;

      try {
        final rawHistory =
            await _service
                .obtenerHistorialUbicaciones(id);

        route =
            TrackingPoint.listFrom(rawHistory);
      } catch (error) {
        historyError = error;
      }

      if (route.isNotEmpty) {
        latestPoint = route.last;
      } else {
        try {
          final rawLatest =
              await _service
                  .obtenerUltimaUbicacion(id);

          latestPoint =
              TrackingPoint.fromMap(rawLatest);

          route = [latestPoint];
        } catch (latestError) {
          if (historyError != null) {
            throw historyError;
          }

          throw latestError;
        }
      }

      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          loading: false,
          refreshing: false,
          route: route,
          latestPoint: latestPoint,
          clearError: true,
        ),
      );
    } catch (error) {
      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          loading: false,
          refreshing: false,
          error: _cleanError(error),
        ),
      );
    } finally {
      _loadInProgress = false;
    }
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

    return message.isEmpty
        ? 'No se pudo actualizar el recorrido.'
        : message;
  }

  void _setState(
    WalkMapState newState,
  ) {
    if (_disposed) {
      return;
    }

    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _disposed = true;
    super.dispose();
  }
}