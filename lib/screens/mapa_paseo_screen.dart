import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../shared/widgets/doggo_screen_scaffold.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import 'home/models/home_walk_status.dart';
import 'tracking/walk_map_controller.dart';
import 'tracking/walk_map_state.dart';
import 'tracking/walk_map_viewport.dart';
import 'tracking_paseo_screen.dart';

class MapaPaseoScreen extends StatefulWidget {
  final Map<String, dynamic> paseo;

  const MapaPaseoScreen({super.key, required this.paseo});

  @override
  State<MapaPaseoScreen> createState() => _MapaPaseoScreenState();
}

class _MapaPaseoScreenState extends State<MapaPaseoScreen> {
  late final WalkMapController _controller;

  final MapController _mapController = MapController();

  bool _initialFitCompleted = false;

  @override
  void initState() {
    super.initState();

    _controller = WalkMapController(walkData: widget.paseo);

    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scheduleInitialFit(WalkMapState state) {
    if (_initialFitCompleted) {
      return;
    }

    final points = _visiblePoints(state);

    if (points.isEmpty) {
      return;
    }

    _initialFitCompleted = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fitAllPoints(state);
      }
    });
  }

  List<LatLng> _visiblePoints(WalkMapState state) {
    return WalkMapViewport.visiblePoints(
      plannedPath: state.plannedPathLatLng,
      checkpoints: state.plannedCheckpoints.map(
        (checkpoint) => checkpoint.position,
      ),
      trackedRoute: state.routeLatLng,
      pickup: state.pickupPoint,
      current: state.currentLatLng,
    );
  }

  void _fitAllPoints(WalkMapState state) {
    final points = _visiblePoints(state);

    if (points.isEmpty) {
      _showMessage('Todavía no hay coordenadas para mostrar.');
      return;
    }

    if (points.length == 1) {
      _mapController.move(points.first, 16);
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(48),
        maxZoom: 17,
      ),
    );
  }

  void _centerCurrentPosition(WalkMapState state) {
    final current = state.currentLatLng ?? state.pickupPoint;

    if (current == null) {
      _showMessage('No hay una posición disponible.');
      return;
    }

    _mapController.move(current, 17);
  }

  Future<void> _openTracking() async {
    final state = _controller.state;
    final walk = state.walk;

    if (!state.canOpenTracking) {
      _showMessage('El envío de ubicación no está disponible.');
      return;
    }

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TrackingPaseoScreen(
          paseoId: walk.id,
          nombrePerro: walk.petName,
          nombrePaseador: walk.walkerName,
        ),
      ),
    );

    if (updated == true) {
      await _controller.refresh();

      if (!mounted) {
        return;
      }

      _initialFitCompleted = false;
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;

        _scheduleInitialFit(state);

        return DogGoScreenScaffold(
          title: 'Mapa del paseo',
          actions: [
            if (state.refreshing)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                  child: SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              IconButton(
                onPressed: _controller.refresh,
                tooltip: 'Actualizar ruta',
                icon: const Icon(Icons.refresh_rounded),
              ),
            const SizedBox(width: 6),
          ],
          body: RefreshIndicator(
            onRefresh: _controller.refresh,
            color: DogGoTheme.teal,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                DogGoSpacing.screenHorizontal,
                18,
                DogGoSpacing.screenHorizontal,
                90,
              ),
              children: [
                _MapHero(state: state),
                const SizedBox(height: 16),
                if (state.error != null)
                  _TrackingErrorBanner(
                    message: state.error!,
                    hasPreviousRoute: state.hasRoute,
                    onRetry: _controller.refresh,
                  ),
                if (state.error != null) const SizedBox(height: 14),
                _MapCard(
                  state: state,
                  mapController: _mapController,
                  onFitAll: () => _fitAllPoints(state),
                  onCenter: () => _centerCurrentPosition(state),
                  onRefresh: _controller.refresh,
                ),
                const SizedBox(height: 14),
                _RouteStatistics(state: state),
                const SizedBox(height: 14),
                _TrackingStatusCard(
                  state: state,
                  onOpenTracking: _openTracking,
                ),
                const SizedBox(height: 14),
                _RouteDetailsCard(state: state),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MapHero extends StatelessWidget {
  final WalkMapState state;

  const _MapHero({required this.state});

  @override
  Widget build(BuildContext context) {
    final walk = state.walk;
    final statusColor = _statusColor(walk.status);

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: DogGoTheme.teal,
        borderRadius: BorderRadius.circular(DogGoRadius.extraLarge),
        boxShadow: DogGoTheme.elevatedShadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -48,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(DogGoRadius.pill),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _statusIcon(walk.status),
                          color: statusColor,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          walk.status.label,
                          style: DogGoTheme.caption(
                            size: 9.5,
                            color: statusColor,
                            weight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (walk.isInProgress)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(DogGoRadius.pill),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: state.locationIsRecent
                                  ? const Color(0xFF9BE4D2)
                                  : DogGoTheme.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            state.locationIsRecent
                                ? 'En vivo'
                                : 'Sin señal reciente',
                            style: DogGoTheme.caption(
                              size: 8.5,
                              color: Colors.white,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                walk.petName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DogGoTheme.title(size: 26, color: Colors.white),
              ),
              const SizedBox(height: 5),
              Text(
                'Paseador: ${walk.walkerName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DogGoTheme.body(
                  size: 11.5,
                  color: Colors.white.withValues(alpha: .78),
                ),
              ),
              const SizedBox(height: 13),
              Text(
                state.statusMessage,
                style: DogGoTheme.body(
                  size: 12,
                  color: Colors.white.withValues(alpha: .92),
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final WalkMapState state;
  final MapController mapController;
  final VoidCallback onFitAll;
  final VoidCallback onCenter;
  final VoidCallback onRefresh;

  const _MapCard({
    required this.state,
    required this.mapController,
    required this.onFitAll,
    required this.onCenter,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final actualRoute = state.routeLatLng;

    final plannedRoute = state.plannedPathLatLng;

    final pickup = state.pickupPoint;

    final current = state.currentLatLng;

    final checkpoints = state.plannedCheckpoints;

    final markers = <Marker>[];

    if (pickup != null) {
      markers.add(
        Marker(
          point: pickup,
          width: 86,
          height: 78,
          child: const _MapMarker(
            icon: Icons.home_rounded,
            color: DogGoTheme.purple,
            label: 'Recogida',
          ),
        ),
      );
    }

    if (plannedRoute.isNotEmpty) {
      markers.add(
        Marker(
          point: plannedRoute.first,
          width: 38,
          height: 38,
          child: const _PlannedPointMarker(
            icon: Icons.play_arrow_rounded,
            color: DogGoTheme.purple,
          ),
        ),
      );

      if (plannedRoute.length >= 2) {
        markers.add(
          Marker(
            point: plannedRoute.last,
            width: 38,
            height: 38,
            child: const _PlannedPointMarker(
              icon: Icons.flag_rounded,
              color: DogGoTheme.purple,
            ),
          ),
        );
      }
    }

    if (actualRoute.length >= 2) {
      final start = actualRoute.first;

      final sameAsPickup =
          pickup != null &&
          start.latitude == pickup.latitude &&
          start.longitude == pickup.longitude;

      if (!sameAsPickup) {
        markers.add(
          Marker(
            point: start,
            width: 76,
            height: 70,
            child: const _MapMarker(
              icon: Icons.trip_origin_rounded,
              color: DogGoTheme.orange,
              label: 'Inicio GPS',
              compact: true,
            ),
          ),
        );
      }
    }

    for (final checkpoint in checkpoints) {
      markers.add(
        Marker(
          point: checkpoint.position,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: checkpoint.reached ? DogGoTheme.green : DogGoTheme.orange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: DogGoTheme.softShadow(),
            ),
            child: Icon(
              checkpoint.reached ? Icons.check_rounded : Icons.flag_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    if (current != null) {
      markers.add(
        Marker(
          point: current,
          width: 90,
          height: 82,
          child: _MapMarker(
            icon: state.outsidePlannedRoute
                ? Icons.warning_rounded
                : Icons.pets_rounded,
            color: state.outsidePlannedRoute
                ? DogGoTheme.red
                : state.walk.isCompleted
                ? DogGoTheme.teal
                : DogGoTheme.green,
            label: state.outsidePlannedRoute
                ? 'Fuera de ruta'
                : state.walk.isCompleted
                ? 'Último punto'
                : 'Paseador',
          ),
        ),
      );
    }

    return Container(
      height: 460,
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.extraLarge),
        border: Border.all(
          color: state.outsidePlannedRoute ? DogGoTheme.red : DogGoTheme.border,
          width: state.outsidePlannedRoute ? 2 : 1,
        ),
        boxShadow: DogGoTheme.softShadow(
          opacity: .035,
          blur: 22,
          offset: const Offset(0, 8),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: state.initialCenter,
              initialZoom: 15,
              minZoom: 3,
              maxZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/'
                    '{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.doggo_flutter',
              ),

              // Área permitida elegida por
              // el dueño.
              if (state.plannedRouteIsArea && plannedRoute.length >= 3)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: plannedRoute,
                      color: state.outsidePlannedRoute
                          ? DogGoTheme.red.withValues(alpha: .12)
                          : DogGoTheme.purple.withValues(alpha: .16),
                      borderColor: state.outsidePlannedRoute
                          ? DogGoTheme.red
                          : DogGoTheme.purple,
                      borderStrokeWidth: 4,
                      pattern: StrokePattern.dashed(segments: const [12, 8]),
                    ),
                  ],
                ),

              // Ruta planeada. Se muestra
              // en morado discontinuo.
              if (!state.plannedRouteIsArea && plannedRoute.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: plannedRoute,
                      strokeWidth: 8,
                      color: Colors.white.withValues(alpha: .92),
                    ),
                    Polyline(
                      points: plannedRoute,
                      strokeWidth: 5,
                      color: DogGoTheme.purple,
                      pattern: StrokePattern.dashed(segments: const [12, 8]),
                    ),
                  ],
                ),

              // Radio de llegada de cada
              // checkpoint.
              if (checkpoints.isNotEmpty)
                CircleLayer(
                  circles: checkpoints
                      .map(
                        (checkpoint) => CircleMarker(
                          point: checkpoint.position,
                          radius: (checkpoint.alertRadiusMeters ?? 50)
                              .toDouble(),
                          useRadiusInMeter: true,
                          color: checkpoint.reached
                              ? DogGoTheme.green.withValues(alpha: .12)
                              : DogGoTheme.orange.withValues(alpha: .14),
                          borderColor: checkpoint.reached
                              ? DogGoTheme.green
                              : DogGoTheme.orange,
                          borderStrokeWidth: 1.5,
                        ),
                      )
                      .toList(),
                ),

              // Ruta GPS real. Se dibuja
              // encima de la planeada.
              if (actualRoute.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: actualRoute,
                      strokeWidth: 9,
                      color: Colors.white.withValues(alpha: .92),
                    ),
                    Polyline(
                      points: actualRoute,
                      strokeWidth: 5,
                      color: DogGoTheme.green,
                    ),
                  ],
                ),

              MarkerLayer(markers: markers),
            ],
          ),

          Positioned(
            left: 12,
            top: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.hasPlannedRoute)
                  _MapStatusPill(
                    icon: Icons.route_rounded,
                    text: state.plannedRouteName,
                    color: DogGoTheme.purple,
                  ),
                if (state.hasPlannedRoute && state.hasRoute)
                  const SizedBox(height: 7),
                if (state.hasRoute)
                  _MapStatusPill(
                    icon: Icons.gps_fixed_rounded,
                    text: state.routePointsLabel,
                    color: DogGoTheme.green,
                  ),
                if (state.outsidePlannedRoute) ...[
                  const SizedBox(height: 7),
                  const _MapStatusPill(
                    icon: Icons.warning_rounded,
                    text: 'Fuera de ruta',
                    color: DogGoTheme.red,
                  ),
                ],
                if (!state.hasAnyRoute)
                  const _MapStatusPill(
                    icon: Icons.info_outline_rounded,
                    text: 'Sin recorrido disponible',
                    color: DogGoTheme.orange,
                  ),
              ],
            ),
          ),

          Positioned(
            right: 12,
            top: 12,
            child: Column(
              children: [
                _MapControlButton(
                  icon: Icons.fit_screen_rounded,
                  tooltip: 'Mostrar recorrido completo',
                  onTap: onFitAll,
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Centrar posición',
                  onTap: onCenter,
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Actualizar',
                  loading: state.refreshing,
                  onTap: onRefresh,
                ),
              ],
            ),
          ),

          if (state.hasAnyRoute)
            const Positioned(left: 12, bottom: 12, child: _MapLegend()),

          if (state.loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x99FFFFFF),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          if (!state.loading && markers.isEmpty && !state.hasAnyRoute)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0xDFFFFFFF),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: DogGoTheme.card,
                        borderRadius: BorderRadius.circular(DogGoRadius.large),
                        border: Border.all(color: DogGoTheme.border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.map_outlined,
                            color: DogGoTheme.muted,
                            size: 42,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sin recorrido disponible',
                            textAlign: TextAlign.center,
                            style: DogGoTheme.title(size: 17),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.statusMessage,
                            textAlign: TextAlign.center,
                            style: DogGoTheme.subtitle(size: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(14),
        boxShadow: DogGoTheme.softShadow(
          opacity: .08,
          blur: 10,
          offset: const Offset(0, 3),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegendItem(
            color: DogGoTheme.purple,
            label: 'Planeada',
            dashed: true,
          ),
          SizedBox(height: 5),
          _LegendItem(color: DogGoTheme.green, label: 'GPS real'),
          SizedBox(height: 5),
          _LegendItem(color: DogGoTheme.orange, label: 'Punto de aviso'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendItem({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 22,
          child: Row(
            children: dashed
                ? [
                    Container(width: 8, height: 3, color: color),
                    const SizedBox(width: 3),
                    Container(width: 8, height: 3, color: color),
                  ]
                : [Container(width: 19, height: 3, color: color)],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: DogGoTheme.caption(
            size: 9,
            color: DogGoTheme.ink,
            weight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PlannedPointMarker extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _PlannedPointMarker({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: DogGoTheme.softShadow(),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool compact;

  const _MapMarker({
    required this.icon,
    required this.color,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 38.0 : 45.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: compact ? 19 : 22),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DogGoRadius.small),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .08),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: DogGoTheme.caption(
              size: 8,
              color: color,
              weight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool loading;

  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: .96),
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          onTap: loading ? null : onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 42,
            height: 42,
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, color: DogGoTheme.ink, size: 20),
          ),
        ),
      ),
    );
  }
}

class _MapStatusPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MapStatusPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(DogGoRadius.pill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: DogGoTheme.caption(
              size: 9.5,
              color: color,
              weight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteStatistics extends StatelessWidget {
  final WalkMapState state;

  const _RouteStatistics({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 17),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatisticItem(
              icon: Icons.route_rounded,
              value: state.distanceLabel,
              label: 'Distancia',
              color: DogGoTheme.teal,
            ),
          ),
          const _StatisticDivider(),
          Expanded(
            child: _StatisticItem(
              icon: Icons.location_on_outlined,
              value: '${state.route.length}',
              label: 'Puntos GPS',
              color: DogGoTheme.purple,
            ),
          ),
          const _StatisticDivider(),
          Expanded(
            child: _StatisticItem(
              icon: Icons.update_rounded,
              value: state.lastUpdateLabel,
              label: 'Actualización',
              color: state.locationIsRecent
                  ? DogGoTheme.green
                  : DogGoTheme.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatisticItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(height: 7),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DogGoTheme.body(size: 11.5, weight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: DogGoTheme.caption(size: 9),
        ),
      ],
    );
  }
}

class _StatisticDivider extends StatelessWidget {
  const _StatisticDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 53, color: DogGoTheme.divider);
  }
}

class _TrackingStatusCard extends StatelessWidget {
  final WalkMapState state;
  final VoidCallback onOpenTracking;

  const _TrackingStatusCard({
    required this.state,
    required this.onOpenTracking,
  });

  @override
  Widget build(BuildContext context) {
    final active = state.walk.isInProgress;
    final color = active ? DogGoTheme.green : _statusColor(state.walk.status);

    final surface = active
        ? DogGoTheme.greenLight
        : _statusSurface(state.walk.status);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(DogGoRadius.medium),
                ),
                child: Icon(
                  active
                      ? Icons.location_searching_rounded
                      : _statusIcon(state.walk.status),
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado del seguimiento',
                      style: DogGoTheme.title(size: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      active && state.locationIsRecent
                          ? 'Recibiendo ubicación'
                          : state.walk.status.label,
                      style: DogGoTheme.caption(
                        size: 9.5,
                        color: color,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(state.statusMessage, style: DogGoTheme.subtitle(size: 11.5)),
          if (state.canOpenTracking) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onOpenTracking,
              icon: const Icon(Icons.my_location_rounded),
              label: const Text('Administrar ubicación en vivo'),
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteDetailsCard extends StatelessWidget {
  final WalkMapState state;

  const _RouteDetailsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final walk = state.walk;
    final current = state.currentPoint;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: DogGoTheme.tealLight,
                  borderRadius: BorderRadius.circular(DogGoRadius.medium),
                ),
                child: const Icon(Icons.route_outlined, color: DogGoTheme.teal),
              ),
              const SizedBox(width: 11),
              Text('Datos del recorrido', style: DogGoTheme.title(size: 16)),
            ],
          ),
          const SizedBox(height: 16),
          _RouteDetailRow(
            icon: Icons.home_outlined,
            label: 'Punto de recogida',
            value: walk.pickupAddress,
          ),
          const Divider(height: 22),
          _RouteDetailRow(
            icon: Icons.pin_drop_outlined,
            label: 'Coordenadas de recogida',
            value: walk.pickupCoordinatesLabel,
          ),
          const Divider(height: 22),
          _RouteDetailRow(
            icon: Icons.my_location_rounded,
            label: 'Última posición',
            value: current?.coordinatesLabel ?? 'No disponible',
          ),
          const Divider(height: 22),
          _RouteDetailRow(
            icon: Icons.access_time_rounded,
            label: 'Fecha de posición',
            value: current?.fullDateLabel ?? 'No disponible',
          ),
          if (current?.accuracy != null) ...[
            const Divider(height: 22),
            _RouteDetailRow(
              icon: Icons.gps_fixed_rounded,
              label: 'Precisión estimada',
              value: '${current!.accuracy!.toStringAsFixed(0)} m',
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RouteDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: DogGoTheme.muted, size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: DogGoTheme.body(size: 10.5, color: DogGoTheme.muted),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: DogGoTheme.body(size: 10.5, weight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _TrackingErrorBanner extends StatelessWidget {
  final String message;
  final bool hasPreviousRoute;
  final VoidCallback onRetry;

  const _TrackingErrorBanner({
    required this.message,
    required this.hasPreviousRoute,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: DogGoTheme.orangeLight,
        borderRadius: BorderRadius.circular(DogGoRadius.medium),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: DogGoTheme.orange),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              hasPreviousRoute
                  ? 'No se pudo actualizar. Se conserva la última ruta disponible.'
                  : message,
              style: DogGoTheme.caption(
                size: 10,
                color: DogGoTheme.orange,
                weight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

Color _statusColor(HomeWalkStatus status) {
  switch (status) {
    case HomeWalkStatus.pending:
      return DogGoTheme.orange;
    case HomeWalkStatus.accepted:
      return DogGoTheme.purple;
    case HomeWalkStatus.inProgress:
      return DogGoTheme.green;
    case HomeWalkStatus.completed:
      return DogGoTheme.teal;
    case HomeWalkStatus.cancelled:
    case HomeWalkStatus.rejected:
      return DogGoTheme.red;
    case HomeWalkStatus.none:
    case HomeWalkStatus.unknown:
      return DogGoTheme.muted;
  }
}

Color _statusSurface(HomeWalkStatus status) {
  switch (status) {
    case HomeWalkStatus.pending:
      return DogGoTheme.orangeLight;
    case HomeWalkStatus.accepted:
      return DogGoTheme.purpleLight;
    case HomeWalkStatus.inProgress:
      return DogGoTheme.greenLight;
    case HomeWalkStatus.completed:
      return DogGoTheme.tealLight;
    case HomeWalkStatus.cancelled:
    case HomeWalkStatus.rejected:
      return DogGoTheme.redLight;
    case HomeWalkStatus.none:
    case HomeWalkStatus.unknown:
      return DogGoTheme.purpleLight;
  }
}

IconData _statusIcon(HomeWalkStatus status) {
  switch (status) {
    case HomeWalkStatus.pending:
      return Icons.schedule_rounded;
    case HomeWalkStatus.accepted:
      return Icons.verified_outlined;
    case HomeWalkStatus.inProgress:
      return Icons.directions_walk_rounded;
    case HomeWalkStatus.completed:
      return Icons.flag_outlined;
    case HomeWalkStatus.cancelled:
    case HomeWalkStatus.rejected:
      return Icons.cancel_outlined;
    case HomeWalkStatus.none:
    case HomeWalkStatus.unknown:
      return Icons.info_outline_rounded;
  }
}
