import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';
import '../widgets/home_section_title.dart';

class HomeExploreTab extends StatelessWidget {
  final VoidCallback onWalkers;
  final VoidCallback onPets;
  final VoidCallback onWalks;
  final VoidCallback onProfile;

  const HomeExploreTab({
    super.key,
    required this.onWalkers,
    required this.onPets,
    required this.onWalks,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeSectionTitle(
            title: 'Explorar',
            subtitle: 'Todo DogGo en un mismo lugar',
          ),
          const SizedBox(height: 18),
          _ExploreFeature(
            icon: Icons.person_search_rounded,
            title: 'Encuentra paseadores',
            description:
                'Consulta perfiles, experiencia, tarifas y disponibilidad.',
            color: DogGoTheme.teal,
            background: DogGoTheme.tealLight,
            onTap: onWalkers,
          ),
          const SizedBox(height: 13),
          _ExploreFeature(
            icon: Icons.pets_outlined,
            title: 'Tus mascotas',
            description:
                'Administra perfiles, fotografías y datos importantes.',
            color: DogGoTheme.orange,
            background: DogGoTheme.orangeLight,
            onTap: onPets,
          ),
          const SizedBox(height: 13),
          _ExploreFeature(
            icon: Icons.route_outlined,
            title: 'Historial de paseos',
            description:
                'Consulta solicitudes, recorridos y servicios anteriores.',
            color: DogGoTheme.green,
            background: DogGoTheme.greenLight,
            onTap: onWalks,
          ),
          const SizedBox(height: 13),
          _ExploreFeature(
            icon: Icons.manage_accounts_outlined,
            title: 'Perfil y seguridad',
            description:
                'Revisa tus datos personales y preferencias de cuenta.',
            color: DogGoTheme.purple,
            background: DogGoTheme.purpleLight,
            onTap: onProfile,
          ),
          const SizedBox(height: 26),
          const _SafetyCard(),
        ],
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
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: DogGoTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: DogGoTheme.title(size: 18),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: DogGoTheme.subtitle(size: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DogGoTheme.muted,
                ),
              ],
            ),
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
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: DogGoTheme.teal,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seguridad DogGo',
            style: DogGoTheme.title(
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Herramientas para acompañarte durante cada paseo.',
            style: DogGoTheme.body(
              size: 12.5,
              color: Colors.white.withOpacity(.78),
            ),
          ),
          const SizedBox(height: 17),
          const _SafetyItem(
            icon: Icons.verified_user_outlined,
            text: 'Perfiles identificados',
          ),
          const SizedBox(height: 11),
          const _SafetyItem(
            icon: Icons.location_on_outlined,
            text: 'Ubicación compartida',
          ),
          const SizedBox(height: 11),
          const _SafetyItem(
            icon: Icons.photo_camera_outlined,
            text: 'Evidencia del servicio',
          ),
        ],
      ),
    );
  }
}

class _SafetyItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SafetyItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: DogGoTheme.orange,
          size: 21,
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: DogGoTheme.body(
            size: 12.5,
            color: Colors.white,
            weight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}