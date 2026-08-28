import 'models/walker.dart';
import 'models/walker_availability.dart';
import 'models/walker_review.dart';
import 'models/walker_trust.dart';

class WalkerDetailState {
  final Walker walker;
  final String? baseUrl;
  final bool loadingProfile;
  final String? profileError;
  final bool loadingAvailability;
  final WalkerAvailability availability;
  final bool loadingTrust;
  final WalkerTrust? trust;
  final bool loadingReviews;
  final String? reviewsError;
  final List<WalkerReview> reviews;

  const WalkerDetailState({
    required this.walker,
    this.baseUrl,
    this.loadingProfile = true,
    this.profileError,
    this.loadingAvailability = true,
    this.availability = const WalkerAvailability.empty(),
    this.loadingTrust = true,
    this.trust,
    this.loadingReviews = true,
    this.reviewsError,
    this.reviews = const [],
  });

  String? get photoUrl {
    return walker.publicPhotoUrl(baseUrl);
  }

  bool get hasReviews {
    return reviews.isNotEmpty;
  }

  int get displayedReviewCount {
    if (reviews.length > walker.reviewCount) {
      return reviews.length;
    }

    return walker.reviewCount;
  }

  int get displayedCompletedWalks {
    final trusted = trust?.completedWalks ?? 0;
    return trusted > walker.completedWalks ? trusted : walker.completedWalks;
  }

  int get displayedExperienceYears {
    final trusted = trust?.experienceYears ?? 0;
    return trusted > walker.experienceYears ? trusted : walker.experienceYears;
  }

  double get displayedRating {
    if (walker.rating > 0) {
      return walker.rating;
    }

    final ratedReviews = reviews.where((review) => review.rating > 0);

    if (ratedReviews.isEmpty) {
      return 0;
    }

    final total = ratedReviews.fold<double>(
      0,
      (sum, review) => sum + review.rating,
    );

    return total / ratedReviews.length;
  }

  String get ratingLabel {
    final value = displayedRating;

    if (value <= 0) {
      return 'Sin calificación';
    }

    return value.toStringAsFixed(1);
  }

  String get reviewCountLabel {
    final count = displayedReviewCount;

    if (count == 0) {
      return 'Sin reseñas';
    }

    if (count == 1) {
      return '1 reseña';
    }

    return '$count reseñas';
  }

  WalkerDetailState copyWith({
    Walker? walker,
    String? baseUrl,
    bool? loadingProfile,
    String? profileError,
    bool clearProfileError = false,
    bool? loadingAvailability,
    WalkerAvailability? availability,
    bool? loadingTrust,
    WalkerTrust? trust,
    bool? loadingReviews,
    String? reviewsError,
    bool clearReviewsError = false,
    List<WalkerReview>? reviews,
  }) {
    return WalkerDetailState(
      walker: walker ?? this.walker,
      baseUrl: baseUrl ?? this.baseUrl,
      loadingProfile: loadingProfile ?? this.loadingProfile,
      profileError: clearProfileError
          ? null
          : profileError ?? this.profileError,
      loadingAvailability: loadingAvailability ?? this.loadingAvailability,
      availability: availability ?? this.availability,
      loadingTrust: loadingTrust ?? this.loadingTrust,
      trust: trust ?? this.trust,
      loadingReviews: loadingReviews ?? this.loadingReviews,
      reviewsError: clearReviewsError
          ? null
          : reviewsError ?? this.reviewsError,
      reviews: reviews ?? this.reviews,
    );
  }
}
