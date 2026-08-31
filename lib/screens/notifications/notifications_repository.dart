import '../../services/notificaciones_service.dart';
import 'models/app_notification.dart';

class NotificationsRepository {
  final NotificacionesService _service;

  NotificationsRepository({NotificacionesService? service})
    : _service = service ?? NotificacionesService();

  Future<List<AppNotification>> getAll() async {
    final response = await _service.obtenerNotificaciones();
    final notifications = response.map(AppNotification.fromJson).toList();

    notifications.sort((first, second) {
      final firstDate =
          first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final secondDate =
          second.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return secondDate.compareTo(firstDate);
    });

    return notifications;
  }

  Future<void> markAsRead(int notificationId) {
    return _service.marcarComoLeida(notificationId);
  }

  Future<void> markAllAsRead() {
    return _service.marcarTodasComoLeidas();
  }
}
