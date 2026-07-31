class Pet {
  final int id;
  final String name;
  final String breed;
  final int? age;
  final String size;
  final String notes;
  final String? photoPath;
  final Map<String, dynamic> rawData;

  const Pet({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.size,
    required this.notes,
    required this.photoPath,
    required this.rawData,
  });

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: _safeInt(
            _value(
              map,
              const [
                'id',
                'Id',
                'perroId',
                'PerroId',
                'mascotaId',
                'MascotaId',
              ],
            ),
          ) ??
          0,
      name: _safeText(
        _value(
          map,
          const [
            'nombre',
            'Nombre',
            'nombrePerro',
            'NombrePerro',
            'name',
            'Name',
          ],
        ),
        fallback: 'Mascota',
      ),
      breed: _safeText(
        _value(
          map,
          const [
            'raza',
            'Raza',
            'breed',
            'Breed',
          ],
        ),
        fallback: 'Sin raza registrada',
      ),
      age: _safeInt(
        _value(
          map,
          const [
            'edad',
            'Edad',
            'age',
            'Age',
          ],
        ),
      ),
      size: _safeText(
        _value(
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
        fallback: 'Sin tamaño registrado',
      ),
      notes: _safeText(
        _value(
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
      ),
      photoPath: _safeNullableText(
        _value(
          map,
          const [
            'fotoUrl',
            'FotoUrl',
            'foto',
            'Foto',
            'imagenUrl',
            'ImagenUrl',
            'urlFoto',
            'UrlFoto',
            'fotoPerroUrl',
            'FotoPerroUrl',
            'photoUrl',
            'PhotoUrl',
          ],
        ),
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

  String get ageLabel {
    final value = age;

    if (value == null) return 'Edad no registrada';
    if (value == 0) return 'Menos de 1 año';
    if (value == 1) return '1 año';

    return '$value años';
  }

  String get shortDescription {
    return '$breed · $ageLabel';
  }

  String get initials {
    final cleanName = name.trim();

    if (cleanName.isEmpty) return 'DG';

    final words = cleanName
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return 'DG';

    if (words.length == 1) {
      return words.first
          .substring(0, 1)
          .toUpperCase();
    }

    return '${words.first.substring(0, 1)}'
            '${words.last.substring(0, 1)}'
        .toUpperCase();
  }

  String? publicPhotoUrl(String? baseUrl) {
    final path = photoPath?.trim();

    if (path == null ||
        path.isEmpty ||
        path.toLowerCase() == 'null') {
      return null;
    }

    if (path.startsWith('http://') ||
        path.startsWith('https://')) {
      return path;
    }

    final server = baseUrl?.trim() ?? '';

    if (server.isEmpty) return path;

    final cleanServer = server.endsWith('/')
        ? server.substring(0, server.length - 1)
        : server;

    final cleanPath =
        path.startsWith('/') ? path : '/$path';

    return '$cleanServer$cleanPath';
  }

  Pet copyWith({
    int? id,
    String? name,
    String? breed,
    int? age,
    bool clearAge = false,
    String? size,
    String? notes,
    String? photoPath,
    bool clearPhoto = false,
    Map<String, dynamic>? rawData,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      age: clearAge ? null : age ?? this.age,
      size: size ?? this.size,
      notes: notes ?? this.notes,
      photoPath:
          clearPhoto ? null : photoPath ?? this.photoPath,
      rawData: rawData ?? this.rawData,
    );
  }

  static List<Pet> listFrom(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map(
          (item) => Pet.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList(growable: false);
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

  static String _safeText(
    dynamic value, {
    String fallback = '',
  }) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  static String? _safeNullableText(dynamic value) {
    final text = value?.toString().trim();

    if (text == null ||
        text.isEmpty ||
        text.toLowerCase() == 'null') {
      return null;
    }

    return text;
  }

  static int? _safeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();

    return int.tryParse(value.toString().trim());
  }
}