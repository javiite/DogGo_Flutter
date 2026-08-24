class WalkPet {
  final int id;
  final String name;
  final String breed;
  final int? age;
  final String size;
  final double? weight;
  final String? sex;
  final bool? sterilized;
  final String? temperament;
  final String? energyLevel;
  final bool? socialWithDogs;
  final bool? socialWithPeople;
  final bool? socialWithChildren;
  final String? leashBehavior;
  final bool? reactive;
  final bool? escapeRisk;
  final String? fearsTriggers;
  final String? knownCommands;
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
    this.weight,
    this.sex,
    this.sterilized,
    this.temperament,
    this.energyLevel,
    this.socialWithDogs,
    this.socialWithPeople,
    this.socialWithChildren,
    this.leashBehavior,
    this.reactive,
    this.escapeRisk,
    this.fearsTriggers,
    this.knownCommands,
    required this.notes,
    required this.photoPath,
    required this.requestedByOwner,
    required this.includedInProposal,
    required this.active,
  });

  factory WalkPet.fromMap(Map<String, dynamic> map) {
    return WalkPet(
      id: _integer(_value(map, const ['perroId'])) ?? 0,
      name: _text(_value(map, const ['nombre']), fallback: 'Mascota'),
      breed: _text(
        _value(map, const ['raza']),
        fallback: 'Sin raza registrada',
      ),
      age: _integer(_value(map, const ['edad'])),
      size: _text(
        _value(map, const ['tamanio']),
        fallback: 'Sin tamaño registrado',
      ),
      weight: _decimal(_value(map, const ['peso'])),
      sex: _nullableText(_value(map, const ['sexo'])),
      sterilized: _nullableBoolean(_value(map, const ['esterilizado'])),
      temperament: _nullableText(_value(map, const ['temperamento'])),
      energyLevel: _nullableText(_value(map, const ['nivelEnergia'])),
      socialWithDogs: _nullableBoolean(
        _value(map, const ['sociableConPerros']),
      ),
      socialWithPeople: _nullableBoolean(
        _value(map, const ['sociableConPersonas']),
      ),
      socialWithChildren: _nullableBoolean(
        _value(map, const ['sociableConNinos']),
      ),
      leashBehavior: _nullableText(_value(map, const ['comportamientoCorrea'])),
      reactive: _nullableBoolean(_value(map, const ['reactivo'])),
      escapeRisk: _nullableBoolean(_value(map, const ['riesgoEscape'])),
      fearsTriggers: _nullableText(_value(map, const ['miedosDetonantes'])),
      knownCommands: _nullableText(_value(map, const ['comandosConocidos'])),
      notes: _text(_value(map, const ['notas'])),
      photoPath: _nullableText(_value(map, const ['fotoUrl'])),
      requestedByOwner: _boolean(
        _value(map, const ['solicitadoPorDuenio']),
        fallback: true,
      ),
      includedInProposal: _boolean(
        _value(map, const ['incluidoEnPropuesta']),
        fallback: true,
      ),
      active: _boolean(_value(map, const ['activo']), fallback: true),
    );
  }

  bool get hasValidId => id > 0;

  bool get removedFromProposal {
    return requestedByOwner && !includedInProposal;
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

    if (server.isEmpty) {
      return path;
    }

    final cleanServer = server.endsWith('/')
        ? server.substring(0, server.length - 1)
        : server;

    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanServer$cleanPath';
  }

  static List<WalkPet> listFrom(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((item) => WalkPet.fromMap(Map<String, dynamic>.from(item)))
        .where((pet) => pet.hasValidId)
        .toList(growable: false);
  }

  static dynamic _value(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];

      if (value != null) {
        return value;
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
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString().trim());
  }

  static bool _boolean(dynamic value, {required bool fallback}) {
    if (value == null) {
      return fallback;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value.toString().trim().toLowerCase();

    if (const {'true', '1', 'sí', 'si', 'yes'}.contains(text)) {
      return true;
    }

    if (const {'false', '0', 'no'}.contains(text)) {
      return false;
    }

    return fallback;
  }

  static double? _decimal(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().trim() ?? '');
  }

  static bool? _nullableBoolean(dynamic value) {
    if (value == null) return null;
    return _boolean(value, fallback: false);
  }
}
