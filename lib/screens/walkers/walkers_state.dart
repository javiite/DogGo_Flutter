import 'models/walker.dart';

enum WalkerSort {
  bestRated,
  lowestRate,
  mostExperience,
}

extension WalkerSortLabel on WalkerSort {
  String get label {
    switch (this) {
      case WalkerSort.bestRated:
        return 'Mejor calificación';
      case WalkerSort.lowestRate:
        return 'Menor tarifa';
      case WalkerSort.mostExperience:
        return 'Más experiencia';
    }
  }
}

class WalkersState {
  static const String allZones = 'Todas';

  final bool loading;
  final String? error;
  final String? baseUrl;
  final List<Walker> walkers;
  final String searchQuery;
  final String selectedZone;
  final bool onlyAvailable;
  final WalkerSort sort;

  const WalkersState({
    this.loading = true,
    this.error,
    this.baseUrl,
    this.walkers = const [],
    this.searchQuery = '',
    this.selectedZone = allZones,
    this.onlyAvailable = false,
    this.sort = WalkerSort.bestRated,
  });

  bool get isEmpty => !loading && walkers.isEmpty;

  bool get hasWalkers => walkers.isNotEmpty;

  bool get hasActiveFilters {
    return searchQuery.trim().isNotEmpty ||
        selectedZone != allZones ||
        onlyAvailable ||
        sort != WalkerSort.bestRated;
  }

  int get totalWalkers => walkers.length;

  int get availableWalkers {
    return walkers
        .where((walker) => walker.available)
        .length;
  }

  double get averageRating {
    final rated = walkers
        .where((walker) => walker.rating > 0)
        .toList(growable: false);

    if (rated.isEmpty) return 0;

    final total = rated.fold<double>(
      0,
      (sum, walker) => sum + walker.rating,
    );

    return total / rated.length;
  }

  List<String> get availableZones {
    final zones = <String>{};

    for (final walker in walkers) {
      zones.addAll(walker.zones);
    }

    final result = zones.toList()..sort();

    return [
      allZones,
      ...result,
    ];
  }

  List<Walker> get filteredWalkers {
    final query = searchQuery.trim().toLowerCase();

    final result = walkers.where((walker) {
      if (onlyAvailable && !walker.available) {
        return false;
      }

      if (selectedZone != allZones) {
        final matchesZone = walker.zones.any(
          (zone) =>
              zone.toLowerCase() ==
              selectedZone.toLowerCase(),
        );

        if (!matchesZone) return false;
      }

      if (query.isEmpty) return true;

      final searchableText = [
        walker.name,
        walker.email,
        walker.description,
        walker.serviceZone,
        walker.rateLabel,
        walker.experienceLabel,
      ].join(' ').toLowerCase();

      return searchableText.contains(query);
    }).toList();

    result.sort((first, second) {
      if (first.available != second.available) {
        return first.available ? -1 : 1;
      }

      switch (sort) {
        case WalkerSort.bestRated:
          final ratingComparison =
              second.rating.compareTo(first.rating);

          if (ratingComparison != 0) {
            return ratingComparison;
          }

          return second.reviewCount.compareTo(
            first.reviewCount,
          );

        case WalkerSort.lowestRate:
          final firstRate =
              first.hourlyRate ?? double.maxFinite;

          final secondRate =
              second.hourlyRate ?? double.maxFinite;

          return firstRate.compareTo(secondRate);

        case WalkerSort.mostExperience:
          return second.experienceYears.compareTo(
            first.experienceYears,
          );
      }
    });

    return List<Walker>.unmodifiable(result);
  }

  String? photoUrlFor(Walker walker) {
    return walker.publicPhotoUrl(baseUrl);
  }

  WalkersState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    String? baseUrl,
    List<Walker>? walkers,
    String? searchQuery,
    String? selectedZone,
    bool? onlyAvailable,
    WalkerSort? sort,
  }) {
    return WalkersState(
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      baseUrl: baseUrl ?? this.baseUrl,
      walkers: walkers ?? this.walkers,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedZone:
          selectedZone ?? this.selectedZone,
      onlyAvailable:
          onlyAvailable ?? this.onlyAvailable,
      sort: sort ?? this.sort,
    );
  }
}