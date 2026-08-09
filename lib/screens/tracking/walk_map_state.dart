import 'package:latlong2/latlong.dart';

import '../routes/models/doggo_route.dart';
import '../walks/models/walk_detail.dart';
import 'models/tracking_point.dart';

class WalkMapState {
  final WalkDetail walk;
  final String role;
  final bool loading;
  final bool refreshing;
  final String? error;

  // Ruta realmente recorrida por GPS.
  final List<TrackingPoint> route;
  final TrackingPoint? latestPoint;

  // Ruta planeada por el dueño.
  final PlannedDoggoRoute? plannedRoute;

  const WalkMapState({
    required this.walk,
    this.role = '',
    this.loading = true,
    this.refreshing = false,
    this.error,
    this.route = const [],
    this.latestPoint,
    this.plannedRoute,
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

  bool get hasPlannedRoute {
    return plannedRoute != null &&
        plannedPathLatLng.isNotEmpty;
  }

  bool get hasAnyRoute {
    return hasRoute || hasPlannedRoute;
  }

  bool get outsidePlannedRoute {
    return plannedRoute?.outsideRoute ??
        false;
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

  List<LatLng> get plannedPathLatLng {
    final planned = plannedRoute;

    if (planned == null) {
      return const [];
    }

    return planned.pathPoints
        .map((point) => point.position)
        .toList(growable: false);
  }

  List<DoggoRoutePoint>
      get plannedCheckpoints {
    return plannedRoute?.checkpoints ??
        const [];
  }

  bool get plannedRouteIsArea {
    return plannedRoute?.isArea ?? false;
  }

  int get plannedAllowedRadius {
    return plannedRoute
            ?.allowedRadiusMeters ??
        0;
  }

  String get plannedRouteName {
    return plannedRoute?.name ??
        'Ruta planificada';
  }

  LatLng get initialCenter {
    final current = currentLatLng;

    if (current != null) {
      return current;
    }

    final planned = plannedPathLatLng;

    if (planned.isNotEmpty) {
      return planned.first;
    }

    final pickup = pickupPoint;

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
      return 'Sin GPS';
    }

    if (route.length == 1) {
      return '1 punto GPS';
    }

    return '${route.length} puntos GPS';
  }

  String get plannedRouteLabel {
    final planned = plannedRoute;

    if (planned == null) {
      return 'Sin ruta planeada';
    }

    final pathCount =
        planned.pathPoints.length;

    final checkpointCount =
        planned.checkpoints.length;

    return '$pathCount puntos · '
        '$checkpointCount avisos';
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
    if (outsidePlannedRoute) {
      return 'El paseador se encuentra fuera '
          'del recorrido permitido.';
    }

    if (walk.isPending) {
      return hasPlannedRoute
          ? 'La ruta está lista. El GPS se '
              'activará cuando comience el paseo.'
          : 'El mapa estará disponible cuando '
              'el paseo sea aceptado e iniciado.';
    }

    if (walk.isAccepted) {
      return hasPlannedRoute
          ? 'Recorrido preparado. La ubicación '
              'en vivo aparecerá al iniciar.'
          : 'La ubicación en vivo se activará '
              'cuando el paseador inicie el servicio.';
    }

    if (walk.isCancelled ||
        walk.isRejected) {
      return 'El seguimiento no está disponible '
          'porque el paseo fue cerrado.';
    }

    if (walk.isCompleted) {
      return hasRoute
          ? 'Se muestra el recorrido GPS '
              'realizado durante el paseo.'
          : 'El paseo finalizó sin una ruta '
              'GPS disponible.';
    }

    if (walk.isInProgress) {
      if (!hasCurrentPosition) {
        return hasPlannedRoute
            ? 'La ruta está preparada, pero '
                'todavía no se recibe ubicación GPS.'
            : 'El paseo está activo, pero todavía '
                'no se ha recibido una ubicación.';
      }

      return locationIsRecent
          ? 'La posición se está actualizando '
              'en tiempo real.'
          : 'La última posición puede estar '
              'desactualizada.';
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
    PlannedDoggoRoute? plannedRoute,
    bool clearPlannedRoute = false,
  }) {
    return WalkMapState(
      walk: walk ?? this.walk,
      role: role ?? this.role,
      loading: loading ?? this.loading,
      refreshing:
          refreshing ?? this.refreshing,
      error: clearError
          ? null
          : error ?? this.error,
      route: route ?? this.route,
      latestPoint: clearLatestPoint
          ? null
          : latestPoint ??
              this.latestPoint,
      plannedRoute: clearPlannedRoute
          ? null
          : plannedRoute ??
              this.plannedRoute,
    );
  }

  static String _normalizeRole(
    String value,
  ) {
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
        .replaceAll(
          RegExp(r'[\s_\-]'),
          '',
        );
  }
}