import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../services/notificaciones_service.dart';
import '../../services/paseos_service.dart';
import '../../services/perros_service.dart';
import '../../services/session_service.dart';
import '../../services/storage_service.dart';
import 'home_state.dart';
import 'models/home_pet.dart';
import 'models/home_walk.dart';

class HomeController extends ChangeNotifier {
  final NotificacionesService _notificationsService;

  HomeState _state = const HomeState();
  Timer? _notificationsTimer;

  bool _disposed = false;
  bool _loadingNotifications = false;
  bool _initialized = false;

  HomeController({
    NotificacionesService? notificationsService,
  }) : _notificationsService =
            notificationsService ?? NotificacionesService();

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
      if (_state.isOwner || _state.isAdmin) loadPets(),
      loadWalks(),
      loadNotifications(silent: true),
    ]);

    _setState(
      _state.copyWith(initialLoading: false),
    );

    _startNotificationsPolling();
  }

  Future<void> refresh() async {
    if (_disposed) {
      return;
    }

    await _loadSession();

    await Future.wait([
      if (_state.isOwner || _state.isAdmin) loadPets(),
      loadWalks(),
      loadNotifications(silent: true),
    ]);
  }

  Future<void> loadPets() async {
    if (_disposed) {
      return;
    }

    _setState(
      _state.copyWith(
        petsLoading: true,
        clearPetsError: true,
      ),
    );

    try {
      final result = await PerrosService.obtenerMisPerros();

      if (_disposed) {
        return;
      }

      if (result['success'] == true) {
        final maps = HomeState.normalizeMapList(
          result['data'],
          possibleKeys: const [
            'items',
            'perros',
            'data',
            'result',
            'resultado',
          ],
        );

        final pets = maps
            .map(
              (map) => HomePet.fromMap(
                map,
                baseUrl: _state.baseUrl,
              ),
            )
            .toList(growable: false);

        _setState(
          _state.copyWith(
            petsLoading: false,
            pets: pets,
            clearPetsError: true,
          ),
        );

        return;
      }

      _setState(
        _state.copyWith(
          petsLoading: false,
          petsError: _messageFrom(
            result,
            'No se pudieron cargar las mascotas.',
          ),
        ),
      );
    } catch (error) {
      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          petsLoading: false,
          petsError: _cleanError(error),
        ),
      );
    }
  }

  Future<void> loadWalks() async {
    if (_disposed) {
      return;
    }

    _setState(
      _state.copyWith(
        walksLoading: true,
        clearWalksError: true,
      ),
    );

    try {
      final result = await PaseosService.obtenerMisPaseos();

      if (_disposed) {
        return;
      }

      if (result['success'] == true) {
        final maps = HomeState.normalizeMapList(
          result['data'],
          possibleKeys: const [
            'items',
            'paseos',
            'data',
            'result',
            'resultado',
          ],
        );

        final walks = maps
            .map(
              (map) => HomeWalk.fromMap(
                map,
                baseUrl: _state.baseUrl,
              ),
            )
            .toList(growable: false);

        _setState(
          _state.copyWith(
            walksLoading: false,
            walks: walks,
            clearWalksError: true,
          ),
        );

        return;
      }

      _setState(
        _state.copyWith(
          walksLoading: false,
          walksError: _messageFrom(
            result,
            'No se pudieron cargar los paseos.',
          ),
        ),
      );
    } catch (error) {
      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          walksLoading: false,
          walksError: _cleanError(error),
        ),
      );
    }
  }

  Future<void> loadNotifications({
    bool silent = false,
  }) async {
    if (_disposed || _loadingNotifications) {
      return;
    }

    _loadingNotifications = true;

    if (!silent) {
      _setState(
        _state.copyWith(notificationsLoading: true),
      );
    }

    try {
      final response =
          await _notificationsService.obtenerNotificaciones();

      if (_disposed) {
        return;
      }

      final notifications = response
          .map(HomeState.safeMap)
          .where((item) => item.isNotEmpty)
          .toList(growable: false);

      notifications.sort((a, b) {
        final dateA = _notificationDate(a);
        final dateB = _notificationDate(b);

        return dateB.compareTo(dateA);
      });

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

      _setState(
        _state.copyWith(
          notificationsLoading: false,
        ),
      );
    } finally {
      _loadingNotifications = false;
    }
  }

  Future<void> markNotificationAsRead(
    int notificationId,
  ) async {
    await _notificationsService.marcarComoLeida(
      notificationId,
    );

    if (_disposed) {
      return;
    }

    final updatedNotifications =
        _state.notifications.map((notification) {
      final id = _notificationId(notification);

      if (id != notificationId) {
        return notification;
      }

      return <String, dynamic>{
        ...notification,
        'leida': true,
        'Leida': true,
        'read': true,
        'Read': true,
      };
    }).toList(growable: false);

    _setState(
      _state.copyWith(
        notifications: updatedNotifications,
      ),
    );
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
          userName: name != null && name.isNotEmpty
              ? name
              : 'Usuario',
          role: SessionService.normalizarRol(rawRole),
          baseUrl: baseUrl,
          clearBaseUrl:
              baseUrl == null || baseUrl.isEmpty,
        ),
      );
    } catch (_) {
      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          userName: 'Usuario',
          role: 'Usuario',
        ),
      );
    }
  }

  void _startNotificationsPolling() {
    _notificationsTimer?.cancel();

    _notificationsTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => loadNotifications(silent: true),
    );
  }

  DateTime _notificationDate(
    Map<String, dynamic> notification,
  ) {
    final value = HomeState.firstValue(
      notification,
      const [
        'fecha',
        'Fecha',
        'fechaCreacion',
        'FechaCreacion',
        'createdAt',
        'CreatedAt',
      ],
    );

    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  int? _notificationId(
    Map<String, dynamic> notification,
  ) {
    final value = HomeState.firstValue(
      notification,
      const [
        'id',
        'Id',
        'notificacionId',
        'NotificacionId',
      ],
    );

    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '');
  }

  String _messageFrom(
    Map<String, dynamic> result,
    String fallback,
  ) {
    final message = result['message']?.toString().trim();

    return message != null && message.isNotEmpty
        ? message
        : fallback;
  }

  String _cleanError(Object error) {
    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();

    return message.isEmpty
        ? 'Ocurrió un error inesperado.'
        : message;
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