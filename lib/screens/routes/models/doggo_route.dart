import 'package:latlong2/latlong.dart';

class DoggoRoutePoint {
  final int id;
  final int order;
  final double latitude;
  final double longitude;
  final String type;
  final String? name;
  final int? alertRadiusMeters;
  final bool notifyOnArrival;
  final bool reached;
  final DateTime? reachedAt;

  const DoggoRoutePoint({
    this.id = 0,
    required this.order,
    required this.latitude,
    required this.longitude,
    this.type = 'Ruta',
    this.name,
    this.alertRadiusMeters,
    this.notifyOnArrival = false,
    this.reached = false,
    this.reachedAt,
  });

  factory DoggoRoutePoint.fromMap(
    Map<String, dynamic> map,
  ) {
    return DoggoRoutePoint(
      id: _integer(
        _value(map, const ['id']),
      ),
      order: _integer(
        _value(map, const ['orden']),
      ),
      latitude: _decimal(
        _value(
          map,
          const ['latitud'],
        ),
      ),
      longitude: _decimal(
        _value(
          map,
          const ['longitud'],
        ),
      ),
      type: _text(
        _value(map, const ['tipo']),
        fallback: 'Ruta',
      ),
      name: _nullableText(
        _value(map, const ['nombre']),
      ),
      alertRadiusMeters: _nullableInteger(
        _value(
          map,
          const ['radioAvisoMetros'],
        ),
      ),
      notifyOnArrival: _boolean(
        _value(
          map,
          const ['notificarAlLlegar'],
        ),
      ),
      reached: _boolean(
        _value(
          map,
          const ['alcanzado'],
        ),
      ),
      reachedAt: _date(
        _value(
          map,
          const ['fechaAlcanzado'],
        ),
      ),
    );
  }

  LatLng get position {
    return LatLng(latitude, longitude);
  }

  bool get isCheckpoint {
    return type.toLowerCase() == 'checkpoint';
  }

  bool get isBoundary {
    return type.toLowerCase() == 'limite';
  }

  String get displayName {
    final cleanName = name?.trim() ?? '';

    if (cleanName.isNotEmpty) {
      return cleanName;
    }

    if (isCheckpoint) {
      return 'Punto de aviso';
    }

    return 'Punto ${order + 1}';
  }

  DoggoRoutePoint copyWith({
    int? id,
    int? order,
    double? latitude,
    double? longitude,
    String? type,
    String? name,
    bool clearName = false,
    int? alertRadiusMeters,
    bool clearAlertRadius = false,
    bool? notifyOnArrival,
    bool? reached,
    DateTime? reachedAt,
    bool clearReachedAt = false,
  }) {
    return DoggoRoutePoint(
      id: id ?? this.id,
      order: order ?? this.order,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      name: clearName ? null : name ?? this.name,
      alertRadiusMeters: clearAlertRadius
          ? null
          : alertRadiusMeters ??
              this.alertRadiusMeters,
      notifyOnArrival:
          notifyOnArrival ?? this.notifyOnArrival,
      reached: reached ?? this.reached,
      reachedAt: clearReachedAt
          ? null
          : reachedAt ?? this.reachedAt,
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'orden': order,
      'latitud': latitude,
      'longitud': longitude,
      'tipo': type,
      if (name?.trim().isNotEmpty ?? false)
        'nombre': name!.trim(),
      if (alertRadiusMeters != null)
        'radioAvisoMetros':
            alertRadiusMeters,
      'notificarAlLlegar':
          notifyOnArrival,
    };
  }
}

class SavedDoggoRoute {
  final int id;
  final String name;
  final String? description;
  final String controlMode;
  final int allowedRadiusMeters;
  final String? startAddress;
  final String? city;
  final String? municipality;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int pointCount;
  final int checkpointCount;
  final List<DoggoRoutePoint> points;

  const SavedDoggoRoute({
    required this.id,
    required this.name,
    this.description,
    this.controlMode = 'Ruta',
    this.allowedRadiusMeters = 100,
    this.startAddress,
    this.city,
    this.municipality,
    this.active = true,
    this.createdAt,
    this.updatedAt,
    this.pointCount = 0,
    this.checkpointCount = 0,
    this.points = const [],
  });

  factory SavedDoggoRoute.fromMap(
    Map<String, dynamic> map,
  ) {
    final points = _mapList(
      _value(map, const ['puntos']),
    ).map(DoggoRoutePoint.fromMap).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return SavedDoggoRoute(
      id: _integer(
        _value(map, const ['id']),
      ),
      name: _text(
        _value(map, const ['nombre']),
        fallback: 'Ruta guardada',
      ),
      description: _nullableText(
        _value(
          map,
          const ['descripcion'],
        ),
      ),
      controlMode: _text(
        _value(
          map,
          const ['modoControl'],
        ),
        fallback: 'Ruta',
      ),
      allowedRadiusMeters: _integer(
        _value(
          map,
          const ['radioPermitidoMetros'],
        ),
        fallback: 100,
      ),
      startAddress: _nullableText(
        _value(
          map,
          const ['direccionInicio'],
        ),
      ),
      city: _nullableText(
        _value(map, const ['ciudad']),
      ),
      municipality: _nullableText(
        _value(
          map,
          const ['municipio'],
        ),
      ),
      active: _boolean(
        _value(map, const ['activa']),
        fallback: true,
      ),
      createdAt: _date(
        _value(
          map,
          const ['fechaCreacion'],
        ),
      ),
      updatedAt: _date(
        _value(
          map,
          const ['fechaActualizacion'],
        ),
      ),
      pointCount: _integer(
        _value(
          map,
          const ['cantidadPuntos'],
        ),
        fallback: points.length,
      ),
      checkpointCount: _integer(
        _value(
          map,
          const ['cantidadCheckpoints'],
        ),
        fallback:
            points.where((p) => p.isCheckpoint).length,
      ),
      points: points,
    );
  }

  bool get isArea {
    return controlMode.toLowerCase() == 'area';
  }

  List<DoggoRoutePoint> get pathPoints {
    return points
        .where((point) => !point.isCheckpoint)
        .toList(growable: false);
  }

  List<DoggoRoutePoint> get checkpoints {
    return points
        .where((point) => point.isCheckpoint)
        .toList(growable: false);
  }
}

class DoggoRouteAlert {
  final int id;
  final String type;
  final String message;
  final double latitude;
  final double longitude;
  final double? routeDistanceMeters;
  final double? gpsAccuracyMeters;
  final DateTime? createdAt;
  final bool resolved;
  final DateTime? resolvedAt;

  const DoggoRouteAlert({
    required this.id,
    required this.type,
    required this.message,
    required this.latitude,
    required this.longitude,
    this.routeDistanceMeters,
    this.gpsAccuracyMeters,
    this.createdAt,
    this.resolved = false,
    this.resolvedAt,
  });

  factory DoggoRouteAlert.fromMap(
    Map<String, dynamic> map,
  ) {
    return DoggoRouteAlert(
      id: _integer(
        _value(map, const ['id']),
      ),
      type: _text(
        _value(map, const ['tipo']),
      ),
      message: _text(
        _value(map, const ['mensaje']),
      ),
      latitude: _decimal(
        _value(
          map,
          const ['latitud'],
        ),
      ),
      longitude: _decimal(
        _value(
          map,
          const ['longitud'],
        ),
      ),
      routeDistanceMeters: _nullableDecimal(
        _value(
          map,
          const ['distanciaRutaMetros'],
        ),
      ),
      gpsAccuracyMeters: _nullableDecimal(
        _value(
          map,
          const ['precisionGpsMetros'],
        ),
      ),
      createdAt: _date(
        _value(
          map,
          const ['fechaCreacion'],
        ),
      ),
      resolved: _boolean(
        _value(
          map,
          const ['resuelta'],
        ),
      ),
      resolvedAt: _date(
        _value(
          map,
          const ['fechaResolucion'],
        ),
      ),
    );
  }

  LatLng get position {
    return LatLng(latitude, longitude);
  }
}

class PlannedDoggoRoute {
  final int id;
  final int walkId;
  final int? savedRouteId;
  final String name;
  final String controlMode;
  final int allowedRadiusMeters;
  final bool active;
  final bool outsideRoute;
  final int consecutiveOutsideReadings;
  final DateTime? assignedAt;
  final List<DoggoRoutePoint> points;
  final List<DoggoRouteAlert> alerts;

  const PlannedDoggoRoute({
    required this.id,
    required this.walkId,
    this.savedRouteId,
    required this.name,
    this.controlMode = 'Ruta',
    this.allowedRadiusMeters = 100,
    this.active = true,
    this.outsideRoute = false,
    this.consecutiveOutsideReadings = 0,
    this.assignedAt,
    this.points = const [],
    this.alerts = const [],
  });

  factory PlannedDoggoRoute.fromMap(
    Map<String, dynamic> map,
  ) {
    final points = _mapList(
      _value(map, const ['puntos']),
    ).map(DoggoRoutePoint.fromMap).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final alerts = _mapList(
      _value(map, const ['alertas']),
    ).map(DoggoRouteAlert.fromMap).toList();

    return PlannedDoggoRoute(
      id: _integer(
        _value(map, const ['id']),
      ),
      walkId: _integer(
        _value(
          map,
          const ['paseoId'],
        ),
      ),
      savedRouteId: _nullableInteger(
        _value(
          map,
          const ['rutaGuardadaId'],
        ),
      ),
      name: _text(
        _value(map, const ['nombre']),
        fallback: 'Ruta del paseo',
      ),
      controlMode: _text(
        _value(
          map,
          const ['modoControl'],
        ),
        fallback: 'Ruta',
      ),
      allowedRadiusMeters: _integer(
        _value(
          map,
          const ['radioPermitidoMetros'],
        ),
        fallback: 100,
      ),
      active: _boolean(
        _value(map, const ['activa']),
        fallback: true,
      ),
      outsideRoute: _boolean(
        _value(
          map,
          const ['fueraDeRuta'],
        ),
      ),
      consecutiveOutsideReadings: _integer(
        _value(
          map,
          const ['lecturasFueraConsecutivas'],
        ),
      ),
      assignedAt: _date(
        _value(
          map,
          const ['fechaAsignacion'],
        ),
      ),
      points: points,
      alerts: alerts,
    );
  }

  bool get isArea {
    return controlMode.toLowerCase() == 'area';
  }

  List<DoggoRoutePoint> get pathPoints {
    return points
        .where((point) => !point.isCheckpoint)
        .toList(growable: false);
  }

  List<DoggoRoutePoint> get checkpoints {
    return points
        .where((point) => point.isCheckpoint)
        .toList(growable: false);
  }
}

class DoggoRouteDraft {
  final String name;
  final String? description;
  final String controlMode;
  final int allowedRadiusMeters;
  final String? startAddress;
  final String? city;
  final String? municipality;
  final List<DoggoRoutePoint> points;

  const DoggoRouteDraft({
    required this.name,
    this.description,
    this.controlMode = 'Ruta',
    this.allowedRadiusMeters = 100,
    this.startAddress,
    this.city,
    this.municipality,
    required this.points,
  });

  bool get isArea {
    return controlMode.toLowerCase() == 'area';
  }

  Map<String, dynamic> toSavedRouteJson() {
    return {
      'nombre': name.trim(),
      if (description?.trim().isNotEmpty ?? false)
        'descripcion': description!.trim(),
      'modoControl': controlMode,
      'radioPermitidoMetros':
          allowedRadiusMeters,
      if (startAddress?.trim().isNotEmpty ?? false)
        'direccionInicio':
            startAddress!.trim(),
      if (city?.trim().isNotEmpty ?? false)
        'ciudad': city!.trim(),
      if (municipality?.trim().isNotEmpty ??
          false)
        'municipio': municipality!.trim(),
      'puntos': points
          .map((point) => point.toRequestJson())
          .toList(growable: false),
    };
  }

  Map<String, dynamic> toAssignmentJson({
    bool saveAsTemplate = false,
    String? templateName,
  }) {
    return {
      'nombre': name.trim(),
      'modoControl': controlMode,
      'radioPermitidoMetros':
          allowedRadiusMeters,
      'puntos': points
          .map((point) => point.toRequestJson())
          .toList(growable: false),
      'guardarComoPlantilla':
          saveAsTemplate,
      if (templateName?.trim().isNotEmpty ?? false)
        'nombrePlantilla':
            templateName!.trim(),
    };
  }
}

dynamic _value(
  Map<String, dynamic> map,
  List<String> keys,
) {
  for (final key in keys) {
    if (map.containsKey(key) &&
        map[key] != null) {
      return map[key];
    }
  }

  return null;
}

List<Map<String, dynamic>> _mapList(
  dynamic value,
) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map(Map<String, dynamic>.from)
      .toList(growable: false);
}

String _text(
  dynamic value, {
  String fallback = '',
}) {
  final text = value?.toString().trim() ?? '';

  if (text.isEmpty ||
      text.toLowerCase() == 'null') {
    return fallback;
  }

  return text;
}

String? _nullableText(dynamic value) {
  final text = _text(value);

  return text.isEmpty ? null : text;
}

int _integer(
  dynamic value, {
  int fallback = 0,
}) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
        value?.toString().trim() ?? '',
      ) ??
      fallback;
}

int? _nullableInteger(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString().trim());
}

double _decimal(
  dynamic value, {
  double fallback = 0,
}) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
        value
            ?.toString()
            .trim()
            .replaceAll(',', '.') ??
        '',
      ) ??
      fallback;
}

double? _nullableDecimal(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
    value
        .toString()
        .trim()
        .replaceAll(',', '.'),
  );
}

bool _boolean(
  dynamic value, {
  bool fallback = false,
}) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final text =
      value?.toString().trim().toLowerCase();

  if (text == 'true' ||
      text == '1' ||
      text == 'si' ||
      text == 'sí') {
    return true;
  }

  if (text == 'false' ||
      text == '0' ||
      text == 'no') {
    return false;
  }

  return fallback;
}

DateTime? _date(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(
    value.toString().trim(),
  )?.toLocal();
}
