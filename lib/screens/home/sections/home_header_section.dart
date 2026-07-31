import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';

class HomeHeaderSection extends StatelessWidget {
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
    final cleanName = userName.trim().isEmpty
        ? 'Usuario'
        : userName.trim();

    final summary = isWalker
        ? _walkerSummary()
        : _ownerSummary();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 10),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: .055,
                  child: Icon(
                    isWalker
                        ? Icons.directions_walk_rounded
                        : Icons.pets_rounded,
                    size: 122,
                    color: DogGoTheme.teal,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 76),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.toUpperCase(),
                    style: DogGoTheme.label(
                      size: 10.5,
                      color: DogGoTheme.teal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hola, $cleanName',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DogGoTheme.title(
                      size: 34,
                      color: DogGoTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    summary,
                    style: DogGoTheme.subtitle(size: 14.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ownerSummary() {
    final petText = petCount == 1
        ? '1 mascota registrada'
        : '$petCount mascotas registradas';

    final walkText = upcomingWalkCount == 1
        ? '1 paseo próximo'
        : '$upcomingWalkCount paseos próximos';

    return '$petText · $walkText';
  }

  String _walkerSummary() {
    if (upcomingWalkCount == 0) {
      return 'No tienes servicios próximos';
    }

    if (upcomingWalkCount == 1) {
      return 'Tienes 1 servicio próximo';
    }

    return 'Tienes $upcomingWalkCount servicios próximos';
  }
}