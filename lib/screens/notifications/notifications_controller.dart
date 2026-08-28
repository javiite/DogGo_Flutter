import 'package:flutter/foundation.dart';

import '../../services/notificaciones_service.dart';
import 'models/app_notification.dart';
import 'notifications_state.dart';

class NotificationsController extends ChangeNotifier {
  final NotificacionesService _service;

  NotificationsState _state = const NotificationsState();

  bool _disposed = false;
  bool _loadInProgress = false;

  NotificationsController({NotificacionesService? service})
    : _service = service ?? NotificacionesService();

  NotificationsState get state => _state;

  Future<void> initialize() async {
    await _load(initialLoad: true);
  }

  Future<void> refresh() async {
    await _load(initialLoad: false);
  }

  Future<void> _load({required bool initialLoad}) async {
    if (_loadInProgress) {
      return;
    }

    _loadInProgress = true;

    _setState(
      _state.copyWith(
        loading: initialLoad && _state.notifications.isEmpty,
        refreshing: !initialLoad,
        clearError: true,
      ),
    );

    try {
      final response = await _service.obtenerNotificaciones();

      final notifications = response.map(AppNotification.fromJson).toList();

      notifications.sort((first, second) {
        final firstDate =
            first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final secondDate =
            second.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return secondDate.compareTo(firstDate);
      });

      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          notifications: notifications,
          loading: false,
          refreshing: false,
          clearError: true,
        ),
      );
    } catch (error) {
      if (_disposed) {
        return;
      }

      _setState(
        _state.copyWith(
          loading: false,
          refreshing: false,
          error: _cleanError(error),
        ),
      );
    } finally {
      _loadInProgress = false;
    }
  }

  void toggleUnreadFilter() {
    if (_state.loading || _state.busy) {
      return;
    }

    _setState(_state.copyWith(showUnreadOnly: !_state.showUnreadOnly));
  }

  Future<void> markAsRead(AppNotification notification) async {
    final id = notification.id;

    if (id == null || notification.isRead || _state.busy) {
      return;
    }

    _setState(_state.copyWith(actingNotificationId: id, clearError: true));

    try {
      await _service.marcarComoLeida(id);

      if (_disposed) {
        return;
      }

      _replaceNotification(notification.copyWith(isRead: true));
    } catch (error) {
      if (!_disposed) {
        _setState(_state.copyWith(error: _cleanError(error)));
      }
    } finally {
      if (!_disposed) {
        _setState(_state.copyWith(clearActingNotification: true));
      }
    }
  }

  Future<void> markAllAsRead() async {
    if (!_state.hasUnread || _state.busy) {
      return;
    }

    final unread = _state.notifications.where((notification) {
      return !notification.isRead && notification.id != null;
    }).toList();

    if (unread.isEmpty) {
      return;
    }

    _setState(_state.copyWith(markingAll: true, clearError: true));

    try {
      await _service.marcarTodasComoLeidas();

      if (_disposed) {
        return;
      }

      final updated = _state.notifications.map((notification) {
        if (!notification.isRead && notification.id != null) {
          return notification.copyWith(isRead: true);
        }

        return notification;
      }).toList();

      _setState(
        _state.copyWith(
          notifications: updated,
          markingAll: false,
          clearError: true,
        ),
      );
    } catch (error) {
      if (!_disposed) {
        _setState(
          _state.copyWith(markingAll: false, error: _cleanError(error)),
        );
      }
    } finally {
      if (!_disposed && _state.markingAll) {
        _setState(_state.copyWith(markingAll: false));
      }
    }
  }

  void clearError() {
    if (_state.error == null) {
      return;
    }

    _setState(_state.copyWith(clearError: true));
  }

  void _replaceNotification(AppNotification updated) {
    final notifications = _state.notifications.map((current) {
      if (current.id != null && current.id == updated.id) {
        return updated;
      }

      return current;
    }).toList();

    _setState(_state.copyWith(notifications: notifications, clearError: true));
  }

  String _cleanError(Object error) {
    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '')
        .trim();

    return message.isEmpty
        ? 'No se pudieron cargar las notificaciones.'
        : message;
  }

  void _setState(NotificationsState newState) {
    if (_disposed) {
      return;
    }

    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
