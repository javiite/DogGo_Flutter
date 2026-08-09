import 'package:shared_preferences/shared_preferences.dart';

import '../screens/explore/models/place_item.dart';

class PlacesPreferencesService {
  static const String _latitudeKey =
      'doggo_places_latitude';

  static const String _longitudeKey =
      'doggo_places_longitude';

  static const String _locationTextKey =
      'doggo_places_location_text';

  static const String _categoryKey =
      'doggo_places_last_category';

  static Future<void> saveLocation({
    required double latitude,
    required double longitude,
    required String locationText,
  }) async {
    final preferences =
        await SharedPreferences.getInstance();

    await preferences.setDouble(
      _latitudeKey,
      latitude,
    );

    await preferences.setDouble(
      _longitudeKey,
      longitude,
    );

    await preferences.setString(
      _locationTextKey,
      locationText.trim().isEmpty
          ? 'Ubicación seleccionada'
          : locationText.trim(),
    );
  }

  static Future<Map<String, dynamic>?>
      getLocation() async {
    final preferences =
        await SharedPreferences.getInstance();

    final latitude =
        preferences.getDouble(_latitudeKey);

    final longitude =
        preferences.getDouble(_longitudeKey);

    if (latitude == null || longitude == null) {
      return null;
    }

    return {
      'latitud': latitude,
      'longitud': longitude,
      'texto': preferences.getString(
            _locationTextKey,
          ) ??
          'Ubicación guardada',
    };
  }

  static Future<void> saveCategory(
    PlaceCategory category,
  ) async {
    final preferences =
        await SharedPreferences.getInstance();

    await preferences.setString(
      _categoryKey,
      category.name,
    );
  }

  static Future<PlaceCategory> getCategory() async {
    final preferences =
        await SharedPreferences.getInstance();

    final savedName =
        preferences.getString(_categoryKey);

    for (final category in PlaceCategory.values) {
      if (category.name == savedName) {
        return category;
      }
    }

    return PlaceCategory.veterinary;
  }

  static Future<void> clearLocation() async {
    final preferences =
        await SharedPreferences.getInstance();

    await preferences.remove(_latitudeKey);
    await preferences.remove(_longitudeKey);
    await preferences.remove(_locationTextKey);
  }
}