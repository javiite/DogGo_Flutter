import 'package:permission_handler/permission_handler.dart';

import '../core/permissions/app_permission.dart';

class PermisoService {
  const PermisoService();

  static Future<bool> pedirCamara() async {
    final status = await Permission.camera.request();

    return status.isGranted ||
        status.isLimited ||
        status.isProvisional;
  }

  static Future<bool> pedirUbicacion() async {
    final status = await Permission
        .locationWhenInUse
        .request();

    return status.isGranted ||
        status.isLimited ||
        status.isProvisional;
  }

  static Future<bool>
      pedirNotificaciones() async {
    final status =
        await Permission.notification.request();

    return status.isGranted ||
        status.isLimited ||
        status.isProvisional;
  }

  static Future<bool>
      camaraConcedida() async {
    final status =
        await Permission.camera.status;

    return status.isGranted ||
        status.isLimited ||
        status.isProvisional;
  }

  static Future<bool>
      ubicacionConcedida() async {
    final status = await Permission
        .locationWhenInUse
        .status;

    return status.isGranted ||
        status.isLimited ||
        status.isProvisional;
  }

  static Future<bool>
      notificacionesConcedidas() async {
    final status =
        await Permission.notification.status;

    return status.isGranted ||
        status.isLimited ||
        status.isProvisional;
  }

  static Future<AppPermissionInfo>
      obtenerEstado(
    AppPermissionType type,
  ) async {
    try {
      final permission =
          _permissionFor(type);
      final status = await permission.status;

      return AppPermissionInfo(
        type: type,
        status: _convertStatus(status),
      );
    } catch (_) {
      return AppPermissionInfo(
        type: type,
        status:
            AppPermissionStatus.unavailable,
      );
    }
  }

  static Future<
          Map<AppPermissionType,
              AppPermissionInfo>>
      obtenerTodosLosEstados() async {
    final results = await Future.wait(
      AppPermissionType.values.map(
        obtenerEstado,
      ),
    );

    return {
      for (final result in results)
        result.type: result,
    };
  }

  static Future<AppPermissionInfo>
      solicitar(
    AppPermissionType type,
  ) async {
    try {
      final permission =
          _permissionFor(type);
      final status =
          await permission.request();

      return AppPermissionInfo(
        type: type,
        status: _convertStatus(status),
      );
    } catch (_) {
      return AppPermissionInfo(
        type: type,
        status:
            AppPermissionStatus.unavailable,
      );
    }
  }

  static Future<bool>
      abrirConfiguracion() async {
    return openAppSettings();
  }

  static Permission _permissionFor(
    AppPermissionType type,
  ) {
    switch (type) {
      case AppPermissionType.camera:
        return Permission.camera;
      case AppPermissionType.location:
        return Permission.locationWhenInUse;
      case AppPermissionType.notifications:
        return Permission.notification;
    }
  }

  static AppPermissionStatus
      _convertStatus(
    PermissionStatus status,
  ) {
    if (status.isGranted) {
      return AppPermissionStatus.granted;
    }

    if (status.isPermanentlyDenied) {
      return AppPermissionStatus
          .permanentlyDenied;
    }

    if (status.isRestricted) {
      return AppPermissionStatus.restricted;
    }

    if (status.isLimited) {
      return AppPermissionStatus.limited;
    }

    if (status.isProvisional) {
      return AppPermissionStatus.provisional;
    }

    if (status.isDenied) {
      return AppPermissionStatus.denied;
    }

    return AppPermissionStatus.unavailable;
  }
}