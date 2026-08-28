import 'package:flutter/material.dart';

import '../shared/widgets/doggo_error_view.dart';
import '../shared/widgets/doggo_loading_view.dart';
import '../shared/widgets/doggo_network_image.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import '../theme/doggo_icons.dart';
import '../services/app_preferences_service.dart';
import '../services/advanced_experience_service.dart';
import '../widgets/doggo_logo.dart';
import 'crear_paseo_screen.dart';
import 'profile/widgets/walker_coverage_map.dart';
import 'walkers/models/walker.dart';
import 'walkers/models/walker_availability.dart';
import 'walkers/models/walker_review.dart';
import 'walkers/walker_detail_controller.dart';
import 'walkers/walker_detail_state.dart';

class DetallePaseadorScreen extends StatefulWidget {
  final Map<String, dynamic> paseador;
  final int? initialPetId;

  const DetallePaseadorScreen({
    super.key,
    required this.paseador,
    this.initialPetId,
  });

  @override
  State<DetallePaseadorScreen> createState() => _DetallePaseadorScreenState();
}

class _DetallePaseadorScreenState extends State<DetallePaseadorScreen> {
  late final WalkerDetailController _controller;
  bool _favorite = false;

  @override
  void initState() {
    super.initState();

    _controller = WalkerDetailController(walkerData: widget.paseador);

    _controller.initialize();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final walkerId = _controller.state.walker.id;
    await AppPreferencesService.rememberWalker(walkerId);
    final ids = await AppPreferencesService.favoriteWalkerIds();
    if (mounted) setState(() => _favorite = ids.contains(walkerId));
  }

  Future<void> _toggleFavorite() async {
    final value = await AppPreferencesService.toggleFavoriteWalker(
      _controller.state.walker.id,
    );
    if (mounted) setState(() => _favorite = value);
    try {
      await AdvancedExperienceService.saveWalkerPreference(
        _controller.state.walker.id,
        favorite: value,
        backup: false,
        priority: value ? 10 : 0,
      );
    } catch (_) {
      // El favorito local sigue disponible incluso si la sincronización falla.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _requestWalk() async {
    final walker = _controller.state.walker;

    if (!walker.available) {
      return;
    }

    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CrearPaseoScreen(
          paseador: walker.toNavigationMap(),
          initialPetId: widget.initialPetId,
        ),
      ),
    );

    if (!mounted || created != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paseo creado correctamente.')),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        final screenWidth = MediaQuery.sizeOf(context).width;
        final horizontalPadding = screenWidth < 380
            ? 16.0
            : screenWidth > 760
            ? 24.0
            : DogGoSpacing.screenHorizontal;

        return Scaffold(
          backgroundColor: DogGoTheme.cream,
          bottomNavigationBar: _RequestBottomBar(
            walker: state.walker,
            onRequest: _requestWalk,
          ),
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _controller.refresh,
              color: DogGoTheme.teal,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  6,
                  horizontalPadding,
                  126,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        children: [
                          _DetailTopBar(
                            available: state.walker.available,
                            favorite: _favorite,
                            onFavorite: _toggleFavorite,
                          ),
                          if (state.loadingProfile) ...[
                            const SizedBox(height: 4),
                            const LinearProgressIndicator(minHeight: 2),
                          ],
                          const SizedBox(height: 16),
                          _ProfessionalHero(state: state),
                          const SizedBox(height: 16),
                          _WalkerMetrics(state: state),
                          const SizedBox(height: 14),
                          _TrustSection(state: state),
                          const SizedBox(height: 14),
                          _ResponsivePair(
                            first: _AboutSection(state: state),
                            second: _ServiceDetailsSection(state: state),
                          ),
                          const SizedBox(height: 14),
                          _ServiceZoneSection(walker: state.walker),
                          const SizedBox(height: 14),
                          _ScheduleSection(
                            availability: state.availability,
                            loading: state.loadingAvailability,
                          ),
                          const SizedBox(height: 14),
                          _VerifiedWalkerSection(walker: state.walker),
                          const SizedBox(height: 28),
                          _ReviewsSection(
                            state: state,
                            onRetry: _controller.loadReviews,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailTopBar extends StatelessWidget {
  final bool available;
  final bool favorite;
  final VoidCallback onFavorite;

  const _DetailTopBar({
    required this.available,
    required this.favorite,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Regresar',
            icon: const Icon(Icons.arrow_back_rounded),
            color: DogGoTheme.ink,
            style: IconButton.styleFrom(
              backgroundColor: DogGoTheme.card,
              side: const BorderSide(color: DogGoTheme.border),
            ),
          ),
          const SizedBox(width: 12),
          const DogGoLogo(size: 42),
          const Spacer(),
          IconButton(
            tooltip: favorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
            onPressed: onFavorite,
            icon: Icon(
              favorite ? DogGoIcons.favoriteActive : DogGoIcons.favorite,
              color: favorite ? DogGoTheme.red : DogGoTheme.teal,
            ),
          ),
          _AvailabilityBadge(available: available),
        ],
      ),
    );
  }
}

class _ProfessionalHero extends StatelessWidget {
  final WalkerDetailState state;

  const _ProfessionalHero({required this.state});

  @override
  Widget build(BuildContext context) {
    final walker = state.walker;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DogGoTheme.teal,
        borderRadius: BorderRadius.circular(DogGoRadius.extraLarge),
        boxShadow: DogGoTheme.elevatedShadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -45,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -55,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PERFIL PROFESIONAL',
                style: DogGoTheme.label(
                  size: 10.5,
                  color: Colors.white.withValues(alpha: .78),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WalkerProfilePhoto(walker: walker, photoUrl: state.photoUrl),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                walker.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: DogGoTheme.title(
                                  size: 23,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (walker.verified) ...[
                              const SizedBox(width: 7),
                              const Icon(
                                DogGoIcons.accepted,
                                color: Color(0xFF9BE4D2),
                                size: 21,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            const Icon(
                              DogGoIcons.rating,
                              color: DogGoTheme.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              state.ratingLabel,
                              style: DogGoTheme.body(
                                size: 12.5,
                                color: Colors.white,
                                weight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '· ${state.reviewCountLabel}',
                                overflow: TextOverflow.ellipsis,
                                style: DogGoTheme.caption(
                                  size: 10.5,
                                  color: Colors.white.withValues(alpha: .7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              DogGoIcons.location,
                              color: Colors.white.withValues(alpha: .7),
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                walker.serviceZone,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: DogGoTheme.caption(
                                  size: 10.5,
                                  color: Colors.white.withValues(alpha: .78),
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(DogGoRadius.medium),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(DogGoIcons.price, color: Colors.white, size: 20),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        walker.rateLabel,
                        style: DogGoTheme.body(
                          size: 13,
                          color: Colors.white,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(
                      walker.available ? DogGoIcons.accepted : DogGoIcons.clock,
                      color: walker.available
                          ? const Color(0xFF9BE4D2)
                          : DogGoTheme.orange,
                      size: 19,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      walker.available ? 'Disponible' : 'No disponible',
                      style: DogGoTheme.caption(
                        size: 10,
                        color: Colors.white,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalkerProfilePhoto extends StatelessWidget {
  final Walker walker;
  final String? photoUrl;

  const _WalkerProfilePhoto({required this.walker, required this.photoUrl});

  bool get _hasValidPhoto {
    final value = photoUrl?.trim() ?? '';

    return value.startsWith('http://') || value.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 96,
          height: 96,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(DogGoRadius.large),
            border: Border.all(
              color: Colors.white.withValues(alpha: .2),
              width: 2,
            ),
          ),
          child: DogGoNetworkImage(
            url: _hasValidPhoto ? photoUrl : null,
            semanticLabel: 'Fotografía de ${walker.name}',
            fallback: _WalkerInitials(initials: walker.initials),
          ),
        ),
        if (walker.verified)
          Positioned(
            right: -5,
            bottom: -5,
            child: Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                color: DogGoTheme.card,
                shape: BoxShape.circle,
                border: Border.all(color: DogGoTheme.teal, width: 3),
              ),
              child: const Icon(
                DogGoIcons.safety,
                color: DogGoTheme.teal,
                size: 16,
              ),
            ),
          ),
      ],
    );
  }
}

class _WalkerInitials extends StatelessWidget {
  final String initials;

  const _WalkerInitials({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: DogGoTheme.title(size: 27, color: Colors.white),
      ),
    );
  }
}

class _WalkerMetrics extends StatelessWidget {
  final WalkerDetailState state;

  const _WalkerMetrics({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 17),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MetricItem(
              icon: DogGoIcons.rating,
              value: state.ratingLabel,
              label: 'Calificación',
              color: DogGoTheme.orange,
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _MetricItem(
              icon: Icons.workspace_premium_outlined,
              value: '${state.displayedExperienceYears}',
              label: state.displayedExperienceYears == 1
                  ? 'Año exp.'
                  : 'Años exp.',
              color: DogGoTheme.purple,
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _MetricItem(
              icon: DogGoIcons.walking,
              value: '${state.displayedCompletedWalks}',
              label: 'Paseos',
              color: DogGoTheme.teal,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MetricItem({
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
          style: DogGoTheme.title(size: 16),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: DogGoTheme.caption(size: 9.5, weight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 54, color: DogGoTheme.divider);
  }
}

class _TrustSection extends StatelessWidget {
  final WalkerDetailState state;

  const _TrustSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final trust = state.trust;

    return _InformationCard(
      icon: DogGoIcons.safety,
      title: 'Confianza DogGo',
      subtitle: 'Señales verificables de su trayectoria',
      child: state.loadingTrust
          ? const LinearProgressIndicator(minHeight: 3)
          : trust == null
          ? _BasicTrust(walker: state.walker)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: DogGoTheme.teal,
                        shape: BoxShape.circle,
                        boxShadow: DogGoTheme.softShadow(
                          opacity: .12,
                          blur: 14,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            trust.scoreLabel,
                            style: DogGoTheme.title(
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '/ 100',
                            style: DogGoTheme.caption(
                              size: 8,
                              color: Colors.white.withValues(alpha: .75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trust.levelLabel,
                            style: DogGoTheme.title(size: 15),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Calculada con verificación, experiencia, paseos y clientes recurrentes.',
                            style: DogGoTheme.caption(size: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: trust.badges
                      .map((badge) => _TrustBadge(label: badge))
                      .toList(growable: false),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _TrustFact(
                        value: '${trust.completedWalks}',
                        label: 'paseos finalizados',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TrustFact(
                        value: '${trust.recurringClients}',
                        label: 'clientes recurrentes',
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _BasicTrust extends StatelessWidget {
  final Walker walker;

  const _BasicTrust({required this.walker});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          walker.verified ? DogGoIcons.accepted : DogGoIcons.info,
          color: walker.verified ? DogGoTheme.green : DogGoTheme.muted,
          size: 24,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            walker.verified
                ? 'Identidad y documentos aprobados por DogGo.'
                : 'Este perfil sigue construyendo su reputación.',
            style: DogGoTheme.subtitle(size: 11.5),
          ),
        ),
      ],
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final String label;

  const _TrustBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: DogGoTheme.greenLight,
        borderRadius: BorderRadius.circular(DogGoRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(DogGoIcons.accepted, size: 14, color: DogGoTheme.green),
          const SizedBox(width: 5),
          Text(
            label,
            style: DogGoTheme.caption(
              size: 9.5,
              color: DogGoTheme.green,
              weight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustFact extends StatelessWidget {
  final String value;
  final String label;

  const _TrustFact({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: DogGoTheme.cream,
        borderRadius: BorderRadius.circular(DogGoRadius.small),
      ),
      child: Column(
        children: [
          Text(value, style: DogGoTheme.title(size: 15)),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DogGoTheme.caption(size: 8.5),
          ),
        ],
      ),
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _ResponsivePair({required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(children: [first, const SizedBox(height: 14), second]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 14),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _AboutSection extends StatelessWidget {
  final WalkerDetailState state;

  const _AboutSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final walker = state.walker;
    return _InformationCard(
      leading: _AboutPhoto(walker: walker, photoUrl: state.photoUrl),
      title: 'Sobre ${_firstName(walker.name)}',
      subtitle: 'Presentación profesional',
      child: Text(
        walker.description,
        style: DogGoTheme.subtitle(size: 13, color: DogGoTheme.ink),
      ),
    );
  }
}

class _AboutPhoto extends StatelessWidget {
  final Walker walker;
  final String? photoUrl;

  const _AboutPhoto({required this.walker, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DogGoTheme.teal,
        borderRadius: BorderRadius.circular(DogGoRadius.medium),
      ),
      child: DogGoNetworkImage(
        url: photoUrl,
        semanticLabel: 'Fotografía de ${walker.name}',
        fallback: _WalkerInitials(initials: walker.initials),
      ),
    );
  }
}

class _ServiceZoneSection extends StatelessWidget {
  final Walker walker;

  const _ServiceZoneSection({required this.walker});

  void _openMap(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => _CoverageMapScreen(walker: walker)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zones = walker.zones.isEmpty ? [walker.serviceZone] : walker.zones;

    return _InformationCard(
      icon: DogGoIcons.map,
      iconColor: DogGoTheme.purple,
      iconBackground: DogGoTheme.purpleLight,
      title: 'Cobertura de servicio',
      subtitle: 'Área aproximada donde puede aceptar paseos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (walker.hasCoverageCenter) ...[
            Stack(
              children: [
                WalkerCoverageMap(
                  latitude: walker.latitude!,
                  longitude: walker.longitude!,
                  radiusKm: walker.serviceRadiusKm,
                  interactive: false,
                  height: 210,
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(DogGoRadius.large),
                    child: InkWell(
                      onTap: () => _openMap(context),
                      borderRadius: BorderRadius.circular(DogGoRadius.large),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(DogGoRadius.pill),
                        boxShadow: DogGoTheme.softShadow(
                          opacity: .08,
                          blur: 10,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            DogGoIcons.view,
                            color: DogGoTheme.teal,
                            size: 15,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Ampliar mapa',
                            style: TextStyle(
                              color: DogGoTheme.teal,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DogGoTheme.purpleLight,
                borderRadius: BorderRadius.circular(DogGoRadius.medium),
              ),
              child: const Column(
                children: [
                  Icon(DogGoIcons.map, color: DogGoTheme.purple, size: 28),
                  SizedBox(height: 7),
                  Text(
                    'Este paseador todavía no dibujó su cobertura en el mapa.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                DogGoIcons.location,
                color: DogGoTheme.purple,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      walker.coverageLabel,
                      style: DogGoTheme.body(size: 12, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Radio de hasta ${walker.serviceRadiusKm} km',
                      style: DogGoTheme.caption(size: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: zones.map((zone) {
              return Container(
                constraints: const BoxConstraints(maxWidth: 260),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: DogGoTheme.purpleLight,
                  borderRadius: BorderRadius.circular(DogGoRadius.pill),
                ),
                child: Text(
                  zone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DogGoTheme.caption(
                    size: 10.5,
                    color: DogGoTheme.purple,
                    weight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            'La ubicación exacta del paseador no se comparte; el círculo representa únicamente su zona de trabajo.',
            style: DogGoTheme.caption(size: 9.5),
          ),
        ],
      ),
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  final WalkerAvailability availability;
  final bool loading;

  const _ScheduleSection({required this.availability, required this.loading});

  @override
  Widget build(BuildContext context) {
    return _InformationCard(
      icon: DogGoIcons.calendarConfirmed,
      iconColor: DogGoTheme.teal,
      iconBackground: DogGoTheme.tealLight,
      title: 'Próximos horarios',
      subtitle: 'Disponibilidad semanal habitual',
      child: loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          : availability.hasSchedules
          ? Column(
              children: [
                ...availability.upcomingSchedules
                    .take(6)
                    .map((schedule) => _ScheduleRow(schedule: schedule)),
                if (availability.schedules.length > 6)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      '+ ${availability.schedules.length - 6} bloques adicionales',
                      style: DogGoTheme.caption(
                        size: 10,
                        color: DogGoTheme.teal,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                const SizedBox(height: 9),
                Text(
                  'El horario definitivo se valida al solicitar el paseo.',
                  style: DogGoTheme.caption(size: 9.5),
                ),
              ],
            )
          : Text(
              'Aún no publicó bloques semanales. Puedes enviar una solicitud para consultar disponibilidad.',
              style: DogGoTheme.subtitle(size: 11.5),
            ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final WalkerSchedule schedule;

  const _ScheduleRow({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DogGoTheme.tealLight,
              borderRadius: BorderRadius.circular(DogGoRadius.small),
            ),
            child: Text(
              schedule.shortDayLabel,
              style: DogGoTheme.caption(
                size: 9.5,
                color: DogGoTheme.teal,
                weight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              schedule.nextDateLabel(),
              style: DogGoTheme.body(size: 11.5, weight: FontWeight.w700),
            ),
          ),
          const Icon(DogGoIcons.clock, size: 16, color: DogGoTheme.muted),
          const SizedBox(width: 5),
          Text(
            schedule.timeRange,
            style: DogGoTheme.body(size: 11, weight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ServiceDetailsSection extends StatelessWidget {
  final WalkerDetailState state;

  const _ServiceDetailsSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final walker = state.walker;
    final completed = state.displayedCompletedWalks;
    final experience = state.displayedExperienceYears;

    return _InformationCard(
      icon: DogGoIcons.details,
      iconColor: DogGoTheme.orange,
      iconBackground: DogGoTheme.orangeLight,
      title: 'Información del servicio',
      subtitle: 'Datos para tu reservación',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 8) / 2;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ServiceFactTile(
                width: itemWidth,
                icon: DogGoIcons.price,
                label: 'Tarifa',
                value: walker.rateLabel,
                accent: DogGoTheme.teal,
              ),
              _ServiceFactTile(
                width: itemWidth,
                icon: DogGoIcons.rating,
                label: 'Experiencia',
                value: experience == 1 ? '1 año' : '$experience años',
                accent: DogGoTheme.purple,
              ),
              _ServiceFactTile(
                width: itemWidth,
                icon: DogGoIcons.walking,
                label: 'Paseos',
                value: completed == 0
                    ? 'Aún sin paseos'
                    : '$completed completos',
                accent: DogGoTheme.orange,
              ),
              _ServiceFactTile(
                width: itemWidth,
                icon: DogGoIcons.clock,
                label: 'Estado',
                value: walker.available ? 'Disponible' : 'No disponible',
                accent: walker.available ? DogGoTheme.green : DogGoTheme.red,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CoverageMapScreen extends StatelessWidget {
  final Walker walker;

  const _CoverageMapScreen({required this.walker});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      appBar: AppBar(title: Text('Cobertura de ${_firstName(walker.name)}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: DogGoTheme.card,
                  borderRadius: BorderRadius.circular(DogGoRadius.medium),
                  border: Border.all(color: DogGoTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      DogGoIcons.location,
                      color: DogGoTheme.purple,
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            walker.coverageLabel,
                            style: DogGoTheme.body(
                              size: 12,
                              weight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Cobertura aproximada de ${walker.serviceRadiusKm} km',
                            style: DogGoTheme.caption(size: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return WalkerCoverageMap(
                      latitude: walker.latitude!,
                      longitude: walker.longitude!,
                      radiusKm: walker.serviceRadiusKm,
                      interactive: true,
                      height: constraints.maxHeight,
                    );
                  },
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'Puedes mover y acercar el mapa. El círculo representa la zona de trabajo, no el domicilio del paseador.',
                textAlign: TextAlign.center,
                style: DogGoTheme.caption(size: 9.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceFactTile extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _ServiceFactTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(DogGoRadius.medium),
        border: Border.all(color: accent.withValues(alpha: .13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 17),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DogGoTheme.caption(
                    size: 9.5,
                    color: DogGoTheme.muted,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DogGoTheme.body(
              size: 11,
              color: DogGoTheme.ink,
              weight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedWalkerSection extends StatelessWidget {
  final Walker walker;

  const _VerifiedWalkerSection({required this.walker});

  @override
  Widget build(BuildContext context) {
    return _InformationCard(
      icon: DogGoIcons.safety,
      iconColor: DogGoTheme.green,
      iconBackground: DogGoTheme.greenLight,
      title: walker.verified ? 'Paseador verificado' : 'Perfil profesional',
      subtitle: walker.verified
          ? 'Expediente revisado y aprobado por DogGo'
          : 'Este perfil continúa en proceso de validación',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: walker.verified
                  ? DogGoTheme.greenLight
                  : DogGoTheme.orangeLight,
              borderRadius: BorderRadius.circular(DogGoRadius.medium),
            ),
            child: Row(
              children: [
                Icon(
                  walker.verified ? DogGoIcons.accepted : DogGoIcons.warning,
                  color: walker.verified ? DogGoTheme.green : DogGoTheme.orange,
                  size: 27,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    walker.verified
                        ? 'Solo los paseadores con verificación aprobada aparecen en la búsqueda de DogGo.'
                        : 'DogGo todavía está revisando la información de este perfil.',
                    style: DogGoTheme.body(
                      size: 11,
                      color: DogGoTheme.ink,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (walker.verified) ...[
            const SizedBox(height: 13),
            const _VerificationCheck(label: 'Identidad oficial validada'),
            const SizedBox(height: 9),
            const _VerificationCheck(
              label: 'Comprobante de domicilio revisado',
            ),
            const SizedBox(height: 9),
            const _VerificationCheck(
              label: 'Cuenta activa y correo confirmado',
            ),
          ],
        ],
      ),
    );
  }
}

class _VerificationCheck extends StatelessWidget {
  final String label;

  const _VerificationCheck({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(DogGoIcons.accepted, color: DogGoTheme.green, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: DogGoTheme.body(size: 10.5, weight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final WalkerDetailState state;
  final VoidCallback onRetry;

  const _ReviewsSection({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reseñas', style: DogGoTheme.title(size: 21)),
                  const SizedBox(height: 4),
                  Text(
                    state.reviewCountLabel,
                    style: DogGoTheme.subtitle(size: 12),
                  ),
                ],
              ),
            ),
            if (state.displayedRating > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: DogGoTheme.orangeLight,
                  borderRadius: BorderRadius.circular(DogGoRadius.pill),
                ),
                child: Row(
                  children: [
                    const Icon(
                      DogGoIcons.rating,
                      color: DogGoTheme.orange,
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      state.ratingLabel,
                      style: DogGoTheme.body(
                        size: 11.5,
                        color: DogGoTheme.ink,
                        weight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (state.loadingReviews)
          const _ReviewsLoading()
        else if (state.reviewsError != null)
          DogGoErrorView(
            title: 'No pudimos cargar las reseñas',
            message: state.reviewsError!,
            icon: Icons.rate_review_outlined,
            onRetry: onRetry,
            compact: true,
          )
        else if (state.reviews.isEmpty)
          const _NoReviewsCard()
        else
          Column(
            children: List.generate(state.reviews.length, (index) {
              final review = state.reviews[index];

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == state.reviews.length - 1 ? 0 : 11,
                ),
                child: _ReviewCard(review: review),
              );
            }),
          ),
      ],
    );
  }
}

class _ReviewsLoading extends StatelessWidget {
  const _ReviewsLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: const DogGoLoadingView(
        message: 'Cargando reseñas...',
        compact: true,
      ),
    );
  }
}

class _NoReviewsCard extends StatelessWidget {
  const _NoReviewsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: DogGoTheme.orangeLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              DogGoIcons.rating,
              color: DogGoTheme.orange,
              size: 26,
            ),
          ),
          const SizedBox(height: 11),
          Text('Aún no hay reseñas', style: DogGoTheme.title(size: 16)),
          const SizedBox(height: 4),
          Text(
            'Las opiniones de otros dueños aparecerán aquí.',
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(size: 11.5),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final WalkerReview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: DogGoTheme.tealLight,
              shape: BoxShape.circle,
            ),
            child: Text(
              review.authorInitials,
              style: DogGoTheme.body(
                size: 12,
                color: DogGoTheme.teal,
                weight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DogGoTheme.body(
                          size: 12.5,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (review.rating > 0) ...[
                      const Icon(
                        DogGoIcons.rating,
                        color: DogGoTheme.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        review.ratingLabel,
                        style: DogGoTheme.body(
                          size: 10.5,
                          weight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                ),
                if (review.dateLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(review.dateLabel, style: DogGoTheme.caption(size: 9.5)),
                ],
                const SizedBox(height: 7),
                Text(
                  review.comment,
                  style: DogGoTheme.subtitle(size: 11.5, color: DogGoTheme.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final Widget child;

  const _InformationCard({
    this.icon,
    this.leading,
    required this.title,
    required this.subtitle,
    required this.child,
    this.iconColor = DogGoTheme.teal,
    this.iconBackground = DogGoTheme.tealLight,
  }) : assert(icon != null || leading != null);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.border),
        boxShadow: DogGoTheme.softShadow(
          opacity: .02,
          blur: 16,
          offset: const Offset(0, 6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              leading ??
                  Container(
                    width: 42,
                    height: 42,
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
                    Text(subtitle, style: DogGoTheme.caption(size: 10.5)),
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

class _AvailabilityBadge extends StatelessWidget {
  final bool available;

  const _AvailabilityBadge({required this.available});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: available ? DogGoTheme.greenLight : DogGoTheme.redLight,
        borderRadius: BorderRadius.circular(DogGoRadius.pill),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: available ? DogGoTheme.green : DogGoTheme.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            available ? 'Disponible' : 'No disponible',
            style: DogGoTheme.caption(
              size: 10,
              color: available ? DogGoTheme.green : DogGoTheme.red,
              weight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestBottomBar extends StatelessWidget {
  final Walker walker;
  final VoidCallback onRequest;

  const _RequestBottomBar({required this.walker, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 370;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          compact ? 12 : DogGoSpacing.screenHorizontal,
          10,
          compact ? 12 : DogGoSpacing.screenHorizontal,
          12,
        ),
        decoration: BoxDecoration(
          color: DogGoTheme.card.withValues(alpha: .98),
          border: const Border(top: BorderSide(color: DogGoTheme.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Row(
              children: [
                if (walker.hourlyRate != null && !compact) ...[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tarifa', style: DogGoTheme.caption(size: 9.5)),
                      Text(
                        '\$${walker.hourlyRate!.toStringAsFixed(2)}',
                        style: DogGoTheme.title(size: 17),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: walker.available ? onRequest : null,
                      icon: Icon(
                        walker.available
                            ? DogGoIcons.walking
                            : DogGoIcons.clock,
                      ),
                      label: Text(
                        walker.available
                            ? compact
                                  ? 'Solicitar'
                                  : 'Solicitar paseo'
                            : 'No disponible',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _firstName(String fullName) {
  final words = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  return words.isEmpty ? 'el paseador' : words.first;
}
