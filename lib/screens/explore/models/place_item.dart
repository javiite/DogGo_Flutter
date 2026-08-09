enum PlaceCategory {
  parks,
  veterinary,
  stores,
  petFriendly,
}

class PlaceItem {
  final String id;
  final String name;
  final String address;
  final PlaceCategory category;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final String? phone;
  final String? website;
  final String source;

  const PlaceItem({
    required this.id,
    required this.name,
    required this.address,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.source,
    this.phone,
    this.website,
  });

  String get distanceLabel {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }

    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }
}