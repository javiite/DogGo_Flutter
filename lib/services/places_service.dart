import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../screens/explore/models/place_item.dart';

class PlacesService {
  static final List<Uri> _endpoints = [
    Uri.parse(
      'https://overpass-api.de/api/interpreter',
    ),
    Uri.parse(
      'https://overpass.private.coffee/api/interpreter',
    ),
  ];

  static Future<List<PlaceItem>> searchNearby({
    required double latitude,
    required double longitude,
    required PlaceCategory category,
    int radiusMeters = 10000,
  }) async {
    final safeRadius = radiusMeters.clamp(
      1000,
      20000,
    );

    final query = _buildQuery(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: safeRadius,
      category: category,
    );

    Object? lastError;

    for (final endpoint in _endpoints) {
      try {
        return await _requestPlaces(
          endpoint: endpoint,
          query: query,
          latitude: latitude,
          longitude: longitude,
          category: category,
        );
      } catch (error) {
        lastError = error;
      }
    }

    if (lastError is Exception) {
      throw lastError;
    }

    throw Exception(
      'Los servicios de lugares no están disponibles. Inténtalo nuevamente.',
    );
  }

  static Future<List<PlaceItem>> _requestPlaces({
    required Uri endpoint,
    required String query,
    required double latitude,
    required double longitude,
    required PlaceCategory category,
  }) async {
    final response = await http
        .post(
          endpoint,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'DogGoApp/1.0',
          },
          body: {
            'data': query,
          },
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode == 429 ||
        response.statusCode == 502 ||
        response.statusCode == 503 ||
        response.statusCode == 504) {
      throw Exception(
        'El servidor de lugares está ocupado.',
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'No se pudieron consultar los lugares cercanos.',
      );
    }

    final decoded = jsonDecode(
      utf8.decode(
        response.bodyBytes,
        allowMalformed: true,
      ),
    );

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'El servicio devolvió una respuesta inesperada.',
      );
    }

    final rawElements = decoded['elements'];

    if (rawElements is! List) {
      return const [];
    }

    final places = <PlaceItem>[];
    final uniqueKeys = <String>{};

    for (final rawElement in rawElements) {
      if (rawElement is! Map) {
        continue;
      }

      final element =
          Map<String, dynamic>.from(rawElement);

      final coordinates = _coordinates(element);

      if (coordinates == null) {
        continue;
      }

      final tags = _tags(element['tags']);
      final name = _placeName(tags, category);

      final uniqueKey =
          '${name.toLowerCase()}|'
          '${coordinates.latitude.toStringAsFixed(5)}|'
          '${coordinates.longitude.toStringAsFixed(5)}';

      if (!uniqueKeys.add(uniqueKey)) {
        continue;
      }

      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        coordinates.latitude,
        coordinates.longitude,
      );

      places.add(
        PlaceItem(
          id: '${element['type'] ?? 'place'}-'
              '${element['id']}',
          name: name,
          address: _address(tags),
          category: category,
          latitude: coordinates.latitude,
          longitude: coordinates.longitude,
          distanceMeters: distance,
          phone: _firstText([
            tags['phone'],
            tags['contact:phone'],
          ]),
          website: _firstText([
            tags['website'],
            tags['contact:website'],
          ]),
          source: 'OpenStreetMap',
        ),
      );
    }

    places.sort(
      (first, second) =>
          first.distanceMeters.compareTo(
        second.distanceMeters,
      ),
    );

    return places.take(30).toList(
          growable: false,
        );
  }

  static String _buildQuery({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    required PlaceCategory category,
  }) {
    final around =
        '(around:$radiusMeters,$latitude,$longitude)';

    final filters = switch (category) {
      PlaceCategory.parks => '''
        nwr$around["leisure"="dog_park"];
        nwr$around["leisure"="park"]["dog"~"yes|designated|leashed",i];
      ''',
      PlaceCategory.veterinary => '''
        nwr$around["amenity"="veterinary"];
      ''',
      PlaceCategory.stores => '''
        nwr$around["shop"="pet"];
        nwr$around["shop"="pet_grooming"];
      ''',
      PlaceCategory.petFriendly => '''
        nwr$around["dog"~"yes|designated|leashed",i]["name"];
        nwr$around["pets"~"yes|allowed",i]["name"];
      ''',
    };

    return '''
      [out:json][timeout:22];
      (
        $filters
      );
      out center tags 80;
    ''';
  }

  static _PlaceCoordinates? _coordinates(
    Map<String, dynamic> element,
  ) {
    final directLatitude =
        _toDouble(element['lat']);

    final directLongitude =
        _toDouble(element['lon']);

    if (directLatitude != null &&
        directLongitude != null) {
      return _PlaceCoordinates(
        latitude: directLatitude,
        longitude: directLongitude,
      );
    }

    final rawCenter = element['center'];

    if (rawCenter is! Map) {
      return null;
    }

    final center =
        Map<String, dynamic>.from(rawCenter);

    final latitude = _toDouble(center['lat']);
    final longitude = _toDouble(center['lon']);

    if (latitude == null || longitude == null) {
      return null;
    }

    return _PlaceCoordinates(
      latitude: latitude,
      longitude: longitude,
    );
  }

  static Map<String, String> _tags(
    dynamic rawTags,
  ) {
    if (rawTags is! Map) {
      return const {};
    }

    return rawTags.map(
      (key, value) => MapEntry(
        key.toString(),
        value?.toString() ?? '',
      ),
    );
  }

  static String _placeName(
    Map<String, String> tags,
    PlaceCategory category,
  ) {
    final name = _firstText([
      tags['name'],
      tags['brand'],
      tags['operator'],
    ]);

    if (name != null) {
      return name;
    }

    return switch (category) {
      PlaceCategory.parks =>
        'Parque para perros',
      PlaceCategory.veterinary => 'Veterinaria',
      PlaceCategory.stores =>
        'Tienda para mascotas',
      PlaceCategory.petFriendly =>
        'Lugar pet friendly',
    };
  }

  static String _address(
    Map<String, String> tags,
  ) {
    final fullAddress = _firstText([
      tags['addr:full'],
    ]);

    if (fullAddress != null) {
      return fullAddress;
    }

    final street = _firstText([
      tags['addr:street'],
      tags['addr:place'],
    ]);

    final houseNumber = _firstText([
      tags['addr:housenumber'],
    ]);

    final suburb = _firstText([
      tags['addr:suburb'],
      tags['addr:neighbourhood'],
      tags['addr:city'],
    ]);

    final parts = <String>[
      if (street != null)
        houseNumber == null
            ? street
            : '$street $houseNumber',
      if (suburb != null) suburb,
    ];

    if (parts.isEmpty) {
      return 'Ubicación registrada en el mapa';
    }

    return parts.join(', ');
  }

  static String? _firstText(
    List<String?> values,
  ) {
    for (final value in values) {
      final cleanValue = value?.trim() ?? '';

      if (cleanValue.isNotEmpty) {
        return cleanValue;
      }
    }

    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }
}

class _PlaceCoordinates {
  final double latitude;
  final double longitude;

  const _PlaceCoordinates({
    required this.latitude,
    required this.longitude,
  });
}