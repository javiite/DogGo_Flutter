import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';
import '../widgets/home_section_title.dart';

class HomeExploreSection extends StatelessWidget {
  final VoidCallback onWalkers;
  final VoidCallback onGuides;
  final VoidCallback onPlaces;
  final VoidCallback onExploreAll;

  const HomeExploreSection({
    super.key,
    required this.onWalkers,
    required this.onGuides,
    required this.onPlaces,
    required this.onExploreAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 27, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionTitle(
            title: 'Explora DogGo',
            subtitle: 'Servicios e ideas para disfrutar juntos',
            actionText: 'Ver todo',
            onAction: onExploreAll,
          ),
          const SizedBox(height: 12),
          _WalkersCard(onTap: onWalkers),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SmallExploreCard(
                  icon: Icons.menu_book_outlined,
                  title: 'Guías',
                  subtitle: 'Consejos para cada paseo',
                  color: DogGoTheme.purple,
                  background: DogGoTheme.purpleLight,
                  onTap: onGuides,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallExploreCard(
                  icon: Icons.place_outlined,
                  title: 'Lugares',
                  subtitle: 'Opciones cerca de ti',
                  color: DogGoTheme.orange,
                  background: DogGoTheme.orangeLight,
                  onTap: onPlaces,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalkersCard extends StatelessWidget {
  final VoidCallback onTap;

  const _WalkersCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.teal,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF087D68), Color(0xFF10A184)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 51,
                height: 51,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Encuentra un paseador',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.title(size: 17, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Consulta perfiles, tarifas y disponibilidad.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.body(
                        size: 10.5,
                        color: Colors.white.withValues(alpha: .80),
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 37,
                height: 37,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: DogGoTheme.teal,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallExploreCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _SmallExploreCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DogGoTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_outward_rounded, color: color, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DogGoTheme.title(size: 15),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: DogGoTheme.subtitle(size: 9.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
