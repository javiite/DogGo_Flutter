class HomeWalker {
  final int? id;
  final String name;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final bool verified;
  final Map<String, dynamic> rawData;

  const HomeWalker({
    this.id,
    required this.name,
    required this.imageUrl,
    this.rating = 0,
    this.reviewCount = 0,
    this.verified = false,
    this.rawData = const {},
  });

  bool get hasImage {
    return imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://');
  }

  String get ratingLabel {
    if (rating <= 0) {
      return 'Sin calificaciones';
    }

    return rating.toStringAsFixed(1);
  }

  factory HomeWalker.fromMap(
    Map<String, dynamic> map, {
    String? baseUrl,
  }) {
    final nestedUser = _safeMap(
      _firstValue(
        map,
        const [
          'usuario',
          'Usuario',
          'user',
          'User',
          'paseador',
          'Paseador',
        ],
      ),
    );

    final combined = <String, dynamic>{
      ...nestedUser,
      ...map,
    };

    final imageValue = _firstValue(
      combined,
      const [
        'fotoMiniaturaUrl',
        'FotoMiniaturaUrl',
        'fotoPerfilUrl',
        'FotoPerfilUrl',
        'fotoUrl',
        'FotoUrl',
        'imagenUrl',
        'ImagenUrl',
      ],
    );

    return HomeWalker(
      id: _toInt(
        _firstValue(
          combined,
          const [
            'paseadorId',
            'PaseadorId',
            'id',
            'Id',
            'usuarioId',
            'UsuarioId',
          ],
        ),
      ),
      name: _fullName(combined),
      imageUrl: _resolveUrl(
        imageValue?.toString() ?? '',
        baseUrl,
      ),
      rating: _toDouble(
            _firstValue(
              combined,
              const [
                'calificacionPromedio',
                'CalificacionPromedio',
                'promedioCalificacion',
                'PromedioCalificacion',
                'rating',
                'Rating',
              ],
            ),
          ) ??
          0,
      reviewCount: _toInt(
            _firstValue(
              combined,
              const [
                'cantidadResenas',
                'CantidadResenas',
                'cantidadReseñas',
                'CantidadReseñas',
                'reviewCount',
                'ReviewCount',
              ],
            ),
          ) ??
          0,
      verified: _toBool(
        _firstValue(
          combined,
          const [
            'verificado',
            'Verificado',
            'estaVerificado',
            'EstaVerificado',
            'verified',
            'Verified',
          ],
        ),
      ),
      rawData: Map<String, dynamic>.unmodifiable(map),
    );
  }

  static String _fullName(Map<String, dynamic> map) {
    final directName = _firstValue(
      map,
      const [
        'nombreCompleto',
        'NombreCompleto',
        'name',
        'Name',
      ],
    )?.toString().trim();

    if (directName != null && directName.isNotEmpty) {
      return directName;
    }

    final firstName = _firstValue(
      map,
      const ['nombre', 'Nombre'],
    )?.toString().trim();

    final lastName = _firstValue(
      map,
      const [
        'apellido',
        'Apellido',
        'apellidos',
        'Apellidos',
      ],
    )?.toString().trim();

    final complete = [
      if (firstName != null && firstName.isNotEmpty) firstName,
      if (lastName != null && lastName.isNotEmpty) lastName,
    ].join(' ');

    return complete.isEmpty ? 'Paseador por confirmar' : complete;
  }

  static String _resolveUrl(
    String value,
    String? baseUrl,
  ) {
    final cleanValue = value.trim();

    if (cleanValue.isEmpty) {
      return '';
    }

    if (cleanValue.startsWith('http://') ||
        cleanValue.startsWith('https://')) {
      return cleanValue;
    }

    final cleanBase = baseUrl?.trim() ?? '';

    if (cleanBase.isEmpty) {
      return cleanValue;
    }

    final normalizedBase = cleanBase.endsWith('/')
        ? cleanBase.substring(0, cleanBase.length - 1)
        : cleanBase;

    final normalizedPath = cleanValue.startsWith('/')
        ? cleanValue
        : '/$cleanValue';

    return '$normalizedBase$normalizedPath';
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

  static Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return const {};
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

  static double? _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized =
        value?.toString().trim().toLowerCase() ?? '';

    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'si' ||
        normalized == 'sí';
  }
}