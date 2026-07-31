enum AppPermissionType {
  camera,
  location,
  notifications,
}

enum AppPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  provisional,
  unavailable,
}

extension AppPermissionTypeData
    on AppPermissionType {
  String get title {
    switch (this) {
      case AppPermissionType.camera:
        return 'Cámara';
      case AppPermissionType.location:
        return 'Ubicación';
      case AppPermissionType.notifications:
        return 'Notificaciones';
    }
  }

  String get description {
    switch (this) {
      case AppPermissionType.camera:
        return 'Para tomar fotos de mascotas y evidencias.';
      case AppPermissionType.location:
        return 'Para usar el mapa y compartir el recorrido del paseo.';
      case AppPermissionType.notifications:
        return 'Para recibir avisos importantes en el teléfono.';
    }
  }

  String get dialogDescription {
    switch (this) {
      case AppPermissionType.camera:
        return 'DogGo necesita la cámara para agregar fotos de mascotas y evidencias de los paseos.';
      case AppPermissionType.location:
        return 'DogGo necesita tu ubicación para seleccionar puntos de recogida y compartir el recorrido durante un paseo activo.';
      case AppPermissionType.notifications:
        return 'DogGo necesita autorización para mostrar avisos importantes en el teléfono.';
    }
  }
}

extension AppPermissionStatusData
    on AppPermissionStatus {
  bool get isGranted {
    return this == AppPermissionStatus.granted ||
        this == AppPermissionStatus.limited ||
        this ==
            AppPermissionStatus.provisional;
  }

  bool get mustOpenSettings {
    return this ==
            AppPermissionStatus
                .permanentlyDenied ||
        this ==
            AppPermissionStatus.restricted;
  }

  bool get canRequest {
    return this == AppPermissionStatus.denied;
  }

  String get label {
    switch (this) {
      case AppPermissionStatus.granted:
        return 'Permitido';
      case AppPermissionStatus.denied:
        return 'Pendiente';
      case AppPermissionStatus.permanentlyDenied:
        return 'Bloqueado';
      case AppPermissionStatus.restricted:
        return 'Restringido';
      case AppPermissionStatus.limited:
        return 'Limitado';
      case AppPermissionStatus.provisional:
        return 'Provisional';
      case AppPermissionStatus.unavailable:
        return 'No disponible';
    }
  }
}

class AppPermissionInfo {
  final AppPermissionType type;
  final AppPermissionStatus status;

  const AppPermissionInfo({
    required this.type,
    required this.status,
  });

  bool get isGranted {
    return status.isGranted;
  }

  bool get mustOpenSettings {
    return status.mustOpenSettings;
  }

  AppPermissionInfo copyWith({
    AppPermissionType? type,
    AppPermissionStatus? status,
  }) {
    return AppPermissionInfo(
      type: type ?? this.type,
      status: status ?? this.status,
    );
  }
}