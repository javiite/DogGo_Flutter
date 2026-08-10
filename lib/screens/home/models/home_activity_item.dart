enum HomeActivityType {
  walkRequested,
  walkAccepted,
  walkStarted,
  walkCompleted,
  walkCancelled,
  newPhoto,
  newMessage,
  routeDeviation,
  routeRecovered,
  checkpointReached,
  notification,
  unknown,
}

class HomeActivityItem {
  final int? id;
  final HomeActivityType type;
  final String title;
  final String description;
  final DateTime? occurredAt;
  final int? referenceId;
  final bool read;

  const HomeActivityItem({
    this.id,
    required this.type,
    required this.title,
    required this.description,
    this.occurredAt,
    this.referenceId,
    this.read = false,
  });

  HomeActivityItem copyWith({
    int? id,
    HomeActivityType? type,
    String? title,
    String? description,
    DateTime? occurredAt,
    int? referenceId,
    bool? read,
  }) {
    return HomeActivityItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      occurredAt: occurredAt ?? this.occurredAt,
      referenceId: referenceId ?? this.referenceId,
      read: read ?? this.read,
    );
  }

  factory HomeActivityItem.fromMap(Map<String, dynamic> map) {
    final typeValue = _firstValue(map, const [
      'tipo',
      'Tipo',
      'type',
      'Type',
      'categoria',
      'Categoria',
    ]);

    final titleValue = _firstValue(map, const [
      'titulo',
      'Titulo',
      'title',
      'Title',
    ]);

    final descriptionValue = _firstValue(map, const [
      'mensaje',
      'Mensaje',
      'descripcion',
      'Descripcion',
      'description',
      'Description',
    ]);

    final dateValue = _firstValue(map, const [
      'fecha',
      'Fecha',
      'fechaCreacion',
      'FechaCreacion',
      'createdAt',
      'CreatedAt',
    ]);

    return HomeActivityItem(
      id: _toInt(
        _firstValue(map, const [
          'id',
          'Id',
          'notificacionId',
          'NotificacionId',
        ]),
      ),
      type: _typeFromValue('$typeValue $titleValue $descriptionValue'),
      title: titleValue?.toString().trim().isNotEmpty == true
          ? titleValue.toString().trim()
          : 'Actividad de DogGo',
      description: descriptionValue?.toString().trim().isNotEmpty == true
          ? descriptionValue.toString().trim()
          : 'Tienes una nueva actualización.',
      occurredAt: _toDateTime(dateValue),
      referenceId: _toInt(
        _firstValue(map, const [
          'referenciaId',
          'ReferenciaId',
          'paseoId',
          'PaseoId',
        ]),
      ),
      read: _toBool(_firstValue(map, const ['leida', 'Leida', 'read', 'Read'])),
    );
  }

  static HomeActivityType _typeFromValue(dynamic value) {
    final normalized = _normalize(value?.toString() ?? '');

    if ((normalized.contains('rutapaseo') || normalized.contains('ruta')) &&
        (normalized.contains('fuera') || normalized.contains('desvio'))) {
      return HomeActivityType.routeDeviation;
    }

    if ((normalized.contains('rutapaseo') || normalized.contains('ruta')) &&
        (normalized.contains('regres') || normalized.contains('reingreso'))) {
      return HomeActivityType.routeRecovered;
    }

    if (normalized.contains('puntoalcanzado') ||
        normalized.contains('puntodecontrol') ||
        normalized.contains('checkpoint')) {
      return HomeActivityType.checkpointReached;
    }

    if (normalized.contains('acept')) {
      return HomeActivityType.walkAccepted;
    }

    if (normalized.contains('inici') || normalized.contains('encurso')) {
      return HomeActivityType.walkStarted;
    }

    if (normalized.contains('final') || normalized.contains('complet')) {
      return HomeActivityType.walkCompleted;
    }

    if (normalized.contains('cancel') || normalized.contains('rechaz')) {
      return HomeActivityType.walkCancelled;
    }

    if (normalized.contains('solic') || normalized.contains('pendient')) {
      return HomeActivityType.walkRequested;
    }

    if (normalized.contains('foto') ||
        normalized.contains('evidencia') ||
        normalized.contains('imagen')) {
      return HomeActivityType.newPhoto;
    }

    if (normalized.contains('chat') || normalized.contains('mensaje')) {
      return HomeActivityType.newMessage;
    }

    if (normalized.contains('notifica')) {
      return HomeActivityType.notification;
    }

    return HomeActivityType.unknown;
  }

  static dynamic _firstValue(Map<String, dynamic> map, List<String> keys) {
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

    return int.tryParse(value?.toString() ?? '');
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized = value?.toString().trim().toLowerCase();

    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'si' ||
        normalized == 'sí';
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value?.toString() ?? '');
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
