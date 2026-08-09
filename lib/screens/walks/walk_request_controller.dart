import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/errors/api_exception.dart';
import '../../services/api_service.dart';
import '../../services/perros_service.dart';
import '../../services/routes_service.dart';
import '../../services/storage_service.dart';
import '../pets/models/pet.dart';
import '../walkers/models/walker.dart';
import 'models/pickup_location.dart';
import 'models/walk_route_selection.dart';
import 'walk_request_state.dart';

class WalkRequestResult {
  final bool success;
  final String message;
  final int? walkId;
  final bool routeAssigned;

  const WalkRequestResult({
    required this.success,
    required this.message,
    this.walkId,
    this.routeAssigned = false,
  });

  const WalkRequestResult.success({
    this.message =
        'Paseo programado correctamente.',
    this.walkId,
    this.routeAssigned = false,
  }) : success = true;

  const WalkRequestResult.failure(
    this.message,
  )   : success = false,
        walkId = null,
        routeAssigned = false;
}

class WalkRequestController
    extends ChangeNotifier {
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
      final results =
          await Future.wait<dynamic>([
        StorageService.obtenerBaseUrl(),
        PerrosService.obtenerMisPerros(),
      ]);

      if (_disposed) {
        return;
      }

      final baseUrl =
          results[0]?.toString();

      final petsResponse =
          _asMap(results[1]);

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
          selectedPetIds: pets.isEmpty
              ? const []
              : [pets.first.id],
          clearSelectedPets: pets.isEmpty,
          defaultLocation:
              defaultLocation,
          clearDefaultLocation:
              defaultLocation == null,
          pickupLocation:
              defaultLocation,
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
    togglePet(petId);
  }

  String? togglePet(int petId) {
    final exists = _state.pets.any(
      (pet) => pet.id == petId,
    );

    if (!exists) {
      return 'La mascota seleccionada no existe.';
    }

    final selected =
        List<int>.from(
      _state.selectedPetIds,
    );

    if (selected.contains(petId)) {
      selected.remove(petId);
    } else {
      if (selected.length >=
          WalkRequestState.maxSelectedPets) {
        return 'Puedes seleccionar máximo '
            '${WalkRequestState.maxSelectedPets} mascotas.';
      }

      selected.add(petId);
    }

    _setState(
      _state.copyWith(
        selectedPetIds: selected,
      ),
    );

    return null;
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
    final location =
        _state.defaultLocation;

    if (location == null) {
      return 'No tienes una ubicación '
          'predeterminada guardada.';
    }

    setPickupLocation(location);
    return null;
  }

  Future<String?>
      useCurrentLocation() async {
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
          await Geolocator
              .isLocationServiceEnabled();

      if (!serviceEnabled) {
        return 'El GPS está desactivado. '
            'Enciéndelo.';
      }

      var permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator
                .requestPermission();
      }

      if (permission ==
          LocationPermission.denied) {
        return 'Permiso de ubicación denegado.';
      }

      if (permission ==
          LocationPermission.deniedForever) {
        return 'Los permisos de ubicación '
            'están denegados permanentemente.';
      }

      final position =
          await Geolocator
              .getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high,
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
    WalkRouteSelection? routeSelection,
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

    final selectedPets =
        _state.selectedPets;

    final selectedPetIds = selectedPets
        .map((pet) => pet.id)
        .toList(growable: false);

    final primaryPet =
        selectedPets.first;

    final date =
        _state.scheduledAt!;

    final location =
        _state.pickupLocation!;

    final cleanNotes =
        notes.trim();

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

      // Primer perro para compatibilidad.
      'perroId': primaryPet.id,
      'PerroId': primaryPet.id,

      // Selección múltiple real.
      'perroIds': selectedPetIds,
      'PerroIds': selectedPetIds,

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

      // El backend vuelve a calcularlo.
      'precio': _state.estimatedTotal,
      'Precio': _state.estimatedTotal,
    };

    try {
      final response =
          await ApiService.postAuth(
        '/api/paseos/multiple',
        body,
      );

      if (!_isSuccessful(response)) {
        final statusCode =
            response['statusCode'];

        final message =
            _responseMessage(
          response,
          fallback:
              'No se pudo crear el paseo.',
        );

        return WalkRequestResult.failure(
          statusCode == null
              ? message
              : '$message Código: $statusCode',
        );
      }

      final walkId =
          _extractCreatedWalkId(response);

      final count =
          selectedPetIds.length;

      final baseMessage = count == 1
          ? 'Paseo solicitado correctamente.'
          : 'Paseo solicitado para '
              '$count mascotas.';

      if (routeSelection == null) {
        return WalkRequestResult.success(
          message: baseMessage,
          walkId: walkId,
          routeAssigned: false,
        );
      }

      if (walkId == null || walkId <= 0) {
        return WalkRequestResult.success(
          message:
              '$baseMessage No pudimos identificar '
              'el paseo para asignar su ruta; '
              'podrás agregarla desde Mis paseos.',
          routeAssigned: false,
        );
      }

      try {
        await _assignRoute(
          walkId: walkId,
          selection: routeSelection,
        );

        return WalkRequestResult.success(
          message:
              '$baseMessage Recorrido guardado.',
          walkId: walkId,
          routeAssigned: true,
        );
      } catch (error) {
        return WalkRequestResult.success(
          message:
              '$baseMessage La solicitud sí fue '
              'creada, pero no se pudo asignar '
              'el recorrido: ${_cleanError(error)}',
          walkId: walkId,
          routeAssigned: false,
        );
      }
    } catch (error) {
      return WalkRequestResult.failure(
        _cleanError(error),
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

  Future<void> _assignRoute({
    required int walkId,
    required WalkRouteSelection selection,
  }) async {
    final savedRoute =
        selection.savedRoute;

    if (savedRoute != null) {
      await RoutesService.assignSavedRoute(
        walkId: walkId,
        savedRouteId: savedRoute.id,
      );

      return;
    }

    final customRoute =
        selection.customRoute;

    if (customRoute == null) {
      return;
    }

    await RoutesService.assignCustomRoute(
      walkId: walkId,
      draft: customRoute,
      saveAsTemplate:
          selection.saveAsTemplate,
      templateName:
          selection.templateName,
    );
  }

  int? _extractCreatedWalkId(
    Map<String, dynamic> response,
  ) {
    dynamic source =
        response['body'] ?? response;

    if (source is Map) {
      source =
          source['data'] ??
          source['Data'] ??
          source['paseo'] ??
          source['Paseo'] ??
          source['resultado'] ??
          source['Resultado'] ??
          source;
    }

    return _extractPositiveId(source);
  }

  int? _extractPositiveId(
    dynamic source,
  ) {
    if (source is num) {
      final value = source.toInt();

      return value > 0 ? value : null;
    }

    if (source is String) {
      final value =
          int.tryParse(source.trim());

      return value != null && value > 0
          ? value
          : null;
    }

    if (source is! Map) {
      return null;
    }

    final map =
        Map<String, dynamic>.from(source);

    const directKeys = [
      'id',
      'Id',
      'paseoId',
      'PaseoId',
      'walkId',
      'WalkId',
    ];

    for (final key in directKeys) {
      final id =
          _extractPositiveId(map[key]);

      if (id != null) {
        return id;
      }
    }

    const nestedKeys = [
      'data',
      'Data',
      'paseo',
      'Paseo',
      'resultado',
      'Resultado',
      'result',
      'Result',
      'value',
      'Value',
    ];

    for (final key in nestedKeys) {
      final id =
          _extractPositiveId(map[key]);

      if (id != null) {
        return id;
      }
    }

    return null;
  }

  String? _validate() {
    if (!_state.walker.hasValidId) {
      return 'No se pudo identificar '
          'al paseador.';
    }

    if (!_state.hasSelectedPets) {
      return 'Selecciona al menos una mascota.';
    }

    if (_state.selectedPetCount >
        WalkRequestState.maxSelectedPets) {
      return 'Puedes seleccionar máximo '
          '${WalkRequestState.maxSelectedPets} mascotas.';
    }

    final date = _state.scheduledAt;

    if (date == null) {
      return 'Selecciona fecha y hora '
          'del paseo.';
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
    for (final endpoint
        in _profileEndpoints) {
      try {
        final response =
            await ApiService.getAuth(
          endpoint,
        );

        if (!_isSuccessful(response)) {
          continue;
        }

        final profile =
            _extractProfile(response);

        if (profile.isEmpty) {
          continue;
        }

        final ownerProfile =
            _nestedMap(
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

        final source =
            ownerProfile.isEmpty
                ? profile
                : ownerProfile;

        try {
          return PickupLocation.fromMap(
            source,
          );
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
        return Map<String, dynamic>.from(
          value,
        );
      }
    }

    return const {};
  }

  bool _isSuccessful(
    Map<String, dynamic> response,
  ) {
    final statusCode =
        response['statusCode'];

    if (statusCode is int &&
        (statusCode < 200 ||
            statusCode >= 300)) {
      return false;
    }

    dynamic body =
        response['body'] ?? response;

    if (body is Map &&
        body['success'] is bool) {
      return body['success'] == true;
    }

    if (response['success'] is bool) {
      return response['success'] == true;
    }

    return statusCode is int &&
        statusCode >= 200 &&
        statusCode < 300;
  }

  String _responseMessage(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    dynamic source =
        response['body'] ?? response;

    if (source is Map) {
      final value =
          source['message'] ??
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
        response['message']
            ?.toString()
            .trim();

    return message == null ||
            message.isEmpty
        ? fallback
        : message;
  }

  Map<String, dynamic> _asMap(
    dynamic value,
  ) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
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
        .replaceFirst(
          'ApiException: ',
          '',
        )
        .trim();

    return message == null ||
            message.isEmpty
        ? 'No se pudo completar la solicitud.'
        : message;
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