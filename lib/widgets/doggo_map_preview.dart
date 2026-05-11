import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DogGoMapPreview extends StatelessWidget {
  final double? latitud;
  final double? longitud;
  final double height;
  final String emptyText;
  final VoidCallback? onTap;

  const DogGoMapPreview({
    super.key,
    required this.latitud,
    required this.longitud,
    this.height = 220,
    this.emptyText = 'Sin ubicación seleccionada',
    this.onTap,
  });

  bool get _tieneUbicacion {
    return latitud != null &&
        longitud != null &&
        latitud! >= -90 &&
        latitud! <= 90 &&
        longitud! >= -180 &&
        longitud! <= 180;
  }

  @override
  Widget build(BuildContext context) {
    final child = _tieneUbicacion ? _buildMap() : _buildEmpty();

    if (onTap == null) return child;

    return GestureDetector(
      onTap: onTap,
      child: child,
    );
  }

  Widget _buildMap() {
    final punto = LatLng(latitud!, longitud!);

    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE0F5F3),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEDE8E0),
        ),
      ),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: punto,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.doggo_flutter',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: punto,
                    width: 54,
                    height: 54,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F9B8E),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.20),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.92),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF0F9B8E),
                    size: 17,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Ubicación predeterminada',
                    style: TextStyle(
                      color: Color(0xFF2D3142),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F5F3),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEDE8E0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.85),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_location_alt_rounded,
              color: Color(0xFF0F9B8E),
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            emptyText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF2D3142),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Toca para seleccionar o actualizar el punto.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7B8194),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}