import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';
import '../models/home_activity_item.dart';
import '../widgets/home_section_title.dart';

class HomeActivitySection extends StatelessWidget {
  final bool loading;
  final List<HomeActivityItem> activities;
  final VoidCallback onSeeAll;
  final ValueChanged<HomeActivityItem> onActivityTap;

  const HomeActivitySection({
    super.key,
    required this.loading,
    required this.activities,
    required this.onSeeAll,
    required this.onActivityTap,
  });

  List<HomeActivityItem> get _orderedActivities {
    final result = [...activities];

    result.sort((first, second) {
      if (first.read != second.read) {
        return first.read ? 1 : -1;
      }

      final firstDate =
          first.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final secondDate =
          second.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return secondDate.compareTo(firstDate);
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final ordered = _orderedActivities;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 27, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionTitle(
            title: 'Actividad reciente',
            subtitle: 'Alertas y novedades importantes',
            actionText: ordered.isEmpty ? null : 'Ver todas',
            onAction: ordered.isEmpty ? null : onSeeAll,
          ),
          const SizedBox(height: 12),
          if (loading)
            const _ActivityLoading()
          else if (ordered.isEmpty)
            const _EmptyActivity()
          else
            Column(
              children: [
                for (var index = 0; index < ordered.length; index++) ...[
                  _ActivityTile(
                    activity: ordered[index],
                    onTap: () => onActivityTap(ordered[index]),
                  ),
                  if (index < ordered.length - 1) const SizedBox(height: 9),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final HomeActivityItem activity;
  final VoidCallback onTap;

  const _ActivityTile({required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _activityStyle(activity.type);
    final critical = activity.type == HomeActivityType.routeDeviation;

    return Material(
      color: critical
          ? const Color(0xFFFFF0EF)
          : activity.read
          ? DogGoTheme.card
          : DogGoTheme.tealLight.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 12, 11, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: critical ? const Color(0xFFEAB6B2) : DogGoTheme.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(style.icon, color: style.color, size: 21),
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
                            activity.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DogGoTheme.body(
                              size: 12.5,
                              color: critical ? DogGoTheme.red : DogGoTheme.ink,
                              weight: activity.read
                                  ? FontWeight.w800
                                  : FontWeight.w900,
                            ),
                          ),
                        ),
                        if (!activity.read)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(left: 7),
                            decoration: BoxDecoration(
                              color: critical
                                  ? DogGoTheme.red
                                  : DogGoTheme.teal,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      activity.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.subtitle(size: 10.5),
                    ),
                    if (activity.occurredAt != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        _relativeDate(activity.occurredAt!),
                        style: DogGoTheme.body(
                          size: 9.5,
                          color: DogGoTheme.muted,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                critical ? Icons.map_rounded : Icons.chevron_right_rounded,
                color: style.color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityLoading extends StatelessWidget {
  const _ActivityLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFFE4E8E6),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DogGoTheme.teal.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: DogGoTheme.teal,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Todo tranquilo por aquí',
                  style: DogGoTheme.title(size: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Las novedades de tus paseos aparecerán aquí.',
                  style: DogGoTheme.subtitle(size: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityStyle {
  final IconData icon;
  final Color color;
  final Color background;

  const _ActivityStyle({
    required this.icon,
    required this.color,
    required this.background,
  });
}

_ActivityStyle _activityStyle(HomeActivityType type) {
  switch (type) {
    case HomeActivityType.walkRequested:
      return const _ActivityStyle(
        icon: Icons.schedule_rounded,
        color: DogGoTheme.orange,
        background: DogGoTheme.orangeLight,
      );
    case HomeActivityType.walkAccepted:
      return const _ActivityStyle(
        icon: Icons.check_circle_outline_rounded,
        color: DogGoTheme.green,
        background: DogGoTheme.greenLight,
      );
    case HomeActivityType.walkStarted:
      return const _ActivityStyle(
        icon: Icons.directions_walk_rounded,
        color: DogGoTheme.teal,
        background: DogGoTheme.tealLight,
      );
    case HomeActivityType.walkCompleted:
      return const _ActivityStyle(
        icon: Icons.flag_outlined,
        color: DogGoTheme.green,
        background: DogGoTheme.greenLight,
      );
    case HomeActivityType.walkCancelled:
      return const _ActivityStyle(
        icon: Icons.cancel_outlined,
        color: DogGoTheme.red,
        background: DogGoTheme.redLight,
      );
    case HomeActivityType.newPhoto:
      return const _ActivityStyle(
        icon: Icons.photo_camera_outlined,
        color: DogGoTheme.purple,
        background: DogGoTheme.purpleLight,
      );
    case HomeActivityType.newMessage:
      return const _ActivityStyle(
        icon: Icons.chat_bubble_outline_rounded,
        color: DogGoTheme.teal,
        background: DogGoTheme.tealLight,
      );
    case HomeActivityType.routeDeviation:
      return const _ActivityStyle(
        icon: Icons.warning_amber_rounded,
        color: DogGoTheme.red,
        background: DogGoTheme.redLight,
      );
    case HomeActivityType.routeRecovered:
      return const _ActivityStyle(
        icon: Icons.add_road_rounded,
        color: DogGoTheme.green,
        background: DogGoTheme.greenLight,
      );
    case HomeActivityType.checkpointReached:
      return const _ActivityStyle(
        icon: Icons.location_on_rounded,
        color: DogGoTheme.purple,
        background: DogGoTheme.purpleLight,
      );
    case HomeActivityType.notification:
    case HomeActivityType.unknown:
      return const _ActivityStyle(
        icon: Icons.notifications_none_rounded,
        color: DogGoTheme.purple,
        background: DogGoTheme.purpleLight,
      );
  }
}

String _relativeDate(DateTime date) {
  final difference = DateTime.now().difference(date);

  if (difference.isNegative) {
    return 'Próximamente';
  }
  if (difference.inMinutes < 1) {
    return 'Ahora';
  }
  if (difference.inMinutes < 60) {
    return 'Hace ${difference.inMinutes} min';
  }
  if (difference.inHours < 24) {
    return 'Hace ${difference.inHours} h';
  }
  if (difference.inDays == 1) {
    return 'Ayer';
  }
  if (difference.inDays < 7) {
    return 'Hace ${difference.inDays} días';
  }

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
