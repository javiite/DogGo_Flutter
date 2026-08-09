import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';
import '../../explore/guides_screen.dart';
import '../../explore/places_screen.dart';
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

  void _openGuides(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const GuidesScreen(),
      ),
    );
  }

  void _openPlaces(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PlacesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        30,
        24,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionTitle(
            title: 'Explora DogGo',
            subtitle:
                'Ideas y servicios para disfrutar juntos',
            actionText: 'Ver más',
            onAction: onExploreAll,
          ),
          const SizedBox(height: 14),
          _WalkersCard(
            onTap: onWalkers,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SmallExploreCard(
                  icon: Icons.menu_book_outlined,
                  title: 'Guías',
                  subtitle: 'Cuidados y consejos',
                  color: DogGoTheme.purple,
                  background: DogGoTheme.purpleLight,
                  onTap: () {
                    _openGuides(context);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SmallExploreCard(
                  icon: Icons.place_outlined,
                  title: 'Lugares',
                  subtitle: 'Espacios por conocer',
                  color: DogGoTheme.orange,
                  background: DogGoTheme.orangeLight,
                  onTap: () {
                    _openPlaces(context);
                  },
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

  const _WalkersCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Buscar paseadores',
      child: Material(
        color: DogGoTheme.teal,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF087866),
                  Color(0xFF0A9A7E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: DogGoTheme.softShadow(
                opacity: .08,
                blur: 22,
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 148,
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -17,
                    bottom: -27,
                    child: Icon(
                      Icons.pets_rounded,
                      size: 138,
                      color: Colors.white.withValues(
                        alpha: .08,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      19,
                      18,
                      18,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(
                                    alpha: .14,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                    20,
                                  ),
                                ),
                                child: Text(
                                  'PASEO SEGURO',
                                  style: DogGoTheme.label(
                                    size: 9.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                'Encuentra a tu\npaseador ideal',
                                style: DogGoTheme.title(
                                  size: 22,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Consulta perfiles y disponibilidad',
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: DogGoTheme.body(
                                  size: 11.5,
                                  color:
                                      Colors.white.withValues(
                                    alpha: .78,
                                  ),
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 50,
                          height: 50,
                          decoration:
                              const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: DogGoTheme.teal,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: DogGoTheme.border,
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 150,
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 22,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_outward_rounded,
                          color: color,
                          size: 19,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.title(size: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.subtitle(
                        size: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}