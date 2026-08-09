import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../services/location_service.dart';
import '../../theme/doggo_theme.dart';
import 'models/doggo_route.dart';

enum _EditorTool {
  route,
  checkpoint,
}

class RouteEditorScreen extends StatefulWidget {
  final LatLng? initialCenter;
  final DoggoRouteDraft? initialDraft;

  const RouteEditorScreen({
    super.key,
    this.initialCenter,
    this.initialDraft,
  });

  @override
  State<RouteEditorScreen> createState() =>
      _RouteEditorScreenState();
}

class _RouteEditorScreenState
    extends State<RouteEditorScreen> {
  final MapController _mapController =
      MapController();

  final LocationService _locationService =
      LocationService();

  late final TextEditingController
      _nameController;

  final List<DoggoRoutePoint> _points = [];

  String _controlMode = 'Ruta';
  int _allowedRadiusMeters = 100;
  _EditorTool _tool = _EditorTool.route;

  bool _locating = false;

  @override
  void initState() {
    super.initState();

    final draft = widget.initialDraft;

    _nameController = TextEditingController(
      text: draft?.name ?? 'Mi ruta DogGo',
    );

    if (draft != null) {
      _controlMode = draft.controlMode;
      _allowedRadiusMeters =
          draft.allowedRadiusMeters;
      _points.addAll(draft.points);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  LatLng get _initialCenter {
    final routePoints = _pathPoints;

    if (routePoints.isNotEmpty) {
      return routePoints.first.position;
    }

    return widget.initialCenter ??
        const LatLng(25.6866, -100.3161);
  }

  List<DoggoRoutePoint> get _pathPoints {
    return _points
        .where((point) => !point.isCheckpoint)
        .toList(growable: false)
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<DoggoRoutePoint> get _checkpoints {
    return _points
        .where((point) => point.isCheckpoint)
        .toList(growable: false)
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  bool get _isArea {
    return _controlMode == 'Area';
  }

  void _addPoint(
    LatLng position,
  ) {
    final nextOrder = _points.isEmpty
        ? 0
        : _points
                .map((point) => point.order)
                .reduce((a, b) => a > b ? a : b) +
            1;

    if (_tool == _EditorTool.checkpoint) {
      final checkpointNumber =
          _checkpoints.length + 1;

      setState(() {
        _points.add(
          DoggoRoutePoint(
            order: nextOrder,
            latitude: position.latitude,
            longitude: position.longitude,
            type: 'Checkpoint',
            name:
                'Punto de aviso $checkpointNumber',
            alertRadiusMeters: 50,
            notifyOnArrival: true,
          ),
        );
      });

      _showMessage(
        'Punto de aviso agregado.',
      );

      return;
    }

    setState(() {
      _points.add(
        DoggoRoutePoint(
          order: nextOrder,
          latitude: position.latitude,
          longitude: position.longitude,
          type: _isArea ? 'Limite' : 'Ruta',
        ),
      );
    });
  }

  void _changeMode(
    String mode,
  ) {
    if (_controlMode == mode) {
      return;
    }

    setState(() {
      _controlMode = mode;

      for (var index = 0;
          index < _points.length;
          index++) {
        final point = _points[index];

        if (point.isCheckpoint) {
          continue;
        }

        _points[index] = point.copyWith(
          type: mode == 'Area'
              ? 'Limite'
              : 'Ruta',
        );
      }
    });
  }

  void _undo() {
    if (_points.isEmpty) {
      _showMessage(
        'Todavía no has agregado puntos.',
      );
      return;
    }

    setState(() {
      _points.removeLast();
    });
  }

  Future<void> _clear() async {
    if (_points.isEmpty) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Borrar recorrido'),
          content: const Text(
            'Se eliminarán todos los puntos y '
            'checkpoints que dibujaste.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor:
                    DogGoTheme.red,
              ),
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _points.clear();
    });
  }

  Future<void> _locate() async {
    if (_locating) {
      return;
    }

    setState(() {
      _locating = true;
    });

    try {
      final position =
          await _locationService
              .obtenerUbicacionActual();

      if (!mounted) {
        return;
      }

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      _mapController.move(
        location,
        17,
      );
    } catch (error) {
      if (mounted) {
        _showMessage(
          _errorMessage(error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _locating = false;
        });
      }
    }
  }

  Future<void> _editCheckpoint(
    DoggoRoutePoint checkpoint,
  ) async {
    final nameController =
        TextEditingController(
      text: checkpoint.name ?? '',
    );

    var radius =
        checkpoint.alertRadiusMeters ?? 50;

    var notify =
        checkpoint.notifyOnArrival;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: DogGoTheme.card,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            sheetContext,
            setSheetState,
          ) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                24 +
                    MediaQuery.viewInsetsOf(
                      sheetContext,
                    ).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: DogGoTheme.border,
                          borderRadius:
                              BorderRadius.circular(
                            99,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Punto de aviso',
                      style: DogGoTheme.title(
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'El dueño recibirá una '
                      'notificación cuando el paseo '
                      'llegue a este lugar.',
                      style:
                          DogGoTheme.subtitle(),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller:
                          nameController,
                      maxLength: 80,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Nombre del punto',
                        prefixIcon: Icon(
                          Icons.flag_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Avisar a $radius metros',
                            style:
                                DogGoTheme.body(),
                          ),
                        ),
                        Text(
                          '$radius m',
                          style:
                              DogGoTheme.label(),
                        ),
                      ],
                    ),
                    Slider(
                      value: radius.toDouble(),
                      min: 10,
                      max: 300,
                      divisions: 29,
                      label: '$radius m',
                      onChanged: (value) {
                        setSheetState(() {
                          radius =
                              value.round();
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      title: const Text(
                        'Enviar notificación',
                      ),
                      subtitle: const Text(
                        'Avisar al dueño al llegar.',
                      ),
                      value: notify,
                      onChanged: (value) {
                        setSheetState(() {
                          notify = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        final index =
                            _points.indexWhere(
                          (point) =>
                              point.order ==
                              checkpoint.order,
                        );

                        if (index >= 0) {
                          setState(() {
                            _points[index] =
                                checkpoint.copyWith(
                              name:
                                  nameController
                                      .text
                                      .trim(),
                              alertRadiusMeters:
                                  radius,
                              notifyOnArrival:
                                  notify,
                            );
                          });
                        }

                        Navigator.pop(
                          sheetContext,
                        );
                      },
                      icon: const Icon(
                        Icons.check_rounded,
                      ),
                      label:
                          const Text('Guardar punto'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _points.removeWhere(
                            (point) =>
                                point.order ==
                                checkpoint.order,
                          );
                        });

                        Navigator.pop(
                          sheetContext,
                        );
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                      ),
                      label: const Text(
                        'Eliminar punto',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            DogGoTheme.red,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
  }

  void _finish() {
    final name =
        _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage(
        'Escribe un nombre para la ruta.',
      );
      return;
    }

    final minimumPoints =
        _isArea ? 3 : 2;

    if (_pathPoints.length <
        minimumPoints) {
      _showMessage(
        _isArea
            ? 'El área necesita por lo menos '
                '3 puntos.'
            : 'El recorrido necesita por lo '
                'menos 2 puntos.',
      );
      return;
    }

    final normalizedPoints =
        <DoggoRoutePoint>[];

    final ordered = [..._points]
      ..sort(
        (a, b) =>
            a.order.compareTo(b.order),
      );

    for (var index = 0;
        index < ordered.length;
        index++) {
      normalizedPoints.add(
        ordered[index].copyWith(
          order: index,
        ),
      );
    }

    final draft = DoggoRouteDraft(
      name: name,
      controlMode: _controlMode,
      allowedRadiusMeters:
          _allowedRadiusMeters,
      points: normalizedPoints,
    );

    Navigator.pop(
      context,
      draft,
    );
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  String _errorMessage(
    Object error,
  ) {
    final message = error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();

    return message.isEmpty
        ? 'No se pudo obtener tu ubicación.'
        : message;
  }

  @override
  Widget build(BuildContext context) {
    final pathPositions = _pathPoints
        .map((point) => point.position)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      appBar: AppBar(
        title: const Text('Crear recorrido'),
        actions: [
          IconButton(
            tooltip: 'Borrar todo',
            onPressed:
                _points.isEmpty ? null : _clear,
            icon: const Icon(
              Icons.delete_sweep_outlined,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter:
                    _initialCenter,
                initialZoom: 16,
                minZoom: 3,
                maxZoom: 19,
                onTap: (_, point) =>
                    _addPoint(point),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/'
                      '{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.example.doggo_flutter',
                ),

                if (_isArea &&
                    pathPositions.length >= 3)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: pathPositions,
                        color: DogGoTheme.teal
                            .withValues(
                          alpha: .18,
                        ),
                        borderColor:
                            DogGoTheme.teal,
                        borderStrokeWidth: 4,
                      ),
                    ],
                  ),

                if (!_isArea &&
                    pathPositions.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: pathPositions,
                        strokeWidth: 10,
                        color: Colors.white
                            .withValues(
                          alpha: .92,
                        ),
                      ),
                      Polyline(
                        points: pathPositions,
                        strokeWidth: 5,
                        color:
                            DogGoTheme.teal,
                      ),
                    ],
                  ),

                if (_checkpoints.isNotEmpty)
                  CircleLayer(
                    circles: _checkpoints
                        .map(
                          (checkpoint) =>
                              CircleMarker(
                            point: checkpoint
                                .position,
                            radius: (
                              checkpoint
                                      .alertRadiusMeters ??
                                  50
                            ).toDouble(),
                            useRadiusInMeter: true,
                            color: DogGoTheme
                                .orange
                                .withValues(
                              alpha: .15,
                            ),
                            borderColor:
                                DogGoTheme.orange,
                            borderStrokeWidth: 2,
                          ),
                        )
                        .toList(),
                  ),

                MarkerLayer(
                  markers: [
                    ..._pathPoints
                        .asMap()
                        .entries
                        .map(
                          (entry) => Marker(
                            point: entry
                                .value.position,
                            width: 38,
                            height: 38,
                            child:
                                _RoutePointMarker(
                              number:
                                  entry.key + 1,
                              isArea: _isArea,
                            ),
                          ),
                        ),
                    ..._checkpoints.map(
                      (checkpoint) => Marker(
                        point:
                            checkpoint.position,
                        width: 48,
                        height: 48,
                        child: GestureDetector(
                          onTap: () =>
                              _editCheckpoint(
                            checkpoint,
                          ),
                          child: Container(
                            decoration:
                                BoxDecoration(
                              color:
                                  DogGoTheme.orange,
                              shape:
                                  BoxShape.circle,
                              border:
                                  Border.all(
                                color:
                                    Colors.white,
                                width: 3,
                              ),
                              boxShadow:
                                  DogGoTheme
                                      .softShadow(),
                            ),
                            child: const Icon(
                              Icons
                                  .flag_rounded,
                              color:
                                  Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            top: 14,
            child: _InstructionCard(
              tool: _tool,
              isArea: _isArea,
              pathCount:
                  _pathPoints.length,
              checkpointCount:
                  _checkpoints.length,
            ),
          ),

          Positioned(
            right: 16,
            bottom: 235,
            child: Column(
              children: [
                _MapButton(
                  tooltip: 'Mi ubicación',
                  loading: _locating,
                  icon:
                      Icons.my_location_rounded,
                  onPressed: _locate,
                ),
                const SizedBox(height: 10),
                _MapButton(
                  tooltip: 'Deshacer',
                  icon: Icons.undo_rounded,
                  onPressed: _undo,
                ),
              ],
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: .28,
            minChildSize: .22,
            maxChildSize: .62,
            snap: true,
            snapSizes: const [
              .28,
              .62,
            ],
            builder: (
              context,
              scrollController,
            ) {
              return Container(
                decoration: BoxDecoration(
                  color: DogGoTheme.card,
                  borderRadius:
                      const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow:
                      DogGoTheme.softShadow(
                    opacity: .10,
                    blur: 28,
                    offset:
                        const Offset(0, -8),
                  ),
                ),
                child: ListView(
                  controller:
                      scrollController,
                  padding:
                      const EdgeInsets.fromLTRB(
                    22,
                    12,
                    22,
                    30,
                  ),
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              DogGoTheme.border,
                          borderRadius:
                              BorderRadius.circular(
                            99,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Diseña el paseo',
                            style:
                                DogGoTheme.title(
                              size: 22,
                            ),
                          ),
                        ),
                        Text(
                          '${_pathPoints.length} puntos',
                          style:
                              DogGoTheme.label(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller:
                          _nameController,
                      maxLength: 80,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Nombre de la ruta',
                        prefixIcon: Icon(
                          Icons.route_rounded,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Tipo de control',
                      style: DogGoTheme.label(
                        color:
                            DogGoTheme.muted,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _ChoiceButton(
                            selected:
                                !_isArea,
                            icon:
                                Icons.route_rounded,
                            label: 'Recorrido',
                            onTap: () =>
                                _changeMode(
                              'Ruta',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ChoiceButton(
                            selected: _isArea,
                            icon: Icons
                                .pentagon_outlined,
                            label:
                                'Área permitida',
                            onTap: () =>
                                _changeMode(
                              'Area',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Herramienta del mapa',
                      style: DogGoTheme.label(
                        color:
                            DogGoTheme.muted,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _ChoiceButton(
                            selected: _tool ==
                                _EditorTool.route,
                            icon: Icons
                                .add_location_alt_outlined,
                            label: _isArea
                                ? 'Dibujar límite'
                                : 'Trazar ruta',
                            onTap: () {
                              setState(() {
                                _tool =
                                    _EditorTool
                                        .route;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ChoiceButton(
                            selected: _tool ==
                                _EditorTool
                                    .checkpoint,
                            icon:
                                Icons.flag_outlined,
                            label:
                                'Punto de aviso',
                            onTap: () {
                              setState(() {
                                _tool =
                                    _EditorTool
                                        .checkpoint;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isArea
                                ? 'Tolerancia fuera del área'
                                : 'Distancia permitida de la ruta',
                            style:
                                DogGoTheme.body(),
                          ),
                        ),
                        Text(
                          '$_allowedRadiusMeters m',
                          style:
                              DogGoTheme.label(),
                        ),
                      ],
                    ),

                    Slider(
                      value:
                          _allowedRadiusMeters
                              .toDouble(),
                      min: 20,
                      max: 1000,
                      divisions: 49,
                      label:
                          '$_allowedRadiusMeters m',
                      onChanged: (value) {
                        setState(() {
                          _allowedRadiusMeters =
                              value.round();
                        });
                      },
                    ),

                    Text(
                      'La alerta se genera después '
                      'de 3 lecturas GPS consecutivas '
                      'fuera del límite.',
                      style:
                          DogGoTheme.caption(),
                    ),

                    const SizedBox(height: 24),

                    FilledButton.icon(
                      onPressed: _finish,
                      icon: const Icon(
                        Icons.check_rounded,
                      ),
                      label: const Text(
                        'Usar este recorrido',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InstructionCard
    extends StatelessWidget {
  final _EditorTool tool;
  final bool isArea;
  final int pathCount;
  final int checkpointCount;

  const _InstructionCard({
    required this.tool,
    required this.isArea,
    required this.pathCount,
    required this.checkpointCount,
  });

  @override
  Widget build(BuildContext context) {
    final checkpointTool =
        tool == _EditorTool.checkpoint;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow:
            DogGoTheme.softShadow(
          opacity: .09,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: checkpointTool
                  ? DogGoTheme.orangeLight
                  : DogGoTheme.tealLight,
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Icon(
              checkpointTool
                  ? Icons.flag_rounded
                  : isArea
                      ? Icons
                          .pentagon_outlined
                      : Icons.route_rounded,
              color: checkpointTool
                  ? DogGoTheme.orange
                  : DogGoTheme.teal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  checkpointTool
                      ? 'Toca para agregar un aviso'
                      : isArea
                          ? 'Toca para delimitar el área'
                          : 'Toca para trazar el recorrido',
                  style: DogGoTheme.body(
                    size: 13,
                    weight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$pathCount puntos · '
                  '$checkpointCount avisos',
                  style:
                      DogGoTheme.caption(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? DogGoTheme.tealLight
          : DogGoTheme.cream,
      borderRadius:
          BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? DogGoTheme.teal
                  : DogGoTheme.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? DogGoTheme.teal
                    : DogGoTheme.muted,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow:
                      TextOverflow.ellipsis,
                  style: DogGoTheme.body(
                    size: 12,
                    color: selected
                        ? DogGoTheme.teal
                        : DogGoTheme.ink,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool loading;

  const _MapButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.card,
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        tooltip: tooltip,
        onPressed:
            loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 21,
                height: 21,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.2,
                ),
              )
            : Icon(
                icon,
                color: DogGoTheme.teal,
              ),
      ),
    );
  }
}

class _RoutePointMarker
    extends StatelessWidget {
  final int number;
  final bool isArea;

  const _RoutePointMarker({
    required this.number,
    required this.isArea,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isArea
            ? DogGoTheme.purple
            : DogGoTheme.teal,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow:
            DogGoTheme.softShadow(),
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: DogGoTheme.body(
          size: 11,
          color: Colors.white,
          weight: FontWeight.w900,
        ),
      ),
    );
  }
}