import 'package:flutter/material.dart';

import '../../home/models/home_walk.dart';
import '../../home/models/home_walk_status.dart';
import '../../home/widgets/home_walk_pet_avatar.dart';

class WalkerHomePriorityCard extends StatelessWidget {
  final HomeWalk? walk;
  final int pendingCount;
  final DateTime now;
  final ValueChanged<HomeWalk> onDetails;
  final ValueChanged<HomeWalk> onMap;
  final ValueChanged<HomeWalk> onChat;
  final VoidCallback onViewRequests;
  final VoidCallback onViewWalks;

  const WalkerHomePriorityCard({
    super.key,
    required this.walk,
    required this.pendingCount,
    required this.now,
    required this.onDetails,
    required this.onMap,
    required this.onChat,
    required this.onViewRequests,
    required this.onViewWalks,
  });

  @override
  Widget build(BuildContext context) {
    final current = walk;

    if (current == null) {
      return _EmptyPriorityCard(onViewWalks: onViewWalks);
    }

    final palette = _PriorityPalette.fromStatus(
      current.status,
      routeAlert: current.isInProgress && current.isOutsideAllowedRoute,
    );
    final isActive = current.isInProgress;
    final isPending = current.isPending;
    final hasRouteAlert = isActive && current.isOutsideAllowedRoute;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -20,
            bottom: -26,
            child: Icon(
              Icons.pets_rounded,
              color: Color(0x1FFFFFFF),
              size: 146,
            ),
          ),
          Column(
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
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(palette.icon, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          palette.eyebrow,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      isPending
                          ? '$pendingCount pendiente${pendingCount == 1 ? '' : 's'}'
                          : hasRouteAlert
                          ? current.routeDeviationTimeLabel(from: now)
                          : current.timeUntilLabel(from: now),
                      style: TextStyle(
                        color: palette.dark,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  HomeWalkPetAvatar(
                    imageUrls: current.petImageUrls,
                    fallbackImageUrl: current.imageUrl,
                    petCount: current.petCount,
                    size: 70,
                    dark: true,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          current.petName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${current.formattedSchedule} · ${current.ownerDisplayName}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFE9F5F2),
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (hasRouteAlert) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          current.routeStatusMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (current.pickupAddress.isNotEmpty) ...[
                const SizedBox(height: 17),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          current.pickupAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        if (isActive) {
                          onMap(current);
                        } else {
                          onDetails(current);
                        }
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        backgroundColor: Colors.white,
                        foregroundColor: palette.dark,
                      ),
                      icon: Icon(
                        isActive
                            ? Icons.map_rounded
                            : isPending
                            ? Icons.assignment_rounded
                            : Icons.event_available_rounded,
                      ),
                      label: Text(
                        isActive
                            ? hasRouteAlert
                                  ? 'Volver al mapa'
                                  : 'Continuar'
                            : isPending
                            ? 'Revisar'
                            : 'Preparar',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (isPending) {
                          onViewRequests();
                        } else {
                          onChat(current);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.58),
                        ),
                      ),
                      icon: Icon(
                        isPending ? Icons.inbox_rounded : Icons.chat_rounded,
                      ),
                      label: Text(isPending ? 'Solicitudes' : 'Chat'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyPriorityCard extends StatelessWidget {
  final VoidCallback onViewWalks;

  const _EmptyPriorityCard({required this.onViewWalks});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4F1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFC8E3DC)),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF087D68),
              size: 32,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Todo bajo control',
                  style: TextStyle(
                    color: Color(0xFF20212B),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'No tienes servicios ni solicitudes inmediatas.',
                  style: TextStyle(
                    color: Color(0xFF6F7279),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Ver mis paseos',
            onPressed: onViewWalks,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }
}

class _PriorityPalette {
  final List<Color> gradient;
  final Color dark;
  final Color shadow;
  final IconData icon;
  final String eyebrow;

  const _PriorityPalette({
    required this.gradient,
    required this.dark,
    required this.shadow,
    required this.icon,
    required this.eyebrow,
  });

  factory _PriorityPalette.fromStatus(
    HomeWalkStatus status, {
    bool routeAlert = false,
  }) {
    if (routeAlert) {
      return const _PriorityPalette(
        gradient: [Color(0xFFA92727), Color(0xFFD94A3D)],
        dark: Color(0xFF8F1F1F),
        shadow: Color(0x3DA92727),
        icon: Icons.warning_amber_rounded,
        eyebrow: 'FUERA DE LA RUTA',
      );
    }

    switch (status) {
      case HomeWalkStatus.inProgress:
        return const _PriorityPalette(
          gradient: [Color(0xFF006E5E), Color(0xFF0A9A7D)],
          dark: Color(0xFF006554),
          shadow: Color(0x33008770),
          icon: Icons.directions_walk_rounded,
          eyebrow: 'PASEO ACTIVO',
        );
      case HomeWalkStatus.accepted:
        return const _PriorityPalette(
          gradient: [Color(0xFF4E3A83), Color(0xFF7960B4)],
          dark: Color(0xFF4E3A83),
          shadow: Color(0x33745CAE),
          icon: Icons.event_available_rounded,
          eyebrow: 'PRÓXIMO SERVICIO',
        );
      default:
        return const _PriorityPalette(
          gradient: [Color(0xFFD87812), Color(0xFFF0A62E)],
          dark: Color(0xFF9B5108),
          shadow: Color(0x33D87812),
          icon: Icons.notifications_active_rounded,
          eyebrow: 'SOLICITUD PENDIENTE',
        );
    }
  }
}
