class WalkPet {
  final int id;
  final String name;
  final String breed;
  final int? age;
  final String size;
  final String notes;
  final String? photoPath;
  final bool requestedByOwner;
  final bool includedInProposal;
  final bool active;

  const WalkPet({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.size,
    required this.notes,
    required this.photoPath,
    required this.requestedByOwner,
    required this.includedInProposal,
    required this.active,
  });

  factory WalkPet.fromMap(
    Map<String, dynamic> map,
  ) {
    return WalkPet(
      id: _integer(
            _value(
              map,
              const [
                'perroId',
                'PerroId',
                'id',
                'Id',
              ],
            ),
          ) ??
          0,
      name: _text(
        _value(
          map,
          const [
            'nombre',
            'Nombre',
            'name',
            'Name',
          ],
        ),
        fallback: 'Mascota',
      ),
      breed: _text(
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
      age: _integer(
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
      size: _text(
        _value(
          map,
          const [
            'tamanio',
            'Tamanio',
            'tamano',
            'Tamano',
            'tamaño',
            'Tamaño',
            'size',
            'Size',
          ],
        ),
        fallback: 'Sin tamaño registrado',
      ),
      notes: _text(
        _value(
          map,
          const [
            'notas',
            'Notas',
            'notes',
            'Notes',
          ],
        ),
      ),
      photoPath: _nullableText(
        _value(
          map,
          const [
            'fotoUrl',
            'FotoUrl',
            'imagenUrl',
            'ImagenUrl',
            'photoUrl',
            'PhotoUrl',
          ],
        ),
      ),
      requestedByOwner: _boolean(
        _value(
          map,
          const [
            'solicitadoPorDuenio',
            'SolicitadoPorDuenio',
          ],
        ),
        fallback: true,
      ),
      includedInProposal: _boolean(
        _value(
          map,
          const [
            'incluidoEnPropuesta',
            'IncluidoEnPropuesta',
          ],
        ),
        fallback: true,
      ),
      active: _boolean(
        _value(
          map,
          const [
            'activo',
            'Activo',
            'active',
            'Active',
          ],
        ),
        fallback: true,
      ),
    );
  }

  bool get hasValidId => id > 0;

  bool get removedFromProposal {
    return requestedByOwner &&
        !includedInProposal;
  }

  String get ageLabel {
    final value = age;

    if (value == null) {
      return 'Edad no registrada';
    }

    if (value == 0) {
      return 'Menos de 1 año';
    }

    if (value == 1) {
      return '1 año';
    }

    return '$value años';
  }

  String get description {
    return '$breed · $ageLabel';
  }

  String get initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return 'DG';
    }

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

    if (server.isEmpty) {
      return path;
    }

    final cleanServer = server.endsWith('/')
        ? server.substring(
            0,
            server.length - 1,
          )
        : server;

    final cleanPath =
        path.startsWith('/') ? path : '/$path';

    return '$cleanServer$cleanPath';
  }

  static List<WalkPet> listFrom(
    dynamic value,
  ) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => WalkPet.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((pet) => pet.hasValidId)
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

  static String _text(
    dynamic value, {
    String fallback = '',
  }) {
    final text =
        value?.toString().trim() ?? '';

    if (text.isEmpty ||
        text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  static String? _nullableText(
    dynamic value,
  ) {
    final text = value?.toString().trim();

    if (text == null ||
        text.isEmpty ||
        text.toLowerCase() == 'null') {
      return null;
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

  static bool _boolean(
    dynamic value, {
    required bool fallback,
  }) {
    if (value == null) {
      return fallback;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text =
        value.toString().trim().toLowerCase();

    if (const {
      'true',
      '1',
      'sí',
      'si',
      'yes',
    }.contains(text)) {
      return true;
    }

    if (const {
      'false',
      '0',
      'no',
    }.contains(text)) {
      return false;
    }

    return fallback;
  }
}