import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../services/perros_service.dart';
import '../../services/storage_service.dart';
import 'models/pet.dart';
import 'pets_state.dart';

class PetsController extends ChangeNotifier {
  PetsState _state = const PetsState();
  bool _disposed = false;
  bool _requestInProgress = false;

  String? _lastMessage;

  PetsState get state => _state;

  String? get lastMessage => _lastMessage;

  Future<void> initialize() {
    return loadPets();
  }

  Future<void> refresh() {
    return loadPets();
  }

  Future<void> loadPets() async {
    if (_requestInProgress) return;

    _requestInProgress = true;
    _lastMessage = null;

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

      if (_disposed) return;

      final baseUrl = results[0]?.toString();
      final response = _asMap(results[1]);

      if (response['success'] != true) {
        throw Exception(
          _responseMessage(
            response,
            fallback:
                'No se pudieron cargar tus mascotas.',
          ),
        );
      }

      final pets = Pet.listFrom(response['data']);

      _setState(
        PetsState(
          loading: false,
          baseUrl: baseUrl,
          pets: pets,
          searchQuery: _state.searchQuery,
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

  void search(String query) {
    _setState(
      _state.copyWith(
        searchQuery: query,
      ),
    );
  }

  void clearSearch() {
    if (_state.searchQuery.isEmpty) return;

    _setState(
      _state.copyWith(
        searchQuery: '',
      ),
    );
  }

  void clearError() {
    if (_state.error == null) return;

    _setState(
      _state.copyWith(
        clearError: true,
      ),
    );
  }

  Pet? findById(int id) {
    for (final pet in _state.pets) {
      if (pet.id == id) {
        return pet;
      }
    }

    return null;
  }

  Future<bool> deletePet(Pet pet) async {
    if (_state.isDeleting || !pet.hasValidId) {
      return false;
    }

    _lastMessage = null;

    _setState(
      _state.copyWith(
        deletingPetId: pet.id,
        clearError: true,
      ),
    );

    try {
      final response =
          await PerrosService.eliminarPerro(pet.id);

      if (_disposed) return false;

      if (response['success'] != true) {
        throw Exception(
          _responseMessage(
            response,
            fallback:
                'No se pudo eliminar a ${pet.name}.',
          ),
        );
      }

      final updatedPets = _state.pets
          .where((item) => item.id != pet.id)
          .toList(growable: false);

      _lastMessage = _responseMessage(
        response,
        fallback:
            '${pet.name} se eliminó correctamente.',
      );

      _setState(
        _state.copyWith(
          pets: updatedPets,
          clearDeletingPet: true,
          clearError: true,
        ),
      );

      return true;
    } catch (error) {
      if (_disposed) return false;

      _setState(
        _state.copyWith(
          clearDeletingPet: true,
          error: _cleanError(error),
        ),
      );

      return false;
    }
  }

  void replacePet(Pet updatedPet) {
    final index = _state.pets.indexWhere(
      (pet) => pet.id == updatedPet.id,
    );

    if (index < 0) {
      _setState(
        _state.copyWith(
          pets: [
            updatedPet,
            ..._state.pets,
          ],
        ),
      );

      return;
    }

    final updatedList =
        List<Pet>.from(_state.pets);

    updatedList[index] = updatedPet;

    _setState(
      _state.copyWith(
        pets: updatedList,
      ),
    );
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
        ? 'No se pudieron cargar tus mascotas.'
        : message;
  }

  void _setState(PetsState newState) {
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