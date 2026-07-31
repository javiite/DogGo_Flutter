import 'models/walker.dart';
import 'models/walker_review.dart';

class WalkerDetailState {
  final Walker walker;
  final String? baseUrl;
  final bool loadingReviews;
  final String? reviewsError;
  final List<WalkerReview> reviews;

  const WalkerDetailState({
    required this.walker,
    this.baseUrl,
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

  double get displayedRating {
    if (walker.rating > 0) {
      return walker.rating;
    }

    final ratedReviews = reviews.where(
      (review) => review.rating > 0,
    );

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
    bool? loadingReviews,
    String? reviewsError,
    bool clearReviewsError = false,
    List<WalkerReview>? reviews,
  }) {
    return WalkerDetailState(
      walker: walker ?? this.walker,
      baseUrl: baseUrl ?? this.baseUrl,
      loadingReviews:
          loadingReviews ?? this.loadingReviews,
      reviewsError: clearReviewsError
          ? null
          : reviewsError ?? this.reviewsError,
      reviews: reviews ?? this.reviews,
    );
  }
}