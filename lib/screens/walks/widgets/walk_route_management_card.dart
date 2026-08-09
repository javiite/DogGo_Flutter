import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../services/routes_service.dart';
import '../../../theme/doggo_theme.dart';
import '../../routes/models/doggo_route.dart';
import '../../routes/route_selection_screen.dart';
import '../models/walk_route_selection.dart';

class WalkRouteManagementCard
    extends StatefulWidget {
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
  State<WalkRouteManagementCard>
      createState() =>
          _WalkRouteManagementCardState();
}

class _WalkRouteManagementCardState
    extends State<WalkRouteManagementCard> {
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
  void didUpdateWidget(
    WalkRouteManagementCard oldWidget,
  ) {
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
      final route =
          await RoutesService.getPlannedRoute(
        widget.walkId,
      );

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
    if (_processing ||
        !widget.canManage) {
      return;
    }

    final selection =
        await Navigator.push<
            WalkRouteSelection>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RouteSelectionScreen(
          initialCenter:
              widget.initialCenter,
        ),
      ),
    );

    if (selection == null || !mounted) {
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      final savedRoute =
          selection.savedRoute;

      if (savedRoute != null) {
        await RoutesService.assignSavedRoute(
          walkId: widget.walkId,
          savedRouteId: savedRoute.id,
        );
      } else {
        final customRoute =
            selection.customRoute;

        if (customRoute == null) {
          return;
        }

        await RoutesService.assignCustomRoute(
          walkId: widget.walkId,
          draft: customRoute,
          saveAsTemplate:
              selection.saveAsTemplate,
          templateName:
              selection.templateName,
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
        _showMessage(
          _cleanError(error),
        );
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
    if (_processing ||
        !widget.canManage ||
        _route == null) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Quitar recorrido',
          ),
          content: const Text(
            'El paseo continuará existiendo, '
            'pero dejará de tener una ruta '
            'o área delimitada.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    DogGoTheme.red,
              ),
              child: const Text(
                'Quitar',
              ),
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
      await RoutesService.removePlannedRoute(
        widget.walkId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _route = null;
      });

      _showMessage(
        'Ruta retirada del paseo.',
        success: true,
      );
    } catch (error) {
      if (mounted) {
        _showMessage(
          _cleanError(error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  String _cleanError(
    Object error,
  ) {
    final text = error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .replaceFirst(
          'ApiException: ',
          '',
        )
        .trim();

    return text.isEmpty
        ? 'No se pudo actualizar la ruta.'
        : text;
  }

  void _showMessage(
    String message, {
    bool success = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success
              ? DogGoTheme.teal
              : DogGoTheme.ink,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: _route == null
              ? DogGoTheme.border
              : DogGoTheme.purple
                  .withValues(alpha: .45),
        ),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const SizedBox(
        height: 90,
        child: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Column(
        children: [
          const Icon(
            Icons.route_outlined,
            color: DogGoTheme.orange,
            size: 32,
          ),
          const SizedBox(height: 9),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style:
                DogGoTheme.subtitle(
              size: 11.5,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _loadRoute,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label:
                const Text('Reintentar'),
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
                  color:
                      DogGoTheme.tealLight,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: const Icon(
                  Icons.add_road_rounded,
                  color: DogGoTheme.teal,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sin recorrido definido',
                      style:
                          DogGoTheme.title(
                        size: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.canManage
                          ? 'Agrega una ruta o '
                              'área permitida.'
                          : 'El dueño no definió '
                              'una ruta.',
                      style:
                          DogGoTheme.subtitle(
                        size: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.canManage) ...[
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: _processing
                  ? null
                  : _selectRoute,
              icon: const Icon(
                Icons.draw_rounded,
              ),
              label: const Text(
                'Agregar recorrido',
              ),
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
                color:
                    DogGoTheme.purpleLight,
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
              child: Icon(
                route.isArea
                    ? Icons
                        .pentagon_outlined
                    : Icons.route_rounded,
                color: DogGoTheme.purple,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          route.name,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              DogGoTheme.title(
                            size: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons
                            .check_circle_rounded,
                        color:
                            DogGoTheme.green,
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
                    style:
                        DogGoTheme.caption(
                      size: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        OutlinedButton.icon(
          onPressed:
              widget.onOpenMap,
          icon: const Icon(
            Icons.map_outlined,
          ),
          label: const Text(
            'Ver recorrido en mapa',
          ),
        ),
        if (widget.canManage) ...[
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _processing
                      ? null
                      : _selectRoute,
                  icon: const Icon(
                    Icons.edit_road_rounded,
                    size: 19,
                  ),
                  label: const Text(
                    'Cambiar',
                  ),
                ),
              ),
              const SizedBox(width: 9),
              IconButton.outlined(
                tooltip:
                    'Quitar recorrido',
                onPressed: _processing
                    ? null
                    : _removeRoute,
                icon: const Icon(
                  Icons.delete_outline,
                  color: DogGoTheme.red,
                ),
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