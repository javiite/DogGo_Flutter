import '../../services/paseadores_service.dart';
import '../../services/storage_service.dart';
import 'models/walker.dart';

class WalkersLoadResult {
  final String? baseUrl;
  final List<Walker> walkers;

  const WalkersLoadResult({required this.baseUrl, required this.walkers});
}

class WalkersRepository {
  Future<WalkersLoadResult> getAll() async {
    final results = await Future.wait<dynamic>([
      StorageService.obtenerBaseUrl(),
      PaseadoresService.obtenerPaseadores(),
    ]);
    final response = results[1] is Map
        ? Map<String, dynamic>.from(results[1] as Map)
        : <String, dynamic>{};
    if (response['success'] != true) {
      final message = response['message']?.toString().trim();
      throw Exception(
        message == null || message.isEmpty
            ? 'No se pudieron cargar los paseadores.'
            : message,
      );
    }
    return WalkersLoadResult(
      baseUrl: results[0]?.toString(),
      walkers: Walker.listFrom(response['data']),
    );
  }
}
