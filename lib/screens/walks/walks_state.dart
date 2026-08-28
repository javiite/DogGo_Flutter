import '../home/models/home_walk.dart';
import '../home/models/home_walk_status.dart';

class WalksState {
  final bool loading;
  final String? error;
  final String? baseUrl;
  final String role;
  final List<HomeWalk> walks;
  final HomeWalkStatus? selectedStatus;
  final String searchQuery;
  final int? actionWalkId;

  const WalksState({
    this.loading = true,
    this.error,
    this.baseUrl,
    this.role = '',
    this.walks = const [],
    this.selectedStatus,
    this.searchQuery = '',
    this.actionWalkId,
  });

  bool get isOwner {
    final value = _normalize(role);

    return value == 'dueno' ||
        value == 'duenio' ||
        value == 'owner' ||
        value == 'cliente';
  }

  bool get isWalker {
    final value = _normalize(role);

    return value == 'paseador' || value == 'walker' || value == 'dogwalker';
  }

  bool get isEmpty => !loading && walks.isEmpty;

  bool get hasWalks => walks.isNotEmpty;

  bool get actionInProgress => actionWalkId != null;

  HomeWalk? get activeWalk {
    for (final walk in walks) {
      if (walk.status == HomeWalkStatus.inProgress) {
        return walk;
      }
    }

    return null;
  }

  List<HomeWalk> get filteredWalks {
    final query = searchQuery.trim().toLowerCase();

    final result = walks.where((walk) {
      if (selectedStatus != null && walk.status != selectedStatus) {
        return false;
      }

      if (query.isEmpty) return true;

      final searchableText = [
        walk.petName,
        walk.walkerName,
        walk.status.label,
        walk.pickupAddress,
        walk.notes,
        walk.formattedSchedule,
      ].join(' ').toLowerCase();

      return searchableText.contains(query);
    }).toList();

    result.sort((first, second) {
      final firstActive =
          first.status == HomeWalkStatus.pending ||
          first.status == HomeWalkStatus.accepted ||
          first.status == HomeWalkStatus.inProgress;

      final secondActive =
          second.status == HomeWalkStatus.pending ||
          second.status == HomeWalkStatus.accepted ||
          second.status == HomeWalkStatus.inProgress;

      if (firstActive != secondActive) {
        return firstActive ? -1 : 1;
      }

      final statusComparison = _statusPriority(
        first.status,
      ).compareTo(_statusPriority(second.status));
      if (statusComparison != 0) {
        return statusComparison;
      }

      final firstDate = first.scheduledAt;
      final secondDate = second.scheduledAt;

      if (firstDate == null && secondDate == null) {
        return 0;
      }

      if (firstDate == null) return 1;
      if (secondDate == null) return -1;

      if (firstActive) {
        return firstDate.compareTo(secondDate);
      }

      return secondDate.compareTo(firstDate);
    });

    return List<HomeWalk>.unmodifiable(result);
  }

  int countByStatus(HomeWalkStatus status) {
    return walks.where((walk) => walk.status == status).length;
  }

  bool isActionRunningFor(HomeWalk walk) {
    return walk.id != null && actionWalkId == walk.id;
  }

  bool canAccept(HomeWalk walk) {
    return isWalker && walk.status == HomeWalkStatus.pending;
  }

  bool canReject(HomeWalk walk) {
    return isWalker && walk.status == HomeWalkStatus.pending;
  }

  bool canStart(HomeWalk walk) {
    return isWalker && walk.status == HomeWalkStatus.accepted;
  }

  bool canFinish(HomeWalk walk) {
    return isWalker && walk.status == HomeWalkStatus.inProgress;
  }

  bool canCancel(HomeWalk walk) {
    if (!isOwner && !isWalker) return false;

    if (walk.status != HomeWalkStatus.pending &&
        walk.status != HomeWalkStatus.accepted) {
      return false;
    }

    final scheduledAt = walk.scheduledAt;
    return scheduledAt == null || scheduledAt.isAfter(DateTime.now());
  }

  static int _statusPriority(HomeWalkStatus status) => switch (status) {
    HomeWalkStatus.inProgress => 0,
    HomeWalkStatus.pending => 1,
    HomeWalkStatus.accepted => 2,
    HomeWalkStatus.completed => 3,
    HomeWalkStatus.cancelled => 4,
    HomeWalkStatus.rejected => 5,
    HomeWalkStatus.none || HomeWalkStatus.unknown => 6,
  };

  WalksState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    String? baseUrl,
    String? role,
    List<HomeWalk>? walks,
    HomeWalkStatus? selectedStatus,
    bool clearSelectedStatus = false,
    String? searchQuery,
    int? actionWalkId,
    bool clearActionWalk = false,
  }) {
    return WalksState(
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      baseUrl: baseUrl ?? this.baseUrl,
      role: role ?? this.role,
      walks: walks ?? this.walks,
      selectedStatus: clearSelectedStatus
          ? null
          : selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      actionWalkId: clearActionWalk ? null : actionWalkId ?? this.actionWalkId,
    );
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[\s_\-]'), '');
  }
}
