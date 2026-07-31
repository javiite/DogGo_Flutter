import '../../core/permissions/app_permission.dart';

class SettingsState {
  final String baseUrl;
  final Map<AppPermissionType,
      AppPermissionInfo> permissions;
  final bool loading;
  final bool savingServer;
  final bool testingServer;
  final AppPermissionType?
      requestingPermission;
  final String? error;
  final String? message;

  const SettingsState({
    this.baseUrl = '',
    this.permissions = const {},
    this.loading = true,
    this.savingServer = false,
    this.testingServer = false,
    this.requestingPermission,
    this.error,
    this.message,
  });

  bool get busy {
    return savingServer ||
        testingServer ||
        requestingPermission != null;
  }

  int get grantedPermissionCount {
    return permissions.values
        .where((permission) {
      return permission.isGranted;
    }).length;
  }

  int get totalPermissionCount {
    return AppPermissionType.values.length;
  }

  bool get allPermissionsGranted {
    return grantedPermissionCount ==
        totalPermissionCount;
  }

  AppPermissionInfo permissionFor(
    AppPermissionType type,
  ) {
    return permissions[type] ??
        AppPermissionInfo(
          type: type,
          status:
              AppPermissionStatus.unavailable,
        );
  }

  bool isRequesting(
    AppPermissionType type,
  ) {
    return requestingPermission == type;
  }

  SettingsState copyWith({
    String? baseUrl,
    Map<AppPermissionType,
            AppPermissionInfo>?
        permissions,
    bool? loading,
    bool? savingServer,
    bool? testingServer,
    AppPermissionType?
        requestingPermission,
    bool clearRequestingPermission = false,
    String? error,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
  }) {
    return SettingsState(
      baseUrl: baseUrl ?? this.baseUrl,
      permissions:
          permissions ?? this.permissions,
      loading: loading ?? this.loading,
      savingServer:
          savingServer ?? this.savingServer,
      testingServer:
          testingServer ?? this.testingServer,
      requestingPermission:
          clearRequestingPermission
              ? null
              : requestingPermission ??
                  this.requestingPermission,
      error: clearError
          ? null
          : error ?? this.error,
      message: clearMessage
          ? null
          : message ?? this.message,
    );
  }
}