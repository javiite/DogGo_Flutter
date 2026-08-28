import 'package:doggo_flutter/screens/tracking/walk_map_viewport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('combina ruta planeada, GPS, recogida y posición actual', () {
    const planned = LatLng(25.68, -100.31);
    const tracked = LatLng(25.69, -100.32);
    const pickup = LatLng(25.70, -100.33);
    const current = LatLng(25.71, -100.34);

    final points = WalkMapViewport.visiblePoints(
      plannedPath: const [planned],
      trackedRoute: const [tracked],
      pickup: pickup,
      current: current,
    );

    expect(points, const [planned, tracked, pickup, current]);
  });

  test('no duplica recogida ni posición actual', () {
    const point = LatLng(25.68, -100.31);

    final points = WalkMapViewport.visiblePoints(
      plannedPath: const [point],
      pickup: point,
      current: point,
    );

    expect(points, const [point]);
  });
}
