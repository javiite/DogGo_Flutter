class HomeSummary {
  final int walks;
  final Duration totalDuration;
  final double distanceKilometers;

  const HomeSummary({
    this.walks = 0,
    this.totalDuration = Duration.zero,
    this.distanceKilometers = 0,
  });

  bool get isEmpty {
    return walks == 0 &&
        totalDuration == Duration.zero &&
        distanceKilometers == 0;
  }

  String get formattedDuration {
    final totalMinutes = totalDuration.inMinutes;

    if (totalMinutes <= 0) {
      return '0 min';
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes.remainder(60);

    if (hours == 0) {
      return '$minutes min';
    }

    if (minutes == 0) {
      return '$hours h';
    }

    return '$hours h $minutes min';
  }

  String get formattedDistance {
    if (distanceKilometers <= 0) {
      return '0 km';
    }

    final hasDecimals =
        distanceKilometers != distanceKilometers.roundToDouble();

    return hasDecimals
        ? '${distanceKilometers.toStringAsFixed(1)} km'
        : '${distanceKilometers.toStringAsFixed(0)} km';
  }

  HomeSummary copyWith({
    int? walks,
    Duration? totalDuration,
    double? distanceKilometers,
  }) {
    return HomeSummary(
      walks: walks ?? this.walks,
      totalDuration: totalDuration ?? this.totalDuration,
      distanceKilometers:
          distanceKilometers ?? this.distanceKilometers,
    );
  }

  factory HomeSummary.fromWalks(
    Iterable<Map<String, dynamic>> walks, {
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    final weekEnd = weekStart.add(const Duration(days: 7));

    var count = 0;
    var totalMinutes = 0;
    var totalDistance = 0.0;

    for (final walk in walks) {
      final status = _normalize(
        _firstValue(
              walk,
              const ['estado', 'Estado', 'status', 'Status'],
            )?.toString() ??
            '',
      );

      if (!_isCompletedStatus(status)) {
        continue;
      }

      final date = _toDateTime(
        _firstValue(
          walk,
          const [
            'fechaFin',
            'FechaFin',
            'fechaProgramada',
            'FechaProgramada',
            'fecha',
            'Fecha',
          ],
        ),
      );

      if (date == null ||
          date.isBefore(weekStart) ||
          !date.isBefore(weekEnd)) {
        continue;
      }

      count++;

      totalMinutes += _extractMinutes(walk);
      totalDistance += _extractDistance(walk);
    }

    return HomeSummary(
      walks: count,
      totalDuration: Duration(minutes: totalMinutes),
      distanceKilometers: totalDistance,
    );
  }

  static int _extractMinutes(Map<String, dynamic> walk) {
    final directMinutes = _toInt(
      _firstValue(
        walk,
        const [
          'duracionMinutos',
          'DuracionMinutos',
          'minutos',
          'Minutos',
        ],
      ),
    );

    if (directMinutes != null && directMinutes > 0) {
      return directMinutes;
    }

    final start = _toDateTime(
      _firstValue(
        walk,
        const [
          'fechaInicio',
          'FechaInicio',
          'horaInicio',
          'HoraInicio',
        ],
      ),
    );

    final end = _toDateTime(
      _firstValue(
        walk,
        const [
          'fechaFin',
          'FechaFin',
          'horaFin',
          'HoraFin',
        ],
      ),
    );

    if (start == null || end == null || !end.isAfter(start)) {
      return 0;
    }

    return end.difference(start).inMinutes;
  }

  static double _extractDistance(Map<String, dynamic> walk) {
    final value = _firstValue(
      walk,
      const [
        'distanciaKm',
        'DistanciaKm',
        'distanciaKilometros',
        'DistanciaKilometros',
        'distanceKm',
        'DistanceKm',
      ],
    );

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _isCompletedStatus(String status) {
    return status == 'finalizado' ||
        status == 'finalizada' ||
        status == 'completado' ||
        status == 'completada' ||
        status == 'completed' ||
        status == 'finished';
  }

  static dynamic _firstValue(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) {
        return map[key];
      }
    }

    return null;
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value?.toString() ?? '');
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[\s_\-]'), '');
  }
}