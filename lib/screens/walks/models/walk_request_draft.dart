import 'pickup_location.dart';

class WalkRequestDraft {
  final int walkerId;
  final List<int> petIds;
  final int durationMinutes;
  final DateTime? scheduledAt;
  final PickupLocation? pickupLocation;
  final String notes;
  final DateTime updatedAt;

  const WalkRequestDraft({
    required this.walkerId,
    this.petIds = const [],
    this.durationMinutes = 30,
    this.scheduledAt,
    this.pickupLocation,
    this.notes = '',
    required this.updatedAt,
  });

  factory WalkRequestDraft.fromMap(Map<String, dynamic> map) {
    final location = map['pickupLocation'];
    return WalkRequestDraft(
      walkerId: int.tryParse('${map['walkerId']}') ?? 0,
      petIds: (map['petIds'] is List ? map['petIds'] as List : const [])
          .map((value) => int.tryParse('$value'))
          .whereType<int>()
          .toList(),
      durationMinutes: int.tryParse('${map['durationMinutes']}') ?? 30,
      scheduledAt: DateTime.tryParse('${map['scheduledAt'] ?? ''}'),
      pickupLocation: location is Map
          ? PickupLocation.fromMap(Map<String, dynamic>.from(location))
          : null,
      notes: map['notes']?.toString() ?? '',
      updatedAt:
          DateTime.tryParse('${map['updatedAt'] ?? ''}') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'walkerId': walkerId,
    'petIds': petIds,
    'durationMinutes': durationMinutes,
    'scheduledAt': scheduledAt?.toIso8601String(),
    'pickupLocation': pickupLocation == null
        ? null
        : {
            'latitudRecogida': pickupLocation!.latitude,
            'longitudRecogida': pickupLocation!.longitude,
            'direccionRecogida': pickupLocation!.address,
            'referenciasRecogida': pickupLocation!.reference,
          },
    'notes': notes,
    'updatedAt': updatedAt.toIso8601String(),
  };
}
