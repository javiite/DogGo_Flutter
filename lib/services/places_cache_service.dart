import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../screens/explore/models/place_item.dart';

class PlacesCacheEntry {
  final List<PlaceItem> places;
  final DateTime savedAt;

  const PlacesCacheEntry({
    required this.places,
    required this.savedAt,
  });

  bool get isFresh {
    return DateTime.now().difference(savedAt) <
        const Duration(minutes: 30);
  }

  String get updatedLabel {
    final difference = DateTime.now().difference(savedAt);

    if (difference.inMinutes < 1) {
      return 'Actualizado ahora';
    }

    if (difference.inMinutes < 60) {
      return 'Actualizado hace ${difference.inMinutes} min';
    }

    if (difference.inHours < 24) {
      return 'Actualizado hace ${difference.inHours} h';
    }

    return 'Datos guardados anteriormente';
  }
}

class PlacesCacheService {
  static const String _prefix =
      'doggo_places_cache_';

  static Future<PlacesCacheEntry?> get({
    required double latitude,
    required double longitude,
    required PlaceCategory category,
  }) async {
    final preferences =
        await SharedPreferences.getInstance();

    final key = _buildKey(
      latitude: latitude,
      longitude: longitude,
      category: category,
    );

    final rawValue = preferences.getString(key);

    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawValue);

      if (decoded is! Map) {
        return null;
      }

      final map = Map<String, dynamic>.from(decoded);
      final savedAt = DateTime.tryParse(
        map['savedAt']?.toString() ?? '',
      );

      final rawPlaces = map['places'];

      if (savedAt == null || rawPlaces is! List) {
        return null;
      }

      final places = rawPlaces
          .whereType<Map>()
          .map(
            (item) => _placeFromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .whereType<PlaceItem>()
          .toList(growable: false);

      return PlacesCacheEntry(
        places: places,
        savedAt: savedAt,
      );
    } catch (_) {
      await preferences.remove(key);
      return null;
    }
  }

  static Future<void> save({
    required double latitude,
    required double longitude,
    required PlaceCategory category,
    required List<PlaceItem> places,
  }) async {
    final preferences =
        await SharedPreferences.getInstance();

    final key = _buildKey(
      latitude: latitude,
      longitude: longitude,
      category: category,
    );

    final value = jsonEncode({
      'savedAt': DateTime.now().toIso8601String(),
      'places': places
          .take(30)
          .map(_placeToMap)
          .toList(growable: false),
    });

    await preferences.setString(key, value);
  }

  static Future<void> clear() async {
    final preferences =
        await SharedPreferences.getInstance();

    final keys = preferences
        .getKeys()
        .where((key) => key.startsWith(_prefix))
        .toList(growable: false);

    for (final key in keys) {
      await preferences.remove(key);
    }
  }

  static String _buildKey({
    required double latitude,
    required double longitude,
    required PlaceCategory category,
  }) {
    final latitudeKey = latitude.toStringAsFixed(3);
    final longitudeKey = longitude.toStringAsFixed(3);

    return '$_prefix'
        '${category.name}_'
        '${latitudeKey}_'
        '$longitudeKey';
  }

  static Map<String, dynamic> _placeToMap(
    PlaceItem place,
  ) {
    return {
      'id': place.id,
      'name': place.name,
      'address': place.address,
      'category': place.category.name,
      'latitude': place.latitude,
      'longitude': place.longitude,
      'distanceMeters': place.distanceMeters,
      'phone': place.phone,
      'website': place.website,
      'source': place.source,
    };
  }

  static PlaceItem? _placeFromMap(
    Map<String, dynamic> map,
  ) {
    final latitude = _toDouble(map['latitude']);
    final longitude = _toDouble(map['longitude']);
    final distance = _toDouble(
      map['distanceMeters'],
    );

    final id = map['id']?.toString().trim() ?? '';
    final name =
        map['name']?.toString().trim() ?? '';

    if (latitude == null ||
        longitude == null ||
        distance == null ||
        id.isEmpty ||
        name.isEmpty) {
      return null;
    }

    final categoryName =
        map['category']?.toString() ?? '';

    final category = PlaceCategory.values
        .where((item) => item.name == categoryName)
        .firstOrNull;

    if (category == null) {
      return null;
    }

    return PlaceItem(
      id: id,
      name: name,
      address: map['address']?.toString() ??
          'Ubicación registrada en el mapa',
      category: category,
      latitude: latitude,
      longitude: longitude,
      distanceMeters: distance,
      phone: _nullableText(map['phone']),
      website: _nullableText(map['website']),
      source:
          map['source']?.toString() ?? 'OpenStreetMap',
    );
  }

  static String? _nullableText(dynamic value) {
    final text = value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
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