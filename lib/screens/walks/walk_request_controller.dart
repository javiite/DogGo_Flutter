import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/errors/api_exception.dart';
import '../../services/api_service.dart';
import '../../services/perros_service.dart';
import '../../services/storage_service.dart';
import '../pets/models/pet.dart';
import '../walkers/models/walker.dart';
import 'models/pickup_location.dart';
import 'walk_request_state.dart';

class WalkRequestResult {
  final bool success;
  final String message;

  const WalkRequestResult({
    required this.success,
    required this.message,
  });

  const WalkRequestResult.success([
    this.message = 'Paseo programado correctamente.',
  ]) : success = true;

  const WalkRequestResult.failure(
    this.message,
  ) : success = false;
}

class WalkRequestController extends ChangeNotifier {
  WalkRequestState _state;

  bool _disposed = false;
  bool _initialRequestInProgress = false;
  bool _submitInProgress = false;

  WalkRequestController({
    required Map<String, dynamic> walkerData,
  }) : _state = WalkRequestState(
          walker: Walker.fromMap(walkerData),
        );

  WalkRequestState get state => _state;

  Future<void> initialize() async {
    if (_initialRequestInProgress) {
      return;
    }

    _initialRequestInProgress = true;

    _setState(
      _state.copyWith(
        loading: true,
        clearError: true,
      ),
    );

    try {
      final results = await Future.wait<dynamic>([
        StorageService.obtenerBaseUrl(),
        PerrosService.obtenerMisPerros(),
      ]);

      if (_disposed) {
        return;
      }

      final baseUrl = results[0]?.toString();
      final petsResponse = _asMap(results[1]);

      if (petsResponse['success'] != true) {
        throw Exception(
          _responseMessage(
            petsResponse,
            fallback:
                'No se pudieron cargar tus mascotas.',
          ),
        );
      }

      final pets = Pet.listFrom(
        petsResponse['data'],
      );

      PickupLocation? defaultLocation;

      try {
        defaultLocation =
            await _loadDefaultLocation();
      } catch (_) {
        defaultLocation = null;
      }

      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          loading: false,
          baseUrl: baseUrl,
          pets: pets,
          selectedPetId:
              pets.isEmpty ? null : pets.first.id,
          clearSelectedPet: pets.isEmpty,
          defaultLocation: defaultLocation,
          clearDefaultLocation:
              defaultLocation == null,
          pickupLocation: defaultLocation,
          clearPickupLocation:
              defaultLocation == null,
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
          error: _cleanError(error),
        ),
      );
    } finally {
      _initialRequestInProgress = false;
    }
  }

  Future<void> refresh() {
    return initialize();
  }

  void selectPet(int petId) {
    final exists = _state.pets.any(
      (pet) => pet.id == petId,
    );

    if (!exists) {
      return;
    }

    _setState(
      _state.copyWith(
        selectedPetId: petId,
      ),
    );
  }

  void selectDuration(int minutes) {
    if (!WalkRequestState.allowedDurations
        .contains(minutes)) {
      return;
    }

    _setState(
      _state.copyWith(
        durationMinutes: minutes,
      ),
    );
  }

  void setSchedule(DateTime date) {
    _setState(
      _state.copyWith(
        scheduledAt: date,
      ),
    );
  }

  void setPickupLocation(
    PickupLocation location,
  ) {
    _setState(
      _state.copyWith(
        pickupLocation: location,
      ),
    );
  }

  String? applyMapResult(
    Map<String, dynamic> result,
  ) {
    try {
      final location =
          PickupLocation.fromMap(result);

      setPickupLocation(location);
      return null;
    } on FormatException catch (error) {
      return error.message;
    } catch (_) {
      return 'No se pudo leer la ubicación seleccionada.';
    }
  }

  String? useDefaultLocation() {
    final location = _state.defaultLocation;

    if (location == null) {
      return 'No tienes una ubicación predeterminada guardada.';
    }

    setPickupLocation(location);
    return null;
  }

  Future<String?> useCurrentLocation() async {
    if (_state.loadingLocation) {
      return null;
    }

    _setState(
      _state.copyWith(
        loadingLocation: true,
      ),
    );

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return 'El GPS está desactivado. Enciéndelo.';
      }

      var permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return 'Permiso de ubicación denegado.';
      }

      if (permission ==
          LocationPermission.deniedForever) {
        return 'Los permisos de ubicación están '
            'denegados permanentemente.';
      }

      final position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_disposed) {
        return null;
      }

      setPickupLocation(
        PickupLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          address: 'Ubicación actual',
          reference: 'Ubicación actual',
        ),
      );

      return null;
    } catch (error) {
      return _cleanError(error);
    } finally {
      _setState(
        _state.copyWith(
          loadingLocation: false,
        ),
      );
    }
  }

  Future<WalkRequestResult> submit({
    required String notes,
  }) async {
    if (_submitInProgress) {
      return const WalkRequestResult.failure(
        'La solicitud ya se está enviando.',
      );
    }

    final validationMessage = _validate();

    if (validationMessage != null) {
      return WalkRequestResult.failure(
        validationMessage,
      );
    }

    final pet = _state.selectedPet!;
    final date = _state.scheduledAt!;
    final location = _state.pickupLocation!;
    final cleanNotes = notes.trim();

    _submitInProgress = true;

    _setState(
      _state.copyWith(
        saving: true,
        clearError: true,
      ),
    );

    final body = <String, dynamic>{
      'paseadorId': _state.walker.id,
      'PaseadorId': _state.walker.id,
      'perroId': pet.id,
      'PerroId': pet.id,
      'perrosIds': [pet.id],
      'PerrosIds': [pet.id],
      'duracionMinutos':
          _state.durationMinutes,
      'DuracionMinutos':
          _state.durationMinutes,
      'esProgramado': true,
      'EsProgramado': true,
      'fechaProgramada':
          date.toIso8601String(),
      'FechaProgramada':
          date.toIso8601String(),
      'latitudRecogida':
          location.latitude,
      'LatitudRecogida':
          location.latitude,
      'longitudRecogida':
          location.longitude,
      'LongitudRecogida':
          location.longitude,
      'direccionRecogida':
          location.displayAddress,
      'DireccionRecogida':
          location.displayAddress,
      'ubicacionTexto':
          location.displayAddress,
      'UbicacionTexto':
          location.displayAddress,
      'referenciasRecogida':
          cleanNotes.isNotEmpty
              ? cleanNotes
              : location.reference,
      'ReferenciasRecogida':
          cleanNotes.isNotEmpty
              ? cleanNotes
              : location.reference,
      'notas': cleanNotes,
      'Notas': cleanNotes,
      'precio': _state.estimatedTotal,
      'Precio': _state.estimatedTotal,
    };

    Object? lastError;
    Map<String, dynamic>? lastResponse;

    try {
      for (final endpoint in _createEndpoints) {
        try {
          final response =
              await ApiService.postAuth(
            endpoint,
            body,
          );

          lastResponse = response;

          if (_isSuccessful(response)) {
            return const WalkRequestResult.success();
          }

          lastError = Exception(
            _responseMessage(
              response,
              fallback:
                  'No se pudo crear el paseo.',
            ),
          );
        } catch (error) {
          lastError = error;
        }
      }

      final statusCode =
          lastResponse?['statusCode'];

      final message = _cleanError(lastError);

      return WalkRequestResult.failure(
        statusCode == null
            ? message
            : '$message Código: $statusCode',
      );
    } finally {
      _submitInProgress = false;

      _setState(
        _state.copyWith(
          saving: false,
        ),
      );
    }
  }

  String? _validate() {
    if (!_state.walker.hasValidId) {
      return 'No se pudo identificar al paseador.';
    }

    if (_state.selectedPet == null) {
      return 'Selecciona una mascota.';
    }

    final date = _state.scheduledAt;

    if (date == null) {
      return 'Selecciona fecha y hora del paseo.';
    }

    if (!date.isAfter(DateTime.now())) {
      return 'La fecha del paseo debe ser futura.';
    }

    if (_state.pickupLocation == null) {
      return 'Selecciona el punto de recogida.';
    }

    return null;
  }

  Future<PickupLocation?>
      _loadDefaultLocation() async {
    for (final endpoint in _profileEndpoints) {
      try {
        final response =
            await ApiService.getAuth(endpoint);

        if (!_isSuccessful(response)) {
          continue;
        }

        final profile =
            _extractProfile(response);

        if (profile.isEmpty) {
          continue;
        }

        final ownerProfile = _nestedMap(
          profile,
          const [
            'duenioPerfil',
            'DuenioPerfil',
            'dueñoPerfil',
            'DueñoPerfil',
            'perfilDuenio',
            'PerfilDuenio',
            'perfilDueño',
            'PerfilDueño',
          ],
        );

        final source = ownerProfile.isEmpty
            ? profile
            : ownerProfile;

        try {
          return PickupLocation.fromMap(source);
        } catch (_) {
          continue;
        }
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  Map<String, dynamic> _extractProfile(
    Map<String, dynamic> response,
  ) {
    dynamic data =
        response['body'] ?? response;

    if (data is Map) {
      data = data['data'] ??
          data['perfil'] ??
          data['usuario'] ??
          data['duenioPerfil'] ??
          data['dueñoPerfil'] ??
          data;
    }

    return _asMap(data);
  }

  Map<String, dynamic> _nestedMap(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = source[key];

      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
    }

    return const {};
  }

  bool _isSuccessful(
    Map<String, dynamic> response,
  ) {
    final statusCode = response['statusCode'];

    if (statusCode is int) {
      return statusCode >= 200 &&
          statusCode < 300;
    }

    if (response['success'] is bool) {
      return response['success'] == true;
    }

    return true;
  }

  String _responseMessage(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    dynamic source =
        response['body'] ?? response;

    if (source is Map) {
      final value = source['message'] ??
          source['mensaje'] ??
          source['error'];

      final message =
          value?.toString().trim();

      if (message != null &&
          message.isNotEmpty) {
        return message;
      }
    }

    final message =
        response['message']?.toString().trim();

    return message == null || message.isEmpty
        ? fallback
        : message;
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

  String _cleanError(Object? error) {
    if (error is ApiException) {
      return error.message;
    }

    final message = error
        ?.toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '')
        .trim();

    return message == null || message.isEmpty
        ? 'No se pudo completar la solicitud.'
        : message;
  }

  List<String> get _createEndpoints {
    return const [
      '/api/paseos/solicitar',
      '/api/Paseos/solicitar',
      '/api/paseos/programar',
      '/api/Paseos/programar',
      '/api/paseos',
      '/api/Paseos',
    ];
  }

  List<String> get _profileEndpoints {
    return const [
      '/api/perfil',
      '/api/Perfil',
      '/api/usuarios/perfil',
      '/api/Usuarios/perfil',
      '/api/auth/me',
      '/api/Auth/me',
      '/api/usuarios/me',
      '/api/Usuarios/me',
    ];
  }

  void _setState(
    WalkRequestState newState,
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
    super.dispose();
  }
}