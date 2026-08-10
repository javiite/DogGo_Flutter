import 'package:flutter/material.dart';

import '../../../shared/widgets/doggo_error_view.dart';
import '../../../shared/widgets/doggo_skeleton_card.dart';
import '../../../theme/doggo_radius.dart';
import '../widgets/home_walk_pet_images.dart';

class HomeWalkSection extends StatelessWidget {
  final bool loading;
  final String? errorMessage;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String statusText;
  final Color statusColor;
  final String imageUrl;
  final List<String> imageUrls;
  final int petCount;
  final bool routeAlert;
  final String timingText;
  final String locationText;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final VoidCallback onRetry;

  const HomeWalkSection({
    super.key,
    required this.loading,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.statusText,
    required this.statusColor,
    required this.imageUrl,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    required this.onRetry,
    this.imageUrls = const [],
    this.petCount = 1,
    this.routeAlert = false,
    this.timingText = '',
    this.locationText = '',
    this.errorMessage,
  });

  List<String> get _effectiveImages {
    if (imageUrls.isNotEmpty) {
      return imageUrls;
    }

    return imageUrl.trim().isEmpty ? const [] : [imageUrl];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 17, 24, 0),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const DogGoSkeletonCard(
        height: 350,
        borderRadius: DogGoRadius.extraLarge,
      );
    }

    if (errorMessage != null) {
      return DogGoErrorView(
        title: 'No pudimos cargar tus paseos',
        message: errorMessage!,
        icon: Icons.route_outlined,
        onRetry: onRetry,
      );
    }

    return _WalkCard(
      eyebrow: eyebrow,
      title: title,
      subtitle: subtitle,
      statusText: statusText,
      statusColor: statusColor,
      imageUrls: _effectiveImages,
      petCount: petCount,
      routeAlert: routeAlert,
      timingText: timingText,
      locationText: locationText,
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
    );
  }
}

class _WalkCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String statusText;
  final Color statusColor;
  final List<String> imageUrls;
  final int petCount;
  final bool routeAlert;
  final String timingText;
  final String locationText;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _WalkCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.statusText,
    required this.statusColor,
    required this.imageUrls,
    required this.petCount,
    required this.routeAlert,
    required this.timingText,
    required this.locationText,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _WalkPalette.resolve(
      statusText: statusText,
      fallback: statusColor,
      routeAlert: routeAlert,
    );

    return Semantics(
      container: true,
      label: '$eyebrow. $title. $subtitle. $statusText',
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: palette.primary,
          borderRadius: BorderRadius.circular(DogGoRadius.extraLarge),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: 0.23),
              blurRadius: 28,
              offset: const Offset(0, 13),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: HomeWalkPetImages(
                imageUrls: imageUrls,
                petCount: petCount,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      palette.primary.withValues(alpha: 0.98),
                      palette.primary.withValues(alpha: 0.89),
                      palette.primary.withValues(alpha: 0.37),
                    ],
                    stops: const [0, 0.54, 1],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -28,
              bottom: -38,
              child: Icon(
                routeAlert ? Icons.warning_amber_rounded : Icons.pets_rounded,
                size: 155,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(palette.icon, color: Colors.white, size: 15),
                            const SizedBox(width: 6),
                            Text(
                              routeAlert ? 'ALERTA DE RUTA' : eyebrow,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.65,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (timingText.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxWidth: 140),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            timingText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 21),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 275),
                    child: Text(
                      routeAlert ? 'El paseo salió de la ruta' : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        height: 1.04,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 290),
                    child: Text(
                      routeAlert
                          ? 'El paseador debe regresar a la zona permitida. Puedes revisar el recorrido en tiempo real.'
                          : subtitle,
                      maxLines: routeAlert ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE9F5F2),
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (locationText.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.white,
                            size: 17,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              locationText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onPrimary,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 49),
                            backgroundColor: Colors.white,
                            foregroundColor: palette.primary,
                          ),
                          icon: Icon(
                            routeAlert
                                ? Icons.map_rounded
                                : palette.primaryActionIcon,
                          ),
                          label: Text(
                            routeAlert ? 'Ver recorrido' : primaryLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onSecondary,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 49),
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.58),
                            ),
                          ),
                          icon: Icon(
                            routeAlert
                                ? Icons.chat_rounded
                                : Icons.arrow_forward_rounded,
                          ),
                          label: Text(
                            routeAlert ? 'Abrir chat' : secondaryLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}

class _WalkPalette {
  final Color primary;
  final IconData icon;
  final IconData primaryActionIcon;

  const _WalkPalette({
    required this.primary,
    required this.icon,
    required this.primaryActionIcon,
  });

  factory _WalkPalette.resolve({
    required String statusText,
    required Color fallback,
    required bool routeAlert,
  }) {
    if (routeAlert) {
      return const _WalkPalette(
        primary: Color(0xFFB42E2E),
        icon: Icons.warning_amber_rounded,
        primaryActionIcon: Icons.map_rounded,
      );
    }

    final status = statusText.trim().toLowerCase();

    if (status.contains('pendiente')) {
      return const _WalkPalette(
        primary: Color(0xFFD87812),
        icon: Icons.hourglass_top_rounded,
        primaryActionIcon: Icons.assignment_outlined,
      );
    }

    if (status.contains('acept') || status.contains('confirm')) {
      return const _WalkPalette(
        primary: Color(0xFF5D478F),
        icon: Icons.event_available_rounded,
        primaryActionIcon: Icons.receipt_long_outlined,
      );
    }

    if (status.contains('curso') || status.contains('progreso')) {
      return const _WalkPalette(
        primary: Color(0xFF087D68),
        icon: Icons.directions_walk_rounded,
        primaryActionIcon: Icons.map_rounded,
      );
    }

    return _WalkPalette(
      primary: fallback,
      icon: Icons.pets_rounded,
      primaryActionIcon: Icons.search_rounded,
    );
  }
}
