import '../../core/session/user_role.dart';
import '../../services/paseadores_service.dart';
import '../../services/paseos_service.dart';
import '../../services/perros_service.dart';
import '../../services/usuario_service.dart';
import 'home_state.dart';
import 'models/home_pet.dart';
import 'models/home_walk.dart';

class HomeRepository {
  final UsuarioService _usuarioService;

  HomeRepository({UsuarioService? usuarioService})
    : _usuarioService = usuarioService ?? UsuarioService();

  Future<String?> loadProfilePhoto({
    required UserRole role,
    required String? baseUrl,
  }) async {
    Map<String, dynamic> profile;

    if (role.isWalker) {
      profile = await PaseadoresService.obtenerMiPerfilPaseador();
    } else if (role.isOwner || role.isAdmin) {
      profile = await _usuarioService.obtenerPerfilDuenio();
    } else {
      profile = await _usuarioService.obtenerPerfil();
    }

    dynamic photo = _findProfilePhoto(profile);
    photo ??= _findProfilePhoto(await _usuarioService.obtenerPerfil());

    return _publicMediaUrl(photo, baseUrl);
  }

  Future<List<HomePet>> loadPets(String? baseUrl) async {
    final result = await PerrosService.obtenerMisPerros();
    if (result['success'] != true) {
      throw Exception(
        _messageFrom(result, 'No se pudieron cargar las mascotas.'),
      );
    }

    return HomeState.normalizeMapList(
          result['data'],
          possibleKeys: const [
            'items',
            'perros',
            'data',
            'result',
            'resultado',
          ],
        )
        .map((map) => HomePet.fromMap(map, baseUrl: baseUrl))
        .toList(growable: false);
  }

  Future<List<HomeWalk>> loadWalks(String? baseUrl) async {
    final result = await PaseosService.obtenerMisPaseos();
    if (result['success'] != true) {
      throw Exception(
        _messageFrom(result, 'No se pudieron cargar los paseos.'),
      );
    }

    return HomeState.normalizeMapList(
          result['data'],
          possibleKeys: const [
            'items',
            'paseos',
            'data',
            'result',
            'resultado',
          ],
        )
        .map((map) => HomeWalk.fromMap(map, baseUrl: baseUrl))
        .toList(growable: false);
  }

  List<HomeWalk> enrichWalksWithPets(
    List<HomeWalk> walks,
    List<HomePet> registeredPets,
  ) {
    if (walks.isEmpty || registeredPets.isEmpty) return walks;

    return walks
        .map((walk) {
          if (walk.effectivePets.isEmpty) return walk;

          final enrichedPets = walk.effectivePets
              .map((walkPet) {
                return _findRegisteredPet(walkPet, registeredPets) ?? walkPet;
              })
              .toList(growable: false);

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
            pet: enrichedPets.first,
            pets: enrichedPets,
            walker: walk.walker,
            rawData: walk.rawData,
          );
        })
        .toList(growable: false);
  }

  dynamic _findProfilePhoto(dynamic source) {
    if (source is! Map) return null;
    final value = source['fotoUrl'];
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty && text.toLowerCase() != 'null') return value;
    return _findProfilePhoto(source['data']);
  }

  String? _publicMediaUrl(dynamic value, String? baseUrl) {
    final path = value?.toString().trim() ?? '';
    if (path.isEmpty || path.toLowerCase() == 'null') return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;

    final server = baseUrl?.trim() ?? '';
    if (server.isEmpty) return null;
    final cleanServer = server.endsWith('/')
        ? server.substring(0, server.length - 1)
        : server;
    return '$cleanServer${path.startsWith('/') ? path : '/$path'}';
  }

  HomePet? _findRegisteredPet(HomePet walkPet, List<HomePet> registeredPets) {
    if (walkPet.id != null) {
      for (final pet in registeredPets) {
        if (pet.id == walkPet.id) return pet;
      }
    }

    final name = _normalize(walkPet.name);
    if (name.isEmpty || name == 'tumascota' || name == 'mascota') return null;
    for (final pet in registeredPets) {
      if (_normalize(pet.name) == name) return pet;
    }
    return null;
  }

  String _messageFrom(Map<String, dynamic> result, String fallback) {
    final message = result['message']?.toString().trim();
    return message == null || message.isEmpty ? fallback : message;
  }

  String _normalize(String value) {
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
}
