import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';
import '../../walker_home/walker_home_controller.dart';
import '../../walker_home/walker_home_state.dart';
import '../models/home_walk.dart';
import '../models/home_walk_status.dart';

class HomeWalkerPanelSection
    extends StatefulWidget {
  // Se conservan temporalmente para no romper
  // la llamada existente desde home_screen.dart.
  final bool available;
  final bool loading;
  final List<HomeWalk> walks;
  final ValueChanged<bool>
      onAvailabilityChanged;

  final ValueChanged<HomeWalk> onWalkTap;
  final ValueChanged<HomeWalk>?
      onWalkDetails;
  final ValueChanged<HomeWalk>? onWalkMap;
  final ValueChanged<HomeWalk>? onWalkChat;
  final VoidCallback onProfileTap;
  final VoidCallback onWalksTap;

  const HomeWalkerPanelSection({
    super.key,
    required this.available,
    required this.loading,
    required this.walks,
    required this.onAvailabilityChanged,
    required this.onWalkTap,
    required this.onProfileTap,
    required this.onWalksTap,
    this.onWalkDetails,
    this.onWalkMap,
    this.onWalkChat,
  });

  @override
  State<HomeWalkerPanelSection> createState() {
    return _HomeWalkerPanelSectionState();
  }
}

class _HomeWalkerPanelSectionState
    extends State<HomeWalkerPanelSection>
    with WidgetsBindingObserver {
  late final WalkerHomeController
      _controller;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(
      this,
    );

    _controller = WalkerHomeController();
    _controller.addListener(
      _handleControllerChange,
    );
    _controller.initialize();
  }

  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state ==
        AppLifecycleState.resumed) {
      _controller.refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(this);

    _controller.removeListener(
      _handleControllerChange,
    );
    _controller.dispose();

    super.dispose();
  }

  Future<void> _changeAvailability(
    bool value,
  ) async {
    final result =
        await _controller.setAvailability(
      value,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      result.message,
      success: result.success,
    );
  }

  Future<void> _acceptRequest(
    HomeWalk walk,
  ) async {
    final confirmed =
        await _confirmAction(
      title: 'Aceptar paseo',
      message:
          '¿Confirmas que puedes realizar el paseo de ${walk.petName} en el horario indicado?',
      confirmLabel: 'Aceptar',
      icon: Icons
          .check_circle_outline_rounded,
      color: const Color(0xFF087D68),
    );

    if (confirmed != true) {
      return;
    }

    final result =
        await _controller.acceptRequest(
      walk,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      result.message,
      success: result.success,
    );
  }

  Future<void> _rejectRequest(
    HomeWalk walk,
  ) async {
    final confirmed =
        await _confirmAction(
      title: 'Rechazar solicitud',
      message:
          'La solicitud desaparecerá de tus pendientes. El dueño recibirá la actualización.',
      confirmLabel: 'Rechazar',
      icon: Icons
          .cancel_outlined,
      color: const Color(0xFFB64238),
      destructive: true,
    );

    if (confirmed != true) {
      return;
    }

    final result =
        await _controller.rejectRequest(
      walk,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      result.message,
      success: result.success,
    );
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
    required Color color,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          icon: Icon(
            icon,
            color: color,
            size: 40,
          ),
          title: Text(title),
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: destructive
                    ? const Color(0xFFB64238)
                    : const Color(0xFF087D68),
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  void _openDetails(HomeWalk walk) {
    final action = widget.onWalkDetails ??
        widget.onWalkTap;

    action(walk);
  }

  void _openMap(HomeWalk walk) {
    final action = widget.onWalkMap ??
        widget.onWalkDetails ??
        widget.onWalkTap;

    action(walk);
  }

  void _openChat(HomeWalk walk) {
    final action = widget.onWalkChat ??
        widget.onWalkDetails ??
        widget.onWalkTap;

    action(walk);
  }

  void _showMessage(
    String message, {
    required bool success,
  }) {
    _controller.clearFeedback();

    final messenger =
        ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          backgroundColor: success
              ? const Color(0xFF087D68)
              : const Color(0xFFB64238),
          content: Row(
            children: [
              Icon(
                success
                    ? Icons
                        .check_circle_rounded
                    : Icons.error_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    if (state.initialLoading) {
      return const _WalkerPanelLoading();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        120,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildTitle(state),
          if (state.error != null) ...[
            const SizedBox(height: 14),
            _buildError(state.error!),
          ],
          const SizedBox(height: 16),
          _buildAvailability(state),
          const SizedBox(height: 18),
          _buildMetrics(state),
          const SizedBox(height: 24),
          _buildOperationalService(state),
          const SizedBox(height: 24),
          _buildPendingRequests(state),
          const SizedBox(height: 24),
          _buildNextService(state),
          const SizedBox(height: 24),
          _buildRecentServices(state),
          const SizedBox(height: 24),
          _buildProfileCard(state),
        ],
      ),
    );
  }

  Widget _buildTitle(
    WalkerHomeState state,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Panel operativo',
                style: DogGoTheme.title(
                  size: 26,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                state.inProgressCount > 0
                    ? 'Tienes un paseo activo. Mantén el seguimiento y las evidencias al día.'
                    : 'Administra solicitudes y servicios desde un solo lugar.',
                style: DogGoTheme.subtitle(
                  size: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Actualizar panel',
          onPressed: state.refreshing
              ? null
              : _controller.refresh,
          style: IconButton.styleFrom(
            backgroundColor:
                DogGoTheme.card,
            foregroundColor:
                DogGoTheme.teal,
            side: const BorderSide(
              color: DogGoTheme.border,
            ),
          ),
          icon: state.refreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.refresh_rounded,
                ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EF),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF0B5B0),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB64238),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF87352F),
                fontSize: 12.5,
                height: 1.35,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            visualDensity:
                VisualDensity.compact,
            onPressed:
                _controller.clearFeedback,
            icon: const Icon(
              Icons.close_rounded,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailability(
    WalkerHomeState state,
  ) {
    final profile = state.profile;
    final available =
        profile?.available ?? false;
    final color = available
        ? const Color(0xFF087D68)
        : const Color(0xFF71747A);
    final background = available
        ? const Color(0xFFE7F4F1)
        : const Color(0xFFF0F2F1);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(23),
        border: Border.all(
          color: color.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 51,
            height: 51,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(17),
            ),
            child: Icon(
              available
                  ? Icons
                      .check_circle_rounded
                  : Icons
                      .pause_circle_rounded,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  available
                      ? 'Disponible para pasear'
                      : 'No disponible',
                  style: DogGoTheme.title(
                    size: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  available
                      ? 'Puedes recibir nuevas solicitudes.'
                      : 'Actívalo cuando estés listo para recibir servicios.',
                  style:
                      DogGoTheme.subtitle(
                    size: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (state.availabilitySaving)
            const SizedBox(
              width: 24,
              height: 24,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2.3,
              ),
            )
          else
            Switch.adaptive(
              value: available,
              activeTrackColor:
                  const Color(0xFF087D68),
              onChanged: profile == null ||
                      state.busy
                  ? null
                  : _changeAvailability,
            ),
        ],
      ),
    );
  }

  Widget _buildMetrics(
    WalkerHomeState state,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen operativo',
          style: DogGoTheme.title(
            size: 19,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 11,
          crossAxisSpacing: 11,
          childAspectRatio: 1.75,
          children: [
            _MetricCard(
              label: 'Solicitudes',
              value: state.pendingCount,
              icon: Icons
                  .mark_email_unread_rounded,
              color:
                  const Color(0xFFE08A1E),
              background:
                  const Color(0xFFFFF4E4),
            ),
            _MetricCard(
              label: 'Confirmados',
              value: state.acceptedCount,
              icon: Icons
                  .event_available_rounded,
              color:
                  const Color(0xFF7554B8),
              background:
                  const Color(0xFFF1ECFA),
            ),
            _MetricCard(
              label: 'En curso',
              value:
                  state.inProgressCount,
              icon: Icons
                  .directions_walk_rounded,
              color:
                  const Color(0xFF087D68),
              background:
                  const Color(0xFFE7F4F1),
            ),
            _MetricCard(
              label: 'Finalizados',
              value:
                  state.completedCount,
              icon: Icons
                  .task_alt_rounded,
              color:
                  const Color(0xFF358451),
              background:
                  const Color(0xFFEAF5ED),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOperationalService(
    WalkerHomeState state,
  ) {
    final active = state.activeWalk;

    if (active == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Paseo en curso',
                style: DogGoTheme.title(
                  size: 20,
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color:
                    const Color(0xFFE7F4F1),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: const Text(
                'ACTIVO',
                style: TextStyle(
                  color:
                      Color(0xFF087D68),
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ActiveWalkCard(
          walk: active,
          onDetails: () {
            _openDetails(active);
          },
          onMap: () {
            _openMap(active);
          },
          onChat: () {
            _openChat(active);
          },
        ),
      ],
    );
  }

  Widget _buildPendingRequests(
    WalkerHomeState state,
  ) {
    final requests =
        state.pendingRequests;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Solicitudes pendientes',
          count: requests.length,
          actionLabel: requests.length > 3
              ? 'Ver todas'
              : null,
          onAction: requests.length > 3
              ? widget.onWalksTap
              : null,
        ),
        const SizedBox(height: 12),
        if (state.walksLoading &&
            requests.isEmpty)
          const _InlineLoading()
        else if (requests.isEmpty)
          const _EmptyOperationalCard(
            icon: Icons
                .inbox_outlined,
            title:
                'No hay solicitudes nuevas',
            subtitle:
                'Las nuevas solicitudes aparecerán aquí para que puedas revisarlas.',
          )
        else
          ...requests.take(3).map(
            (walk) {
              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 11,
                ),
                child: _RequestCard(
                  walk: walk,
                  loading:
                      state.isActingOn(
                    walk,
                  ),
                  onDetails: () {
                    _openDetails(walk);
                  },
                  onAccept: () {
                    _acceptRequest(walk);
                  },
                  onReject: () {
                    _rejectRequest(walk);
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildNextService(
    WalkerHomeState state,
  ) {
    final next =
        state.nextAcceptedWalk;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Siguiente paseo',
          actionLabel: 'Ver agenda',
          onAction: widget.onWalksTap,
        ),
        const SizedBox(height: 12),
        if (next == null)
          const _EmptyOperationalCard(
            icon: Icons
                .event_available_outlined,
            title:
                'Sin paseos confirmados',
            subtitle:
                'Cuando aceptes una solicitud aparecerá aquí como tu siguiente servicio.',
          )
        else
          _NextWalkCard(
            walk: next,
            onDetails: () {
              _openDetails(next);
            },
            onChat: () {
              _openChat(next);
            },
          ),
      ],
    );
  }

  Widget _buildRecentServices(
    WalkerHomeState state,
  ) {
    final completed =
        state.recentCompleted;

    if (completed.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Actividad reciente',
          actionLabel: 'Ver historial',
          onAction: widget.onWalksTap,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: DogGoTheme.card,
            borderRadius:
                BorderRadius.circular(21),
            border: Border.all(
              color: DogGoTheme.border,
            ),
          ),
          child: Column(
            children: [
              for (var index = 0;
                  index < completed.length;
                  index++) ...[
                _CompletedWalkRow(
                  walk: completed[index],
                  onTap: () {
                    _openDetails(
                      completed[index],
                    );
                  },
                ),
                if (index <
                    completed.length - 1)
                  const Divider(
                    height: 1,
                    indent: 67,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(
    WalkerHomeState state,
  ) {
    final profile = state.profile;
    final percentage =
        profile?.completionPercentage ?? 0;

    return Material(
      color: DogGoTheme.card,
      borderRadius:
          BorderRadius.circular(22),
      child: InkWell(
        onTap: widget.onProfileTap,
        borderRadius:
            BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(22),
            border: Border.all(
              color: DogGoTheme.border,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFF1ECFA,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      color:
                          Color(0xFF7554B8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'Perfil profesional',
                          style:
                              DogGoTheme.title(
                            size: 17,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          profile
                                      ?.serviceZone
                                      .isNotEmpty ==
                                  true
                              ? profile!
                                  .serviceZone
                              : 'Completa tu zona de servicio',
                          style: DogGoTheme
                              .subtitle(
                            size: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      color:
                          Color(0xFF7554B8),
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons
                        .chevron_right_rounded,
                    color:
                        Color(0xFFB5B7BA),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                borderRadius:
                    BorderRadius.circular(20),
                backgroundColor:
                    const Color(0xFFF1ECFA),
                valueColor:
                    const AlwaysStoppedAnimation<
                        Color>(
                  Color(0xFF7554B8),
                ),
              ),
              if (profile != null) ...[
                const SizedBox(height: 13),
                Row(
                  children: [
                    _ProfileFact(
                      icon:
                          Icons.star_rounded,
                      text: profile.rating > 0
                          ? profile.rating
                              .toStringAsFixed(
                                1,
                              )
                          : 'Sin nota',
                    ),
                    const SizedBox(width: 16),
                    _ProfileFact(
                      icon: Icons
                          .payments_outlined,
                      text: profile
                                  .hourlyRate >
                              0
                          ? '\$${profile.hourlyRate.toStringAsFixed(0)}/h'
                          : 'Sin tarifa',
                    ),
                    const SizedBox(width: 16),
                    _ProfileFact(
                      icon: Icons
                          .work_history_outlined,
                      text:
                          '${profile.experienceYears} años',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color background;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius:
            BorderRadius.circular(19),
        border: Border.all(
          color: DogGoTheme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: background,
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: DogGoTheme.title(
                    size: 20,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      DogGoTheme.subtitle(
                    size: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveWalkCard
    extends StatelessWidget {
  final HomeWalk walk;
  final VoidCallback onDetails;
  final VoidCallback onMap;
  final VoidCallback onChat;

  const _ActiveWalkCard({
    required this.walk,
    required this.onDetails,
    required this.onMap,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A806A),
            Color(0xFF075F54),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF087D68)
                .withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PetAvatar(
                imageUrl: walk.imageUrl,
                size: 59,
                dark: true,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      walk.petName,
                      style: DogGoTheme.title(
                        size: 21,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      walk.formattedSchedule,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFFD6EEE9),
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ver detalles',
                onPressed: onDetails,
                style: IconButton.styleFrom(
                  foregroundColor:
                      Colors.white,
                  backgroundColor:
                      Colors.white.withValues(
                    alpha: 0.13,
                  ),
                ),
                icon: const Icon(
                  Icons
                      .arrow_forward_rounded,
                ),
              ),
            ],
          ),
          if (walk.pickupAddress.isNotEmpty) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFFD6EEE9),
                  size: 19,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    walk.pickupAddress,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Color(0xFFD6EEE9),
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onMap,
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        Colors.white,
                    foregroundColor:
                        const Color(
                      0xFF087D68,
                    ),
                  ),
                  icon: const Icon(
                    Icons.map_rounded,
                  ),
                  label: const Text(
                    'Recorrido',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: onChat,
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        Colors.white,
                    side: BorderSide(
                      color: Colors.white
                          .withValues(
                        alpha: 0.50,
                      ),
                    ),
                  ),
                  icon: const Icon(
                    Icons.chat_rounded,
                  ),
                  label: const Text('Chat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestCard
    extends StatelessWidget {
  final HomeWalk walk;
  final bool loading;
  final VoidCallback onDetails;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.walk,
    required this.loading,
    required this.onDetails,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius:
            BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFF1D5AE),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap:
                loading ? null : onDetails,
            borderRadius:
                BorderRadius.circular(16),
            child: Row(
              children: [
                _PetAvatar(
                  imageUrl: walk.imageUrl,
                  size: 51,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        walk.petName,
                        style:
                            DogGoTheme.title(
                          size: 16,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        walk.formattedSchedule,
                        style: const TextStyle(
                          color:
                              Color(
                            0xFFE08A1E,
                          ),
                          fontSize: 11.5,
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),
                      if (walk
                          .pickupAddress
                          .isNotEmpty) ...[
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          walk.pickupAddress,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style: DogGoTheme
                              .subtitle(
                            size: 10.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons
                      .chevron_right_rounded,
                  color:
                      Color(0xFFB5B7BA),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 10,
              ),
              child:
                  LinearProgressIndicator(),
            )
          else
            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed: onReject,
                    style: OutlinedButton
                        .styleFrom(
                      foregroundColor:
                          const Color(
                        0xFFB64238,
                      ),
                      side:
                          const BorderSide(
                        color:
                            Color(
                          0xFFE5B5B1,
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                    label: const Text(
                      'Rechazar',
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child:
                      FilledButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(
                      Icons
                          .check_rounded,
                    ),
                    label: const Text(
                      'Aceptar',
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _NextWalkCard
    extends StatelessWidget {
  final HomeWalk walk;
  final VoidCallback onDetails;
  final VoidCallback onChat;

  const _NextWalkCard({
    required this.walk,
    required this.onDetails,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius:
            BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFD9CDEA),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _PetAvatar(
                imageUrl: walk.imageUrl,
                size: 52,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      walk.petName,
                      style: DogGoTheme.title(
                        size: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      walk.formattedSchedule,
                      style: const TextStyle(
                        color:
                            Color(0xFF7554B8),
                        fontSize: 11.5,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    if (walk.pickupAddress
                        .isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        walk.pickupAddress,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: DogGoTheme.subtitle(
                          size: 10.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: onChat,
                  icon: const Icon(
                    Icons.chat_rounded,
                  ),
                  label: const Text('Chat'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child:
                    FilledButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(
                    Icons
                        .play_arrow_rounded,
                  ),
                  label: const Text(
                    'Preparar',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletedWalkRow
    extends StatelessWidget {
  final HomeWalk walk;
  final VoidCallback onTap;

  const _CompletedWalkRow({
    required this.walk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF5ED),
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.task_alt_rounded,
          color: Color(0xFF358451),
        ),
      ),
      title: Text(
        walk.petName,
        style: DogGoTheme.title(
          size: 14,
        ),
      ),
      subtitle: Text(
        walk.formattedSchedule,
        style: DogGoTheme.subtitle(
          size: 10.5,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
      ),
    );
  }
}

class _SectionHeader
    extends StatelessWidget {
  final String title;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.count,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: DogGoTheme.title(
                    size: 20,
                  ),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFE7F4F1,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    '$count',
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF087D68),
                      fontSize: 10.5,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null &&
            onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _EmptyOperationalCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyOperationalCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius:
            BorderRadius.circular(21),
        border: Border.all(
          color: DogGoTheme.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: DogGoTheme.muted,
            size: 38,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: DogGoTheme.title(
              size: 17,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(
              size: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PetAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;
  final bool dark;

  const _PetAvatar({
    required this.imageUrl,
    required this.size,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(
                alpha: 0.14,
              )
            : const Color(0xFFE7F4F1),
        borderRadius:
            BorderRadius.circular(
          size * 0.30,
        ),
      ),
      child: Icon(
        Icons.pets_rounded,
        color: dark
            ? Colors.white
            : const Color(0xFF087D68),
        size: size * 0.46,
      ),
    );

    if (imageUrl.isEmpty) {
      return fallback;
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(
        size * 0.30,
      ),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) => fallback,
      ),
    );
  }
}

class _ProfileFact
    extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ProfileFact({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            color:
                const Color(0xFF7554B8),
            size: 17,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color:
                    Color(0xFF676870),
                fontSize: 10.5,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineLoading
    extends StatelessWidget {
  const _InlineLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius:
            BorderRadius.circular(21),
        border: Border.all(
          color: DogGoTheme.border,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _WalkerPanelLoading
    extends StatelessWidget {
  const _WalkerPanelLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        120,
      ),
      child: Column(
        children: [
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFE4E8E6),
              borderRadius:
                  BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 105,
            decoration: BoxDecoration(
              color: const Color(0xFFE4E8E6),
              borderRadius:
                  BorderRadius.circular(23),
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 11,
            crossAxisSpacing: 11,
            childAspectRatio: 1.75,
            children: List.generate(
              4,
              (_) => Container(
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFE4E8E6,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    19,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFE4E8E6),
              borderRadius:
                  BorderRadius.circular(23),
            ),
          ),
        ],
      ),
    );
  }
}