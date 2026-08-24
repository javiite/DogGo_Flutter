import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../services/paseadores_service.dart';
import '../../services/session_service.dart';
import '../../services/storage_service.dart';
import '../../services/usuario_service.dart';
import 'profile_state.dart';

class ProfileController extends ChangeNotifier {
  final UsuarioService _usuarioService;

  ProfileState _state = const ProfileState();
  bool _disposed = false;
  bool _requestInProgress = false;

  ProfileController({UsuarioService? usuarioService})
    : _usuarioService = usuarioService ?? UsuarioService();

  ProfileState get state => _state;

  bool get isLoading => _state.loading;

  bool get hasError => _state.error != null;

  Future<void> initialize() {
    return loadProfile();
  }

  Future<void> refresh() {
    return loadProfile();
  }

  Future<void> loadProfile() async {
    if (_requestInProgress) return;

    _requestInProgress = true;

    _setState(_state.copyWith(loading: true, clearError: true));

    try {
      final results = await Future.wait<dynamic>([
        StorageService.obtenerBaseUrl(),
        _usuarioService.obtenerPerfil(),
      ]);

      if (_disposed) return;

      final baseUrl = results[0]?.toString();
      final user = _asMap(results[1]);

      final temporaryState = ProfileState(
        loading: true,
        baseUrl: baseUrl,
        user: user,
      );

      Map<String, dynamic>? ownerProfile;
      Map<String, dynamic>? walkerProfile;

      if (temporaryState.isOwner) {
        ownerProfile = await _loadOwnerProfile();
      }

      if (temporaryState.isWalker) {
        walkerProfile = await _loadWalkerProfile();
      }

      if (_disposed) return;

      _setState(
        ProfileState(
          loading: false,
          baseUrl: baseUrl,
          user: user,
          ownerProfile: ownerProfile,
          walkerProfile: walkerProfile,
        ),
      );
    } catch (error) {
      if (_disposed) return;

      _setState(_state.copyWith(loading: false, error: _cleanError(error)));
    } finally {
      _requestInProgress = false;
    }
  }

  Future<Map<String, dynamic>?> _loadOwnerProfile() async {
    try {
      final response = await _usuarioService.obtenerPerfilDuenio();

      return _asMap(response);
    } catch (error) {
      debugPrint(
        'No se pudo cargar el perfil de dueño: '
        '${_cleanError(error)}',
      );

      return null;
    }
  }

  Future<Map<String, dynamic>?> _loadWalkerProfile() async {
    try {
      final response = await PaseadoresService.obtenerMiPerfilPaseador();

      return _asMap(response);
    } catch (error) {
      debugPrint(
        'No se pudo cargar el perfil de paseador: '
        '${_cleanError(error)}',
      );

      return null;
    }
  }

  Future<bool> closeSession() async {
    try {
      await SessionService.cerrarSesion();
      return true;
    } catch (error) {
      if (!_disposed) {
        _setState(_state.copyWith(error: _cleanError(error)));
      }

      return false;
    }
  }

  void clearError() {
    if (_state.error == null) return;

    _setState(_state.copyWith(clearError: true));
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  String _cleanError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '')
        .trim();

    if (message.isEmpty) {
      return 'No se pudo cargar tu perfil.';
    }

    return message;
  }

  void _setState(ProfileState newState) {
    if (_disposed) return;

    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
