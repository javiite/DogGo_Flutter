import '../../routes/models/doggo_route.dart';

class WalkRouteSelection {
  final SavedDoggoRoute? savedRoute;
  final DoggoRouteDraft? customRoute;
  final bool saveAsTemplate;
  final String? templateName;

  const WalkRouteSelection.saved(
    SavedDoggoRoute route,
  )   : savedRoute = route,
        customRoute = null,
        saveAsTemplate = false,
        templateName = null;

  const WalkRouteSelection.custom({
    required DoggoRouteDraft route,
    this.saveAsTemplate = false,
    this.templateName,
  })  : savedRoute = null,
        customRoute = route;

  bool get usesSavedRoute {
    return savedRoute != null;
  }

  bool get usesCustomRoute {
    return customRoute != null;
  }

  String get name {
    return savedRoute?.name ??
        customRoute?.name ??
        'Sin recorrido';
  }

  String get controlMode {
    return savedRoute?.controlMode ??
        customRoute?.controlMode ??
        'Ruta';
  }

  int get allowedRadiusMeters {
    return savedRoute?.allowedRadiusMeters ??
        customRoute?.allowedRadiusMeters ??
        100;
  }

  int get pointCount {
    return savedRoute?.points.length ??
        customRoute?.points.length ??
        0;
  }

  int get checkpointCount {
    final points = savedRoute?.points ??
        customRoute?.points ??
        const [];

    return points
        .where((point) => point.isCheckpoint)
        .length;
  }
}