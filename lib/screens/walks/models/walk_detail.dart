import '../../home/models/home_walk_status.dart';
import 'walk_pet.dart';

class WalkDetail {
  final int id;
  final HomeWalkStatus status;
  final String rawStatus;

  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime? cancelledAt;

  final int durationMinutes;

  final double? price;
  final double? basePrice;
  final double? proposedPrice;

  final String petName;
  final List<WalkPet> pets;

  final int requestedPetCount;
  final int proposedPetCount;
  final int activePetCount;

  final String walkerName;
  final String ownerName;

  final String pickupAddress;
  final String pickupReferences;
  final String notes;

  final double? pickupLatitude;
  final double? pickupLongitude;

  final String? petPhotoPath;
  final String? startPhotoPath;
  final String? endPhotoPath;

  final String? cancellationReason;
  final String? cancelledBy;

  final String? petChangeReason;
  final DateTime? petChangeProposedAt;
  final DateTime? petChangeAnsweredAt;
  final bool? petChangeAccepted;

  final bool rated;
  final Map<String, dynamic> rawData;

  const WalkDetail({
    required this.id,
    required this.status,
    this.rawStatus = '',
    this.scheduledAt,
    this.startedAt,
    this.finishedAt,
    this.cancelledAt,
    this.durationMinutes = 0,
    this.price,
    this.basePrice,
    this.proposedPrice,
    this.petName = 'Mascota',
    this.pets = const [],
    this.requestedPetCount = 0,
    this.proposedPetCount = 0,
    this.activePetCount = 0,
    this.walkerName = 'Paseador no asignado',
    this.ownerName = 'Dueño no disponible',
    this.pickupAddress = 'Ubicación de recogida no definida',
    this.pickupReferences = 'Sin referencias adicionales',
    this.notes = '',
    this.pickupLatitude,
    this.pickupLongitude,
    this.petPhotoPath,
    this.startPhotoPath,
    this.endPhotoPath,
    this.cancellationReason,
    this.cancelledBy,
    this.petChangeReason,
    this.petChangeProposedAt,
    this.petChangeAnsweredAt,
    this.petChangeAccepted,
    this.rated = false,
    this.rawData = const {},
  });

  factory WalkDetail.fromMap(Map<String, dynamic> map) {
    final pet = _nestedMap(map, const ['perro', 'Perro', 'mascota', 'Mascota']);

    final walker = _nestedMap(map, const [
      'paseador',
      'Paseador',
      'walker',
      'Walker',
    ]);

    final walkerUser = _nestedMap(walker, const [
      'usuario',
      'Usuario',
      'user',
      'User',
    ]);

    final owner = _nestedMap(map, const [
      'duenio',
      'Duenio',
      'dueño',
      'Dueño',
      'propietario',
      'Propietario',
    ]);

    final petOwner = _nestedMap(pet, const [
      'duenio',
      'Duenio',
      'dueño',
      'Dueño',
      'usuario',
      'Usuario',
    ]);

    final rawStatus = _text(
      _value(map, const ['estado', 'Estado', 'status', 'Status']),
    );

    final parsedPets = WalkPet.listFrom(
      _mergePetProfiles(
        _value(map, const ['perros', 'Perros', 'mascotas', 'Mascotas']),
        _value(map, const ['perfilesMascotas', 'PerfilesMascotas']),
      ),
    );

    final legacyPetId = _integer(_value(map, const ['perroId', 'PerroId']));

    final legacyPetName = _text(
      _value(map, const [
            'perroNombre',
            'PerroNombre',
            'nombrePerro',
            'NombrePerro',
            'mascotaNombre',
            'MascotaNombre',
          ]) ??
          _value(pet, const ['nombre', 'Nombre', 'name', 'Name']),
      fallback: 'Mascota',
    );

    final legacyPetPhoto = _nullableText(
      _value(map, const [
            'perroFotoUrl',
            'PerroFotoUrl',
            'perroImagenUrl',
            'PerroImagenUrl',
            'fotoPerroUrl',
            'FotoPerroUrl',
          ]) ??
          _value(pet, const ['fotoUrl', 'FotoUrl', 'imagenUrl', 'ImagenUrl']),
    );

    final allPets = parsedPets.isNotEmpty
        ? parsedPets
        : legacyPetId != null && legacyPetId > 0
        ? [
            WalkPet(
              id: legacyPetId,
              name: legacyPetName,
              breed: _text(
                _value(pet, const ['raza', 'Raza']),
                fallback: 'Sin raza registrada',
              ),
              age: _integer(_value(pet, const ['edad', 'Edad'])),
              size: _text(
                _value(pet, const [
                  'tamanio',
                  'Tamanio',
                  'tamano',
                  'Tamano',
                  'tamaño',
                  'Tamaño',
                ]),
                fallback: 'Sin tamaño registrado',
              ),
              notes: _text(_value(pet, const ['notas', 'Notas'])),
              photoPath: legacyPetPhoto,
              requestedByOwner: true,
              includedInProposal: true,
              active: true,
            ),
          ]
        : const <WalkPet>[];

    final requestedCount =
        _integer(
          _value(map, const [
            'cantidadPerrosSolicitados',
            'CantidadPerrosSolicitados',
          ]),
        ) ??
        allPets.where((pet) => pet.requestedByOwner).length;

    final proposedCount =
        _integer(
          _value(map, const [
            'cantidadPerrosPropuestos',
            'CantidadPerrosPropuestos',
          ]),
        ) ??
        allPets.where((pet) => pet.includedInProposal).length;

    final activeCount =
        _integer(_value(map, const ['cantidadPerros', 'CantidadPerros'])) ??
        allPets.where((pet) => pet.active).length;

    final primaryPet = allPets.isEmpty
        ? null
        : allPets.firstWhere((pet) => pet.active, orElse: () => allPets.first);

    return WalkDetail(
      id: _integer(_value(map, const ['id', 'Id', 'paseoId', 'PaseoId'])) ?? 0,
      status: _statusFrom(rawStatus),
      rawStatus: rawStatus,
      scheduledAt: _dateTime(
        _value(map, const [
          'fechaProgramada',
          'FechaProgramada',
          'fecha',
          'Fecha',
        ]),
      ),
      startedAt: _dateTime(
        _value(map, const [
          'fechaInicio',
          'FechaInicio',
          'startedAt',
          'StartedAt',
        ]),
      ),
      finishedAt: _dateTime(
        _value(map, const ['fechaFin', 'FechaFin', 'finishedAt', 'FinishedAt']),
      ),
      cancelledAt: _dateTime(
        _value(map, const [
          'fechaCancelacion',
          'FechaCancelacion',
          'fechaCancelación',
          'FechaCancelación',
          'cancelledAt',
          'CancelledAt',
        ]),
      ),
      durationMinutes:
          _integer(
            _value(map, const [
              'duracionMinutos',
              'DuracionMinutos',
              'minutos',
              'Minutos',
            ]),
          ) ??
          0,
      price: _decimal(
        _value(map, const [
          'precioFinal',
          'PrecioFinal',
          'precio',
          'Precio',
          'total',
          'Total',
        ]),
      ),
      basePrice: _decimal(_value(map, const ['precioBase', 'PrecioBase'])),
      proposedPrice: _decimal(
        _value(map, const ['precioPropuesto', 'PrecioPropuesto']),
      ),
      petName: primaryPet?.name ?? legacyPetName,
      pets: List<WalkPet>.unmodifiable(allPets),
      requestedPetCount: requestedCount,
      proposedPetCount: proposedCount,
      activePetCount: activeCount,
      walkerName: _personName(
        completeName: _value(map, const [
          'paseadorNombreCompleto',
          'PaseadorNombreCompleto',
        ]),
        directName: _value(map, const [
          'paseadorNombre',
          'PaseadorNombre',
          'nombrePaseador',
          'NombrePaseador',
        ]),
        directLastName: _value(map, const [
          'paseadorApellido',
          'PaseadorApellido',
        ]),
        person: walker,
        user: walkerUser,
        fallback: 'Paseador no asignado',
      ),
      ownerName: _personName(
        completeName: _value(map, const [
          'duenioNombreCompleto',
          'DuenioNombreCompleto',
          'dueñoNombreCompleto',
          'DueñoNombreCompleto',
        ]),
        directName: _value(map, const [
          'duenioNombre',
          'DuenioNombre',
          'dueñoNombre',
          'DueñoNombre',
        ]),
        directLastName: _value(map, const [
          'duenioApellido',
          'DuenioApellido',
          'dueñoApellido',
          'DueñoApellido',
        ]),
        person: owner.isEmpty ? petOwner : owner,
        fallback: 'Dueño no disponible',
      ),
      pickupAddress: _text(
        _value(map, const [
          'ubicacionTexto',
          'UbicacionTexto',
          'direccionRecogida',
          'DireccionRecogida',
          'direccion',
          'Direccion',
        ]),
        fallback: 'Ubicación de recogida no definida',
      ),
      pickupReferences: _text(
        _value(map, const [
          'referenciasRecogida',
          'ReferenciasRecogida',
          'referencias',
          'Referencias',
        ]),
        fallback: 'Sin referencias adicionales',
      ),
      notes: _text(
        _value(map, const ['notas', 'Notas', 'observaciones', 'Observaciones']),
      ),
      pickupLatitude: _decimal(
        _value(map, const [
          'latitudRecogida',
          'LatitudRecogida',
          'latRecogida',
          'LatRecogida',
          'latitud',
          'Latitud',
        ]),
      ),
      pickupLongitude: _decimal(
        _value(map, const [
          'longitudRecogida',
          'LongitudRecogida',
          'lngRecogida',
          'LngRecogida',
          'longitud',
          'Longitud',
        ]),
      ),
      petPhotoPath: primaryPet?.photoPath ?? legacyPetPhoto,
      startPhotoPath: _nullableText(
        _value(map, const [
          'fotoInicioUrl',
          'FotoInicioUrl',
          'evidenciaInicioUrl',
          'EvidenciaInicioUrl',
        ]),
      ),
      endPhotoPath: _nullableText(
        _value(map, const [
          'fotoFinUrl',
          'FotoFinUrl',
          'evidenciaFinUrl',
          'EvidenciaFinUrl',
        ]),
      ),
      cancellationReason: _nullableText(
        _value(map, const [
          'motivoCancelacion',
          'MotivoCancelacion',
          'motivoCancelación',
          'MotivoCancelación',
        ]),
      ),
      cancelledBy: _nullableText(
        _value(map, const ['canceladoPor', 'CanceladoPor']),
      ),
      petChangeReason: _nullableText(
        _value(map, const [
          'motivoPropuestaCambioPerros',
          'MotivoPropuestaCambioPerros',
        ]),
      ),
      petChangeProposedAt: _dateTime(
        _value(map, const [
          'fechaPropuestaCambioPerros',
          'FechaPropuestaCambioPerros',
        ]),
      ),
      petChangeAnsweredAt: _dateTime(
        _value(map, const [
          'fechaRespuestaCambioPerros',
          'FechaRespuestaCambioPerros',
        ]),
      ),
      petChangeAccepted: _nullableBoolean(
        _value(map, const ['cambioPerrosAceptado', 'CambioPerrosAceptado']),
      ),
      rated: _boolean(
        _value(map, const [
          'calificado',
          'Calificado',
          'tieneCalificacion',
          'TieneCalificacion',
          'rated',
          'Rated',
        ]),
      ),
      rawData: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(map),
      ),
    );
  }

  bool get hasValidId => id > 0;

  bool get isPending => status == HomeWalkStatus.pending;

  bool get isAccepted => status == HomeWalkStatus.accepted;

  bool get isInProgress => status == HomeWalkStatus.inProgress;

  bool get isCompleted => status == HomeWalkStatus.completed;

  bool get isCancelled => status == HomeWalkStatus.cancelled;

  bool get isRejected => status == HomeWalkStatus.rejected;

  bool get isFinished => isCompleted || isCancelled || isRejected;

  bool get hasMultiplePets => requestedPetCount > 1 || pets.length > 1;

  bool get hasPendingPetProposal {
    final normalized = _normalize(rawStatus);

    return normalized == 'cambiopropuesto' ||
        normalized == 'cambiomascotaspropuesto';
  }

  bool get petProposalWasAccepted => petChangeAccepted == true;

  bool get petProposalWasRejected => petChangeAccepted == false;

  List<WalkPet> get requestedPets {
    return pets.where((pet) => pet.requestedByOwner).toList(growable: false);
  }

  List<WalkPet> get proposedPets {
    return pets.where((pet) => pet.includedInProposal).toList(growable: false);
  }

  List<WalkPet> get activePets {
    return pets.where((pet) => pet.active).toList(growable: false);
  }

  List<WalkPet> get excludedFromProposal {
    return pets
        .where((pet) => pet.requestedByOwner && !pet.includedInProposal)
        .toList(growable: false);
  }

  bool get hasStartEvidence => startPhotoPath != null;

  bool get hasEndEvidence => endPhotoPath != null;

  bool get hasPickupCoordinates {
    final latitude = pickupLatitude;
    final longitude = pickupLongitude;

    if (latitude == null || longitude == null) {
      return false;
    }

    if (latitude == 0 && longitude == 0) {
      return false;
    }

    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  String get petsLabel {
    final list = activePets.isNotEmpty ? activePets : requestedPets;

    if (list.isEmpty) {
      return petName;
    }

    if (list.length == 1) {
      return list.first.name;
    }

    return list.map((pet) => pet.name).join(', ');
  }

  String get petCountLabel {
    final count = activePetCount > 0 ? activePetCount : pets.length;

    return count == 1 ? '1 mascota' : '$count mascotas';
  }

  String get durationLabel {
    if (durationMinutes <= 0) {
      return 'Sin duración';
    }

    if (durationMinutes == 60) {
      return '1 hora';
    }

    if (durationMinutes == 90) {
      return '1.5 horas';
    }

    return '$durationMinutes min';
  }

  String get priceLabel {
    final value = price;

    return value == null ? 'No disponible' : '\$${value.toStringAsFixed(2)}';
  }

  String get basePriceLabel {
    final value = basePrice;

    return value == null ? 'No disponible' : '\$${value.toStringAsFixed(2)}';
  }

  String get proposedPriceLabel {
    final value = proposedPrice;

    return value == null ? priceLabel : '\$${value.toStringAsFixed(2)}';
  }

  String get scheduledLabel => _formatDate(scheduledAt);

  String get startedLabel => _formatDate(startedAt);

  String get finishedLabel => _formatDate(finishedAt);

  String get cancelledLabel => _formatDate(cancelledAt);

  String get pickupCoordinatesLabel {
    if (!hasPickupCoordinates) {
      return 'Coordenadas no disponibles';
    }

    return '${pickupLatitude!.toStringAsFixed(6)}, '
        '${pickupLongitude!.toStringAsFixed(6)}';
  }

  String? publicPetPhotoUrl(String? baseUrl) {
    return _publicUrl(petPhotoPath, baseUrl);
  }

  String? publicStartPhotoUrl(String? baseUrl) {
    return _publicUrl(startPhotoPath, baseUrl);
  }

  String? publicEndPhotoUrl(String? baseUrl) {
    return _publicUrl(endPhotoPath, baseUrl);
  }

  Map<String, dynamic> toNavigationMap() {
    return {
      ...rawData,
      'id': id,
      'paseoId': id,
      'estado': rawStatus,
      'perroNombre': petName,
      'perros': pets
          .map(
            (pet) => {
              'perroId': pet.id,
              'nombre': pet.name,
              'raza': pet.breed,
              'edad': pet.age,
              'tamanio': pet.size,
              'notas': pet.notes,
              'fotoUrl': pet.photoPath,
              'solicitadoPorDuenio': pet.requestedByOwner,
              'incluidoEnPropuesta': pet.includedInProposal,
              'activo': pet.active,
            },
          )
          .toList(),
    };
  }

  static HomeWalkStatus _statusFrom(String value) {
    final normalized = _normalize(value);

    // Mientras existe una contrapropuesta,
    // no debe tratarse como paseo aceptable
    // o iniciable.
    if (normalized == 'cambiopropuesto' ||
        normalized == 'cambiomascotaspropuesto') {
      return HomeWalkStatus.unknown;
    }

    return HomeWalkStatus.fromValue(value);
  }

  static String _personName({
    dynamic completeName,
    dynamic directName,
    dynamic directLastName,
    Map<String, dynamic> person = const {},
    Map<String, dynamic> user = const {},
    required String fallback,
  }) {
    final complete = _text(completeName);

    if (complete.isNotEmpty) {
      return complete;
    }

    final direct = [
      _text(directName),
      _text(directLastName),
    ].where((part) => part.isNotEmpty).join(' ');

    if (direct.isNotEmpty) {
      return direct;
    }

    final nestedComplete = _text(
      _value(person, const [
            'nombreCompleto',
            'NombreCompleto',
            'fullName',
            'FullName',
          ]) ??
          _value(user, const [
            'nombreCompleto',
            'NombreCompleto',
            'fullName',
            'FullName',
          ]),
    );

    if (nestedComplete.isNotEmpty) {
      return nestedComplete;
    }

    final firstName = _text(
      _value(person, const ['nombre', 'Nombre', 'name', 'Name']) ??
          _value(user, const ['nombre', 'Nombre', 'name', 'Name']),
    );

    final lastName = _text(
      _value(person, const ['apellido', 'Apellido', 'lastName', 'LastName']) ??
          _value(user, const ['apellido', 'Apellido', 'lastName', 'LastName']),
    );

    final result = '$firstName $lastName'.trim();

    return result.isEmpty ? fallback : result;
  }

  static String _formatDate(DateTime? date) {
    if (date == null) {
      return 'No disponible';
    }

    final local = date.toLocal();

    final day = local.day.toString().padLeft(2, '0');

    final month = local.month.toString().padLeft(2, '0');

    final hour = local.hour.toString().padLeft(2, '0');

    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/${local.year} · '
        '$hour:$minute';
  }

  static String? _publicUrl(String? path, String? baseUrl) {
    final value = path?.trim();

    if (value == null || value.isEmpty || value.toLowerCase() == 'null') {
      return null;
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final server = baseUrl?.trim() ?? '';

    if (server.isEmpty) {
      return value;
    }

    final cleanServer = server.endsWith('/')
        ? server.substring(0, server.length - 1)
        : server;

    final cleanPath = value.startsWith('/') ? value : '/$value';

    return '$cleanServer$cleanPath';
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

  static List<dynamic> _mergePetProfiles(
    dynamic petsValue,
    dynamic profilesValue,
  ) {
    if (petsValue is! List) return const [];

    final profiles = <int, Map<String, dynamic>>{};
    if (profilesValue is List) {
      for (final item in profilesValue.whereType<Map>()) {
        final profile = Map<String, dynamic>.from(item);
        final id = _integer(profile['perroId'] ?? profile['PerroId']);
        if (id != null) profiles[id] = profile;
      }
    }

    return petsValue
        .whereType<Map>()
        .map((item) {
          final pet = Map<String, dynamic>.from(item);
          final id = _integer(
            pet['perroId'] ?? pet['PerroId'] ?? pet['id'] ?? pet['Id'],
          );
          return <String, dynamic>{
            ...pet,
            if (id != null && profiles[id] != null) ...profiles[id]!,
          };
        })
        .toList(growable: false);
  }

  static Map<String, dynamic> _nestedMap(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];

      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
    }

    return const {};
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

  static double? _decimal(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().trim().replaceAll(',', '.'));
  }

  static DateTime? _dateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value?.toString() ?? '');
  }

  static bool _boolean(dynamic value) {
    return _nullableBoolean(value) ?? false;
  }

  static bool? _nullableBoolean(dynamic value) {
    if (value == null) {
      return null;
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

    return null;
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
