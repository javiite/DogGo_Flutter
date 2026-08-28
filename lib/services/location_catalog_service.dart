import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../screens/location/models/mexico_location.dart';
import 'api_service.dart';

class LocationCatalogService {
  Future<List<MexicoState>> getStates() async {
    final response = await ApiService.getAuth(
      '/api/catalogos/ubicaciones/estados',
    );
    final data = _data(response);
    return data
        .whereType<Map>()
        .map((item) => MexicoState.fromMap(Map<String, dynamic>.from(item)))
        .where((item) => item.code.isNotEmpty)
        .toList();
  }

  Future<List<MexicoMunicipality>> getMunicipalities(String stateCode) async {
    final response = await ApiService.getAuth(
      '/api/catalogos/ubicaciones/estados/$stateCode/municipios',
    );
    final data = _data(response);
    return data
        .whereType<Map>()
        .map(
          (item) => MexicoMunicipality.fromMap(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.code.isNotEmpty)
        .toList();
  }

  Future<LatLng?> geocodeMunicipality({
    required String municipality,
    required String state,
  }) async {
    final query = '$municipality, $state, México';
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'mx',
    });
    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'DogGoApp/1.0 (coverage-map)',
        'Accept-Language': 'es-MX,es',
      },
    );
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty || decoded.first is! Map) {
      return null;
    }
    final item = Map<String, dynamic>.from(decoded.first as Map);
    final latitude = double.tryParse(item['lat']?.toString() ?? '');
    final longitude = double.tryParse(item['lon']?.toString() ?? '');
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude, longitude);
  }

  List<dynamic> _data(Map<String, dynamic> response) {
    final raw = response['body'] ?? response;
    if (raw is Map) {
      final data = raw['data'];
      if (data is List) return data;
      final message = raw['message'];
      if (message != null) throw Exception(message.toString());
    }
    throw Exception('El catálogo de ubicaciones no devolvió datos válidos.');
  }
}
