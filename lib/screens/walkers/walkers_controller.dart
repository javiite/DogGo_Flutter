import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import 'models/walker.dart';
import 'walkers_repository.dart';
import 'walkers_state.dart';

class WalkersController extends ChangeNotifier {
  final WalkersRepository _repository;
  WalkersState _state = const WalkersState();

  bool _disposed = false;
  bool _requestInProgress = false;

  WalkersState get state => _state;

  WalkersController({WalkersRepository? repository})
    : _repository = repository ?? WalkersRepository();

  Future<void> initialize() {
    return loadWalkers();
  }

  Future<void> refresh() {
    return loadWalkers();
  }

  Future<void> loadWalkers() async {
    if (_requestInProgress) return;

    _requestInProgress = true;

    _setState(_state.copyWith(loading: true, clearError: true));

    try {
      final result = await _repository.getAll();

      if (_disposed) return;

      final walkers = result.walkers;

      var selectedZone = _state.selectedZone;

      final validZones = <String>{
        WalkersState.allZones,
        for (final walker in walkers) ...walker.zones,
      };

      if (!validZones.contains(selectedZone)) {
        selectedZone = WalkersState.allZones;
      }

      _setState(
        WalkersState(
          loading: false,
          baseUrl: result.baseUrl,
          walkers: walkers,
          searchQuery: _state.searchQuery,
          selectedZone: selectedZone,
          onlyAvailable: _state.onlyAvailable,
          sort: _state.sort,
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

  void selectZone(String? zone) {
    if (zone == null || !_state.availableZones.contains(zone)) {
      return;
    }

    _setState(_state.copyWith(selectedZone: zone));
  }

  void setOnlyAvailable(bool value) {
    _setState(_state.copyWith(onlyAvailable: value));
  }

  void setSort(WalkerSort? sort) {
    if (sort == null) return;

    _setState(_state.copyWith(sort: sort));
  }

  void clearFilters() {
    _setState(
      _state.copyWith(
        searchQuery: '',
        selectedZone: WalkersState.allZones,
        onlyAvailable: false,
        sort: WalkerSort.nearest,
        clearError: true,
      ),
    );
  }

  void clearError() {
    if (_state.error == null) return;

    _setState(_state.copyWith(clearError: true));
  }

  Walker? findById(int id) {
    for (final walker in _state.walkers) {
      if (walker.id == id) {
        return walker;
      }
    }

    return null;
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

    return message.isEmpty ? 'No se pudieron cargar los paseadores.' : message;
  }

  void _setState(WalkersState newState) {
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
