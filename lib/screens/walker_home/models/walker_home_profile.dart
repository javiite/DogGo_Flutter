class WalkerHomeProfile {
  final String description;
  final String serviceZone;
  final double hourlyRate;
  final int experienceYears;
  final bool available;
  final double rating;
  final int reviewCount;
  final String photoUrl;

  const WalkerHomeProfile({
    this.description = '',
    this.serviceZone = '',
    this.hourlyRate = 0,
    this.experienceYears = 0,
    this.available = false,
    this.rating = 0,
    this.reviewCount = 0,
    this.photoUrl = '',
  });

  factory WalkerHomeProfile.fromMap(
    Map<String, dynamic> map, {
    String? baseUrl,
  }) {
    final profile = map;

    return WalkerHomeProfile(
      description: _text(
        _value(
          profile,
          const ['descripcion'],
        ),
      ),
      serviceZone: _text(
        _value(
          profile,
          const ['zonaServicio'],
        ),
      ),
      hourlyRate: _double(
            _value(
              profile,
              const ['tarifaPorHora'],
            ),
          ) ??
          0,
      experienceYears: _int(
            _value(
              profile,
              const ['experienciaAnios'],
            ),
          ) ??
          0,
      available: _bool(
        _value(
          profile,
          const ['disponible'],
        ),
      ),
      rating: _double(
            _value(
              profile,
              const ['calificacionPromedio'],
            ),
          ) ??
          0,
      reviewCount: _int(
            _value(
              profile,
              const ['cantidadResenas'],
            ),
          ) ??
          0,
      photoUrl: _publicUrl(
        _value(
          profile,
          const ['fotoUrl'],
        ),
        baseUrl,
      ),
    );
  }

  bool get hasCompleteProfessionalData {
    return description.isNotEmpty &&
        serviceZone.isNotEmpty &&
        hourlyRate > 0 &&
        experienceYears >= 0;
  }

  int get completionPercentage {
    var completed = 0;

    if (description.isNotEmpty) {
      completed++;
    }

    if (serviceZone.isNotEmpty) {
      completed++;
    }

    if (hourlyRate > 0) {
      completed++;
    }

    if (experienceYears >= 0) {
      completed++;
    }

    if (photoUrl.isNotEmpty) {
      completed++;
    }

    return ((completed / 5) * 100).round();
  }

  WalkerHomeProfile copyWith({
    String? description,
    String? serviceZone,
    double? hourlyRate,
    int? experienceYears,
    bool? available,
    double? rating,
    int? reviewCount,
    String? photoUrl,
  }) {
    return WalkerHomeProfile(
      description:
          description ?? this.description,
      serviceZone:
          serviceZone ?? this.serviceZone,
      hourlyRate:
          hourlyRate ?? this.hourlyRate,
      experienceYears:
          experienceYears ??
              this.experienceYears,
      available:
          available ?? this.available,
      rating: rating ?? this.rating,
      reviewCount:
          reviewCount ?? this.reviewCount,
      photoUrl: photoUrl ?? this.photoUrl,
    );
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

  static String _text(dynamic value) {
    if (value == null) {
      return '';
    }

    final text = value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null') {
      return '';
    }

    return text;
  }

  static int? _int(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  static double? _double(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value
              ?.toString()
              .replaceAll(',', '.') ??
          '',
    );
  }

  static bool _bool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value
        ?.toString()
        .trim()
        .toLowerCase();

    return const {
      'true',
      '1',
      'sí',
      'si',
      'yes',
      'activo',
      'disponible',
    }.contains(text);
  }

  static String _publicUrl(
    dynamic value,
    String? baseUrl,
  ) {
    final path = _text(value);

    if (path.isEmpty) {
      return '';
    }

    if (path.startsWith('http://') ||
        path.startsWith('https://')) {
      return path;
    }

    final base = baseUrl
            ?.trim()
            .replaceAll(
              RegExp(r'/+$'),
              '',
            ) ??
        '';

    if (base.isEmpty) {
      return path;
    }

    final normalizedPath =
        path.startsWith('/')
            ? path
            : '/$path';

    return '$base$normalizedPath';
  }
}
