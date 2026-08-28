import 'package:geolocator/geolocator.dart';

import 'permiso_service.dart';

class LocationService {
  Future<bool> servicioUbicacionActivo() async {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<bool> pedirPermisoUbicacion() async {
    final servicioActivo = await servicioUbicacionActivo();

    if (!servicioActivo) {
      throw Exception('El GPS del teléfono está apagado.');
    }

    final permisoPlugin = await PermisoService.pedirUbicacion();

    if (!permisoPlugin) {
      throw Exception('No se concedió permiso de ubicación.');
    }

    LocationPermission permiso = await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.denied) {
      throw Exception('Permiso de ubicación denegado.');
    }

    if (permiso == LocationPermission.deniedForever) {
      throw Exception(
        'Permiso de ubicación bloqueado. Actívalo desde configuración.',
      );
    }

    return true;
  }

  Future<Position> obtenerUbicacionActual() async {
    await pedirPermisoUbicacion();

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
  }

  Stream<Position> escucharUbicacion() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 8,
    );

    return Geolocator.getPositionStream(locationSettings: settings);
  }

  String formatearCoordenadas(Position position) {
    final lat = position.latitude.toStringAsFixed(6);
    final lng = position.longitude.toStringAsFixed(6);

    return '$lat, $lng';
  }
}
