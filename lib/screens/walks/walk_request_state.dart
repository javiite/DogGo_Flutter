import '../pets/models/pet.dart';
import '../walkers/models/walker.dart';
import 'models/pickup_location.dart';
import 'models/walk_request_availability.dart';

class WalkScheduleDraft {
  final DateTime startsAt;
  final int durationMinutes;
  final List<int> petIds;

  const WalkScheduleDraft({
    required this.startsAt,
    required this.durationMinutes,
    required this.petIds,
  });

  DateTime get endsAt => startsAt.add(Duration(minutes: durationMinutes));

  bool overlaps(DateTime start, int duration) {
    final end = start.add(Duration(minutes: duration));
    return start.isBefore(endsAt) && end.isAfter(startsAt);
  }
}

class WalkRequestState {
  static const List<int> allowedDurations = [30, 45, 60, 90];
  static const int minDurationMinutes = 30;
  static const int maxDurationMinutes = 90;
  static const int durationStepMinutes = 5;

  static const int maxSelectedPets = 5;

  static bool isValidDuration(int minutes) {
    return minutes >= minDurationMinutes &&
        minutes <= maxDurationMinutes &&
        minutes % durationStepMinutes == 0;
  }

  final Walker walker;
  final bool loading;
  final bool saving;
  final bool loadingLocation;
  final String? error;
  final String? baseUrl;
  final List<Pet> pets;
  final List<int> selectedPetIds;
  final int durationMinutes;
  final DateTime? selectedDay;
  final DateTime? scheduledAt;
  final List<WalkScheduleDraft> scheduledWalks;
  final PickupLocation? pickupLocation;
  final PickupLocation? defaultLocation;
  final bool loadingAvailability;
  final WalkRequestAvailability? availability;
  final String? availabilityError;

  const WalkRequestState({
    required this.walker,
    this.loading = true,
    this.saving = false,
    this.loadingLocation = false,
    this.error,
    this.baseUrl,
    this.pets = const [],
    this.selectedPetIds = const [],
    this.durationMinutes = 30,
    this.selectedDay,
    this.scheduledAt,
    this.scheduledWalks = const [],
    this.pickupLocation,
    this.defaultLocation,
    this.loadingAvailability = false,
    this.availability,
    this.availabilityError,
  });

  List<Pet> get selectedPets {
    return pets
        .where((pet) => selectedPetIds.contains(pet.id))
        .toList(growable: false);
  }

  int get selectedPetCount {
    return selectedPets.length;
  }

  bool isPetSelected(int petId) {
    return selectedPetIds.contains(petId);
  }

  bool get hasPets {
    return pets.isNotEmpty;
  }

  bool get hasSelectedPets {
    return selectedPets.isNotEmpty;
  }

  bool get hasMultiplePets {
    return selectedPetCount > 1;
  }

  bool get hasPickupLocation {
    return pickupLocation != null;
  }

  bool get hasDefaultLocation {
    return defaultLocation != null;
  }

  bool get canSubmit {
    final walks = effectiveScheduledWalks;
    return !loading &&
        !saving &&
        walker.hasValidId &&
        hasSelectedPets &&
        selectedPetCount <= maxSelectedPets &&
        walks.isNotEmpty &&
        pickupLocation != null &&
        walks.every(
          (walk) =>
              availability?.accepts(walk.startsAt, walk.durationMinutes) ==
              true,
        );
  }

  List<WalkScheduleDraft> get effectiveScheduledWalks {
    if (scheduledWalks.isNotEmpty) return scheduledWalks;
    if (scheduledAt == null) return const [];
    return [
      WalkScheduleDraft(
        startsAt: scheduledAt!,
        durationMinutes: durationMinutes,
        petIds: List.unmodifiable(selectedPetIds),
      ),
    ];
  }

  List<DateTime> get effectiveScheduledDates {
    return effectiveScheduledWalks.map((item) => item.startsAt).toList();
  }

  int get walkCount => effectiveScheduledDates.length;

  List<WalkTimeSlotOption> get currentSlotOptions {
    final day = selectedDay;
    final source = availability;
    if (day == null || source == null) return const [];
    return source.slotOptionsFor(
      day,
      durationMinutes,
      localReservations: scheduledWalks
          .map(
            (walk) => WalkUnavailablePeriod(
              walk.startsAt.toUtc(),
              walk.endsAt.toUtc(),
              true,
            ),
          )
          .toList(growable: false),
    );
  }

  double get hourlyRate {
    return walker.hourlyRate ?? 0;
  }

  double get basePrice {
    return hourlyRate * (durationMinutes / 60);
  }

  double get additionalPetsPrice {
    if (selectedPetCount <= 1) {
      return 0;
    }

    return basePrice * 0.50 * (selectedPetCount - 1);
  }

  double get pricePerWalk {
    if (!hasSelectedPets) {
      return 0;
    }

    return basePrice + additionalPetsPrice;
  }

  double priceForWalk(WalkScheduleDraft walk) {
    final base = hourlyRate * (walk.durationMinutes / 60);
    final additional = walk.petIds.length <= 1
        ? 0
        : base * .50 * (walk.petIds.length - 1);
    return base + additional;
  }

  double get estimatedTotal {
    final walks = effectiveScheduledWalks;
    if (walks.isEmpty) return pricePerWalk;
    return walks.fold(0, (total, walk) => total + priceForWalk(walk));
  }

  String get selectedPetsLabel {
    if (selectedPets.isEmpty) {
      return 'Selecciona tus mascotas';
    }

    if (selectedPets.length == 1) {
      return selectedPets.first.name;
    }

    return '${selectedPets.length} mascotas';
  }

  String get pricingExplanation {
    if (selectedPetCount <= 1) {
      return 'Tarifa para una mascota';
    }

    final additional = selectedPetCount - 1;

    return additional == 1
        ? 'Incluye 1 mascota adicional al 50%'
        : 'Incluye $additional mascotas adicionales al 50%';
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

    final minute = date.minute.toString().padLeft(2, '0');

    return '${date.day} '
        '${months[date.month - 1]} '
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
    List<int>? selectedPetIds,
    bool clearSelectedPets = false,
    int? durationMinutes,
    DateTime? selectedDay,
    bool clearSelectedDay = false,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
    List<WalkScheduleDraft>? scheduledWalks,
    bool clearScheduledWalks = false,
    PickupLocation? pickupLocation,
    bool clearPickupLocation = false,
    PickupLocation? defaultLocation,
    bool clearDefaultLocation = false,
    bool? loadingAvailability,
    WalkRequestAvailability? availability,
    String? availabilityError,
    bool clearAvailabilityError = false,
  }) {
    return WalkRequestState(
      walker: walker ?? this.walker,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      loadingLocation: loadingLocation ?? this.loadingLocation,
      error: clearError ? null : error ?? this.error,
      baseUrl: baseUrl ?? this.baseUrl,
      pets: pets ?? this.pets,
      selectedPetIds: clearSelectedPets
          ? const []
          : selectedPetIds ?? this.selectedPetIds,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      selectedDay: clearSelectedDay ? null : selectedDay ?? this.selectedDay,
      scheduledAt: clearScheduledAt ? null : scheduledAt ?? this.scheduledAt,
      scheduledWalks: clearScheduledWalks
          ? const []
          : scheduledWalks ?? this.scheduledWalks,
      pickupLocation: clearPickupLocation
          ? null
          : pickupLocation ?? this.pickupLocation,
      defaultLocation: clearDefaultLocation
          ? null
          : defaultLocation ?? this.defaultLocation,
      loadingAvailability: loadingAvailability ?? this.loadingAvailability,
      availability: availability ?? this.availability,
      availabilityError: clearAvailabilityError
          ? null
          : availabilityError ?? this.availabilityError,
    );
  }
}
