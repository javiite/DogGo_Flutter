import 'package:flutter/foundation.dart';

import '../../services/session_service.dart';
import 'session_state.dart';

class SessionController extends ChangeNotifier {
  SessionState _state = const SessionState();
  bool _disposed = false;

  SessionState get state => _state;

  Future<void> initialize() async {
    _setState(
      _state.copyWith(
        loading: true,
        clearError: true,
      ),
    );

    try {
      final results = await Future.wait<dynamic>([
        SessionService.obtenerToken(),
        SessionService.obtenerUsuarioId(),
        SessionService.obtenerNombre(),
        SessionService.obtenerEmail(),
        SessionService.obtenerRol(),
      ]);

      if (_disposed) {
        return;
      }

      final token = results[0]?.toString().trim();
      final userId = results[1] is int
          ? results[1] as int
          : int.tryParse(
              results[1]?.toString() ?? '',
            );

      final name =
          results[2]?.toString().trim() ?? '';

      final email =
          results[3]?.toString().trim() ?? '';

      final rawRole =
          results[4]?.toString().trim();

      final authenticated =
          token != null && token.isNotEmpty;

      _setState(
        SessionState(
          loading: false,
          authenticated: authenticated,
          userId: userId,
          token: authenticated ? token : null,
          name: name.isEmpty ? 'Usuario' : name,
          email: email,
          role: SessionService.normalizarRol(rawRole),
        ),
      );
    } catch (error) {
      if (_disposed) {
        return;
      }

      _setState(
        SessionState(
          loading: false,
          authenticated: false,
          errorMessage: _cleanError(error),
        ),
      );
    }
  }

  Future<void> refresh() {
    return initialize();
  }

  Future<void> saveFromLogin(
    Map<String, dynamic> data,
  ) async {
    await SessionService.guardarSesionDesdeLogin(data);
    await initialize();
  }

  Future<void> closeSession() async {
    _setState(
      _state.copyWith(
        loading: true,
        clearError: true,
      ),
    );

    try {
      await SessionService.cerrarSesion();

      if (_disposed) {
        return;
      }

      _setState(
        const SessionState(
          loading: false,
          authenticated: false,
        ),
      );
    } catch (error) {
      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          loading: false,
          errorMessage: _cleanError(error),
        ),
      );
    }
  }

  String _cleanError(Object error) {
    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();

    return message.isEmpty
        ? 'No se pudo revisar la sesión.'
        : message;
  }

  void _setState(SessionState newState) {
    if (_disposed) {
      return;
    }

    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}