import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';
import '../widgets/home_shortcut.dart';

class HomeShortcutsSection extends StatelessWidget {
  final bool isWalker;
  final VoidCallback onPetsOrProfile;
  final VoidCallback onAgenda;
  final VoidCallback onWalks;
  final VoidCallback onExplore;

  const HomeShortcutsSection({
    super.key,
    required this.isWalker,
    required this.onPetsOrProfile,
    required this.onAgenda,
    required this.onWalks,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    final shortcuts = [
      _ShortcutData(
        icon: isWalker
            ? Icons.badge_outlined
            : Icons.pets_outlined,
        label: isWalker ? 'Perfil' : 'Mascotas',
        onTap: onPetsOrProfile,
      ),
      _ShortcutData(
        icon: Icons.calendar_today_outlined,
        label: 'Agenda',
        onTap: onAgenda,
      ),
      _ShortcutData(
        icon: Icons.route_outlined,
        label: 'Paseos',
        onTap: onWalks,
      ),
      _ShortcutData(
        icon: Icons.explore_outlined,
        label: 'Explorar',
        onTap: onExplore,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accesos',
            style: DogGoTheme.title(
              size: 21,
              color: DogGoTheme.ink,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var index = 0;
                  index < shortcuts.length;
                  index++) ...[
                Expanded(
                  child: HomeShortcut(
                    icon: shortcuts[index].icon,
                    label: shortcuts[index].label,
                    onTap: shortcuts[index].onTap,
                  ),
                ),
                if (index < shortcuts.length - 1)
                  const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ShortcutData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShortcutData({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}