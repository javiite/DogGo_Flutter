class PetPhoto {
  final int id;
  final String url;
  final int order;
  final bool isPrimary;
  final DateTime? createdAt;

  const PetPhoto({
    required this.id,
    required this.url,
    required this.order,
    required this.isPrimary,
    required this.createdAt,
  });

  factory PetPhoto.fromMap(
    Map<String, dynamic> map,
  ) {
    return PetPhoto(
      id: _readInt(
            map,
            const ['id', 'Id'],
          ) ??
          0,
      url: _readText(
        map,
        const [
          'url',
          'Url',
          'fotoUrl',
          'FotoUrl',
          'imagenUrl',
          'ImagenUrl',
        ],
      ),
      order: _readInt(
            map,
            const [
              'orden',
              'Orden',
              'order',
              'Order',
            ],
          ) ??
          0,
      isPrimary: _readBool(
        map,
        const [
          'esPrincipal',
          'EsPrincipal',
          'principal',
          'isPrimary',
        ],
      ),
      createdAt: _readDate(
        map,
        const [
          'fechaCreacion',
          'FechaCreacion',
          'createdAt',
          'CreatedAt',
        ],
      ),
    );
  }

  bool get hasValidId => id > 0;

  String? publicUrl(String? baseUrl) {
    final path = url.trim();

    if (path.isEmpty ||
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

  static List<PetPhoto> listFrom(
    dynamic value,
  ) {
    if (value is! List) {
      return const [];
    }

    final photos = value
        .whereType<Map>()
        .map(
          (item) => PetPhoto.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((photo) => photo.url.isNotEmpty)
        .toList();

    photos.sort((first, second) {
      if (first.isPrimary != second.isPrimary) {
        return first.isPrimary ? -1 : 1;
      }

      return first.order.compareTo(
        second.order,
      );
    });

    return List<PetPhoto>.unmodifiable(
      photos,
    );
  }

  static dynamic _value(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      if (map[key] != null) {
        return map[key];
      }
    }

    return null;
  }

  static String _readText(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final text =
        _value(map, keys)?.toString().trim() ??
            '';

    return text.toLowerCase() == 'null'
        ? ''
        : text;
  }

  static int? _readInt(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final value = _value(map, keys);

    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  static bool _readBool(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final value = _value(map, keys);

    if (value is bool) return value;
    if (value is num) return value != 0;

    final text =
        value?.toString().toLowerCase();

    return text == 'true' || text == '1';
  }

  static DateTime? _readDate(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final value = _value(map, keys);

    if (value is DateTime) {
      return value.toLocal();
    }

    final parsed = DateTime.tryParse(
      value?.toString() ?? '',
    );

    return parsed?.toLocal();
  }
}