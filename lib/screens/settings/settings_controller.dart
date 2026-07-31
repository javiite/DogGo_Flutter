import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/permissions/app_permission.dart';
import '../../services/permiso_service.dart';
import '../../services/storage_service.dart';
import 'settings_state.dart';

enum SettingsResultCode {
  success,
  invalidUrl,
  permissionGranted,
  permissionDenied,
  openSettingsRequired,
  failed,
}

class SettingsResult {
  final bool success;
  final String message;
  final SettingsResultCode code;

  const SettingsResult({
    required this.success,
    required this.message,
    required this.code,
  });

  const SettingsResult.success(
    this.message, {
    this.code = SettingsResultCode.success,
  }) : success = true;

  const SettingsResult.failure(
    this.message, {
    this.code = SettingsResultCode.failed,
  }) : success = false;

  bool get requiresAppSettings {
    return code ==
        SettingsResultCode
            .openSettingsRequired;
  }
}

class SettingsController
    extends ChangeNotifier {
  final http.Client _httpClient;
  final bool _ownsHttpClient;

  SettingsState _state =
      const SettingsState();

  bool _disposed = false;
  bool _loadingInProgress = false;

  SettingsController({
    http.Client? httpClient,
  })  : _httpClient =
            httpClient ?? http.Client(),
        _ownsHttpClient =
            httpClient == null;

  SettingsState get state => _state;

  Future<void> initialize() async {
    if (_loadingInProgress) {
      return;
    }

    _loadingInProgress = true;

    _setState(
      _state.copyWith(
        loading: true,
        clearError: true,
        clearMessage: true,
      ),
    );

    try {
      final results =
          await Future.wait<dynamic>([
        StorageService.obtenerBaseUrl(),
        PermisoService
            .obtenerTodosLosEstados(),
      ]);

      final baseUrl =
          results[0] as String? ?? '';
      final permissions = Map<
          AppPermissionType,
          AppPermissionInfo>.from(
        results[1] as Map,
      );

      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          baseUrl: baseUrl,
          permissions: permissions,
          loading: false,
          clearError: true,
        ),
      );
    } catch (error) {
      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          loading: false,
          error: _cleanError(
            error,
            fallback:
                'No se pudo cargar la configuración.',
          ),
        ),
      );
    } finally {
      _loadingInProgress = false;
    }
  }

  Future<void> refreshPermissions() async {
    if (_state.requestingPermission !=
        null) {
      return;
    }

    try {
      final permissions =
          await PermisoService
              .obtenerTodosLosEstados();

      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          permissions: permissions,
          clearError: true,
        ),
      );
    } catch (error) {
      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          error: _cleanError(
            error,
            fallback:
                'No se pudieron revisar los permisos.',
          ),
        ),
      );
    }
  }

  Future<SettingsResult> saveServer(
    String value,
  ) async {
    if (_state.savingServer) {
      return const SettingsResult.failure(
        'La dirección ya se está guardando.',
      );
    }

    final validation =
        validateServerUrl(value);

    if (!validation.success) {
      return validation;
    }

    final cleanUrl =
        normalizeServerUrl(value);

    _setState(
      _state.copyWith(
        savingServer: true,
        clearError: true,
        clearMessage: true,
      ),
    );

    try {
      await StorageService.guardarBaseUrl(
        cleanUrl,
      );

      if (_disposed) {
        return const SettingsResult.failure(
          'La pantalla ya no está disponible.',
        );
      }

      _setState(
        _state.copyWith(
          baseUrl: cleanUrl,
          savingServer: false,
          message:
              'Servidor actualizado correctamente.',
          clearError: true,
        ),
      );

      return const SettingsResult.success(
        'Servidor actualizado correctamente.',
      );
    } catch (error) {
      final message = _cleanError(
        error,
        fallback:
            'No se pudo guardar la dirección del servidor.',
      );

      if (!_disposed) {
        _setState(
          _state.copyWith(
            savingServer: false,
            error: message,
          ),
        );
      }

      return SettingsResult.failure(
        message,
      );
    } finally {
      if (!_disposed &&
          _state.savingServer) {
        _setState(
          _state.copyWith(
            savingServer: false,
          ),
        );
      }
    }
  }

  Future<SettingsResult> testServer(
    String value,
  ) async {
    if (_state.testingServer) {
      return const SettingsResult.failure(
        'La conexión ya se está probando.',
      );
    }

    final validation =
        validateServerUrl(value);

    if (!validation.success) {
      return validation;
    }

    final cleanUrl =
        normalizeServerUrl(value);
    final uri = Uri.parse(cleanUrl);

    _setState(
      _state.copyWith(
        testingServer: true,
        clearError: true,
        clearMessage: true,
      ),
    );

    try {
      final response = await _httpClient
          .get(
            uri,
            headers: const {
              'Accept':
                  'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 8),
          );

      if (_disposed) {
        return const SettingsResult.failure(
          'La pantalla ya no está disponible.',
        );
      }

      final statusCode =
          response.statusCode;

      final message = statusCode >= 500
          ? 'El servidor respondió, pero presentó un error interno ($statusCode).'
          : 'Conexión correcta. El servidor respondió con código $statusCode.';

      _setState(
        _state.copyWith(
          testingServer: false,
          message: message,
          clearError: true,
        ),
      );

      return SettingsResult.success(
        message,
      );
    } on TimeoutException {
      const message =
          'El servidor tardó demasiado en responder. Revisa la IP, el puerto y la red.';

      if (!_disposed) {
        _setState(
          _state.copyWith(
            testingServer: false,
            error: message,
          ),
        );
      }

      return const SettingsResult.failure(
        message,
      );
    } catch (error) {
      final message = _connectionError(
        error,
      );

      if (!_disposed) {
        _setState(
          _state.copyWith(
            testingServer: false,
            error: message,
          ),
        );
      }

      return SettingsResult.failure(
        message,
      );
    } finally {
      if (!_disposed &&
          _state.testingServer) {
        _setState(
          _state.copyWith(
            testingServer: false,
          ),
        );
      }
    }
  }

  Future<SettingsResult>
      requestPermission(
    AppPermissionType type,
  ) async {
    if (_state.requestingPermission !=
        null) {
      return const SettingsResult.failure(
        'Ya se está revisando otro permiso.',
      );
    }

    final current =
        _state.permissionFor(type);

    if (current.isGranted) {
      return SettingsResult.success(
        'El permiso de ${type.title.toLowerCase()} ya está activo.',
        code:
            SettingsResultCode.permissionGranted,
      );
    }

    if (current.mustOpenSettings) {
      return SettingsResult.failure(
        'El permiso de ${type.title.toLowerCase()} está bloqueado. Debes activarlo desde los ajustes del teléfono.',
        code: SettingsResultCode
            .openSettingsRequired,
      );
    }

    _setState(
      _state.copyWith(
        requestingPermission: type,
        clearError: true,
        clearMessage: true,
      ),
    );

    try {
      final updated =
          await PermisoService.solicitar(
        type,
      );

      if (_disposed) {
        return const SettingsResult.failure(
          'La pantalla ya no está disponible.',
        );
      }

      final permissions = Map<
          AppPermissionType,
          AppPermissionInfo>.from(
        _state.permissions,
      );

      permissions[type] = updated;

      _setState(
        _state.copyWith(
          permissions: permissions,
          clearRequestingPermission: true,
          clearError: true,
        ),
      );

      if (updated.isGranted) {
        final message =
            'Permiso de ${type.title.toLowerCase()} activado.';

        _setState(
          _state.copyWith(
            message: message,
          ),
        );

        return SettingsResult.success(
          message,
          code: SettingsResultCode
              .permissionGranted,
        );
      }

      if (updated.mustOpenSettings) {
        return SettingsResult.failure(
          'El permiso quedó bloqueado. Puedes activarlo desde los ajustes del teléfono.',
          code: SettingsResultCode
              .openSettingsRequired,
        );
      }

      return SettingsResult.failure(
        'El permiso de ${type.title.toLowerCase()} no fue autorizado.',
        code: SettingsResultCode
            .permissionDenied,
      );
    } catch (error) {
      final message = _cleanError(
        error,
        fallback:
            'No se pudo solicitar el permiso.',
      );

      if (!_disposed) {
        _setState(
          _state.copyWith(
            clearRequestingPermission:
                true,
            error: message,
          ),
        );
      }

      return SettingsResult.failure(
        message,
      );
    } finally {
      if (!_disposed &&
          _state.requestingPermission !=
              null) {
        _setState(
          _state.copyWith(
            clearRequestingPermission:
                true,
          ),
        );
      }
    }
  }

  Future<SettingsResult>
      openAppSettings() async {
    try {
      final opened =
          await PermisoService
              .abrirConfiguracion();

      if (!opened) {
        return const SettingsResult.failure(
          'No se pudieron abrir los ajustes del teléfono.',
        );
      }

      return const SettingsResult.success(
        'Ajustes del teléfono abiertos.',
      );
    } catch (error) {
      return SettingsResult.failure(
        _cleanError(
          error,
          fallback:
              'No se pudieron abrir los ajustes del teléfono.',
        ),
      );
    }
  }

  SettingsResult validateServerUrl(
    String value,
  ) {
    final cleanUrl =
        normalizeServerUrl(value);

    if (cleanUrl.isEmpty) {
      return const SettingsResult.failure(
        'Escribe la dirección del servidor.',
        code:
            SettingsResultCode.invalidUrl,
      );
    }

    final uri =
        Uri.tryParse(cleanUrl);

    if (uri == null ||
        !uri.hasScheme ||
        uri.host.trim().isEmpty) {
      return const SettingsResult.failure(
        'Escribe una dirección válida, por ejemplo http://127.0.0.1:5230.',
        code:
            SettingsResultCode.invalidUrl,
      );
    }

    final scheme =
        uri.scheme.toLowerCase();

    if (scheme != 'http' &&
        scheme != 'https') {
      return const SettingsResult.failure(
        'La dirección debe comenzar con http:// o https://.',
        code:
            SettingsResultCode.invalidUrl,
      );
    }

    final path =
        uri.path.toLowerCase();

    if (path == '/api' ||
        path.endsWith('/api')) {
      return const SettingsResult.failure(
        'Guarda únicamente la URL base, sin agregar /api al final.',
        code:
            SettingsResultCode.invalidUrl,
      );
    }

    return const SettingsResult.success(
      'Dirección válida.',
    );
  }

  String normalizeServerUrl(
    String value,
  ) {
    var clean = value.trim();

    while (clean.endsWith('/')) {
      clean = clean.substring(
        0,
        clean.length - 1,
      );
    }

    return clean;
  }

  void clearFeedback() {
    if (_state.error == null &&
        _state.message == null) {
      return;
    }

    _setState(
      _state.copyWith(
        clearError: true,
        clearMessage: true,
      ),
    );
  }

  String _connectionError(
    Object error,
  ) {
    final raw = error.toString();

    if (raw.contains(
          'Connection refused',
        ) ||
        raw.contains(
          'Failed host lookup',
        ) ||
        raw.contains(
          'Network is unreachable',
        ) ||
        raw.contains(
          'No route to host',
        )) {
      return 'No se pudo alcanzar el servidor. Revisa que el backend esté encendido y que la dirección sea correcta.';
    }

    return _cleanError(
      error,
      fallback:
          'No se pudo conectar con el servidor.',
    );
  }

  String _cleanError(
    Object error, {
    required String fallback,
  }) {
    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ClientException: ', '')
        .trim();

    return message.isEmpty
        ? fallback
        : message;
  }

  void _setState(
    SettingsState newState,
  ) {
    if (_disposed) {
      return;
    }

    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;

    if (_ownsHttpClient) {
      _httpClient.close();
    }

    super.dispose();
  }
}