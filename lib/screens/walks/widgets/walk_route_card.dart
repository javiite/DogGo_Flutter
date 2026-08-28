import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../theme/doggo_theme.dart';
import '../../routes/route_selection_screen.dart';
import '../models/pickup_location.dart';
import '../models/walk_route_selection.dart';

class WalkRouteCard extends StatelessWidget {
  final PickupLocation? pickupLocation;
  final WalkRouteSelection? selection;
  final ValueChanged<WalkRouteSelection?> onChanged;

  const WalkRouteCard({
    super.key,
    required this.pickupLocation,
    required this.selection,
    required this.onChanged,
  });

  Future<void> _openSelector(BuildContext context) async {
    final location = pickupLocation;

    if (location == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Primero selecciona el punto '
              'de recogida.',
            ),
          ),
        );

      return;
    }

    final result = await Navigator.push<WalkRouteSelection>(
      context,
      MaterialPageRoute(
        builder: (_) => RouteSelectionScreen(
          initialCenter: LatLng(location.latitude, location.longitude),
        ),
      ),
    );

    if (result != null) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = selection;

    if (current == null) {
      return Material(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => _openSelector(context),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: DogGoTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: DogGoTheme.tealLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: DogGoTheme.teal,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Elegir recorrido',
                        style: DogGoTheme.title(size: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Usa una ruta guardada '
                        'o dibuja una nueva.',
                        style: DogGoTheme.subtitle(size: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DogGoTheme.muted,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isArea = current.controlMode.toLowerCase() == 'area';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DogGoTheme.teal, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: DogGoTheme.teal,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isArea ? Icons.pentagon_outlined : Icons.route_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            current.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DogGoTheme.title(size: 15),
                          ),
                        ),
                        const SizedBox(width: 7),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: DogGoTheme.teal,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${current.pointCount} puntos'
                      ' · '
                      '${current.checkpointCount} avisos'
                      ' · '
                      '${current.allowedRadiusMeters} m',
                      style: DogGoTheme.caption(
                        size: 10.5,
                        color: DogGoTheme.tealDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RoutePreview(selection: current),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openSelector(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: DogGoTheme.card,
                  ),
                  icon: const Icon(Icons.edit_road_rounded, size: 19),
                  label: const Text('Cambiar'),
                ),
              ),
              const SizedBox(width: 9),
              IconButton.outlined(
                tooltip: 'Quitar recorrido',
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.close_rounded, color: DogGoTheme.red),
              ),
            ],
          ),
          if (current.saveAsTemplate) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.bookmark_added_outlined,
                  color: DogGoTheme.teal,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'También se guardará en '
                    'Mis rutas.',
                    style: DogGoTheme.caption(color: DogGoTheme.tealDark),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RoutePreview extends StatelessWidget {
  final WalkRouteSelection selection;

  const _RoutePreview({required this.selection});

  @override
  Widget build(BuildContext context) {
    final points = selection.points;
    final path = points
        .where((point) => !point.isCheckpoint)
        .map((point) => point.position)
        .toList(growable: false);
    final checkpoints = points
        .where((point) => point.isCheckpoint)
        .toList(growable: false);
    final visible = path.isNotEmpty
        ? path
        : points.map((point) => point.position).toList(growable: false);

    if (visible.isEmpty) {
      return Container(
        width: double.infinity,
        height: 105,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: DogGoTheme.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'La vista previa aparecerá al cargar los puntos de la ruta.',
          textAlign: TextAlign.center,
          style: DogGoTheme.caption(size: 10),
        ),
      );
    }

    final center = _center(visible);
    final isArea = selection.controlMode.toLowerCase() == 'area';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 145,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: _zoom(visible),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.doggo_flutter',
            ),
            if (isArea && path.length >= 3)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: path,
                    color: DogGoTheme.teal.withValues(alpha: .18),
                    borderColor: DogGoTheme.teal,
                    borderStrokeWidth: 3,
                  ),
                ],
              ),
            if (!isArea && path.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(points: path, strokeWidth: 7, color: Colors.white),
                  Polyline(
                    points: path,
                    strokeWidth: 4,
                    color: DogGoTheme.teal,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: visible.first,
                  width: 32,
                  height: 32,
                  child: Container(
                    decoration: BoxDecoration(
                      color: DogGoTheme.teal,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
                ...checkpoints.map(
                  (point) => Marker(
                    point: point.position,
                    width: 28,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: DogGoTheme.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.flag_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static LatLng _center(List<LatLng> points) {
    final latitude = points.fold<double>(0, (sum, item) => sum + item.latitude);
    final longitude = points.fold<double>(
      0,
      (sum, item) => sum + item.longitude,
    );
    return LatLng(latitude / points.length, longitude / points.length);
  }

  static double _zoom(List<LatLng> points) {
    if (points.length == 1) return 16;
    final latitudes = points.map((point) => point.latitude);
    final longitudes = points.map((point) => point.longitude);
    final span =
        (latitudes.reduce((a, b) => a > b ? a : b) -
                latitudes.reduce((a, b) => a < b ? a : b))
            .abs()
            .clamp(0, 180);
    final longitudeSpan =
        (longitudes.reduce((a, b) => a > b ? a : b) -
                longitudes.reduce((a, b) => a < b ? a : b))
            .abs();
    final maxSpan = span > longitudeSpan ? span : longitudeSpan;
    if (maxSpan < .002) return 16;
    if (maxSpan < .006) return 14.5;
    if (maxSpan < .02) return 13;
    if (maxSpan < .06) return 11.5;
    return 10;
  }
}
