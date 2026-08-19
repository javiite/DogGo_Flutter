import 'home_pet.dart';
import 'home_walk_status.dart';
import 'home_walker.dart';

class HomeWalk {
  final int? id;
  final int? programacionId;
  final HomeWalkStatus status;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int durationMinutes;
  final double distanceKilometers;
  final double? price;
  final String pickupAddress;
  final String notes;
  final String ownerName;
  final bool hasPlannedRoute;
  final bool isOutsideAllowedRoute;
  final DateTime? firstRouteDeviationAt;
  final DateTime? lastRouteReadingAt;
  final HomePet? pet;
  final List<HomePet> pets;
  final HomeWalker? walker;
  final Map<String, dynamic> rawData;

  const HomeWalk({
    this.id,
    this.programacionId,
    required this.status,
    this.scheduledAt,
    this.startedAt,
    this.finishedAt,
    this.durationMinutes = 0,
    this.distanceKilometers = 0,
    this.price,
    this.pickupAddress = '',
    this.notes = '',
    this.ownerName = '',
    this.hasPlannedRoute = false,
    this.isOutsideAllowedRoute = false,
    this.firstRouteDeviationAt,
    this.lastRouteReadingAt,
    this.pet,
    this.pets = const [],
    this.walker,
    this.rawData = const {},
  });

  List<HomePet> get effectivePets {
    if (pets.isNotEmpty) {
      return pets;
    }

    final primaryPet = pet;

    return primaryPet == null ? const [] : [primaryPet];
  }

  int get petCount {
    return effectivePets.length;
  }

  bool get hasMultiplePets {
    return petCount > 1;
  }

  String get petName {
    final currentPets = effectivePets;

    if (currentPets.isEmpty) {
      return 'tu mascota';
    }

    if (currentPets.length == 1) {
      return currentPets.first.name;
    }

    return currentPets.map((pet) => pet.name).join(', ');
  }

  String get petCountLabel {
    return petCount == 1 ? '1 mascota' : '$petCount mascotas';
  }

  String get walkerName {
    return walker?.name ?? 'paseador por confirmar';
  }

  // En las tarjetas del paseo debe aparecer
  // la mascota, no la foto del paseador.
  String get imageUrl {
    for (final currentPet in effectivePets) {
      if (currentPet.imageUrl.isNotEmpty) {
        return currentPet.imageUrl;
      }
    }

    return '';
  }

  List<String> get petImageUrls {
    return effectivePets
        .map((pet) => pet.imageUrl)
        .where((url) => url.startsWith('http://') || url.startsWith('https://'))
        .toSet()
        .toList(growable: false);
  }

  bool get hasPetImage {
    return petImageUrls.isNotEmpty;
  }

  bool get isInProgress {
    return status == HomeWalkStatus.inProgress;
  }

  bool get isPending {
    return status == HomeWalkStatus.pending;
  }

  bool get isAccepted {
    return status == HomeWalkStatus.accepted;
  }

  bool get isCompleted {
    return status == HomeWalkStatus.completed;
  }

  String get ownerDisplayName {
    return ownerName.isEmpty ? 'Dueño DogGo' : ownerName;
  }

  String get routeStatusMessage {
    if (!hasPlannedRoute) {
      return 'Este paseo no tiene una ruta planificada.';
    }

    if (isOutsideAllowedRoute) {
      return 'El recorrido salió de la zona permitida. Regresa a la ruta indicada.';
    }

    return 'El recorrido se mantiene dentro de la ruta permitida.';
  }

  String routeDeviationTimeLabel({DateTime? from}) {
    final deviation = firstRouteDeviationAt;

    if (deviation == null) {
      return 'Atención inmediata';
    }

    final reference = from ?? DateTime.now();
    final minutes = reference.difference(deviation).inMinutes;

    if (minutes <= 1) {
      return 'Desvío reciente';
    }

    if (minutes < 60) {
      return 'Fuera hace $minutes min';
    }

    final hours = minutes ~/ 60;
    return 'Fuera hace $hours h';
  }

  String timeUntilLabel({DateTime? from}) {
    final date = scheduledAt;

    if (date == null) {
      return 'Horario por confirmar';
    }

    final reference = from ?? DateTime.now();
    final difference = date.difference(reference);
    final absoluteMinutes = difference.inMinutes.abs();

    if (difference.inMinutes >= 24 * 60) {
      final days = (difference.inMinutes / (24 * 60)).ceil();
      return days == 1 ? 'Mañana' : 'En $days días';
    }

    if (difference.inMinutes > 60) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);

      return minutes == 0 ? 'En $hours h' : 'En $hours h $minutes min';
    }

    if (difference.inMinutes > 1) {
      return 'En ${difference.inMinutes} min';
    }

    if (difference.inMinutes >= -10) {
      return 'Comienza ahora';
    }

    if (absoluteMinutes < 60) {
      return 'Hace $absoluteMinutes min';
    }

    return formattedSchedule;
  }

  bool get isUpcoming {
    return status == HomeWalkStatus.pending ||
        status == HomeWalkStatus.accepted ||
        status == HomeWalkStatus.inProgress ||
        status == HomeWalkStatus.unknown;
  }

  String get formattedSchedule {
    final date = scheduledAt;

    if (date == null) {
      return 'Horario por confirmar';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final walkDay = DateTime(date.year, date.month, date.day);

    String dayLabel;

    if (walkDay == today) {
      dayLabel = 'Hoy';
    } else if (walkDay == tomorrow) {
      dayLabel = 'Mañana';
    } else {
      dayLabel =
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}';
    }

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$dayLabel · $hour:$minute';
  }

  factory HomeWalk.fromMap(Map<String, dynamic> map, {String? baseUrl}) {
    final petMap = _extractPetMap(map);
    final walkerMap = _extractWalkerMap(map);

    final parsedPets = _extractPets(map, baseUrl);

    final legacyPet = petMap.isEmpty
        ? _petFromFlatWalk(map, baseUrl)
        : HomePet.fromMap(petMap, baseUrl: baseUrl);

    final pets = parsedPets.isNotEmpty
        ? parsedPets
        : legacyPet == null
        ? const <HomePet>[]
        : <HomePet>[legacyPet];

    final pet = pets.isEmpty ? legacyPet : pets.first;

    final walker = walkerMap.isEmpty
        ? _walkerFromFlatWalk(map, baseUrl)
        : HomeWalker.fromMap(walkerMap, baseUrl: baseUrl);

    return HomeWalk(
      id: _toInt(_firstValue(map, const ['id', 'Id', 'paseoId', 'PaseoId'])),
      programacionId: _toInt(
        _firstValue(map, const ['programacionId', 'ProgramacionId']),
      ),
      status: HomeWalkStatus.fromValue(
        _firstValue(map, const ['estado', 'Estado', 'status', 'Status']),
      ),
      scheduledAt: _toDateTime(
        _firstValue(map, const [
          'fechaProgramada',
          'FechaProgramada',
          'scheduledAt',
          'ScheduledAt',
          'fecha',
          'Fecha',
        ]),
      ),
      startedAt: _toDateTime(
        _firstValue(map, const [
          'fechaInicio',
          'FechaInicio',
          'startedAt',
          'StartedAt',
        ]),
      ),
      finishedAt: _toDateTime(
        _firstValue(map, const [
          'fechaFin',
          'FechaFin',
          'finishedAt',
          'FinishedAt',
        ]),
      ),
      durationMinutes:
          _toInt(
            _firstValue(map, const [
              'duracionMinutos',
              'DuracionMinutos',
              'minutos',
              'Minutos',
            ]),
          ) ??
          0,
      distanceKilometers:
          _toDouble(
            _firstValue(map, const [
              'distanciaKm',
              'DistanciaKm',
              'distanciaKilometros',
              'DistanciaKilometros',
            ]),
          ) ??
          0,
      price: _toDouble(
        _firstValue(map, const [
          'precioFinal',
          'PrecioFinal',
          'precio',
          'Precio',
          'total',
          'Total',
        ]),
      ),
      pickupAddress: _text(
        _firstValue(map, const [
          'ubicacionTexto',
          'UbicacionTexto',
          'direccionRecogida',
          'DireccionRecogida',
          'ubicacionRecogidaTexto',
          'UbicacionRecogidaTexto',
        ]),
      ),
      notes: _text(
        _firstValue(map, const [
          'notas',
          'Notas',
          'observaciones',
          'Observaciones',
        ]),
      ),
      ownerName: _ownerNameFromMap(map),
      hasPlannedRoute: _toBool(
        _firstValue(map, const [
          'tieneRutaPlanificada',
          'TieneRutaPlanificada',
          'hasPlannedRoute',
          'HasPlannedRoute',
        ]),
      ),
      isOutsideAllowedRoute: _toBool(
        _firstValue(map, const [
          'fueraDeRuta',
          'FueraDeRuta',
          'isOutsideRoute',
          'IsOutsideRoute',
        ]),
      ),
      firstRouteDeviationAt: _toDateTime(
        _firstValue(map, const [
          'fechaPrimerDesvio',
          'FechaPrimerDesvio',
          'firstRouteDeviationAt',
          'FirstRouteDeviationAt',
        ]),
      ),
      lastRouteReadingAt: _toDateTime(
        _firstValue(map, const [
          'fechaUltimaLecturaRuta',
          'FechaUltimaLecturaRuta',
          'lastRouteReadingAt',
          'LastRouteReadingAt',
        ]),
      ),
      pet: pet,
      pets: List<HomePet>.unmodifiable(pets),
      walker: walker,
      rawData: Map<String, dynamic>.unmodifiable(map),
    );
  }

  static String _ownerNameFromMap(Map<String, dynamic> map) {
    final fullName = _text(
      _firstValue(map, const [
        'duenioNombreCompleto',
        'DuenioNombreCompleto',
        'dueñoNombreCompleto',
        'DueñoNombreCompleto',
        'ownerName',
        'OwnerName',
      ]),
    );

    if (fullName.isNotEmpty) {
      return fullName;
    }

    final firstName = _text(
      _firstValue(map, const [
        'duenioNombre',
        'DuenioNombre',
        'dueñoNombre',
        'DueñoNombre',
      ]),
    );
    final lastName = _text(
      _firstValue(map, const [
        'duenioApellido',
        'DuenioApellido',
        'dueñoApellido',
        'DueñoApellido',
      ]),
    );

    return '$firstName $lastName'.trim();
  }

  static HomePet? _petFromFlatWalk(Map<String, dynamic> map, String? baseUrl) {
    final name = _firstValue(map, const [
      'perroNombre',
      'PerroNombre',
      'nombrePerro',
      'NombrePerro',
      'mascotaNombre',
      'MascotaNombre',
    ]);

    final petId = _firstValue(map, const [
      'perroId',
      'PerroId',
      'mascotaId',
      'MascotaId',
    ]);

    final image = _firstValue(map, const [
      // Nombres reales de los DTO del backend.
      'perroFotoUrl',
      'PerroFotoUrl',
      'perroImagenUrl',
      'PerroImagenUrl',

      // Variantes conservadas por compatibilidad.
      'fotoPerroUrl',
      'FotoPerroUrl',
      'imagenPerroUrl',
      'ImagenPerroUrl',
      'mascotaFotoUrl',
      'MascotaFotoUrl',
    ]);

    if (name == null && petId == null && image == null) {
      return null;
    }

    return HomePet.fromMap({
      'perroId': petId,
      'nombre': name ?? 'Mascota',
      'raza': _firstValue(map, const [
        'perroRaza',
        'PerroRaza',
        'razaPerro',
        'RazaPerro',
      ]),
      'edad': _firstValue(map, const [
        'perroEdad',
        'PerroEdad',
        'edadPerro',
        'EdadPerro',
      ]),
      'imagenUrl': image,
    }, baseUrl: baseUrl);
  }

  static HomeWalker? _walkerFromFlatWalk(
    Map<String, dynamic> map,
    String? baseUrl,
  ) {
    final name = _firstValue(map, const [
      'paseadorNombreCompleto',
      'PaseadorNombreCompleto',
      'nombreCompletoPaseador',
      'NombreCompletoPaseador',
      'paseadorNombre',
      'PaseadorNombre',
      'nombrePaseador',
      'NombrePaseador',
    ]);

    final walkerId = _firstValue(map, const ['paseadorId', 'PaseadorId']);

    if (name == null && walkerId == null) {
      return null;
    }

    return HomeWalker.fromMap({
      'paseadorId': walkerId,
      'nombreCompleto': name ?? 'Paseador',
      'fotoUrl': _firstValue(map, const [
        'paseadorFotoUrl',
        'PaseadorFotoUrl',
        'fotoPaseadorUrl',
        'FotoPaseadorUrl',
        'imagenPaseadorUrl',
        'ImagenPaseadorUrl',
      ]),
    }, baseUrl: baseUrl);
  }

  static List<HomePet> _extractPets(Map<String, dynamic> map, String? baseUrl) {
    final value = _firstValue(map, const [
      'perros',
      'Perros',
      'mascotas',
      'Mascotas',
    ]);

    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => HomePet.fromMap(
            Map<String, dynamic>.from(item),
            baseUrl: baseUrl,
          ),
        )
        .where((pet) => pet.id != null)
        .toList(growable: false);
  }

  static Map<String, dynamic> _extractPetMap(Map<String, dynamic> map) {
    return _safeMap(
      _firstValue(map, const ['perro', 'Perro', 'mascota', 'Mascota']),
    );
  }

  static Map<String, dynamic> _extractWalkerMap(Map<String, dynamic> map) {
    return _safeMap(
      _firstValue(map, const ['paseador', 'Paseador', 'walker', 'Walker']),
    );
  }

  static dynamic _firstValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (!map.containsKey(key)) {
        continue;
      }

      final value = map[key];

      if (value == null) {
        continue;
      }

      if (value is String &&
          (value.trim().isEmpty || value.trim().toLowerCase() == 'null')) {
        continue;
      }

      return value;
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

    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '');
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized = value?.toString().trim().toLowerCase() ?? '';

    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'si' ||
        normalized == 'sí';
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is DateTime) {
      return value.toLocal();
    }

    final parsed = DateTime.tryParse(value?.toString() ?? '');

    return parsed?.toLocal();
  }

  static String _text(dynamic value) {
    final text = value?.toString().trim() ?? '';

    if (text.toLowerCase() == 'null') {
      return '';
    }

    return text;
  }
}
