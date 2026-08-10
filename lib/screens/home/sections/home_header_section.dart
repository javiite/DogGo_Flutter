import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';

class HomeHeaderSection extends StatelessWidget {
  final String userName;
  final String? photoUrl;
  final int petCount;
  final int upcomingWalkCount;
  final int activeWalkCount;
  final int pendingWalkCount;
  final bool isWalker;

  const HomeHeaderSection({
    super.key,
    required this.userName,
    required this.petCount,
    required this.upcomingWalkCount,
    required this.isWalker,
    this.photoUrl,
    this.activeWalkCount = 0,
    this.pendingWalkCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cleanName = userName.trim().isEmpty ? 'Usuario' : userName.trim();
    final hasActiveWalk = activeWalkCount > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _UserAvatar(
                name: cleanName,
                isWalker: isWalker,
                photoUrl: photoUrl,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()},',
                      style: DogGoTheme.subtitle(size: 11.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cleanName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.title(size: 25, color: DogGoTheme.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: hasActiveWalk ? const Color(0xFFE7F4F1) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: hasActiveWalk
                    ? const Color(0xFFC3E0D8)
                    : DogGoTheme.border,
              ),
            ),
            child: Row(
              children: [
                _CompactMetric(
                  icon: Icons.pets_rounded,
                  value: petCount,
                  label: petCount == 1 ? 'mascota' : 'mascotas',
                  color: DogGoTheme.teal,
                ),
                const _MetricDivider(),
                _CompactMetric(
                  icon: hasActiveWalk
                      ? Icons.directions_walk_rounded
                      : Icons.event_available_rounded,
                  value: hasActiveWalk ? activeWalkCount : upcomingWalkCount,
                  label: hasActiveWalk
                      ? 'en paseo'
                      : upcomingWalkCount == 1
                      ? 'próximo'
                      : 'próximos',
                  color: hasActiveWalk ? DogGoTheme.green : DogGoTheme.purple,
                ),
                const _MetricDivider(),
                _CompactMetric(
                  icon: Icons.hourglass_top_rounded,
                  value: pendingWalkCount,
                  label: pendingWalkCount == 1 ? 'pendiente' : 'pendientes',
                  color: DogGoTheme.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Buenos días';
    }
    if (hour < 19) {
      return 'Buenas tardes';
    }
    return 'Buenas noches';
  }
}

class _UserAvatar extends StatelessWidget {
  final String name;
  final bool isWalker;
  final String? photoUrl;

  const _UserAvatar({
    required this.name,
    required this.isWalker,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? 'D' : name.characters.first.toUpperCase();
    final photo = photoUrl?.trim() ?? '';

    return Container(
      width: 52,
      height: 52,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWalker
              ? const [Color(0xFF7554B8), Color(0xFF533A89)]
              : const [Color(0xFF0A806A), Color(0xFF075F54)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isWalker ? DogGoTheme.purple : DogGoTheme.teal).withValues(
              alpha: 0.18,
            ),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: photo.startsWith('http://') || photo.startsWith('https://')
          ? Image.network(
              photo,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _AvatarInitial(initial: initial),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    _AvatarInitial(initial: initial),
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                );
              },
            )
          : _AvatarInitial(initial: initial),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  final String initial;

  const _AvatarInitial({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _CompactMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value', style: DogGoTheme.title(size: 14)),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DogGoTheme.subtitle(size: 8.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: DogGoTheme.border,
    );
  }
}
