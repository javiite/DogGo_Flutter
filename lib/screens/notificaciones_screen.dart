import 'package:flutter/material.dart';

import 'chat_paseo_screen.dart';
import 'detalle_paseo_screen.dart';
import 'mis_paseos_screen.dart';
import 'programacion_paseos_screen.dart';
import 'notifications/models/app_notification.dart';
import 'notifications/notifications_controller.dart';
import 'notifications/notifications_state.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() {
    return _NotificacionesScreenState();
  }
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  late final NotificationsController _controller;

  bool _openingNotification = false;

  @override
  void initState() {
    super.initState();

    _controller = NotificationsController();

    _controller.addListener(_handleControllerChange);

    _controller.initialize();
  }

  void _handleControllerChange() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);

    _controller.dispose();

    super.dispose();
  }

  Future<void> _openNotification(AppNotification notification) async {
    if (_openingNotification || _controller.state.busy) {
      return;
    }

    _openingNotification = true;

    try {
      if (!notification.isRead) {
        await _controller.markAsRead(notification);
      }

      if (!mounted) {
        return;
      }

      final referenceId = notification.referenceId;

      if (notification.opensProgram && referenceId != null) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) =>
                ProgramacionPaseosScreen(programacionId: referenceId),
          ),
        );
      } else if (notification.opensRouteMap &&
          referenceId != null &&
          referenceId > 0) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) =>
                DetallePaseoScreen(paseoId: referenceId, openMapOnLoad: true),
          ),
        );
      } else if (notification.opensChat &&
          referenceId != null &&
          referenceId > 0) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ChatPaseoScreen(
              paseoId: referenceId,
              nombrePerro: notification.dogName,
              nombreOtroUsuario: notification.otherUserName,
            ),
          ),
        );
      } else if (notification.opensWalks &&
          referenceId != null &&
          referenceId > 0) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => DetallePaseoScreen(paseoId: referenceId),
          ),
        );
      } else if (notification.opensWalks) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const MisPaseosScreen()),
        );
      }

      if (mounted) {
        await _controller.refresh();
      }
    } finally {
      _openingNotification = false;
    }
  }

  Future<void> _markAllAsRead() async {
    final state = _controller.state;

    if (!state.hasUnread || state.busy) {
      return;
    }

    await _controller.markAllAsRead();

    if (!mounted) {
      return;
    }

    if (_controller.state.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Todas las notificaciones quedaron marcadas como leídas.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF20212D),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: state.refreshing ? null : _controller.refresh,
            icon: state.refreshing
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            enabled: !state.busy,
            onSelected: (value) {
              if (value == 'mark_all') {
                _markAllAsRead();
              }
            },
            itemBuilder: (_) {
              return [
                PopupMenuItem<String>(
                  value: 'mark_all',
                  enabled: state.hasUnread,
                  child: const Row(
                    children: [
                      Icon(Icons.done_all_rounded, size: 21),
                      SizedBox(width: 11),
                      Text('Marcar todas como leídas'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: SafeArea(top: false, child: _buildBody(state)),
    );
  }

  Widget _buildBody(NotificationsState state) {
    if (state.loading && state.notifications.isEmpty) {
      return const _NotificationsLoading();
    }

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      color: const Color(0xFF087D68),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildSummary(state)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildFilters(state)),
          ),
          if (state.error != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(child: _buildError(state.error!)),
            ),
          if (state.markingAll)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: LinearProgressIndicator(
                  minHeight: 3,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
          if (state.visibleNotifications.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(state),
            )
          else
            ..._buildNotificationGroups(state),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildSummary(NotificationsState state) {
    final unreadCount = state.unreadCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A806A), Color(0xFF075F54)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF087D68).withValues(alpha: .20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 31,
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 23,
                        minHeight: 23,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFC447),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Color(0xFF20212D),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unreadCount == 0
                      ? 'Todo al día'
                      : '$unreadCount pendiente'
                            '${unreadCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  unreadCount == 0
                      ? 'No tienes avisos nuevos por revisar.'
                      : 'Revisa las novedades de tus paseos y mensajes.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .86),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (state.hasUnread)
            IconButton(
              tooltip: 'Marcar todas como leídas',
              onPressed: state.busy ? null : _markAllAsRead,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: .14),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.done_all_rounded),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters(NotificationsState state) {
    return Row(
      children: [
        Expanded(
          child: _NotificationFilter(
            label: 'Todas',
            count: state.notifications.length,
            selected: !state.showUnreadOnly,
            onTap: state.showUnreadOnly ? _controller.toggleUnreadFilter : null,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: _NotificationFilter(
            label: 'Pendientes',
            count: state.unreadCount,
            selected: state.showUnreadOnly,
            onTap: !state.showUnreadOnly
                ? _controller.toggleUnreadFilter
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFF4B8B2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB73E35)),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF8E312A),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            visualDensity: VisualDensity.compact,
            onPressed: _controller.clearError,
            icon: const Icon(Icons.close_rounded, size: 19),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNotificationGroups(NotificationsState state) {
    final groups = state.groupedNotifications;

    final widgets = <Widget>[];

    for (final group in AppNotificationGroup.values) {
      final notifications = groups[group] ?? const [];

      if (notifications.isEmpty) {
        continue;
      }

      widgets.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  _groupTitle(group),
                  style: const TextStyle(
                    color: Color(0xFF20212D),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${notifications.length}',
                    style: const TextStyle(
                      color: Color(0xFF087D68),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      widgets.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) {
              return const SizedBox(height: 11);
            },
            itemBuilder: (_, index) {
              final notification = notifications[index];

              return _NotificationCard(
                notification: notification,
                loading: state.actingNotificationId == notification.id,
                onTap: () {
                  _openNotification(notification);
                },
                onMarkAsRead: notification.isRead
                    ? null
                    : () {
                        _controller.markAsRead(notification);
                      },
              );
            },
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildEmptyState(NotificationsState state) {
    final filtered = state.showUnreadOnly;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 50, 28, 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F3F0),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              filtered
                  ? Icons.done_all_rounded
                  : Icons.notifications_none_rounded,
              color: const Color(0xFF087D68),
              size: 42,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            filtered ? 'No tienes pendientes' : 'Sin notificaciones',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF20212D),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            filtered
                ? 'Ya revisaste todas tus notificaciones.'
                : 'Aquí aparecerán avisos sobre paseos, mensajes, evidencias y cambios importantes.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF73747D),
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (filtered) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _controller.toggleUnreadFilter,
              icon: const Icon(Icons.notifications_rounded),
              label: const Text('Ver todas'),
            ),
          ],
        ],
      ),
    );
  }

  String _groupTitle(AppNotificationGroup group) {
    switch (group) {
      case AppNotificationGroup.today:
        return 'Hoy';
      case AppNotificationGroup.yesterday:
        return 'Ayer';
      case AppNotificationGroup.earlier:
        return 'Anteriores';
    }
  }
}

class _NotificationFilter extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback? onTap;

  const _NotificationFilter({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF087D68) : Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected
                  ? const Color(0xFF087D68)
                  : const Color(0xFFE3E5E4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF5D5E67),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                constraints: const BoxConstraints(minWidth: 24),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: .18)
                      : const Color(0xFFF0F2F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF087D68),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final bool loading;
  final VoidCallback onTap;
  final VoidCallback? onMarkAsRead;

  const _NotificationCard({
    required this.notification,
    required this.loading,
    required this.onTap,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(notification.category);

    final icon = _categoryIcon(notification.category);

    return Material(
      color: notification.isRead ? Colors.white : color.withValues(alpha: .065),
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: loading ? null : onTap,
        onLongPress: loading ? null : onMarkAsRead,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: notification.isRead
                  ? const Color(0xFFE7E9E8)
                  : color.withValues(alpha: .25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 25),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: const Color(0xFF20212D),
                              fontSize: 14.5,
                              height: 1.2,
                              fontWeight: notification.isRead
                                  ? FontWeight.w700
                                  : FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (loading)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: color,
                            ),
                          )
                        else if (!notification.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        color: Color(0xFF696A73),
                        fontSize: 12.5,
                        height: 1.38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _categoryLabel(notification.category),
                            style: TextStyle(
                              color: color,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (notification.formattedDate.isNotEmpty)
                          Expanded(
                            child: Text(
                              notification.formattedDate,
                              style: const TextStyle(
                                color: Color(0xFF96979E),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (notification.opensChat || notification.opensWalks)
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: color,
                            size: 18,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _categoryIcon(AppNotificationCategory category) {
    switch (category) {
      case AppNotificationCategory.walk:
        return Icons.route_rounded;
      case AppNotificationCategory.request:
        return Icons.assignment_rounded;
      case AppNotificationCategory.message:
        return Icons.chat_rounded;
      case AppNotificationCategory.cancelled:
        return Icons.cancel_rounded;
      case AppNotificationCategory.profile:
        return Icons.person_rounded;
      case AppNotificationCategory.rating:
        return Icons.star_rounded;
      case AppNotificationCategory.evidence:
        return Icons.photo_camera_rounded;
      case AppNotificationCategory.general:
        return Icons.notifications_rounded;
    }
  }

  static Color _categoryColor(AppNotificationCategory category) {
    switch (category) {
      case AppNotificationCategory.walk:
        return const Color(0xFF087D68);
      case AppNotificationCategory.request:
        return const Color(0xFFE08A1E);
      case AppNotificationCategory.message:
        return const Color(0xFF3478D4);
      case AppNotificationCategory.cancelled:
        return const Color(0xFFC94D43);
      case AppNotificationCategory.profile:
        return const Color(0xFF7554B8);
      case AppNotificationCategory.rating:
        return const Color(0xFFD49A11);
      case AppNotificationCategory.evidence:
        return const Color(0xFF1685A5);
      case AppNotificationCategory.general:
        return const Color(0xFF697078);
    }
  }

  static String _categoryLabel(AppNotificationCategory category) {
    switch (category) {
      case AppNotificationCategory.walk:
        return 'Paseo';
      case AppNotificationCategory.request:
        return 'Solicitud';
      case AppNotificationCategory.message:
        return 'Mensaje';
      case AppNotificationCategory.cancelled:
        return 'Cancelación';
      case AppNotificationCategory.profile:
        return 'Perfil';
      case AppNotificationCategory.rating:
        return 'Calificación';
      case AppNotificationCategory.evidence:
        return 'Evidencia';
      case AppNotificationCategory.general:
        return 'General';
    }
  }
}

class _NotificationsLoading extends StatelessWidget {
  const _NotificationsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E9E7),
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E9E7),
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E9E7),
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        ...List.generate(4, (index) {
          return Container(
            height: 116,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E9E7),
              borderRadius: BorderRadius.circular(21),
            ),
          );
        }),
      ],
    );
  }
}
