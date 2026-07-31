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
    if (age == null || age! <= 0) {
      return 'Edad por confirmar';
    }

    return age == 1 ? '1 año' : '$age años';
  }

  bool get hasImage {
    return imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://');
  }

  factory HomePet.fromMap(
    Map<String, dynamic> map, {
    String? baseUrl,
  }) {
    final imageValue = _firstValue(
      map,
      const [
        'fotoMiniaturaUrl',
        'FotoMiniaturaUrl',
        'fotoUrl',
        'FotoUrl',
        'imagenUrl',
        'ImagenUrl',
        'urlFoto',
        'UrlFoto',
        'fotoPerroUrl',
        'FotoPerroUrl',
      ],
    );

    return HomePet(
      id: _toInt(
        _firstValue(
          map,
          const [
            'id',
            'Id',
            'perroId',
            'PerroId',
          ],
        ),
      ),
      name: _text(
        _firstValue(
          map,
          const ['nombre', 'Nombre', 'name', 'Name'],
        ),
        fallback: 'Mascota',
      ),
      breed: _text(
        _firstValue(
          map,
          const ['raza', 'Raza', 'breed', 'Breed'],
        ),
        fallback: 'Raza por confirmar',
      ),
      age: _toInt(
        _firstValue(
          map,
          const ['edad', 'Edad', 'age', 'Age'],
        ),
      ),
      size: _text(
        _firstValue(
          map,
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
          map,
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
      rawData: Map<String, dynamic>.unmodifiable(map),
    );
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

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  static String _text(
    dynamic value, {
    required String fallback,
  }) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}