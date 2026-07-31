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
    this.walker,
    this.rawData = const {},
  });

  String get petName => pet?.name ?? 'tu mascota';

  String get walkerName =>
      walker?.name ?? 'paseador por confirmar';

  String get imageUrl {
    if (pet?.imageUrl.isNotEmpty == true) {
      return pet!.imageUrl;
    }

    if (walker?.imageUrl.isNotEmpty == true) {
      return walker!.imageUrl;
    }

    return '';
  }

  bool get isInProgress {
    return status == HomeWalkStatus.inProgress;
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

    final dayLabel = walkDay == today
        ? 'Hoy'
        : walkDay == tomorrow
            ? 'Mañana'
            : '${date.day.toString().padLeft(2, '0')}/'
                '${date.month.toString().padLeft(2, '0')}';

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$dayLabel · $hour:$minute';
  }

  factory HomeWalk.fromMap(
    Map<String, dynamic> map, {
    String? baseUrl,
  }) {
    final petMap = _extractPetMap(map);
    final walkerMap = _extractWalkerMap(map);

    return HomeWalk(
      id: _toInt(
        _firstValue(
          map,
          const ['id', 'Id', 'paseoId', 'PaseoId'],
        ),
      ),
      status: HomeWalkStatus.fromValue(
        _firstValue(
          map,
          const ['estado', 'Estado', 'status', 'Status'],
        ),
      ),
      scheduledAt: _toDateTime(
        _firstValue(
          map,
          const [
            'fechaProgramada',
            'FechaProgramada',
            'fecha',
            'Fecha',
          ],
        ),
      ),
      startedAt: _toDateTime(
        _firstValue(
          map,
          const ['fechaInicio', 'FechaInicio'],
        ),
      ),
      finishedAt: _toDateTime(
        _firstValue(
          map,
          const ['fechaFin', 'FechaFin'],
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
      pet: petMap.isEmpty
          ? _petFromFlatWalk(map, baseUrl)
          : HomePet.fromMap(petMap, baseUrl: baseUrl),
      walker: walkerMap.isEmpty
          ? _walkerFromFlatWalk(map, baseUrl)
          : HomeWalker.fromMap(walkerMap, baseUrl: baseUrl),
      rawData: Map<String, dynamic>.unmodifiable(map),
    );
  }

  static HomePet? _petFromFlatWalk(
    Map<String, dynamic> map,
    String? baseUrl,
  ) {
    final name = _firstValue(
      map,
      const [
        'nombrePerro',
        'NombrePerro',
        'perroNombre',
        'PerroNombre',
      ],
    );

    if (name == null || name.toString().trim().isEmpty) {
      return null;
    }

    return HomePet.fromMap(
      {
        'perroId': _firstValue(
          map,
          const ['perroId', 'PerroId'],
        ),
        'nombre': name,
        'raza': _firstValue(
          map,
          const ['razaPerro', 'RazaPerro'],
        ),
        'fotoUrl': _firstValue(
          map,
          const [
            'fotoPerroUrl',
            'FotoPerroUrl',
            'imagenPerroUrl',
            'ImagenPerroUrl',
          ],
        ),
      },
      baseUrl: baseUrl,
    );
  }

  static HomeWalker? _walkerFromFlatWalk(
    Map<String, dynamic> map,
    String? baseUrl,
  ) {
    final name = _firstValue(
      map,
      const [
        'nombrePaseador',
        'NombrePaseador',
        'paseadorNombre',
        'PaseadorNombre',
      ],
    );

    if (name == null || name.toString().trim().isEmpty) {
      return null;
    }

    return HomeWalker.fromMap(
      {
        'paseadorId': _firstValue(
          map,
          const ['paseadorId', 'PaseadorId'],
        ),
        'nombreCompleto': name,
        'fotoUrl': _firstValue(
          map,
          const [
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

  static Map<String, dynamic> _extractPetMap(
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

  static Map<String, dynamic> _extractWalkerMap(
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

  static DateTime? _toDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value?.toString() ?? '');
  }

  static String _text(dynamic value) {
    return value?.toString().trim() ?? '';
  }
}