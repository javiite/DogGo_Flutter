import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';
import '../../explore/guides_screen.dart';
import '../../explore/places_screen.dart';
import '../widgets/home_section_title.dart';

class HomeExploreTab extends StatelessWidget {
  final bool isWalker;
  final VoidCallback onWalkers;
  final VoidCallback onPets;
  final VoidCallback onAvailability;
  final VoidCallback onWalks;
  final VoidCallback onProfile;

  const HomeExploreTab({
    super.key,
    required this.isWalker,
    required this.onWalkers,
    required this.onPets,
    required this.onAvailability,
    required this.onWalks,
    required this.onProfile,
  });

  void _openPlaces(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PlacesScreen(),
      ),
    );
  }

  void _openGuides(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const GuidesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeSectionTitle(
            title: 'Explorar',
            subtitle: 'Todo para disfrutar más con tu mascota',
          ),
          const SizedBox(height: 18),
          _WalkersHero(onTap: onWalkers),
          const SizedBox(height: 28),
          Text(
            'Descubre',
            style: DogGoTheme.title(size: 21),
          ),
          const SizedBox(height: 6),
          Text(
            'Ideas, servicios y espacios para compartir.',
            style: DogGoTheme.subtitle(size: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DiscoveryCard(
                  icon: Icons.place_outlined,
                  title: 'Lugares',
                  subtitle: 'Sitios cercanos',
                  color: DogGoTheme.orange,
                  background: DogGoTheme.orangeLight,
                  onTap: () {
                    _openPlaces(context);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DiscoveryCard(
                  icon: Icons.menu_book_outlined,
                  title: 'Guías',
                  subtitle: 'Consejos útiles',
                  color: DogGoTheme.purple,
                  background: DogGoTheme.purpleLight,
                  onTap: () {
                    _openGuides(context);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 29),
          Text(
            'Tu espacio DogGo',
            style: DogGoTheme.title(size: 21),
          ),
          const SizedBox(height: 14),
          _ExploreFeature(
            icon: isWalker
                ? Icons.event_available_outlined
                : Icons.pets_outlined,
            title: isWalker ? 'Mi disponibilidad' : 'Tus mascotas',
            description: isWalker
                ? 'Configura tus días, horarios y periodos no disponibles.'
                : 'Administra perfiles, fotografías y datos importantes.',
            color: isWalker ? DogGoTheme.teal : DogGoTheme.orange,
            background:
                isWalker ? DogGoTheme.tealLight : DogGoTheme.orangeLight,
            onTap: isWalker ? onAvailability : onPets,
          ),
          const SizedBox(height: 12),
          _ExploreFeature(
            icon: Icons.route_outlined,
            title: 'Historial de paseos',
            description:
                'Consulta solicitudes, recorridos y servicios anteriores.',
            color: DogGoTheme.green,
            background: DogGoTheme.greenLight,
            onTap: onWalks,
          ),
          const SizedBox(height: 12),
          _ExploreFeature(
            icon: Icons.manage_accounts_outlined,
            title: 'Perfil y seguridad',
            description:
                'Revisa tus datos personales y preferencias de cuenta.',
            color: DogGoTheme.purple,
            background: DogGoTheme.purpleLight,
            onTap: onProfile,
          ),
          const SizedBox(height: 27),
          const _SafetyCard(),
        ],
      ),
    );
  }
}

class _WalkersHero extends StatelessWidget {
  final VoidCallback onTap;

  const _WalkersHero({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.teal,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          height: 172,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF076858),
                Color(0xFF079A7D),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -30,
                child: Icon(
                  Icons.pets_rounded,
                  size: 155,
                  color: Colors.white.withValues(alpha: .08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(21),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: .14,
                              ),
                              borderRadius:
                                  BorderRadius.circular(30),
                            ),
                            child: Text(
                              'PASEADORES DOGGO',
                              style: DogGoTheme.body(
                                size: 9.5,
                                color: Colors.white,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Encuentra a la\npersona ideal',
                            style: DogGoTheme.title(
                              size: 23,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Consulta perfiles, experiencia y disponibilidad.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DogGoTheme.body(
                              size: 11.5,
                              color: Colors.white.withValues(
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
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: DogGoTheme.teal,
                        size: 25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoveryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _DiscoveryCard({
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
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 151,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: DogGoTheme.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: DogGoTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 23,
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
              const Spacer(),
              Text(
                title,
                style: DogGoTheme.title(size: 17),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DogGoTheme.subtitle(size: 10.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _ExploreFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DogGoTheme.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: DogGoTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 51,
                height: 51,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DogGoTheme.body(
                        size: 14,
                        color: DogGoTheme.ink,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.subtitle(size: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              const Icon(
                Icons.chevron_right_rounded,
                color: DogGoTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: const BoxDecoration(
                  color: DogGoTheme.tealLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: DogGoTheme.teal,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seguridad DogGo',
                      style: DogGoTheme.title(size: 18),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Acompañamiento durante cada paseo',
                      style: DogGoTheme.subtitle(size: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SafetyChip(
                icon: Icons.badge_outlined,
                text: 'Perfiles',
              ),
              _SafetyChip(
                icon: Icons.location_on_outlined,
                text: 'Ubicación',
              ),
              _SafetyChip(
                icon: Icons.photo_camera_outlined,
                text: 'Evidencias',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SafetyChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SafetyChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: DogGoTheme.cream,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: DogGoTheme.teal,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: DogGoTheme.body(
              size: 10.5,
              color: DogGoTheme.ink,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
