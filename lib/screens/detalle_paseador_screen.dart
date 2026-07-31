import 'package:flutter/material.dart';

import '../shared/widgets/doggo_error_view.dart';
import '../shared/widgets/doggo_loading_view.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import '../widgets/doggo_logo.dart';
import 'crear_paseo_screen.dart';
import 'walkers/models/walker.dart';
import 'walkers/models/walker_review.dart';
import 'walkers/walker_detail_controller.dart';
import 'walkers/walker_detail_state.dart';

class DetallePaseadorScreen extends StatefulWidget {
  final Map<String, dynamic> paseador;

  const DetallePaseadorScreen({
    super.key,
    required this.paseador,
  });

  @override
  State<DetallePaseadorScreen> createState() =>
      _DetallePaseadorScreenState();
}

class _DetallePaseadorScreenState
    extends State<DetallePaseadorScreen> {
  late final WalkerDetailController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WalkerDetailController(
      walkerData: widget.paseador,
    );

    _controller.initialize();
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
        ),
      ),
    );

    if (!mounted || created != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Paseo creado correctamente.',
        ),
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;

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
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  DogGoSpacing.screenHorizontal,
                  6,
                  DogGoSpacing.screenHorizontal,
                  126,
                ),
                children: [
                  _DetailTopBar(
                    available: state.walker.available,
                  ),
                  const SizedBox(height: 16),
                  _ProfessionalHero(
                    state: state,
                  ),
                  const SizedBox(height: 16),
                  _WalkerMetrics(
                    state: state,
                  ),
                  const SizedBox(height: 24),
                  _AboutSection(
                    walker: state.walker,
                  ),
                  const SizedBox(height: 14),
                  _ServiceZoneSection(
                    walker: state.walker,
                  ),
                  const SizedBox(height: 14),
                  _ServiceDetailsSection(
                    walker: state.walker,
                  ),
                  const SizedBox(height: 14),
                  const _SafetySection(),
                  const SizedBox(height: 28),
                  _ReviewsSection(
                    state: state,
                    onRetry: _controller.loadReviews,
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

  const _DetailTopBar({
    required this.available,
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
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
            color: DogGoTheme.ink,
            style: IconButton.styleFrom(
              backgroundColor: DogGoTheme.card,
              side: const BorderSide(
                color: DogGoTheme.border,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const DogGoLogo(size: 42),
          const Spacer(),
          _AvailabilityBadge(
            available: available,
          ),
        ],
      ),
    );
  }
}

class _ProfessionalHero extends StatelessWidget {
  final WalkerDetailState state;

  const _ProfessionalHero({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final walker = state.walker;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DogGoTheme.teal,
        borderRadius: BorderRadius.circular(
          DogGoRadius.extraLarge,
        ),
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
                color: Colors.white.withValues(
                  alpha: .06,
                ),
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
                color: Colors.white.withValues(
                  alpha: .04,
                ),
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
                  color: Colors.white.withValues(
                    alpha: .78,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _WalkerProfilePhoto(
                    walker: walker,
                    photoUrl: state.photoUrl,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                walker.name,
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: DogGoTheme.title(
                                  size: 23,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (walker.verified) ...[
                              const SizedBox(width: 7),
                              const Icon(
                                Icons.verified_rounded,
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
                              Icons.star_rounded,
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
                                overflow:
                                    TextOverflow.ellipsis,
                                style: DogGoTheme.caption(
                                  size: 10.5,
                                  color: Colors.white
                                      .withValues(alpha: .7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: Colors.white.withValues(
                                alpha: .7,
                              ),
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                walker.serviceZone,
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: DogGoTheme.caption(
                                  size: 10.5,
                                  color: Colors.white
                                      .withValues(alpha: .78),
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
                  color: Colors.white.withValues(
                    alpha: .11,
                  ),
                  borderRadius: BorderRadius.circular(
                    DogGoRadius.medium,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: .12,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
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
                      walker.available
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      color: walker.available
                          ? const Color(0xFF9BE4D2)
                          : DogGoTheme.orange,
                      size: 19,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      walker.available
                          ? 'Disponible'
                          : 'No disponible',
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

  const _WalkerProfilePhoto({
    required this.walker,
    required this.photoUrl,
  });

  bool get _hasValidPhoto {
    final value = photoUrl?.trim() ?? '';

    return value.startsWith('http://') ||
        value.startsWith('https://');
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
            borderRadius: BorderRadius.circular(
              DogGoRadius.large,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: .2),
              width: 2,
            ),
          ),
          child: _hasValidPhoto
              ? Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return _WalkerInitials(
                      initials: walker.initials,
                    );
                  },
                )
              : _WalkerInitials(
                  initials: walker.initials,
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
                border: Border.all(
                  color: DogGoTheme.teal,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
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

  const _WalkerInitials({
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: DogGoTheme.title(
          size: 27,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _WalkerMetrics extends StatelessWidget {
  final WalkerDetailState state;

  const _WalkerMetrics({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final walker = state.walker;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        border: Border.all(
          color: DogGoTheme.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MetricItem(
              icon: Icons.star_rounded,
              value: state.ratingLabel,
              label: 'Calificación',
              color: DogGoTheme.orange,
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _MetricItem(
              icon: Icons.workspace_premium_outlined,
              value: '${walker.experienceYears}',
              label: walker.experienceYears == 1
                  ? 'Año exp.'
                  : 'Años exp.',
              color: DogGoTheme.purple,
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _MetricItem(
              icon: Icons.directions_walk_rounded,
              value: '${walker.completedWalks}',
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
        Icon(
          icon,
          color: color,
          size: 21,
        ),
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
          style: DogGoTheme.caption(
            size: 9.5,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 54,
      color: DogGoTheme.divider,
    );
  }
}

class _AboutSection extends StatelessWidget {
  final Walker walker;

  const _AboutSection({
    required this.walker,
  });

  @override
  Widget build(BuildContext context) {
    return _InformationCard(
      icon: Icons.person_outline_rounded,
      title: 'Sobre ${_firstName(walker.name)}',
      subtitle: 'Presentación profesional',
      child: Text(
        walker.description,
        style: DogGoTheme.subtitle(
          size: 13,
          color: DogGoTheme.ink,
        ),
      ),
    );
  }
}

class _ServiceZoneSection extends StatelessWidget {
  final Walker walker;

  const _ServiceZoneSection({
    required this.walker,
  });

  @override
  Widget build(BuildContext context) {
    final zones = walker.zones.isEmpty
        ? [walker.serviceZone]
        : walker.zones;

    return _InformationCard(
      icon: Icons.location_on_outlined,
      iconColor: DogGoTheme.purple,
      iconBackground: DogGoTheme.purpleLight,
      title: 'Zona de servicio',
      subtitle: 'Áreas donde realiza paseos',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: zones.map((zone) {
          return Container(
            constraints: const BoxConstraints(
              maxWidth: 260,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: DogGoTheme.purpleLight,
              borderRadius: BorderRadius.circular(
                DogGoRadius.pill,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: DogGoTheme.purple,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Flexible(
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
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ServiceDetailsSection extends StatelessWidget {
  final Walker walker;

  const _ServiceDetailsSection({
    required this.walker,
  });

  @override
  Widget build(BuildContext context) {
    return _InformationCard(
      icon: Icons.fact_check_outlined,
      iconColor: DogGoTheme.orange,
      iconBackground: DogGoTheme.orangeLight,
      title: 'Información del servicio',
      subtitle: 'Datos para tu reservación',
      child: Column(
        children: [
          _InformationRow(
            icon: Icons.payments_outlined,
            label: 'Tarifa',
            value: walker.rateLabel,
          ),
          const Divider(height: 22),
          _InformationRow(
            icon: Icons.workspace_premium_outlined,
            label: 'Experiencia',
            value: walker.experienceLabel,
          ),
          const Divider(height: 22),
          _InformationRow(
            icon: Icons.directions_walk_outlined,
            label: 'Paseos realizados',
            value: walker.completedWalksLabel,
          ),
          const Divider(height: 22),
          _InformationRow(
            icon: Icons.schedule_rounded,
            label: 'Estado',
            value: walker.available
                ? 'Disponible para solicitudes'
                : 'No disponible por ahora',
            valueColor: walker.available
                ? DogGoTheme.green
                : DogGoTheme.red,
          ),
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = DogGoTheme.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: DogGoTheme.muted,
          size: 19,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            label,
            style: DogGoTheme.body(
              size: 11.5,
              color: DogGoTheme.muted,
              weight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: DogGoTheme.body(
              size: 11.5,
              color: valueColor,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SafetySection extends StatelessWidget {
  const _SafetySection();

  @override
  Widget build(BuildContext context) {
    return _InformationCard(
      icon: Icons.shield_outlined,
      iconColor: DogGoTheme.green,
      iconBackground: DogGoTheme.greenLight,
      title: 'Seguridad DogGo',
      subtitle: 'Protección durante el servicio',
      child: const Column(
        children: [
          _SafetyItem(
            icon: Icons.location_searching_rounded,
            title: 'Seguimiento del recorrido',
            description:
                'Consulta la ubicación durante un paseo activo.',
          ),
          SizedBox(height: 14),
          _SafetyItem(
            icon: Icons.photo_camera_outlined,
            title: 'Evidencia del servicio',
            description:
                'El paseador puede registrar el inicio y el final.',
          ),
          SizedBox(height: 14),
          _SafetyItem(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Comunicación directa',
            description:
                'Mantén el contacto desde el chat del paseo.',
          ),
        ],
      ),
    );
  }
}

class _SafetyItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _SafetyItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: DogGoTheme.greenLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: DogGoTheme.green,
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: DogGoTheme.body(
                  size: 12,
                  weight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: DogGoTheme.caption(size: 10.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final WalkerDetailState state;
  final VoidCallback onRetry;

  const _ReviewsSection({
    required this.state,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reseñas',
                    style: DogGoTheme.title(size: 21),
                  ),
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
                  borderRadius: BorderRadius.circular(
                    DogGoRadius.pill,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
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
            children: List.generate(
              state.reviews.length,
              (index) {
                final review = state.reviews[index];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index ==
                            state.reviews.length - 1
                        ? 0
                        : 11,
                  ),
                  child: _ReviewCard(
                    review: review,
                  ),
                );
              },
            ),
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
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        border: Border.all(
          color: DogGoTheme.border,
        ),
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
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        border: Border.all(
          color: DogGoTheme.border,
        ),
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
              Icons.star_outline_rounded,
              color: DogGoTheme.orange,
              size: 26,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            'Aún no hay reseñas',
            style: DogGoTheme.title(size: 16),
          ),
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

  const _ReviewCard({
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        border: Border.all(
          color: DogGoTheme.border,
        ),
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
                        Icons.star_rounded,
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
                  Text(
                    review.dateLabel,
                    style: DogGoTheme.caption(size: 9.5),
                  ),
                ],
                const SizedBox(height: 7),
                Text(
                  review.comment,
                  style: DogGoTheme.subtitle(
                    size: 11.5,
                    color: DogGoTheme.ink,
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

class _InformationCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final Widget child;

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
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        border: Border.all(
          color: DogGoTheme.border,
        ),
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(
                    DogGoRadius.medium,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DogGoTheme.title(size: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: DogGoTheme.caption(
                        size: 10.5,
                      ),
                    ),
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

  const _AvailabilityBadge({
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: available
            ? DogGoTheme.greenLight
            : DogGoTheme.redLight,
        borderRadius: BorderRadius.circular(
          DogGoRadius.pill,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: available
                  ? DogGoTheme.green
                  : DogGoTheme.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            available ? 'Disponible' : 'No disponible',
            style: DogGoTheme.caption(
              size: 10,
              color: available
                  ? DogGoTheme.green
                  : DogGoTheme.red,
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

  const _RequestBottomBar({
    required this.walker,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          DogGoSpacing.screenHorizontal,
          10,
          DogGoSpacing.screenHorizontal,
          12,
        ),
        decoration: BoxDecoration(
          color: DogGoTheme.card.withValues(
            alpha: .98,
          ),
          border: const Border(
            top: BorderSide(
              color: DogGoTheme.border,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            if (walker.hourlyRate != null) ...[
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tarifa',
                    style: DogGoTheme.caption(size: 9.5),
                  ),
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
                  onPressed: walker.available
                      ? onRequest
                      : null,
                  icon: Icon(
                    walker.available
                        ? Icons.directions_walk_rounded
                        : Icons.schedule_rounded,
                  ),
                  label: Text(
                    walker.available
                        ? 'Solicitar paseo'
                        : 'No disponible',
                  ),
                ),
              ),
            ),
          ],
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