import 'package:flutter/material.dart';

import '../shared/widgets/doggo_error_view.dart';
import '../shared/widgets/doggo_loading_view.dart';
import '../shared/widgets/doggo_network_image.dart';
import '../shared/widgets/doggo_screen_scaffold.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import '../widgets/doggo_map_preview.dart';
import 'calificar_paseo_screen.dart';
import 'chat_paseo_screen.dart';
import 'evidencia_paseo_screen.dart';
import 'home/models/home_walk_status.dart';
import 'mapa_paseo_screen.dart';
import 'tracking_paseo_screen.dart';
import 'crear_paseo_screen.dart';
import '../services/paseadores_service.dart';
import 'walks/models/walk_detail.dart';
import 'walks/models/pickup_location.dart';
import 'walks/models/walk_request_draft.dart';
import 'walks/walk_safety_center_screen.dart';
import 'walks/walk_detail_controller.dart';
import 'walks/walk_detail_state.dart';
import 'walks/widgets/walk_pets_section.dart';
import 'walks/widgets/walk_action_dialogs.dart';
import 'package:latlong2/latlong.dart';
import 'walks/widgets/walk_route_management_card.dart';
import 'advanced/walk_planning_screen.dart';
import 'public_owner_profile_screen.dart';

class DetallePaseoScreen extends StatefulWidget {
  final int? id;
  final int? paseoId;
  final Map<String, dynamic>? paseo;
  final String? rol;
  final VoidCallback? onPaseoActualizado;
  final bool openMapOnLoad;

  const DetallePaseoScreen({
    super.key,
    this.id,
    this.paseoId,
    this.paseo,
    this.rol,
    this.onPaseoActualizado,
    this.openMapOnLoad = false,
  });

  @override
  State<DetallePaseoScreen> createState() => _DetallePaseoScreenState();
}

class _DetallePaseoScreenState extends State<DetallePaseoScreen> {
  late final WalkDetailController _controller;
  bool _automaticMapOpened = false;

  @override
  void initState() {
    super.initState();

    _controller = WalkDetailController(
      id: widget.id,
      walkId: widget.paseoId,
      initialWalk: widget.paseo,
      role: widget.rol,
    );

    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _performAction(
    WalkDetailAction action, {
    String cancellationReason = '',
  }) async {
    final result = await _controller.perform(
      action,
      cancellationReason: cancellationReason,
    );

    if (!mounted) {
      return;
    }

    if (result.code == WalkDetailResultCode.finalEvidenceRequired) {
      final upload = await _confirmDialog(
        title: 'Evidencia final requerida',
        message:
            'Antes de finalizar el paseo debes registrar una fotografía de entrega.',
        confirmText: 'Subir evidencia',
        icon: Icons.photo_camera_outlined,
      );

      if (upload == true) {
        await _openEvidence('fin');
      }

      return;
    }

    _showMessage(result.message, success: result.success);

    if (result.success) {
      widget.onPaseoActualizado?.call();
    }
  }

  Future<void> _acceptWalk() async {
    final confirmed = await _confirmDialog(
      title: 'Aceptar paseo',
      message:
          'Confirma que puedes realizar el servicio en la fecha, horario y ubicación indicados.',
      confirmText: 'Aceptar solicitud',
      icon: Icons.check_circle_outline_rounded,
    );

    if (confirmed == true) {
      await _performAction(WalkDetailAction.accept);
    }
  }

  Future<void> _rejectWalk() async {
    final confirmed = await _confirmDialog(
      title: 'Rechazar solicitud',
      message: 'La solicitud dejará de estar disponible para este servicio.',
      confirmText: 'Rechazar',
      destructive: true,
      icon: Icons.block_outlined,
    );

    if (confirmed == true) {
      await _performAction(WalkDetailAction.reject);
    }
  }

  Future<void> _startWalk() async {
    final confirmed = await _confirmDialog(
      title: 'Iniciar paseo',
      message:
          'Inicia el servicio únicamente cuando ya estés con la mascota en el punto de recogida.',
      confirmText: 'Iniciar paseo',
      icon: Icons.directions_walk_rounded,
    );

    if (confirmed == true) {
      await _performAction(WalkDetailAction.start);
    }
  }

  Future<void> _finishWalk() async {
    final state = _controller.state;

    if (state.needsEndEvidence) {
      await _performAction(WalkDetailAction.finish);
      return;
    }

    final confirmed = await _confirmDialog(
      title: 'Finalizar paseo',
      message:
          'Confirma que la mascota fue entregada correctamente y que el servicio terminó.',
      confirmText: 'Finalizar',
      icon: Icons.flag_outlined,
    );

    if (confirmed == true) {
      await _performAction(WalkDetailAction.finish);
    }
  }

  Future<void> _cancelWalk() async {
    final reason = await _requestCancellationReason();

    if (reason == null) {
      return;
    }

    await _performAction(WalkDetailAction.cancel, cancellationReason: reason);
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required IconData icon,
    bool destructive = false,
  }) {
    return showWalkActionConfirmation(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      icon: icon,
      destructive: destructive,
    );
  }

  Future<String?> _requestCancellationReason() async {
    return showWalkCancellationReason(context);
  }

  Future<void> _openChat() async {
    final state = _controller.state;
    final walk = state.walk;
    final id = state.walkId;

    if (walk == null || id == null || !state.canOpenChat) {
      _showMessage('El chat no está disponible para este paseo.');
      return;
    }

    final otherName = state.isWalker ? walk.ownerName : walk.walkerName;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPaseoScreen(
          paseoId: id,
          nombrePerro: walk.petName,
          nombreOtroUsuario: otherName,
        ),
      ),
    );
  }

  Future<void> _openMap() async {
    final state = _controller.state;
    final walk = state.walk;

    if (walk == null || !state.canOpenMap) {
      _showMessage('El mapa todavía no está disponible.');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapaPaseoScreen(paseo: walk.toNavigationMap()),
      ),
    );
  }

  void _scheduleAutomaticMap(WalkDetailState state) {
    if (!widget.openMapOnLoad ||
        _automaticMapOpened ||
        state.walk == null ||
        !state.canOpenMap) {
      return;
    }

    _automaticMapOpened = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await _openMap();
    });
  }

  Future<void> _openTracking() async {
    final state = _controller.state;
    final walk = state.walk;
    final id = state.walkId;

    if (walk == null || id == null || !state.canOpenTracking) {
      _showMessage('El seguimiento todavía no está disponible.');
      return;
    }

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TrackingPaseoScreen(
          paseoId: id,
          nombrePerro: walk.petName,
          nombrePaseador: walk.walkerName,
        ),
      ),
    );

    if (updated == true) {
      await _refreshAfterChild();
    }
  }

  Future<void> _openPlanning() async {
    final id = _controller.state.walkId;
    if (id == null) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => WalkPlanningScreen(
          walkId: id,
          role:
              widget.rol ?? (_controller.state.isWalker ? 'Paseador' : 'Dueño'),
        ),
      ),
    );
    await _controller.refresh();
  }

  Future<void> _openOwnerProfile() async {
    final walk = _controller.state.walk;
    if (walk == null || walk.ownerId <= 0) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PublicOwnerProfileScreen(ownerId: walk.ownerId),
      ),
    );
  }

  Future<void> _openEvidence(String type) async {
    final state = _controller.state;
    final walk = state.walk;
    final id = state.walkId;

    if (walk == null || id == null) {
      return;
    }

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EvidenciaPaseoScreen(
          paseoId: id,
          tipo: type,
          nombrePerro: walk.petName,
          nombrePaseador: walk.walkerName,
        ),
      ),
    );

    if (updated == true) {
      await _refreshAfterChild();

      _showMessage(
        type == 'inicio'
            ? 'Evidencia inicial guardada.'
            : 'Evidencia final guardada.',
        success: true,
      );
    }
  }

  Future<void> _openRating() async {
    final state = _controller.state;
    final walk = state.walk;
    final id = state.walkId;

    if (walk == null || id == null || !state.canRate) {
      return;
    }

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CalificarPaseoScreen(
          paseoId: id,
          nombrePerro: walk.petName,
          nombrePaseador: walk.walkerName,
        ),
      ),
    );

    if (updated == true) {
      await _refreshAfterChild();
      _showMessage('Gracias por compartir tu opinión.', success: true);
    }
  }

  Future<void> _repeatWalk() async {
    final state = _controller.state;
    final walk = state.walk;
    if (walk == null || !state.isOwner || !walk.isFinished) return;
    final rawId = walk.rawData['paseadorId'] ?? walk.rawData['PaseadorId'];
    final walkerId = int.tryParse('$rawId');
    if (walkerId == null || walkerId <= 0) {
      _showMessage('No pudimos identificar al paseador anterior.');
      return;
    }
    try {
      final walker = await PaseadoresService.obtenerPaseador(walkerId);
      if (!mounted) return;
      final petIds =
          (walk.activePets.isNotEmpty ? walk.activePets : walk.requestedPets)
              .map((pet) => pet.id)
              .toList();
      final location = walk.hasPickupCoordinates
          ? PickupLocation(
              latitude: walk.pickupLatitude!,
              longitude: walk.pickupLongitude!,
              address: walk.pickupAddress,
              reference: walk.pickupReferences,
            )
          : null;
      final created = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => CrearPaseoScreen(
            paseador: walker,
            initialDraft: WalkRequestDraft(
              walkerId: walkerId,
              petIds: petIds,
              durationMinutes: walk.durationMinutes,
              pickupLocation: location,
              notes: walk.pickupReferences,
              updatedAt: DateTime.now(),
            ),
          ),
        ),
      );
      if (created == true) widget.onPaseoActualizado?.call();
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openSafetyCenter() async {
    final state = _controller.state;
    final walk = state.walk;
    if (walk == null) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => WalkSafetyCenterScreen(
          walk: walk,
          role: state.role,
          baseUrl: state.baseUrl,
          canOpenChat: state.canOpenChat,
          canOpenMap: state.canOpenMap,
          canOpenTracking: state.canOpenTracking,
          onChat: _openChat,
          onMap: _openMap,
          onTracking: _openTracking,
        ),
      ),
    );
  }

  Future<void> _refreshAfterChild() async {
    await _controller.refresh();

    if (!mounted) {
      return;
    }

    widget.onPaseoActualizado?.call();
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? DogGoTheme.teal : DogGoTheme.ink,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        _scheduleAutomaticMap(state);

        return DogGoScreenScaffold(
          title: 'Detalle del paseo',
          actions: [
            IconButton(
              onPressed: state.loading || state.walkId == null
                  ? null
                  : _openPlanning,
              tooltip: 'Preparación y acuerdos',
              icon: const Icon(Icons.checklist_rounded),
            ),
            IconButton(
              onPressed: state.loading ? null : _controller.refresh,
              tooltip: 'Actualizar',
              icon: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(width: 7),
          ],
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(WalkDetailState state) {
    if (state.loading && state.walk == null) {
      return const DogGoLoadingView(
        message: 'Cargando información del paseo...',
      );
    }

    if (state.error != null && state.walk == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(DogGoSpacing.screenHorizontal),
        child: DogGoErrorView(
          title: 'No pudimos cargar el paseo',
          message: state.error!,
          icon: Icons.route_outlined,
          onRetry: _controller.initialize,
        ),
      );
    }

    final walk = state.walk;

    if (walk == null) {
      return const Center(child: Text('No hay información disponible.'));
    }

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      color: DogGoTheme.teal,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          DogGoSpacing.screenHorizontal,
          18,
          DogGoSpacing.screenHorizontal,
          110,
        ),
        children: [
          _StatusHero(state: state),
          const SizedBox(height: 16),
          _WalkProgress(walk: walk),
          const SizedBox(height: 22),
          _RecommendedStep(
            state: state,
            onStart: _startWalk,
            onOpenMap: _openMap,
            onTracking: _openTracking,
            onStartEvidence: () => _openEvidence('inicio'),
            onEndEvidence: () => _openEvidence('fin'),
            onFinish: _finishWalk,
            onRate: _openRating,
          ),
          const SizedBox(height: 22),
          _QuickActions(
            state: state,
            onChat: _openChat,
            onMap: _openMap,
            onTracking: _openTracking,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openPlanning,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Preparar paseo y acordar llegada'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _openSafetyCenter,
            icon: const Icon(Icons.health_and_safety_rounded),
            label: const Text('Abrir experiencia completa'),
          ),
          const SizedBox(height: 22),
          _ServiceInformation(walk: walk),
          const SizedBox(height: 14),
          WalkPetsSection(
            state: state,
            controller: _controller,
            canViewPetProfiles: true,
          ),
          const SizedBox(height: 14),
          _ParticipantsCard(
            walk: walk,
            isWalker: state.isWalker,
            baseUrl: state.baseUrl,
            onOwnerTap: state.isWalker ? _openOwnerProfile : null,
          ),
          const SizedBox(height: 14),
          _PickupCard(
            walk: walk,
            onOpenMap: state.canOpenMap ? _openMap : null,
          ),

          const SizedBox(height: 14),

          WalkRouteManagementCard(
            walkId: walk.id,
            initialCenter: walk.hasPickupCoordinates
                ? LatLng(walk.pickupLatitude!, walk.pickupLongitude!)
                : const LatLng(25.6866, -100.3161),
            canManage: state.isOwner && (walk.isPending || walk.isAccepted),
            onOpenMap: _openMap,
          ),

          const SizedBox(height: 22),
          _EvidenceSection(
            state: state,
            onStartEvidence: () => _openEvidence('inicio'),
            onEndEvidence: () => _openEvidence('fin'),
          ),
          if (walk.isCancelled || walk.isRejected) ...[
            const SizedBox(height: 22),
            _CancellationCard(walk: walk),
          ],
          const SizedBox(height: 22),
          _MainActions(
            state: state,
            onAccept: _acceptWalk,
            onReject: _rejectWalk,
            onStart: _startWalk,
            onFinish: _finishWalk,
            onCancel: _cancelWalk,
            onRate: _openRating,
          ),
          if (state.isOwner && walk.isFinished) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _repeatWalk,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Repetir este paseo'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  final WalkDetailState state;

  const _StatusHero({required this.state});

  @override
  Widget build(BuildContext context) {
    final walk = state.walk!;
    final color = _statusColor(walk.status);
    final surface = _statusSurface(walk.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.extraLarge),
        border: Border.all(color: color.withValues(alpha: .2)),
        boxShadow: DogGoTheme.softShadow(
          opacity: .035,
          blur: 22,
          offset: const Offset(0, 8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(DogGoRadius.pill),
                ),
                child: Row(
                  children: [
                    Icon(_statusIcon(walk.status), color: color, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      walk.status.label,
                      style: DogGoTheme.caption(
                        size: 10.5,
                        color: color,
                        weight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PetPhoto(url: state.petPhotoUrl, name: walk.petName),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      walk.petsLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.title(size: 23),
                    ),
                    const SizedBox(height: 6),
                    _HeroDetail(
                      icon: Icons.calendar_month_outlined,
                      text: walk.scheduledLabel,
                    ),
                    const SizedBox(height: 5),
                    _HeroDetail(
                      icon: Icons.schedule_outlined,
                      text: walk.durationLabel,
                    ),
                    const SizedBox(height: 5),
                    _HeroDetail(
                      icon: Icons.person_outline_rounded,
                      text: state.isWalker ? walk.ownerName : walk.walkerName,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: surface.withValues(alpha: .65),
              borderRadius: BorderRadius.circular(DogGoRadius.medium),
            ),
            child: Text(
              state.statusMessage,
              style: DogGoTheme.body(
                size: 11.5,
                color: color,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PetPhoto extends StatelessWidget {
  final String? url;
  final String name;

  const _PetPhoto({required this.url, required this.name});

  bool get _hasPhoto {
    final value = url?.trim() ?? '';

    return value.startsWith('http://') || value.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 100,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
      ),
      child: DogGoNetworkImage(
        url: _hasPhoto ? url : null,
        semanticLabel: 'Fotografía de $name',
        fallback: const _PetPlaceholder(),
      ),
    );
  }
}

class _PetPlaceholder extends StatelessWidget {
  const _PetPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.pets_rounded, color: DogGoTheme.teal, size: 37);
  }
}

class _HeroDetail extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroDetail({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: DogGoTheme.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DogGoTheme.subtitle(size: 11),
          ),
        ),
      ],
    );
  }
}

class _WalkProgress extends StatelessWidget {
  final WalkDetail walk;

  const _WalkProgress({required this.walk});

  int get _currentStep {
    if (walk.isCompleted) {
      return 4;
    }

    if (walk.isInProgress) {
      return 3;
    }

    if (walk.isAccepted) {
      return 2;
    }

    if (walk.isPending) {
      return 1;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['Solicitud', 'Aceptado', 'En curso', 'Finalizado'];

    final closed = walk.isCancelled || walk.isRejected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progreso del servicio', style: DogGoTheme.title(size: 16)),
          const SizedBox(height: 16),
          Row(
            children: List.generate(labels.length, (index) {
              final step = index + 1;
              final completed = !closed && step <= _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: closed
                                  ? DogGoTheme.redLight
                                  : completed
                                  ? DogGoTheme.teal
                                  : DogGoTheme.purpleLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              closed
                                  ? Icons.close_rounded
                                  : completed
                                  ? Icons.check_rounded
                                  : Icons.circle_outlined,
                              size: 15,
                              color: closed
                                  ? DogGoTheme.red
                                  : completed
                                  ? Colors.white
                                  : DogGoTheme.muted,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            labels[index],
                            textAlign: TextAlign.center,
                            style: DogGoTheme.caption(
                              size: 8.5,
                              color: completed
                                  ? DogGoTheme.teal
                                  : DogGoTheme.muted,
                              weight: completed
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index < labels.length - 1)
                      Container(
                        width: 10,
                        height: 2,
                        color: !closed && step < _currentStep
                            ? DogGoTheme.teal
                            : DogGoTheme.border,
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _RecommendedStep extends StatelessWidget {
  final WalkDetailState state;
  final VoidCallback onStart;
  final VoidCallback onOpenMap;
  final VoidCallback onTracking;
  final VoidCallback onStartEvidence;
  final VoidCallback onEndEvidence;
  final VoidCallback onFinish;
  final VoidCallback onRate;

  const _RecommendedStep({
    required this.state,
    required this.onStart,
    required this.onOpenMap,
    required this.onTracking,
    required this.onStartEvidence,
    required this.onEndEvidence,
    required this.onFinish,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final action = state.recommendedAction;
    final button = _buttonFor(action);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DogGoTheme.tealLight, DogGoTheme.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.teal.withValues(alpha: .15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: DogGoTheme.card,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _recommendedIcon(action),
              color: DogGoTheme.teal,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SIGUIENTE PASO', style: DogGoTheme.label(size: 9.5)),
                const SizedBox(height: 6),
                Text(state.recommendedTitle, style: DogGoTheme.title(size: 17)),
                const SizedBox(height: 5),
                Text(
                  state.recommendedDescription,
                  style: DogGoTheme.subtitle(size: 11.5),
                ),
                if (button != null) ...[
                  const SizedBox(height: 13),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: state.acting ? null : button.onPressed,
                      icon: Icon(button.icon, size: 18),
                      label: Text(button.label),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _RecommendedButton? _buttonFor(WalkDetailRecommendedAction action) {
    switch (action) {
      case WalkDetailRecommendedAction.startWalk:
        return _RecommendedButton(
          label: 'Iniciar paseo',
          icon: Icons.directions_walk_rounded,
          onPressed: onStart,
        );

      case WalkDetailRecommendedAction.uploadStartEvidence:
        return _RecommendedButton(
          label: 'Subir evidencia inicial',
          icon: Icons.photo_camera_outlined,
          onPressed: onStartEvidence,
        );

      case WalkDetailRecommendedAction.activateTracking:
        return _RecommendedButton(
          label: 'Abrir seguimiento',
          icon: Icons.location_searching_rounded,
          onPressed: onTracking,
        );

      case WalkDetailRecommendedAction.followRoute:
        return _RecommendedButton(
          label: 'Ver recorrido',
          icon: Icons.map_outlined,
          onPressed: onOpenMap,
        );

      case WalkDetailRecommendedAction.uploadEndEvidence:
        return _RecommendedButton(
          label: 'Subir evidencia final',
          icon: Icons.photo_camera_back_outlined,
          onPressed: onEndEvidence,
        );

      case WalkDetailRecommendedAction.finishWalk:
        return _RecommendedButton(
          label: 'Finalizar paseo',
          icon: Icons.flag_outlined,
          onPressed: onFinish,
        );

      case WalkDetailRecommendedAction.rateExperience:
        return _RecommendedButton(
          label: 'Calificar paseo',
          icon: Icons.star_outline_rounded,
          onPressed: onRate,
        );

      case WalkDetailRecommendedAction.waitForWalker:
      case WalkDetailRecommendedAction.reviewRequest:
      case WalkDetailRecommendedAction.preparePet:
      case WalkDetailRecommendedAction.completed:
      case WalkDetailRecommendedAction.cancelled:
      case WalkDetailRecommendedAction.unavailable:
        return null;
    }
  }
}

class _RecommendedButton {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _RecommendedButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}

class _QuickActions extends StatelessWidget {
  final WalkDetailState state;
  final VoidCallback onChat;
  final VoidCallback onMap;
  final VoidCallback onTracking;

  const _QuickActions({
    required this.state,
    required this.onChat,
    required this.onMap,
    required this.onTracking,
  });

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      _QuickAction(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Chat',
        enabled: state.canOpenChat,
        onTap: onChat,
      ),
      _QuickAction(
        icon: Icons.map_outlined,
        label: 'Mapa',
        enabled: state.canOpenMap,
        onTap: onMap,
      ),
      if (state.isWalker)
        _QuickAction(
          icon: Icons.location_searching_rounded,
          label: 'Tracking',
          enabled: state.canOpenTracking,
          onTap: onTracking,
        ),
    ];

    return Row(
      children: List.generate(actions.length, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == actions.length - 1 ? 0 : 9,
            ),
            child: actions[index],
          ),
        );
      }),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.card,
      borderRadius: BorderRadius.circular(DogGoRadius.medium),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(DogGoRadius.medium),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DogGoRadius.medium),
            border: Border.all(color: DogGoTheme.border),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: enabled ? DogGoTheme.teal : DogGoTheme.disabled,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: DogGoTheme.caption(
                  size: 10,
                  color: enabled ? DogGoTheme.ink : DogGoTheme.disabled,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceInformation extends StatelessWidget {
  final WalkDetail walk;

  const _ServiceInformation({required this.walk});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.receipt_long_outlined,
      title: 'Información del servicio',
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.calendar_month_outlined,
            label: 'Programado',
            value: walk.scheduledLabel,
          ),
          const Divider(height: 22),
          _DetailRow(
            icon: Icons.schedule_outlined,
            label: 'Duración',
            value: walk.durationLabel,
          ),
          const Divider(height: 22),
          _DetailRow(
            icon: Icons.payments_outlined,
            label: 'Total del paseo',
            value: walk.priceLabel,
            valueColor: DogGoTheme.teal,
          ),
          if (walk.basePrice != null && walk.activePetCount > 1) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${walk.basePriceLabel} por mascota × ${walk.activePetCount}',
                style: DogGoTheme.caption(size: 9.5),
              ),
            ),
          ],
          if (walk.startedAt != null) ...[
            const Divider(height: 22),
            _DetailRow(
              icon: Icons.play_circle_outline_rounded,
              label: 'Inicio real',
              value: walk.startedLabel,
            ),
          ],
          if (walk.finishedAt != null) ...[
            const Divider(height: 22),
            _DetailRow(
              icon: Icons.flag_outlined,
              label: 'Finalización',
              value: walk.finishedLabel,
            ),
          ],
        ],
      ),
    );
  }
}

class _ParticipantsCard extends StatelessWidget {
  final WalkDetail walk;
  final bool isWalker;
  final String? baseUrl;
  final VoidCallback? onOwnerTap;

  const _ParticipantsCard({
    required this.walk,
    required this.isWalker,
    required this.baseUrl,
    this.onOwnerTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.people_outline_rounded,
      title: 'Participantes',
      child: Column(
        children: [
          _Participant(
            icon: Icons.pets_rounded,
            role: 'Mascota',
            name: walk.petName,
            color: DogGoTheme.teal,
            photoUrl: walk.publicPetPhotoUrl(baseUrl),
          ),
          const SizedBox(height: 13),
          _Participant(
            icon: Icons.directions_walk_rounded,
            role: 'Paseador',
            name: walk.walkerName,
            color: DogGoTheme.purple,
            photoUrl: walk.publicWalkerPhotoUrl(baseUrl),
          ),
          const SizedBox(height: 13),
          _Participant(
            icon: Icons.person_outline_rounded,
            role: 'Dueño',
            name: walk.ownerName,
            color: DogGoTheme.orange,
            photoUrl: walk.publicOwnerPhotoUrl(baseUrl),
            onTap: onOwnerTap,
          ),
        ],
      ),
    );
  }
}

class _Participant extends StatelessWidget {
  final IconData icon;
  final String role;
  final String name;
  final Color color;
  final String? photoUrl;
  final VoidCallback? onTap;

  const _Participant({
    required this.icon,
    required this.role,
    required this.name,
    required this.color,
    this.photoUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: photoUrl == null
                  ? Icon(icon, color: color, size: 19)
                  : DogGoNetworkImage(
                      url: photoUrl,
                      semanticLabel: 'Fotografía de $name',
                      fit: BoxFit.cover,
                      fallback: Icon(icon, color: color, size: 19),
                    ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role, style: DogGoTheme.caption(size: 9.5)),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DogGoTheme.body(size: 12, weight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: DogGoTheme.muted),
          ],
        ),
      ),
    );
  }
}

class _PickupCard extends StatelessWidget {
  final WalkDetail walk;
  final VoidCallback? onOpenMap;

  const _PickupCard({required this.walk, this.onOpenMap});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.location_on_outlined,
      title: 'Punto de recogida',
      trailing: onOpenMap == null
          ? null
          : IconButton(
              onPressed: onOpenMap,
              tooltip: 'Abrir mapa',
              icon: const Icon(Icons.open_in_new_rounded),
              color: DogGoTheme.teal,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            walk.pickupAddress,
            style: DogGoTheme.body(size: 12.5, weight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(walk.pickupReferences, style: DogGoTheme.subtitle(size: 11)),
          const SizedBox(height: 12),
          DogGoMapPreview(
            latitud: walk.pickupLatitude,
            longitud: walk.pickupLongitude,
            height: 145,
            markerLabel: 'Punto de recogida',
            emptyText: 'No hay coordenadas para mostrar',
            onTap: onOpenMap,
          ),
          if (onOpenMap != null) ...[
            const SizedBox(height: 11),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenMap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Ver punto de recogida en el mapa'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EvidenceSection extends StatelessWidget {
  final WalkDetailState state;
  final VoidCallback onStartEvidence;
  final VoidCallback onEndEvidence;

  const _EvidenceSection({
    required this.state,
    required this.onStartEvidence,
    required this.onEndEvidence,
  });

  @override
  Widget build(BuildContext context) {
    final walk = state.walk!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Evidencias', style: DogGoTheme.title(size: 21)),
        const SizedBox(height: 4),
        Text(
          'Registro fotográfico del servicio',
          style: DogGoTheme.subtitle(size: 12),
        ),
        const SizedBox(height: 13),
        _EvidenceCard(
          title: 'Evidencia inicial',
          subtitle: walk.hasStartEvidence
              ? 'Recepción registrada'
              : 'Pendiente de registrar',
          imageUrl: state.startPhotoUrl,
          completed: walk.hasStartEvidence,
          canUpload: state.canUploadStartEvidence,
          onUpload: onStartEvidence,
        ),
        const SizedBox(height: 11),
        _EvidenceCard(
          title: 'Evidencia final',
          subtitle: walk.hasEndEvidence
              ? 'Entrega registrada'
              : 'Pendiente de registrar',
          imageUrl: state.endPhotoUrl,
          completed: walk.hasEndEvidence,
          canUpload: state.canUploadEndEvidence,
          onUpload: onEndEvidence,
        ),
      ],
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final bool completed;
  final bool canUpload;
  final VoidCallback onUpload;

  const _EvidenceCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.completed,
    required this.canUpload,
    required this.onUpload,
  });

  bool get _hasImage {
    final value = imageUrl?.trim() ?? '';

    return value.startsWith('http://') || value.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(
          color: completed
              ? DogGoTheme.green.withValues(alpha: .25)
              : DogGoTheme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: completed ? DogGoTheme.greenLight : DogGoTheme.purpleLight,
              borderRadius: BorderRadius.circular(DogGoRadius.medium),
            ),
            child: _hasImage
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return _EvidencePlaceholder(completed: completed);
                    },
                  )
                : _EvidencePlaceholder(completed: completed),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DogGoTheme.body(size: 12.5, weight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: DogGoTheme.caption(
                    size: 10,
                    color: completed ? DogGoTheme.green : DogGoTheme.muted,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (canUpload)
            IconButton(
              onPressed: onUpload,
              tooltip: 'Subir fotografía',
              icon: const Icon(Icons.add_a_photo_outlined),
              color: DogGoTheme.teal,
              style: IconButton.styleFrom(
                backgroundColor: DogGoTheme.tealLight,
              ),
            )
          else
            Icon(
              completed ? Icons.check_circle_rounded : Icons.schedule_rounded,
              color: completed ? DogGoTheme.green : DogGoTheme.muted,
            ),
        ],
      ),
    );
  }
}

class _EvidencePlaceholder extends StatelessWidget {
  final bool completed;

  const _EvidencePlaceholder({required this.completed});

  @override
  Widget build(BuildContext context) {
    return Icon(
      completed ? Icons.photo_outlined : Icons.add_a_photo_outlined,
      color: completed ? DogGoTheme.green : DogGoTheme.muted,
      size: 27,
    );
  }
}

class _CancellationCard extends StatelessWidget {
  final WalkDetail walk;

  const _CancellationCard({required this.walk});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: DogGoTheme.redLight,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.red.withValues(alpha: .2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: DogGoTheme.red),
              const SizedBox(width: 9),
              Text(
                walk.isRejected ? 'Solicitud rechazada' : 'Paseo cancelado',
                style: DogGoTheme.title(size: 16, color: DogGoTheme.red),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            walk.cancellationReason ??
                (walk.isRejected
                    ? 'El paseador no aceptó esta solicitud.'
                    : 'No se registró un motivo.'),
            style: DogGoTheme.body(size: 11.5, color: DogGoTheme.ink),
          ),
          if (walk.cancelledBy != null) ...[
            const SizedBox(height: 7),
            Text(
              'Cancelado por: ${walk.cancelledBy}',
              style: DogGoTheme.caption(size: 10),
            ),
          ],
          if (walk.cancelledAt != null) ...[
            const SizedBox(height: 3),
            Text(walk.cancelledLabel, style: DogGoTheme.caption(size: 10)),
          ],
        ],
      ),
    );
  }
}

class _MainActions extends StatelessWidget {
  final WalkDetailState state;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onStart;
  final VoidCallback onFinish;
  final VoidCallback onCancel;
  final VoidCallback onRate;

  const _MainActions({
    required this.state,
    required this.onAccept,
    required this.onReject,
    required this.onStart,
    required this.onFinish,
    required this.onCancel,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrimaryAction =
        state.canAccept || state.canStart || state.canFinish || state.canRate;

    if (!hasPrimaryAction && !state.canReject && !state.canCancel) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Acciones', style: DogGoTheme.title(size: 21)),
        const SizedBox(height: 13),
        if (state.canAccept)
          ElevatedButton.icon(
            onPressed: state.acting ? null : onAccept,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Aceptar solicitud'),
          ),
        if (state.canStart)
          ElevatedButton.icon(
            onPressed: state.acting ? null : onStart,
            icon: const Icon(Icons.directions_walk_rounded),
            label: const Text('Iniciar paseo'),
          ),
        if (state.canFinish)
          ElevatedButton.icon(
            onPressed: state.acting ? null : onFinish,
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Finalizar paseo'),
          ),
        if (state.canRate)
          ElevatedButton.icon(
            onPressed: state.acting ? null : onRate,
            icon: const Icon(Icons.star_outline_rounded),
            label: const Text('Calificar paseo'),
          ),
        if (state.canReject) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: state.acting ? null : onReject,
            icon: const Icon(Icons.block_outlined),
            label: const Text('Rechazar solicitud'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DogGoTheme.red,
              side: const BorderSide(color: DogGoTheme.red),
            ),
          ),
        ],
        if (state.canCancel) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: state.acting ? null : onCancel,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancelar paseo'),
            style: TextButton.styleFrom(
              foregroundColor: DogGoTheme.red,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
        if (state.acting) ...[
          const SizedBox(height: 12),
          const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: DogGoTheme.tealLight,
                  borderRadius: BorderRadius.circular(DogGoRadius.medium),
                ),
                child: Icon(icon, color: DogGoTheme.teal, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: DogGoTheme.title(size: 16))),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = DogGoTheme.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: DogGoTheme.muted),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: DogGoTheme.body(size: 11, color: DogGoTheme.muted),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: DogGoTheme.body(
              size: 11,
              color: valueColor,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

IconData _recommendedIcon(WalkDetailRecommendedAction action) {
  switch (action) {
    case WalkDetailRecommendedAction.waitForWalker:
      return Icons.hourglass_top_rounded;
    case WalkDetailRecommendedAction.reviewRequest:
      return Icons.fact_check_outlined;
    case WalkDetailRecommendedAction.preparePet:
      return Icons.pets_outlined;
    case WalkDetailRecommendedAction.startWalk:
      return Icons.directions_walk_rounded;
    case WalkDetailRecommendedAction.uploadStartEvidence:
    case WalkDetailRecommendedAction.uploadEndEvidence:
      return Icons.photo_camera_outlined;
    case WalkDetailRecommendedAction.activateTracking:
      return Icons.location_searching_rounded;
    case WalkDetailRecommendedAction.followRoute:
      return Icons.map_outlined;
    case WalkDetailRecommendedAction.finishWalk:
      return Icons.flag_outlined;
    case WalkDetailRecommendedAction.rateExperience:
      return Icons.star_outline_rounded;
    case WalkDetailRecommendedAction.completed:
      return Icons.task_alt_rounded;
    case WalkDetailRecommendedAction.cancelled:
      return Icons.cancel_outlined;
    case WalkDetailRecommendedAction.unavailable:
      return Icons.info_outline_rounded;
  }
}

Color _statusColor(HomeWalkStatus status) {
  switch (status) {
    case HomeWalkStatus.pending:
      return DogGoTheme.orange;
    case HomeWalkStatus.accepted:
      return DogGoTheme.purple;
    case HomeWalkStatus.inProgress:
      return DogGoTheme.green;
    case HomeWalkStatus.completed:
      return DogGoTheme.teal;
    case HomeWalkStatus.cancelled:
    case HomeWalkStatus.rejected:
      return DogGoTheme.red;
    case HomeWalkStatus.none:
    case HomeWalkStatus.unknown:
      return DogGoTheme.muted;
  }
}

Color _statusSurface(HomeWalkStatus status) {
  switch (status) {
    case HomeWalkStatus.pending:
      return DogGoTheme.orangeLight;
    case HomeWalkStatus.accepted:
      return DogGoTheme.purpleLight;
    case HomeWalkStatus.inProgress:
      return DogGoTheme.greenLight;
    case HomeWalkStatus.completed:
      return DogGoTheme.tealLight;
    case HomeWalkStatus.cancelled:
    case HomeWalkStatus.rejected:
      return DogGoTheme.redLight;
    case HomeWalkStatus.none:
    case HomeWalkStatus.unknown:
      return DogGoTheme.purpleLight;
  }
}

IconData _statusIcon(HomeWalkStatus status) {
  switch (status) {
    case HomeWalkStatus.pending:
      return Icons.schedule_rounded;
    case HomeWalkStatus.accepted:
      return Icons.verified_outlined;
    case HomeWalkStatus.inProgress:
      return Icons.directions_walk_rounded;
    case HomeWalkStatus.completed:
      return Icons.flag_outlined;
    case HomeWalkStatus.cancelled:
    case HomeWalkStatus.rejected:
      return Icons.cancel_outlined;
    case HomeWalkStatus.none:
    case HomeWalkStatus.unknown:
      return Icons.info_outline_rounded;
  }
}
