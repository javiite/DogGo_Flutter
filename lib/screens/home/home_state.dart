import 'models/home_activity_item.dart';
import 'models/home_pet.dart';
import 'models/home_summary.dart';
import 'models/home_walk.dart';
import 'models/home_walk_status.dart';

class HomeState {
  final bool initialLoading;
  final bool petsLoading;
  final bool walksLoading;
  final bool notificationsLoading;

  final String userName;
  final String role;
  final String? baseUrl;
  final String? userPhotoUrl;

  final String? petsError;
  final String? walksError;

  final List<HomePet> pets;
  final List<HomeWalk> walks;
  final List<Map<String, dynamic>> notifications;

  const HomeState({
    this.initialLoading = true,
    this.petsLoading = false,
    this.walksLoading = false,
    this.notificationsLoading = false,
    this.userName = 'Usuario',
    this.role = 'Usuario',
    this.baseUrl,
    this.userPhotoUrl,
    this.petsError,
    this.walksError,
    this.pets = const [],
    this.walks = const [],
    this.notifications = const [],
  });

  bool get isWalker {
    final normalized = _normalize(role);

    return normalized == 'paseador';
  }

  bool get isOwner {
    final normalized = _normalize(role);

    return normalized == 'duenio';
  }

  bool get isAdmin {
    final normalized = _normalize(role);

    return normalized == 'admin' || normalized == 'superadmin';
  }

  int get unreadNotifications {
    return notifications.where((notification) {
      final value = firstValue(notification, const ['leida']);

      return !_toBool(value);
    }).length;
  }

  List<HomeActivityItem> get recentActivities {
    final activities = notifications.map(HomeActivityItem.fromMap).toList();

    activities.sort((a, b) {
      final dateA = a.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      final dateB = b.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return dateB.compareTo(dateA);
    });

    return activities.take(4).toList(growable: false);
  }

  List<HomeWalk> get upcomingWalks {
    final now = DateTime.now();

    final result = walks.where((walk) {
      if (!walk.isUpcoming) {
        return false;
      }

      if (walk.status == HomeWalkStatus.inProgress) {
        return true;
      }

      final date = walk.scheduledAt;

      if (date == null) {
        return true;
      }

      return date.isAfter(now.subtract(const Duration(hours: 12)));
    }).toList();

    result.sort((a, b) {
      if (a.status == HomeWalkStatus.inProgress &&
          b.status != HomeWalkStatus.inProgress) {
        return -1;
      }

      if (b.status == HomeWalkStatus.inProgress &&
          a.status != HomeWalkStatus.inProgress) {
        return 1;
      }

      final dateA = a.scheduledAt;
      final dateB = b.scheduledAt;

      if (dateA == null && dateB == null) {
        return 0;
      }

      if (dateA == null) {
        return 1;
      }

      if (dateB == null) {
        return -1;
      }

      return dateA.compareTo(dateB);
    });

    return result;
  }

  HomeWalk? get priorityWalk {
    final routeAlert = routeAlertWalk;

    if (routeAlert != null) {
      return routeAlert;
    }

    const priority = [
      HomeWalkStatus.inProgress,
      HomeWalkStatus.accepted,
      HomeWalkStatus.pending,
      HomeWalkStatus.unknown,
    ];

    final upcoming = upcomingWalks;

    for (final status in priority) {
      for (final walk in upcoming) {
        if (walk.status == status) {
          return walk;
        }
      }
    }

    return upcoming.isEmpty ? null : upcoming.first;
  }

  HomeWalk? get routeAlertWalk {
    for (final walk in upcomingWalks) {
      if (walk.isInProgress && walk.isOutsideAllowedRoute) {
        return walk;
      }
    }

    return null;
  }

  int get activeWalkCount {
    return walks.where((walk) => walk.isInProgress).length;
  }

  int get pendingWalkCount {
    return walks.where((walk) => walk.isPending).length;
  }

  int get confirmedWalkCount {
    return walks.where((walk) => walk.isAccepted).length;
  }

  HomeSummary get weeklySummary {
    return HomeSummary.fromWalks(walks.map((walk) => walk.rawData));
  }

  HomeState copyWith({
    bool? initialLoading,
    bool? petsLoading,
    bool? walksLoading,
    bool? notificationsLoading,
    String? userName,
    String? role,
    String? baseUrl,
    bool clearBaseUrl = false,
    String? userPhotoUrl,
    bool clearUserPhotoUrl = false,
    String? petsError,
    bool clearPetsError = false,
    String? walksError,
    bool clearWalksError = false,
    List<HomePet>? pets,
    List<HomeWalk>? walks,
    List<Map<String, dynamic>>? notifications,
  }) {
    return HomeState(
      initialLoading: initialLoading ?? this.initialLoading,
      petsLoading: petsLoading ?? this.petsLoading,
      walksLoading: walksLoading ?? this.walksLoading,
      notificationsLoading: notificationsLoading ?? this.notificationsLoading,
      userName: userName ?? this.userName,
      role: role ?? this.role,
      baseUrl: clearBaseUrl ? null : baseUrl ?? this.baseUrl,
      userPhotoUrl: clearUserPhotoUrl
          ? null
          : userPhotoUrl ?? this.userPhotoUrl,
      petsError: clearPetsError ? null : petsError ?? this.petsError,
      walksError: clearWalksError ? null : walksError ?? this.walksError,
      pets: pets ?? this.pets,
      walks: walks ?? this.walks,
      notifications: notifications ?? this.notifications,
    );
  }

  static dynamic firstValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) {
        return map[key];
      }
    }

    return null;
  }

  static Map<String, dynamic> safeMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return const {};
  }

  static List<Map<String, dynamic>> normalizeMapList(
    dynamic value, {
    List<String> possibleKeys = const [
      'items',
      'data',
      'result',
      'resultado',
      'paseos',
      'perros',
      'notificaciones',
      'notifications',
    ],
  }) {
    dynamic candidate = value;

    if (candidate is Map) {
      for (final key in possibleKeys) {
        final possibleList = candidate[key];

        if (possibleList is List) {
          candidate = possibleList;
          break;
        }
      }
    }

    if (candidate is! List) {
      return const [];
    }

    return candidate
        .whereType<Map>()
        .map(safeMap)
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized = value?.toString().trim().toLowerCase() ?? '';

    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'si' ||
        normalized == 'sí';
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
