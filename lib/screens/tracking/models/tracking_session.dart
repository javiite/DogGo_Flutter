class TrackingSession {
  final bool active;
  final int walkId;
  final String petName;
  final String walkerName;
  final double? latitude;
  final double? longitude;
  final DateTime? lastSentAt;

  const TrackingSession({
    required this.active,
    required this.walkId,
    required this.petName,
    required this.walkerName,
    this.latitude,
    this.longitude,
    this.lastSentAt,
  });

  factory TrackingSession.fromMap(
    Map<String, dynamic> map,
  ) {
    return TrackingSession(
      active: _boolean(map['activo']),
      walkId: _integer(
            map['paseoId'] ??
                map['PaseoId'],
          ) ??
          0,
      petName: _text(
        map['nombrePerro'],
        fallback: 'Mascota',
      ),
      walkerName: _text(
        map['nombrePaseador'],
        fallback: 'Paseador',
      ),
      latitude: _decimal(
        map['latitud'] ??
            map['Latitud'],
      ),
      longitude: _decimal(
        map['longitud'] ??
            map['Longitud'],
      ),
      lastSentAt: _dateTime(
        map['ultimoEnvio'] ??
            map['UltimoEnvio'],
      ),
    );
  }

  bool get hasValidWalk {
    return walkId > 0;
  }

  bool get hasCoordinates {
    final lat = latitude;
    final lng = longitude;

    if (lat == null || lng == null) {
      return false;
    }

    if (lat == 0 && lng == 0) {
      return false;
    }

    return lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  String get coordinatesLabel {
    if (!hasCoordinates) {
      return 'Sin ubicación registrada';
    }

    return '${latitude!.toStringAsFixed(6)}, '
        '${longitude!.toStringAsFixed(6)}';
  }

  String get timeLabel {
    final date = lastSentAt?.toLocal();

    if (date == null) {
      return 'Aún no enviada';
    }

    final hour =
        date.hour.toString().padLeft(2, '0');
    final minute =
        date.minute.toString().padLeft(2, '0');
    final second =
        date.second.toString().padLeft(2, '0');

    return '$hour:$minute:$second';
  }

  String get stableSendKey {
    return lastSentAt?.toIso8601String() ?? '';
  }

  TrackingSession copyWith({
    bool? active,
    int? walkId,
    String? petName,
    String? walkerName,
    double? latitude,
    bool clearLatitude = false,
    double? longitude,
    bool clearLongitude = false,
    DateTime? lastSentAt,
    bool clearLastSentAt = false,
  }) {
    return TrackingSession(
      active: active ?? this.active,
      walkId: walkId ?? this.walkId,
      petName: petName ?? this.petName,
      walkerName:
          walkerName ?? this.walkerName,
      latitude: clearLatitude
          ? null
          : latitude ?? this.latitude,
      longitude: clearLongitude
          ? null
          : longitude ?? this.longitude,
      lastSentAt: clearLastSentAt
          ? null
          : lastSentAt ?? this.lastSentAt,
    );
  }

  static String _text(
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

  static bool _boolean(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text =
        value?.toString().trim().toLowerCase();

    return const {
      'true',
      '1',
      'sí',
      'si',
      'yes',
    }.contains(text);
  }
}