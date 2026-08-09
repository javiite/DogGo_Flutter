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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionTitle(
            title: 'Actividad reciente',
            subtitle: 'Las novedades importantes de tu cuenta',
            actionText: activities.isEmpty ? null : 'Ver todas',
            onAction: activities.isEmpty ? null : onSeeAll,
          ),
          const SizedBox(height: 14),
          if (loading)
            const _ActivityLoading()
          else if (activities.isEmpty)
            const _EmptyActivity()
          else
            Container(
              decoration: BoxDecoration(
                color: DogGoTheme.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: DogGoTheme.border),
                boxShadow: DogGoTheme.softShadow(
                  opacity: .025,
                  blur: 16,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var index = 0;
                      index < activities.length;
                      index++) ...[
                    _ActivityTile(
                      activity: activities[index],
                      onTap: () {
                        onActivityTap(activities[index]);
                      },
                    ),
                    if (index < activities.length - 1)
                      const Divider(
                        height: 1,
                        indent: 76,
                        color: DogGoTheme.border,
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final HomeActivityItem activity;
  final VoidCallback onTap;

  const _ActivityTile({
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _activityStyle(activity.type);

    return Material(
      color: activity.read
          ? DogGoTheme.card
          : DogGoTheme.tealLight.withValues(alpha: .42),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  style.icon,
                  color: style.color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
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
                              size: 13.5,
                              color: DogGoTheme.ink,
                              weight: activity.read
                                  ? FontWeight.w700
                                  : FontWeight.w900,
                            ),
                          ),
                        ),
                        if (!activity.read)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: DogGoTheme.teal,
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
                      style: DogGoTheme.subtitle(
                        size: 11.5,
                      ),
                    ),
                    if (activity.occurredAt != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: DogGoTheme.muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _relativeDate(activity.occurredAt!),
                            style: DogGoTheme.body(
                              size: 10,
                              color: DogGoTheme.muted,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: DogGoTheme.muted,
                size: 21,
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
      height: 132,
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: DogGoTheme.teal,
        ),
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
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DogGoTheme.tealLight,
            DogGoTheme.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: DogGoTheme.teal.withValues(alpha: .12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: const BoxDecoration(
              color: DogGoTheme.card,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: DogGoTheme.teal,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Todo tranquilo por aquí',
                  style: DogGoTheme.title(size: 17),
                ),
                const SizedBox(height: 5),
                Text(
                  'Las actualizaciones de tus paseos aparecerán en este espacio.',
                  style: DogGoTheme.subtitle(size: 11.5),
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
  final now = DateTime.now();
  final difference = now.difference(date);

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