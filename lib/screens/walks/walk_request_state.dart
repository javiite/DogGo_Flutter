import '../pets/models/pet.dart';
import '../walkers/models/walker.dart';
import 'models/pickup_location.dart';

class WalkRequestState {
  static const List<int> allowedDurations = [
    30,
    45,
    60,
    90,
  ];

  final Walker walker;
  final bool loading;
  final bool saving;
  final bool loadingLocation;
  final String? error;
  final String? baseUrl;
  final List<Pet> pets;
  final int? selectedPetId;
  final int durationMinutes;
  final DateTime? scheduledAt;
  final PickupLocation? pickupLocation;
  final PickupLocation? defaultLocation;

  const WalkRequestState({
    required this.walker,
    this.loading = true,
    this.saving = false,
    this.loadingLocation = false,
    this.error,
    this.baseUrl,
    this.pets = const [],
    this.selectedPetId,
    this.durationMinutes = 30,
    this.scheduledAt,
    this.pickupLocation,
    this.defaultLocation,
  });

  Pet? get selectedPet {
    final id = selectedPetId;

    if (id == null) {
      return null;
    }

    for (final pet in pets) {
      if (pet.id == id) {
        return pet;
      }
    }

    return null;
  }

  bool get hasPets {
    return pets.isNotEmpty;
  }

  bool get hasPickupLocation {
    return pickupLocation != null;
  }

  bool get hasDefaultLocation {
    return defaultLocation != null;
  }

  bool get canSubmit {
    return !loading &&
        !saving &&
        walker.hasValidId &&
        selectedPet != null &&
        scheduledAt != null &&
        pickupLocation != null;
  }

  double get hourlyRate {
    return walker.hourlyRate ?? 0;
  }

  double get estimatedTotal {
    return hourlyRate *
        (durationMinutes / 60);
  }

  String get durationLabel {
    switch (durationMinutes) {
      case 30:
        return '30 min';
      case 45:
        return '45 min';
      case 60:
        return '1 hora';
      case 90:
        return '1.5 horas';
      default:
        return '$durationMinutes min';
    }
  }

  String get scheduleLabel {
    final date = scheduledAt;

    if (date == null) {
      return 'Selecciona fecha y hora';
    }

    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    final hour = date.hour.toString().padLeft(2, '0');
    final minute =
        date.minute.toString().padLeft(2, '0');

    return '${date.day} ${months[date.month - 1]} '
        '${date.year} · $hour:$minute';
  }

  String? petPhotoUrl(Pet pet) {
    return pet.publicPhotoUrl(baseUrl);
  }

  String? get walkerPhotoUrl {
    return walker.publicPhotoUrl(baseUrl);
  }

  WalkRequestState copyWith({
    Walker? walker,
    bool? loading,
    bool? saving,
    bool? loadingLocation,
    String? error,
    bool clearError = false,
    String? baseUrl,
    List<Pet>? pets,
    int? selectedPetId,
    bool clearSelectedPet = false,
    int? durationMinutes,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
    PickupLocation? pickupLocation,
    bool clearPickupLocation = false,
    PickupLocation? defaultLocation,
    bool clearDefaultLocation = false,
  }) {
    return WalkRequestState(
      walker: walker ?? this.walker,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      loadingLocation:
          loadingLocation ?? this.loadingLocation,
      error: clearError
          ? null
          : error ?? this.error,
      baseUrl: baseUrl ?? this.baseUrl,
      pets: pets ?? this.pets,
      selectedPetId: clearSelectedPet
          ? null
          : selectedPetId ?? this.selectedPetId,
      durationMinutes:
          durationMinutes ?? this.durationMinutes,
      scheduledAt: clearScheduledAt
          ? null
          : scheduledAt ?? this.scheduledAt,
      pickupLocation: clearPickupLocation
          ? null
          : pickupLocation ?? this.pickupLocation,
      defaultLocation: clearDefaultLocation
          ? null
          : defaultLocation ?? this.defaultLocation,
    );
  }
}