import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../services/routes_service.dart';
import '../../shared/widgets/doggo_screen_scaffold.dart';
import '../../theme/doggo_theme.dart';
import '../walks/models/walk_route_selection.dart';
import 'models/doggo_route.dart';
import 'route_editor_screen.dart';

class RouteSelectionScreen extends StatefulWidget {
  final LatLng initialCenter;

  const RouteSelectionScreen({super.key, required this.initialCenter});

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  bool _loading = true;
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

  Future<void> _drawRoute() async {
    final draft = await Navigator.push<DoggoRouteDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => RouteEditorScreen(initialCenter: widget.initialCenter),
      ),
    );

    if (draft == null || !mounted) {
      return;
    }

    final selection = await _askTemplateOptions(draft);

    if (selection == null || !mounted) {
      return;
    }

    Navigator.pop(context, selection);
  }

  Future<WalkRouteSelection?> _askTemplateOptions(DoggoRouteDraft draft) async {
    var saveAsTemplate = true;
    var templateName = draft.name;

    return showModalBottomSheet<WalkRouteSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: DogGoTheme.card,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: DogGoTheme.border,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text('Recorrido listo', style: DogGoTheme.title(size: 23)),
                    const SizedBox(height: 6),
                    Text(
                      'Puedes usarlo solamente '
                      'en este paseo o guardarlo '
                      'para solicitar otros paseos '
                      'más rápido.',
                      style: DogGoTheme.subtitle(),
                    ),
                    const SizedBox(height: 18),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: saveAsTemplate,
                      title: const Text('Guardar en Mis rutas'),
                      subtitle: const Text(
                        'Podrás reutilizar este '
                        'recorrido más adelante.',
                      ),
                      onChanged: (value) {
                        setSheetState(() {
                          saveAsTemplate = value;
                        });
                      },
                    ),
                    if (saveAsTemplate) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: templateName,
                        maxLength: 80,
                        onChanged: (value) {
                          templateName = value;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Nombre para guardarla',
                          prefixIcon: Icon(Icons.bookmark_outline),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () {
                        final cleanName = templateName.trim();

                        if (saveAsTemplate && cleanName.isEmpty) {
                          ScaffoldMessenger.of(sheetContext)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Escribe un nombre '
                                  'para guardar la ruta.',
                                ),
                              ),
                            );

                          return;
                        }

                        Navigator.pop(
                          sheetContext,
                          WalkRouteSelection.custom(
                            route: draft,
                            saveAsTemplate: saveAsTemplate,
                            templateName: saveAsTemplate ? cleanName : null,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Usar en este paseo'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _selectSavedRoute(SavedDoggoRoute route) {
    Navigator.pop(context, WalkRouteSelection.saved(route));
  }

  String _cleanError(Object error) {
    final text = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '')
        .trim();

    return text.isEmpty ? 'No se pudieron cargar tus rutas.' : text;
  }

  @override
  Widget build(BuildContext context) {
    return DogGoScreenScaffold(
      title: 'Recorrido del paseo',
      body: RefreshIndicator(
        color: DogGoTheme.teal,
        onRefresh: _loadRoutes,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
          children: [
            _HeaderCard(onDraw: _drawRoute),
            const SizedBox(height: 26),

            Text('Tus rutas guardadas', style: DogGoTheme.title(size: 21)),
            const SizedBox(height: 5),
            Text(
              'Selecciona una para utilizar '
              'el mismo recorrido.',
              style: DogGoTheme.subtitle(size: 13),
            ),
            const SizedBox(height: 16),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 50),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ErrorCard(message: _error!, onRetry: _loadRoutes)
            else if (_routes.isEmpty)
              _EmptyRoutesCard(onDraw: _drawRoute)
            else
              ..._routes.map(
                (route) => Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: _SavedRouteCard(
                    route: route,
                    onTap: () => _selectSavedRoute(route),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close_rounded),
              label: const Text('Continuar sin ruta específica'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final VoidCallback onDraw;

  const _HeaderCard({required this.onDraw});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DogGoTheme.teal,
        borderRadius: BorderRadius.circular(28),
        boxShadow: DogGoTheme.elevatedShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.route_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Tú decides el recorrido',
            style: DogGoTheme.title(size: 25, color: Colors.white),
          ),
          const SizedBox(height: 7),
          Text(
            'Dibuja una ruta, delimita un área '
            'permitida y agrega puntos donde '
            'quieres recibir avisos.',
            style: DogGoTheme.subtitle(
              size: 13,
              color: Colors.white.withValues(alpha: .82),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onDraw,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: DogGoTheme.teal,
            ),
            icon: const Icon(Icons.edit_location_alt_rounded),
            label: const Text('Dibujar nueva ruta'),
          ),
        ],
      ),
    );
  }
}

class _SavedRouteCard extends StatelessWidget {
  final SavedDoggoRoute route;
  final VoidCallback onTap;

  const _SavedRouteCard({required this.route, required this.onTap});

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
        onTap: onTap,
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
                height: 125,
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
                            color: DogGoTheme.teal.withValues(alpha: .20),
                            borderColor: DogGoTheme.teal,
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
                    if (path.isNotEmpty)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: path.first,
                            width: 34,
                            height: 34,
                            child: Container(
                              decoration: BoxDecoration(
                                color: DogGoTheme.teal,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.pets_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
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
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: DogGoTheme.muted,
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

class _EmptyRoutesCard extends StatelessWidget {
  final VoidCallback onDraw;

  const _EmptyRoutesCard({required this.onDraw});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: DogGoTheme.tealLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_road_rounded,
              color: DogGoTheme.teal,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Todavía no tienes rutas',
            textAlign: TextAlign.center,
            style: DogGoTheme.title(size: 17),
          ),
          const SizedBox(height: 6),
          Text(
            'Dibuja la primera y guárdala '
            'para tus próximos paseos.',
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(size: 12),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onDraw,
            icon: const Icon(Icons.draw_rounded),
            label: const Text('Crear mi primera ruta'),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DogGoTheme.redLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DogGoTheme.red.withValues(alpha: .25)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: DogGoTheme.red, size: 34),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: DogGoTheme.body(color: DogGoTheme.red),
          ),
          const SizedBox(height: 14),
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
