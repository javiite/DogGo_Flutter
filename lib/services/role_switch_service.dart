import 'api_service.dart';
import 'background_tracking_service.dart';
import 'session_service.dart';

enum DogGoRoleMode { owner, walker }

extension DogGoRoleModeData on DogGoRoleMode {
  String get apiValue {
    return switch (this) {
      DogGoRoleMode.owner => 'Duenio',
      DogGoRoleMode.walker => 'Paseador',
    };
  }

  String get label {
    return switch (this) {
      DogGoRoleMode.owner => 'Dueño',
      DogGoRoleMode.walker => 'Paseador',
    };
  }
}

class RoleSwitchResult {
  final bool success;
  final String message;
  final String role;
  final bool profileCreated;
  final bool requiresProfileCompletion;

  const RoleSwitchResult({
    required this.success,
    required this.message,
    this.role = '',
    this.profileCreated = false,
    this.requiresProfileCompletion = false,
  });

  const RoleSwitchResult.failure(String message)
    : this(success: false, message: message);
}

abstract final class RoleSwitchService {
  static Future<RoleSwitchResult> changeMode(DogGoRoleMode mode) async {
    await BackgroundTrackingService.detenerTracking();
    final response = await ApiService.postAuth('/api/auth/cambiar-modo', {
      'rol': mode.apiValue,
    });

    final statusCode = response['statusCode'];

    final body = _asMap(response['body']);

    final statusOk = statusCode is int && statusCode >= 200 && statusCode < 300;

    if (!statusOk || body['success'] != true) {
      return RoleSwitchResult.failure(
        _firstText([body['message'], body['mensaje'], body['error']]) ??
            'No se pudo cambiar el modo.',
      );
    }

    final data = _nullableMap(body['data']);

    if (data == null) {
      return const RoleSwitchResult.failure(
        'El servidor no devolvió la nueva sesión.',
      );
    }

    final token = _firstText([
      data['token'],
      data['Token'],
      data['jwt'],
      data['Jwt'],
      data['accessToken'],
      data['AccessToken'],
    ]);

    final rawRole = _firstText([
      data['rol'],
      data['Rol'],
      data['role'],
      data['Role'],
    ]);

    if (token == null || rawRole == null) {
      return const RoleSwitchResult.failure('La nueva sesión está incompleta.');
    }

    await SessionService.guardarSesionDesdeLogin(data);

    final savedRole = await SessionService.obtenerRol();

    if (savedRole == null || savedRole.trim().isEmpty) {
      return const RoleSwitchResult.failure(
        'No se pudo guardar el nuevo modo.',
      );
    }

    return RoleSwitchResult(
      success: true,
      message:
          _firstText([body['message'], body['mensaje']]) ??
          'Modo ${mode.label} activado.',
      role: SessionService.normalizarRol(savedRole),
      profileCreated: _asBool(data['perfilCreado'] ?? data['PerfilCreado']),
      requiresProfileCompletion: _asBool(
        data['requiereCompletarPerfil'] ?? data['RequiereCompletarPerfil'],
      ),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    return _nullableMap(value) ?? <String, dynamic>{};
  }

  static Map<String, dynamic>? _nullableMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  static String? _firstText(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();

      if (text != null && text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().trim().toLowerCase();

    return text == 'true' || text == '1' || text == 'si' || text == 'sí';
  }
}
