import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../services/routes_service.dart';
import '../../shared/widgets/doggo_screen_scaffold.dart';
import '../../theme/doggo_theme.dart';
import 'models/doggo_route.dart';
import 'route_editor_screen.dart';

class SavedRoutesScreen extends StatefulWidget {
  final LatLng? initialCenter;

  const SavedRoutesScreen({super.key, this.initialCenter});

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  bool _loading = true;
  bool _processing = false;
  String? _error;

  List<SavedDoggoRoute> _routes = const [];

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final routes = await RoutesService.getSavedRoutes();

      if (!mounted) {
        return;
      }

      setState(() {
        _routes = routes;
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

  LatLng get _defaultCenter {
    if (_routes.isNotEmpty) {
      final path = _routes.first.pathPoints;

      if (path.isNotEmpty) {
        return path.first.position;
      }
    }

    return widget.initialCenter ?? const LatLng(25.6866, -100.3161);
  }

  Future<void> _createRoute() async {
    final draft = await Navigator.push<DoggoRouteDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => RouteEditorScreen(initialCenter: _defaultCenter),
      ),
    );

    if (draft == null || !mounted) {
      return;
    }

    await _runAction(
      action: () => RoutesService.createSavedRoute(draft),
      successMessage: 'Ruta guardada correctamente.',
    );
  }

  Future<void> _editRoute(SavedDoggoRoute route) async {
    SavedDoggoRoute completeRoute = route;

    try {
      completeRoute = await RoutesService.getSavedRoute(route.id);
    } catch (error) {
      if (mounted) {
        _showMessage(_cleanError(error));
      }
      return;
    }

    if (!mounted) {
      return;
    }

    final draft = await Navigator.push<DoggoRouteDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => RouteEditorScreen(
          initialCenter: completeRoute.pathPoints.isEmpty
              ? _defaultCenter
              : completeRoute.pathPoints.first.position,
          initialDraft: _draftFromRoute(completeRoute),
        ),
      ),
    );

    if (draft == null || !mounted) {
      return;
    }

    await _runAction(
      action: () =>
          RoutesService.updateSavedRoute(routeId: route.id, draft: draft),
      successMessage: 'Ruta actualizada correctamente.',
    );
  }

  Future<void> _duplicateRoute(SavedDoggoRoute route) async {
    await _runAction(
      action: () => RoutesService.duplicateSavedRoute(route.id),
      successMessage: 'Ruta duplicada correctamente.',
    );
  }

  Future<void> _deleteRoute(SavedDoggoRoute route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar ruta'),
          content: Text(
            '¿Quieres eliminar “${route.name}”?\n\n'
            'Los paseos que ya la utilizaron '
            'conservarán su copia del recorrido.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: DogGoTheme.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _runAction(
      action: () async {
        await RoutesService.deleteSavedRoute(route.id);

        return null;
      },
      successMessage: 'Ruta eliminada.',
    );
  }

  Future<void> _runAction({
    required Future<Object?> Function() action,
    required String successMessage,
  }) async {
    if (_processing) {
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      await action();

      if (!mounted) {
        return;
      }

      _showMessage(successMessage, success: true);

      await _loadRoutes();
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

  DoggoRouteDraft _draftFromRoute(SavedDoggoRoute route) {
    return DoggoRouteDraft(
      name: route.name,
      description: route.description,
      controlMode: route.controlMode,
      allowedRadiusMeters: route.allowedRadiusMeters,
      startAddress: route.startAddress,
      city: route.city,
      municipality: route.municipality,
      points: route.points
          .map(
            (point) =>
                point.copyWith(id: 0, reached: false, clearReachedAt: true),
          )
          .toList(growable: false),
    );
  }

  String _cleanError(Object error) {
    final text = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '')
        .trim();

    return text.isEmpty ? 'No se pudo completar la acción.' : text;
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
    return DogGoScreenScaffold(
      title: 'Mis rutas',
      actions: [
        IconButton(
          tooltip: 'Crear ruta',
          onPressed: _processing ? null : _createRoute,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      floatingActionButton: _loading || _error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: _processing ? null : _createRoute,
              backgroundColor: DogGoTheme.teal,
              foregroundColor: Colors.white,
              icon: _processing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_road_rounded),
              label: const Text('Nueva ruta'),
            ),
      body: RefreshIndicator(
        color: DogGoTheme.teal,
        onRefresh: _loadRoutes,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 180),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 70),
          _RoutesError(message: _error!, onRetry: _loadRoutes),
        ],
      );
    }

    if (_routes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          _EmptyRoutes(onCreate: _createRoute),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: [
        _RoutesSummary(
          routeCount: _routes.length,
          checkpointCount: _routes.fold(
            0,
            (total, route) => total + route.checkpointCount,
          ),
        ),
        const SizedBox(height: 24),
        Text('Recorridos guardados', style: DogGoTheme.title(size: 21)),
        const SizedBox(height: 5),
        Text(
          'Toca una ruta para editarla '
          'o utiliza el menú para duplicarla.',
          style: DogGoTheme.subtitle(size: 12.5),
        ),
        const SizedBox(height: 15),
        ..._routes.map(
          (route) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _SavedRouteManagementCard(
              route: route,
              disabled: _processing,
              onEdit: () => _editRoute(route),
              onDuplicate: () => _duplicateRoute(route),
              onDelete: () => _deleteRoute(route),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoutesSummary extends StatelessWidget {
  final int routeCount;
  final int checkpointCount;

  const _RoutesSummary({
    required this.routeCount,
    required this.checkpointCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: DogGoTheme.teal,
        borderRadius: BorderRadius.circular(27),
        boxShadow: DogGoTheme.elevatedShadow(),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.route_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$routeCount '
                  '${routeCount == 1 ? "ruta" : "rutas"}',
                  style: DogGoTheme.title(size: 21, color: Colors.white),
                ),
                Text(
                  '$checkpointCount puntos '
                  'de aviso configurados',
                  style: DogGoTheme.subtitle(
                    size: 11.5,
                    color: Colors.white.withValues(alpha: .78),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedRouteManagementCard extends StatelessWidget {
  final SavedDoggoRoute route;
  final bool disabled;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _SavedRouteManagementCard({
    required this.route,
    required this.disabled,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final path = route.pathPoints
        .map((point) => point.position)
        .toList(growable: false);

    final center = path.isEmpty ? const LatLng(25.6866, -100.3161) : path.first;

    return Material(
      color: DogGoTheme.card,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: disabled ? null : onEdit,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: DogGoTheme.border),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 145,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/'
                          '{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.doggo_flutter',
                    ),
                    if (route.isArea && path.length >= 3)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: path,
                            color: DogGoTheme.purple.withValues(alpha: .17),
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
                    if (route.checkpoints.isNotEmpty)
                      MarkerLayer(
                        markers: route.checkpoints
                            .map(
                              (point) => Marker(
                                point: point.position,
                                width: 34,
                                height: 34,
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
                                    size: 16,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(17),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: DogGoTheme.tealLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        route.isArea
                            ? Icons.pentagon_outlined
                            : Icons.route_rounded,
                        color: DogGoTheme.teal,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DogGoTheme.title(size: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${route.pointCount} puntos'
                            ' · '
                            '${route.checkpointCount} avisos'
                            ' · '
                            '${route.allowedRadiusMeters} m',
                            style: DogGoTheme.caption(size: 10.5),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      enabled: !disabled,
                      tooltip: 'Opciones',
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit();
                            break;
                          case 'duplicate':
                            onDuplicate();
                            break;
                          case 'delete':
                            onDelete();
                            break;
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_rounded),
                            title: Text('Editar'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'duplicate',
                          child: ListTile(
                            leading: Icon(Icons.content_copy_rounded),
                            title: Text('Duplicar'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline_rounded,
                              color: DogGoTheme.red,
                            ),
                            title: Text(
                              'Eliminar',
                              style: TextStyle(color: DogGoTheme.red),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRoutes extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyRoutes({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: DogGoTheme.tealLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_road_rounded,
              color: DogGoTheme.teal,
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Crea tu primera ruta',
            textAlign: TextAlign.center,
            style: DogGoTheme.title(size: 20),
          ),
          const SizedBox(height: 7),
          Text(
            'Guarda los recorridos que utilizas '
            'con frecuencia y solicita paseos '
            'más rápido.',
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.draw_rounded),
            label: const Text('Dibujar ruta'),
          ),
        ],
      ),
    );
  }
}

class _RoutesError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _RoutesError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DogGoTheme.redLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DogGoTheme.red.withValues(alpha: .25)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: DogGoTheme.red, size: 38),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: DogGoTheme.body(color: DogGoTheme.red),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Intentar nuevamente'),
          ),
        ],
      ),
    );
  }
}
