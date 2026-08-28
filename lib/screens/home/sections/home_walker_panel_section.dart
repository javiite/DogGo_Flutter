import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../theme/doggo_theme.dart';
import '../../walker_home/walker_home_controller.dart';
import '../../walker_home/walker_home_state.dart';
import '../../walker_home/widgets/walker_home_priority_card.dart';
import '../../walker_home/widgets/walker_home_requests_section.dart';
import '../../walker_home/widgets/walker_home_summary_section.dart';
import '../models/home_walk.dart';

class HomeWalkerPanelSection extends StatefulWidget {
  // Estos argumentos se conservan porque home_screen.dart ya utiliza este
  // contrato. El panel operativo carga su información con su controlador.
  final bool available;
  final bool loading;
  final List<HomeWalk> walks;
  final ValueChanged<bool> onAvailabilityChanged;
  final ValueChanged<HomeWalk> onWalkTap;
  final ValueChanged<HomeWalk>? onWalkDetails;
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

class _HomeWalkerPanelSectionState extends State<HomeWalkerPanelSection>
    with WidgetsBindingObserver {
  late final WalkerHomeController _controller;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _controller = WalkerHomeController();
    _controller.addListener(_handleControllerChange);
    _controller.initialize();

    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _now = DateTime.now();
      _controller.refresh();
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    super.dispose();
  }

  void _openDetails(HomeWalk walk) {
    final action = widget.onWalkDetails ?? widget.onWalkTap;
    action(walk);
  }

  void _openMap(HomeWalk walk) {
    final action = widget.onWalkMap ?? widget.onWalkDetails ?? widget.onWalkTap;
    action(walk);
  }

  void _openChat(HomeWalk walk) {
    final action =
        widget.onWalkChat ?? widget.onWalkDetails ?? widget.onWalkTap;
    action(walk);
  }

  Future<void> _changeAvailability(bool value) async {
    final result = await _controller.setAvailability(value);

    if (!mounted) {
      return;
    }

    _showMessage(result.message, success: result.success);
  }

  Future<void> _acceptRequest(HomeWalk walk) async {
    final confirmed = await _confirmAction(
      title: 'Aceptar paseo',
      message:
          '¿Confirmas que puedes realizar el paseo de ${walk.petName} en el horario indicado?',
      confirmLabel: 'Aceptar solicitud',
      icon: Icons.check_circle_outline_rounded,
      color: const Color(0xFF087D68),
    );

    if (confirmed != true) {
      return;
    }

    final result = await _controller.acceptRequest(walk);

    if (mounted) {
      _showMessage(result.message, success: result.success);
    }
  }

  Future<void> _rejectRequest(HomeWalk walk) async {
    final confirmed = await _confirmAction(
      title: 'Rechazar solicitud',
      message:
          'La solicitud desaparecerá de tus pendientes y el dueño recibirá la actualización.',
      confirmLabel: 'Rechazar',
      icon: Icons.cancel_outlined,
      color: const Color(0xFFB64238),
      destructive: true,
    );

    if (confirmed != true) {
      return;
    }

    final result = await _controller.rejectRequest(walk);

    if (mounted) {
      _showMessage(result.message, success: result.success);
    }
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
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Icon(icon, color: color, size: 40),
          title: Text(title, textAlign: TextAlign.center),
          content: Text(message, textAlign: TextAlign.center),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: destructive
                    ? const Color(0xFFB64238)
                    : const Color(0xFF087D68),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message, {required bool success}) {
    _controller.clearFeedback();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: success
              ? const Color(0xFF087D68)
              : const Color(0xFFB64238),
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_rounded : Icons.error_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 11),
              Expanded(child: Text(message)),
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
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            state: state,
            onRefresh: state.refreshing ? null : _controller.refresh,
          ),
          if (state.error != null) ...[
            const SizedBox(height: 14),
            _ErrorBanner(message: state.error!, onRetry: _controller.refresh),
          ],
          const SizedBox(height: 18),
          WalkerHomePriorityCard(
            walk: state.priorityWalk,
            pendingCount: state.pendingCount,
            now: _now,
            onDetails: _openDetails,
            onMap: _openMap,
            onChat: _openChat,
            onViewRequests: widget.onWalksTap,
            onViewWalks: widget.onWalksTap,
          ),
          if (state.pendingRequests.isNotEmpty) ...[
            const SizedBox(height: 25),
            WalkerHomeRequestsSection(
              requests: state.pendingRequests,
              isActingOn: state.isActingOn,
              onDetails: _openDetails,
              onAccept: _acceptRequest,
              onReject: _rejectRequest,
              onSeeAll: widget.onWalksTap,
            ),
          ],
          const SizedBox(height: 25),
          WalkerHomeSummarySection(
            profile: state.profile,
            savingAvailability: state.availabilitySaving,
            activeCount: state.inProgressCount,
            scheduledCount: state.scheduledCount,
            pendingCount: state.pendingCount,
            completedCount: state.completedCount,
            onAvailabilityChanged: _changeAvailability,
            onProfileTap: widget.onProfileTap,
            onWalksTap: widget.onWalksTap,
          ),
          const SizedBox(height: 14),
          _AvailabilityShortcut(
            available: state.profile?.available ?? false,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.availability,
            ).then((_) => _controller.refresh()),
          ),
          if (state.recentCompleted.isNotEmpty) ...[
            const SizedBox(height: 27),
            _RecentServicesSection(
              walks: state.recentCompleted,
              onTap: _openDetails,
              onSeeAll: widget.onWalksTap,
            ),
          ],
        ],
      ),
    );
  }
}

class _AvailabilityShortcut extends StatelessWidget {
  final bool available;
  final VoidCallback onTap;

  const _AvailabilityShortcut({required this.available, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: DogGoTheme.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: DogGoTheme.tealLight,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: DogGoTheme.teal,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Horarios y disponibilidad',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      available
                          ? 'Disponible · administra tu semana'
                          : 'Pausada · revisa tu agenda',
                      style: const TextStyle(
                        color: DogGoTheme.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final WalkerHomeState state;
  final VoidCallback? onRefresh;

  const _PanelHeader({required this.state, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.activeWalk != null
                    ? 'Tu paseo está activo'
                    : state.nextAcceptedWalk != null
                    ? 'Tu jornada DogGo'
                    : 'Panel del paseador',
                style: DogGoTheme.title(size: 27),
              ),
              const SizedBox(height: 5),
              Text(
                state.activeWalk != null
                    ? 'Mantén el seguimiento activo y revisa el recorrido.'
                    : state.hasImmediateWork
                    ? 'Lo más importante aparece primero.'
                    : 'Organiza tu disponibilidad y próximos servicios.',
                style: DogGoTheme.subtitle(size: 12.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Actualizar panel',
          onPressed: onRefresh,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: DogGoTheme.teal,
            side: const BorderSide(color: DogGoTheme.border),
          ),
          icon: state.refreshing
              ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0B5B0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB64238)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF87352F),
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _RecentServicesSection extends StatelessWidget {
  final List<HomeWalk> walks;
  final ValueChanged<HomeWalk> onTap;
  final VoidCallback onSeeAll;

  const _RecentServicesSection({
    required this.walks,
    required this.onTap,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Actividad reciente',
                style: TextStyle(
                  color: Color(0xFF20212B),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(onPressed: onSeeAll, child: const Text('Historial')),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: const Color(0xFFE0E2E1)),
          ),
          child: Column(
            children: [
              for (var index = 0; index < walks.length; index++) ...[
                ListTile(
                  onTap: () => onTap(walks[index]),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5ED),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.task_alt_rounded,
                      color: Color(0xFF358451),
                    ),
                  ),
                  title: Text(
                    walks[index].petName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${walks[index].formattedSchedule} · ${walks[index].ownerDisplayName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
                if (index < walks.length - 1)
                  const Divider(height: 1, indent: 70),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WalkerPanelLoading extends StatelessWidget {
  const _WalkerPanelLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
      child: Column(
        children: [
          _skeleton(68),
          const SizedBox(height: 18),
          _skeleton(290),
          const SizedBox(height: 18),
          _skeleton(110),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(child: _skeleton(80)),
              const SizedBox(width: 10),
              Expanded(child: _skeleton(80)),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _skeleton(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE4E8E6),
        borderRadius: BorderRadius.circular(23),
      ),
    );
  }
}
