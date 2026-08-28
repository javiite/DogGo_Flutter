import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';
import '../../home/models/home_walk_status.dart';
import '../models/walk_detail.dart';

class WalkStatusTimeline extends StatelessWidget {
  final WalkDetail walk;

  const WalkStatusTimeline({super.key, required this.walk});

  @override
  Widget build(BuildContext context) {
    final cancelled = walk.isCancelled || walk.isRejected;
    final current = _currentStep(walk.status);
    final items = <({String title, String detail, IconData icon})>[
      (
        title: 'Solicitud enviada',
        detail: walk.scheduledLabel,
        icon: Icons.send_rounded,
      ),
      (
        title: cancelled ? 'Servicio cerrado' : 'Paseo confirmado',
        detail: cancelled
            ? (walk.cancellationReason ?? 'Cancelado o rechazado')
            : 'Paseador y mascotas confirmados',
        icon: cancelled ? Icons.block_rounded : Icons.verified_rounded,
      ),
      (
        title: 'Paseo iniciado',
        detail: walk.startedAt == null ? 'Pendiente' : walk.startedLabel,
        icon: Icons.directions_walk_rounded,
      ),
      (
        title: 'Paseo finalizado',
        detail: walk.finishedAt == null ? 'Pendiente' : walk.finishedLabel,
        icon: Icons.flag_rounded,
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Línea de tiempo', style: DogGoTheme.title(size: 17)),
          const SizedBox(height: 16),
          for (var index = 0; index < items.length; index++)
            _TimelineItem(
              title: items[index].title,
              detail: items[index].detail,
              icon: items[index].icon,
              completed: cancelled ? index <= 1 : index <= current,
              active: cancelled ? index == 1 : index == current,
              last: index == items.length - 1,
              cancelled: cancelled && index == 1,
            ),
        ],
      ),
    );
  }

  int _currentStep(HomeWalkStatus status) {
    switch (status) {
      case HomeWalkStatus.pending:
        return 0;
      case HomeWalkStatus.accepted:
        return 1;
      case HomeWalkStatus.inProgress:
        return 2;
      case HomeWalkStatus.completed:
        return 3;
      case HomeWalkStatus.cancelled:
      case HomeWalkStatus.rejected:
        return 1;
      case HomeWalkStatus.none:
      case HomeWalkStatus.unknown:
        return 0;
    }
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String detail;
  final IconData icon;
  final bool completed;
  final bool active;
  final bool last;
  final bool cancelled;

  const _TimelineItem({
    required this.title,
    required this.detail,
    required this.icon,
    required this.completed,
    required this.active,
    required this.last,
    required this.cancelled,
  });

  @override
  Widget build(BuildContext context) {
    final color = cancelled
        ? DogGoTheme.red
        : completed
        ? DogGoTheme.teal
        : DogGoTheme.disabled;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: active ? color : color.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: active ? Colors.white : color,
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: completed
                        ? color.withValues(alpha: .45)
                        : DogGoTheme.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: DogGoTheme.body(weight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(detail, style: DogGoTheme.caption(size: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
