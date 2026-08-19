import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../services/background_tracking_service.dart';
import '../../services/location_service.dart';
import '../../services/storage_service.dart';
import '../../services/tracking_service.dart';
import 'live_tracking_state.dart';
import 'models/tracking_session.dart';

class LiveTrackingResult {
  final bool success;
  final String message;

  const LiveTrackingResult({required this.success, required this.message});

  const LiveTrackingResult.success(this.message) : success = true;

  const LiveTrackingResult.failure(this.message) : success = false;
}

class LiveTrackingController extends ChangeNotifier {
  final LocationService _locationService;
  final TrackingService _trackingService;

  LiveTrackingState _state;

  Timer? _statusTimer;
  StreamSubscription<Map<String, dynamic>?>? _routeStatusSubscription;
  bool _disposed = false;
  bool _syncInProgress = false;
  bool _actionInProgress = false;
  String? _lastObservedSendKey;

  LiveTrackingController({
    required int walkId,
    required String petName,
    required String walkerName,
    LocationService? locationService,
    TrackingService? trackingService,
  }) : _locationService = locationService ?? LocationService(),
       _trackingService = trackingService ?? TrackingService(),
       _state = LiveTrackingState(
         walkId: walkId,
         petName: petName,
         walkerName: walkerName,
       );

  LiveTrackingState get state => _state;

  Future<void> initialize() async {
    _routeStatusSubscription ??= BackgroundTrackingService.cambiosEstadoRuta
        .listen((event) {
          if (event != null && !_disposed) {
            _applyRouteStatus(event);
          }
        });

    await syncStatus();

    if (_disposed) {
      return;
    }

    _statusTimer?.cancel();

    _statusTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_disposed && !_state.processing) {
        syncStatus(silent: true);
      }
    });
  }

  Future<void> syncStatus({bool silent = false}) async {
    if (_syncInProgress || _disposed) {
      return;
    }

    _syncInProgress = true;

    if (!silent) {
      _setState(_state.copyWith(loading: true, clearError: true));
    }

    try {
      final results = await Future.wait<dynamic>([
        StorageService.obtenerTrackingActivo(),
        BackgroundTrackingService.estaCorriendo(),
        BackgroundTrackingService.obtenerEstadoRuta(),
      ]);

      if (_disposed) {
        return;
      }

      final rawSession = results[0];
      final serviceRunning = results[1] == true;

      TrackingSession? session;

      if (rawSession is Map) {
        session = TrackingSession.fromMap(
          Map<String, dynamic>.from(rawSession),
        );
      }

      var updates = _state.successfulUpdates;

      final sendKey = session?.stableSendKey ?? '';

      if (_lastObservedSendKey == null) {
        _lastObservedSendKey = sendKey;
      } else if (sendKey.isNotEmpty &&
          sendKey != _lastObservedSendKey &&
          session?.walkId == _state.walkId) {
        updates++;
        _lastObservedSendKey = sendKey;
      }

      _setState(
        _state.copyWith(
          loading: false,
          serviceRunning: serviceRunning,
          session: session,
          clearSession: session == null,
          successfulUpdates: updates,
          clearError: true,
        ),
      );

      final routeStatus = results[2];
      if (routeStatus is Map) {
        _applyRouteStatus(Map<String, dynamic>.from(routeStatus));
      }
    } catch (error) {
      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          loading: false,
          error: silent ? _state.error : _cleanError(error),
        ),
      );
    } finally {
      _syncInProgress = false;
    }
  }

  Future<LiveTrackingResult> activateBackgroundTracking() async {
    if (_actionInProgress) {
      return const LiveTrackingResult.failure('Ya hay una acción en proceso.');
    }

    if (_state.isCurrentWalkActive) {
      return const LiveTrackingResult.failure('La ubicación ya está activa.');
    }

    if (_state.anotherWalkIsActive) {
      return const LiveTrackingResult.failure(
        'Hay otro paseo compartiendo ubicación. Detén ese seguimiento antes de continuar.',
      );
    }

    _actionInProgress = true;

    _setState(_state.copyWith(processing: true, clearError: true));

    try {
      await _locationService.pedirPermisoUbicacion();

      final started = await BackgroundTrackingService.iniciarTracking(
        paseoId: _state.walkId,
        nombrePerro: _state.petName,
        nombrePaseador: _state.walkerName,
      );

      if (!started) {
        return const LiveTrackingResult.failure(
          'No se pudo iniciar el servicio de ubicación.',
        );
      }

      _setState(_state.copyWith(changed: true));

      await Future.delayed(const Duration(milliseconds: 900));

      await syncStatus(silent: true);

      return const LiveTrackingResult.success('Ubicación en vivo activada.');
    } catch (error) {
      final message = _cleanError(error);

      _setState(_state.copyWith(error: message));

      return LiveTrackingResult.failure(message);
    } finally {
      _actionInProgress = false;

      _setState(_state.copyWith(processing: false));
    }
  }

  Future<LiveTrackingResult> pauseBackgroundTracking() async {
    if (_actionInProgress) {
      return const LiveTrackingResult.failure('Ya hay una acción en proceso.');
    }

    if (!_state.isCurrentWalkActive && !_state.serviceRunning) {
      return const LiveTrackingResult.failure('La ubicación ya está pausada.');
    }

    _actionInProgress = true;

    _setState(_state.copyWith(processing: true, clearError: true));

    try {
      await BackgroundTrackingService.detenerTracking();

      _setState(
        _state.copyWith(
          changed: true,
          serviceRunning: false,
          clearSession: true,
        ),
      );

      await syncStatus(silent: true);

      return const LiveTrackingResult.success('Ubicación en vivo pausada.');
    } catch (error) {
      final message = _cleanError(error);

      _setState(_state.copyWith(error: message));

      return LiveTrackingResult.failure(message);
    } finally {
      _actionInProgress = false;

      _setState(_state.copyWith(processing: false));
    }
  }

  Future<LiveTrackingResult> sendCurrentLocation() async {
    if (_actionInProgress) {
      return const LiveTrackingResult.failure('Ya hay una acción en proceso.');
    }

    _actionInProgress = true;

    _setState(_state.copyWith(processing: true, clearError: true));

    try {
      final position = await _locationService.obtenerUbicacionActual();

      final response = await _trackingService.enviarUbicacion(
        paseoId: _state.walkId,
        latitud: position.latitude,
        longitud: position.longitude,
        precisionGpsMetros: position.accuracy,
        fechaLectura: position.timestamp,
      );

      final monitoring = response['monitoreoRuta'] ?? response['MonitoreoRuta'];
      if (monitoring is Map) {
        _applyRouteStatus(Map<String, dynamic>.from(monitoring));
      }

      final sentAt = DateTime.now();

      await StorageService.guardarUltimaUbicacionTracking(
        latitud: position.latitude,
        longitud: position.longitude,
        fecha: sentAt,
      );

      final currentSession = _state.session;

      final session = TrackingSession(
        active: currentSession?.active ?? false,
        walkId: _state.walkId,
        petName: _state.petName,
        walkerName: _state.walkerName,
        latitude: position.latitude,
        longitude: position.longitude,
        lastSentAt: sentAt,
      );

      _lastObservedSendKey = session.stableSendKey;

      _setState(
        _state.copyWith(
          changed: true,
          session: session,
          successfulUpdates: _state.successfulUpdates + 1,
          accuracy: position.accuracy,
          speed: position.speed,
          altitude: position.altitude,
        ),
      );

      return const LiveTrackingResult.success(
        'Ubicación actualizada correctamente.',
      );
    } catch (error) {
      final message = _cleanError(error);

      _setState(_state.copyWith(error: message));

      return LiveTrackingResult.failure(message);
    } finally {
      _actionInProgress = false;

      _setState(_state.copyWith(processing: false));
    }
  }

  bool get shouldReturnUpdated {
    return _state.changed || _state.isCurrentWalkActive;
  }

  void _applyRouteStatus(Map<String, dynamic> map) {
    final paseoId = _integer(map, 'paseoId');
    if (paseoId != null && paseoId != _state.walkId) return;

    final checkpointsRaw = _value(map, 'checkpointsAlcanzados');
    final checkpoints = checkpointsRaw is List
        ? checkpointsRaw
              .map((item) => item?.toString().trim() ?? '')
              .where((item) => item.isNotEmpty)
              .toList(growable: false)
        : const <String>[];
    final dateValue = _value(map, 'fecha')?.toString();

    _setState(
      _state.copyWith(
        routeMonitoringActive: _boolean(map, 'rutaActiva'),
        outsideRoute: _boolean(map, 'fueraDeRuta'),
        reentryDetected: _boolean(map, 'reingresoDetectado'),
        distanceRouteMeters: _number(map, 'distanciaRutaMetros'),
        clearDistanceRoute: _number(map, 'distanciaRutaMetros') == null,
        allowedRadiusMeters: _number(map, 'radioPermitidoMetros'),
        clearAllowedRadius: _number(map, 'radioPermitidoMetros') == null,
        checkpointsReached: checkpoints,
        routeMessage: _value(map, 'mensaje')?.toString(),
        clearRouteMessage: _value(map, 'mensaje') == null,
        routeUpdatedAt: DateTime.tryParse(dateValue ?? '') ?? DateTime.now(),
      ),
    );
  }

  Object? _value(Map<String, dynamic> map, String key) {
    return map[key] ?? map['${key[0].toUpperCase()}${key.substring(1)}'];
  }

  bool _boolean(Map<String, dynamic> map, String key) {
    final value = _value(map, key);
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value?.toString().toLowerCase() == 'true';
  }

  double? _number(Map<String, dynamic> map, String key) {
    final value = _value(map, key);
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  int? _integer(Map<String, dynamic> map, String key) {
    final value = _value(map, key);
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
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

    return message.isEmpty ? 'No se pudo actualizar la ubicación.' : message;
  }

  void _setState(LiveTrackingState newState) {
    if (_disposed) {
      return;
    }

    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _routeStatusSubscription?.cancel();
    _disposed = true;
    super.dispose();
  }
}
