import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';

class HomeHeaderSection
    extends StatelessWidget {
  final String userName;
  final String role;
  final int petCount;
  final int upcomingWalkCount;
  final bool isWalker;

  const HomeHeaderSection({
    super.key,
    required this.userName,
    required this.role,
    required this.petCount,
    required this.upcomingWalkCount,
    required this.isWalker,
  });

  @override
  Widget build(BuildContext context) {
    final cleanName =
        userName.trim().isEmpty
            ? 'Usuario'
            : userName.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        4,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _UserAvatar(
                name: cleanName,
                isWalker: isWalker,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style:
                          DogGoTheme.subtitle(
                        size: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      cleanName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: DogGoTheme.title(
                        size: 27,
                        color:
                            DogGoTheme.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      DogGoTheme.tealLight,
                  borderRadius:
                      BorderRadius.circular(
                    30,
                  ),
                ),
                child: Text(
                  isWalker
                      ? 'PASEADOR'
                      : 'DUEÑO',
                  style: DogGoTheme.label(
                    size: 9.5,
                    color: DogGoTheme.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeaderMetric(
                  icon: isWalker
                      ? Icons
                          .task_alt_rounded
                      : Icons.pets_rounded,
                  value: isWalker
                      ? '$upcomingWalkCount'
                      : '$petCount',
                  label: isWalker
                      ? upcomingWalkCount == 1
                          ? 'servicio próximo'
                          : 'servicios próximos'
                      : petCount == 1
                          ? 'mascota'
                          : 'mascotas',
                  color: DogGoTheme.teal,
                  background:
                      DogGoTheme.tealLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeaderMetric(
                  icon: isWalker
                      ? Icons
                          .calendar_month_rounded
                      : Icons
                          .directions_walk_rounded,
                  value:
                      '$upcomingWalkCount',
                  label: isWalker
                      ? 'en tu agenda'
                      : upcomingWalkCount == 1
                          ? 'paseo próximo'
                          : 'paseos próximos',
                  color: DogGoTheme.orange,
                  background:
                      DogGoTheme.orangeLight,
                ),
              ),
            ],
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

class _UserAvatar
    extends StatelessWidget {
  final String name;
  final bool isWalker;

  const _UserAvatar({
    required this.name,
    required this.isWalker,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty
        ? 'D'
        : name.characters.first
            .toUpperCase();

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWalker
              ? const [
                  Color(0xFF7554B8),
                  Color(0xFF533A89),
                ]
              : const [
                  Color(0xFF0A806A),
                  Color(0xFF075F54),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: (isWalker
                    ? DogGoTheme.purple
                    : DogGoTheme.teal)
                .withValues(
              alpha: 0.20,
            ),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 23,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeaderMetric
    extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color background;

  const _HeaderMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: DogGoTheme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: background,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: DogGoTheme.title(
                    size: 17,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      DogGoTheme.subtitle(
                    size: 9.5,
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