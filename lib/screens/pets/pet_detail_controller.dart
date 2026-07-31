import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../services/perros_service.dart';
import '../../services/storage_service.dart';
import 'models/pet.dart';
import 'pet_detail_state.dart';

class PetDetailController extends ChangeNotifier {
  final Pet initialPet;

  late PetDetailState _state;
  bool _disposed = false;
  bool _requestInProgress = false;

  PetDetailController({
    required Map<String, dynamic> initialData,
  }) : initialPet = Pet.fromMap(initialData) {
    _state = PetDetailState(
      loading: true,
      pet: initialPet,
    );
  }

  PetDetailState get state => _state;

  Future<void> initialize() {
    return loadDetail();
  }

  Future<void> refresh() {
    return loadDetail();
  }

  Future<void> markChangedAndRefresh() async {
    _setState(
      _state.copyWith(
        changed: true,
      ),
    );

    await loadDetail();
  }

  Future<void> loadDetail() async {
    if (_requestInProgress) return;

    if (!initialPet.hasValidId) {
      _setState(
        _state.copyWith(
          loading: false,
          error:
              'No se encontró el identificador de la mascota.',
        ),
      );
      return;
    }

    _requestInProgress = true;

    _setState(
      _state.copyWith(
        loading: true,
        clearError: true,
      ),
    );

    try {
      final results = await Future.wait<dynamic>([
        StorageService.obtenerBaseUrl(),
        PerrosService.obtenerPerroPorId(initialPet.id),
      ]);

      if (_disposed) return;

      final baseUrl = results[0]?.toString();
      final response = _asMap(results[1]);

      if (response['success'] != true) {
        throw Exception(
          _responseMessage(
            response,
            fallback:
                'No se pudo cargar la información de la mascota.',
          ),
        );
      }

      final detailMap = _asMap(response['data']);

      if (detailMap.isEmpty) {
        throw Exception(
          'El servidor no devolvió información de la mascota.',
        );
      }

      _setState(
        PetDetailState(
          loading: false,
          baseUrl: baseUrl,
          pet: Pet.fromMap(detailMap),
          changed: _state.changed,
        ),
      );
    } catch (error) {
      if (_disposed) return;

      _setState(
        _state.copyWith(
          loading: false,
          error: _cleanError(error),
        ),
      );
    } finally {
      _requestInProgress = false;
    }
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

  String _responseMessage(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    final value = response['message'] ??
        response['mensaje'] ??
        response['error'];

    final message = value?.toString().trim();

    if (message == null || message.isEmpty) {
      return fallback;
    }

    return message;
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

    return message.isEmpty
        ? 'No se pudo cargar la mascota.'
        : message;
  }

  void _setState(PetDetailState newState) {
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