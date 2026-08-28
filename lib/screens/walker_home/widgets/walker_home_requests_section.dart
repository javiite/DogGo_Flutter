import 'package:flutter/material.dart';

import '../../home/models/home_walk.dart';
import '../../home/widgets/home_walk_pet_avatar.dart';

class WalkerHomeRequestsSection extends StatelessWidget {
  final List<HomeWalk> requests;
  final bool Function(HomeWalk walk) isActingOn;
  final ValueChanged<HomeWalk> onDetails;
  final ValueChanged<HomeWalk> onAccept;
  final ValueChanged<HomeWalk> onReject;
  final VoidCallback onSeeAll;

  const WalkerHomeRequestsSection({
    super.key,
    required this.requests,
    required this.isActingOn,
    required this.onDetails,
    required this.onAccept,
    required this.onReject,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const SizedBox.shrink();
    }

    final grouped = <HomeWalk>[];
    final counts = <int, int>{};
    final seen = <int>{};
    for (final walk in requests) {
      final programId = walk.programacionId;
      if (programId != null) {
        counts[programId] = (counts[programId] ?? 0) + 1;
        if (!seen.add(programId)) continue;
      }
      grouped.add(walk);
    }
    final visible = grouped.take(3).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Solicitudes por revisar',
                    style: TextStyle(
                      color: Color(0xFF20212B),
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Responde para que el dueño pueda organizarse.',
                    style: TextStyle(color: Color(0xFF74767E), fontSize: 11.5),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onSeeAll, child: const Text('Ver todas')),
          ],
        ),
        const SizedBox(height: 12),
        ...visible.map(
          (walk) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: _RequestCard(
              walk: walk,
              programCount: walk.programacionId == null
                  ? 0
                  : counts[walk.programacionId] ?? 0,
              loading: isActingOn(walk),
              onDetails: () => onDetails(walk),
              onAccept: () => onAccept(walk),
              onReject: () => onReject(walk),
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final HomeWalk walk;
  final int programCount;
  final bool loading;
  final VoidCallback onDetails;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.walk,
    this.programCount = 0,
    required this.loading,
    required this.onDetails,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: loading ? null : onDetails,
        borderRadius: BorderRadius.circular(23),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: const Color(0xFFF0D4AE)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0E343434),
                blurRadius: 16,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  HomeWalkPetAvatar(
                    imageUrls: walk.petImageUrls,
                    fallbackImageUrl: walk.imageUrl,
                    petCount: walk.petCount,
                    size: 56,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          programCount > 1
                              ? 'Programación · $programCount paseos'
                              : walk.petName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF20212B),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${walk.formattedSchedule} · ${walk.ownerDisplayName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFD77713),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (walk.pickupAddress.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            walk.pickupAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF777980),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFB4B6BB),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (loading)
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: Color(0xFFD87812),
                )
              else if (programCount > 1)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onDetails,
                    icon: const Icon(Icons.event_note_rounded),
                    label: const Text('Revisar programación'),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          foregroundColor: const Color(0xFFB64238),
                          side: const BorderSide(color: Color(0xFFE5B5B1)),
                        ),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Rechazar'),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onAccept,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          backgroundColor: const Color(0xFF087D68),
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Aceptar'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
