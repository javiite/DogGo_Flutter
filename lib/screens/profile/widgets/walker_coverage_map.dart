import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../theme/doggo_radius.dart';
import '../../../theme/doggo_theme.dart';

class WalkerCoverageMap extends StatefulWidget {
  final double latitude;
  final double longitude;
  final int radiusKm;
  final ValueChanged<LatLng> onCenterChanged;

  const WalkerCoverageMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.onCenterChanged,
  });

  @override
  State<WalkerCoverageMap> createState() => _WalkerCoverageMapState();
}

class _WalkerCoverageMapState extends State<WalkerCoverageMap> {
  final MapController _controller = MapController();

  LatLng get _center => LatLng(widget.latitude, widget.longitude);

  double get _zoom {
    if (widget.radiusKm <= 3) return 12.5;
    if (widget.radiusKm <= 7) return 11.5;
    if (widget.radiusKm <= 15) return 10.5;
    if (widget.radiusKm <= 30) return 9.5;
    return 8.8;
  }

  @override
  void didUpdateWidget(covariant WalkerCoverageMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude ||
        oldWidget.radiusKm != widget.radiusKm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.move(_center, _zoom);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DogGoRadius.large),
      child: SizedBox(
        height: 235,
        child: FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: _zoom,
            minZoom: 5,
            maxZoom: 18,
            onTap: (_, point) => widget.onCenterChanged(point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.doggo_flutter',
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: _center,
                  radius: widget.radiusKm * 1000,
                  useRadiusInMeter: true,
                  color: DogGoTheme.teal.withValues(alpha: .16),
                  borderColor: DogGoTheme.teal,
                  borderStrokeWidth: 2.5,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _center,
                  width: 48,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      color: DogGoTheme.teal,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8),
                      ],
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                ),
              ],
            ),
            RichAttributionWidget(
              attributions: const [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
