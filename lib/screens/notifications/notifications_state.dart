import 'models/app_notification.dart';

class NotificationsState {
  final List<AppNotification> notifications;
  final bool loading;
  final bool refreshing;
  final bool markingAll;
  final int? actingNotificationId;
  final bool showUnreadOnly;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.loading = true,
    this.refreshing = false,
    this.markingAll = false,
    this.actingNotificationId,
    this.showUnreadOnly = false,
    this.error,
  });

  bool get busy {
    return markingAll ||
        actingNotificationId != null;
  }

  bool get isEmpty {
    return notifications.isEmpty;
  }

  int get unreadCount {
    return notifications
        .where((notification) {
          return !notification.isRead;
        })
        .length;
  }

  bool get hasUnread {
    return unreadCount > 0;
  }

  List<AppNotification> get visibleNotifications {
    final filtered = showUnreadOnly
        ? notifications
            .where((notification) {
              return !notification.isRead;
            })
            .toList()
        : List<AppNotification>.from(
            notifications,
          );

    filtered.sort((first, second) {
      final firstDate = first.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final secondDate = second.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);

      return secondDate.compareTo(firstDate);
    });

    return filtered;
  }

  Map<AppNotificationGroup,
          List<AppNotification>>
      get groupedNotifications {
    final groups =
        <AppNotificationGroup,
            List<AppNotification>>{
      AppNotificationGroup.today: [],
      AppNotificationGroup.yesterday: [],
      AppNotificationGroup.earlier: [],
    };

    for (final notification
        in visibleNotifications) {
      groups[notification.group]!.add(
        notification,
      );
    }

    return groups;
  }

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? loading,
    bool? refreshing,
    bool? markingAll,
    int? actingNotificationId,
    bool clearActingNotification = false,
    bool? showUnreadOnly,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications:
          notifications ?? this.notifications,
      loading: loading ?? this.loading,
      refreshing:
          refreshing ?? this.refreshing,
      markingAll:
          markingAll ?? this.markingAll,
      actingNotificationId:
          clearActingNotification
              ? null
              : actingNotificationId ??
                  this.actingNotificationId,
      showUnreadOnly:
          showUnreadOnly ??
              this.showUnreadOnly,
      error: clearError
          ? null
          : error ?? this.error,
    );
  }
}