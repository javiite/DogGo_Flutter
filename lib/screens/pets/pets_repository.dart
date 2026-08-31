import '../../services/perros_service.dart';
import '../../services/storage_service.dart';
import 'models/pet.dart';

class PetsLoadResult {
  final String? baseUrl;
  final List<Pet> pets;

  const PetsLoadResult({required this.baseUrl, required this.pets});
}

class PetDeleteResult {
  final String message;
  const PetDeleteResult(this.message);
}

class PetsRepository {
  Future<PetsLoadResult> getMine() async {
    final results = await Future.wait<dynamic>([
      StorageService.obtenerBaseUrl(),
      PerrosService.obtenerMisPerros(),
    ]);
    final response = _asMap(results[1]);
    if (response['success'] != true) {
      throw Exception(
        _message(response, 'No se pudieron cargar tus mascotas.'),
      );
    }
    return PetsLoadResult(
      baseUrl: results[0]?.toString(),
      pets: Pet.listFrom(response['data']),
    );
  }

  Future<PetDeleteResult> delete(Pet pet) async {
    final response = await PerrosService.eliminarPerro(pet.id);
    if (response['success'] != true) {
      throw Exception(_message(response, 'No se pudo eliminar a ${pet.name}.'));
    }
    return PetDeleteResult(
      _message(response, '${pet.name} se eliminó correctamente.'),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    return value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }

  String _message(Map<String, dynamic> response, String fallback) {
    final value =
        response['message'] ?? response['mensaje'] ?? response['error'];
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }
}
