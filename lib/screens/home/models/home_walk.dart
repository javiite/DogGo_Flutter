import 'home_pet.dart';
import 'home_walk_status.dart';
import 'home_walker.dart';

class HomeWalk {
  final int? id;
  final HomeWalkStatus status;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int durationMinutes;
  final double distanceKilometers;
  final double? price;
  final String pickupAddress;
  final String notes;
  final HomePet? pet;
  final List<HomePet> pets;
  final HomeWalker? walker;
  final Map<String, dynamic> rawData;

  const HomeWalk({
    this.id,
    required this.status,
    this.scheduledAt,
    this.startedAt,
    this.finishedAt,
    this.durationMinutes = 0,
    this.distanceKilometers = 0,
    this.price,
    this.pickupAddress = '',
    this.notes = '',
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

    return primaryPet == null
        ? const []
        : [primaryPet];
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

    return currentPets
        .map((pet) => pet.name)
        .join(', ');
  }

  String get petCountLabel {
    return petCount == 1
        ? '1 mascota'
        : '$petCount mascotas';
  }

  String get walkerName {
    return walker?.name ??
        'paseador por confirmar';
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
        .where(
          (url) =>
              url.startsWith('http://') ||
              url.startsWith('https://'),
        )
        .toSet()
        .toList(growable: false);
  }

  bool get hasPetImage {
    return petImageUrls.isNotEmpty;
  }

  bool get isInProgress {
    return status ==
        HomeWalkStatus.inProgress;
  }

  bool get isUpcoming {
    return status ==
            HomeWalkStatus.pending ||
        status ==
            HomeWalkStatus.accepted ||
        status ==
            HomeWalkStatus.inProgress ||
        status ==
            HomeWalkStatus.unknown;
  }

  String get formattedSchedule {
    final date = scheduledAt;

    if (date == null) {
      return 'Horario por confirmar';
    }

    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );
    final tomorrow = today.add(
      const Duration(days: 1),
    );
    final walkDay = DateTime(
      date.year,
      date.month,
      date.day,
    );

    String dayLabel;

    if (walkDay == today) {
      dayLabel = 'Hoy';
    } else if (walkDay == tomorrow) {
      dayLabel = 'MaÃ±ana';
    } else {
      dayLabel =
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}';
    }

    final hour = date.hour
        .toString()
        .padLeft(2, '0');
    final minute = date.minute
        .toString()
        .padLeft(2, '0');

    return '$dayLabel Â· $hour:$minute';
  }

  factory HomeWalk.fromMap(
    Map<String, dynamic> map, {
    String? baseUrl,
  }) {
    final petMap = _extractPetMap(map);
    final walkerMap =
        _extractWalkerMap(map);

    final parsedPets = _extractPets(
      map,
      baseUrl,
    );

    final legacyPet = petMap.isEmpty
        ? _petFromFlatWalk(
            map,
            baseUrl,
          )
        : HomePet.fromMap(
            petMap,
            baseUrl: baseUrl,
          );

    final pets = parsedPets.isNotEmpty
        ? parsedPets
        : legacyPet == null
            ? const <HomePet>[]
            : <HomePet>[legacyPet];

    final pet =
        pets.isEmpty ? legacyPet : pets.first;

    final walker = walkerMap.isEmpty
        ? _walkerFromFlatWalk(
            map,
            baseUrl,
          )
        : HomeWalker.fromMap(
            walkerMap,
            baseUrl: baseUrl,
          );

    return HomeWalk(
      id: _toInt(
        _firstValue(
          map,
          const [
            'id',
            'Id',
            'paseoId',
            'PaseoId',
          ],
        ),
      ),
      status: HomeWalkStatus.fromValue(
        _firstValue(
          map,
          const [
            'estado',
            'Estado',
            'status',
            'Status',
          ],
        ),
      ),
      scheduledAt: _toDateTime(
        _firstValue(
          map,
          const [
            'fechaProgramada',
            'FechaProgramada',
            'scheduledAt',
            'ScheduledAt',
            'fecha',
            'Fecha',
          ],
        ),
      ),
      startedAt: _toDateTime(
        _firstValue(
          map,
          const [
            'fechaInicio',
            'FechaInicio',
            'startedAt',
            'StartedAt',
          ],
        ),
      ),
      finishedAt: _toDateTime(
        _firstValue(
          map,
          const [
            'fechaFin',
            'FechaFin',
            'finishedAt',
            'FinishedAt',
          ],
        ),
      ),
      durationMinutes: _toInt(
            _firstValue(
              map,
              const [
                'duracionMinutos',
                'DuracionMinutos',
                'minutos',
                'Minutos',
              ],
            ),
          ) ??
          0,
      distanceKilometers: _toDouble(
            _firstValue(
              map,
              const [
                'distanciaKm',
                'DistanciaKm',
                'distanciaKilometros',
                'DistanciaKilometros',
              ],
            ),
          ) ??
          0,
      price: _toDouble(
        _firstValue(
          map,
          const [
            'precioFinal',
            'PrecioFinal',
            'precio',
            'Precio',
            'total',
            'Total',
          ],
        ),
      ),
      pickupAddress: _text(
        _firstValue(
          map,
          const [
            'ubicacionTexto',
            'UbicacionTexto',
            'direccionRecogida',
            'DireccionRecogida',
            'ubicacionRecogidaTexto',
            'UbicacionRecogidaTexto',
          ],
        ),
      ),
      notes: _text(
        _firstValue(
          map,
          const [
            'notas',
            'Notas',
            'observaciones',
            'Observaciones',
          ],
        ),
      ),
      pet: pet,
      pets: List<HomePet>.unmodifiable(
        pets,
      ),
      walker: walker,
      rawData:
          Map<String, dynamic>.unmodifiable(
        map,
      ),
    );
  }

  static HomePet? _petFromFlatWalk(
    Map<String, dynamic> map,
    String? baseUrl,
  ) {
    final name = _firstValue(
      map,
      const [
        'perroNombre',
        'PerroNombre',
        'nombrePerro',
        'NombrePerro',
        'mascotaNombre',
        'MascotaNombre',
      ],
    );

    final petId = _firstValue(
      map,
      const [
        'perroId',
        'PerroId',
        'mascotaId',
        'MascotaId',
      ],
    );

    final image = _firstValue(
      map,
      const [
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
      ],
    );

    if (name == null &&
        petId == null &&
        image == null) {
      return null;
    }

    return HomePet.fromMap(
      {
        'perroId': petId,
        'nombre':
            name ?? 'Mascota',
        'raza': _firstValue(
          map,
          const [
            'perroRaza',
            'PerroRaza',
            'razaPerro',
            'RazaPerro',
          ],
        ),
        'edad': _firstValue(
          map,
          const [
            'perroEdad',
            'PerroEdad',
            'edadPerro',
            'EdadPerro',
          ],
        ),
        'imagenUrl': image,
      },
      baseUrl: baseUrl,
    );
  }

  static HomeWalker?
      _walkerFromFlatWalk(
    Map<String, dynamic> map,
    String? baseUrl,
  ) {
    final name = _firstValue(
      map,
      const [
        'paseadorNombreCompleto',
        'PaseadorNombreCompleto',
        'nombreCompletoPaseador',
        'NombreCompletoPaseador',
        'paseadorNombre',
        'PaseadorNombre',
        'nombrePaseador',
        'NombrePaseador',
      ],
    );

    final walkerId = _firstValue(
      map,
      const [
        'paseadorId',
        'PaseadorId',
      ],
    );

    if (name == null &&
        walkerId == null) {
      return null;
    }

    return HomeWalker.fromMap(
      {
        'paseadorId': walkerId,
        'nombreCompleto':
            name ?? 'Paseador',
        'fotoUrl': _firstValue(
          map,
          const [
            'paseadorFotoUrl',
            'PaseadorFotoUrl',
            'fotoPaseadorUrl',
            'FotoPaseadorUrl',
            'imagenPaseadorUrl',
            'ImagenPaseadorUrl',
          ],
        ),
      },
      baseUrl: baseUrl,
    );
  }

  static List<HomePet> _extractPets(
    Map<String, dynamic> map,
    String? baseUrl,
  ) {
    final value = _firstValue(
      map,
      const [
        'perros',
        'Perros',
        'mascotas',
        'Mascotas',
      ],
    );

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
        .where(
          (pet) => pet.id != null,
        )
        .toList(growable: false);
  }

  static Map<String, dynamic>
      _extractPetMap(
    Map<String, dynamic> map,
  ) {
    return _safeMap(
      _firstValue(
        map,
        const [
          'perro',
          'Perro',
          'mascota',
          'Mascota',
        ],
      ),
    );
  }

  static Map<String, dynamic>
      _extractWalkerMap(
    Map<String, dynamic> map,
  ) {
    return _safeMap(
      _firstValue(
        map,
        const [
          'paseador',
          'Paseador',
          'walker',
          'Walker',
        ],
      ),
    );
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

  static Map<String, dynamic> _safeMap(
    dynamic value,
  ) {
    if (value
        is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
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

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  static double? _toDouble(
    dynamic value,
  ) {
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

  static DateTime? _toDateTime(
    dynamic value,
  ) {
    if (value is DateTime) {
      return value.toLocal();
    }

    final parsed = DateTime.tryParse(
      value?.toString() ?? '',
    );

    return parsed?.toLocal();
  }

  static String _text(dynamic value) {
    final text =
        value?.toString().trim() ?? '';

    if (text.toLowerCase() == 'null') {
      return '';
    }

    return text;
  }
}

