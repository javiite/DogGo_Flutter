import '../home/models/home_walk.dart';
import '../home/models/home_walk_status.dart';
import 'models/walker_home_profile.dart';

class WalkerHomeState {
  final bool initialLoading;
  final bool refreshing;
  final bool profileLoading;
  final bool walksLoading;
  final bool availabilitySaving;
  final int? actingWalkId;
  final String? baseUrl;
  final WalkerHomeProfile? profile;
  final List<HomeWalk> walks;
  final String? error;
  final String? message;

  const WalkerHomeState({
    this.initialLoading = true,
    this.refreshing = false,
    this.profileLoading = false,
    this.walksLoading = false,
    this.availabilitySaving = false,
    this.actingWalkId,
    this.baseUrl,
    this.profile,
    this.walks = const [],
    this.error,
    this.message,
  });

  bool get busy {
    return availabilitySaving ||
        actingWalkId != null;
  }

  bool get available {
    return profile?.available ?? false;
  }

  int get pendingCount {
    return walks
        .where(
          (walk) =>
              walk.status ==
              HomeWalkStatus.pending,
        )
        .length;
  }

  int get acceptedCount {
    return walks
        .where(
          (walk) =>
              walk.status ==
              HomeWalkStatus.accepted,
        )
        .length;
  }

  int get inProgressCount {
    return walks
        .where(
          (walk) =>
              walk.status ==
              HomeWalkStatus.inProgress,
        )
        .length;
  }

  int get completedCount {
    return walks
        .where(
          (walk) =>
              walk.status ==
              HomeWalkStatus.completed,
        )
        .length;
  }

  List<HomeWalk> get pendingRequests {
    final result = walks
        .where(
          (walk) =>
              walk.status ==
              HomeWalkStatus.pending,
        )
        .toList();

    result.sort(_sortByDate);

    return result;
  }

  List<HomeWalk> get operationalWalks {
    final result = walks.where((walk) {
      return walk.status ==
              HomeWalkStatus.inProgress ||
          walk.status ==
              HomeWalkStatus.accepted;
    }).toList();

    result.sort((first, second) {
      if (first.status ==
          HomeWalkStatus.inProgress) {
        return -1;
      }

      if (second.status ==
          HomeWalkStatus.inProgress) {
        return 1;
      }

      return _sortByDate(
        first,
        second,
      );
    });

    return result;
  }

  List<HomeWalk> get recentCompleted {
    final result = walks
        .where(
          (walk) =>
              walk.status ==
              HomeWalkStatus.completed,
        )
        .toList();

    result.sort((first, second) {
      final firstDate =
          first.finishedAt ??
              first.scheduledAt ??
              DateTime
                  .fromMillisecondsSinceEpoch(
                0,
              );

      final secondDate =
          second.finishedAt ??
              second.scheduledAt ??
              DateTime
                  .fromMillisecondsSinceEpoch(
                0,
              );

      return secondDate.compareTo(
        firstDate,
      );
    });

    return result.take(3).toList();
  }

  HomeWalk? get activeWalk {
    for (final walk in operationalWalks) {
      if (walk.status ==
          HomeWalkStatus.inProgress) {
        return walk;
      }
    }

    return null;
  }

  HomeWalk? get nextAcceptedWalk {
    for (final walk in operationalWalks) {
      if (walk.status ==
          HomeWalkStatus.accepted) {
        return walk;
      }
    }

    return null;
  }

  bool isActingOn(HomeWalk walk) {
    return walk.id != null &&
        actingWalkId == walk.id;
  }

  WalkerHomeState copyWith({
    bool? initialLoading,
    bool? refreshing,
    bool? profileLoading,
    bool? walksLoading,
    bool? availabilitySaving,
    int? actingWalkId,
    bool clearActingWalk = false,
    String? baseUrl,
    WalkerHomeProfile? profile,
    bool clearProfile = false,
    List<HomeWalk>? walks,
    String? error,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
  }) {
    return WalkerHomeState(
      initialLoading:
          initialLoading ??
              this.initialLoading,
      refreshing:
          refreshing ?? this.refreshing,
      profileLoading:
          profileLoading ??
              this.profileLoading,
      walksLoading:
          walksLoading ??
              this.walksLoading,
      availabilitySaving:
          availabilitySaving ??
              this.availabilitySaving,
      actingWalkId: clearActingWalk
          ? null
          : actingWalkId ??
              this.actingWalkId,
      baseUrl: baseUrl ?? this.baseUrl,
      profile: clearProfile
          ? null
          : profile ?? this.profile,
      walks: walks ?? this.walks,
      error: clearError
          ? null
          : error ?? this.error,
      message: clearMessage
          ? null
          : message ?? this.message,
    );
  }

  static int _sortByDate(
    HomeWalk first,
    HomeWalk second,
  ) {
    final firstDate =
        first.scheduledAt ??
            DateTime
                .fromMillisecondsSinceEpoch(
              0,
            );

    final secondDate =
        second.scheduledAt ??
            DateTime
                .fromMillisecondsSinceEpoch(
              0,
            );

    return firstDate.compareTo(
      secondDate,
    );
  }
}