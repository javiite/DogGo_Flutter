import 'package:latlong2/latlong.dart';

abstract final class WalkMapViewport {
  static List<LatLng> visiblePoints({
    Iterable<LatLng> plannedPath = const [],
    Iterable<LatLng> checkpoints = const [],
    Iterable<LatLng> trackedRoute = const [],
    LatLng? pickup,
    LatLng? current,
  }) {
    final points = <LatLng>[...plannedPath, ...checkpoints, ...trackedRoute];

    _addIfMissing(points, pickup);
    _addIfMissing(points, current);

    return List<LatLng>.unmodifiable(points);
  }

  static void _addIfMissing(List<LatLng> points, LatLng? candidate) {
    if (candidate == null || _contains(points, candidate)) return;
    points.add(candidate);
  }

  static bool _contains(List<LatLng> points, LatLng target) {
    return points.any(
      (point) =>
          point.latitude == target.latitude &&
          point.longitude == target.longitude,
    );
  }
}
