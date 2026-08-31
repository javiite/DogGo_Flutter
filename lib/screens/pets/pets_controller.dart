import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import 'models/pet.dart';
import 'pets_repository.dart';
import 'pets_state.dart';

class PetsController extends ChangeNotifier {
  final PetsRepository _repository;
  PetsState _state = const PetsState();
  bool _disposed = false;
  bool _requestInProgress = false;

  String? _lastMessage;

  PetsState get state => _state;

  String? get lastMessage => _lastMessage;

  PetsController({PetsRepository? repository})
    : _repository = repository ?? PetsRepository();

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

    _setState(_state.copyWith(loading: true, clearError: true));

    try {
      final result = await _repository.getMine();

      if (_disposed) return;

      _setState(
        PetsState(
          loading: false,
          baseUrl: result.baseUrl,
          pets: result.pets,
          searchQuery: _state.searchQuery,
        ),
      );
    } catch (error) {
      if (_disposed) return;

      _setState(_state.copyWith(loading: false, error: _cleanError(error)));
    } finally {
      _requestInProgress = false;
    }
  }

  void search(String query) {
    _setState(_state.copyWith(searchQuery: query));
  }

  void clearSearch() {
    if (_state.searchQuery.isEmpty) return;

    _setState(_state.copyWith(searchQuery: ''));
  }

  void clearError() {
    if (_state.error == null) return;

    _setState(_state.copyWith(clearError: true));
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

    _setState(_state.copyWith(deletingPetId: pet.id, clearError: true));

    try {
      final result = await _repository.delete(pet);

      if (_disposed) return false;

      final updatedPets = _state.pets
          .where((item) => item.id != pet.id)
          .toList(growable: false);

      _lastMessage = result.message;

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
        _state.copyWith(clearDeletingPet: true, error: _cleanError(error)),
      );

      return false;
    }
  }

  void replacePet(Pet updatedPet) {
    final index = _state.pets.indexWhere((pet) => pet.id == updatedPet.id);

    if (index < 0) {
      _setState(_state.copyWith(pets: [updatedPet, ..._state.pets]));

      return;
    }

    final updatedList = List<Pet>.from(_state.pets);

    updatedList[index] = updatedPet;

    _setState(_state.copyWith(pets: updatedList));
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

    return message.isEmpty ? 'No se pudieron cargar tus mascotas.' : message;
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
