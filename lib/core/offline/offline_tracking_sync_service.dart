import '../../services/tracking_service.dart';
import 'offline_tracking_models.dart';
import 'offline_tracking_repository.dart';

class OfflineTrackingSyncService {
  OfflineTrackingSyncService({
    OfflineTrackingRepository? repository,
    TrackingService? trackingService,
  }) : _repository = repository ?? OfflineTrackingRepository(),
       _trackingService = trackingService ?? TrackingService();

  static final OfflineTrackingSyncService instance =
      OfflineTrackingSyncService();

  final OfflineTrackingRepository _repository;
  final TrackingService _trackingService;

  bool _syncing = false;

  Future<void> initialize() {
    return _repository.recoverInterruptedSyncs();
  }

  Future<OfflineTrackingSyncResult> syncPending({
    int maxBatches = 5,
    int batchSize = 100,
  }) async {
    if (_syncing) {
      return OfflineTrackingSyncResult(
        pending: await _repository.pendingTrackingPointCount(),
        busy: true,
      );
    }

    _syncing = true;

    var synced = 0;
    var rejected = 0;
    Object? lastError;
    var hasIrrecoverable = false;
    final monitoringEvents = <RouteMonitoringEvent>[];

    try {
      for (var batchNumber = 0; batchNumber < maxBatches; batchNumber++) {
        final points = await _repository.claimPendingTrackingPoints(
          limit: batchSize,
        );

        if (points.isEmpty) break;

        final byWalk = <int, List<OfflineTrackingPointRecord>>{};

        for (final point in points) {
          byWalk.putIfAbsent(point.paseoId, () => []).add(point);
        }

        var shouldPause = false;

        for (final entry in byWalk.entries) {
          final ids = entry.value
              .map((point) => point.clientPointId)
              .toList(growable: false);

          try {
            final response = await _trackingService.enviarUbicacionesLote(
              paseoId: entry.key,
              puntos: entry.value
                  .map(
                    (point) => <String, dynamic>{
                      'clientPointId': point.clientPointId,
                      'latitud': point.latitude,
                      'longitud': point.longitude,
                      if (point.accuracy != null)
                        'precisionGpsMetros': point.accuracy,
                      if (point.altitude != null)
                        'altitudMetros': point.altitude,
                      if (point.speed != null)
                        'velocidadMetrosSegundo': point.speed,
                      if (point.heading != null) 'rumboGrados': point.heading,
                      'fechaCaptura': point.capturedAt
                          .toUtc()
                          .toIso8601String(),
                    },
                  )
                  .toList(growable: false),
            );

            monitoringEvents.addAll(
              _readMonitoringEvents(response, paseoId: entry.key),
            );

            final acceptedIds = _readIds(response, 'aceptadas');
            final duplicateIds = _readIds(response, 'duplicadas');
            final confirmedIds = <String>{...acceptedIds, ...duplicateIds};

            if (confirmedIds.isNotEmpty) {
              await _repository.markTrackingPointsSynced(
                confirmedIds.toList(growable: false),
              );
              synced += confirmedIds.length;
            }

            final rejectedItems = _readItems(response, 'rechazadas');
            final rejectedIds = <String>{};

            for (final item in rejectedItems) {
              final id = item['clientPointId']?.toString().trim() ?? '';
              if (id.isEmpty) continue;

              rejectedIds.add(id);
              final reason =
                  item['motivo']?.toString().trim() ??
                  'La API rechazó la coordenada.';

              await _repository.markTrackingPointsFailed([id], reason);
            }

            rejected += rejectedIds.length;

            final unresolvedIds = ids
                .where(
                  (id) =>
                      !confirmedIds.contains(id) && !rejectedIds.contains(id),
                )
                .toList(growable: false);

            if (unresolvedIds.isNotEmpty) {
              const message =
                  'La API no confirmó algunas coordenadas del lote.';
              await _repository.markTrackingPointsFailed(
                unresolvedIds,
                message,
              );
              rejected += unresolvedIds.length;
              lastError = message;
            }

            if (rejectedIds.isNotEmpty || unresolvedIds.isNotEmpty) {
              shouldPause = true;
            }
          } catch (error) {
            await _repository.markTrackingPointsFailed(ids, error);
            lastError = error;
            hasIrrecoverable = _isPermanent(error);
            shouldPause = true;
          }
        }

        if (shouldPause) break;
      }

      return OfflineTrackingSyncResult(
        synced: synced,
        rejected: rejected,
        pending: await _repository.pendingTrackingPointCount(),
        lastError: lastError,
        hasIrrecoverable: hasIrrecoverable,
        monitoringEvents: monitoringEvents,
      );
    } finally {
      _syncing = false;
    }
  }

  bool _isPermanent(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('código: 400') ||
        message.contains('código: 403') ||
        message.contains('paseo no encontrado') ||
        message.contains('solo se puede enviar ubicación') ||
        message.contains('solo el paseador asignado');
  }

  List<Map<String, dynamic>> _readItems(
    Map<String, dynamic> response,
    String key,
  ) {
    final value = response[key] ?? response[_capitalize(key)];

    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Set<String> _readIds(Map<String, dynamic> response, String key) {
    return _readItems(response, key)
        .map((item) => item['clientPointId'])
        .whereType<Object>()
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  List<RouteMonitoringEvent> _readMonitoringEvents(
    Map<String, dynamic> response, {
    required int paseoId,
  }) {
    final raw = response['monitoreoRuta'];
    final items = raw is List ? raw : <dynamic>[?raw];
    final events = <RouteMonitoringEvent>[];

    for (final item in items.whereType<Map>()) {
      final wrapper = Map<String, dynamic>.from(item);
      final resultRaw = wrapper['resultado'] ?? wrapper;
      if (resultRaw is! Map) continue;

      final result = Map<String, dynamic>.from(resultRaw);
      final event = RouteMonitoringEvent.fromMap(paseoId: paseoId, map: result);

      if (event.routeActive) events.add(event);
    }

    return events;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class OfflineTrackingSyncResult {
  const OfflineTrackingSyncResult({
    this.synced = 0,
    this.rejected = 0,
    this.pending = 0,
    this.busy = false,
    this.lastError,
    this.monitoringEvents = const <RouteMonitoringEvent>[],
    this.hasIrrecoverable = false,
  });

  final int synced;
  final int rejected;
  final int pending;
  final bool busy;
  final Object? lastError;
  final List<RouteMonitoringEvent> monitoringEvents;
  final bool hasIrrecoverable;

  bool get completed => pending == 0 && lastError == null;
}

class RouteMonitoringEvent {
  const RouteMonitoringEvent({
    required this.paseoId,
    required this.routeActive,
    required this.locationProcessed,
    required this.insideZone,
    required this.outsideRoute,
    required this.alertGenerated,
    required this.reentryDetected,
    required this.checkpointsReached,
    required this.message,
    this.distanceRouteMeters,
    this.allowedRadiusMeters,
  });

  final int paseoId;
  final bool routeActive;
  final bool locationProcessed;
  final bool insideZone;
  final bool outsideRoute;
  final bool alertGenerated;
  final bool reentryDetected;
  final List<String> checkpointsReached;
  final String message;
  final double? distanceRouteMeters;
  final double? allowedRadiusMeters;

  bool get hasCheckpoint => checkpointsReached.isNotEmpty;
  bool get significant => alertGenerated || reentryDetected || hasCheckpoint;

  factory RouteMonitoringEvent.fromMap({
    required int paseoId,
    required Map<String, dynamic> map,
  }) {
    return RouteMonitoringEvent(
      paseoId: paseoId,
      routeActive: _bool(map, 'rutaActiva'),
      locationProcessed: _bool(map, 'ubicacionProcesada'),
      insideZone: _bool(map, 'dentroDeZona', fallback: true),
      outsideRoute: _bool(map, 'fueraDeRuta'),
      alertGenerated: _bool(map, 'alertaGenerada'),
      reentryDetected: _bool(map, 'reingresoDetectado'),
      distanceRouteMeters: _double(map, 'distanciaRutaMetros'),
      allowedRadiusMeters: _double(map, 'radioPermitidoMetros'),
      checkpointsReached: _strings(map, 'checkpointsAlcanzados'),
      message: _value(map, 'mensaje')?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'paseoId': paseoId,
      'rutaActiva': routeActive,
      'ubicacionProcesada': locationProcessed,
      'dentroDeZona': insideZone,
      'fueraDeRuta': outsideRoute,
      'alertaGenerada': alertGenerated,
      'reingresoDetectado': reentryDetected,
      'distanciaRutaMetros': distanceRouteMeters,
      'radioPermitidoMetros': allowedRadiusMeters,
      'checkpointsAlcanzados': checkpointsReached,
      'mensaje': message,
      'fecha': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static Object? _value(Map<String, dynamic> map, String key) {
    return map[key] ?? map['${key[0].toUpperCase()}${key.substring(1)}'];
  }

  static bool _bool(
    Map<String, dynamic> map,
    String key, {
    bool fallback = false,
  }) {
    final value = _value(map, key);
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  static double? _double(Map<String, dynamic> map, String key) {
    final value = _value(map, key);
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static List<String> _strings(Map<String, dynamic> map, String key) {
    final value = _value(map, key);
    if (value is! List) return const <String>[];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
