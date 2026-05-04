import 'package:permission_handler/permission_handler.dart';

class PermisoService {
  static Future<bool> pedirCamara() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> pedirUbicacion() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  static Future<bool> camaraConcedida() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  static Future<bool> ubicacionConcedida() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  static Future<bool> abrirConfiguracion() async {
    return openAppSettings();
  }
}
