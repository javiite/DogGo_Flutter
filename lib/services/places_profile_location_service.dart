import 'usuario_service.dart';

class PlacesProfileLocationService {
  final UsuarioService _usuarioService;

  PlacesProfileLocationService({
    UsuarioService? usuarioService,
  }) : _usuarioService =
            usuarioService ?? UsuarioService();

  Future<Map<String, dynamic>?>
      getDefaultPickupLocation() async {
    try {
      final response =
          await _usuarioService.obtenerPerfilDuenio();

      final profile =
          _extractMap(response['perfil']) ?? response;

      final latitude = _toDouble(profile['latitud']);

      final longitude = _toDouble(profile['longitud']);

      if (!_validCoordinates(
        latitude,
        longitude,
      )) {
        return null;
      }

      final address = _firstText([profile['direccion']]);

      final zone = _firstText([profile['zona']]);

      final locationText = address ??
          zone ??
          'Ubicación de recogida';

      return {
        'latitud': latitude,
        'longitud': longitude,
        'texto': locationText,
        'origen': 'perfil',
      };
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _extractMap(
    dynamic value,
  ) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  String? _firstText(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';

      if (text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  bool _validCoordinates(
    double? latitude,
    double? longitude,
  ) {
    if (latitude == null || longitude == null) {
      return false;
    }

    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return false;
    }

    return latitude != 0 || longitude != 0;
  }
}
