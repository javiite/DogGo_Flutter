import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapaEstaticoPreview extends StatelessWidget {
  final double? latitud;
  final double? longitud;
  final String titulo;
  final String subtitulo;
  final Color color;
  final VoidCallback? onTap;

  const MapaEstaticoPreview({
    super.key,
    required this.latitud,
    required this.longitud,
    required this.titulo,
    required this.subtitulo,
    this.color = const Color(0xFF1F8A70),
    this.onTap,
  });

  bool get _tieneCoordenadas {
    return latitud != null && longitud != null;
  }

  LatLng get _centro {
    if (_tieneCoordenadas) {
      return LatLng(latitud!, longitud!);
    }

    return const LatLng(25.6866, -100.3161);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _centro,
                initialZoom: _tieneCoordenadas ? 16 : 12,
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
                if (_tieneCoordenadas)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _centro,
                        width: 58,
                        height: 58,
                        child: Icon(
                          Icons.location_on_rounded,
                          color: color,
                          size: 48,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _tieneCoordenadas
                          ? Icons.location_on_rounded
                          : Icons.location_off_rounded,
                      color: color,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey.shade600,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}