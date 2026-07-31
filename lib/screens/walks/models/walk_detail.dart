import '../../home/models/home_walk_status.dart';

class WalkDetail {
  final int id;
  final HomeWalkStatus status;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime? cancelledAt;
  final int durationMinutes;
  final double? price;
  final String petName;
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
  final bool rated;
  final Map<String, dynamic> rawData;

  const WalkDetail({
    required this.id,
    required this.status,
    this.scheduledAt,
    this.startedAt,
    this.finishedAt,
    this.cancelledAt,
    this.durationMinutes = 0,
    this.price,
    this.petName = 'Mascota',
    this.walkerName = 'Paseador no asignado',
    this.ownerName = 'Dueño no disponible',
    this.pickupAddress =
        'Ubicación de recogida no definida',
    this.pickupReferences =
        'Sin referencias adicionales',
    this.notes = '',
    this.pickupLatitude,
    this.pickupLongitude,
    this.petPhotoPath,
    this.startPhotoPath,
    this.endPhotoPath,
    this.cancellationReason,
    this.cancelledBy,
    this.rated = false,
    this.rawData = const {},
  });

  factory WalkDetail.fromMap(
    Map<String, dynamic> map,
  ) {
    final pet = _nestedMap(
      map,
      const [
        'perro',
        'Perro',
        'mascota',
        'Mascota',
      ],
    );

    final walker = _nestedMap(
      map,
      const [
        'paseador',
        'Paseador',
        'walker',
        'Walker',
      ],
    );

    final walkerUser = _nestedMap(
      walker,
      const [
        'usuario',
        'Usuario',
        'user',
        'User',
      ],
    );

    final owner = _nestedMap(
      map,
      const [
        'duenio',
        'Duenio',
        'dueño',
        'Dueño',
        'propietario',
        'Propietario',
      ],
    );

    final petOwner = _nestedMap(
      pet,
      const [
        'duenio',
        'Duenio',
        'dueño',
        'Dueño',
        'usuario',
        'Usuario',
      ],
    );

    return WalkDetail(
      id: _integer(
            _value(
              map,
              const [
                'id',
                'Id',
                'paseoId',
                'PaseoId',
              ],
            ),
          ) ??
          0,
      status: HomeWalkStatus.fromValue(
        _value(
          map,
          const [
            'estado',
            'Estado',
            'status',
            'Status',
          ],
        ),
      ),
      scheduledAt: _dateTime(
        _value(
          map,
          const [
            'fechaProgramada',
            'FechaProgramada',
            'fecha',
            'Fecha',
          ],
        ),
      ),
      startedAt: _dateTime(
        _value(
          map,
          const [
            'fechaInicio',
            'FechaInicio',
            'startedAt',
            'StartedAt',
          ],
        ),
      ),
      finishedAt: _dateTime(
        _value(
          map,
          const [
            'fechaFin',
            'FechaFin',
            'finishedAt',
            'FinishedAt',
          ],
        ),
      ),
      cancelledAt: _dateTime(
        _value(
          map,
          const [
            'fechaCancelacion',
            'FechaCancelacion',
            'fechaCancelación',
            'FechaCancelación',
            'cancelledAt',
            'CancelledAt',
          ],
        ),
      ),
      durationMinutes: _integer(
            _value(
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
      price: _decimal(
        _value(
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
      petName: _text(
        _value(
              map,
              const [
                'perroNombre',
                'PerroNombre',
                'nombrePerro',
                'NombrePerro',
                'mascotaNombre',
                'MascotaNombre',
              ],
            ) ??
            _value(
              pet,
              const [
                'nombre',
                'Nombre',
                'name',
                'Name',
              ],
            ),
        fallback: 'Mascota',
      ),
      walkerName: _personName(
        directName: _value(
          map,
          const [
            'paseadorNombre',
            'PaseadorNombre',
            'nombrePaseador',
            'NombrePaseador',
          ],
        ),
        directLastName: _value(
          map,
          const [
            'paseadorApellido',
            'PaseadorApellido',
            'apellidoPaseador',
            'ApellidoPaseador',
          ],
        ),
        person: walker,
        user: walkerUser,
        fallback: 'Paseador no asignado',
      ),
      ownerName: _personName(
        directName: _value(
          map,
          const [
            'duenioNombre',
            'DuenioNombre',
            'dueñoNombre',
            'DueñoNombre',
            'nombreDuenio',
            'NombreDuenio',
            'nombreDueño',
            'NombreDueño',
          ],
        ),
        directLastName: _value(
          map,
          const [
            'duenioApellido',
            'DuenioApellido',
            'dueñoApellido',
            'DueñoApellido',
            'apellidoDuenio',
            'ApellidoDuenio',
            'apellidoDueño',
            'ApellidoDueño',
          ],
        ),
        person: owner.isEmpty ? petOwner : owner,
        fallback: 'Dueño no disponible',
      ),
      pickupAddress: _text(
        _value(
          map,
          const [
            'ubicacionTexto',
            'UbicacionTexto',
            'ubicacionRecogidaTexto',
            'UbicacionRecogidaTexto',
            'direccionRecogida',
            'DireccionRecogida',
            'direccion',
            'Direccion',
          ],
        ),
        fallback:
            'Ubicación de recogida no definida',
      ),
      pickupReferences: _text(
        _value(
          map,
          const [
            'referenciasRecogida',
            'ReferenciasRecogida',
            'referencias',
            'Referencias',
          ],
        ),
        fallback:
            'Sin referencias adicionales',
      ),
      notes: _text(
        _value(
          map,
          const [
            'notas',
            'Notas',
            'observaciones',
            'Observaciones',
          ],
        ),
      ),
      pickupLatitude: _decimal(
        _value(
          map,
          const [
            'latitudRecogida',
            'LatitudRecogida',
            'latRecogida',
            'LatRecogida',
            'ubicacionLatitud',
            'UbicacionLatitud',
            'latitud',
            'Latitud',
          ],
        ),
      ),
      pickupLongitude: _decimal(
        _value(
          map,
          const [
            'longitudRecogida',
            'LongitudRecogida',
            'lngRecogida',
            'LngRecogida',
            'lonRecogida',
            'LonRecogida',
            'ubicacionLongitud',
            'UbicacionLongitud',
            'longitud',
            'Longitud',
          ],
        ),
      ),
      petPhotoPath: _nullableText(
        _value(
              map,
              const [
                'perroFotoUrl',
                'PerroFotoUrl',
                'fotoPerroUrl',
                'FotoPerroUrl',
              ],
            ) ??
            _value(
              pet,
              const [
                'fotoUrl',
                'FotoUrl',
                'imagenUrl',
                'ImagenUrl',
              ],
            ),
      ),
      startPhotoPath: _nullableText(
        _value(
          map,
          const [
            'fotoInicioUrl',
            'FotoInicioUrl',
            'evidenciaInicioUrl',
            'EvidenciaInicioUrl',
          ],
        ),
      ),
      endPhotoPath: _nullableText(
        _value(
          map,
          const [
            'fotoFinUrl',
            'FotoFinUrl',
            'evidenciaFinUrl',
            'EvidenciaFinUrl',
          ],
        ),
      ),
      cancellationReason: _nullableText(
        _value(
          map,
          const [
            'motivoCancelacion',
            'MotivoCancelacion',
            'motivoCancelación',
            'MotivoCancelación',
          ],
        ),
      ),
      cancelledBy: _nullableText(
        _value(
          map,
          const [
            'canceladoPor',
            'CanceladoPor',
          ],
        ),
      ),
      rated: _boolean(
        _value(
          map,
          const [
            'calificado',
            'Calificado',
            'tieneCalificacion',
            'TieneCalificacion',
            'tieneCalificación',
            'TieneCalificación',
            'rated',
            'Rated',
          ],
        ),
      ),
      rawData: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(map),
      ),
    );
  }

  bool get hasValidId => id > 0;

  bool get isPending =>
      status == HomeWalkStatus.pending;

  bool get isAccepted =>
      status == HomeWalkStatus.accepted;

  bool get isInProgress =>
      status == HomeWalkStatus.inProgress;

  bool get isCompleted =>
      status == HomeWalkStatus.completed;

  bool get isCancelled =>
      status == HomeWalkStatus.cancelled;

  bool get isRejected =>
      status == HomeWalkStatus.rejected;

  bool get isFinished =>
      isCompleted || isCancelled || isRejected;

  bool get hasStartEvidence =>
      startPhotoPath != null;

  bool get hasEndEvidence =>
      endPhotoPath != null;

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

    if (value == null) {
      return 'No disponible';
    }

    return '\$${value.toStringAsFixed(2)}';
  }

  String get scheduledLabel {
    return _formatDate(scheduledAt);
  }

  String get startedLabel {
    return _formatDate(startedAt);
  }

  String get finishedLabel {
    return _formatDate(finishedAt);
  }

  String get cancelledLabel {
    return _formatDate(cancelledAt);
  }

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
    return Map<String, dynamic>.from(rawData);
  }

  static String _personName({
    dynamic directName,
    dynamic directLastName,
    Map<String, dynamic> person = const {},
    Map<String, dynamic> user = const {},
    required String fallback,
  }) {
    final direct = [
      _text(directName),
      _text(directLastName),
    ].where((part) => part.isNotEmpty).join(' ');

    if (direct.isNotEmpty) {
      return direct;
    }

    final fullName = _text(
      _value(
            person,
            const [
              'nombreCompleto',
              'NombreCompleto',
              'fullName',
              'FullName',
            ],
          ) ??
          _value(
            user,
            const [
              'nombreCompleto',
              'NombreCompleto',
              'fullName',
              'FullName',
            ],
          ),
    );

    if (fullName.isNotEmpty) {
      return fullName;
    }

    final firstName = _text(
      _value(
            person,
            const [
              'nombre',
              'Nombre',
              'name',
              'Name',
            ],
          ) ??
          _value(
            user,
            const [
              'nombre',
              'Nombre',
              'name',
              'Name',
            ],
          ),
    );

    final lastName = _text(
      _value(
            person,
            const [
              'apellido',
              'Apellido',
              'lastName',
              'LastName',
            ],
          ) ??
          _value(
            user,
            const [
              'apellido',
              'Apellido',
              'lastName',
              'LastName',
            ],
          ),
    );

    final result =
        '$firstName $lastName'.trim();

    return result.isEmpty ? fallback : result;
  }

  static String _formatDate(DateTime? date) {
    if (date == null) {
      return 'No disponible';
    }

    final local = date.toLocal();

    final day =
        local.day.toString().padLeft(2, '0');
    final month =
        local.month.toString().padLeft(2, '0');
    final hour =
        local.hour.toString().padLeft(2, '0');
    final minute =
        local.minute.toString().padLeft(2, '0');

    return '$day/$month/${local.year} · '
        '$hour:$minute';
  }

  static String? _publicUrl(
    String? path,
    String? baseUrl,
  ) {
    final value = path?.trim();

    if (value == null ||
        value.isEmpty ||
        value.toLowerCase() == 'null') {
      return null;
    }

    if (value.startsWith('http://') ||
        value.startsWith('https://')) {
      return value;
    }

    final server = baseUrl?.trim() ?? '';

    if (server.isEmpty) {
      return value;
    }

    final cleanServer = server.endsWith('/')
        ? server.substring(0, server.length - 1)
        : server;

    final cleanPath =
        value.startsWith('/') ? value : '/$value';

    return '$cleanServer$cleanPath';
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

  static String _text(
    dynamic value, {
    String fallback = '',
  }) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty ||
        text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  static String? _nullableText(dynamic value) {
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

  static double? _decimal(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value
          .toString()
          .trim()
          .replaceAll(',', '.'),
    );
  }

  static DateTime? _dateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value?.toString() ?? '',
    );
  }

  static bool _boolean(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text =
        value?.toString().trim().toLowerCase();

    return const {
      'true',
      '1',
      'sí',
      'si',
      'yes',
    }.contains(text);
  }
}