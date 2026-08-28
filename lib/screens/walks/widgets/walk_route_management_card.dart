import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../services/routes_service.dart';
import '../../../theme/doggo_theme.dart';
import '../../routes/models/doggo_route.dart';
import '../../routes/route_selection_screen.dart';
import '../models/walk_route_selection.dart';

class WalkRouteManagementCard extends StatefulWidget {
  final int walkId;
  final LatLng initialCenter;
  final bool canManage;
  final VoidCallback onOpenMap;

  const WalkRouteManagementCard({
    super.key,
    required this.walkId,
    required this.initialCenter,
    required this.canManage,
    required this.onOpenMap,
  });

  @override
  State<WalkRouteManagementCard> createState() =>
      _WalkRouteManagementCardState();
}

class _WalkRouteManagementCardState extends State<WalkRouteManagementCard> {
  PlannedDoggoRoute? _route;

  bool _loading = true;
  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void didUpdateWidget(WalkRouteManagementCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.walkId != widget.walkId) {
      _loadRoute();
    }
  }

  Future<void> _loadRoute() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final route = await RoutesService.getPlannedRoute(widget.walkId);

      if (!mounted) {
        return;
      }

      setState(() {
        _route = route;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = _cleanError(error);
      });
    }
  }

  Future<void> _selectRoute() async {
    if (_processing || !widget.canManage) {
      return;
    }

    final selection = await Navigator.push<WalkRouteSelection>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RouteSelectionScreen(initialCenter: widget.initialCenter),
      ),
    );

    if (selection == null || !mounted) {
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      final savedRoute = selection.savedRoute;

      if (savedRoute != null) {
        await RoutesService.assignSavedRoute(
          walkId: widget.walkId,
          savedRouteId: savedRoute.id,
        );
      } else {
        final customRoute = selection.customRoute;

        if (customRoute == null) {
          return;
        }

        await RoutesService.assignCustomRoute(
          walkId: widget.walkId,
          draft: customRoute,
          saveAsTemplate: selection.saveAsTemplate,
          templateName: selection.templateName,
        );
      }

      if (!mounted) {
        return;
      }

      _showMessage(
        _route == null
            ? 'Ruta agregada al paseo.'
            : 'Ruta del paseo actualizada.',
        success: true,
      );

      await _loadRoute();
    } catch (error) {
      if (mounted) {
        _showMessage(_cleanError(error));
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  Future<void> _removeRoute() async {
    if (_processing || !widget.canManage || _route == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Quitar recorrido'),
          content: const Text(
            'El paseo continuará existiendo, '
            'pero dejará de tener una ruta '
            'o área delimitada.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: DogGoTheme.red),
              child: const Text('Quitar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      await RoutesService.removePlannedRoute(widget.walkId);

      if (!mounted) {
        return;
      }

      setState(() {
        _route = null;
      });

      _showMessage('Ruta retirada del paseo.', success: true);
    } catch (error) {
      if (mounted) {
        _showMessage(_cleanError(error));
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  String _cleanError(Object error) {
    final text = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '')
        .trim();

    return text.isEmpty ? 'No se pudo actualizar la ruta.' : text;
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? DogGoTheme.teal : DogGoTheme.ink,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _route == null
              ? DogGoTheme.border
              : DogGoTheme.purple.withValues(alpha: .45),
        ),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Column(
        children: [
          const Icon(Icons.route_outlined, color: DogGoTheme.orange, size: 32),
          const SizedBox(height: 9),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(size: 11.5),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _loadRoute,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    final route = _route;

    if (route == null) {
      return Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: DogGoTheme.tealLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.add_road_rounded,
                  color: DogGoTheme.teal,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sin recorrido definido',
                      style: DogGoTheme.title(size: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.canManage
                          ? 'Agrega una ruta o '
                                'área permitida.'
                          : 'El dueño no definió '
                                'una ruta.',
                      style: DogGoTheme.subtitle(size: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.canManage) ...[
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: _processing ? null : _selectRoute,
              icon: const Icon(Icons.draw_rounded),
              label: const Text('Agregar recorrido'),
            ),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: DogGoTheme.purpleLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                route.isArea ? Icons.pentagon_outlined : Icons.route_rounded,
                color: DogGoTheme.purple,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.canManage ? route.name : 'Recorrido indicado',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DogGoTheme.title(size: 15),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: DogGoTheme.green,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${route.pathPoints.length} puntos'
                    ' · '
                    '${route.checkpoints.length} avisos'
                    ' · '
                    '${route.allowedRadiusMeters} m',
                    style: DogGoTheme.caption(size: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _PlannedRoutePreview(route: route, onTap: widget.onOpenMap),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: widget.onOpenMap,
          icon: const Icon(Icons.map_outlined),
          label: const Text('Ver recorrido en mapa'),
        ),
        if (widget.canManage) ...[
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _processing ? null : _selectRoute,
                  icon: const Icon(Icons.edit_road_rounded, size: 19),
                  label: const Text('Cambiar'),
                ),
              ),
              const SizedBox(width: 9),
              IconButton.outlined(
                tooltip: 'Quitar recorrido',
                onPressed: _processing ? null : _removeRoute,
                icon: const Icon(Icons.delete_outline, color: DogGoTheme.red),
              ),
            ],
          ),
        ],
        if (_processing) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }
}

class _PlannedRoutePreview extends StatelessWidget {
  final PlannedDoggoRoute route;
  final VoidCallback onTap;

  const _PlannedRoutePreview({required this.route, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final path = route.pathPoints
        .map((point) => point.position)
        .toList(growable: false);
    final visible = path.isNotEmpty
        ? path
        : route.points.map((point) => point.position).toList(growable: false);

    if (visible.isEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: DogGoTheme.purpleLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'La vista previa aparecerá cuando la ruta tenga puntos.',
          textAlign: TextAlign.center,
          style: DogGoTheme.caption(size: 10.5),
        ),
      );
    }

    return Semantics(
      button: true,
      label: 'Abrir vista completa del recorrido',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 150,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _center(visible),
                    initialZoom: _zoom(visible),
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
                    if (route.isArea && path.length >= 3)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: path,
                            color: DogGoTheme.purple.withValues(alpha: .18),
                            borderColor: DogGoTheme.purple,
                            borderStrokeWidth: 3,
                          ),
                        ],
                      ),
                    if (!route.isArea && path.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: path,
                            strokeWidth: 7,
                            color: Colors.white,
                          ),
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
                          width: 34,
                          height: 34,
                          child: Container(
                            decoration: BoxDecoration(
                              color: DogGoTheme.teal,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.pets_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        ...route.checkpoints.map(
                          (point) => Marker(
                            point: point.position,
                            width: 30,
                            height: 30,
                            child: Container(
                              decoration: BoxDecoration(
                                color: DogGoTheme.orange,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.flag_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .92),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          color: DogGoTheme.teal,
                          size: 16,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Vista previa',
                          style: TextStyle(
                            color: DogGoTheme.ink,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    final latitudeSpan =
        (latitudes.reduce((a, b) => a > b ? a : b) -
                latitudes.reduce((a, b) => a < b ? a : b))
            .abs();
    final longitudeSpan =
        (longitudes.reduce((a, b) => a > b ? a : b) -
                longitudes.reduce((a, b) => a < b ? a : b))
            .abs();
    final maxSpan = latitudeSpan > longitudeSpan ? latitudeSpan : longitudeSpan;
    if (maxSpan < .002) return 16;
    if (maxSpan < .006) return 14.5;
    if (maxSpan < .02) return 13;
    if (maxSpan < .06) return 11.5;
    return 10;
  }
}
