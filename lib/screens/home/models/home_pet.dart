class HomePet {
  final int? id;
  final String name;
  final String breed;
  final int? age;
  final String size;
  final String notes;
  final String imageUrl;
  final Map<String, dynamic> rawData;

  const HomePet({
    this.id,
    required this.name,
    required this.breed,
    this.age,
    required this.size,
    required this.notes,
    required this.imageUrl,
    this.rawData = const {},
  });

  String get ageLabel {
    if (age == null || age! < 0) {
      return 'Edad por confirmar';
    }

    if (age == 1) {
      return '1 año';
    }

    return '$age años';
  }

  bool get hasImage {
    return imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://');
  }

  factory HomePet.fromMap(
    Map<String, dynamic> map, {
    String? baseUrl,
  }) {
    final source = _unwrap(map);

    final imageValue = _firstValue(
      source,
      const [
        'fotoMiniaturaUrl',
        'FotoMiniaturaUrl',
        'fotoUrl',
        'FotoUrl',
        'imagenUrl',
        'ImagenUrl',
        'urlFoto',
        'UrlFoto',

        // Variantes usadas por paseos.
        'perroFotoUrl',
        'PerroFotoUrl',
        'perroImagenUrl',
        'PerroImagenUrl',
        'fotoPerroUrl',
        'FotoPerroUrl',
        'imagenPerroUrl',
        'ImagenPerroUrl',
      ],
    );

    return HomePet(
      id: _toInt(
        _firstValue(
          source,
          const [
            'id',
            'Id',
            'perroId',
            'PerroId',
            'mascotaId',
            'MascotaId',
          ],
        ),
      ),
      name: _text(
        _firstValue(
          source,
          const [
            'nombre',
            'Nombre',
            'name',
            'Name',
            'perroNombre',
            'PerroNombre',
            'nombrePerro',
            'NombrePerro',
          ],
        ),
        fallback: 'Mascota',
      ),
      breed: _text(
        _firstValue(
          source,
          const [
            'raza',
            'Raza',
            'breed',
            'Breed',
            'perroRaza',
            'PerroRaza',
            'razaPerro',
            'RazaPerro',
          ],
        ),
        fallback: 'Raza por confirmar',
      ),
      age: _toInt(
        _firstValue(
          source,
          const [
            'edad',
            'Edad',
            'age',
            'Age',
          ],
        ),
      ),
      size: _text(
        _firstValue(
          source,
          const [
            'tamano',
            'Tamano',
            'tamanio',
            'Tamanio',
            'tamaño',
            'Tamaño',
            'size',
            'Size',
          ],
        ),
        fallback: 'No especificado',
      ),
      notes: _text(
        _firstValue(
          source,
          const [
            'notas',
            'Notas',
            'observaciones',
            'Observaciones',
            'notes',
            'Notes',
          ],
        ),
        fallback: '',
      ),
      imageUrl: _resolveUrl(
        imageValue?.toString() ?? '',
        baseUrl,
      ),
      rawData:
          Map<String, dynamic>.unmodifiable(
        source,
      ),
    );
  }

  static Map<String, dynamic> _unwrap(
    Map<String, dynamic> map,
  ) {
    final nested = _firstValue(
      map,
      const [
        'perro',
        'Perro',
        'mascota',
        'Mascota',
      ],
    );

    if (nested is Map<String, dynamic>) {
      return nested;
    }

    if (nested is Map) {
      return Map<String, dynamic>.from(
        nested,
      );
    }

    return map;
  }

  static String _resolveUrl(
    String value,
    String? baseUrl,
  ) {
    final cleanValue = value.trim();

    if (cleanValue.isEmpty ||
        cleanValue.toLowerCase() == 'null') {
      return '';
    }

    if (cleanValue.startsWith('http://') ||
        cleanValue.startsWith('https://')) {
      return cleanValue;
    }

    var cleanBase =
        baseUrl?.trim() ?? '';

    while (cleanBase.endsWith('/')) {
      cleanBase = cleanBase.substring(
        0,
        cleanBase.length - 1,
      );
    }

    if (cleanBase.isEmpty) {
      return cleanValue;
    }

    final normalizedPath =
        cleanValue.startsWith('/')
            ? cleanValue
            : '/$cleanValue';

    return '$cleanBase$normalizedPath';
  }

  static dynamic _firstValue(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      if (!map.containsKey(key)) {
        continue;
      }

      final value = map[key];

      if (value == null) {
        continue;
      }

      if (value is String &&
          (value.trim().isEmpty ||
              value.trim().toLowerCase() ==
                  'null')) {
        continue;
      }

      return value;
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

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  static String _text(
    dynamic value, {
    required String fallback,
  }) {
    final text =
        value?.toString().trim() ?? '';

    if (text.isEmpty ||
        text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }
}