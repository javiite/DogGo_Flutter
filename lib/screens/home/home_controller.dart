import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/session/user_role.dart';
import '../../services/session_service.dart';
import '../../services/storage_service.dart';
import '../notifications/notifications_repository.dart';
import 'home_repository.dart';
import 'home_state.dart';

class HomeController extends ChangeNotifier {
  final HomeRepository _repository;
  final NotificationsRepository _notificationsRepository;

  HomeState _state = const HomeState();

  Timer? _notificationsTimer;

  bool _disposed = false;
  bool _loadingNotifications = false;
  bool _initialized = false;

  HomeController({
    HomeRepository? repository,
    NotificationsRepository? notificationsRepository,
  }) : _repository = repository ?? HomeRepository(),
       _notificationsRepository =
           notificationsRepository ?? NotificationsRepository();

  HomeState get state => _state;

  bool get initialized => _initialized;

  Future<void> initialize() async {
    if (_initialized || _disposed) {
      return;
    }

    _initialized = true;

    _setState(
      _state.copyWith(
        initialLoading: true,
        clearPetsError: true,
        clearWalksError: true,
      ),
    );

    await _loadSession();

    await Future.wait([
      loadProfilePhoto(),
      if (_state.isOwner || _state.isAdmin) loadPets(silent: true),
      loadWalks(silent: true),
      loadNotifications(silent: true),
    ]);

    if (_disposed) {
      return;
    }

    _setState(_state.copyWith(initialLoading: false));

    _startNotificationsPolling();
  }

  Future<void> refresh() async {
    if (_disposed) {
      return;
    }

    await _loadSession();

    await Future.wait([
      loadProfilePhoto(),
      if (_state.isOwner || _state.isAdmin) loadPets(),
      loadWalks(),
      loadNotifications(silent: true),
    ]);
  }

  Future<void> loadProfilePhoto() async {
    if (_disposed) {
      return;
    }

    try {
      final publicUrl = await _repository.loadProfilePhoto(
        role: _state.role,
        baseUrl: _state.baseUrl,
      );

      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          userPhotoUrl: publicUrl,
          clearUserPhotoUrl: publicUrl == null,
        ),
      );
    } catch (error) {
      debugPrint(
        'No se pudo cargar la foto del Home: '
        '${_cleanError(error)}',
      );
    }
  }

  Future<void> loadPets({bool silent = false}) async {
    if (_disposed) {
      return;
    }

    if (!silent) {
      _setState(_state.copyWith(petsLoading: true, clearPetsError: true));
    }

    try {
      final pets = await _repository.loadPets(_state.baseUrl);

      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          petsLoading: false,
          pets: pets,
          walks: _repository.enrichWalksWithPets(_state.walks, pets),
          clearPetsError: true,
        ),
      );
    } catch (error) {
      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(petsLoading: false, petsError: _cleanError(error)),
      );
    }
  }

  Future<void> loadWalks({bool silent = false}) async {
    if (_disposed) {
      return;
    }

    if (!silent) {
      _setState(_state.copyWith(walksLoading: true, clearWalksError: true));
    }

    try {
      final parsedWalks = await _repository.loadWalks(_state.baseUrl);

      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          walksLoading: false,
          walks: _repository.enrichWalksWithPets(parsedWalks, _state.pets),
          clearWalksError: true,
        ),
      );
    } catch (error) {
      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(walksLoading: false, walksError: _cleanError(error)),
      );
    }
  }

  Future<void> loadNotifications({bool silent = false}) async {
    if (_disposed || _loadingNotifications) {
      return;
    }

    _loadingNotifications = true;

    if (!silent) {
      _setState(_state.copyWith(notificationsLoading: true));
    }

    try {
      final notifications = await _notificationsRepository.getAll();

      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          notificationsLoading: false,
          notifications: notifications,
        ),
      );
    } catch (_) {
      if (_disposed) {
        return;
      }

      _setState(_state.copyWith(notificationsLoading: false));
    } finally {
      _loadingNotifications = false;
    }
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    await _notificationsRepository.markAsRead(notificationId);

    if (_disposed) {
      return;
    }

    final updatedNotifications = _state.notifications
        .map((notification) {
          if (notification.id != notificationId) {
            return notification;
          }
          return notification.copyWith(isRead: true);
        })
        .toList(growable: false);

    _setState(_state.copyWith(notifications: updatedNotifications));
  }

  Future<void> _loadSession() async {
    try {
      final results = await Future.wait<dynamic>([
        SessionService.obtenerNombre(),
        SessionService.obtenerRol(),
        StorageService.obtenerBaseUrl(),
      ]);

      if (_disposed) {
        return;
      }

      final name = results[0]?.toString().trim();

      final rawRole = results[1]?.toString();

      final baseUrl = results[2]?.toString().trim();

      _setState(
        _state.copyWith(
          userName: name != null && name.isNotEmpty ? name : 'Usuario',
          role: UserRoleCodec.parse(rawRole),
          baseUrl: baseUrl,
          clearBaseUrl: baseUrl == null || baseUrl.isEmpty,
        ),
      );
    } catch (_) {
      if (_disposed) {
        return;
      }

      _setState(_state.copyWith(userName: 'Usuario', role: UserRole.unknown));
    }
  }

  void _startNotificationsPolling() {
    _notificationsTimer?.cancel();

    _notificationsTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      loadNotifications(silent: true);
    });
  }

  String _cleanError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();

    return message.isEmpty ? 'Ocurrió un error inesperado.' : message;
  }

  void _setState(HomeState newState) {
    if (_disposed) {
      return;
    }

    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _notificationsTimer?.cancel();

    super.dispose();
  }
}
