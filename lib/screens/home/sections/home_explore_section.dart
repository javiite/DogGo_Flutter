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
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionTitle(
            title: 'Explora DogGo',
            subtitle: 'Encuentra servicios y contenido útil',
            actionText: 'Ver más',
            onAction: onExploreAll,
          ),
          const SizedBox(height: 14),
          _ExploreCard(
            icon: Icons.person_search_rounded,
            title: 'Paseadores',
            subtitle:
                'Encuentra perfiles, tarifas y disponibilidad.',
            color: DogGoTheme.teal,
            background: DogGoTheme.tealLight,
            onTap: onWalkers,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ExploreCard(
                  compact: true,
                  icon: Icons.menu_book_outlined,
                  title: 'Guías',
                  subtitle: 'Consejos para tu mascota.',
                  color: DogGoTheme.purple,
                  background: DogGoTheme.purpleLight,
                  onTap: onGuides,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ExploreCard(
                  compact: true,
                  icon: Icons.place_outlined,
                  title: 'Lugares',
                  subtitle: 'Espacios para visitar.',
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

class _ExploreCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;
  final bool compact;

  const _ExploreCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
    this.compact = false,
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
            height: compact ? 196 : null,
            constraints: compact
                ? null
                : const BoxConstraints(minHeight: 112),
            padding: EdgeInsets.all(compact ? 16 : 17),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: DogGoTheme.border),
            ),
            child: compact
                ? _buildCompact()
                : _buildHorizontal(),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontal() {
    return Row(
      children: [
        _ExploreIcon(
          icon: icon,
          color: color,
          background: background,
        ),
        const SizedBox(width: 14),
        Expanded(child: _textContent()),
        const SizedBox(width: 8),
        const Icon(
          Icons.arrow_forward_rounded,
          color: DogGoTheme.muted,
          size: 21,
        ),
      ],
    );
  }

  Widget _buildCompact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ExploreIcon(
          icon: icon,
          color: color,
          background: background,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _textContent(),
        ),
        const SizedBox(height: 8),
        Icon(
          Icons.arrow_forward_rounded,
          color: color,
          size: 20,
        ),
      ],
    );
  }

  Widget _textContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DogGoTheme.title(
            size: compact ? 17 : 19,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: DogGoTheme.subtitle(
            size: compact ? 11.5 : 12.5,
          ),
        ),
      ],
    );
  }
}

class _ExploreIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;

  const _ExploreIcon({
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: color,
        size: 25,
      ),
    );
  }
}