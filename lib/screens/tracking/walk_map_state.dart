import 'package:latlong2/latlong.dart';

import '../walks/models/walk_detail.dart';
import 'models/tracking_point.dart';

class WalkMapState {
  final WalkDetail walk;
  final String role;
  final bool loading;
  final bool refreshing;
  final String? error;
  final List<TrackingPoint> route;
  final TrackingPoint? latestPoint;

  const WalkMapState({
    required this.walk,
    this.role = '',
    this.loading = true,
    this.refreshing = false,
    this.error,
    this.route = const [],
    this.latestPoint,
  });

  bool get isWalker {
    final value = _normalizeRole(role);

    return value == 'paseador' ||
        value == 'walker' ||
        value == 'dogwalker';
  }

  bool get shouldLoadTracking {
    return walk.isInProgress ||
        walk.isCompleted;
  }

  bool get canOpenTracking {
    return isWalker &&
        walk.isInProgress &&
        walk.hasValidId;
  }

  bool get hasRoute {
    return route.isNotEmpty;
  }

  bool get hasCurrentPosition {
    return currentPoint != null;
  }

  TrackingPoint? get currentPoint {
    if (latestPoint != null) {
      return latestPoint;
    }

    if (route.isEmpty) {
      return null;
    }

    return route.last;
  }

  LatLng? get pickupPoint {
    if (!walk.hasPickupCoordinates) {
      return null;
    }

    return LatLng(
      walk.pickupLatitude!,
      walk.pickupLongitude!,
    );
  }

  LatLng? get currentLatLng {
    final point = currentPoint;

    if (point == null) {
      return null;
    }

    return LatLng(
      point.latitude,
      point.longitude,
    );
  }

  List<LatLng> get routeLatLng {
    return route
        .map(
          (point) => LatLng(
            point.latitude,
            point.longitude,
          ),
        )
        .toList(growable: false);
  }

  LatLng get initialCenter {
    final current = currentLatLng;
    final pickup = pickupPoint;

    if (current != null) {
      return current;
    }

    if (pickup != null) {
      return pickup;
    }

    return const LatLng(
      25.6866,
      -100.3161,
    );
  }

  double get distanceKilometers {
    if (route.length < 2) {
      return 0;
    }

    const distance = Distance();
    var meters = 0.0;

    for (var index = 1;
        index < route.length;
        index++) {
      final previous = route[index - 1];
      final current = route[index];

      final segment = distance.as(
        LengthUnit.Meter,
        LatLng(
          previous.latitude,
          previous.longitude,
        ),
        LatLng(
          current.latitude,
          current.longitude,
        ),
      );

      if (segment.isFinite &&
          segment >= 0 &&
          segment < 10000) {
        meters += segment;
      }
    }

    return meters / 1000;
  }

  String get distanceLabel {
    final distance = distanceKilometers;

    if (distance <= 0) {
      return '0 km';
    }

    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }

    return '${distance.toStringAsFixed(2)} km';
  }

  String get routePointsLabel {
    if (route.isEmpty) {
      return 'Sin puntos';
    }

    if (route.length == 1) {
      return '1 punto';
    }

    return '${route.length} puntos';
  }

  String get lastUpdateLabel {
    final date =
        currentPoint?.recordedAt?.toLocal();

    if (date == null) {
      return 'Sin actualización';
    }

    final difference =
        DateTime.now().difference(date);

    if (difference.isNegative ||
        difference.inSeconds < 15) {
      return 'Ahora';
    }

    if (difference.inMinutes < 1) {
      return 'Hace ${difference.inSeconds} s';
    }

    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    }

    if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    }

    return currentPoint!.fullDateLabel;
  }

  bool get locationIsRecent {
    final date = currentPoint?.recordedAt;

    if (date == null) {
      return false;
    }

    return DateTime.now()
            .difference(date)
            .inMinutes <
        2;
  }

  String get statusMessage {
    if (walk.isPending) {
      return 'El mapa estará disponible cuando el paseo sea aceptado e iniciado.';
    }

    if (walk.isAccepted) {
      return 'La ubicación en vivo se activará cuando el paseador inicie el servicio.';
    }

    if (walk.isCancelled ||
        walk.isRejected) {
      return 'El seguimiento no está disponible porque el paseo fue cerrado.';
    }

    if (walk.isCompleted) {
      return hasRoute
          ? 'Se muestra la ruta registrada durante el paseo.'
          : 'El paseo finalizó sin una ruta GPS disponible.';
    }

    if (walk.isInProgress) {
      if (!hasCurrentPosition) {
        return 'El paseo está activo, pero todavía no se ha recibido una ubicación.';
      }

      return locationIsRecent
          ? 'La posición se está actualizando en tiempo real.'
          : 'La última posición puede estar desactualizada.';
    }

    return 'Seguimiento no disponible.';
  }

  WalkMapState copyWith({
    WalkDetail? walk,
    String? role,
    bool? loading,
    bool? refreshing,
    String? error,
    bool clearError = false,
    List<TrackingPoint>? route,
    TrackingPoint? latestPoint,
    bool clearLatestPoint = false,
  }) {
    return WalkMapState(
      walk: walk ?? this.walk,
      role: role ?? this.role,
      loading: loading ?? this.loading,
      refreshing:
          refreshing ?? this.refreshing,
      error:
          clearError ? null : error ?? this.error,
      route: route ?? this.route,
      latestPoint: clearLatestPoint
          ? null
          : latestPoint ?? this.latestPoint,
    );
  }

  static String _normalizeRole(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[\s_\-]'), '');
  }
}