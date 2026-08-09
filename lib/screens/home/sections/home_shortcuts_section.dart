import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';

class HomeShortcutsSection
    extends StatelessWidget {
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
            : Icons.pets_rounded,
        label: isWalker
            ? 'Mi perfil'
            : 'Mascotas',
        color: DogGoTheme.teal,
        background:
            DogGoTheme.tealLight,
        onTap: onPetsOrProfile,
      ),
      _ShortcutData(
        icon:
            Icons.calendar_month_rounded,
        label: 'Agenda',
        color: DogGoTheme.purple,
        background:
            DogGoTheme.purpleLight,
        onTap: onAgenda,
      ),
      _ShortcutData(
        icon: Icons.route_rounded,
        label: 'Paseos',
        color: DogGoTheme.orange,
        background:
            DogGoTheme.orangeLight,
        onTap: onWalks,
      ),
      _ShortcutData(
        icon: Icons.explore_rounded,
        label: 'Explorar',
        color: DogGoTheme.green,
        background:
            DogGoTheme.greenLight,
        onTap: onExplore,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        28,
        24,
        0,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Todo a la mano',
                  style: DogGoTheme.title(
                    size: 20,
                  ),
                ),
              ),
              Text(
                'Accesos rápidos',
                style: DogGoTheme.subtitle(
                  size: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              borderRadius:
                  BorderRadius.circular(22),
              border: Border.all(
                color: DogGoTheme.border,
              ),
              boxShadow:
                  DogGoTheme.softShadow(
                opacity: 0.025,
                blur: 14,
              ),
            ),
            child: Row(
              children: [
                for (var index = 0;
                    index <
                        shortcuts.length;
                    index++) ...[
                  Expanded(
                    child: _ShortcutButton(
                      data:
                          shortcuts[index],
                    ),
                  ),
                  if (index <
                      shortcuts.length - 1)
                    Container(
                      width: 1,
                      height: 47,
                      color:
                          DogGoTheme.border,
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

class _ShortcutButton
    extends StatelessWidget {
  final _ShortcutData data;

  const _ShortcutButton({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: data.label,
      child: InkWell(
        onTap: data.onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 4,
          ),
          child: Column(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: data.background,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  data.icon,
                  color: data.color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                data.label,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: DogGoTheme.body(
                  size: 10.5,
                  weight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutData {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _ShortcutData({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });
}