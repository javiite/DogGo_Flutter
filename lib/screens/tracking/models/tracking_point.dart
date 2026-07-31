class TrackingPoint {
  final int? id;
  final double latitude;
  final double longitude;
  final DateTime? recordedAt;
  final double? accuracy;
  final double? speed;
  final Map<String, dynamic> rawData;

  const TrackingPoint({
    this.id,
    required this.latitude,
    required this.longitude,
    this.recordedAt,
    this.accuracy,
    this.speed,
    this.rawData = const {},
  });

  factory TrackingPoint.fromMap(
    Map<String, dynamic> map,
  ) {
    final latitude = _decimal(
      _value(
        map,
        const [
          'latitud',
          'Latitud',
          'latitudActual',
          'LatitudActual',
          'latitude',
          'Latitude',
          'lat',
          'Lat',
        ],
      ),
    );

    final longitude = _decimal(
      _value(
        map,
        const [
          'longitud',
          'Longitud',
          'longitudActual',
          'LongitudActual',
          'longitude',
          'Longitude',
          'lng',
          'Lng',
          'lon',
          'Lon',
        ],
      ),
    );

    if (!_validCoordinates(
      latitude,
      longitude,
    )) {
      throw const FormatException(
        'El punto GPS no contiene coordenadas válidas.',
      );
    }

    return TrackingPoint(
      id: _integer(
        _value(
          map,
          const [
            'id',
            'Id',
            'ubicacionId',
            'UbicacionId',
            'trackingId',
            'TrackingId',
          ],
        ),
      ),
      latitude: latitude!,
      longitude: longitude!,
      recordedAt: _dateTime(
        _value(
          map,
          const [
            'fecha',
            'Fecha',
            'fechaRegistro',
            'FechaRegistro',
            'timestamp',
            'Timestamp',
            'createdAt',
            'CreatedAt',
          ],
        ),
      ),
      accuracy: _decimal(
        _value(
          map,
          const [
            'precision',
            'Precision',
            'precisión',
            'Precisión',
            'accuracy',
            'Accuracy',
          ],
        ),
      ),
      speed: _decimal(
        _value(
          map,
          const [
            'velocidad',
            'Velocidad',
            'speed',
            'Speed',
          ],
        ),
      ),
      rawData: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(map),
      ),
    );
  }

  String get coordinatesLabel {
    return '${latitude.toStringAsFixed(6)}, '
        '${longitude.toStringAsFixed(6)}';
  }

  String get timeLabel {
    final date = recordedAt?.toLocal();

    if (date == null) {
      return 'Hora no disponible';
    }

    final hour =
        date.hour.toString().padLeft(2, '0');
    final minute =
        date.minute.toString().padLeft(2, '0');
    final second =
        date.second.toString().padLeft(2, '0');

    return '$hour:$minute:$second';
  }

  String get fullDateLabel {
    final date = recordedAt?.toLocal();

    if (date == null) {
      return 'Fecha no disponible';
    }

    final day =
        date.day.toString().padLeft(2, '0');
    final month =
        date.month.toString().padLeft(2, '0');
    final hour =
        date.hour.toString().padLeft(2, '0');
    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} '
        '$hour:$minute';
  }

  String get stableKey {
    if (id != null) {
      return 'id:$id';
    }

    return '${latitude.toStringAsFixed(7)}|'
        '${longitude.toStringAsFixed(7)}|'
        '${recordedAt?.toIso8601String() ?? ''}';
  }

  static List<TrackingPoint> listFrom(
    dynamic value,
  ) {
    if (value is! List) {
      return const [];
    }

    final points = <TrackingPoint>[];
    final keys = <String>{};

    for (final item in value.whereType<Map>()) {
      try {
        final point = TrackingPoint.fromMap(
          Map<String, dynamic>.from(item),
        );

        if (keys.add(point.stableKey)) {
          points.add(point);
        }
      } catch (_) {
        // Los puntos inválidos no deben romper
        // el resto del recorrido.
      }
    }

    points.sort((first, second) {
      final firstDate = first.recordedAt;
      final secondDate = second.recordedAt;

      if (firstDate == null &&
          secondDate == null) {
        return 0;
      }

      if (firstDate == null) {
        return -1;
      }

      if (secondDate == null) {
        return 1;
      }

      return firstDate.compareTo(secondDate);
    });

    return List<TrackingPoint>.unmodifiable(
      points,
    );
  }

  static bool _validCoordinates(
    double? latitude,
    double? longitude,
  ) {
    if (latitude == null ||
        longitude == null) {
      return false;
    }

    if (latitude == 0 && longitude == 0) {
      return false;
    }

    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  static dynamic _value(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];

      if (value != null) {
        return value;
      }
    }

    return null;
  }

  static int? _integer(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString().trim(),
    );
  }

  static double? _decimal(dynamic value) {
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

  static DateTime? _dateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value?.toString() ?? '',
    );
  }
}