import 'models/rating_option.dart';

class RatingState {
  final int walkId;
  final String petName;
  final String walkerName;
  final bool checking;
  final bool submitting;
  final bool alreadyRated;
  final String? error;
  final RatingOption selectedRating;

  const RatingState({
    required this.walkId,
    required this.petName,
    required this.walkerName,
    this.checking = true,
    this.submitting = false,
    this.alreadyRated = false,
    this.error,
    this.selectedRating =
        RatingOption.excellent,
  });

  bool get busy {
    return checking || submitting;
  }

  int get score {
    return selectedRating.score;
  }

  String get scoreLabel {
    return '$score de 5 estrellas';
  }

  bool get canSubmit {
    return walkId > 0 &&
        !busy &&
        !alreadyRated;
  }

  RatingState copyWith({
    int? walkId,
    String? petName,
    String? walkerName,
    bool? checking,
    bool? submitting,
    bool? alreadyRated,
    String? error,
    bool clearError = false,
    RatingOption? selectedRating,
  }) {
    return RatingState(
      walkId: walkId ?? this.walkId,
      petName: petName ?? this.petName,
      walkerName:
          walkerName ?? this.walkerName,
      checking:
          checking ?? this.checking,
      submitting:
          submitting ?? this.submitting,
      alreadyRated:
          alreadyRated ?? this.alreadyRated,
      error:
          clearError ? null : error ?? this.error,
      selectedRating:
          selectedRating ?? this.selectedRating,
    );
  }
}