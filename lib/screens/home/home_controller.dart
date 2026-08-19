import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../services/notificaciones_service.dart';
import '../../services/paseadores_service.dart';
import '../../services/paseos_service.dart';
import '../../services/perros_service.dart';
import '../../services/session_service.dart';
import '../../services/storage_service.dart';
import '../../services/usuario_service.dart';
import 'home_state.dart';
import 'models/home_pet.dart';
import 'models/home_walk.dart';

class HomeController extends ChangeNotifier {
  final NotificacionesService _notificationsService;
  final UsuarioService _usuarioService;

  HomeState _state = const HomeState();

  Timer? _notificationsTimer;

  bool _disposed = false;
  bool _loadingNotifications = false;
  bool _initialized = false;

  HomeController({
    NotificacionesService? notificationsService,
    UsuarioService? usuarioService,
  }) : _notificationsService = notificationsService ?? NotificacionesService(),
       _usuarioService = usuarioService ?? UsuarioService();

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
      if (_state.isOwner || _state.isAdmin) loadPets(),
      loadWalks(),
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
      Map<String, dynamic> profile;

      if (_state.isWalker) {
        profile = await PaseadoresService.obtenerMiPerfilPaseador();
      } else if (_state.isOwner || _state.isAdmin) {
        profile = await _usuarioService.obtenerPerfilDuenio();
      } else {
        profile = await _usuarioService.obtenerPerfil();
      }

      dynamic photo = _findProfilePhoto(profile);

      if (photo == null) {
        final user = await _usuarioService.obtenerPerfil();
        photo = _findProfilePhoto(user);
      }

      if (_disposed) {
        return;
      }

      final publicUrl = _publicMediaUrl(photo);

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

  dynamic _findProfilePhoto(dynamic source) {
    if (source is! Map) {
      return null;
    }

    const photoKeys = [
      'fotoUrl',
      'FotoUrl',
      'fotoPerfilUrl',
      'FotoPerfilUrl',
      'imagenUrl',
      'ImagenUrl',
      'foto',
      'Foto',
    ];

    for (final key in photoKeys) {
      final value = source[key];
      final text = value?.toString().trim() ?? '';

      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return value;
      }
    }

    const nestedKeys = [
      'data',
      'Data',
      'perfil',
      'Perfil',
      'usuario',
      'Usuario',
      'duenio',
      'Duenio',
      'dueño',
      'Dueño',
      'paseador',
      'Paseador',
      'result',
      'resultado',
    ];

    for (final key in nestedKeys) {
      final value = _findProfilePhoto(source[key]);

      if (value != null) {
        return value;
      }
    }

    return null;
  }

  String? _publicMediaUrl(dynamic value) {
    final path = value?.toString().trim() ?? '';

    if (path.isEmpty || path.toLowerCase() == 'null') {
      return null;
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    final server = _state.baseUrl?.trim() ?? '';

    if (server.isEmpty) {
      return null;
    }

    final cleanServer = server.endsWith('/')
        ? server.substring(0, server.length - 1)
        : server;
    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanServer$cleanPath';
  }

  Future<void> loadPets() async {
    if (_disposed) {
      return;
    }

    _setState(_state.copyWith(petsLoading: true, clearPetsError: true));

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
            .map((map) => HomePet.fromMap(map, baseUrl: _state.baseUrl))
            .toList(growable: false);

        final enrichedWalks = _enrichWalksWithPets(_state.walks, pets);

        _setState(
          _state.copyWith(
            petsLoading: false,
            pets: pets,
            walks: enrichedWalks,
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
        _state.copyWith(petsLoading: false, petsError: _cleanError(error)),
      );
    }
  }

  Future<void> loadWalks() async {
    if (_disposed) {
      return;
    }

    _setState(_state.copyWith(walksLoading: true, clearWalksError: true));

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

        final parsedWalks = maps
            .map((map) => HomeWalk.fromMap(map, baseUrl: _state.baseUrl))
            .toList(growable: false);

        final enrichedWalks = _enrichWalksWithPets(parsedWalks, _state.pets);

        _setState(
          _state.copyWith(
            walksLoading: false,
            walks: enrichedWalks,
            clearWalksError: true,
          ),
        );

        return;
      }

      _setState(
        _state.copyWith(
          walksLoading: false,
          walksError: _messageFrom(result, 'No se pudieron cargar los paseos.'),
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

  List<HomeWalk> _enrichWalksWithPets(
    List<HomeWalk> walks,
    List<HomePet> registeredPets,
  ) {
    if (walks.isEmpty || registeredPets.isEmpty) {
      return walks;
    }

    return walks
        .map((walk) {
          final walkPets = walk.effectivePets;

          if (walkPets.isEmpty) {
            return walk;
          }

          final enrichedPets = walkPets
              .map((walkPet) {
                final registeredPet = _findRegisteredPet(
                  walkPet,
                  registeredPets,
                );

                if (registeredPet == null) {
                  return walkPet;
                }

                // La información del listado de mascotas
                // es la fuente más completa para fotografías
                // y datos generales.
                return registeredPet;
              })
              .toList(growable: false);

          final primaryPet = enrichedPets.isEmpty
              ? walk.pet
              : enrichedPets.first;

          return HomeWalk(
            id: walk.id,
            programacionId: walk.programacionId,
            status: walk.status,
            scheduledAt: walk.scheduledAt,
            startedAt: walk.startedAt,
            finishedAt: walk.finishedAt,
            durationMinutes: walk.durationMinutes,
            distanceKilometers: walk.distanceKilometers,
            price: walk.price,
            pickupAddress: walk.pickupAddress,
            notes: walk.notes,
            pet: primaryPet,
            pets: enrichedPets,
            walker: walk.walker,
            rawData: walk.rawData,
          );
        })
        .toList(growable: false);
  }

  HomePet? _findRegisteredPet(HomePet walkPet, List<HomePet> registeredPets) {
    final walkPetId = walkPet.id;

    if (walkPetId != null) {
      for (final pet in registeredPets) {
        if (pet.id == walkPetId) {
          return pet;
        }
      }
    }

    final normalizedName = _normalizeText(walkPet.name);

    if (normalizedName.isEmpty ||
        normalizedName == 'tumascota' ||
        normalizedName == 'mascota') {
      return null;
    }

    for (final pet in registeredPets) {
      if (_normalizeText(pet.name) == normalizedName) {
        return pet;
      }
    }

    return null;
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
      final response = await _notificationsService.obtenerNotificaciones();

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

      _setState(_state.copyWith(notificationsLoading: false));
    } finally {
      _loadingNotifications = false;
    }
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    await _notificationsService.marcarComoLeida(notificationId);

    if (_disposed) {
      return;
    }

    final updatedNotifications = _state.notifications
        .map((notification) {
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
          role: SessionService.normalizarRol(rawRole),
          baseUrl: baseUrl,
          clearBaseUrl: baseUrl == null || baseUrl.isEmpty,
        ),
      );
    } catch (_) {
      if (_disposed) {
        return;
      }

      _setState(_state.copyWith(userName: 'Usuario', role: 'Usuario'));
    }
  }

  void _startNotificationsPolling() {
    _notificationsTimer?.cancel();

    _notificationsTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      loadNotifications(silent: true);
    });
  }

  DateTime _notificationDate(Map<String, dynamic> notification) {
    final value = HomeState.firstValue(notification, const [
      'fecha',
      'Fecha',
      'fechaCreacion',
      'FechaCreacion',
      'createdAt',
      'CreatedAt',
    ]);

    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  int? _notificationId(Map<String, dynamic> notification) {
    final value = HomeState.firstValue(notification, const [
      'id',
      'Id',
      'notificacionId',
      'NotificacionId',
    ]);

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  String _messageFrom(Map<String, dynamic> result, String fallback) {
    final message = result['message']?.toString().trim();

    return message != null && message.isNotEmpty ? message : fallback;
  }

  String _cleanError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();

    return message.isEmpty ? 'Ocurrió un error inesperado.' : message;
  }

  String _normalizeText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[\s_\-]'), '');
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
