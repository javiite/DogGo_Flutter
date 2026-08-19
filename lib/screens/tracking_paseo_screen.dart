import 'package:flutter/material.dart';

import '../shared/widgets/doggo_error_view.dart';
import '../shared/widgets/doggo_loading_view.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import 'tracking/live_tracking_controller.dart';
import 'tracking/live_tracking_state.dart';

class TrackingPaseoScreen extends StatefulWidget {
  final int paseoId;
  final String nombrePerro;
  final String nombrePaseador;

  const TrackingPaseoScreen({
    super.key,
    required this.paseoId,
    required this.nombrePerro,
    required this.nombrePaseador,
  });

  @override
  State<TrackingPaseoScreen> createState() => _TrackingPaseoScreenState();
}

class _TrackingPaseoScreenState extends State<TrackingPaseoScreen>
    with WidgetsBindingObserver {
  late final LiveTrackingController _controller;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _controller = LiveTrackingController(
      walkId: widget.paseoId,
      petName: widget.nombrePerro,
      walkerName: widget.nombrePaseador,
    );

    _controller.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.syncStatus();
    }
  }

  void _close() {
    Navigator.pop(context, _controller.shouldReturnUpdated);
  }

  Future<void> _activate() async {
    final result = await _controller.activateBackgroundTracking();

    if (!mounted) {
      return;
    }

    _showMessage(result.message, success: result.success);
  }

  Future<void> _pause() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.pause_circle_outline_rounded, color: DogGoTheme.red),
              SizedBox(width: 10),
              Expanded(child: Text('Pausar ubicación')),
            ],
          ),
          content: const Text(
            'Se detendrá el envío en segundo plano. '
            'La última posición seguirá visible en el mapa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Volver'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: DogGoTheme.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Pausar ubicación'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final result = await _controller.pauseBackgroundTracking();

    if (!mounted) {
      return;
    }

    _showMessage(result.message, success: result.success);
  }

  Future<void> _sendNow() async {
    final result = await _controller.sendCurrentLocation();

    if (!mounted) {
      return;
    }

    _showMessage(result.message, success: result.success);
  }

  void _showMessage(String message, {bool success = false}) {
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

        return Scaffold(
          backgroundColor: DogGoTheme.cream,
          appBar: AppBar(
            leading: IconButton(
              onPressed: _close,
              tooltip: 'Regresar',
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: const Text('Ubicación en vivo'),
            actions: [
              IconButton(
                onPressed: state.processing ? null : _controller.syncStatus,
                tooltip: 'Actualizar estado',
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: state.loading
              ? const DogGoLoadingView(
                  message: 'Comprobando el servicio de ubicación...',
                )
              : RefreshIndicator(
                  onRefresh: _controller.syncStatus,
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
                      _TrackingHero(state: state),
                      if (state.hasRouteStatus) ...[
                        const SizedBox(height: 14),
                        _RouteMonitoringCard(state: state),
                      ],
                      if (state.error != null) ...[
                        const SizedBox(height: 14),
                        DogGoErrorView(
                          title: 'Problema con la ubicación',
                          message: state.error!,
                          icon: Icons.location_off_outlined,
                          onRetry: _controller.syncStatus,
                          compact: true,
                        ),
                      ],
                      if (state.anotherWalkIsActive) ...[
                        const SizedBox(height: 14),
                        _AnotherWalkWarning(state: state),
                      ],
                      const SizedBox(height: 16),
                      _TrackingStatistics(state: state),
                      const SizedBox(height: 14),
                      _CurrentLocationCard(state: state),
                      const SizedBox(height: 14),
                      _BackgroundServiceCard(state: state),
                      const SizedBox(height: 14),
                      const _TrackingSafetyCard(),
                      const SizedBox(height: 22),
                      _TrackingActions(
                        state: state,
                        onActivate: _activate,
                        onPause: _pause,
                        onSendNow: _sendNow,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _RouteMonitoringCard extends StatelessWidget {
  const _RouteMonitoringCard({required this.state});

  final LiveTrackingState state;

  @override
  Widget build(BuildContext context) {
    final outside = state.outsideRoute;
    final reentered = state.reentryDetected && !outside;
    final color = outside
        ? DogGoTheme.red
        : reentered
        ? DogGoTheme.green
        : DogGoTheme.teal;
    final background = outside
        ? const Color(0xFFFFECEC)
        : reentered
        ? const Color(0xFFE8F6ED)
        : DogGoTheme.tealLight;
    final title = outside
        ? 'Fuera de la ruta permitida'
        : reentered
        ? 'Regresaste a la ruta'
        : state.checkpointsReached.isNotEmpty
        ? 'Punto del recorrido alcanzado'
        : 'Dentro del recorrido permitido';
    final icon = outside
        ? Icons.warning_amber_rounded
        : reentered
        ? Icons.add_location_alt_outlined
        : state.checkpointsReached.isNotEmpty
        ? Icons.flag_circle_outlined
        : Icons.verified_user_outlined;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: color.withValues(alpha: .38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(DogGoRadius.medium),
                ),
                child: Icon(icon, color: Colors.white, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DogGoTheme.title(size: 16, color: color),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      state.routeMessage?.trim().isNotEmpty == true
                          ? state.routeMessage!.trim()
                          : 'DogGo está verificando el recorrido con cada lectura GPS.',
                      style: DogGoTheme.subtitle(size: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (state.distanceRouteMeters != null ||
              state.allowedRadiusMeters != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _RouteMetric(
                    label: 'Distancia a la ruta',
                    value: state.routeDistanceLabel,
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RouteMetric(
                    label: 'Margen permitido',
                    value: state.allowedRadiusMeters == null
                        ? 'N/D'
                        : '${state.allowedRadiusMeters!.round()} m',
                    color: color,
                  ),
                ),
              ],
            ),
          ],
          if (state.checkpointsReached.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: state.checkpointsReached
                  .map(
                    (checkpoint) => Chip(
                      avatar: Icon(Icons.check_rounded, size: 16, color: color),
                      label: Text(checkpoint),
                      backgroundColor: Colors.white.withValues(alpha: .72),
                      side: BorderSide(color: color.withValues(alpha: .22)),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteMetric extends StatelessWidget {
  const _RouteMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .68),
        borderRadius: BorderRadius.circular(DogGoRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: DogGoTheme.caption(size: 9)),
          const SizedBox(height: 2),
          Text(value, style: DogGoTheme.title(size: 14, color: color)),
        ],
      ),
    );
  }
}

class _TrackingHero extends StatelessWidget {
  final LiveTrackingState state;

  const _TrackingHero({required this.state});

  @override
  Widget build(BuildContext context) {
    final active = state.isCurrentWalkActive;

    final color = active
        ? DogGoTheme.green
        : state.hasLocation
        ? DogGoTheme.orange
        : DogGoTheme.muted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: active ? DogGoTheme.teal : DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.extraLarge),
        border: Border.all(color: active ? DogGoTheme.teal : DogGoTheme.border),
        boxShadow: active
            ? DogGoTheme.elevatedShadow()
            : DogGoTheme.softShadow(
                opacity: .03,
                blur: 20,
                offset: const Offset(0, 8),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LiveIndicator(active: active),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withValues(alpha: .13)
                      : DogGoTheme.tealLight,
                  borderRadius: BorderRadius.circular(DogGoRadius.pill),
                ),
                child: Text(
                  'Paseo #${state.walkId}',
                  style: DogGoTheme.caption(
                    size: 9,
                    color: active ? Colors.white : DogGoTheme.teal,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 61,
                height: 61,
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withValues(alpha: .13)
                      : DogGoTheme.tealLight,
                  borderRadius: BorderRadius.circular(DogGoRadius.large),
                ),
                child: Icon(
                  active
                      ? Icons.location_searching_rounded
                      : Icons.location_on_outlined,
                  color: active ? Colors.white : color,
                  size: 29,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.petName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.title(
                        size: 23,
                        color: active ? Colors.white : DogGoTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      state.statusTitle,
                      style: DogGoTheme.body(
                        size: 11.5,
                        color: active
                            ? Colors.white.withValues(alpha: .82)
                            : color,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            state.statusDescription,
            style: DogGoTheme.subtitle(
              size: 11.5,
              color: active
                  ? Colors.white.withValues(alpha: .82)
                  : DogGoTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveIndicator extends StatelessWidget {
  final bool active;

  const _LiveIndicator({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? Colors.white.withValues(alpha: .13)
            : DogGoTheme.purpleLight,
        borderRadius: BorderRadius.circular(DogGoRadius.pill),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF9BE4D2) : DogGoTheme.muted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'EN VIVO' : 'PAUSADO',
            style: DogGoTheme.label(
              size: 8.5,
              color: active ? Colors.white : DogGoTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingStatistics extends StatelessWidget {
  final LiveTrackingState state;

  const _TrackingStatistics({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 17),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatisticItem(
              icon: Icons.update_rounded,
              value: state.lastSentLabel,
              label: 'Último envío',
              color: DogGoTheme.teal,
            ),
          ),
          const _StatisticDivider(),
          Expanded(
            child: _StatisticItem(
              icon: Icons.gps_fixed_rounded,
              value: state.accuracyLabel,
              label: 'Precisión',
              color: DogGoTheme.purple,
            ),
          ),
          const _StatisticDivider(),
          Expanded(
            child: _StatisticItem(
              icon: Icons.cloud_upload_outlined,
              value: '${state.successfulUpdates}',
              label: 'Actualizaciones',
              color: DogGoTheme.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatisticItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(height: 7),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DogGoTheme.body(size: 11, weight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: DogGoTheme.caption(size: 8.8),
        ),
      ],
    );
  }
}

class _StatisticDivider extends StatelessWidget {
  const _StatisticDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 52, color: DogGoTheme.divider);
  }
}

class _CurrentLocationCard extends StatelessWidget {
  final LiveTrackingState state;

  const _CurrentLocationCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return _InformationCard(
      icon: Icons.my_location_rounded,
      title: 'Última ubicación',
      subtitle: state.hasLocation
          ? 'Posición enviada al dueño'
          : 'Todavía no hay coordenadas',
      child: Column(
        children: [
          _InformationRow(
            icon: Icons.pin_drop_outlined,
            label: 'Coordenadas',
            value: state.coordinatesLabel,
          ),
          const Divider(height: 22),
          _InformationRow(
            icon: Icons.access_time_rounded,
            label: 'Hora',
            value: state.lastSentLabel,
          ),
          const Divider(height: 22),
          _InformationRow(
            icon: Icons.speed_rounded,
            label: 'Velocidad',
            value: state.speedLabel,
          ),
          const Divider(height: 22),
          _InformationRow(
            icon: Icons.height_rounded,
            label: 'Altitud',
            value: state.altitudeLabel,
          ),
        ],
      ),
    );
  }
}

class _BackgroundServiceCard extends StatelessWidget {
  final LiveTrackingState state;

  const _BackgroundServiceCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return _InformationCard(
      icon: Icons.phone_android_rounded,
      title: 'Servicio en segundo plano',
      subtitle: state.serviceRunning
          ? 'El servicio está ejecutándose'
          : 'El servicio está detenido',
      iconColor: state.serviceRunning ? DogGoTheme.green : DogGoTheme.muted,
      iconBackground: state.serviceRunning
          ? DogGoTheme.greenLight
          : DogGoTheme.purpleLight,
      child: Column(
        children: [
          _ServiceCheck(
            completed: state.serviceRunning,
            title: 'Servicio de Android',
            description: state.serviceRunning
                ? 'Activo en primer plano'
                : 'Sin ejecutar',
          ),
          const SizedBox(height: 13),
          _ServiceCheck(
            completed: state.isCurrentWalkActive,
            title: 'Paseo vinculado',
            description: state.isCurrentWalkActive
                ? 'Paseo #${state.walkId}'
                : 'Sin vínculo activo',
          ),
          const SizedBox(height: 13),
          _ServiceCheck(
            completed: state.hasLocation,
            title: 'Primera ubicación',
            description: state.hasLocation
                ? 'Enviada correctamente'
                : 'Pendiente',
          ),
          const SizedBox(height: 13),
          const _ServiceCheck(
            completed: true,
            title: 'Frecuencia',
            description: 'Aproximadamente cada 5 segundos',
          ),
        ],
      ),
    );
  }
}

class _ServiceCheck extends StatelessWidget {
  final bool completed;
  final String title;
  final String description;

  const _ServiceCheck({
    required this.completed,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: completed ? DogGoTheme.greenLight : DogGoTheme.purpleLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            completed ? Icons.check_rounded : Icons.remove_rounded,
            color: completed ? DogGoTheme.green : DogGoTheme.muted,
            size: 17,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: DogGoTheme.body(size: 11.5, weight: FontWeight.w800),
              ),
              Text(description, style: DogGoTheme.caption(size: 9.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrackingSafetyCard extends StatelessWidget {
  const _TrackingSafetyCard();

  @override
  Widget build(BuildContext context) {
    return _InformationCard(
      icon: Icons.shield_outlined,
      title: 'Privacidad y seguridad',
      subtitle: 'La ubicación pertenece únicamente a este paseo',
      iconColor: DogGoTheme.purple,
      iconBackground: DogGoTheme.purpleLight,
      child: Text(
        'El seguimiento debe permanecer activo solamente durante el servicio. '
        'Al finalizar o cancelar el paseo, DogGo detendrá el envío.',
        style: DogGoTheme.subtitle(size: 11.5),
      ),
    );
  }
}

class _TrackingActions extends StatelessWidget {
  final LiveTrackingState state;
  final VoidCallback onActivate;
  final VoidCallback onPause;
  final VoidCallback onSendNow;

  const _TrackingActions({
    required this.state,
    required this.onActivate,
    required this.onPause,
    required this.onSendNow,
  });

  @override
  Widget build(BuildContext context) {
    if (state.anotherWalkIsActive) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (state.isCurrentWalkActive)
          ElevatedButton.icon(
            onPressed: state.processing ? null : onSendNow,
            icon: state.processing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.gps_fixed_rounded),
            label: Text(
              state.processing
                  ? 'Obteniendo ubicación...'
                  : 'Enviar ubicación ahora',
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: state.processing ? null : onActivate,
            icon: state.processing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_circle_outline_rounded),
            label: Text(
              state.processing
                  ? 'Activando servicio...'
                  : 'Activar ubicación en vivo',
            ),
          ),
        if (state.isCurrentWalkActive) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: state.processing ? null : onPause,
            icon: const Icon(Icons.pause_circle_outline_rounded),
            label: const Text('Pausar ubicación'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DogGoTheme.red,
              side: const BorderSide(color: DogGoTheme.red),
            ),
          ),
        ],
      ],
    );
  }
}

class _AnotherWalkWarning extends StatelessWidget {
  final LiveTrackingState state;

  const _AnotherWalkWarning({required this.state});

  @override
  Widget build(BuildContext context) {
    final otherWalk = state.session?.walkId;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: DogGoTheme.orangeLight,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.orange.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: DogGoTheme.orange,
            size: 27,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              otherWalk == null
                  ? state.statusDescription
                  : 'El paseo #$otherWalk está compartiendo ubicación. Detén ese seguimiento antes de activar este.',
              style: DogGoTheme.body(
                size: 11,
                color: DogGoTheme.orange,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Color iconColor;
  final Color iconBackground;

  const _InformationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.iconColor = DogGoTheme.teal,
    this.iconBackground = DogGoTheme.tealLight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(DogGoRadius.medium),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: DogGoTheme.title(size: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: DogGoTheme.caption(size: 9.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: DogGoTheme.muted, size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: DogGoTheme.body(size: 10.5, color: DogGoTheme.muted),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: DogGoTheme.body(size: 10.5, weight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
