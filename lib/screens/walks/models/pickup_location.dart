class PickupLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String reference;

  const PickupLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.reference = '',
  });

  factory PickupLocation.fromMap(
    Map<String, dynamic> map,
  ) {
    final latitude = _decimal(
      _value(
        map,
        const [
          'latitudRecogida',
          'LatitudRecogida',
          'latitud',
          'Latitud',
          'lat',
          'Lat',
          'latitude',
          'Latitude',
        ],
      ),
    );

    final longitude = _decimal(
      _value(
        map,
        const [
          'longitudRecogida',
          'LongitudRecogida',
          'longitud',
          'Longitud',
          'lng',
          'Lng',
          'lon',
          'Lon',
          'longitude',
          'Longitude',
        ],
      ),
    );

    if (latitude == null || longitude == null) {
      throw const FormatException(
        'La ubicación no contiene coordenadas válidas.',
      );
    }

    final address = _text(
      _value(
        map,
        const [
          'direccionRecogida',
          'DireccionRecogida',
          'direccion',
          'Direccion',
          'ubicacionTexto',
          'UbicacionTexto',
          'ubicacionRecogidaTexto',
          'UbicacionRecogidaTexto',
          'texto',
          'Texto',
          'address',
          'Address',
        ],
      ),
      fallback: 'Ubicación seleccionada',
    );

    final reference = _text(
      _value(
        map,
        const [
          'referenciasRecogida',
          'ReferenciasRecogida',
          'referencia',
          'Referencia',
          'reference',
          'Reference',
        ],
      ),
    );

    return PickupLocation(
      latitude: latitude,
      longitude: longitude,
      address: address,
      reference: reference,
    );
  }

  String get coordinatesLabel {
    return '${latitude.toStringAsFixed(5)}, '
        '${longitude.toStringAsFixed(5)}';
  }

  String get displayAddress {
    final value = address.trim();

    return value.isEmpty
        ? coordinatesLabel
        : value;
  }

  PickupLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? reference,
  }) {
    return PickupLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      reference: reference ?? this.reference,
    );
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
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty ||
        text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
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
}