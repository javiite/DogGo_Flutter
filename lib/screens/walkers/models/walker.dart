class Walker {
  final int id;
  final String name;
  final String email;
  final String description;
  final String serviceZone;
  final List<String> zones;
  final double? hourlyRate;
  final double rating;
  final int experienceYears;
  final int reviewCount;
  final int completedWalks;
  final bool available;
  final bool verified;
  final String? photoPath;
  final String? stateName;
  final String? municipalityName;
  final double? distanceKm;
  final int serviceRadiusKm;
  final bool withinCoverage;
  final String locationMatch;
  final Map<String, dynamic> rawData;

  const Walker({
    required this.id,
    required this.name,
    required this.email,
    required this.description,
    required this.serviceZone,
    required this.zones,
    required this.hourlyRate,
    required this.rating,
    required this.experienceYears,
    required this.reviewCount,
    required this.completedWalks,
    required this.available,
    required this.verified,
    required this.photoPath,
    required this.stateName,
    required this.municipalityName,
    required this.distanceKm,
    required this.serviceRadiusKm,
    required this.withinCoverage,
    required this.locationMatch,
    required this.rawData,
  });

  factory Walker.fromMap(Map<String, dynamic> map) {
    final zone = _text(
      _deepValue(map, const [
        'zonaServicio',
        'ZonaServicio',
        'zona',
        'Zona',
        'zonas',
        'Zonas',
        'serviceZone',
        'ServiceZone',
      ]),
      fallback: 'Sin zona registrada',
    );

    return Walker(
      id:
          _integer(
            _deepValue(map, const [
              'id',
              'Id',
              'paseadorId',
              'PaseadorId',
              'usuarioId',
              'UsuarioId',
              'walkerId',
              'WalkerId',
            ]),
          ) ??
          0,
      name: _walkerName(map),
      email: _text(
        _deepValue(map, const ['email', 'Email', 'correo', 'Correo']),
        fallback: 'Correo no disponible',
      ),
      description: _text(
        _deepValue(map, const [
          'descripcion',
          'Descripcion',
          'descripción',
          'bio',
          'Bio',
          'description',
          'Description',
        ]),
        fallback: 'Sin descripción registrada.',
      ),
      serviceZone: zone,
      zones: _splitZones(zone),
      hourlyRate: _decimal(
        _deepValue(map, const [
          'tarifaPorHora',
          'TarifaPorHora',
          'tarifa',
          'Tarifa',
          'hourlyRate',
          'HourlyRate',
        ]),
      ),
      rating:
          _decimal(
            _deepValue(map, const [
              'calificacionPromedio',
              'CalificacionPromedio',
              'calificaciónPromedio',
              'rating',
              'Rating',
              'calificacion',
              'Calificacion',
            ]),
          ) ??
          0,
      experienceYears:
          _integer(
            _deepValue(map, const [
              'experienciaAnios',
              'ExperienciaAnios',
              'experienciaAños',
              'ExperienciaAños',
              'experiencia',
              'Experiencia',
              'experienceYears',
              'ExperienceYears',
            ]),
          ) ??
          0,
      reviewCount:
          _integer(
            _deepValue(map, const [
              'cantidadResenas',
              'CantidadResenas',
              'cantidadReseñas',
              'CantidadReseñas',
              'totalResenas',
              'TotalResenas',
              'reviewCount',
              'ReviewCount',
            ]),
          ) ??
          0,
      completedWalks:
          _integer(
            _deepValue(map, const [
              'paseosCompletados',
              'PaseosCompletados',
              'cantidadPaseos',
              'CantidadPaseos',
              'totalPaseos',
              'TotalPaseos',
              'completedWalks',
              'CompletedWalks',
            ]),
          ) ??
          0,
      available: _boolean(
        _deepValue(map, const [
          'disponible',
          'Disponible',
          'available',
          'Available',
        ]),
        fallback: true,
      ),
      verified: _boolean(
        _deepValue(map, const [
          'verificado',
          'Verificado',
          'esVerificado',
          'EsVerificado',
          'verified',
          'Verified',
        ]),
      ),
      photoPath: _nullableText(
        _deepValue(map, const [
          'fotoUrl',
          'FotoUrl',
          'fotoPerfilUrl',
          'FotoPerfilUrl',
          'imagenUrl',
          'ImagenUrl',
          'foto',
          'Foto',
          'photoUrl',
          'PhotoUrl',
        ]),
      ),
      stateName: _nullableText(
        _deepValue(map, const ['estadoNombre', 'EstadoNombre']),
      ),
      municipalityName: _nullableText(
        _deepValue(map, const ['municipioNombre', 'MunicipioNombre']),
      ),
      distanceKm: _decimal(
        _deepValue(map, const ['distanciaKm', 'DistanciaKm']),
      ),
      serviceRadiusKm:
          _integer(
            _deepValue(map, const ['radioServicioKm', 'RadioServicioKm']),
          ) ??
          10,
      withinCoverage: _boolean(
        _deepValue(map, const ['dentroDeCobertura', 'DentroDeCobertura']),
      ),
      locationMatch: _text(
        _deepValue(map, const [
          'coincidenciaUbicacion',
          'CoincidenciaUbicacion',
        ]),
        fallback: 'SinUbicacion',
      ),
      rawData: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(map),
      ),
    );
  }

  bool get hasValidId => id > 0;

  bool get hasPhoto {
    final value = photoPath?.trim();
    return value != null && value.isNotEmpty;
  }

  String get rateLabel {
    final rate = hourlyRate;

    if (rate == null) {
      return 'Tarifa no disponible';
    }

    return '\$${rate.toStringAsFixed(2)} / hora';
  }

  String get ratingLabel {
    if (rating <= 0) return 'Sin calificación';
    return rating.toStringAsFixed(1);
  }

  String get experienceLabel {
    if (experienceYears <= 0) {
      return 'Sin experiencia registrada';
    }

    if (experienceYears == 1) {
      return '1 año de experiencia';
    }

    return '$experienceYears años de experiencia';
  }

  String get proximityLabel {
    if (distanceKm != null) return '${distanceKm!.toStringAsFixed(1)} km de ti';
    if (locationMatch == 'MismoMunicipio') return 'En tu municipio';
    if (locationMatch == 'MismoEstado') return 'En tu estado';
    return municipalityName ?? serviceZone;
  }

  String get reviewCountLabel {
    if (reviewCount == 0) return 'Sin reseñas';
    if (reviewCount == 1) return '1 reseña';

    return '$reviewCount reseñas';
  }

  String get completedWalksLabel {
    if (completedWalks == 0) {
      return 'Sin paseos registrados';
    }

    if (completedWalks == 1) {
      return '1 paseo completado';
    }

    return '$completedWalks paseos completados';
  }

  String get initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return 'DG';

    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }

    return '${words.first.substring(0, 1)}'
            '${words.last.substring(0, 1)}'
        .toUpperCase();
  }

  String? publicPhotoUrl(String? baseUrl) {
    final path = photoPath?.trim();

    if (path == null || path.isEmpty || path.toLowerCase() == 'null') {
      return null;
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    final server = baseUrl?.trim() ?? '';

    if (server.isEmpty) return path;

    final cleanServer = server.endsWith('/')
        ? server.substring(0, server.length - 1)
        : server;

    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanServer$cleanPath';
  }

  Map<String, dynamic> toNavigationMap() {
    return {
      ...rawData,
      'id': id,
      'paseadorId': id,
      'nombre': name,
      'nombreCompleto': name,
      'email': email,
      'descripcion': description,
      'zonaServicio': serviceZone,
      'tarifaPorHora': hourlyRate,
      'calificacionPromedio': rating,
      'experienciaAnios': experienceYears,
      'cantidadResenas': reviewCount,
      'paseosCompletados': completedWalks,
      'disponible': available,
      'verificado': verified,
      'fotoUrl': photoPath,
      'estadoNombre': stateName,
      'municipioNombre': municipalityName,
      'distanciaKm': distanceKm,
      'radioServicioKm': serviceRadiusKm,
      'dentroDeCobertura': withinCoverage,
      'coincidenciaUbicacion': locationMatch,
    };
  }

  static List<Walker> listFrom(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((item) => Walker.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  static String _walkerName(Map<String, dynamic> map) {
    final complete = _text(
      _deepValue(map, const [
        'nombreCompleto',
        'NombreCompleto',
        'fullName',
        'FullName',
      ]),
    );

    if (complete.isNotEmpty) return complete;

    final firstName = _text(
      _deepValue(map, const [
        'nombre',
        'Nombre',
        'nombrePaseador',
        'NombrePaseador',
        'name',
        'Name',
      ]),
    );

    final lastName = _text(
      _deepValue(map, const ['apellido', 'Apellido', 'lastName', 'LastName']),
    );

    final result = '$firstName $lastName'.trim();

    return result.isEmpty ? 'Paseador DogGo' : result;
  }

  static List<String> _splitZones(String value) {
    if (value.trim().isEmpty || value == 'Sin zona registrada') {
      return const [];
    }

    final zones = value
        .split(RegExp(r'[,;|]'))
        .map((zone) => zone.trim())
        .where((zone) => zone.isNotEmpty)
        .toSet()
        .toList();

    zones.sort();

    return List<String>.unmodifiable(zones);
  }

  static dynamic _deepValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];

      if (value != null) return value;
    }

    const nestedKeys = [
      'usuario',
      'Usuario',
      'user',
      'User',
      'perfil',
      'Perfil',
    ];

    for (final nestedKey in nestedKeys) {
      final nested = map[nestedKey];

      if (nested is Map) {
        final nestedMap = Map<String, dynamic>.from(nested);

        for (final key in keys) {
          final value = nestedMap[key];

          if (value != null) return value;
        }
      }
    }

    return null;
  }

  static String _text(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  static String? _nullableText(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    return text;
  }

  static int? _integer(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();

    return int.tryParse(value.toString().trim());
  }

  static double? _decimal(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString().trim().replaceAll(',', '.'));
  }

  static bool _boolean(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value?.toString().trim().toLowerCase();

    if (text == null || text.isEmpty || text == 'null') {
      return fallback;
    }

    return const {
      'true',
      '1',
      'sí',
      'si',
      'yes',
      'activo',
      'disponible',
      'verificado',
    }.contains(text);
  }
}
